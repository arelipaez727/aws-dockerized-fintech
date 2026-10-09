# FinTech Nova - Trabajo Práctico Grupo 10

## Despliegue en AWS EC2

Para desplegar la infraestructura en la instancia EC2, utilizamos dos scripts: `transferir.sh` (ejecutado localmente) y `deploy.sh` (ejecutado en el servidor). 

Antes de comenzar, asegúrate de editar las variables `EC2_USER`, `EC2_IP` y `SSH_KEY` dentro del archivo `transferir.sh` con los datos correspondientes a tu sesión de AWS Academy.

Sigue estos pasos en orden:

### 1. Preparar el servidor remoto
**En tu computadora local**, ejecuta el siguiente comando para enviar los archivos `deploy.sh` y `docker-compose.yml` al servidor:
```bash
./transferir.sh --preparar
```

### 2. Configurar dependencias e infraestructura
**Conectado al servidor EC2 por SSH**, ejecuta el script de despliegue para instalar Docker, crear las carpetas necesarias, generar el certificado SSL y descargar las imágenes desde Docker Hub:
```bash
./deploy.sh --preparar
```

### 3. Transferir configuraciones y secretos
**De vuelta en tu computadora local**, transfiere todos los archivos `.env` y el archivo `config.yaml` a las carpetas que acaba de crear el paso anterior en el servidor:
```bash
./transferir.sh --levantar
```

### 4. Validar archivos y levantar el stack
**Conectado nuevamente al servidor EC2 por SSH**, ejecuta el último paso para validar que todos los secretos estén en su lugar y poner en marcha los contenedores:
```bash
./deploy.sh --levantar
```
