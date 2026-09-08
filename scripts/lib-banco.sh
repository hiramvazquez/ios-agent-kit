#!/usr/bin/env bash
# Arnés común de los bancos de pruebas del kit (`verifica-puerta.sh`,
# `verifica-contexto.sh`).
#
# Por qué existe: el segundo banco nació copiando ~33 líneas del primero —el montaje
# temporal, el cuerpo de `repo()`, el cierre de `caso()` y el resumen entero—. Lo señaló un
# juez de aceptación, y con razón: el propio digest que este kit inyecta en cada turno dice
# «antes de escribir una función, busca si ya existe». Se escribió mientras se leía eso.
#
# No se carga solo: cada banco hace `. "$(dirname "$0")/lib-banco.sh"`.

# --- estado -------------------------------------------------------------------------------

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

FALLOS=0
ROJOS_ESPERADOS=0
TOTAL=0

# --- montaje ------------------------------------------------------------------------------

# repo_base <nombre> <kit_conf:si|no>
#
# Un repositorio git con un commit dentro y, si se pide, un `kit.conf`. Lo que cada banco
# necesite además —una firma, un `openspec/`, dependencias— lo añade él.
repo_base() {
    local nombre="$1" conf="$2"
    local r="$TMP/$nombre"
    mkdir -p "$r" || return 1
    (
        cd "$r" || exit 1
        git init -q .
        git config user.email t@t.t
        git config user.name t
        echo base > base.txt
        git add base.txt
        git commit -qm base
        [ "$conf" = "si" ] && echo 'verificaciones() { :; }' > kit.conf
        exit 0
    )
}

# --- aserciones ---------------------------------------------------------------------------

contiene() { case "$1" in *"$2"*) return 0 ;; *) return 1 ;; esac; }

# caso <resultado:0|1> <descripción> [motivo_si_es_fallo_conocido]
#
# El tercer argumento marca los casos que fallan porque lo que se está probando aún no está
# arreglado. Se cuentan aparte y se enseñan en cada corrida: un fallo conocido que se
# esconde deja de ser conocido.
caso() {
    local ok="$1" desc="$2" conocido="${3:-}"
    TOTAL=$((TOTAL+1))
    if [ "$ok" -eq 0 ]; then
        printf '  ✅ %s\n' "$desc"
    elif [ -n "$conocido" ]; then
        printf '  🔴 %s\n     %s\n' "$desc" "$conocido"
        ROJOS_ESPERADOS=$((ROJOS_ESPERADOS+1))
    else
        printf '  ❌ %s\n' "$desc"
        FALLOS=$((FALLOS+1))
    fi
}

# --- cierre -------------------------------------------------------------------------------

# resumen <etiqueta de lo probado> <cambio que cierra los rojos>
#
# El número de casos se CUENTA. Antes iba escrito a mano («los once casos») en el banco y
# repetido en `kit.conf`, y el mismo commit que lo escribió ya se contradecía con el README.
# Un censo a mano envejece en cuanto alguien añade un caso, y nadie se entera.
resumen() {
    local etiqueta="$1" cambio="${2:-}"
    echo
    if [ "$ROJOS_ESPERADOS" -gt 0 ]; then
        printf '🔴 %s de %s caso(s) en rojo por el fallo que este banco existe para fijar.\n' \
            "$ROJOS_ESPERADOS" "$TOTAL"
        [ -n "$cambio" ] && printf '   Se cierran con el cambio «%s».\n' "$cambio"
    fi
    if [ "$FALLOS" -gt 0 ]; then
        printf '❌ %s de %s caso(s) fallan por algo que NO estaba previsto — míralos.\n' \
            "$FALLOS" "$TOTAL"
    fi
    [ "$((FALLOS+ROJOS_ESPERADOS))" -eq 0 ] && printf '✅ %s cumple los %s casos.\n' "$etiqueta" "$TOTAL"
    return $(( FALLOS + ROJOS_ESPERADOS > 0 ? 1 : 0 ))
}
