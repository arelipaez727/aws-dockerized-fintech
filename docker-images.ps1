# ==============================================================================
# Fintech Nova - Script de Gestión de Imágenes Docker Hub (PowerShell)
# Usuario Docker Hub: octaviobenjamin
# ==============================================================================

param(
    [Parameter(Position=0)]
    [ValidateSet("build", "crear", "pull", "bajar", "push", "subir", "all", "todo", "list", "listar", "help", "menu")]
    [string]$Action = "menu"
)

$DockerUser = "octaviobenjamin"

$Services = @(
    @{ Name = "db"; Dockerfile = "db/Dockerfile"; Context = "."; HubTag = "$DockerUser/db:1.0.0"; LocalTag = "fintech-nova-db:1.0.0"; FallbackTag = "" },
    @{ Name = "api-clientes"; Dockerfile = "api-clientes/Dockerfile"; Context = "."; HubTag = "$DockerUser/api-clientes:1.0.0"; LocalTag = "fintech-nova-api-clientes:1.0.0"; FallbackTag = "" },
    @{ Name = "api-pagos"; Dockerfile = "api-pagos/Dockerfile"; Context = "."; HubTag = "$DockerUser/api-pagos:1.0.0"; LocalTag = "fintech-nova-api-pagos:1.0.0"; FallbackTag = "" },
    @{ Name = "api-facturas"; Dockerfile = "api-facturas/Dockerfile"; Context = "."; HubTag = "$DockerUser/api-facturas:1.0.1"; LocalTag = "fintech-nova-api-facturas:1.0.1"; FallbackTag = "$DockerUser/api-facturas:1.0.0" },
    @{ Name = "api-transacciones"; Dockerfile = "api-transacciones/Dockerfile"; Context = "."; HubTag = "$DockerUser/api-transacciones:1.0.0"; LocalTag = "fintech-nova-api-transacciones:1.0.0"; FallbackTag = "" },
    @{ Name = "api-tarjetas"; Dockerfile = "api-tarjetas/Dockerfile"; Context = "."; HubTag = "$DockerUser/api-tarjetas:1.0.0"; LocalTag = "fintech-nova-api-tarjetas:1.0.0"; FallbackTag = "" },
    @{ Name = "web"; Dockerfile = "web/Dockerfile"; Context = "."; HubTag = "$DockerUser/web:1.0.1"; LocalTag = "fintech-nova-web:1.0.1"; FallbackTag = "$DockerUser/web:1.0.0" },
    @{ Name = "web2"; Dockerfile = "web2/Dockerfile"; Context = "web2"; HubTag = "$DockerUser/web2:1.0.0"; LocalTag = "octaviobenjamin/web2:1.0.0"; FallbackTag = "" }
)

function Build-Images {
    Write-Host "`n=== CREANDO (BUILD) TODAS LAS IMÁGENES DOCKER ===" -ForegroundColor Cyan
    Write-Host "Namespace: $DockerUser`n" -ForegroundColor Gray

    foreach ($svc in $Services) {
        Write-Host "▶ Construyendo servicio: " -NoNewline -ForegroundColor Blue
        Write-Host $svc.Name -ForegroundColor White
        Write-Host "  Dockerfile: $($svc.Dockerfile) | Contexto: $($svc.Context)" -ForegroundColor Gray

        if ($svc.HubTag -eq $svc.LocalTag) {
            docker build -t $svc.HubTag -f $svc.Dockerfile $svc.Context
        } else {
            docker build -t $svc.HubTag -t $svc.LocalTag -f $svc.Dockerfile $svc.Context
        }

        if ($svc.FallbackTag) {
            docker tag $svc.HubTag $svc.FallbackTag
            Write-Host "  ✔ Tag secundario: $($svc.FallbackTag)" -ForegroundColor Green
        }

        Write-Host "  ✔ Creada: $($svc.HubTag)`n" -ForegroundColor Green
    }
}

function Push-Images {
    Write-Host "`n=== SUBIENDO (PUSH) IMÁGENES A DOCKER HUB ($DockerUser) ===" -ForegroundColor Cyan
    Write-Host "Asegurate de haber iniciado sesión con 'docker login'`n" -ForegroundColor Yellow

    foreach ($svc in $Services) {
        Write-Host "▶ Subiendo: $($svc.HubTag)" -ForegroundColor Blue
        docker push $svc.HubTag
        if ($svc.FallbackTag) {
            docker push $svc.FallbackTag
        }
        Write-Host ""
    }
}

function Pull-Images {
    Write-Host "`n=== BAJANDO (PULL) IMÁGENES DESDE DOCKER HUB ($DockerUser) ===" -ForegroundColor Cyan

    foreach ($svc in $Services) {
        Write-Host "▶ Bajando: $($svc.HubTag)" -ForegroundColor Blue
        docker pull $svc.HubTag
        if ($LASTEXITCODE -ne 0 -and $svc.FallbackTag) {
            Write-Host "  Tag $($svc.HubTag) no encontrado, intentando fallback $($svc.FallbackTag)..." -ForegroundColor Yellow
            docker pull $svc.FallbackTag
            docker tag $svc.FallbackTag $svc.HubTag
        }

        if ($svc.HubTag -ne $svc.LocalTag) {
            docker tag $svc.HubTag $svc.LocalTag
            Write-Host "  ✔ Etiquetada para Compose: $($svc.LocalTag)" -ForegroundColor Green
        }
        Write-Host ""
    }
}

function List-Images {
    Write-Host "`n=== IMÁGENES LOCALES ($DockerUser / fintech-nova) ===" -ForegroundColor Cyan
    docker images --filter "reference=$DockerUser/*" --filter "reference=fintech-nova-*"
    Write-Host ""
}

function Show-Help {
    Write-Host "Uso: .\docker-images.ps1 [Action]`n" -ForegroundColor White
    Write-Host "Acciones disponibles:"
    Write-Host "  build | crear   - Compila y crea las 8 imágenes locales"
    Write-Host "  pull  | bajar   - Descarga las imágenes desde Docker Hub"
    Write-Host "  push  | subir   - Sube las imágenes a Docker Hub"
    Write-Host "  all   | todo    - Build -> Push -> Pull"
    Write-Host "  list  | listar  - Muestra las imágenes locales"
    Write-Host "  help            - Muestra esta ayuda`n"
}

switch ($Action) {
    { $_ -in "build", "crear" } { Build-Images }
    { $_ -in "pull", "bajar" }  { Pull-Images }
    { $_ -in "push", "subir" }  { Push-Images }
    { $_ -in "all", "todo" }    { Build-Images; Push-Images; Pull-Images }
    { $_ -in "list", "listar" } { List-Images }
    { $_ -in "help" }           { Show-Help }
    default {
        Write-Host "`n=== GESTOR DE IMÁGENES DOCKER HUB ($DockerUser) ===" -ForegroundColor Cyan
        Write-Host "1) Crear (Build) todas las imágenes"
        Write-Host "2) Bajar (Pull) todas las imágenes de Docker Hub"
        Write-Host "3) Subir (Push) todas las imágenes a Docker Hub"
        Write-Host "4) Todo (Build -> Push -> Pull)"
        Write-Host "5) Listar imágenes locales"
        Write-Host "6) Salir`n"
        $opc = Read-Host "Selecciona una opción [1-6]"
        switch ($opc) {
            "1" { Build-Images }
            "2" { Pull-Images }
            "3" { Push-Images }
            "4" { Build-Images; Push-Images; Pull-Images }
            "5" { List-Images }
            default { Write-Host "Saliendo." }
        }
    }
}
