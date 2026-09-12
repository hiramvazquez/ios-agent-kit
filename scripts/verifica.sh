#!/usr/bin/env bash
# Verifica el proyecto y FIRMA que la verificación corrió contra ESTE diff.
#
# El marker liga el resultado al sha256 del árbol de trabajo Y del índice: entre los dos está
# todo lo que un commit puede llevarse. Stagear después de firmar cambia el índice, y por tanto
# invalida la firma — por eso stagear, verificar y commitear van en comandos separados.
#
# Sin esto, "los tests pasan" es una afirmación sobre un árbol que pudo cambiar después de
# correrlos — el fallo de proceso más común y el que menos rastro deja.
#
# Los comandos concretos NO viven aquí: los pone cada proyecto en `kit.conf`. Este script
# es del kit y es igual en todos.
#
# LÍMITE DECLARADO: ese `kit.conf` se CARGA con `.`, así que verificar ejecuta código del
# repositorio en el que estés. Es la única forma de que cada proyecto declare sus propios
# pasos, y no se puede cerrar sin perder eso. En los repositorios de uno da igual; sobre un
# repositorio clonado de fuera, `kit.conf` es código que nadie ha leído.
#
# Uso:  verifica.sh              verifica y firma
#       verifica.sh --informe    imprime el último informe, sin volver a correr
#       verifica.sh --comprueba  ¿hay firma válida para este árbol? (exit 1 si no)
set -uo pipefail

# `$DIR` se resuelve ANTES del `cd`, igual que en el resto de scripts del kit: después, una
# invocación relativa desde un subdirectorio ya no encontraría la lib.
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
. "$DIR/lib-kit.sh"

RAIZ="$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "❌ no es un repo git"; exit 1; }
cd "$RAIZ" || exit 1

CONF="$RAIZ/kit.conf"
ESTADO="$RAIZ/.agent-kit"
MARKER="$ESTADO/verificacion.txt"
mkdir -p "$ESTADO"

case "${1:-}" in
--informe)
    [ -f "$MARKER" ] && cat "$MARKER" || echo "sin informe: nadie ha corrido verifica todavía"
    exit 0 ;;
--comprueba)
    # DOS condiciones, no una: la firma tiene que ser de este árbol Y de una verificación que
    # salió VERDE. Comprobando solo el árbol, tras una corrida en rojo el marker seguía ahí con
    # su línea `diff:` y esto respondía «firma válida» — la puerta que debe parar un cambio roto
    # lo dejaba pasar.
    [ -f "$MARKER" ] || { echo "❌ nada verificado todavía"; exit 1; }
    grep -q "^diff: $(huella_diff)$" "$MARKER" \
        || { echo "❌ la firma es de OTRO diff — vuelve a verificar"; exit 1; }
    grep -q "^resultado: verde$" "$MARKER" \
        || { echo "❌ la última verificación salió en ROJO — arréglalo y vuelve a verificar"; exit 1; }
    echo "✅ firma válida para este árbol"; exit 0
    ;;
esac

if [ ! -f "$CONF" ]; then
    cat >&2 <<'AYUDA'
❌ falta kit.conf en la raíz del proyecto.

   Es el ÚNICO fichero que el kit necesita que escribas. Define qué significa
   "verificado" aquí — build y tests de este proyecto — y dónde vive el código.

   Créalo con /kit-init, o copia plantillas/kit.conf.ejemplo del kit.
AYUDA
    exit 3   # "no pude mirar", que no es lo mismo que "está mal"
fi

# El árbol sucio ya no hace mentir a la firma —se firma el árbol, así que lo verificado y lo
# firmado son lo mismo—, pero sigue avisando por lo que queda: con cambios sin stagear se puede
# commitear un SUBCONJUNTO de lo verificado, y ese subconjunto no se ha probado solo.
#
# Avisa y lo DEJA ESCRITO en el informe; no bloquea. Quien tenga trabajo en curso aparte decide
# si lo guarda (`git stash -k`) o asume la diferencia, y el reviewer y el juez lo leen en
# `--informe`.
SUCIO="$(git diff --name-only 2>/dev/null)"

# ¿Estoy corriendo el kit que el proyecto cree que corre?
#
# Un plugin instalado NO se actualiza solo, y `claude plugin install` tampoco lo actualiza:
# hace falta `claude plugin marketplace update` y luego `claude plugin update`. Mientras tanto
# el proyecto corre una versión vieja sin que nada lo diga, y un arreglo publicado no protege a
# quien cree tenerlo. Pasó, y se descubrió de casualidad.
#
# No bloquea y no habla si no tiene nada que decir. La consulta al remoto es como mucho una vez
# al día y falla en silencio sin red.
DESFASE=""
_ver() { sed -n 's/.*"version": *"\([^"]*\)".*/\1/p' "$1" 2>/dev/null | head -1; }
MI_JSON="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/.claude-plugin/plugin.json"
if [ -f "$MI_JSON" ]; then
    MI_VER="$(_ver "$MI_JSON")"
    MI_NOMBRE="$(sed -n 's/.*"name": *"\([^"]*\)".*/\1/p' "$MI_JSON" | head -1)"
    for d in "$HOME"/.claude/plugins/marketplaces/*/; do
        [ -f "$d/.claude-plugin/plugin.json" ] || continue
        grep -q "\"name\": *\"$MI_NOMBRE\"" "$d/.claude-plugin/plugin.json" || continue
        MKT_VER="$(_ver "$d/.claude-plugin/plugin.json")"
        [ -n "$MKT_VER" ] && [ "$MKT_VER" != "$MI_VER" ] && DESFASE="corriendo $MI_VER, instalable $MKT_VER → claude plugin update $MI_NOMBRE"

        # Y el propio clon del marketplace puede estar atrasado respecto a su remoto: si los
        # dos coinciden en la versión vieja, compararlos entre sí no avisa de nada.
        STAMP="$ESTADO/.consulta-version"
        if [ -z "$(find "$STAMP" -mtime -1 2>/dev/null)" ]; then
            if GIT_TERMINAL_PROMPT=0 git -C "$d" fetch --quiet origin 2>/dev/null; then
                touch "$STAMP"
                REF="$(git -C "$d" rev-parse --verify --quiet origin/HEAD || echo origin/main)"
                REM_VER="$(git -C "$d" show "$REF:.claude-plugin/plugin.json" 2>/dev/null \
                           | sed -n 's/.*"version": *"\([^"]*\)".*/\1/p' | head -1)"
                [ -n "$REM_VER" ] && [ "$REM_VER" != "$MKT_VER" ] && \
                    DESFASE="corriendo $MI_VER, publicada $REM_VER → claude plugin marketplace update ${d%/} && claude plugin update $MI_NOMBRE"
            fi
        fi
        break
    done
fi

FALLOS=0
INFORME=""
paso() {  # paso "<nombre>" <comando...>   ← lo usa kit.conf
    local n="$1"; shift
    printf '▶ %s\n' "$n"
    if out=$("$@" 2>&1); then
        INFORME="${INFORME}✅ ${n}"$'\n'
    else
        INFORME="${INFORME}❌ ${n}"$'\n'"$(printf '%s\n' "$out" | tail -15)"$'\n'
        FALLOS=$((FALLOS+1))
    fi
}

FUENTES="App Sources Packages"      # default razonable; kit.conf puede pisarlo
# shellcheck disable=SC1090
. "$CONF"
type verificaciones >/dev/null 2>&1 || {
    echo "❌ kit.conf no define la función verificaciones()" >&2; exit 3; }

verificaciones

# Lógica repetida: avisa, no bloquea. Un duplicado puede ser deliberado, y quien lo decide
# es quien mira el cambio, no un script.
#
# Y solo se reportan los grupos que TOCA este cambio: en un proyecto vivo, los preexistentes se
# repiten en cada verificación hasta que nadie los lee, y el aviso que siempre dice lo mismo
# deja de ser un aviso. Los ocultos se cuentan en una línea y se listan con /kit-duplicados.
printf '▶ %s\n' "lógica repetida"
TOCADOS="$ESTADO/.tocados"
{ git diff --cached --name-only; git diff --name-only; } 2>/dev/null | sort -u > "$TOCADOS"
DUP="$(python3 "$(dirname "${BASH_SOURCE[0]}")/busca-duplicados.py" $FUENTES --tocados "$TOCADOS" 2>&1)"
rm -f "$TOCADOS"
case "$DUP" in
  # Se copia el texto tal cual y no un "ninguna" propio: la salida limpia ya trae, cuando
  # toca, la línea de cuántos grupos preexistentes quedaron fuera del reporte. Resumirla
  # aquí la perdía.
  *"sin lógica repetida"*) INFORME="${INFORME}${DUP}"$'\n' ;;
  *) INFORME="${INFORME}⚠️  lógica repetida (mírala, no bloquea):"$'\n'"${DUP}"$'\n' ;;
esac

if [ -n "$DESFASE" ]; then
    INFORME="${INFORME}"$'\n'"⚠️  KIT DESFASADO: $DESFASE"$'\n'
fi

if [ -n "$SUCIO" ]; then
    INFORME="${INFORME}"$'\n'"⚠️  ÁRBOL SUCIO: estos ficheros trackeados tienen cambios SIN STAGEAR. Lo que se ha"$'\n'
    INFORME="${INFORME}    verificado es el árbol entero; si commiteas solo el índice, commitearás MENOS"$'\n'
    INFORME="${INFORME}    de lo que se ha probado:"$'\n'
    INFORME="${INFORME}$(printf '%s\n' "$SUCIO" | sed 's/^/      /')"$'\n'
fi

{
    echo "verificado: $(date -u +%FT%TZ)"
    echo "diff: $(huella_diff)"
    echo "rama: $(git rev-parse --abbrev-ref HEAD)"
    # Lo lee `--comprueba`. Sin esta línea, un marker de una corrida en rojo era
    # indistinguible de uno verde para la puerta de commit.
    [ "$FALLOS" -eq 0 ] && echo "resultado: verde" || echo "resultado: rojo ($FALLOS paso(s))"
    echo
    printf '%s' "$INFORME"
} > "$MARKER"

printf '%s' "$INFORME"
[ -n "$DESFASE" ] && echo "⚠️  kit desfasado: $DESFASE"
[ -n "$SUCIO" ] && echo "⚠️  hay cambios sin stagear: se ha verificado el árbol entero, y un commit del índice lleva menos."
[ "$FALLOS" -eq 0 ] && echo "✅ verificación en verde, firmada contra el árbol verificado." \
                    || echo "❌ $FALLOS paso(s) en rojo — sin firma útil."

# 0 verde · 1 rojo · 3 «no pude mirar». El rojo es 1 SIEMPRE, no el número de pasos: saliendo
# con el recuento, exactamente TRES pasos en rojo son indistinguibles de «no hay kit.conf», y
# esa distinción es lo que el contrato publica. El recuento vive en el informe y en la línea
# `resultado:` de la firma, que es donde se lee.
[ "$FALLOS" -eq 0 ] && exit 0 || exit 1
