param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$IpPublica
)

# Ejecutar desde la raiz del proyecto en PowerShell: .\transferir.ps1 <IP_PUBLICA_EC2>
$ErrorActionPreference = 'Stop'
$EC2_USER = 'ec2-user'
$SSH_KEY = Join-Path $HOME '.ssh/keydevops.pem'
$DESTINO = "${EC2_USER}@${IpPublica}"

$partes = $IpPublica.Split('.')
if ($IpPublica -notmatch '^(?:[0-9]{1,3}\.){3}[0-9]{1,3}$' -or
    @($partes | Where-Object { [int]$_ -gt 255 }).Count -gt 0) {
    throw 'La IP debe ser una direccion IPv4 valida.'
}

if (-not (Test-Path -LiteralPath 'deploy.sh' -PathType Leaf) -or
    -not (Test-Path -LiteralPath 'docker-compose.yml' -PathType Leaf)) {
    throw 'Ejecuta este script desde la raiz del proyecto.'
}

if (-not (Test-Path -LiteralPath $SSH_KEY -PathType Leaf)) {
    throw "No existe la llave SSH en $SSH_KEY"
}

foreach ($comando in @('ssh', 'scp')) {
    if (-not (Get-Command $comando -ErrorAction SilentlyContinue)) {
        throw "Falta el comando $comando."
    }
}

$archivos = @(
    'db/.env',
    'api-clientes/.env',
    'api-pagos/.env',
    'api-facturas/.env',
    'api-transacciones/.env',
    'api-tarjetas/.env',
    'web2/config.yaml'
)

foreach ($archivo in $archivos) {
    if (-not (Test-Path -LiteralPath $archivo -PathType Leaf) -or
        (Get-Item -LiteralPath $archivo).Length -eq 0) {
        throw "Falta o esta vacio $archivo. No se transfirio nada."
    }
}

Write-Host "[1/3] Creando carpetas en $DESTINO"
# Los .env contienen secretos; config.yaml solo describe rutas y debe ser legible por el usuario app de Web2.
$crearCarpetas = 'umask 077; mkdir -p db api-clientes api-pagos api-facturas api-transacciones api-tarjetas web2 certs; touch db/.env api-clientes/.env api-pagos/.env api-facturas/.env api-transacciones/.env api-tarjetas/.env web2/config.yaml; chmod 600 db/.env api-clientes/.env api-pagos/.env api-facturas/.env api-transacciones/.env api-tarjetas/.env; chmod 644 web2/config.yaml'
& ssh -i $SSH_KEY $DESTINO $crearCarpetas
if ($LASTEXITCODE -ne 0) { throw 'No se pudieron crear las carpetas en EC2.' }

Write-Host '[2/3] Transfiriendo Compose, deploy y configuraciones privadas'
& scp -i $SSH_KEY 'deploy.sh' 'docker-compose.yml' "${DESTINO}:~/"
if ($LASTEXITCODE -ne 0) { throw 'Fallo la transferencia de deploy.sh o docker-compose.yml.' }

foreach ($archivo in $archivos) {
    & scp -i $SSH_KEY $archivo "${DESTINO}:~/$archivo"
    if ($LASTEXITCODE -ne 0) { throw "Fallo la transferencia de $archivo." }
}

Write-Host '[3/3] Guardando la IP publica y ajustando permisos en EC2'
$ajustarPermisos = "umask 077; printf '%s\n' '$IpPublica' > .deploy-public-ip; chmod 600 .deploy-public-ip db/.env api-clientes/.env api-pagos/.env api-facturas/.env api-transacciones/.env api-tarjetas/.env; chmod 644 web2/config.yaml"
& ssh -i $SSH_KEY $DESTINO $ajustarPermisos
if ($LASTEXITCODE -ne 0) { throw 'No se pudo guardar la IP o ajustar permisos en EC2.' }

Write-Host 'Transferencia completa. En EC2: cd ~ && bash ./deploy.sh' -ForegroundColor Green
