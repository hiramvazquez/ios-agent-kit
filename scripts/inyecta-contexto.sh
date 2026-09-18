#!/usr/bin/env bash
# Hook UserPromptSubmit: pone el acuerdo delante del modelo en CADA turno.
#
# Contra la deriva no sirve obligar a leer una skill: el modelo cree que se acuerda y no
# relee. Lo que sirve es que el texto esté delante otra vez, siempre, y que sea CORTO.
#
# Inyecta cinco cosas y ninguna más:
#   0. DE QUÉ REPOSITORIO habla,
#   1. las reglas innegociables (las que no puede comprobar ningún linter),
#   2. el cambio OpenSpec activo, con lo que queda por hacer y lo que está FUERA de alcance,
#   3. qué dependencias traen reglas propias — SOLO si las hay,
#   4. si la firma de verificación corresponde al árbol actual.
#
# El punto 0 existe porque este hook lee el repositorio del directorio que hereda de la
# sesión, que no tiene por qué ser aquel en el que se está trabajando: el plugin se instala
# para el usuario, no para un proyecto. Nombrarlo no arregla el desfase, pero convierte una
# afirmación falsa sobre el trabajo en curso en una cierta y atribuida.
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

# El JSON que este hook emite declara en `hookEventName` el evento que lo invocó: el mismo
# script está registrado en `UserPromptSubmit` y en `SessionStart` con el matcher `compact`.
# El evento viaja en el JSON de stdin; sin señal reconocible se asume `UserPromptSubmit`.
#
# CON TOPE DE TIEMPO: `[ -t 0 ]` solo reconoce el caso terminal, y con un stdin que nunca
# cierra, esperar EOF es colgar la sesión. `read -t 1 -d ''` devuelve en cuanto llega EOF y
# corta al segundo si no llega; sin el JSON solo se pierde saber qué evento invoca.
#
# Aquí solo se lee: quién invoca se decide abajo, en el MISMO `python3` que serializa la
# salida, para no arrancar un intérprete aparte en cada turno.
#
# LÍMITE DECLARADO: aquí se fija la FORMA del JSON. Que el acuerdo reaparezca de verdad tras
# una compactación solo se ve compactando una sesión real con el plugin instalado.
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

# Tres situaciones, no dos: un repositorio sin `openspec/` no puede seguir la orden de abrir
# una propuesta, así que recibe otra cosa.
if [ ! -d openspec ]; then
    add "· Este repositorio no usa OpenSpec — aquí no hay acuerdo que consultar."
else
    cambio_activo
    ACT="$ACTIVO"
    if [ -n "$ACT" ]; then
        add "· Cambio activo: ${ACT##*/}"
        # Callarse cuál de los dos se ha elegido es peor que elegir: el digest afirmaría
        # cosas de un acuerdo mientras se trabaja en el otro.
        [ "$ACTIVOS_N" -gt 1 ] && add "    ⚠️  hay $ACTIVOS_N cambios activos; este es el primero por orden, no necesariamente el tuyo."
        # SOLO si hay lista: sin `tasks.md` no hay línea de recuento (ver `recuento_tareas`).
        PEND=0
        recuento_tareas "$ACT"
        if [ -n "$TAREAS_TOTAL" ]; then
            PEND=$((TAREAS_TOTAL - TAREAS_HECHAS))
            add "    tareas: $TAREAS_HECHAS/$TAREAS_TOTAL hechas"
        fi
        # Sin fichero intermedio: para componer tres líneas de texto no hace falta tocar el
        # disco, y menos un temporal de nombre adivinable desde un hook que corre en cada
        # turno de cualquier repositorio.
        if [ "$PEND" -gt 0 ]; then
            PENDIENTES="$(grep '^- \[ \]' "$ACT/tasks.md" 2>/dev/null | head -3 | sed 's/^/    /')"
            [ -n "$PENDIENTES" ] && L="${L}${PENDIENTES}"$'\n'
        fi
        # La cabecera, en CUALQUIER caja y con dos almohadillas o más; el bloque termina en el
        # siguiente `## `, no en cualquier `#` (un `### Matiz` o una almohadilla en un bloque
        # de código lo cortarían antes de tiempo).
        FUERA="$(awk 'tolower($0) ~ /^##+ fuera de alcance/ {f=1; next} f && /^## / {exit} f && /^- /' \
                 "$ACT/proposal.md" 2>/dev/null | head -3)"
        [ -n "$FUERA" ] && { add "    FUERA de alcance:"; L="${L}$(printf '%s\n' "$FUERA" | sed 's/^/      /')"$'\n'; }
    else
        add "· Sin cambio OpenSpec activo. Si vas a tocar código, primero /opsx:propose."
    fi
fi

# Los paquetes de los que depende el proyecto traen sus propias reglas, y viven en rutas
# que git ignora (`.build/checkouts`, `DerivedData/.../SourcePackages`). No se inyecta la
# doc —envejece y ocupa—, se inyecta que EXISTE y cómo llegar.
#
# Se cachea: este hook corre en CADA turno y un `find` sobre DerivedData no es gratis. El
# caché vive FUERA del repositorio observado —para no crear `.agent-kit/` en repositorios
# que nunca pidieron el kit— y con la ruta del repositorio en la clave, para que un caché
# compartido no sirva las dependencias de un proyecto a otro.
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/ios-agent-kit"
CACHE="$CACHE_DIR/$(printf '%s' "$RAIZ" | shasum -a 256 | cut -c1-32).paquetes"
mkdir -p "$CACHE_DIR" 2>/dev/null
if [ -z "$(find "$CACHE" -mtime -1 2>/dev/null)" ]; then
    # Acotado a ESTE repositorio; la heurística y sus límites viven en `lib-kit.sh`.
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

# Solo LECTURA: si el fichero no está, no se crea. Lo escribe `verifica.sh`.
M="$RAIZ/.agent-kit/verificacion.txt"
if [ -f "$M" ]; then
    # El toolchain sale del marker, NO se detecta: interrogar al compilador cuesta 0,3 s y
    # esto corre en cada turno. Una firma sin ese campo deja la línea como estaba.
    TC="$(sed -n 's/^toolchain: //p' "$M" | head -1)"
    grep -q "^diff: $(huella_diff)$" "$M" \
        && add "· Verificación: firmada contra el árbol actual${TC:+ (toolchain: $TC)}." \
        || add "· Verificación: la firma es de OTRO árbol — /kit-verifica antes de commitear."
else
    add "· Verificación: sin firmar todavía."
fi

# UN solo `python3`: decide el evento invocante y serializa la salida.
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
