param (
    [Parameter(Mandatory=$true, HelpMessage="Nombre de usuario de Docker Hub")]
    [string]$DockerUser
)

Write-Host "=== Logueando en Docker Hub ===" -ForegroundColor Cyan
docker login
if ($LASTEXITCODE -ne 0) {
    Write-Host "Fallo el inicio de sesión en Docker Hub." -ForegroundColor Red
    exit $LASTEXITCODE
}

Write-Host "=== Construyendo imágenes ===" -ForegroundColor Cyan
docker build -t "$DockerUser/fintech-nova-db:1.0.2" -f db/Dockerfile .
docker build -t "$DockerUser/fintech-nova-api-clientes:1.0.2" -f api-clientes/Dockerfile .
docker build -t "$DockerUser/fintech-nova-api-pagos:1.0.2" -f api-pagos/Dockerfile .
docker build -t "$DockerUser/fintech-nova-api-facturas:1.0.2" -f api-facturas/Dockerfile .
docker build -t "$DockerUser/fintech-nova-api-transacciones:1.0.2" -f api-transacciones/Dockerfile .
docker build -t "$DockerUser/fintech-nova-api-tarjetas:1.0.2" -f api-tarjetas/Dockerfile .
docker build -t "$DockerUser/fintech-nova-web:1.0.2" -f web/Dockerfile .
docker build -t "$DockerUser/fintech-nova-web2:1.0.2" -f web2/Dockerfile web2

Write-Host "=== Subiendo imágenes a Docker Hub ===" -ForegroundColor Cyan
docker push "$DockerUser/fintech-nova-db:1.0.2"
docker push "$DockerUser/fintech-nova-api-clientes:1.0.2"
docker push "$DockerUser/fintech-nova-api-pagos:1.0.2"
docker push "$DockerUser/fintech-nova-api-facturas:1.0.2"
docker push "$DockerUser/fintech-nova-api-transacciones:1.0.2"
docker push "$DockerUser/fintech-nova-api-tarjetas:1.0.2"
docker push "$DockerUser/fintech-nova-web:1.0.2"
docker push "$DockerUser/fintech-nova-web2:1.0.2"

Write-Host "=== Proceso finalizado ===" -ForegroundColor Green
Write-Host "Recuerda actualizar tu docker-compose.yml con las imágenes, ejemplo:"
Write-Host "image: $DockerUser/fintech-nova-db:1.0.2" -ForegroundColor Yellow
