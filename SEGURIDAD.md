# Seguridad

## Gestión de secretos y configuración

- Docker Compose carga las credenciales de MariaDB y de las cinco APIs desde seis archivos `.env`. Se usa `env_file` con `format: raw`, lo que evita que Compose interprete caracteres como `$` dentro de las contraseñas.
- Las cinco APIs obtienen `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER` y `DB_PASSWORD` exclusivamente del entorno. No existen credenciales de respaldo en el código y cada servicio detiene su inicio con un error que identifica la variable faltante, sin imprimir su valor, si alguna no está definida o está vacía.
- `web2` no recibe variables desde un `.env`: monta `web2/config.yaml` en `/app/config.yaml` como solo lectura. Este archivo define las rutas públicas que muestra y sondea el monitor.
- Los `.env`, `web2/config.yaml`, `.deploy-public-ip`, la carpeta `certs/` y las extensiones habituales de certificados y claves están excluidos por `.gitignore`. Solo se versionan las plantillas `env.example` y `web2/config.yaml.example`.
- El `.dockerignore` raíz excluye de los contextos de construcción los `.env`, certificados, claves privadas y artefactos de dependencias o compilación. `web2/.dockerignore` excluye además `config.yaml`; por lo tanto, la configuración real del monitor no se envía en su contexto de construcción.
- `transferir.sh` y `transferir.ps1` validan que los siete archivos privados requeridos existan y no estén vacíos antes de copiarlos mediante SCP sobre SSH. Se transfieren directamente desde el equipo del grupo a EC2, sin incorporarlos al repositorio ni a las imágenes. En EC2 se crean con `umask 077` y se les aplican permisos `600`, también a `.deploy-public-ip`.
- La clave SSH esperada es `~/.ssh/keydevops.pem` y no se transfiere al servidor ni se incorpora a las imágenes. En WSL debe existir dentro del home de la distribución y conservar permisos restrictivos.
- La misma cuenta de aplicación de MariaDB recibe `ALL PRIVILEGES` sobre las cinco bases. La separación es lógica, no por credencial.

No deben incluirse valores reales de credenciales, claves, certificados ni archivos de configuración privada en commits, imágenes públicas, capturas o documentación.

## TLS y certificados

- NGINX es el punto de terminación TLS. Escucha en el puerto `8443` del contenedor `web`, acepta TLS 1.2 y 1.3 y oculta su versión mediante `server_tokens off`. Compose publica únicamente `443:8443`.
- `deploy.sh` genera el certificado en tiempo de ejecución, directamente en EC2, con RSA de 2048 bits, SHA-256 y 365 días de vigencia. Esta opción permite incluir en el SAN la IP pública de la instancia de esa sesión del sandbox, que puede cambiar entre sesiones, y evita empaquetar la clave privada en una imagen pública de Docker Hub. El SAN incluye la IP pública registrada, `localhost` y `127.0.0.1`.
- El script reutiliza el certificado si coincide con la IP y tiene más de 24 horas de vigencia. Si debe reemplazarlo, primero genera archivos nuevos, conserva copias del par anterior y fija `certs/key.pem` y el respaldo de la clave en modo `600`.
- Compose monta `./certs` en `/etc/nginx/certs` como solo lectura. El certificado y la clave no forman parte de la imagen de `web`.
- El certificado es autofirmado: cifra la conexión, pero el navegador no puede validar su identidad mediante una autoridad de confianza. `curl --insecure` se usa solamente en las comprobaciones del despliegue y en pruebas documentadas; no equivale a una validación TLS confiable.
- Entre NGINX, `web2` y las APIs el tráfico usa HTTP dentro de `app_net`. El cifrado está configurado entre el cliente y NGINX, no entre contenedores.


## Exposición de red y AWS

- Solo `web` publica un puerto del host. Las cinco APIs (`8080`), MariaDB (`3306`) y `web2` (`80`) son accesibles únicamente desde la red Docker `app_net`.
- NGINX expone `/`, `/monitor/` y las rutas `/api/*`; también redirige `/web2` hacia `/monitor/`. No hay un listener HTTP público ni una redirección desde el puerto 80.
- **Reglas esperadas del Security Group, pendientes de verificación en AWS:** HTTPS `443` desde Internet; SSH `22` limitado a la IP autorizada; `80`, `3306` y `8080` cerrados al público. Los scripts no crean ni verifican estas reglas. Registrarlas en `AWS_EC2.md` y respaldarlas con evidencia de la consola de AWS o comandos de AWS CLI antes de afirmar que están aplicadas.
- `api-pagos` consulta `open.er-api.com` y `api-transacciones` consulta `ipapi.co`, ambas por HTTPS y sin API key. Las llamadas tienen un tiempo máximo de cinco segundos y sus fallos no impiden guardar el registro, aunque generan una dependencia de salida hacia servicios de terceros.

## Imágenes y ejecución de contenedores

- Las cinco APIs se ejecutan con usuarios no root (`app` o `node`). `web`, `web2` y la imagen personalizada de MariaDB no declaran un usuario alternativo en sus Dockerfiles y conservan el comportamiento de sus imágenes base.
- Las imágenes base son imágenes publicadas por los proyectos o proveedores correspondientes: MariaDB, Python, Node, Maven/Eclipse Temurin, Go/Alpine, Microsoft .NET y NGINX. Java, Go, .NET y `web` usan compilaciones multietapa, por lo que sus herramientas de compilación no quedan en las imágenes finales. Python y Node usan imágenes de runtime.
- Compose fija etiquetas explícitas para las ocho imágenes publicadas en Docker Hub. Esto mejora la repetibilidad respecto de `latest`, pero las etiquetas no son inmutables como un digest y el repositorio no aporta firma ni attestations de las imágenes.
- `web2` parte de `nginx:alpine` sin fijar una versión concreta. Las demás imágenes base tienen una versión declarada, aunque tampoco están fijadas por digest.
- Compose establece límites de CPU y memoria, reinicio automático y un healthcheck para MariaDB. Estos controles mejoran disponibilidad y contención de recursos, pero no sustituyen autenticación, autorización ni hardening del runtime.
- `deploy.sh` valida la sintaxis efectiva con `docker compose config --quiet`, descarga las imágenes, inicia el stack y espera HTTP 200 en las siete rutas HTTPS antes de informar éxito. La verificación usa `--insecure` porque el certificado es autofirmado.

## Seguridad de las aplicaciones

- Las APIs usan consultas parametrizadas o repositorios ORM en las operaciones revisadas, lo que reduce el riesgo de inyección SQL en esos endpoints.
- No hay autenticación ni autorización. Cualquier cliente que alcance el puerto 443 puede listar, crear, modificar y eliminar clientes, pagos, facturas, transacciones y tarjetas. Este es el riesgo funcional más importante si el sistema queda expuesto fuera de un entorno académico controlado.
- No se observan límites de frecuencia, tamaño máximo de solicitudes, protección contra abuso ni validación homogénea de los datos de entrada. Algunas APIs validan campos básicos y otras confían en el mapeo del framework o en restricciones de la base.
- NGINX no configura actualmente HSTS, Content-Security-Policy ni otros encabezados HTTP de endurecimiento. Tampoco se limita allí el tamaño o la frecuencia de las solicitudes.
- Los logs de error de algunas APIs imprimen excepciones internas. No se devuelven credenciales al cliente, pero en un entorno real los logs deben tener acceso restringido y evitar datos personales o secretos.

## Revisión según OWASP Docker Top 10

Se usa [OWASP Docker Top 10](https://owasp.org/projects/docker-top-10) como lista de controles de referencia, no como certificación. El proyecto aplica algunos controles y mantiene otros como riesgos pendientes:

| Control | Aplicación observada y estado |
| --- | --- |
| D01 — Asignación segura de usuarios | Las cinco APIs configuran un usuario no root. `web`, `web2` y MariaDB no declaran un usuario alternativo en sus Dockerfiles; revisar si es compatible endurecerlos. |
| D02 — Estrategia de parches | Se declaran versiones de imágenes base, pero `web2` usa la etiqueta flotante `nginx:alpine` y no se documenta un proceso periódico de actualización o análisis de vulnerabilidades. |
| D03 — Separación de red y firewall | Los servicios comparten `app_net` y solo `web` publica `443`. Las reglas reales del Security Group todavía deben verificarse en AWS. |
| D04 — Valores seguros y hardening | NGINX usa TLS 1.2/1.3 y `server_tokens off`. No se documentan autenticación, autorización, límites de solicitudes ni encabezados como HSTS y CSP. |
| D05 — Contexto de seguridad | Las bases están separadas por servicio, pero la cuenta de aplicación tiene privilegios sobre las cinco. No se configura filesystem de solo lectura ni reducción de capacidades Linux. |
| D06 — Protección de secretos | Se usan `env_file`, reglas de exclusión y transferencia SCP/SSH con permisos `600`. Las APIs no contienen credenciales de respaldo y fallan al iniciar si falta una variable obligatoria de conexión. |
| D07 — Protección de recursos | Compose define límites de CPU y memoria; MariaDB también tiene healthcheck. |
| D08 — Integridad y procedencia de imágenes | Se usan imágenes base de sus proveedores y etiquetas de versión. No se documentan análisis, firma ni verificación criptográfica de las imágenes publicadas. |
| D09 — Paradigma inmutable | Las imágenes se versionan con etiquetas y los datos de MariaDB persisten en un volumen. No se fijan imágenes por digest ni se configura filesystem de contenedor de solo lectura. |
| D10 — Registro de actividad | Hay logs de aplicación y errores, pero no se documentan políticas de retención, centralización o revisión periódica. |

## Despliegue seguro

1. Completar los seis `.env` y `web2/config.yaml` a partir de sus plantillas, sin versionarlos.
2. Restringir la clave SSH a su propietario y ejecutar `transferir.sh <IP>` o `transferir.ps1 <IP>` desde la raíz del proyecto.
3. Verificar en AWS que SSH `22` esté limitado a la IP autorizada, que solo HTTPS `443` esté abierto al público y que los demás puertos permanezcan cerrados.
4. En EC2, ejecutar `bash ./deploy.sh`. El script valida archivos, instala Docker y Compose cuando faltan, prepara el certificado, descarga las imágenes y comprueba el servicio.
5. Revisar `sudo docker compose ps` y los logs sin copiar credenciales ni datos sensibles. Confirmar además que los archivos privados conserven permisos `600`.

## Pendientes recomendados

- Incorporar autenticación y autorización antes de utilizar datos reales o exponer los ABM públicamente.
- Ejecutar y conservar resultados de análisis de dependencias, imágenes y configuración (por ejemplo, Trivy y Checkov). El repositorio no contiene reportes de estos controles.
- Fijar las imágenes base y, para despliegues controlados, las imágenes publicadas mediante digest; agregar generación de SBOM y firma de imágenes.
- Ejecutar contenedores con filesystem de solo lectura y reducir capacidades Linux cuando la compatibilidad de cada servicio esté comprobada.
- Agregar encabezados de seguridad, límites de solicitudes, validación consistente y una política de logs.
- Verificar externamente las reglas efectivas del Security Group, la visibilidad de los repositorios en Docker Hub y la prueba integral del flujo actual en una EC2 nueva.
