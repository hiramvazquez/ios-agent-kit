#!/usr/bin/env bash
# /kit-estado: ¿cómo estamos? En una pantalla y al instante, sin compilar ni tocar nada.
#
# Los demás comandos del kit sirven para HACER —verificar, revisar, juzgar—, y el único que
# ya decía parte de esto, `/kit-verifica`, ejecuta el `kit.conf` entero: en un proyecto iOS
# son minutos, y una pregunta que tarda minutos no se hace.
#
# NO DECIDE NADA. Cada línea la decide otra pieza, y aquí solo se junta:
#   - el trabajo sin guardar, de `git status`;
#   - los cambios activos y sus tareas, de `cambio_activo` y `recuento_tareas` (`lib-kit.sh`);
#   - la firma, de `verifica.sh --comprueba`, que es el veredicto de la puerta de commit;
#   - la lógica repetida, de `busca-duplicados.py`;
#   - la versión del kit y qué hacer con ella, de `version_kit` (`lib-kit.sh`).
# Si una de estas respuestas se calculara aquí por su cuenta, podría contradecir a la pieza
# que de verdad decide.
#
# SOLO LEE. No toca el árbol de trabajo, no crea `.agent-kit/` y no consulta ningún remoto.
# `GIT_OPTIONAL_LOCKS=0` impide que `git status` reescriba el índice de paso.
#
# Sale con 0 siempre que haya podido mirar, aunque lo que cuente esté en rojo: es una pregunta,
# no una puerta. Fuera de un repositorio git sale con 1, como sus hermanos.
#
# LÍMITES DECLARADOS:
#   - «Sin empujar» y «sin traer» son respecto al último `fetch`: mirar el remoto exige red.
#   - Carga `kit.conf` para saber dónde buscar duplicados, y cargarlo ejecuta código del
#     repositorio.
#   - Del detector de duplicados se queda con sus líneas de resumen, que reconoce por el emoji
#     con el que empiezan. Si el detector cambia esos emojis, la línea desaparece sin avisar.
#   - No tiene banco: su salida no la comprueba nada salvo leerla. Lo que decide cada línea sí
#     vive en piezas con banco.
#   - El `git diff HEAD` con el que `verifica.sh --comprueba` calcula la huella sí refresca la
#     caché del índice (`.git/index`): `GIT_OPTIONAL_LOCKS` lo respeta `git status`, y `git
#     diff` no. Lo stageado no cambia; evitarlo exigiría cambiar la huella.
set -uo pipefail
export GIT_OPTIONAL_LOCKS=0

# `$DIR` antes del `cd`, por lo mismo que en el resto de scripts del kit.
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
. "$DIR/lib-kit.sh"

# Se comprueba la RESOLUCIÓN, no el `cd`: `cd ""` devuelve 0 en bash (spec `raiz-de-trabajo`).
RAIZ="$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "❌ no es un repo git"; exit 1; }
cd "$RAIZ" || exit 1

# ── Trabajo sin guardar ────────────────────────────────────────────────────────────────────────
# Una sola llamada: la cabecera `## ` trae rama, upstream y adelantados/atrasados, y cada línea
# `XY ruta` dice si el fichero está stageado (X) o tiene cambios sin stagear (Y). Las cadenas de
# la cabecera en `--porcelain` no se traducen.
#
# `--untracked-files=all` para contar FICHEROS sin trackear y no directorios.
CAB=""; STAGEADOS=0; SIN_STAGEAR=0; SIN_TRACKEAR=0
while IFS= read -r l; do
    case "$l" in
        "## "*) CAB="${l#"## "}" ;;
        "??"*)  SIN_TRACKEAR=$((SIN_TRACKEAR + 1)) ;;
        *)      [ "${l:0:1}" != " " ] && STAGEADOS=$((STAGEADOS + 1))
                [ "${l:1:1}" != " " ] && SIN_STAGEAR=$((SIN_STAGEAR + 1)) ;;
    esac
done < <(git status --porcelain=v1 --branch --untracked-files=all 2>/dev/null)

# «No commits yet on » se quita ANTES de partir la cabecera: un clon de un repositorio vacío
# trae upstream igual (`No commits yet on main...origin/main [gone]`).
SIN_COMMITS=""
case "$CAB" in "No commits yet on "*) CAB="${CAB#"No commits yet on "}"; SIN_COMMITS=", sin commits todavía" ;; esac
SIGUE=""
case "$CAB" in
    "HEAD (no branch)"*) RAMA="ninguna: HEAD suelto" ;;
    *"..."*)             RAMA="${CAB%%...*}"; SIGUE="${CAB#*...}"; SIGUE="${SIGUE%% \[*}" ;;
    *)                   RAMA="${CAB%% \[*}" ;;
esac
RAMA="${RAMA}${SIN_COMMITS}"
# Los nombres de rama no admiten espacios, así que «ahead » y «behind » solo pueden ser del
# corchete del final.
ADELANTE=0; ATRAS=0
case "$CAB" in *"ahead "*)  ADELANTE="${CAB#*ahead }"; ADELANTE="${ADELANTE%%[],]*}" ;; esac
case "$CAB" in *"behind "*) ATRAS="${CAB#*behind }";   ATRAS="${ATRAS%%]*}" ;; esac

echo "▶ ${RAIZ##*/} · rama ${RAMA}"
echo "  sin guardar: $STAGEADOS stageado(s) · $SIN_STAGEAR sin stagear · $SIN_TRACKEAR sin trackear"
if [ -z "$SIGUE" ]; then
    echo "  sin upstream: no sigue ninguna rama remota"
else
    case "$CAB" in
        *"[gone]") echo "  sigue a ${SIGUE}, que ya no existe en el remoto" ;;
        *)         echo "  $ADELANTE sin empujar · $ATRAS sin traer, respecto a $SIGUE en el último fetch" ;;
    esac
fi

# ── Cambios activos ────────────────────────────────────────────────────────────────────────────
# TODOS, no solo el primero: el digest de cada turno habla de uno, y aquí se pregunta por el total.
echo
if [ ! -d openspec ]; then
    echo "▶ OpenSpec: este repositorio no lo usa"
else
    cambio_activo
    if [ "$ACTIVOS_N" -eq 0 ]; then
        echo "▶ Cambios activos: ninguno"
    else
        echo "▶ Cambios activos: $ACTIVOS_N"
        # `printf '%s'` y no `<<<`: `ACTIVOS` ya acaba en salto de línea, y un here-string le
        # añadiría otro, que se leería como un cambio vacío.
        while IFS= read -r c; do
            recuento_tareas "$c"
            if [ -n "$TAREAS_TOTAL" ]; then
                echo "  · ${c##*/} — tareas $TAREAS_HECHAS/$TAREAS_TOTAL hechas"
            else
                echo "  · ${c##*/} — sin lista de tareas"
            fi
        done < <(printf '%s' "$ACTIVOS")
    fi
fi

# ── Verificación ───────────────────────────────────────────────────────────────────────────────
# El veredicto es el de `--comprueba`, tal cual: firma de este árbol Y de una verificación en
# verde. Mirar solo la huella —como hace el digest— daría «firmada» tras una verificación en rojo.
echo
echo "▶ Verificación"
VEREDICTO="$(bash "$DIR/verifica.sh" --comprueba 2>&1)"
echo "  $VEREDICTO"
M=".agent-kit/verificacion.txt"
if [ -f "$M" ]; then
    echo "  última: $(sed -n 's/^verificado: //p' "$M" | head -1) · $(sed -n 's/^resultado: //p' "$M" | head -1) · rama $(sed -n 's/^rama: //p' "$M" | head -1)"
    # También cuando la firma ya no vale: saber CON QUÉ se verificó la última vez es justo lo
    # que falta cuando el CI dice una cosa y la firma local decía otra.
    TC="$(sed -n 's/^toolchain: //p' "$M" | head -1)"
    LIM="$(sed -n 's/^limites: //p' "$M" | head -1)"
    # Solo si el veredicto no lo trae ya: cuando la firma vale, `--comprueba` lo dice.
    case "$VEREDICTO" in
        *"toolchain: "*) [ -n "$TC" ] && echo "  límites del proyecto: ${LIM:-sin declarar}" ;;
        *) [ -n "$TC" ] && echo "  toolchain: $TC · límites del proyecto: ${LIM:-sin declarar}" ;;
    esac
fi

# ── Lógica repetida ────────────────────────────────────────────────────────────────────────────
# SIN `--tocados`: aquí se cuentan todos los grupos, también los que ningún cambio en curso toca.
# `FUENTES` sale de `kit.conf` en un subshell, con el mismo valor por defecto que `verifica.sh`, y
# sin `set -u`, que abortaría con cualquier variable sin definir de un `kit.conf` ajeno.
echo
echo "▶ Lógica repetida, en todo el proyecto"
FUENTES="$(set +u; FUENTES="App Sources Packages"
           # shellcheck source=/dev/null
           [ -f kit.conf ] && . ./kit.conf >/dev/null 2>&1
           printf '%s' "$FUENTES")"
# `$FUENTES` sin comillas a propósito: son varios directorios.
RESUMEN="$(python3 "$DIR/busca-duplicados.py" $FUENTES 2>&1 | grep -E '^(✅|❌|⚠)' | sed 's/:$//')"
if [ -z "$RESUMEN" ]; then
    echo "  no reconozco el resumen del detector: /kit-duplicados lo corre entero"
else
    printf '%s\n' "$RESUMEN" | sed 's/^/  /'
    case "$RESUMEN" in *"❌"*|*"⚠"*) echo "  → la lista, con /kit-duplicados" ;; esac
fi

# ── Versión del kit ────────────────────────────────────────────────────────────────────────────
# Qué comparar y qué aconsejar lo decide `version_kit`; lo que se añade aquí es decir con honradez
# cuánto se ha podido comparar cuando no hay consejo.
echo
version_kit "$(cd "$DIR/.." && pwd)"
if [ -z "$VER_CORRE" ]; then
    echo "▶ Kit: no encuentro su plugin.json junto a los scripts"
elif [ -n "$CONSEJO_VERSION" ]; then
    echo "▶ Kit: ⚠️  $CONSEJO_VERSION"
elif [ -n "$VER_INSTALADA" ] && [ -n "$VER_CLON" ]; then
    echo "▶ Kit: corre la $VER_CORRE, la misma que está instalada y que trae el marketplace"
elif [ -n "$VER_CLON" ]; then
    echo "▶ Kit: corre la $VER_CORRE, la misma que trae el marketplace; la instalada no la puedo leer"
else
    echo "▶ Kit: corre la $VER_CORRE; no encuentro el marketplace con el que compararla"
fi

exit 0
