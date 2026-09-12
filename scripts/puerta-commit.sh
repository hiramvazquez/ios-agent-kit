#!/usr/bin/env bash
# Hook PreToolUse — el ÚNICO que bloquea, porque es el único evento de Claude Code que
# puede. Si el comando es un commit, exige que exista firma de verificación para ESE diff,
# en EL REPOSITORIO AL QUE VA EL COMMIT.
#
# Por qué este y no otros: sin él, "los tests pasan" es una afirmación del modelo sobre un
# árbol que pudo cambiar después de correrlos. Es error de proceso, no mala fe, y es el
# fallo que más caro sale porque no deja rastro.
#
# QUÉ MIRA. La invocación, analizada con `shlex` —no la subcadena "git commit" en el texto del
# comando—, y el repositorio de destino que de ahí se resuelve. Reconocer por subcadena fallaba
# de cuatro formas a la vez, y las cuatro están fijadas en `verifica-puerta.sh`.
#
# LÍMITES, declarados porque estrecharlos sin decirlo sería peor que tenerlos:
#   - `--no-verify` y cualquier otra vía deliberada siguen abiertas. Este hook frena el
#     olvido, no a quien decide saltárselo; eso no se puede cerrar desde dentro de la misma
#     máquina, y fingir lo contrario es peor que no tenerlo.
#   - Un commit desde otra terminal, o desde un git que no pase por la herramienta Bash de
#     Claude Code, no lo ve nadie.
#   - El análisis es sintáctico, y esta lista es lo que de verdad cubre —no lo que sería
#     bonito que cubriera—: la invocación directa; la dirigida con `-C`, `--git-dir` o
#     `--git-dir=`; un `cd`/`pushd` encadenado por delante, también dentro de `( … )` o
#     `{ …; }`; y un `bash -c '…'` (o `sh`/`zsh`) analizado por dentro, hasta 4 niveles.
#   - Lo que NO cubre, y cae al directorio heredado: una invocación construida en tiempo de
#     ejecución —`$CMD commit`, un alias, un `eval` con la orden en una variable—, y
#     cualquier envoltorio que no sea un shell de la lista. El olvido tiene formas comunes,
#     no retorcidas; estas no son las comunes.
set -uo pipefail

# El análisis vive en `analiza-invocacion.py`, en su propio fichero y con UNA sola invocación
# de python: dos intérpretes por comando cuestan +12,6 ms en CADA comando de la sesión.
#
# Fallo ABIERTO si algo va mal ahí dentro: sin poder leer la entrada no se puede afirmar
# que haya un commit, y bloquear ante un JSON raro convertiría un fallo del hook en una
# sesión inutilizable.
ANALISIS="$(python3 "$(dirname "${BASH_SOURCE[0]}")/analiza-invocacion.py" 2>/dev/null)" || ANALISIS="NO"

case "$ANALISIS" in
    COMMIT*) ;;
    # Fallo ABIERTO y deliberado: no hay commit, no hay nada que vigilar. Es la salida de la
    # inmensa mayoría de comandos y tiene que ser barata.
    *) exit 0 ;;
esac

PISTA="${ANALISIS#COMMIT }"

# La pista puede ser un directorio cualquiera del repositorio, o un `.git`. Que lo resuelva
# git, que es quien sabe.
DESTINO="$(git -C "$PISTA" rev-parse --show-toplevel 2>/dev/null)"
[ -n "$DESTINO" ] || DESTINO="$(git -C "$(dirname "$PISTA")" rev-parse --show-toplevel 2>/dev/null)"

# Fallo ABIERTO: si no hay repositorio, no hay commit que proteger y será git quien dé el
# error que corresponda.
[ -n "$DESTINO" ] || exit 0

# Un repositorio sin `kit.conf` no usa el kit: no hay flujo que proteger, y exigirle firma
# lo dejaría sin salida, porque `verifica.sh` aborta allí por falta de ese mismo fichero.
# Fallo ABIERTO, y deliberado.
[ -f "$DESTINO/kit.conf" ] || exit 0

# Aquí sí: repositorio del kit y commit de verdad. Fallo CERRADO — si la firma falta o es de
# otro diff, se bloquea. `verifica.sh --comprueba` mira el repositorio de SU directorio de
# trabajo, así que se le da el de destino y no el heredado.
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
