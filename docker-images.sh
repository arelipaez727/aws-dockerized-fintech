#!/usr/bin/env bash
# ==============================================================================
# Fintech Nova - Script de Gestión de Imágenes Docker Hub
# Usuario Docker Hub: octaviobenjamin
# ==============================================================================

set -o pipefail

# Colores para la terminal
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # Sin color

DOCKER_USER="octaviobenjamin"

# Definición de los 8 servicios del proyecto:
# Formato: "nombre_servicio|dockerfile|contexto|tag_hub|tag_local|tag_fallback"
SERVICES=(
    "db|db/Dockerfile|.|${DOCKER_USER}/db:1.0.0|fintech-nova-db:1.0.0|"
    "api-clientes|api-clientes/Dockerfile|.|${DOCKER_USER}/api-clientes:1.0.0|fintech-nova-api-clientes:1.0.0|"
    "api-pagos|api-pagos/Dockerfile|.|${DOCKER_USER}/api-pagos:1.0.0|fintech-nova-api-pagos:1.0.0|"
    "api-facturas|api-facturas/Dockerfile|.|${DOCKER_USER}/api-facturas:1.0.1|fintech-nova-api-facturas:1.0.1|${DOCKER_USER}/api-facturas:1.0.0"
    "api-transacciones|api-transacciones/Dockerfile|.|${DOCKER_USER}/api-transacciones:1.0.0|fintech-nova-api-transacciones:1.0.0|"
    "api-tarjetas|api-tarjetas/Dockerfile|.|${DOCKER_USER}/api-tarjetas:1.0.0|fintech-nova-api-tarjetas:1.0.0|"
    "web|web/Dockerfile|.|${DOCKER_USER}/web:1.0.1|fintech-nova-web:1.0.1|${DOCKER_USER}/web:1.0.0"
    "web2|web2/Dockerfile|web2|${DOCKER_USER}/web2:1.0.0|octaviobenjamin/web2:1.0.0|"
)

# Detectar comando docker (con o sin sudo según permisos locales)
detect_docker() {
    if docker info >/dev/null 2>&1; then
        DOCKER_CMD="docker"
    elif sudo -n docker info >/dev/null 2>&1; then
        DOCKER_CMD="sudo docker"
    else
        DOCKER_CMD="sudo docker"
    fi
}

# 1. Crear (Build) todas las imágenes
build_images() {
    echo -e "\n${CYAN}${BOLD}=== CREANDO (BUILD) TODAS LAS IMÁGENES DOCKER ===${NC}"
    echo -e "Namespace objetivo: ${BOLD}${DOCKER_USER}${NC}\n"

    for entry in "${SERVICES[@]}"; do
        IFS="|" read -r name dockerfile context hub_tag local_tag fallback_tag <<< "$entry"

        echo -e "${BLUE}▶ Construyendo servicio:${NC} ${BOLD}${name}${NC}"
        echo -e "  Dockerfile: ${dockerfile} | Contexto: ${context}"

        # Construir y etiquetar tanto con el tag de Docker Hub como con el tag local
        if [ "$hub_tag" = "$local_tag" ]; then
            $DOCKER_CMD build -t "$hub_tag" -f "$dockerfile" "$context"
        else
            $DOCKER_CMD build -t "$hub_tag" -t "$local_tag" -f "$dockerfile" "$context"
        fi

        # Si tiene tag fallback (ej. 1.0.0 para facturas o web), etiquetar también
        if [ -n "$fallback_tag" ]; then
            $DOCKER_CMD tag "$hub_tag" "$fallback_tag"
            echo -e "  ${GREEN}✔${NC} Etiqueta adicional creada: ${fallback_tag}"
        fi

        echo -e "  ${GREEN}✔ Imagen creada exitosamente:${NC} ${hub_tag}\n"
    done

    echo -e "${GREEN}${BOLD}✔ Todas las 8 imágenes fueron creadas y etiquetadas localmente.${NC}\n"
}

# 2. Subir (Push) todas las imágenes a Docker Hub
push_images() {
    echo -e "\n${CYAN}${BOLD}=== SUBIENDO (PUSH) IMÁGENES A DOCKER HUB (${DOCKER_USER}) ===${NC}\n"

    # Verificar sesión en Docker Hub
    echo -e "${YELLOW}Verificando inicio de sesión en Docker Hub...${NC}"
    echo -e "Si no estás autenticado, ejecutá previamente: ${BOLD}docker login${NC}\n"

    for entry in "${SERVICES[@]}"; do
        IFS="|" read -r name dockerfile context hub_tag local_tag fallback_tag <<< "$entry"

        echo -e "${BLUE}▶ Subiendo imagen:${NC} ${BOLD}${hub_tag}${NC}"
        if $DOCKER_CMD push "$hub_tag"; then
            echo -e "  ${GREEN}✔ Subida exitosa:${NC} ${hub_tag}\n"
        else
            echo -e "  ${RED}✖ Error al subir:${NC} ${hub_tag}"
            echo -e "  Asegurate de haber iniciado sesión con '${BOLD}docker login -u ${DOCKER_USER}${NC}'\n"
        fi

        # Subir también tag secundario si existe
        if [ -n "$fallback_tag" ]; then
            echo -e "${BLUE}▶ Subiendo tag adicional:${NC} ${BOLD}${fallback_tag}${NC}"
            $DOCKER_CMD push "$fallback_tag" || true
        fi
    done

    echo -e "${GREEN}${BOLD}✔ Proceso de subida (push) finalizado.${NC}\n"
}

# 3. Bajar (Pull) todas las imágenes desde Docker Hub
pull_images() {
    echo -e "\n${CYAN}${BOLD}=== BAJANDO (PULL) IMÁGENES DESDE DOCKER HUB (${DOCKER_USER}) ===${NC}\n"

    for entry in "${SERVICES[@]}"; do
        IFS="|" read -r name dockerfile context hub_tag local_tag fallback_tag <<< "$entry"

        echo -e "${BLUE}▶ Bajando imagen:${NC} ${BOLD}${hub_tag}${NC}"
        if $DOCKER_CMD pull "$hub_tag"; then
            echo -e "  ${GREEN}✔ Descargada exitosamente:${NC} ${hub_tag}"
        elif [ -n "$fallback_tag" ]; then
            echo -e "  ${YELLOW}⚠ Tag ${hub_tag} no encontrado en Hub. Intentando fallback:${NC} ${fallback_tag}"
            if $DOCKER_CMD pull "$fallback_tag"; then
                $DOCKER_CMD tag "$fallback_tag" "$hub_tag"
                echo -e "  ${GREEN}✔ Fallback descargado y re-etiquetado a:${NC} ${hub_tag}"
            else
                echo -e "  ${RED}✖ No se pudo descargar ni ${hub_tag} ni ${fallback_tag}${NC}"
            fi
        else
            echo -e "  ${RED}✖ Falló la descarga de:${NC} ${hub_tag}"
        fi

        # Asegurar que el tag local para docker-compose.yml esté disponible
        if [ "$hub_tag" != "$local_tag" ]; then
            $DOCKER_CMD tag "$hub_tag" "$local_tag" 2>/dev/null || true
            echo -e "  ${GREEN}✔${NC} Etiquetada para Compose: ${local_tag}"
        fi
        echo ""
    done

    echo -e "${GREEN}${BOLD}✔ Proceso de descarga (pull) completado.${NC}\n"
}

# Listar el estado actual de las imágenes locales
list_images() {
    echo -e "\n${CYAN}${BOLD}=== IMÁGENES LOCALES DE FINTECH NOVA / ${DOCKER_USER} ===${NC}\n"
    $DOCKER_CMD images --filter "reference=${DOCKER_USER}/*" --filter "reference=fintech-nova-*"
    echo ""
}

# Menú de ayuda
show_help() {
    echo -e "${BOLD}Uso:${NC} $0 [comando]"
    echo ""
    echo -e "${BOLD}Comandos disponibles:${NC}"
    echo -e "  ${GREEN}build${NC} | ${GREEN}crear${NC}        Compila y crea las 8 imágenes Docker locales"
    echo -e "  ${GREEN}pull${NC}  | ${GREEN}bajar${NC}        Descarga (pull) todas las imágenes desde Docker Hub (${DOCKER_USER})"
    echo -e "  ${GREEN}push${NC}  | ${GREEN}subir${NC}        Sube (push) todas las imágenes creadas a Docker Hub"
    echo -e "  ${GREEN}all${NC}   | ${GREEN}todo${NC}         Ejecuta el flujo completo: Build -> Push -> Pull"
    echo -e "  ${GREEN}list${NC}  | ${GREEN}listar${NC}       Muestra las imágenes locales existentes"
    echo -e "  ${GREEN}help${NC}  | ${GREEN}--help${NC}       Muestra esta ayuda"
    echo ""
}

# Menú interactivo si no se pasaron argumentos
interactive_menu() {
    clear 2>/dev/null || true
    echo -e "${CYAN}${BOLD}======================================================${NC}"
    echo -e "${CYAN}${BOLD}  FINTECH NOVA - GESTOR DE IMÁGENES DOCKER HUB (${DOCKER_USER})  ${NC}"
    echo -e "${CYAN}${BOLD}======================================================${NC}"
    echo -e "Selecciona una opción:"
    echo -e "  ${BOLD}1)${NC} ${GREEN}Crear (Build)${NC} todas las imágenes"
    echo -e "  ${BOLD}2)${NC} ${CYAN}Bajar (Pull)${NC} todas las imágenes desde Docker Hub"
    echo -e "  ${BOLD}3)${NC} ${YELLOW}Subir (Push)${NC} todas las imágenes a Docker Hub"
    echo -e "  ${BOLD}4)${NC} ${BLUE}Crear y Bajar${NC} (Build local + Re-etiquetado)"
    echo -e "  ${BOLD}5)${NC} ${BOLD}Todo${NC} (Build -> Push -> Pull)"
    echo -e "  ${BOLD}6)${NC} Listar imágenes locales actuales"
    echo -e "  ${BOLD}7)${NC} Salir"
    echo ""
    read -rp "Opción [1-7]: " opcion

    case "$opcion" in
        1) build_images ;;
        2) pull_images ;;
        3) push_images ;;
        4) build_images; pull_images ;;
        5) build_images; push_images; pull_images ;;
        6) list_images ;;
        7) echo "Saliendo."; exit 0 ;;
        *) echo -e "${RED}Opción no válida.${NC}"; exit 1 ;;
    esac
}

# Punto de entrada principal
main() {
    detect_docker

    if [ $# -eq 0 ]; then
        if [ -t 0 ]; then
            interactive_menu
        else
            show_help
        fi
        exit 0
    fi

    case "$1" in
        build|crear)
            build_images
            ;;
        pull|bajar)
            pull_images
            ;;
        push|subir)
            push_images
            ;;
        all|todo)
            build_images
            push_images
            pull_images
            ;;
        list|listar)
            list_images
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            echo -e "${RED}Error: Comando desconocido '$1'${NC}\n"
            show_help
            exit 1
            ;;
    esac
}

main "$@"
