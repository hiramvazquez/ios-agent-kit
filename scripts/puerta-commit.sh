#!/usr/bin/env bash
# Hook PreToolUse — el único evento de Claude Code que puede bloquear. Si el comando es un
# commit, exige firma de verificación para ese diff EN EL REPOSITORIO AL QUE VA EL COMMIT.
# La invocación la analiza `analiza-invocacion.py` con `shlex`, no una subcadena.
#
# LÍMITES DECLARADOS. Frena el olvido, no a quien se lo salta: `--no-verify`, otra terminal y
# un git que no pase por la herramienta Bash quedan fuera. Cubre la invocación directa, `-C`,
# `--git-dir`, un `cd`/`pushd` en la misma línea (también en `( … )` o `{ …; }`) y un
# `bash -c '…'` hasta 4 niveles. NO cubre, y cae al directorio heredado: `~` o una variable
# sin expandir, un `cd` en una línea y el commit en otra, y una invocación construida en
# tiempo de ejecución (`$CMD commit`, un alias, un `eval`).
set -uo pipefail

# Fallo ABIERTO si algo va mal ahí dentro: bloquear ante un JSON raro convertiría un fallo
# del hook en una sesión inutilizable.
ANALISIS="$(python3 "$(dirname "${BASH_SOURCE[0]}")/analiza-invocacion.py" 2>/dev/null)" || ANALISIS="NO"

case "$ANALISIS" in
    COMMIT*) ;;
    # Fallo ABIERTO y deliberado: no hay commit, no hay nada que vigilar. Es la salida de la
    # inmensa mayoría de comandos y tiene que ser barata.
    *) exit 0 ;;
esac

PISTA="${ANALISIS#COMMIT }"

# La pista puede ser un directorio del repositorio o un `.git`: que lo resuelva git.
DESTINO="$(git -C "$PISTA" rev-parse --show-toplevel 2>/dev/null)"
[ -n "$DESTINO" ] || DESTINO="$(git -C "$(dirname "$PISTA")" rev-parse --show-toplevel 2>/dev/null)"

# Fallo ABIERTO: sin repositorio no hay commit que proteger; git dará su error.
[ -n "$DESTINO" ] || exit 0

# Un repositorio sin `kit.conf` no usa el kit: no hay flujo que proteger, y exigirle firma lo
# dejaría sin salida. Fallo ABIERTO, y deliberado.
[ -f "$DESTINO/kit.conf" ] || exit 0

# Fallo CERRADO: firma ausente o de otro diff bloquea. `--comprueba` mira el repositorio de
# SU directorio de trabajo, así que se le da el de destino y no el heredado.
if (cd "$DESTINO" && bash "$(dirname "${BASH_SOURCE[0]}")/verifica.sh" --comprueba) >/dev/null 2>&1; then
    exit 0
fi

DESTINO="$DESTINO" python3 - <<'PY'
import json, os
print(json.dumps({"hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": (
        "No hay verificación firmada para el árbol de "
        f"{os.environ['DESTINO']}. Stagea primero, corre `/kit-verifica` ahí y commitea "
        "después, en un comando aparte: se firma el árbol Y el índice, así que encadenar el "
        "`add` con el commit cambia lo firmado."
    )}}))
PY
