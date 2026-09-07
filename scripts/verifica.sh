#!/usr/bin/env bash
# Verifica el proyecto y FIRMA que la verificación corrió contra ESTE diff.
#
# El marker liga el resultado al sha256 del diff staged. Sin eso, "los tests pasan" es una
# afirmación sobre un árbol que pudo cambiar después de correrlos — el fallo de proceso más
# común y el que menos rastro deja.
#
# Los comandos concretos NO viven aquí: los pone cada proyecto en `kit.conf`. Este script
# es del kit y es igual en todos.
#
# Uso:  verifica.sh              verifica y firma
#       verifica.sh --informe    imprime el último informe, sin volver a correr
#       verifica.sh --comprueba  ¿hay firma válida para el diff staged? (exit 1 si no)
set -uo pipefail
RAIZ="$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "❌ no es un repo git"; exit 1; }
cd "$RAIZ" || exit 1

CONF="$RAIZ/kit.conf"
ESTADO="$RAIZ/.agent-kit"
MARKER="$ESTADO/verificacion.txt"
mkdir -p "$ESTADO"

huella() { git diff --cached | shasum -a 256 | cut -d' ' -f1; }

case "${1:-}" in
--informe)
    [ -f "$MARKER" ] && cat "$MARKER" || echo "sin informe: nadie ha corrido verifica todavía"
    exit 0 ;;
--comprueba)
    # DOS condiciones, no una. La firma tiene que ser de este diff Y de una verificación
    # que salió VERDE. Antes solo se comprobaba el diff, asi que tras una verificacion en
    # rojo el marker seguia ahi con su linea `diff:` y esto respondia "firma valida": la
    # puerta que debe parar un cambio roto lo dejaba pasar. Lo caz0 un juez de aceptacion
    # comprobando un criterio que decia "sale en rojo y no firma" — la segunda mitad era
    # falsa.
    [ -f "$MARKER" ] || { echo "❌ nada verificado todavía"; exit 1; }
    grep -q "^diff: $(huella)$" "$MARKER" \
        || { echo "❌ la firma es de OTRO diff — vuelve a verificar"; exit 1; }
    grep -q "^resultado: verde$" "$MARKER" \
        || { echo "❌ la última verificación salió en ROJO — arréglalo y vuelve a verificar"; exit 1; }
    echo "✅ firma válida para el diff staged"; exit 0
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

# El árbol sucio hace mentir a la firma, y hay que decirlo.
#
# `swift build`/`swift test` compilan el ÁRBOL DE TRABAJO; la firma es del ÍNDICE. Si algún
# fichero trackeado tiene cambios sin stagear, lo verificado NO es lo que se va a commitear
# — y el informe diría "verde" sobre otro código. Lo cazaron dos revisiones seguidas sobre
# un cambio ajeno que llevaba días en el árbol.
#
# Avisa y lo DEJA ESCRITO en el informe; no bloquea. Quien tenga trabajo en curso aparte
# decide si lo guarda (`git stash -k`) o asume la diferencia — pero ya no puede no saberlo,
# y el reviewer y el juez lo leen en `--informe`.
SUCIO="$(git diff --name-only 2>/dev/null)"

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
printf '▶ %s\n' "lógica repetida"
DUP="$(python3 "$(dirname "${BASH_SOURCE[0]}")/busca-duplicados.py" $FUENTES 2>&1)"
case "$DUP" in
  *"sin lógica repetida"*) INFORME="${INFORME}✅ lógica repetida: ninguna"$'\n' ;;
  *) INFORME="${INFORME}⚠️  lógica repetida (mírala, no bloquea):"$'\n'"${DUP}"$'\n' ;;
esac

if [ -n "$SUCIO" ]; then
    INFORME="${INFORME}"$'\n'"⚠️  ÁRBOL SUCIO: estos ficheros trackeados tienen cambios SIN STAGEAR, así que"$'\n'
    INFORME="${INFORME}    lo que se compiló y testeó NO es exactamente lo que se va a commitear:"$'\n'
    INFORME="${INFORME}$(printf '%s\n' "$SUCIO" | sed 's/^/      /')"$'\n'
fi

{
    echo "verificado: $(date -u +%FT%TZ)"
    echo "diff: $(huella)"
    echo "rama: $(git rev-parse --abbrev-ref HEAD)"
    # Lo lee `--comprueba`. Sin esta línea, un marker de una corrida en rojo era
    # indistinguible de uno verde para la puerta de commit.
    [ "$FALLOS" -eq 0 ] && echo "resultado: verde" || echo "resultado: rojo ($FALLOS paso(s))"
    echo
    printf '%s' "$INFORME"
} > "$MARKER"

printf '%s' "$INFORME"
[ -n "$SUCIO" ] && echo "⚠️  el árbol tenía cambios sin stagear: la firma vale, el verde es sobre otro árbol."
[ "$FALLOS" -eq 0 ] && echo "✅ verificación en verde, firmada contra el diff staged." \
                    || echo "❌ $FALLOS paso(s) en rojo — sin firma útil."
exit "$FALLOS"
