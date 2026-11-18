#!/usr/bin/env bash
# Comprueba, ANTES de publicar un cambio, lo que el validador de Claude Code no mira: que los
# scripts que citan los hooks, los comandos y los agentes existan, y que se citen por la raíz
# del plugin. Que los manifiestos carguen lo comprueba `claude plugin validate`, que es un
# paso aparte de `kit.conf`.
#
# Uso:  bash scripts/autocomprueba.sh            comprueba SU kit
#       bash scripts/autocomprueba.sh <raíz>     comprueba el árbol de kit que le digas
#
# Códigos de salida: 0 sano · 1 hay problemas, SEA CUAL SEA cuántos · 3 no pude mirar. Es la
# misma forma que `verifica.sh`: confundir «no pude mirar» con «está mal» hace que un gate
# roto parezca un proyecto roto. El recuento de problemas se imprime, que es donde se lee.
#
# LÍMITE DECLARADO: no tiene banco.
set -uo pipefail
RAIZ="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
# `${1:-…}` sustituye cuando está sin definir *o* vacío, así que un argumento vacío no llega;
# la guarda es por si la resolución por defecto falla: `cd ""` devuelve 0 en bash y
# comprobaría el directorio actual en silencio.
[ -n "$RAIZ" ] || { echo "❌ raíz vacía: pásame un directorio o ningún argumento"; exit 3; }
cd "$RAIZ" || { echo "❌ no existe la raíz «${RAIZ}»"; exit 3; }
FALLOS=0

# 4. Todo comando referenciado por un hook existe y es ejecutable
python3 - <<'PY' || FALLOS=$((FALLOS+1))
import json, os, re, sys
d = json.load(open("hooks/hooks.json")).get("hooks", {})
faltan = []
for grupos in d.values():
    for g in grupos:
        for h in g.get("hooks", []):
            m = re.search(r'\$\{CLAUDE_PLUGIN_ROOT\}/(\S+?)"', h.get("command",""))
            if m and not os.access(m.group(1), os.X_OK): faltan.append(m.group(1))
if faltan:
    print(f"❌ hooks apuntan a scripts que no existen o no son ejecutables: {faltan}")
    sys.exit(1)
print("✅ los scripts de los hooks existen y son ejecutables")
PY

# 5. Todo script citado por un comando o un agente existe. El punto 4 solo mira los hooks; un
#    comando que invoque un script mal escrito fallaría el día que alguien lo use, en otro
#    proyecto, sin contexto para diagnosticarlo.
python3 - <<'PY2' || FALLOS=$((FALLOS+1))
import os, re, sys, glob
faltan = []
for f in glob.glob("commands/*.md") + glob.glob("agents/*.md") + glob.glob("skills/*/SKILL.md"):
    for ruta in re.findall(r'\$\{CLAUDE_PLUGIN_ROOT\}/([^\s"`\')]+)', open(f).read()):
        if not os.path.exists(ruta):
            faltan.append(f"{f} → {ruta}")
if faltan:
    print("❌ comandos/agentes citan ficheros que no existen:")
    for x in faltan: print(f"     {x}")
    sys.exit(1)
print("✅ los scripts que citan comandos y agentes existen")
PY2

# 5b. Y que se citen POR LA RAÍZ DEL PLUGIN, no por una ruta del proyecto: el punto 5 solo mira
#     las rutas que YA empiezan por `${CLAUDE_PLUGIN_ROOT}`, y no ve lo mal citado, que es el
#     error más probable. Solo mira DENTRO de los bloques de código: en la prosa, `rodaja.sh`
#     es un nombre, no una invocación.
python3 - <<'PY3' || FALLOS=$((FALLOS+1))
import os, re, sys, glob
kit = {os.path.basename(p) for p in glob.glob("scripts/*") if os.path.isfile(p)}
malas = []
for f in glob.glob("commands/*.md") + glob.glob("agents/*.md") + glob.glob("skills/*/SKILL.md"):
    dentro = False
    for n, linea in enumerate(open(f).read().splitlines(), 1):
        if linea.lstrip().startswith("```"):
            dentro = not dentro
            continue
        if not dentro:
            continue
        for tok in re.findall(r"[\w./${}-]+\.(?:sh|py)", linea):
            if os.path.basename(tok) not in kit:
                continue          # no es un fichero del kit: será del proyecto
            if "CLAUDE_PLUGIN_ROOT" in tok:
                continue
            malas.append(f"{f}:{n} → {tok}")
if malas:
    print("❌ comandos/agentes invocan ficheros del kit sin ${CLAUDE_PLUGIN_ROOT}:")
    for x in malas: print(f"     {x}")
    print("     los scripts viven en el plugin, no en el repo del proyecto")
    sys.exit(1)
print("✅ los ficheros del kit se invocan por la raíz del plugin")
PY3

echo
[ "$FALLOS" -eq 0 ] && echo "✅ kit sano — se puede publicar." || echo "❌ $FALLOS problema(s): NO publiques."

# El rojo es 1 SIEMPRE, no `$FALLOS`: con el recuento, tres problemas y una raíz inexistente
# (3) serían indistinguibles para quien solo mira el código.
[ "$FALLOS" -eq 0 ] && exit 0 || exit 1
