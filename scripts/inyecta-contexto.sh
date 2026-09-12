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
# La 3 es condicional: en un repositorio sin dependencias resueltas salen cuatro, así que quien
# cuente sobre uno de esos escribirá «cuatro».
#
# POR QUÉ EL PUNTO 0. Este hook lee el repositorio del directorio que hereda de la sesión, y ese
# no tiene por qué ser aquel en el que se está trabajando: el plugin se instala para el usuario,
# no para un proyecto. Nombrar el repositorio NO arregla el desfase —no hay señal disponible de
# dónde trabaja el modelo, y adivinarla sería peor que callarse—, pero convierte una afirmación
# falsa sobre el trabajo en curso en una cierta y atribuida. El día que Claude Code dé al hook
# el repositorio de la tarea, esto se sustituye.
#
# NO ESCRIBE NADA DENTRO DEL REPOSITORIO OBSERVADO: corre en toda sesión del usuario, también
# en repositorios que nunca pidieron el kit.
set -uo pipefail

# `$DIR` se resuelve ANTES del `cd`: después, una invocación relativa desde un subdirectorio
# ya no encontraría la lib.
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
. "$DIR/lib-kit.sh"

RAIZ="$(git rev-parse --show-toplevel 2>/dev/null)" || exit 0
[ -n "$RAIZ" ] || exit 0
cd "$RAIZ" || exit 0

# El JSON que este hook emite debe declarar en `hookEventName` el evento que lo invocó, y el
# mismo script está registrado en DOS: `UserPromptSubmit` en cada turno, y `SessionStart` con el
# matcher `compact`, para reinyectar el acuerdo justo cuando compactar se lo come. El evento
# viaja en el JSON de stdin; sin señal reconocible se asume `UserPromptSubmit`, que es el caso
# mayoritario.
#
# LÍMITE DECLARADO: aquí se fija la FORMA del JSON. Que el acuerdo reaparezca de verdad tras una
# compactación solo se ve compactando una sesión real con el plugin instalado, y esa prueba vive
# fuera de este repositorio.
#
# CON TOPE DE TIEMPO, y no es prudencia de más: `[ -t 0 ]` solo reconoce el caso terminal, y con
# un stdin que nunca cierra, esperar EOF es esperar para siempre. Este hook corre ANTES de cada
# turno, así que colgarlo es colgar la sesión. `read -t 1 -d ''` devuelve en cuanto llega EOF y
# corta al segundo si no llega; sin el JSON solo se pierde saber qué evento invoca, y de eso hay
# valor por defecto.
#
# AQUÍ SOLO SE LEE: quién invoca se decide abajo, en el MISMO `python3` que serializa la salida.
# Arrancar un intérprete aparte solo para mirar `hook_event_name` costaba 20,9 ms por turno.
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
add "    - Un hallazgo se arregla en su causa y restando: no es motivo para un fichero nuevo."

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
        # `|| true` y NO `|| echo 0`: `grep -c` imprime "0" Y sale con estado 1 cuando no hay
        # coincidencias, así que el segundo idiom añade un SEGUNDO "0" y deja PEND="0\n0". En
        # bash 3.2 —el de macOS— expandir `$((TOT-PEND))` con eso es un error de expansión
        # aritmética, y ese error aborta el COMPOUND ENTERO: se pierden en silencio "tareas:",
        # la lista de pendientes y el "FUERA de alcance", justo en el turno en que el cambio
        # está terminado y más mandan. El contenido va por `printf` en vez de dejar que `grep`
        # abra el fichero, para que "cero coincidencias" siga imprimiendo "0" exista o no.
        #
        # Y SOLO si hay lista: un cambio pequeño no lleva `tasks.md` —lo recomienda
        # `docs/FLUJO.md`—, y ahí esto decía «tareas: 0/0 hechas», que se lee como «no queda
        # nada por hacer» cuando lo cierto es que ese cambio no tiene lista.
        PEND=0
        if [ -f "$ACT/tasks.md" ]; then
            TASKS="$(cat "$ACT/tasks.md")"
            PEND="$(printf '%s\n' "$TASKS" | grep -c '^- \[ \]' || true)"
            TOT="$(printf '%s\n' "$TASKS" | grep -cE '^- \[[ x]\]' || true)"
            add "    tareas: $((TOT-PEND))/$TOT hechas"
        fi
        # Sin fichero intermedio: para componer tres líneas de texto no hace falta tocar el
        # disco, y menos un temporal de nombre adivinable en un directorio donde escribe
        # cualquiera, desde un hook que corre en cada turno de cualquier repositorio.
        if [ "$PEND" -gt 0 ]; then
            PENDIENTES="$(grep '^- \[ \]' "$ACT/tasks.md" 2>/dev/null | head -3 | sed 's/^/    /')"
            [ -n "$PENDIENTES" ] && L="${L}${PENDIENTES}"$'\n'
        fi
        # La cabecera, en CUALQUIER caja y con dos almohadillas o más. Distinguir mayúsculas
        # hacía desaparecer el bloque del digest sin decir nada en las propuestas que la
        # escriben «## FUERA de alcance»; y cortar en cualquier `#` lo terminaba antes de
        # tiempo, en un `### Matiz` o en una almohadilla dentro de un bloque de código.
        FUERA="$(awk 'tolower($0) ~ /^##+ fuera de alcance/ {f=1; next} f && /^## / {exit} f && /^- /' \
                 "$ACT/proposal.md" 2>/dev/null | head -3)"
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
    # ACOTAR A ESTE REPOSITORIO. Sin filtrar, el `find` recorre TODO
    # `~/Library/Developer/Xcode/DerivedData` y un repositorio sin un solo fichero .swift acaba
    # anunciando las dependencias de otro proyecto de la máquina — un dato equivocado que parece
    # correcto. La heurística y sus límites viven en `lib-kit.sh`, que es de donde la toma
    # también `doc-paquetes.sh`.
    derivados_propios "$RAIZ"

    # `-print0` y un `while read -d ''`: partir por espacios se come las rutas que los llevan
    # dentro, y en DerivedData las hay.
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
    grep -q "^diff: $(huella_diff)$" "$M" \
        && add "· Verificación: firmada contra el árbol actual." \
        || add "· Verificación: la firma es de OTRO árbol — /kit-verifica antes de commitear."
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
