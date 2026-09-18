#!/usr/bin/env bash
# Piezas compartidas por los scripts del kit que corren DENTRO del repositorio de un
# proyecto. `lib-banco.sh` es el arnés de los bancos de pruebas; esto es para producción.
#
# No se carga solo: cada script hace `. "$DIR/lib-kit.sh"`, con `$DIR` resuelto ANTES de
# cambiar de directorio.

# cambio_activo — deja tres variables puestas:
#     ACTIVO     ruta del cambio OpenSpec activo, o vacío si no hay ninguno
#     ACTIVOS_N  cuántos hay
#     ACTIVOS    las rutas de TODOS, una por línea y en el mismo orden, o vacío
#
# Se llama SIN subshell —`cambio_activo` y luego `$ACTIVO`, nunca `$(cambio_activo)`—: una
# sustitución de comandos se comería dos de las tres. `ACTIVOS` es una cadena y no un array
# porque expandir un array vacío bajo `set -u` aborta en bash 3.2. El orden lo fija
# `LC_ALL=C sort`: cuál es «el» activo cuando hay varios es arbitrario, pero estable.
cambio_activo() {
    ACTIVO=""
    ACTIVOS=""
    ACTIVOS_N=0
    local d
    while IFS= read -r d; do
        [ -n "$d" ] || continue
        ACTIVOS_N=$((ACTIVOS_N + 1))
        [ -z "$ACTIVO" ] && ACTIVO="$d"
        ACTIVOS="${ACTIVOS}${d}"$'\n'
    done < <(find openspec/changes -maxdepth 1 -mindepth 1 -type d ! -name archive 2>/dev/null \
             | LC_ALL=C sort)
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

# version_json — la primera `"version"` del JSON que le llega por la entrada estándar.
#
# Por la entrada y no por nombre de fichero, porque `verifica.sh` también la saca de un `git show`.
version_json() { sed -n 's/.*"version": *"\([^"]*\)".*/\1/p' | head -1; }

# version_kit <raíz-del-kit> — qué versión del kit corre, cuál está instalada y cuál trae el
# marketplace, y qué hacer si no coinciden. Deja puestas:
#     VER_CORRE        la del `plugin.json` de <raíz-del-kit>: la que ha cargado esta conversación
#     VER_INSTALADA    la que Claude Code tiene instalada, o vacía si no se puede leer
#     VER_CLON         la del clon local del marketplace, o vacía si no lo hay
#     KIT_CLON         el directorio de ese clon, o vacío
#     KIT_ID           `<nombre>@<marketplace>`, que es como lo nombra `claude plugin`
#     CONSEJO_VERSION  qué hacer, en una frase, o vacío si no hay nada que hacer
#
# Se llama SIN subshell. Solo LEE: ni red ni escritura. Tres versiones y no dos: con solo la
# que corre y la del clon no se distingue «falta actualizar» de «la actualización está
# instalada y esta conversación sigue con la vieja». LÍMITES: `installed_plugins.json` es un
# fichero interno de Claude Code, no un contrato; sin clon del marketplace se calla; con el
# kit cargado desde un directorio de desarrollo el consejo no aplica y no se detecta.
#
# SC2034: `CONSEJO_VERSION` se lee en los scripts que cargan esta lib, no aquí.
# shellcheck disable=SC2034
version_kit() {
    VER_CORRE=""; VER_INSTALADA=""; VER_CLON=""; KIT_CLON=""; KIT_ID=""; CONSEJO_VERSION=""
    [ -f "$1/.claude-plugin/plugin.json" ] || return 0
    local nombre d c nueva
    VER_CORRE="$(version_json < "$1/.claude-plugin/plugin.json")"
    nombre="$(sed -n 's/.*"name": *"\([^"]*\)".*/\1/p' "$1/.claude-plugin/plugin.json" | head -1)"
    KIT_ID="$nombre"
    for d in "$HOME"/.claude/plugins/marketplaces/*/; do
        c="${d%/}"
        [ -f "$c/.claude-plugin/plugin.json" ] || continue
        grep -q "\"name\": *\"$nombre\"" "$c/.claude-plugin/plugin.json" || continue
        KIT_CLON="$c"
        VER_CLON="$(version_json < "$c/.claude-plugin/plugin.json")"
        KIT_ID="$nombre@${c##*/}"
        break
    done

    # La de ámbito `user` si hay varias: es la que se instala para todas las conversaciones.
    if [ -n "$KIT_CLON" ]; then
        VER_INSTALADA="$(KIT_ID="$KIT_ID" python3 -c '
import json, os
try:
    ruta = os.path.expanduser("~/.claude/plugins/installed_plugins.json")
    e = json.load(open(ruta))["plugins"].get(os.environ["KIT_ID"]) or []
    e = [x for x in e if x.get("scope") == "user"] or e
    print(e[0].get("version", ""))
except Exception:
    pass
' 2>/dev/null)"
    fi

    nueva="abre una conversación nueva: una reanudada puede seguir con la versión con la que empezó"
    if [ -n "$VER_INSTALADA" ]; then
        if [ -n "$VER_CLON" ] && [ "$VER_CLON" != "$VER_INSTALADA" ]; then
            CONSEJO_VERSION="instalada la $VER_INSTALADA y el marketplace trae la $VER_CLON → claude plugin update $KIT_ID, y después $nueva"
        elif [ "$VER_INSTALADA" != "$VER_CORRE" ]; then
            CONSEJO_VERSION="esta conversación corre la $VER_CORRE y está instalada la $VER_INSTALADA → $nueva"
        fi
    elif [ -n "$VER_CLON" ] && [ "$VER_CLON" != "$VER_CORRE" ]; then
        CONSEJO_VERSION="corriendo $VER_CORRE, instalable $VER_CLON → claude plugin update $KIT_ID, y después $nueva"
    fi
}
