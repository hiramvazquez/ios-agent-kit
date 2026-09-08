#!/usr/bin/env bash
# Hook UserPromptSubmit: pone el acuerdo delante del modelo en CADA turno.
#
# Contra la deriva no sirve obligar a leer una skill: el modelo cree que se acuerda y no
# relee. Lo que sí sirve es que el texto esté delante otra vez, siempre, y que sea CORTO —
# un digest que se lee, no un documento que se ignora.
#
# Inyecta cuatro cosas y ninguna más:
#   0. DE QUÉ REPOSITORIO habla,
#   1. las reglas innegociables (las que no puede comprobar ningún linter),
#   2. el cambio OpenSpec activo, con lo que queda por hacer y lo que está FUERA de alcance,
#   3. si la firma de verificación corresponde al árbol actual.
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

RAIZ="$(git rev-parse --show-toplevel 2>/dev/null)" || exit 0
[ -n "$RAIZ" ] || exit 0
cd "$RAIZ" || exit 0

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
    ACT="$(find openspec/changes -maxdepth 1 -mindepth 1 -type d ! -name archive 2>/dev/null | head -1)"
    if [ -n "$ACT" ]; then
        add "· Cambio activo: ${ACT##*/}"
        PEND="$(grep -c '^- \[ \]' "$ACT/tasks.md" 2>/dev/null || echo 0)"
        TOT="$(grep -cE '^- \[[ x]\]' "$ACT/tasks.md" 2>/dev/null || echo 0)"
        add "    tareas: $((TOT-PEND))/$TOT hechas"
        [ "$PEND" -gt 0 ] && grep '^- \[ \]' "$ACT/tasks.md" 2>/dev/null | head -3 | sed 's/^/    /' \
            | while IFS= read -r t; do printf '%s\n' "$t"; done > /tmp/.ic.$$ && \
            { L="${L}$(cat /tmp/.ic.$$)"$'\n'; rm -f /tmp/.ic.$$; }
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
    # `-print0` y un `while read -d ''`: el `xargs` de antes partía por espacios y se comía
    # cualquier ruta con un espacio dentro, que en DerivedData las hay.
    while IFS= read -r -d '' f; do
        b="${f%/*}"        # dirname
        printf '%s\n' "${b##*/}"   # basename
    done < <(find . "$HOME/Library/Developer/Xcode/DerivedData" -maxdepth 6 \
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

printf '{"hookSpecificOutput":{"hookEventName":"UserPromptSubmit","additionalContext":%s}}\n' \
    "$(printf '📌 Acuerdo vigente (inyectado, no lo pidas de nuevo):\n%s' "$L" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))')"
