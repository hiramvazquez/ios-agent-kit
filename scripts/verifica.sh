#!/usr/bin/env bash
# Verifica el proyecto y FIRMA que la verificación corrió contra ESTE diff.
#
# El marker liga el resultado al sha256 del árbol de trabajo Y del índice: entre los dos está
# todo lo que un commit puede llevarse. Stagear después de firmar cambia el índice y por tanto
# invalida la firma — por eso stagear, verificar y commitear van en comandos separados.
#
# Sin esto, "los tests pasan" es una afirmación sobre un árbol que pudo cambiar después de
# correrlos — el fallo de proceso más común y el que menos rastro deja.
#
# Los comandos concretos NO viven aquí: los pone cada proyecto en `kit.conf`.
#
# LÍMITE DECLARADO: ese `kit.conf` se CARGA con `.`, así que verificar ejecuta código del
# repositorio en el que estés. Es la única forma de que cada proyecto declare sus propios
# pasos. Sobre un repositorio clonado de fuera, `kit.conf` es código que nadie ha leído.
#
# Uso:  verifica.sh              verifica y firma
#       verifica.sh --informe    imprime el último informe, sin volver a correr
#       verifica.sh --comprueba  ¿hay firma válida para este árbol? (exit 1 si no)
set -uo pipefail

# `$DIR` se resuelve ANTES del `cd`: después, una invocación relativa desde un subdirectorio
# ya no encontraría la lib.
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
. "$DIR/lib-kit.sh"

RAIZ="$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "❌ no es un repo git"; exit 1; }
cd "$RAIZ" || exit 1

CONF="$RAIZ/kit.conf"
ESTADO="$RAIZ/.agent-kit"
MARKER="$ESTADO/verificacion.txt"

# Los dos modos de abajo solo LEEN, y no crean `.agent-kit/`: una pregunta no puede dejar un
# directorio en un repositorio que nunca pidió el kit. Lo crea verificar.
case "${1:-}" in
--informe)
    [ -f "$MARKER" ] && cat "$MARKER" || echo "sin informe: nadie ha corrido verifica todavía"
    exit 0 ;;
--comprueba)
    # DOS condiciones, no una: la firma tiene que ser de este árbol Y de una verificación que
    # salió VERDE. Con solo la huella, un marker de una corrida en rojo valdría.
    [ -f "$MARKER" ] || { echo "❌ nada verificado todavía"; exit 1; }
    grep -q "^diff: $(huella_diff)$" "$MARKER" \
        || { echo "❌ la firma es de OTRO diff — vuelve a verificar"; exit 1; }
    grep -q "^resultado: verde$" "$MARKER" \
        || { echo "❌ la última verificación salió en ROJO — arréglalo y vuelve a verificar"; exit 1; }
    # El alcance sale del marker, no de detectarlo otra vez: lo que importa es con qué se
    # FIRMÓ. Una firma sin ese campo responde sin él.
    TC="$(sed -n 's/^toolchain: //p' "$MARKER" | head -1)"
    echo "✅ firma válida para este árbol${TC:+ · toolchain: $TC}"; exit 0
    ;;
esac
mkdir -p "$ESTADO"

if [ ! -f "$CONF" ]; then
    cat >&2 <<'AYUDA'
❌ falta kit.conf en la raíz del proyecto.

   Es el ÚNICO fichero que el kit necesita que escribas. Define qué significa
   "verificado" aquí — build y tests de este proyecto — y dónde vive el código.

   Créalo con /kit-init, o copia plantillas/kit.conf.ejemplo del kit.
AYUDA
    exit 3   # "no pude mirar", que no es lo mismo que "está mal"
fi

# Se firma el árbol, así que lo verificado y lo firmado son lo mismo; pero con cambios sin
# stagear se puede commitear un SUBCONJUNTO de lo verificado, y ese subconjunto no se ha
# probado solo. Avisa y lo deja escrito en el informe; no bloquea.
SUCIO="$(git diff --name-only 2>/dev/null)"

# ¿Estoy corriendo el kit que el proyecto cree que corre?
#
# Un plugin instalado no se actualiza solo, y una conversación reanudada puede seguir
# cargando la versión con la que empezó. Qué versiones se comparan y qué se aconseja lo
# decide `version_kit`, en `lib-kit.sh`, que es de donde lo toma también `/kit-estado`. Lo
# único que es de aquí es mirar el REMOTO del marketplace, como mucho una vez al día y en
# silencio sin red. No bloquea y no habla si no tiene nada que decir.
version_kit "$(cd "$DIR/.." && pwd)"
DESFASE="$CONSEJO_VERSION"
if [ -n "$KIT_CLON" ]; then
    STAMP="$ESTADO/.consulta-version"
    if [ -z "$(find "$STAMP" -mtime -1 2>/dev/null)" ]; then
        if GIT_TERMINAL_PROMPT=0 git -C "$KIT_CLON" fetch --quiet origin 2>/dev/null; then
            touch "$STAMP"
            REF="$(git -C "$KIT_CLON" rev-parse --verify --quiet origin/HEAD || echo origin/main)"
            REM_VER="$(git -C "$KIT_CLON" show "$REF:.claude-plugin/plugin.json" 2>/dev/null | version_json)"
            # El marketplace se nombra por su NOMBRE, no por su ruta.
            [ -n "$REM_VER" ] && [ "$REM_VER" != "$VER_CLON" ] && \
                DESFASE="corriendo $VER_CORRE, publicada $REM_VER → claude plugin marketplace update ${KIT_CLON##*/} && claude plugin update $KIT_ID, y después abre una conversación nueva"
        fi
    fi
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

# Qué NO cubre la firma de ESTE proyecto, en prosa y opcional. Vacío por defecto: un proyecto
# que no lo declara no miente, pero el informe lo dice en vez de dejar creer que no hay
# límites. Lo escribe el proyecto porque el kit no puede saberlo.
LIMITES=""
# shellcheck disable=SC1090
. "$CONF"
type verificaciones >/dev/null 2>&1 || {
    echo "❌ kit.conf no define la función verificaciones()" >&2; exit 3; }

verificaciones

# Lógica repetida: avisa, no bloquea. Un duplicado puede ser deliberado, y quien lo decide
# es quien mira el cambio, no un script.
#
# Solo se reportan los grupos que TOCA este cambio: los preexistentes se repetirían en cada
# verificación hasta que nadie los lea. Se cuentan en una línea y se listan con /kit-duplicados.
printf '▶ %s\n' "lógica repetida"
TOCADOS="$ESTADO/.tocados"
{ git diff --cached --name-only; git diff --name-only; } 2>/dev/null | sort -u > "$TOCADOS"
DUP="$(python3 "$(dirname "${BASH_SOURCE[0]}")/busca-duplicados.py" $FUENTES --tocados "$TOCADOS" 2>&1)"
rm -f "$TOCADOS"
case "$DUP" in
  # Se copia el texto tal cual: la salida limpia ya trae, cuando toca, la línea de cuántos
  # grupos preexistentes quedaron fuera del reporte.
  *"sin lógica repetida"*) INFORME="${INFORME}${DUP}"$'\n' ;;
  *) INFORME="${INFORME}⚠️  lógica repetida (mírala, no bloquea):"$'\n'"${DUP}"$'\n' ;;
esac

if [ -n "$DESFASE" ]; then
    INFORME="${INFORME}"$'\n'"⚠️  KIT DESFASADO: $DESFASE"$'\n'
fi

if [ -n "$LIMITES" ]; then
    INFORME="${INFORME}"$'\n'"LO QUE ESTA FIRMA NO CUBRE, según este proyecto:"$'\n'
    INFORME="${INFORME}$(printf '%s\n' "$LIMITES" | sed 's/^/    /')"$'\n'
else
    INFORME="${INFORME}"$'\n'"ℹ️  este proyecto no declara los límites de su firma (LIMITES en kit.conf)."$'\n'
fi

if [ -n "$SUCIO" ]; then
    INFORME="${INFORME}"$'\n'"⚠️  ÁRBOL SUCIO: estos ficheros trackeados tienen cambios SIN STAGEAR. Lo que se ha"$'\n'
    INFORME="${INFORME}    verificado es el árbol entero; si commiteas solo el índice, commitearás MENOS"$'\n'
    INFORME="${INFORME}    de lo que se ha probado:"$'\n'
    INFORME="${INFORME}$(printf '%s\n' "$SUCIO" | sed 's/^/      /')"$'\n'
fi

# ── La puerta de commit ──────────────────────────────────────────────────────────────────────
# Un hook `pre-commit` de git, regenerado en cada firma —también en rojo: la puerta tiene que
# existir para bloquear ese árbol—. Lleva copiada la definición de `huella_diff` con
# `declare -f`, así que la huella sigue teniendo una sola definición, en `lib-kit.sh`.
#
# Va siempre a `.agent-kit/pre-commit`. Si el repositorio no tiene `pre-commit`, o el que tiene
# es del kit (lleva la marca), se copia a los hooks de git. Si hay uno ajeno, o `core.hooksPath`
# está configurado, no se toca nada y el informe dice qué fichero es y qué línea añadir.
#
# El hook se ABRE si el repositorio ya no tiene `kit.conf`: sin él no hay quien firme, y un
# hook que sobrevive a desinstalar el kit no puede convertirse en un muro.
#
# LÍMITES DECLARADOS: no frena `--no-verify`, un git que no lea los hooks del repositorio, ni
# los commits que git crea sin pasar por `pre-commit` (merge, revert, cherry-pick, rebase).
instala_puerta() {
    local propio="$ESTADO/pre-commit" hooks destino
    {
        echo '#!/usr/bin/env bash'
        echo "# $MARCA_PUERTA. La regenera verifica.sh en cada firma; no la edites."
        echo '# Exige que la firma de .agent-kit/verificacion.txt sea del árbol y del índice que se'
        echo '# van a commitear, y de una verificación verde. Si el repositorio ya no tiene kit.conf,'
        echo '# deja pasar: ya no usa el kit. No frena --no-verify, un git que no lea los hooks del'
        echo '# repositorio, ni los commits de merge, revert, cherry-pick o rebase.'
        echo 'set -u'
        echo 'RAIZ="$(git rev-parse --show-toplevel)" || exit 1'
        echo 'cd "$RAIZ" || exit 1'
        echo '[ -f kit.conf ] || exit 0'
        declare -f huella_diff
        cat <<'HOOK'
M=".agent-kit/verificacion.txt"
[ -f "$M" ] && grep -q "^diff: $(huella_diff)$" "$M" && grep -q '^resultado: verde$' "$M" && exit 0
cat >&2 <<'MSG'
❌ ios-agent-kit: no hay verificación firmada para lo que se va a commitear.
   Stagea primero, corre /kit-verifica y commitea después, en un comando aparte: se firma el
   árbol Y el índice, así que encadenar el `add` con el commit cambia lo firmado.
MSG
exit 1
HOOK
    } > "$propio"
    chmod +x "$propio"

    hooks="$(git rev-parse --git-path hooks)"
    destino="$hooks/pre-commit"
    if [ -n "$(git config --get core.hooksPath)" ]; then
        INFORME="${INFORME}"$'\n'"ℹ️  PUERTA DE COMMIT: este repositorio usa core.hooksPath, así que no se toca. Añade a $destino:"$'\n'"    bash .agent-kit/pre-commit"$'\n'
    elif [ -e "$destino" ] && ! grep -q "$MARCA_PUERTA" "$destino"; then
        INFORME="${INFORME}"$'\n'"ℹ️  PUERTA DE COMMIT: $destino ya existe y no es del kit, así que no se toca. Añádele:"$'\n'"    bash .agent-kit/pre-commit"$'\n'
    elif [ -e "$destino" ]; then
        cp "$propio" "$destino" && chmod +x "$destino" \
            || INFORME="${INFORME}"$'\n'"⚠️  PUERTA DE COMMIT: no se pudo refrescar $destino. El hook que hay se queda como estaba."$'\n'
    elif mkdir -p "$hooks" && cp "$propio" "$destino" && chmod +x "$destino"; then
        INFORME="${INFORME}"$'\n'"ℹ️  puerta de commit instalada en $destino"$'\n'
    else
        INFORME="${INFORME}"$'\n'"⚠️  PUERTA DE COMMIT: no se pudo escribir $destino. Este repositorio queda SIN puerta."$'\n'
    fi
}
instala_puerta

# UNA sola llamada, y su resultado se escribe en la firma: el digest y `/kit-estado` leen esa
# línea en vez de volver a detectar (cuesta 0,3 s, inaceptable en un hook de cada turno).
TOOLCHAIN="$(toolchain)"

{
    echo "verificado: $(date -u +%FT%TZ)"
    echo "diff: $(huella_diff)"
    echo "rama: $(git rev-parse --abbrev-ref HEAD)"
    # Lo que hace que «verificado» no se lea como «esto pasa» sino como «esto pasó aquí».
    echo "toolchain: $TOOLCHAIN"
    [ -n "$LIMITES" ] && echo "limites: declarados" || echo "limites: sin declarar"
    # Lo lee `--comprueba`: sin esta línea, un marker de una corrida en rojo sería
    # indistinguible de uno verde.
    [ "$FALLOS" -eq 0 ] && echo "resultado: verde" || echo "resultado: rojo ($FALLOS paso(s))"
    echo
    printf '%s' "$INFORME"
} > "$MARKER"

printf '%s' "$INFORME"
[ -n "$DESFASE" ] && echo "⚠️  kit desfasado: $DESFASE"
[ -n "$SUCIO" ] && echo "⚠️  hay cambios sin stagear: se ha verificado el árbol entero, y un commit del índice lleva menos."
# El alcance va EN la línea del veredicto, no debajo: una línea aparte se lee como un aviso
# más y se salta.
[ "$FALLOS" -eq 0 ] && echo "✅ verde · toolchain: $TOOLCHAIN · firmado contra el árbol verificado — no dice nada de otros toolchains." \
                    || echo "❌ $FALLOS paso(s) en rojo · toolchain: $TOOLCHAIN — sin firma útil."

# 0 verde · 1 rojo · 3 «no pude mirar». El rojo es 1 SIEMPRE, no el número de pasos: con el
# recuento, exactamente tres pasos en rojo serían indistinguibles de «no hay kit.conf». El
# recuento vive en el informe y en la línea `resultado:` de la firma.
[ "$FALLOS" -eq 0 ] && exit 0 || exit 1
