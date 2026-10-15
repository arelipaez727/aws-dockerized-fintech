# Configuración de AWS EC2

## 1. Datos de la Instancia, Sistema Operativo y Red (VPC / Subred)

Los siguientes datos corresponden a la sesión del Sandbox de AWS Academy Learner Lab en la que se desplegó y probó el stack completo:

| Parámetro | Valor |
| :--- | :--- |
| **Nombre de la instancia** | `TPDevOps` |
| **Instance ID** | `i-0ba2aa2bb9f68cf1a` |
| **Tipo de instancia** | `t3.medium` (2 vCPU, 4 GiB RAM) |
| **Sistema Operativo / AMI** | Amazon Linux 2023 (`2023.12.20261013.0`) |
| **Descripción de la AMI** | Amazon Linux 2023 AMI `2023.12.20261013.0`, `x86_64`, kernel `6.18` |
| **AMI ID** | `ami-004d1eaf8eaa0107d` |
| **Arquitectura** | `x86_64` (64-bit) |
| **IP Pública (IPv4)** | `52.200.213.71` |
| **DNS Público (IPv4)** | `ec2-52-200-213-71.compute-1.amazonaws.com` |
| **IP Privada (IPv4)** | `172.31.17.255` |
| **Región / Zona de Disponibilidad** | `us-east-1` (N. Virginia) / `us-east-1c` |
| **VPC ID** | `vpc-080514a8c391170e3` |
| **Subnet ID** | `subnet-0bad929645ac54ce0` |

![Resumen de la instancia EC2](docs/img/aws-ec2-detalle.png)

![AMI y tipo de instancia seleccionados](docs/img/aws-ami-instancia.png)

![VPC, subred y zona de disponibilidad de la instancia](docs/img/aws-ec2-red.png)

---

## 2. Security Group (Reglas de Entrada y de Salida)

La instancia utiliza el Security Group **`launch-wizard-1`** asociado a la VPC `vpc-080514a8c391170e3`.

### Reglas de Entrada (Inbound Rules)

| Security Group Rule ID | Tipo | Protocolo | Puerto | Origen (Source) | Descripción |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `sgr-0710754862cb5c832` | SSH | TCP | `22` | `190.16.218.36/32` | Acceso SSH restringido exclusivamente a la IP del equipo (`My IP`). |
| `sgr-0b9f57dbf8ed1e8e9` | HTTPS | TCP | `443` | `0.0.0.0/0` | Acceso público HTTPS hacia el proxy inverso Nginx (`web`). |

- **Puertos cerrados:** El puerto `80` (HTTP) no se encuentra abierto ni publicado. Los puertos internos `3306` (MariaDB), `8080` (APIs) y `8081` (`web2`) tampoco están expuestos en el Security Group y solo son alcanzables dentro de la red interna `app_net` de Docker.

### Reglas de Salida (Outbound Rules)

| Tipo | Protocolo | Puerto | Destino (Destination) | Descripción |
| :--- | :--- | :--- | :--- | :--- |
| All traffic | All | All | `0.0.0.0/0` | Permite descargar paquetes del sistema e imágenes de Docker Hub y consultar por HTTPS las APIs externas de tipo de cambio y geolocalización. |

![Configuración del Security Group durante la creación](docs/img/aws-sg-creacion.png)

![Reglas de entrada y salida del Security Group en la consola](docs/img/aws-sg-inbound.png)

---

## 3. Conexión a la Instancia EC2

La conexión se realizó desde PowerShell por **SSH** utilizando el usuario por defecto de Amazon Linux 2023 (`ec2-user`) y la clave privada `keydevops.pem` guardada en `$HOME\.ssh`:

```powershell
ssh -i "$HOME\.ssh\keydevops.pem" ec2-user@52.200.213.71
```

![Conexión SSH a Amazon Linux 2023](docs/img/05-aws-ssh-conexion.png)

---

## 4. Configuración Previa en la Instancia Antes de Levantar los Contenedores

Antes de iniciar los contenedores con Docker Compose, la preparación de la instancia se ejecutó mediante los scripts automatizados del proyecto en dos etapas:

### 4.1. Preparación de directorios y archivos de configuración (`transferir.sh` / `transferir.ps1`)
Desde la computadora local se ejecutó `.\transferir.ps1 52.200.213.71`, el cual configuró en `/home/ec2-user`:
1. Creación de los directorios `db/`, `api-clientes/`, `api-pagos/`, `api-facturas/`, `api-transacciones/`, `api-tarjetas/`, `web2/` y `certs/`.
2. Copia por `scp` de `deploy.sh`, `docker-compose.yml`, los seis archivos `.env` de credenciales y `web2/config.yaml`.
3. Registro de la IP pública en `.deploy-public-ip` y aplicación de permisos `600` sobre los archivos `.env` y `644` sobre `web2/config.yaml`.

### 4.2. Instalación de paquetes y certificado en la EC2 (`deploy.sh`)
Dentro de la instancia se ejecutó `bash ./deploy.sh`, que configuró automáticamente:
1. **Dependencias base:** Comprobación de `curl` (provisto por `curl-minimal` en Amazon Linux 2023) e instalación de `openssl` si no estuviera presente.
2. **Motor de Docker:** Instalación del paquete `docker` mediante `sudo dnf install -y docker` y activación del servicio con `sudo systemctl enable --now docker`.
3. **Plugin de Docker Compose:** Descarga del binario oficial `v5.6.0` para arquitectura `x86_64` e instalación con permisos de ejecución en `/usr/local/lib/docker/cli-plugins/docker-compose`.
4. **Certificado TLS autofirmado:** Generación con `openssl req -x509` del certificado `certs/cert.pem` y la clave privada `certs/key.pem` (permisos `600`) con `CN=52.200.213.71` y `subjectAltName=IP:52.200.213.71,DNS:localhost,IP:127.0.0.1`.
5. **Descarga de imágenes sin `docker login`:** Como las ocho imágenes publicadas en Docker Hub (`yisvs9/fintech-nova-*`) son públicas, no fue necesario ejecutar `docker login` ni almacenar credenciales de Docker Hub en la instancia EC2; `deploy.sh` ejecutó directamente `sudo docker compose pull` y `sudo docker compose up -d`.
