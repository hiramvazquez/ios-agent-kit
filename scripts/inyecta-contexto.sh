#!/usr/bin/env bash
# Hook UserPromptSubmit: pone el acuerdo delante del modelo en CADA turno.
#
# Contra la deriva no sirve obligar a leer una skill: el modelo cree que se acuerda y no
# relee. Lo que sí sirve es que el texto esté delante otra vez, siempre, y que sea CORTO —
# un digest que se lee, no un documento que se ignora.
#
# Inyecta tres cosas y ninguna más:
#   1. las reglas innegociables (las que no puede comprobar ningún linter),
#   2. el cambio OpenSpec activo, con lo que queda por hacer y lo que está FUERA de alcance,
#   3. si la firma de verificación corresponde al árbol actual.
set -uo pipefail
cd "$(git rev-parse --show-toplevel 2>/dev/null)" || exit 0

L=""
add() { L="${L}$1"$'\n'; }

add "· Reglas que ningún linter puede comprobar por ti:"
add "    - El acuerdo manda: si el código y openspec/ discrepan, se corrige el código o se"
add "      renegocia el acuerdo POR ESCRITO. Nunca se reescribe el acuerdo para que encaje."
add "    - Antes de escribir una función, busca si ya existe: /kit-duplicados."
add "    - Fuera de alcance es fuera de alcance, incluso si 'ya que estamos'."

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

# Los paquetes de los que depende el proyecto traen sus propias reglas, y viven en rutas
# que git ignora (`.build/checkouts`, `DerivedData/.../SourcePackages`). Nadie las encuentra
# solo. No se inyecta la doc —envejece y ocupa—, se inyecta que EXISTE y cómo llegar.
# Se cachea: este hook corre en CADA turno y un `find` sobre DerivedData no es gratis. El
# nombre de las dependencias cambia como mucho cuando se toca un Package.swift.
CACHE="$(git rev-parse --show-toplevel)/.agent-kit/.paquetes-con-reglas"
mkdir -p "$(dirname "$CACHE")"
if [ -z "$(find "$CACHE" -mtime -1 2>/dev/null)" ]; then
    find . "$HOME/Library/Developer/Xcode/DerivedData" -maxdepth 6 -name AGENTS.md \
         -path "*checkouts*" 2>/dev/null \
      | xargs -n1 dirname 2>/dev/null | xargs -n1 basename 2>/dev/null \
      | sort -u | tr '\n' ' ' > "$CACHE" 2>/dev/null
fi
DEPDOC="$(cat "$CACHE" 2>/dev/null)"
[ -n "$DEPDOC" ] && add "· Estos paquetes traen sus PROPIAS reglas y no están en el repo: ${DEPDOC}— rutas con /kit-doc."

M="$(git rev-parse --show-toplevel)/.agent-kit/verificacion.txt"
if [ -f "$M" ]; then
    grep -q "^diff: $(git diff --cached | shasum -a 256 | cut -d' ' -f1)$" "$M" \
        && add "· Verificación: firmada contra el diff staged actual." \
        || add "· Verificación: la firma es de OTRO diff — /kit-verifica antes de commitear."
else
    add "· Verificación: sin firmar todavía."
fi

printf '{"hookSpecificOutput":{"hookEventName":"UserPromptSubmit","additionalContext":%s}}\n' \
    "$(printf '📌 Acuerdo vigente (inyectado, no lo pidas de nuevo):\n%s' "$L" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))')"
