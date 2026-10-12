# Errores y hallazgos

## E01 — Controlador MySQL conectado a MariaDB

- **Síntoma:** al iniciar `api-facturas`, Hibernate mostró `Unknown column 'RESERVED' in 'WHERE'`. La API respondía, pero quedaba un aviso de incompatibilidad.
- **Causa:** el proyecto usaba MySQL Connector/J y la URL `jdbc:mysql://` para un servidor MariaDB 11.8.9. El controlador intentó consultar una columna `RESERVED` que no existe en `INFORMATION_SCHEMA.KEYWORDS` de MariaDB.
- **Corrección:** se sustituyó la dependencia por MariaDB Connector/J 3.5.10, se cambió la URL a `jdbc:mariadb://`, se quitó el dialecto MySQL fijado manualmente y se desactivó `spring.jpa.open-in-view`.
- **Verificación:** tras reconstruir la imagen `fintech-nova-api-facturas:1.0.1`, los logs mostraron `org.mariadb.jdbc.Connection`, no repitieron el aviso y `GET /facturas` devolvió HTTP 200 con las dos facturas iniciales.
- **Evidencia para adjuntar:** capturas de los logs antes y después, y de la respuesta HTTP.

## E02 — Límite de consultas de la API de geolocalización

- **Síntoma:** al crear una transacción con `origen_ip=8.8.8.8`, el campo `pais` quedó vacío.
- **Causa observada:** el log de `api-transacciones` mostró `La API externa de geolocalizacion devolvio un error: RateLimited`.
- **Comportamiento previsto:** la transacción se guardó igualmente; una falla del proveedor externo no impide el ABM.
- **Verificación:** el POST creó la transacción `id=3`. Luego, el PUT sobre esa transacción con `origen_ip=1.1.1.1` obtuvo `pais=Australia`, y un GET confirmó que se persistió.
- **Mejora posible:** hacer las pruebas automáticas con una respuesta simulada del proveedor externo y mostrar en la interfaz cuándo no pudo determinarse el país.

## E03 — MariaDB lista, pero el healthcheck marcaba `unhealthy`

- **Síntoma observado:** `docker compose ps db` mostró `unhealthy`, aunque el log de MariaDB decía `ready for connections`.
- **Evidencia:** el historial del healthcheck mostró `Can't connect to local server through socket '/run/mysqld/mysqld.sock'`; el servidor informaba su socket en `/run/mariadb/mariadb.sock`.
- **Corrección en esta práctica:** el Compose usa `healthcheck.sh --connect`. Se recreó un volumen de prueba que no contenía datos que hubiera que conservar y la DB pasó a `healthy`.
- **Aprendizaje:** no interpretar `unhealthy` como caída del proceso sin leer los logs de ambos. En un entorno con datos reales, no borrar el volumen para resolverlo: primero investigar y respaldar.

## E04 — Una contraseña con `$` se interpretaba como variable de Compose

- **Síntoma observado:** al iniciar la DB apareció `The "mQ8z" variable is not set. Defaulting to a blank string.`
- **Causa:** Compose interpolaba parte de una contraseña de los archivos `.env` como si fuera una variable. No se registra aquí la contraseña.
- **Corrección:** los servicios usan `env_file` con `format: raw` para pasar esos valores sin interpolarlos.
- **Verificación:** `docker compose config --quiet` terminó sin advertencias y la DB pudo iniciar con sus credenciales.

## E05 — `/monitor/` devolvía Web1 y la hoja de estilo llegaba como HTML

- **Síntoma observado:** en `https://127.0.0.1:18444/monitor/` se veía Web1; la respuesta de `/monitor/theme.css` era `text/html`, no `text/css`.
- **Causa:** se consultaba el contenedor/proxy anterior publicado en `18444`, cuya imagen todavía servía el `index.html` de Web1 como fallback. `docker compose up -d` no reconstruye automáticamente una imagen cuando el Compose solo declara `image:`.
- **Corrección:** reconstruir la imagen después de editar el frontend y consultar el puerto publicado por el Compose actual: `https://localhost/monitor/` (`443`).
- **Verificación:** `/monitor/` respondió con la página del monitor y `/monitor/theme.css` con HTTP 200 y `Content-Type: text/css`.

## E06 — Faltaba `web2/config.yaml` después del merge

- **Hallazgo preventivo:** el Compose montaba `./web2/config.yaml:/app/config.yaml:ro`, pero el archivo local no existía. Era un riesgo de fallo al crear el contenedor y el monitor no habría tenido rutas para sondear.
- **Corrección:** se completó `web2/config.yaml.example` con las seis rutas públicas y se creó `web2/config.yaml` a partir de ese contenido. El archivo real está ignorado por Git y no se incorpora a la imagen.
- **Verificación:** `docker compose up -d` levantó Web2 y `/monitor/config.js` incluyó los seis servicios.

## E07 — Facturas devolvió 502 durante el arranque

- **Síntoma observado:** en una prueba local, `/api/facturas` devolvió HTTP 502 mientras los otros endpoints respondían 200.
- **Causa confirmada:** Nginx registró `connect() failed (111: Connection refused)` a `api-facturas:8080` antes de que Spring Boot terminara de iniciar. No era un problema de DNS ni de credenciales: luego Tomcat anunció que escuchaba en `8080`.
- **Corrección:** `deploy.sh` espera y reintenta las rutas HTTPS antes de declarar exitoso el despliegue.
- **Verificación:** una nueva solicitud a `/api/facturas` devolvió HTTP 200 y las facturas iniciales.

## E08 — El script intentaba hacer `pull` antes de recibir los `.env`

- **Hallazgo preventivo, no fallo ejecutado en EC2:** `deploy.sh --preparar` llamaba a `docker compose pull` antes de `transferir.sh --levantar`. El Compose requiere seis archivos `.env` que todavía no estarían en la instancia.
- **Corrección inicial:** se separó la preparación de la instalación en dos fases. Tras la primera prueba completa en AWS, se simplificó el flujo: `transferir.sh` o `transferir.ps1` crea las carpetas y envía **todos** los archivos primero; `deploy.sh` valida, instala, genera el certificado, hace `pull` y prueba el stack.
- **Estado:** el flujo anterior de dos fases llegó a ocho contenedores `Up` y respondió por HTTPS desde Windows. El nuevo flujo simplificado está pendiente de prueba integral en una EC2 nueva.

## E09 — Docker no estaba disponible dentro de WSL

- **Síntoma observado:** `wsl -d Ubuntu -- docker version` respondió `The command 'docker' could not be found in this WSL 2 distro`.
- **Causa:** Docker Desktop funcionaba desde PowerShell, pero su integración con esa distribución WSL no estaba habilitada.
- **Alternativa usada:** construir y publicar las ocho imágenes con Docker desde PowerShell. Para ejecutar `./deploy.sh --build` en WSL habrá que habilitar allí la integración de Docker Desktop.
- **Verificación:** los ocho `push` terminaron y `docker compose pull` descargó las ocho imágenes públicas.

## E10 — Comandos de Compose fuera de la raíz del proyecto

- **Síntoma observado:** desde `C:\Users\Jesus`, `docker compose up -d --no-deps --force-recreate web2` respondió `no configuration file provided: not found`.
- **Causa:** Compose busca el archivo de configuración en el directorio actual (o hay que indicarlo explícitamente).
- **Corrección:** ejecutar los comandos desde la raíz del repositorio, donde está `docker-compose.yml`.

## E11 — Se pegó un comando Bash multilínea en PowerShell

- **Síntoma observado:** PowerShell marcó `Falta la expresión después del operador unario "--"` al pegar `docker run` con barras invertidas (`\`) al final de cada línea.
- **Causa:** `\` continúa líneas en Bash, no en PowerShell.
- **Corrección:** usar una sola línea en PowerShell, su carácter de continuación propio o ejecutar el comando en WSL. Docker Desktop puede atender comandos desde ambos entornos si WSL tiene la integración habilitada.

## E12 — `curl` entró en conflicto con `curl-minimal` en Amazon Linux 2023

- **Síntoma observado:** `bash ./deploy.sh --preparar` terminó en el paso 1 con `problem with installed package curl-minimal` al ejecutar `yum install -y curl`.
- **Causa:** la AMI de Amazon Linux 2023 ya trae `curl-minimal`, que proporciona el comando `curl`. El paquete `curl` completo entra en conflicto con él. `set -e` detuvo el script antes de instalar Docker.
- **Corrección:** comprobar si existe el comando y, solo si falta, instalar `curl-minimal`; comprobar también `openssl` antes de generar el certificado. No hace falta reemplazar el paquete existente con `--allowerasing`.
- **Verificación:** tras transferir el script corregido, la preparación terminó correctamente en Amazon Linux 2023. El despliegue completo inició ocho contenedores, con MariaDB `healthy`; desde Windows, `/`, `/monitor/` y `/api/clientes` respondieron HTTP 200 por HTTPS.

## E13 — Hibernate registraba la contraseña JDBC

- **Síntoma observado:** al arrancar `api-facturas` con Spring Boot 4, Hibernate 7 imprimió en INFO la URL JDBC efectiva, que incluía `user` y `password`. No se reproduce aquí el valor de la contraseña.
- **Causa:** el controlador MariaDB añadió las credenciales a la URL que Hibernate usa para mostrar la información de la conexión.
- **Corrección:** se bajó a WARN el logger `org.hibernate.orm.connections.pooling`. Las credenciales siguen llegando solo por variables de entorno; no se incorporan a la imagen ni a Git.
- **Verificación:** después de reconstruir y recrear el contenedor, `/api/facturas` volvió a responder HTTP 200 y los nuevos logs ya no contienen `password=`.
- **Acción pendiente:** rotar la clave que haya aparecido en logs anteriores, coordinando el cambio del usuario en MariaDB y de los cinco `.env` de las APIs. No basta con editar solo los `.env` si el volumen de la DB ya está inicializado.


## Riesgos pendientes de la primera prueba en AWS

- El flujo nuevo de dos comandos (`transferir` local y `deploy.sh` remoto) valida archivos y detiene la ejecución ante errores de `ssh`/`scp`. Todavía falta probarlo completo en una EC2 recién creada; la prueba exitosa de AWS fue con la versión anterior de los scripts.
- `deploy.sh` ahora comprueba el plugin Compose independientemente de Docker y lo instala si falta. Este caso particular todavía no se probó en una EC2 que ya tuviera Docker sin Compose.
- `web2` ahora escucha en `8081` **solo dentro de `app_net`**. La imagen base de Nginx aún declara `EXPOSE 80` como metadato heredado, pero el proceso no escucha allí y Compose no publica ese puerto.
- Los límites de memoria de los ocho servicios suman `2880M`, además de lo que necesita el sistema operativo. Una EC2 de 2 GB podría quedarse sin memoria; el tamaño de instancia y el consumo real deben comprobarse en el Sandbox.
- El escaneo de Docker Scout del 12/10/2026 sobre las imágenes locales `1.0.2` encontró hallazgos altos/críticos residuales en las bases de MariaDB, Pagos y las dos webs. Cuatro imágenes (Clientes, Facturas, Transacciones y Tarjetas) no tenían hallazgos de esas severidades. En MariaDB, Scout sigue contando el `gosu` antiguo presente en una capa de la imagen oficial aun cuando el binario ejecutado fue sustituido por `gosu 1.19` compilado con Go 1.26.9; también señala SQLite de la base UBI9 sin parche disponible. Esto no autoriza a afirmar que la imagen esté libre de vulnerabilidades. La DB no se publica al host, pero deben seguirse las actualizaciones de MariaDB/UBI antes de una entrega o despliegue real.
