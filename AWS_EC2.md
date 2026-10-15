# Evidencia de Configuración y Despliegue en AWS EC2

Este documento registra la configuración de infraestructura en AWS Academy Learner Lab, las reglas de red, el aprovisionamiento automatizado y la validación del despliegue de **FinTech Nova** (Grupo 10).

## 1. Instancia EC2 y Red (VPC / Subred)

La instancia se creó desde la consola web de AWS EC2 con los siguientes parámetros de sesión:

| Parámetro | Valor registrado |
| :--- | :--- |
| **Nombre de la instancia** | `TPDevOps` |
| **ID de la instancia** | `i-02bd7698d64ea9ea1` |
| **AMI / Sistema Operativo** | Amazon Linux 2023 (`al2023-ami-2023.12.20261012.0-kernel-6.10-x86_64` / `ami-09706586205a51eb2`) |
| **Arquitectura** | `x86_64` (64-bit) |
| **Tipo de instancia** | `t3.medium` (2 vCPU, 4 GiB RAM) |
| **Almacenamiento** | 1 volumen raíz EBS de `8 GiB` (`gp3`, 3000 IOPS) |
| **Región / Zona de Disponibilidad** | `us-east-1` (N. Virginia) / `us-east-1d` |
| **VPC ID** | `vpc-0ff796200b0fd80a9` |
| **Subnet ID** | `subnet-0df550d950e15a232` (con auto-asignación de IP pública habilitada) |
| **IP Pública (IPv4)** | `32.194.87.233` |
| **DNS Público (IPv4)** | `ec2-32-194-87-233.compute-1.amazonaws.com` |
| **IP Privada (IPv4)** | `172.31.44.111` |
| **Par de llaves SSH** | `keydevops` (`keydevops.pem`, RSA) |

![Resumen de la instancia EC2](docs/img/aws-ec2-detalle.png)

---

## 2. Security Group (Reglas de Entrada y Salida)

Se asoció el Security Group **`launch-wizard-1`** (`sg-0e63e479a589b5bcf`) en la VPC `vpc-0ff796200b0fd80a9`, exponiendo únicamente el puerto HTTPS público y restringiendo la administración por SSH.

### Reglas de Entrada (Inbound Rules)

| ID de Regla | Tipo | Protocolo | Rango de Puertos | Origen (Source) | Propósito |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `sgr-067e21f51e1766ed8` | SSH | TCP | `22` | `190.247.70.100/32` (*My IP*) | Administración por SSH restringida exclusivamente a la IP del equipo. |
| `sgr-0a2e75f1460360a70` | HTTPS | TCP | `443` | `0.0.0.0/0` (*Anywhere-IPv4*) | Único punto de entrada público hacia el proxy inverso Nginx (`web`). |

* **Puertos cerrados:** El puerto `80` (HTTP sin cifrar), el puerto `3306` (MariaDB) y los puertos `8080` de las cinco APIs no están publicados ni abiertos en el Security Group. En las pruebas de navegador se verifica que `http://32.194.87.233` no establece conexión y solo responde `https://32.194.87.233`.

### Reglas de Salida (Outbound Rules)

| Tipo | Protocolo | Rango de Puertos | Destino (Destination) | Propósito |
| :--- | :--- | :--- | :--- | :--- |
| All traffic | All | All | `0.0.0.0/0` | Permitir la descarga de paquetes del SO, imágenes desde Docker Hub y consultas HTTPS de `api-pagos` (tipo de cambio), `api-transacciones` (geolocalización) y alertas de `web2` (Telegram). |

![Configuración del Security Group durante la creación](docs/img/aws-sg-creacion.png)

![Reglas de entrada del Security Group en la consola](docs/img/aws-sg-inbound.png)
---

## 3. Publicación de Imágenes en Docker Hub

Antes del despliegue en EC2, las ocho imágenes fueron construidas localmente desde la raíz del proyecto mediante `build.ps1` y publicadas en los repositorios públicos de Docker Hub bajo el usuario `yisvs9` (versión `1.0.2`), permitiendo que la instancia EC2 ejecute únicamente `docker compose pull` sin compilar código en el servidor:

```powershell
.\build.ps1 -DockerUser yisvs9
```

![Repositorios publicados en Docker Hub](docs/img/04-dockerhub-repos.png)

![Push de las ocho imágenes desde PowerShell](docs/img/04b-dockerhub-push.png)

---

## 4. Conexión SSH y Transferencia de Secretos

### Acceso a la instancia

La conexión se realiza mediante el cliente OpenSSH utilizando el usuario por defecto de Amazon Linux 2023 (`ec2-user`) y la clave privada descargada al crear la instancia, con permisos restringidos a `600` (`chmod 600 ~/.ssh/keydevops.pem`):

```bash
ssh -i ~/.ssh/keydevops.pem ec2-user@32.194.87.233
```

Una vez dentro de la instancia, se verificaron los grupos del usuario y la versión exacta del sistema operativo mediante `groups` y `cat /etc/os-release`.

![Conexión SSH a Amazon Linux 2023](docs/img/05-aws-ssh-conexion.png)

### Transferencia de configuración fuera de Git

Para no subir archivos `.env` ni configuraciones sensibles al repositorio Git, desde la máquina local se ejecutó el script `transferir.sh`:

```bash
./transferir.sh 32.194.87.233
```

Este script realiza tres tareas por `ssh`/`scp`:
1. Crea en `/home/ec2-user` los directorios `db`, `api-clientes`, `api-pagos`, `api-facturas`, `api-transacciones`, `api-tarjetas`, `web2` y `certs`.
2. Transfiere `deploy.sh`, `docker-compose.yml`, los seis archivos `.env` de cada servicio y `web2/config.yaml`.
3. Guarda la IP pública en `.deploy-public-ip` y restringe los permisos de los archivos `.env` a `600` (ajustando `web2/config.yaml` a `644` para permitir su lectura por parte del contenedor del monitor).

![Ejecución de transferir.sh y archivos en EC2](docs/img/06-aws-transferencia.png)

---

## 5. Preparación de la Instancia y Despliegue (`deploy.sh`)

En la sesión SSH dentro de la instancia EC2 se ejecutó el script automatizado de aprovisionamiento y despliegue:

```bash
cd ~
./deploy.sh
```

El script configuró la instancia desde cero ejecutando cinco etapas:
1. **Validación de archivos (`[1/5]`):** Verifica que existan y no estén vacíos `docker-compose.yml`, los seis `.env`, `web2/config.yaml`, el directorio `certs/` y `.deploy-public-ip`.
2. **Instalación de dependencias (`[2/5]`):**
   * Verifica la presencia de `curl` (provisto por `curl-minimal` en AL2023) y `openssl`.
   * Instala el motor de Docker desde los repositorios oficiales de Amazon Linux (`sudo dnf install -y docker`, instalando `docker-25.0.16`) y habilita el servicio con `sudo systemctl enable --now docker`.
   * Descarga e instala el binario oficial del plugin **Docker Compose `v5.6.0`** en `/usr/local/lib/docker/cli-plugins/docker-compose`.
3. **Generación del certificado TLS autofirmado (`[3/5]`):** Genera en runtime dentro de la EC2 el par `certs/key.pem` (permisos `600`) y `certs/cert.pem` con `openssl req -x509`, incluyendo `CN=32.194.87.233` y `subjectAltName=IP:32.194.87.233,DNS:localhost,IP:127.0.0.1`, los cuales se montan como solo lectura (`:ro`) en el contenedor `web`.
4. **Descarga y orquestación (`[4/5]`):** Valida el archivo Compose (`docker compose config --quiet`), descarga las ocho imágenes públicas desde Docker Hub (`docker compose pull` — sin requerir `docker login` en la EC2 por ser repositorios públicos) y levanta el stack en segundo plano (`docker compose up -d`).
5. **Verificación de endpoints (`[5/5]`):** Realiza peticiones `curl --insecure` contra las siete rutas expuestas por HTTPS (`/`, `/api/clientes`, `/api/pagos`, `/api/facturas`, `/api/transacciones`, `/api/tarjetas` y `/monitor/`) hasta confirmar respuesta `HTTP 200` en todas ellas.

![Ejecución de deploy.sh y estado de los contenedores](docs/img/07-aws-deploy-sh.png)

---

## 6. Verificación de Funcionamiento desde el Exterior

Con el despliegue finalizado, se probó el acceso desde el exterior contra la IP pública `32.194.87.233`:

1. **Pruebas por terminal (`curl`):** Se verificaron las respuestas HTTP 200 y las cargas útiles JSON de las cinco APIs y de ambos frontends a través del proxy inverso Nginx.
2. **Validación HTTPS y Certificado Autofirmado:** Al ingresar a `https://32.194.87.233/` desde el navegador, se presenta la advertencia esperada por tratarse de un certificado autofirmado (`MOZILLA_PKIX_ERROR_SELF_SIGNED_CERT`), tras lo cual carga la interfaz principal.
3. **ABM en Frontend Principal (`web`) y Monitor (`web2`):** Se verificó la operatoria completa de alta, edición, consulta y baja en los 5 módulos, así como el panel de monitoreo en `https://32.194.87.233/monitor/` junto con las alertas en tiempo real vía Telegram ante la caída y recuperación de un microservicio.

![Pruebas curl contra los endpoints públicos](docs/img/08-aws-curl-validacion.png)

![Advertencia de certificado autofirmado y ABM en Web 1](docs/img/09-aws-navegador-web1.png)

![Monitor Web 2 y notificaciones por Telegram](docs/img/10-aws-navegador-web2.png)