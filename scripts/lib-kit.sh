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

# huella_diff — el sha256 de una FOTO DEL ÁRBOL DE TRABAJO, salvo `openspec/` y `.agent-kit/`.
# El árbol es lo que se compila y lo que se prueba, así que es lo que se firma.
#
# La foto la hace GIT, no este script: un índice aparte, `git add -A` y `write-tree`. El id de
# ese árbol ES la huella. Así entra lo que git sabe y nosotros no: submódulos (su commit),
# enlaces simbólicos (su destino, roto o no), permisos, borrados, y cualquier nombre de
# fichero —comillas, tabuladores, acentos, emoji— sin parsear una sola ruta.
#
# El índice y los objetos viven en `~/.cache/ios-agent-kit/foto/<hash de la raíz>` y SOBREVIVEN
# entre llamadas: son un caché. Sin él, cada foto rehashea el árbol entero y el hook de cada
# turno se va a segundos en un proyecto de verdad; con él, `add -A` solo toca lo que haya
# cambiado. Fuera del repositorio por dos razones: dentro, `add -A` se encontraría el propio
# caché y se añadiría a sí mismo mientras git escribe ahí —medido: la foto fallaba—, y
# preguntar por la firma no puede crear `.agent-kit/` en un repositorio que no pidió el kit.
# Es caché y nada más: borrarlo es siempre seguro y la siguiente foto lo reconstruye.
#
# Se hace `cd` a la raíz del repositorio: los pathspecs son relativos al directorio actual, y
# sin esto la huella cambiaría según desde dónde se llame —y las exclusiones no se aplicarían—.
#
# Esa es la lección de las dos rondas del revisor del 2026-09-20: la primera versión leía
# `git diff --name-only` y decidía con `[ -e ]`; con `core.quotePath` en true —su valor por
# defecto— una ruta con `ñ` salía citada, no se encontraba, y su contenido NO se hasheaba
# nunca, así que reescribirla entera tras firmar no movía la huella. Apagar el entrecomillado
# tapaba ese caso y dejaba los otros tres: comillas y tabuladores en el nombre, enlaces rotos
# y submódulos.
#
# **No depende del índice, a propósito.** Parte del índice solo para heredar su caché de
# stat —si no, cada foto rehashearía el árbol entero—, pero el `add -A` lo pone al día contra
# el árbol, así que lo que esté o no stageado no cambia el resultado. Stagear lo que ya se
# verificó, incluidos los ficheros nuevos que escribe `/kit-init`, no invalida la firma. Del
# índice se ocupa `indice_divergente`, abajo: son dos preguntas distintas.
#
# **No escribe en tu repositorio.** Los objetos que `add`/`write-tree` necesitan crear van al
# caché (`GIT_OBJECT_DIRECTORY`), con el del repositorio como alternativa de solo lectura.
# Medido: el número de objetos sueltos del repo no cambia.
#
# **Falla cerrada:** si algo impide fotografiar el árbol —un fichero sin permiso de lectura,
# un filtro de `.gitattributes` que no está instalado— devuelve 1 e imprime un `SIN-HUELLA…`
# IRREPETIBLE. Irrepetible a propósito: con una constante, un fallo que persiste se firma y
# después cuadra consigo mismo, y la puerta deja pasar cualquier árbol.
#
# Sin `openspec/`, porque es el acuerdo y no lo que se compila, y OpenSpec escribe ahí justo
# después de verificar: marcar tareas o archivar invalidaba una firma cuyo código no cambió.
# Sin `.agent-kit/` SIEMPRE, lo ignore el proyecto o no: es donde vive la propia firma, y
# dentro de la foto escribirla invalidaría la firma recién escrita.
#
# Única definición: la usan quien firma (`verifica.sh`), el hook `pre-commit` que genera (la
# copia con `declare -f`) y el digest de cada turno.
#
# LÍMITES DECLARADOS: lo que git ignora (`.gitignore`) no está en la foto, que es lo que se
# quiere —`build/`, `DerivedData/`—; lo que vive en `openspec/` tampoco, así que si un
# `kit.conf` verifica algo de ahí, un cambio posterior en ese directorio no lo invalida.
# caché_foto — imprime el directorio donde vive el caché de la foto de ESTE repositorio.
# Una sola definición: la usan la foto y quien la limpia.
cache_foto() {
    local raiz
    raiz="$(git rev-parse --show-toplevel 2>/dev/null)" || return 1
    printf '%s/ios-agent-kit/foto/%s\n' "${XDG_CACHE_HOME:-$HOME/.cache}" \
        "$(printf '%s' "$raiz" | shasum -a 256 | cut -c1-16)"
}

# limpia_copias_viejas — tira las copias del índice que dejó una foto que no llegó a terminar
# (un Ctrl-C, una sesión que se cae). Solo las de más de una hora: a esa edad ninguna está en
# uso, y una foto en marcha no puede quedarse sin la suya. Se llama al VERIFICAR, una vez por
# firma, y no en cada foto: ahí costaría un proceso por turno para limpiar lo que casi nunca
# hay. Lo cazó el revisor: sin esto se acumulan para siempre.
limpia_copias_viejas() {
    local c
    c="$(cache_foto)" || return 0
    find "$c" -name 'indice.??????' -mmin +60 -delete 2>/dev/null
    return 0
}

huella_diff() {
    local raiz cache idx obj mio arbol alternativos rutas
    # Las dos rutas en UNA llamada: arrancar git cuesta ~60 ms en un portátil, y esto corre en
    # el hook de cada turno. `--git-path objects` y no `$raiz/.git/objects`: con un worktree
    # enlazado o un submódulo, el directorio de objetos no está donde parece.
    rutas="$(git rev-parse --show-toplevel --git-path objects 2>/dev/null)" || return 1
    raiz="$(printf '%s\n' "$rutas" | head -1)"
    alternativos="$(printf '%s\n' "$rutas" | tail -1)"
    # `--git-path` sale relativo al directorio ACTUAL, y abajo se hace `cd` a la raíz: se
    # absolutiza aquí, antes de moverse.
    case "$alternativos" in /*) ;; *) alternativos="$PWD/$alternativos" ;; esac
    # El caché vive FUERA del repositorio, junto al de dependencias. Dentro no puede: `add -A`
    # se lo encontraría y se añadiría a sí mismo mientras git escribe ahí, y la foto fallaba.
    # Además, preguntar por la firma no debe crear `.agent-kit/` en un repo que no pidió el kit.
    cache="$(cache_foto)" || { fallo_sin_huella; return 1; }
    idx="$cache/indice"
    obj="$cache/objetos"
    mkdir -p "$obj" 2>/dev/null || { fallo_sin_huella; return 1; }
    # Cada foto trabaja sobre su PROPIA copia del índice y la devuelve al terminar. El índice
    # compartido se lo disputarían dos fotos simultáneas —una sesión y un `git commit` en otra
    # terminal, o el digest y la puerta a la vez—: `git add` pierde el `index.lock` y el
    # perdedor rechazaba un commit legítimo. Medido por el revisor: 8 de 20 con dos fotos a la
    # vez. Copiar cuesta un milisegundo y el `mv` final es atómico, así que el caché queda
    # entero gane quien gane.
    # `mktemp` y no `$idx.$$`: dos fotos lanzadas desde el mismo shell comparten `$$` —y
    # también el estado de `$RANDOM`—, así que se pisarían el fichero entre ellas.
    mio="$(mktemp "$idx.XXXXXX" 2>/dev/null)" || { fallo_sin_huella; return 1; }
    # Si todavía no hay caché, el temporal se BORRA: `mktemp` lo deja vacío y git rechaza un
    # índice de cero bytes. Sin fichero, git lo crea él.
    cp "$idx" "$mio" 2>/dev/null || rm -f "$mio"
    arbol="$(
        cd "$raiz" || exit 1
        export GIT_INDEX_FILE="$mio" GIT_OBJECT_DIRECTORY="$obj"
        export GIT_ALTERNATE_OBJECT_DIRECTORIES="$alternativos"
        # `openspec/` se excluye al AÑADIR, así no entra nunca en el índice del caché y no hay
        # que rehashearlo en cada foto. `.agent-kit/` no se puede excluir ahí: nombrar en el
        # pathspec de `add` una ruta que el proyecto ignora hace que salga con 1 aunque el
        # árbol esté bien, y aquí el código de salida tiene que poder creerse. Se quita del
        # índice después, y donde el proyecto ya lo ignora eso no cuesta nada.
        git --no-literal-pathspecs add -A -- ':(top)' ':(top,exclude)openspec/' >/dev/null 2>&1 \
            && git --no-literal-pathspecs rm -r --cached -q --ignore-unmatch -- ':(top).agent-kit/' >/dev/null 2>&1 \
            && git write-tree 2>/dev/null
    )"
    # Un valor IRREPETIBLE, no una constante: si fuera fija y la causa del fallo siguiera ahí
    # —un fichero sin permiso de lectura, un filtro de .gitattributes que no está instalado—,
    # la firma guardaría esa cadena, quien comprueba recalcularía la misma, cuadrarían, y la
    # puerta dejaría pasar cualquier árbol. Lo cazó el revisor el 2026-09-20 con reproducción.
    # Quien firma además mira el código de salida y se niega a firmar.
    if [ -n "$arbol" ]; then
        mv -f "$mio" "$idx" 2>/dev/null || rm -f "$mio"
    else
        # El caché se TIRA cuando la foto falla: si el índice quedó corrupto, copiarlo otra vez
        # repetiría el fallo para siempre —tres fotos seguidas en rojo, medido por el revisor—,
        # y es un caché: reconstruirlo cuesta una foto. Con esto, el estado corrupto se cura
        # solo, como ya hacía el índice ilegible.
        rm -f "$mio" "$idx"
        fallo_sin_huella
        return 1
    fi
    printf '%s' "$arbol" | shasum -a 256 | cut -d' ' -f1
}

# fallo_sin_huella — el valor que imprime la foto cuando no puede. Cambia ENTRE PROCESOS, que
# es donde importa: quien firma es un proceso y quien comprueba es otro, así que una firma
# escrita con este valor no puede cuadrar con la comprobación siguiente. Dentro del mismo
# proceso y llamado desde `$( )` sí se repite —la subshell hereda `$$`, `$RANDOM` y no devuelve
# el contador—, y eso está medido y aceptado: ningún llamador lo pide dos veces, y lo que cierra
# el agujero de verdad es que `verifica.sh` se niegue a firmar.
fallo_sin_huella() {
    : "${KIT_FOTOS_FALLIDAS:=0}"
    KIT_FOTOS_FALLIDAS=$((KIT_FOTOS_FALLIDAS + 1))
    echo "SIN-HUELLA-$$-${RANDOM}-${KIT_FOTOS_FALLIDAS}-$(date +%s)"
}

# indice_divergente — las rutas stageadas cuyo contenido NO es el del árbol. Vacío es que el
# índice no lleva nada que la huella no cubra.
#
# Es la otra mitad de la firma, y la que cierra el agujero que la huella del árbol sola deja
# abierto: stagear contenido y después devolver el fichero a su contenido de `HEAD` deja el
# árbol igual que al firmar, mientras `git commit` a secas se lleva el índice.
#
# La intersección de «rutas stageadas» (índice contra `HEAD`) con «rutas cuyo índice y árbol
# difieren» (`git diff` a secas). Si una ruta está en las dos, lo stageado no es lo verificado.
# Por rutas y no por contenido porque `git diff --name-only` ya compara contenido, y porque
# una lista de rutas es lo que hay que enseñar al bloquear. Mismos pathspecs que la huella,
# `openspec/` excluido incluido: el acuerdo no es lo que se compila. Única definición: la usan
# `verifica.sh`, su `--comprueba` y el hook que genera.
indice_divergente() {
    comm -12 \
        <(git -c core.quotePath=false --no-literal-pathspecs diff --cached --name-only -- ':(top)' ':(top,exclude)openspec/' ':(top,exclude).agent-kit/' | sort) \
        <(git -c core.quotePath=false --no-literal-pathspecs diff --name-only -- ':(top)' ':(top,exclude)openspec/' ':(top,exclude).agent-kit/' | sort)
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
