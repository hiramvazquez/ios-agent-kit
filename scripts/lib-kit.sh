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
# Se llama SIN subshell —`cambio_activo` y luego `$ACTIVO`, nunca `$(cambio_activo)`— porque
# devuelve tres cosas y una sustitución de comandos se comería las otras dos.
#
# `ACTIVOS` es una cadena y no un array: expandir un array vacío bajo `set -u` aborta en bash
# 3.2, que es lo que `derivados_propios` tiene que esquivar más abajo.
#
# Vive aquí porque la usan el hook de contexto, `rodaja.sh` y `estado.sh`, y copiada ya se cobró
# un fallo: cada copia elegía con `head -1` sobre un `find`, o sea por el orden del sistema de
# ficheros, así que con dos cambios abiertos el digest podía hablar de uno mientras la marca de
# revisión copiaba las tareas del otro.
#
# El orden lo fija `LC_ALL=C sort`, para que no dependa del sistema de ficheros ni del idioma
# de la máquina. Cuál es «el» activo cuando hay varios sigue siendo arbitrario, pero arbitrario
# y ESTABLE, y quien llama puede decir que hay más de uno en vez de callárselo.
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
# Las dos VACÍAS si el cambio no tiene `tasks.md`, y no a cero: un cambio pequeño no lleva lista
# —lo recomienda `docs/FLUJO.md`—, y «tareas: 0/0 hechas» se lee como «no queda nada por hacer»
# cuando lo cierto es que ese cambio no tiene lista. Quien llama mira `TAREAS_TOTAL` vacía.
#
# Se llama SIN subshell, por lo mismo que `cambio_activo`.
#
# `|| true` y NO `|| echo 0`: `grep -c` imprime "0" Y sale con estado 1 cuando no hay
# coincidencias, así que el segundo idiom añade un SEGUNDO "0" y deja "0\n0". En bash 3.2 —el de
# macOS— expandir la resta de abajo con eso es un error de expansión aritmética, y ese error
# aborta el COMPOUND ENTERO de quien llama: en el hook se perdían en silencio "tareas:", la lista
# de pendientes y el "FUERA de alcance", justo en el turno en que el cambio está terminado y más
# mandan. El contenido va por `printf` en vez de dejar que `grep` abra el fichero, para que "cero
# coincidencias" siga imprimiendo "0".
#
# Vive aquí porque la usan el hook de contexto y `estado.sh`, y la trampa de arriba no se ve
# reescribiéndola de memoria.
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

# huella_diff — el sha256 de lo que hay que firmar: el ÁRBOL DE TRABAJO **y** el ÍNDICE, los dos.
#
# LOS DOS, y cada uno cierra un agujero distinto:
#
#   - El ÁRBOL es lo que `verificaciones()` compila, y lo que se lleva un `git commit -a` o un
#     pathspec. Firmando solo el índice, verificar sin nada stageado firma el diff VACÍO y esa
#     firma sigue valiendo después de editar.
#   - El ÍNDICE es lo que se lleva un `git commit` a secas. Firmando solo el árbol, stagear
#     veneno y devolver el fichero a su contenido de HEAD deja la huella igual, y se commitea
#     algo que nunca se compiló.
#
# EL SEPARADOR TAMPOCO ES ADORNO: pegados sin marca, el hunk del último fichero por orden puede
# migrar del diff del árbol al del índice sin cambiar un byte, y la huella no se mueve.
#
# CONSECUENCIA ASUMIDA: stagear después de firmar cambia el índice y por tanto invalida la
# firma. Por eso stagear, verificar y commitear van en comandos separados. Es el lado correcto
# en el que equivocarse: lo contrario es dejar pasar contenido que nadie miró.
#
# Sin ningún commit todavía no hay `HEAD` con el que comparar —`git diff HEAD` falla—, y ahí el
# índice es la única referencia que existe.
#
# Vive aquí porque la usan `verifica.sh` —que firma— y el hook de contexto —que dice si la firma
# vale—: si las dos no dan el mismo número, el digest anuncia «la firma es de OTRO árbol» en
# cada turno de un árbol recién firmado.
huella_diff() {
    if git rev-parse --verify --quiet HEAD >/dev/null 2>&1; then
        { git diff HEAD; echo '--- índice ---'; git diff --cached; }
    else
        git diff --cached
    fi | shasum -a 256 | cut -d' ' -f1
}

# toolchain — imprime en UNA línea con qué se ha verificado.
#
# POR QUÉ EXISTE. La firma decía «verificado» y lo único que puede decir es «verificado con el
# toolchain de esta máquina». El 2026-09-17 AppStarter llevaba doce corridas de CI en rojo con la
# firma local en verde: el diagnóstico que lo tumbaba lo produce Swift 6.2.4 —el del CI— y no lo
# produce Swift 6.4 —el de aquí—. Ninguna firma local puede ver eso; lo que sí puede es decir con
# qué corrió, para que quien lea el verde sepa qué le falta.
#
# Vive aquí, y no en `verifica.sh`, por lo mismo que `huella_diff`: la escribe quien firma y la
# LEEN el digest y `/kit-estado`. Pero esos dos leen la línea del marker, no vuelven a llamar
# aquí — detectar cuesta 0,3 s, despreciable una vez por verificación e inaceptable en un hook
# que corre en cada turno.
#
# UNA LÍNEA, y corta: la consume el digest, que se inyecta en cada turno. `Swift 6.4 · Xcode
# 27.0` dice lo que hace falta; el build number no distingue nada que importe para esto.
#
# LA DIVERGENCIA que avisa es la que costó un día el 2026-09-15: el `swift` del PATH era el de
# swiftly (6.3.3) mientras Xcode traía 6.4, y el build moría en `build-tool plugin failures` sin
# compilar una línea, con un diagnóstico que no nombra el toolchain. Se AVISA, no se bloquea:
# hay proyectos que usan un toolchain de swift.org a propósito.
#
# LÍMITE DECLARADO. Esto describe el entorno, no lo valida: si no hay nada que interrogar dice
# «no identificado» y sale con 0. Un paso que aborta por no poder describir el entorno convierte
# un dato informativo en una puerta, y el kit se usa en repositorios sin Xcode.
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
# Separada de `toolchain` porque se interroga DOS veces —el del PATH y el de `xcrun`— y la
# comparación de las dos es el aviso de divergencia. `head -1` porque `swift --version` imprime
# también la línea del target, que aquí no aporta.
#
# El patrón NO exige «Apple»: un toolchain de swift.org en Linux anuncia `Swift version 6.0.3`,
# y con el prefijo obligatorio esta función lo saltaba en silencio y la línea acabava
# atribuyendo la corrida al Swift de `xcrun` — afirmando un compilador que no ejecutó los pasos.
# Lo encontró el revisor; en macOS no es alcanzable, pero el modo de fallo era mentir, no callar.
version_swift() {
    "$@" --version 2>/dev/null | sed -n 's/.*Swift version \([0-9][0-9.]*\).*/\1/p' | head -1
}

# derivados_propios <raíz> — deja una variable puesta:
#     DD_PROPIO  array con los directorios de DerivedData que son de ESE repositorio
#
# Se llama SIN subshell, por lo mismo que `cambio_activo`: un array no sobrevive a una
# sustitución de comandos.
#
# POR QUÉ EXISTE. Sin acotar, un `find` sobre `~/Library/Developer/Xcode/DerivedData` devuelve
# los paquetes de TODOS los proyectos de la máquina, y el kit anuncia a un repositorio las
# dependencias de otro. Vive aquí y no copiada en los dos sitios que la usan —el hook de
# contexto y `doc-paquetes.sh`— porque copiarla ya dejó una de las dos sin arreglar.
#
# LA HEURÍSTICA, DECLARADA. Xcode nombra cada carpeta `<Proyecto>-<hash>`, donde `<Proyecto>`
# es el nombre del `.xcodeproj` o `.xcworkspace` — un dato que no se tiene sin abrir el
# proyecto. Se aproxima con el nombre del directorio del repositorio, que coincide en el caso
# común: clonar y abrir sin renombrar la carpeta.
#
# QUÉ SE PIERDE, en tres formas y NO todas seguras:
#
#   (a) Falso negativo si el `.xcodeproj` se llama distinto de la carpeta que lo contiene —un
#       monorepo, una carpeta renombrada—: no encuentra su propio DerivedData y se calla.
#       Este sí es el lado seguro del error.
#
#   (b) Dos repositorios con el mismo nombre de carpeta comparten el filtro; Xcode los
#       distingue por el hash y esto no.
#
#   (c) **Y este NO es seguro, así que va escrito y no disimulado:** el hash de Xcode no está
#       restringido en el patrón, así que un proyecto cuyo nombre EMPIECE por el tuyo más un
#       guion casa igual. Un repositorio llamado `spm` recibe lo de `spm-pro-<hash>`. Acotarlo
#       de verdad —exigir la forma del hash, o leer el `info.plist` de cada carpeta— es otra
#       decisión con su propia medición. Lo que no se puede es seguir diciendo por ahí que
#       «falla hacia el lado seguro», porque en (c) no lo hace.
#
# `nullglob` hace que, sin ninguna carpeta que case, el array quede VACÍO en vez de con el
# patrón literal. Quien lo use debe expandirlo con `${DD_PROPIO[@]+"${DD_PROPIO[@]}"}`: en bash
# 3.2 expandir `"${arr[@]}"` de un array vacío bajo `set -u` es «unbound variable» y aborta el
# script entero, y `"${arr[@]:-}"` pasa un argumento vacío que no todo `find` tiene por qué
# tolerar.
derivados_propios() {
    local proyecto="${1##*/}" _ng
    # Se RESTAURA el estado previo en vez de apagarlo: un `shopt -u` incondicional destruye el
    # `nullglob` de quien llame, y `shopt -p` imprime justo el comando que lo deja como estaba.
    _ng="$(shopt -p nullglob)"
    shopt -s nullglob
    # SC2034: shellcheck no ve el uso porque está en los scripts que cargan esta lib, no aquí.
    # `cambio_activo` no lo necesita porque lee `ACTIVO` dentro de su propio bucle.
    # shellcheck disable=SC2034
    DD_PROPIO=("$HOME/Library/Developer/Xcode/DerivedData/${proyecto}-"*)
    eval "$_ng"
}

# version_json — la primera `"version"` del JSON que le llega por la entrada estándar.
#
# Por la entrada y no por nombre de fichero, porque `verifica.sh` también la saca de un `git show`.
# Es un `sed` y no un parser, y basta: los `plugin.json` llevan `"version"` una vez, arriba.
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
# Se llama SIN subshell, por lo mismo que `cambio_activo`. Solo LEE: ni red ni escritura. Mirar el
# remoto del marketplace es cosa de `verifica.sh`, una vez al día.
#
# POR QUÉ TRES VERSIONES Y NO DOS. Hasta el 2026-09-15 se comparaba la que corre con la del clon, y
# el consejo era siempre `claude plugin update`. El 2026-09-14 eso aconsejó mal: con la 1.12.2 ya
# instalada, una conversación REANUDADA desde el historial de la app seguía cargando la 1.10.0 —conservó
# la raíz del plugin con la que empezó—, así que actualizar ya estaba hecho y lo que faltaba era una
# conversación nueva. Con `--continue` o `--resume` no está medido.
# Sin mirar la instalada no hay forma de distinguir un caso del otro.
#
# EL ORDEN DE LOS CONSEJOS: si el marketplace trae otra versión que la instalada, actualizar va
# primero y la conversación nueva detrás, en la misma frase. Solo con lo instalado al día queda
# únicamente la conversación.
#
# LÍMITES DECLARADOS:
#   - `installed_plugins.json` es un fichero interno de Claude Code, no un contrato. Si no se puede
#     leer, se compara la que corre con la del clon, que es lo que se hacía antes.
#   - El clon se busca como antes: el primer marketplace cuyo `plugin.json` de raíz lleve el mismo
#     nombre. Sin clon no hay `<marketplace>` con el que buscar la instalada, y se calla.
#   - Con el kit cargado desde un directorio de desarrollo, la que corre y la instalada también
#     difieren, y el consejo de conversación nueva no aplica. No se detecta.
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
