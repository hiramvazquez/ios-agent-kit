#!/usr/bin/env bash
# Piezas compartidas por los scripts del kit que corren DENTRO del repositorio de un
# proyecto. `lib-banco.sh` es el arnés de los bancos de pruebas; esto es para producción.
#
# No se carga solo: cada script hace `. "$DIR/lib-kit.sh"`, con `$DIR` resuelto ANTES de
# cambiar de directorio.

# cambio_activo — deja tres variables puestas:
#     ACTIVO     ruta del cambio OpenSpec activo SI HAY EXACTAMENTE UNO; vacío con ninguno
#                y vacío con varios
#     ACTIVOS_N  cuántos hay
#     ACTIVOS    las rutas de TODOS, una por línea y en el mismo orden, o vacío
#
# Con varios no se designa ninguno: nada dice cuál es el de la sesión, y una pieza que actúe
# sobre el primero afirma cosas del acuerdo de otro. Quien necesite uno lo recibe de quien lo
# invoca, o dice que hay varios. El orden de la lista lo fija `LC_ALL=C sort`, para que sea el
# mismo en cada invocación.
#
# Se llama SIN subshell —`cambio_activo` y luego `$ACTIVO`, nunca `$(cambio_activo)`—: una
# sustitución de comandos se comería dos de las tres. `ACTIVOS` es una cadena y no un array
# porque expandir un array vacío bajo `set -u` aborta en bash 3.2.
cambio_activo() {
    ACTIVO=""
    ACTIVOS=""
    ACTIVOS_N=0
    local d
    while IFS= read -r d; do
        [ -n "$d" ] || continue
        ACTIVOS_N=$((ACTIVOS_N + 1))
        ACTIVOS="${ACTIVOS}${d}"$'\n'
    done < <(find openspec/changes -maxdepth 1 -mindepth 1 -type d ! -name archive 2>/dev/null \
             | LC_ALL=C sort)
    # `if` y no `[ … ] && …`: como última orden, un `&&` fallido haría devolver 1 a la función.
    # SC2034: se lee en los scripts que cargan esta lib, no aquí.
    # shellcheck disable=SC2034
    if [ "$ACTIVOS_N" -eq 1 ]; then ACTIVO="${ACTIVOS%$'\n'}"; fi
}

# recuento_tareas <cambio> — deja dos variables puestas:
#     TAREAS_HECHAS  cuántas tareas de su `tasks.md` están marcadas
#     TAREAS_TOTAL   cuántas hay
#
# Las dos VACÍAS si el cambio no tiene `tasks.md`, y no a cero: «0/0 hechas» se lee como «no
# queda nada por hacer». Se llama SIN subshell. `|| true` y NO `|| echo 0`: `grep -c` imprime
# "0" Y sale con 1 sin coincidencias, y con "0\n0" la resta aborta en bash 3.2.
recuento_tareas() {
    TAREAS_HECHAS=""
    TAREAS_TOTAL=""
    [ -f "$1/tasks.md" ] || return 0
    local tareas pendientes
    tareas="$(cat "$1/tasks.md")"
    pendientes="$(printf '%s\n' "$tareas" | grep -c '^- \[ \]' || true)"
    TAREAS_TOTAL="$(printf '%s\n' "$tareas" | grep -cE '^- \[[ x]\]' || true)"
    # SC2034: se lee en los scripts que cargan esta lib, no aquí.
    # shellcheck disable=SC2034
    TAREAS_HECHAS=$((TAREAS_TOTAL - pendientes))
}

# MARCA_PUERTA — la línea que identifica un `pre-commit` como del kit. La escribe `verifica.sh`
# al generarlo y la leen `verifica.sh` (¿es mío el que hay?) y `estado.sh` (¿está instalada?).
# shellcheck disable=SC2034
MARCA_PUERTA="ios-agent-kit: puerta de commit"

# huella_diff — el sha256 de lo que hay que firmar: el ÁRBOL DE TRABAJO **y** el ÍNDICE.
#
# Los dos, porque cada uno cierra un agujero distinto: el árbol es lo que se compila y lo que
# se lleva un `git commit -a` o un pathspec; el índice es lo que se lleva un `git commit` a
# secas. El separador impide que un hunk migre de un diff al otro sin mover la huella.
# Consecuencia asumida: stagear después de firmar invalida la firma. Sin ningún commit no
# hay `HEAD`, y el índice es la única referencia. Única definición: la usan quien firma
# (`verifica.sh`) y quien dice si la firma vale (el hook de contexto).
huella_diff() {
    if git rev-parse --verify --quiet HEAD >/dev/null 2>&1; then
        { git diff HEAD; echo '--- índice ---'; git diff --cached; }
    else
        git diff --cached
    fi | shasum -a 256 | cut -d' ' -f1
}

# toolchain — imprime en UNA línea con qué se ha verificado: el `swift` del PATH, el Xcode
# seleccionado, y un aviso si el swift del PATH no es el que expone `xcrun`.
#
# «Verificado» solo puede significar «verificado con el toolchain de esta máquina»; esto
# dice cuál. La divergencia se AVISA, no se bloquea: hay proyectos que usan un toolchain de
# swift.org a propósito. Una línea y corta: la consume el digest de cada turno, que lee la
# línea del marker en vez de volver a llamar aquí (detectar cuesta 0,3 s).
#
# LÍMITE DECLARADO: describe el entorno, no lo valida. Si no hay nada que interrogar dice «no
# identificado» y sale con 0: el kit se usa en repositorios sin Xcode.
toolchain() {
    local swift_path="" swift_xcrun="" xcode="" linea=""

    command -v swift >/dev/null 2>&1 && swift_path="$(version_swift swift)"
    command -v xcrun >/dev/null 2>&1 && swift_xcrun="$(version_swift xcrun swift)"
    command -v xcodebuild >/dev/null 2>&1 \
        && xcode="$(xcodebuild -version 2>/dev/null | sed -n '1s/^Xcode //p')"

    # El del PATH es el que ejecuta la mayoría de los pasos de un `kit.conf`; si no hay, el de
    # `xcrun` es el que habría corrido.
    [ -n "$swift_path" ] && linea="Swift $swift_path" \
        || { [ -n "$swift_xcrun" ] && linea="Swift $swift_xcrun (vía xcrun)"; }
    [ -n "$xcode" ] && linea="${linea:+$linea · }Xcode $xcode"

    if [ -n "$swift_path" ] && [ -n "$swift_xcrun" ] && [ "$swift_path" != "$swift_xcrun" ]; then
        linea="$linea · OJO: el swift del PATH ($swift_path) NO es el de Xcode ($swift_xcrun)"
    fi

    printf '%s\n' "${linea:-no identificado}"
}

# version_swift <orden…> — la versión de Swift que anuncia esa orden, o vacío.
#
# El patrón NO exige el prefijo «Apple»: un toolchain de swift.org anuncia `Swift version
# 6.0.3`, y saltarlo en silencio atribuiría la corrida al Swift de `xcrun`. `head -1` porque
# `swift --version` imprime también la línea del target.
version_swift() {
    "$@" --version 2>/dev/null | sed -n 's/.*Swift version \([0-9][0-9.]*\).*/\1/p' | head -1
}

# derivados_propios <raíz> — deja una variable puesta:
#     DD_PROPIO  array con los directorios de DerivedData que son de ESE repositorio
#
# Se llama SIN subshell: un array no sobrevive a una sustitución de comandos. Sin acotar, un
# `find` sobre DerivedData devuelve los paquetes de TODOS los proyectos de la máquina.
#
# LA HEURÍSTICA, DECLARADA. Xcode nombra cada carpeta `<Proyecto>-<hash>`, donde `<Proyecto>`
# es el nombre del `.xcodeproj` o `.xcworkspace`. Se aproxima con el nombre del directorio del
# repositorio, que coincide en el caso común. Lo que se pierde, y no todo es seguro:
#
#   (a) Falso negativo si el `.xcodeproj` se llama distinto de la carpeta: no encuentra su
#       propio DerivedData y se calla. Ese es el lado seguro.
#   (b) Dos repositorios con el mismo nombre de carpeta comparten el filtro.
#   (c) **Y este NO es seguro:** el hash no está restringido en el patrón, así que un proyecto
#       cuyo nombre EMPIECE por el tuyo más un guion casa igual. Un repositorio `spm` recibe lo
#       de `spm-pro-<hash>`. Acotarlo de verdad —exigir la forma del hash, o leer el
#       `info.plist` de cada carpeta— es otra decisión con su propia medición.
#
# `nullglob` deja el array VACÍO si nada casa. Quien lo use debe expandirlo con
# `${DD_PROPIO[@]+"${DD_PROPIO[@]}"}`: en bash 3.2 expandir un array vacío bajo `set -u` aborta.
derivados_propios() {
    local proyecto="${1##*/}" _ng
    # Se RESTAURA el estado previo en vez de apagarlo: un `shopt -u` incondicional destruye el
    # `nullglob` de quien llame, y `shopt -p` imprime justo el comando que lo deja como estaba.
    _ng="$(shopt -p nullglob)"
    shopt -s nullglob
    # SC2034: shellcheck no ve el uso porque está en los scripts que cargan esta lib, no aquí.
    # shellcheck disable=SC2034
    DD_PROPIO=("$HOME/Library/Developer/Xcode/DerivedData/${proyecto}-"*)
    eval "$_ng"
}
