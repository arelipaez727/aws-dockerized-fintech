param (
    [Parameter(Mandatory=$true, HelpMessage="Nombre de usuario de Docker Hub")]
    [string]$DockerUser
)

$ErrorActionPreference = 'Stop'

function Invoke-Docker {
    param([string[]]$DockerArgs)

    & docker @DockerArgs
    if ($LASTEXITCODE -ne 0) {
        throw "Fallo docker $($DockerArgs -join ' ') (codigo $LASTEXITCODE)."
    }
}

Write-Host "=== Logueando en Docker Hub ===" -ForegroundColor Cyan
Invoke-Docker -DockerArgs @('login')

$servicios = @(
    @{ Nombre = 'db'; Contexto = '.' }
    @{ Nombre = 'api-clientes'; Contexto = '.' }
    @{ Nombre = 'api-pagos'; Contexto = '.' }
    @{ Nombre = 'api-facturas'; Contexto = '.' }
    @{ Nombre = 'api-transacciones'; Contexto = '.' }
    @{ Nombre = 'api-tarjetas'; Contexto = '.' }
    @{ Nombre = 'web'; Contexto = '.' }
    @{ Nombre = 'web2'; Contexto = 'web2' }
)

Write-Host "=== Construyendo imágenes ===" -ForegroundColor Cyan
foreach ($servicio in $servicios) {
    $imagen = "$DockerUser/fintech-nova-$($servicio.Nombre):1.0.2"
    Write-Host "Construyendo $imagen" -ForegroundColor Yellow
    Invoke-Docker -DockerArgs @('build', '-t', $imagen, '-f', "$($servicio.Nombre)/Dockerfile", $servicio.Contexto)
}

Write-Host "=== Subiendo imágenes a Docker Hub ===" -ForegroundColor Cyan
foreach ($servicio in $servicios) {
    $imagen = "$DockerUser/fintech-nova-$($servicio.Nombre):1.0.2"
    Write-Host "Subiendo $imagen" -ForegroundColor Yellow
    Invoke-Docker -DockerArgs @('push', $imagen)
}

Write-Host "=== Ocho imágenes publicadas correctamente ===" -ForegroundColor Green
Write-Host "Comprueba que docker-compose.yml use el mismo namespace y tag 1.0.2."
