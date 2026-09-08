#!/usr/bin/env bash
# Hook PreToolUse — el ÚNICO que bloquea, porque es el único evento de Claude Code que
# puede. Si el comando es un commit, exige que exista firma de verificación para ESE diff,
# en EL REPOSITORIO AL QUE VA EL COMMIT.
#
# Por qué este y no otros: sin él, "los tests pasan" es una afirmación del modelo sobre un
# árbol que pudo cambiar después de correrlos. Es error de proceso, no mala fe, y es el
# fallo que más caro sale porque no deja rastro.
#
# QUÉ MIRA, y por qué así. La primera versión reconocía un commit buscando la subcadena
# "git commit" y comprobaba siempre el repositorio del directorio heredado. Fallaba de
# cuatro formas a la vez, las cuatro fijadas hoy en `verifica-puerta.sh`:
#   - una invocación dirigida con `-C` no contiene esa subcadena: se colaba sin comprobar
#     NADA;
#   - con el cwd en otro repositorio, comprobaba el equivocado y bloqueaba commits sí
#     verificados;
#   - bloqueaba cualquier comando que MENCIONARA las palabras — un `echo`, un `grep`,
#     escribir esta misma cabecera;
#   - en repositorios sin `kit.conf` bloqueaba sin salida, porque `verifica.sh` tampoco
#     puede firmar allí.
# Ahora se analiza la invocación con `shlex` y se resuelve el repositorio de destino.
#
# LÍMITES, declarados porque estrecharlos sin decirlo sería peor que tenerlos:
#   - `--no-verify` y cualquier otra vía deliberada siguen abiertas. Este hook frena el
#     olvido, no a quien decide saltárselo; eso no se puede cerrar desde dentro de la misma
#     máquina, y fingir lo contrario es peor que no tenerlo.
#   - Un commit desde otra terminal, o desde un git que no pase por la herramienta Bash de
#     Claude Code, no lo ve nadie.
#   - El análisis es sintáctico. Cubre la invocación directa, la dirigida con `-C` o
#     `--git-dir`, y un `cd <ruta>` encadenado por delante. Una construida en tiempo de
#     ejecución —`$CMD commit`, un alias, un `eval` con la orden en una variable— cae al
#     directorio heredado, que es el comportamiento de antes. El olvido tiene formas
#     comunes, no retorcidas.
set -uo pipefail

# El comando se lee ANTES y aparte, porque el analizador de abajo llega por stdin: si se
# leyera el JSON allí, `python3 -` estaría usando stdin para el programa y para los datos a
# la vez, y el JSON no llegaría nunca. Pasó en la primera versión de este arreglo y el
# síntoma era mudo — el analizador respondía «no es un commit» a todo y la puerta dejaba
# pasar cualquier cosa. Lo cazó `verifica-puerta.sh`.
#
# Fallo ABIERTO si el JSON no se puede leer: sin entrada no se puede afirmar que haya un
# commit, y bloquear ante un JSON raro convertiría un fallo del hook en una sesión
# inutilizable.
CMD="$(python3 -c 'import json,sys; print(json.load(sys.stdin).get("tool_input",{}).get("command",""))' 2>/dev/null)" || CMD=""

# El análisis va en python: `shlex` sabe de comillas y de operadores, y bash no sin
# reimplementarlo mal. Imprime una línea:
#   NO                → esto no es un commit
#   COMMIT <ruta>     → sí lo es, y la ruta es la pista de dónde (o "." si no hay pista)
ANALISIS="$(python3 - "$CMD" <<'PY'
import shlex, sys

cmd = sys.argv[1] if len(sys.argv) > 1 else ""

try:
    lex = shlex.shlex(cmd, posix=True, punctuation_chars=True)
    lex.whitespace_split = True
    tokens = list(lex)
except ValueError:
    # Comillas sin cerrar: no es un comando que vaya a ejecutarse tal cual. Fallo ABIERTO,
    # mismo argumento que arriba.
    print("NO"); sys.exit(0)

SEPARADORES = {";", "&&", "||", "|", "&", "\n"}

# Trocea en comandos simples. Un `cd` solo manda sobre lo que viene después de él.
segmentos, actual = [], []
for t in tokens:
    if t in SEPARADORES:
        segmentos.append(actual); actual = []
    else:
        actual.append(t)
segmentos.append(actual)

# Opciones globales de git que se COMEN el argumento siguiente. Sin esta lista, en una
# invocación dirigida con `-C /ruta` el subcomando parecería ser "/ruta".
CON_VALOR = {"-C", "--git-dir", "--work-tree", "-c", "--exec-path", "--namespace",
             "--super-prefix", "--config-env"}

cd_pendiente = None   # último `cd <ruta>` visto en la cadena

for seg in segmentos:
    if not seg:
        continue
    # Saltar asignaciones que preceden al comando: FOO=bar git …
    i = 0
    while i < len(seg) and "=" in seg[i] and not seg[i].startswith("-") \
            and "/" not in seg[i].split("=")[0]:
        i += 1
    if i >= len(seg):
        continue
    base = seg[i].rsplit("/", 1)[-1]

    if base == "cd" and i + 1 < len(seg):
        cd_pendiente = seg[i + 1]
        continue

    if base != "git":
        continue

    ruta = None
    j = i + 1
    while j < len(seg):
        a = seg[j]
        if a in CON_VALOR:
            if a in ("-C", "--git-dir") and j + 1 < len(seg):
                ruta = seg[j + 1]
            j += 2
            continue
        if a.startswith("--git-dir="):
            ruta = a.split("=", 1)[1]; j += 1; continue
        if a.startswith("-"):
            j += 1; continue
        # Primer argumento que no es opción ni valor de opción: el subcomando.
        if a == "commit":
            print("COMMIT " + (ruta or cd_pendiente or "."))
            sys.exit(0)
        break   # es otro subcomando de git; este segmento no nos interesa

print("NO")
PY
)"

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
        "No hay verificación firmada para el diff staged de "
        f"{os.environ['DESTINO']}. Corre `/kit-verifica` ahí y commitea después, en un "
        "comando aparte — encadenar el `add` con el commit cambia el diff entre la firma "
        "y el commit."
    )}}))
PY
