# Fintech Nova — guía para levantar el TP en local

Esta guía corresponde al avance de la rama `feat/dockerizacion-inicial-Jesus`. Hoy levanta **7 contenedores**: MariaDB, cinco APIs y el frontend `web`, servido por HTTPS. `web2`, Docker Hub y el despliegue en EC2 todavía están pendientes. Los comandos, salvo la generación del certificado, están pensados para **PowerShell en Windows 11** y deben ejecutarse desde la **raíz del repositorio**.

## 1. Requisitos y descarga

- Docker Desktop iniciado y configurado para contenedores Linux.
- Git y VS Code.
- Docker Compose **2.30 o posterior**, porque el archivo usa `env_file` con `format: raw`.
- WSL con OpenSSL para crear el certificado local. Node, Java, Go y .NET no necesitan instalarse en Windows: las compilaciones se hacen con Docker.

```powershell
git clone https://labsys.frc.utn.edu.ar/gitlab/desarrollo-y-operaciones-devops/tps-2026/grupo-10/trabajopracticogrupo10.git
cd trabajopracticogrupo10
git switch --track origin/feat/dockerizacion-inicial-Jesus
docker --version
docker compose version
```

Si ya clonaron el repositorio, hagan `git fetch origin` y cambien a esa rama. Antes de continuar, verifiquen que la terminal esté en la carpeta que contiene `docker-compose.yml`, `db/`, `api-clientes/` y `web/`.

## 2. Crear los archivos de entorno

Cada servicio recibe variables mediante un archivo `.env` propio. Los `env.example` son plantillas públicas; **los `.env` reales no se suben a Git**.

```powershell
Copy-Item .\db\env.example .\db\.env
Copy-Item .\api-clientes\env.example .\api-clientes\.env
Copy-Item .\api-pagos\env.example .\api-pagos\.env
Copy-Item .\api-facturas\env.example .\api-facturas\.env
Copy-Item .\api-transacciones\env.example .\api-transacciones\.env
Copy-Item .\api-tarjetas\env.example .\api-tarjetas\.env
```

En `db/.env`, completen estos valores (los textos entre `< >` son marcadores que deben reemplazarse):

```dotenv
MYSQL_ROOT_PASSWORD=<clave-root-fuerte>
MYSQL_DATABASE=db_clientes
MYSQL_USER=<usuario-de-aplicacion>
MYSQL_PASSWORD=<clave-de-aplicacion-fuerte>
```

La clave de `root` debe ser distinta de la clave de aplicación. El script `db/init-scripts/00-databases.sh` crea las cinco bases. La imagen oficial crea inicialmente la indicada por `MYSQL_DATABASE`.

En **cada** `api-*/.env`, completen:

```dotenv
DB_HOST=db
DB_PORT=3306
DB_NAME=<base-del-servicio>
DB_USER=<mismo-usuario-de-aplicacion-que-en-db/.env>
DB_PASSWORD=<misma-clave-de-aplicacion-que-en-db/.env>
PORT=8080
```

| Archivo | `DB_NAME` |
| --- | --- |
| `api-clientes/.env` | `db_clientes` |
| `api-pagos/.env` | `db_pagos` |
| `api-facturas/.env` | `db_facturas` |
| `api-transacciones/.env` | `db_transacciones` |
| `api-tarjetas/.env` | `db_tarjetas` |

`DB_HOST=db` es el **nombre del servicio en Compose**; Docker lo resuelve dentro de la red compartida. No usen `localhost` ni la IP de otro compañero. El usuario y la contraseña de aplicación deben coincidir exactamente en la base y en las cinco APIs. La separación actual es por nombre de base, **no por permisos independientes**: el script concede al mismo usuario acceso a las cinco.

Escriban los valores como `CLAVE=valor`, **sin comillas exteriores ni espacios agregados**. El `format: raw` del Compose conserva caracteres como `$` literalmente; si escriben comillas alrededor de una contraseña, esas comillas pasarán a formar parte de ella. No compartan contraseñas por chat, capturas ni commits.

## 3. Generar el certificado local

Abran una terminal **WSL** en VS Code, ubicada en la misma raíz del proyecto. `pwd` debería mostrar una ruta bajo `/mnt/c/.../trabajopracticogrupo10` si el repositorio está en `C:`.

```bash
pwd
openssl version
mkdir -p certs
openssl req -x509 -newkey rsa:2048 -sha256 -nodes -days 30 -keyout certs/key.pem -out certs/cert.pem -subj "/CN=localhost" -addext "subjectAltName=DNS:localhost,IP:127.0.0.1"
openssl x509 -in certs/cert.pem -noout -subject -ext subjectAltName
git check-ignore -v certs/key.pem certs/cert.pem
```

Esperamos `CN=localhost` y `DNS:localhost, IP Address:127.0.0.1`. Si los archivos ya existen, no repitan `openssl req` salvo que quieran reemplazarlos. `key.pem` es una **clave privada**: no se sube a Git ni se copia dentro de la imagen pública. Compose monta `certs/` en Nginx como solo lectura. Al ser autofirmado, el navegador advertirá que el certificado no es de una autoridad confiable; eso es esperable para esta prueba local. En EC2 se generará **otro certificado**.

## 4. Construir las imágenes desde la raíz

Vuelvan a **PowerShell** en la raíz. Todos los comandos terminan en `.` porque ese punto indica el contexto de construcción, que es la raíz del repositorio. `-f` selecciona el Dockerfile de cada servicio.

```powershell
docker build -t fintech-nova-db:1.0.0 -f db/Dockerfile .
docker build -t fintech-nova-api-clientes:1.0.0 -f api-clientes/Dockerfile .
docker build -t fintech-nova-api-pagos:1.0.0 -f api-pagos/Dockerfile .
docker build -t fintech-nova-api-facturas:1.0.1 -f api-facturas/Dockerfile .
docker build -t fintech-nova-api-transacciones:1.0.0 -f api-transacciones/Dockerfile .
docker build -t fintech-nova-api-tarjetas:1.0.0 -f api-tarjetas/Dockerfile .
docker build -t fintech-nova-web:1.0.0 -f web/Dockerfile .
```

El Compose actual usa `image:` y **no contiene `build:`**. Por eso primero deben existir estas imágenes locales. La versión `1.0.1` de facturas incluye la corrección para el driver de MariaDB.

## 5. Levantar y verificar

```powershell
docker compose config --quiet
docker compose config --services
docker compose up -d
docker compose ps
```

`config --quiet` valida el archivo sin imprimir los valores de los `.env`. `config --services` debe listar siete servicios. `db` debe llegar a `(healthy)` y los demás quedar `Up`. Si alguna API tarda en iniciar, esperen unos segundos y vuelvan a consultar `docker compose ps`.

El único puerto publicado al host es el de `web`: **`127.0.0.1:18444` → `8443` del contenedor**. Abran `https://localhost:18444/` en el navegador. Para verificar también los cinco proxys:

```powershell
curl.exe -k -i https://127.0.0.1:18444/
curl.exe -k -i https://127.0.0.1:18444/api/clientes
curl.exe -k -i https://127.0.0.1:18444/api/pagos
curl.exe -k -i https://127.0.0.1:18444/api/facturas
curl.exe -k -i https://127.0.0.1:18444/api/transacciones
curl.exe -k -i https://127.0.0.1:18444/api/tarjetas
```

Esperamos `HTTP/1.1 200` y datos de ejemplo. `-k` omite **solo para la prueba** la verificación de confianza del certificado autofirmado. La conexión del navegador a Nginx es HTTPS; dentro de la red Docker, Nginx habla HTTP con las APIs. Ni las APIs ni MariaDB publican puertos al host.

## 6. Si algo falla

- **Una API devuelve `502`**: esperen unos segundos y revisen `docker compose ps` y `docker compose logs --tail=50 api-facturas` (reemplacen por el servicio afectado). Un contenedor `Up` no siempre significa que la aplicación terminó de iniciar.
- **Base `unhealthy`**: revisen `docker compose logs --tail=50 db`. El healthcheck actual comprueba conectividad TCP porque la variante UBI de MariaDB usa un socket distinto del que intentaba la comprobación de InnoDB. Que esté `healthy` no reemplaza probar una consulta mediante las APIs.
- **Aviso `The "..." variable is not set`**: no compartan la contraseña. Verifiquen que usan Compose 2.30 o posterior y que cada servicio conserva `env_file` con `format: raw`.
- **Puerto 18444 ocupado**: cambien únicamente el número de la izquierda en `ports:` del servicio `web`; conserven `8443` a la derecha. No abran el puerto 80.
- **Falla después de cambiar claves**: las variables de inicialización de MariaDB solo se aplican sobre una base nueva. **No borren el volumen para “probar” si contiene datos**; coordinen antes una copia de seguridad o un reinicio deliberado.
- **Servicios externos**: `api-pagos` y `api-transacciones` consultan proveedores externos al crear/actualizar datos. Pueden sufrir límites de uso; el dato principal debe seguir guardándose aunque falte el campo enriquecido.

Para detener los contenedores sin borrar los datos:

```powershell
docker compose down
```

No ejecuten `docker compose down -v` salvo que realmente quieran **eliminar el volumen de MariaDB y sus datos**.

## 7. Qué falta para la entrega

Este es un **punto de control local**, no el despliegue definitivo. Falta desarrollar `web2` (octavo contenedor), mejorar la interfaz principal, publicar las imágenes en los namespaces de Docker Hub acordados por el grupo, cambiar las referencias `image:` a esas imágenes, adaptar el puerto HTTPS para EC2, generar allí un certificado nuevo y completar la documentación y las capturas exigidas por la consigna. No suban `.env`, `key.pem` ni otros secretos a GitLab o Docker Hub.

## Referencias

- [Docker Compose: `env_file` y `format: raw`](https://docs.docker.com/reference/compose-file/services/#env_file)
- [Docker Compose: nombres de servicio en la red](https://docs.docker.com/compose/how-tos/networking/)
- [Docker Compose: qué elimina `down` y qué elimina `down -v`](https://docs.docker.com/reference/cli/docker/compose/down/)
- [MariaDB: variables de inicialización y volumen existente](https://hub.docker.com/_/mariadb)
