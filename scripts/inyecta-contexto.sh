#!/usr/bin/env bash
# Hook UserPromptSubmit: pone el acuerdo delante del modelo en CADA turno.
#
# Contra la deriva no sirve obligar a leer una skill: el modelo cree que se acuerda y no
# relee. Lo que sí sirve es que el texto esté delante otra vez, siempre, y que sea CORTO —
# un digest que se lee, no un documento que se ignora.
#
# Inyecta cinco cosas y ninguna más:
#   0. DE QUÉ REPOSITORIO habla,
#   1. las reglas innegociables (las que no puede comprobar ningún linter),
#   2. el cambio OpenSpec activo, con lo que queda por hacer y lo que está FUERA de alcance,
#   3. qué dependencias traen reglas propias — SOLO si las hay,
#   4. si la firma de verificación corresponde al árbol actual.
#
# La 3 es condicional, y por eso este recuento ya ha estado mal dos veces: en un repositorio
# sin dependencias resueltas —como este mismo— salen cuatro, y quien cuente ahí escribirá
# «cuatro». Lo cazó el revisor el 2026-09-08, contando sobre un repo que sí las tenía.
#
# POR QUÉ EL PUNTO 0. Este hook lee el repositorio del directorio que hereda de la sesión,
# y ese no tiene por qué ser aquel en el que se está trabajando: el plugin se instala para
# el usuario, no para un proyecto. El 2026-09-07 estuvo una sesión entera afirmando «Sin
# cambio OpenSpec activo» mientras el repositorio real tenía uno con siete tareas hechas.
# Nombrar el repositorio NO arregla el desfase —no hay señal disponible de dónde trabaja el
# modelo, y adivinarlo sería peor que callarse—, pero convierte una afirmación falsa sobre
# el trabajo en curso en una afirmación cierta y atribuida. El día que Claude Code dé al
# hook el repositorio de la tarea, esto se sustituye.
#
# NO ESCRIBE NADA DENTRO DEL REPOSITORIO OBSERVADO. Antes creaba `.agent-kit/` para su
# caché, en cualquier repositorio por el que pasara una sesión, usara el kit o no.
set -uo pipefail

# `$DIR` se resuelve ANTES del `cd`: después, una invocación relativa desde un subdirectorio
# ya no encontraría la lib.
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
. "$DIR/lib-kit.sh"

RAIZ="$(git rev-parse --show-toplevel 2>/dev/null)" || exit 0
[ -n "$RAIZ" ] || exit 0
cd "$RAIZ" || exit 0

# El JSON que este hook emite debe declarar, en `hookEventName`, el evento que lo invocó —
# así lo exige la documentación de Claude Code—, y el mismo script está registrado en DOS
# eventos: `UserPromptSubmit` en cada turno, y `SessionStart` con el matcher `compact`, para
# reinyectar el acuerdo justo cuando compactar se lo come. El evento invocante viaja en el
# JSON de stdin, en el campo `hook_event_name`; sin señal reconocible, se asume
# `UserPromptSubmit`, que es el caso mayoritario y el comportamiento de antes de este cambio.
#
# LÍMITE DECLARADO: lo que se fija aquí es la FORMA del JSON —que el nombre emitido sea el
# del evento invocante—. Que el efecto se note de verdad, que el acuerdo reaparezca tras una
# compactación real, solo se ve compactando una sesión real con el plugin instalado; esa
# prueba vive fuera de este repositorio y el banco no puede fijarla.
#
# CON TOPE DE TIEMPO, y esto no es prudencia de más. `[ -t 0 ]` solo reconoce el caso
# terminal; si stdin es un pipe ABIERTO que nunca cierra —un invocador que no cierra la
# entrada, un arranque desde otro proceso— un `cat` se queda esperando EOF para siempre y este
# hook corre ANTES de cada turno: colgarlo es colgar la sesión. Reproducido el 2026-09-08 con
# `bash inyecta-contexto.sh < <(sleep 300)`: ocho minutos vivo hasta que lo maté a mano, y lo
# encontró una medición de coste que se quedó parada, no una prueba.
#
# El riesgo NACE con la lectura de stdin: antes de este cambio el hook no leía la entrada, así
# que no podía colgarse. `read -t 1 -d ""` devuelve en cuanto llega EOF —el caso de siempre— y
# corta al segundo si no llega nunca; sin el JSON solo se pierde saber qué evento invoca, y de
# eso ya hay un valor por defecto.
#
# AQUÍ SOLO SE LEE. Quién invoca se decide abajo, en el MISMO `python3` que serializa la
# salida, y eso no es preferencia de estilo: es la regla que `analiza-invocacion.py` ya lleva
# escrita en su cabecera —«leer el JSON en un `python3 -c` aparte y analizar en otro costaba
# dos arranques de intérprete en CADA comando: +12,6 ms sobre 30 iteraciones»—. Este hook
# corre en cada turno, así que paga lo mismo. La primera versión de este bloque arrancaba un
# intérprete solo para mirar `hook_event_name`: medido el 2026-09-08, 20,9 ms por turno sobre
# 30 iteraciones — más caro que lo que aquella cabecera ya se negó a pagar.
ENTRADA=""
[ -t 0 ] || IFS= read -r -t 1 -d '' ENTRADA 2>/dev/null || true

L=""
add() { L="${L}$1"$'\n'; }

add "· Repo: ${RAIZ##*/} — $RAIZ"
add "  (lo de abajo es de ESE repositorio; si estás trabajando en otro, no es su acuerdo)"

add "· Reglas que ningún linter puede comprobar por ti:"
add "    - El acuerdo manda: si el código y openspec/ discrepan, se corrige el código o se"
add "      renegocia el acuerdo POR ESCRITO. Nunca se reescribe el acuerdo para que encaje."
add "    - Antes de escribir una función, busca si ya existe: /kit-duplicados."
add "    - Fuera de alcance es fuera de alcance, incluso si 'ya que estamos'."

# Tres situaciones, no dos. Antes, un repositorio sin `openspec/` salía por la misma rama
# que uno que lo tiene y no está usándolo, y recibía la misma orden: «primero
# /opsx:propose». Sobre un repositorio que no usa OpenSpec, eso es un consejo que nadie
# puede seguir ahí.
if [ ! -d openspec ]; then
    add "· Este repositorio no usa OpenSpec — aquí no hay acuerdo que consultar."
else
    cambio_activo
    ACT="$ACTIVO"
    if [ -n "$ACT" ]; then
        add "· Cambio activo: ${ACT##*/}"
        # Callarse cuál de los dos se ha elegido es peor que elegir: el digest afirmaría
        # cosas de un acuerdo mientras se trabaja en el otro, que es el mismo fallo que
        # arregló la línea de atribución del repositorio.
        [ "$ACTIVOS_N" -gt 1 ] && add "    ⚠️  hay $ACTIVOS_N cambios activos; este es el primero por orden, no necesariamente el tuyo."
        # `grep -c` imprime "0" Y sale con estado 1 cuando no hay coincidencias. El idiom
        # `$(grep -c ... || echo 0)` no lo sabe: con cero pendientes, grep YA imprimió "0" y
        # el `|| echo 0` ve el estado de salida no-cero y añade un SEGUNDO "0", dejando
        # PEND="0\n0" —dos líneas, una detrás de otra—. En bash 3.2 —el de macOS, el que
        # resuelve `#!/usr/bin/env bash`— expandir `$((TOT-PEND))` con ese valor es un error
        # de sintaxis en la expresión aritmética, y ese error aborta el COMPOUND ENTERO (el
        # `if [ -n "$ACT" ]; then … fi` de arriba), no solo esta línea: se pierden en
        # silencio "tareas:", la lista de pendientes y el "FUERA de alcance", y el mensaje de
        # error queda escrito en stderr. Reproducido el 2026-09-08 con un `tasks.md` de cero
        # pendientes contra la versión de este hook anterior a este cambio.
        #
        # El arreglo es el idiom que YA usa `rodaja.sh` con el mismo `grep -c` (línea con
        # `printf '%s\n' "$D" | grep -c ... || true`): `|| true` en vez de `|| echo 0`, que
        # no imprime nada, así que no hay segundo "0" que sumar. Y para que "cero
        # coincidencias" siga imprimiendo "0" en vez de nada —que es lo que pasa si
        # `tasks.md` no llega a abrirse—, el contenido se pasa por `printf` en vez de dejar
        # que `grep` abra el fichero: un `printf` con salto de línea le da a `grep -c` una
        # entrada bien formada exista o no el fichero, igual que hace `rodaja.sh` con `$D`.
        TASKS="$(cat "$ACT/tasks.md" 2>/dev/null)"
        PEND="$(printf '%s\n' "$TASKS" | grep -c '^- \[ \]' || true)"
        TOT="$(printf '%s\n' "$TASKS" | grep -cE '^- \[[ x]\]' || true)"
        add "    tareas: $((TOT-PEND))/$TOT hechas"
        # Sin fichero intermedio. Esto pasaba por `/tmp/.ic.$$`: un nombre derivable del
        # identificador de proceso, en un directorio donde escribe cualquiera, y escrito por
        # un hook que corre en CADA turno de CUALQUIER repositorio por el que pase una
        # sesión. Para componer tres líneas de texto no hace falta tocar el disco, y menos
        # ahí. Es la misma regla que este hook ya cumplía —no escribir dentro del repositorio
        # observado— aplicada al único sitio donde todavía escribía.
        if [ "$PEND" -gt 0 ]; then
            PENDIENTES="$(grep '^- \[ \]' "$ACT/tasks.md" 2>/dev/null | head -3 | sed 's/^/    /')"
            [ -n "$PENDIENTES" ] && L="${L}${PENDIENTES}"$'\n'
        fi
        FUERA="$(sed -n '/## Fuera de alcance/,/^## /p' "$ACT/proposal.md" 2>/dev/null | grep '^- ' | head -3)"
        [ -n "$FUERA" ] && { add "    FUERA de alcance:"; L="${L}$(printf '%s\n' "$FUERA" | sed 's/^/      /')"$'\n'; }
    else
        add "· Sin cambio OpenSpec activo. Si vas a tocar código, primero /opsx:propose."
    fi
fi

# Los paquetes de los que depende el proyecto traen sus propias reglas, y viven en rutas
# que git ignora (`.build/checkouts`, `DerivedData/.../SourcePackages`). Nadie las encuentra
# solo. No se inyecta la doc —envejece y ocupa—, se inyecta que EXISTE y cómo llegar.
#
# Se cachea: este hook corre en CADA turno y un `find` sobre DerivedData no es gratis. El
# nombre de las dependencias cambia como mucho cuando se toca un Package.swift.
#
# El caché vive FUERA del repositorio observado, con la ruta del repositorio en la clave.
# Fuera, porque si no acaba creando `.agent-kit/` en repositorios que nunca pidieron el
# kit. Y con el repositorio en la clave porque, sin eso, un caché compartido serviría las
# dependencias de un proyecto a otro — un fallo peor que el que arregla, porque el dato
# equivocado parece correcto.
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/ios-agent-kit"
CACHE="$CACHE_DIR/$(printf '%s' "$RAIZ" | shasum -a 256 | cut -c1-32).paquetes"
mkdir -p "$CACHE_DIR" 2>/dev/null
if [ -z "$(find "$CACHE" -mtime -1 2>/dev/null)" ]; then
    # ACOTAR A ESTE REPOSITORIO. Medido el 2026-09-08: sin filtrar, el `find` recorría TODO
    # `~/Library/Developer/Xcode/DerivedData`, y este mismo repositorio —que tiene CERO
    # ficheros .swift— anunciaba "AppFoundation CoreNetworking": dependencias de AppStarter y
    # DemoMulti, otros proyectos de la misma máquina. Un repositorio vacío recién creado en
    # /tmp recibía la misma frase. Es justo el fallo que el comentario de arriba ya declara
    # peor que el que arregla: el caché ya era uno por repositorio, pero los cachés de la
    # máquina contenían todos la misma respuesta de la máquina entera.
    #
    # HEURÍSTICA, DECLARADA (no hay forma barata de hacerlo exacto): Xcode nombra cada
    # carpeta de DerivedData "<Proyecto>-<hash>", donde <Proyecto> es el nombre del
    # .xcodeproj o .xcworkspace — un dato que este script no tiene sin abrir el proyecto. Se
    # aproxima con el nombre del directorio del repositorio (`${RAIZ##*/}`): coincide en el
    # caso común, clonar y abrir sin renombrar la carpeta.
    #
    # QUÉ SE PIERDE. (a) Falso negativo: si el .xcodeproj se llama distinto del directorio
    # que lo contiene —un monorepo, una carpeta renombrada tras clonar—, este repositorio no
    # encuentra su propio DerivedData y el hook calla en vez de anunciar dependencias que sí
    # existen. Es el lado seguro del error: callarse es preferible a servir la respuesta de
    # otro proyecto, que es el fallo que este bloque corrige. (b) No llega a cero: dos
    # repositorios distintos que compartan nombre de carpeta en la misma máquina seguirían
    # compartiendo el filtro por prefijo —Xcode los distingue por el hash, no este script—,
    # pero eso es una colisión de nombre, no el recorrido de la máquina entera de hoy.
    #
    # `nullglob` es lo que hace que, sin ninguna carpeta que empiece por "$PROYECTO-", el
    # array quede VACÍO en vez de con el patrón literal sin expandir; y la expansión de más
    # abajo es lo que evita que ese array vacío tumbe el script entero bajo `set -u` — en bash
    # 3.2 (el de macOS) expandir "${arr[@]}" de un array con cero elementos es "unbound
    # variable" y aborta el script, no solo esa línea. Probado el 2026-09-08 contra ese bash.
    #
    # Se usa `${arr[@]+"${arr[@]}"}` y no `"${arr[@]:-}"`, que es lo que había: el segundo pasa
    # a `find` un argumento de ruta VACÍO cuando el array está vacío. BSD find lo tolera y
    # sigue procesando `.`, pero es una tolerancia con la que no hay por qué contar — y el
    # idiom correcto ya estaba escrito en `doc-paquetes.sh`, que es donde había que mirar
    # antes de escribir el otro.
    PROYECTO="${RAIZ##*/}"
    shopt -s nullglob
    DD_PROPIO=("$HOME/Library/Developer/Xcode/DerivedData/${PROYECTO}-"*)
    shopt -u nullglob

    # `-print0` y un `while read -d ''`: el `xargs` de antes partía por espacios y se comía
    # cualquier ruta con un espacio dentro, que en DerivedData las hay.
    while IFS= read -r -d '' f; do
        b="${f%/*}"        # dirname
        printf '%s\n' "${b##*/}"   # basename
    done < <(find . ${DD_PROPIO[@]+"${DD_PROPIO[@]}"} -maxdepth 6 \
                  -name AGENTS.md -path "*checkouts*" -print0 2>/dev/null) \
        | sort -u | tr '\n' ' ' > "$CACHE" 2>/dev/null
fi
DEPDOC="$(cat "$CACHE" 2>/dev/null)"
[ -n "$DEPDOC" ] && add "· Estos paquetes traen sus PROPIAS reglas y no están en el repo: ${DEPDOC}— rutas con /kit-doc."

# Solo LECTURA: si el fichero no está, no se crea. Lo escribe `verifica.sh`, que es quien
# tiene algo que firmar.
M="$RAIZ/.agent-kit/verificacion.txt"
if [ -f "$M" ]; then
    grep -q "^diff: $(git diff --cached | shasum -a 256 | cut -d' ' -f1)$" "$M" \
        && add "· Verificación: firmada contra el diff staged actual." \
        || add "· Verificación: la firma es de OTRO diff — /kit-verifica antes de commitear."
else
    add "· Verificación: sin firmar todavía."
fi

# UN solo `python3`: decide el evento invocante y serializa la salida. Ver la nota de arriba.
# Sin señal reconocible se asume `UserPromptSubmit`, que es el caso mayoritario y el
# comportamiento de antes de que este hook mirase el evento.
ENTRADA_HOOK="$ENTRADA" DIGESTO="$L" python3 - <<'FIN'
import json, os, sys
evento = "UserPromptSubmit"
try:
    if json.loads(os.environ.get("ENTRADA_HOOK") or "{}").get("hook_event_name") == "SessionStart":
        evento = "SessionStart"
except Exception:
    pass
sys.stdout.write(json.dumps({"hookSpecificOutput": {
    "hookEventName": evento,
    "additionalContext": "📌 Acuerdo vigente (inyectado, no lo pidas de nuevo):\n"
                         + os.environ.get("DIGESTO", ""),
}}) + "\n")
FIN
