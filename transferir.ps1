param (
    [Parameter(Mandatory=$true)]
    [ValidateSet("--preparar", "--levantar")]
    [string]$Accion
)

# Configura aquí el usuario y la IP de la instancia EC2
$EC2_USER = "ubuntu"
$EC2_IP = "0.0.0.0"
$SSH_KEY = "ruta\a\tu\llave.pem"

switch ($Accion) {
    "--preparar" {
        Write-Host "=== Transfiriendo deploy.sh y docker-compose.yml al servidor ===" -ForegroundColor Cyan
        scp -i "$SSH_KEY" deploy.sh docker-compose.yml "${EC2_USER}@${EC2_IP}:~/"
        Write-Host "Archivos transferidos. Conéctate por SSH y ejecuta: ./deploy.sh --preparar" -ForegroundColor Green
    }
    "--levantar" {
        Write-Host "=== Transfiriendo los archivos .env y config.yaml al servidor ===" -ForegroundColor Cyan
        # db
        scp -i "$SSH_KEY" db\.env "${EC2_USER}@${EC2_IP}:~/db/.env"
        # apis
        scp -i "$SSH_KEY" api-clientes\.env "${EC2_USER}@${EC2_IP}:~/api-clientes/.env"
        scp -i "$SSH_KEY" api-pagos\.env "${EC2_USER}@${EC2_IP}:~/api-pagos/.env"
        scp -i "$SSH_KEY" api-facturas\.env "${EC2_USER}@${EC2_IP}:~/api-facturas/.env"
        scp -i "$SSH_KEY" api-transacciones\.env "${EC2_USER}@${EC2_IP}:~/api-transacciones/.env"
        scp -i "$SSH_KEY" api-tarjetas\.env "${EC2_USER}@${EC2_IP}:~/api-tarjetas/.env"
        # web2
        scp -i "$SSH_KEY" web2\config.yaml "${EC2_USER}@${EC2_IP}:~/web2/config.yaml"
        
        Write-Host "Secretos transferidos. Conéctate por SSH y ejecuta: ./deploy.sh --levantar" -ForegroundColor Green
    }
}
