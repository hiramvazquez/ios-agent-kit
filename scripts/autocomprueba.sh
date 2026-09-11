#!/usr/bin/env bash
# Comprueba que el kit está sano ANTES de publicar un cambio.
#
# Por qué existe: al montar el kit, los manifiestos fallaron DOS veces —`plugin.json` con
# rutas que ya eran las de por defecto, y `hooks/hooks.json` con los eventos fuera del
# objeto `hooks`— y ninguna de las dos se ve leyendo el fichero. Se ven al instalar, cuando
# `claude plugin list` dice "failed to load".
#
# La regla del README dice que un detector solo nace si la clase ya falló dos veces. Esta
# falló dos veces el mismo día, así que se lo ha ganado.
#
# Uso:  bash scripts/autocomprueba.sh            comprueba SU kit
#       bash scripts/autocomprueba.sh <raíz>     comprueba el árbol de kit que le digas
#
# La raíz opcional existe para poder probarlo a mano contra un árbol roto sin tocar el del
# kit. Tuvo un banco que lo hacía; se retiró el 2026-09-11 porque solo cazaba fallos de este
# mismo script. `kit.conf` lo invoca sin argumentos y no se entera.
#
# Códigos de salida: 0 sano · 1 hay problemas, SEA CUAL SEA cuántos · 3 no pude mirar.
#
# Hereda la forma de `scripts/verifica.sh` — está documentada, con su razón, en
# `openspec/specs/verificacion-firmada/spec.md`: «confundirlos hace que un gate roto parezca
# un proyecto roto, y al revés». Hasta el 2026-09-08 esta puerta —la de publicación, y no la
# de commit, que es la que ya tenía la regla— salía con `exit "$FALLOS"`, y las dos guardas de
# abajo salían con 1: un ÚNICO problema real y «no existe la raíz» daban el mismo código. La
# regla ya existía en el repo; no había llegado a este hermano. El recuento de problemas no se
# pierde: sigue impreso más abajo, que es donde de verdad se lee.
set -uo pipefail
RAIZ="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
# La guarda es por si la resolución por defecto falla: si ese `cd … && pwd` no imprime nada,
# `RAIZ` queda vacía, y `cd ""` devuelve 0 en bash — comprobaría el directorio actual en
# silencio. (Un argumento vacío NO llega hasta aquí: `${1:-…}` sustituye cuando está sin
# definir *o* vacío, al revés de lo que ponía esta nota antes. Lo midió un juez corriendo
# `autocomprueba.sh ""`.)
[ -n "$RAIZ" ] || { echo "❌ raíz vacía: pásame un directorio o ningún argumento"; exit 3; }
cd "$RAIZ" || { echo "❌ no existe la raíz «${RAIZ}»"; exit 3; }
FALLOS=0
mal() { printf '❌ %s\n' "$1"; FALLOS=$((FALLOS+1)); }
bien() { printf '✅ %s\n' "$1"; }

# 1. Los tres JSON parsean
for f in .claude-plugin/plugin.json .claude-plugin/marketplace.json hooks/hooks.json; do
    python3 -c "import json,sys; json.load(open('$f'))" 2>/dev/null \
        && bien "$f parsea" || mal "$f NO parsea"
done

# 2. plugin.json no declara rutas que ya son las de por defecto (el validador las rechaza)
python3 - <<'PY' || FALLOS=$((FALLOS+1))
import json, sys
d = json.load(open(".claude-plugin/plugin.json"))
sobran = [k for k in ("agents","skills","commands","hooks") if k in d]
if sobran:
    print(f"❌ plugin.json declara {sobran}: usa las rutas por defecto y quita esas claves")
    sys.exit(1)
print("✅ plugin.json no declara rutas redundantes")
PY

# 3. hooks.json envuelve los eventos en el objeto `hooks`
python3 - <<'PY' || FALLOS=$((FALLOS+1))
import json, sys
d = json.load(open("hooks/hooks.json"))
eventos = {"PreToolUse","PostToolUse","UserPromptSubmit","SessionStart","SessionEnd","Stop"}
if eventos & set(d) - {"hooks"}:
    print("❌ hooks.json pone eventos en el nivel superior: van dentro de {\"hooks\": {...}}")
    sys.exit(1)
if "hooks" not in d:
    print("❌ hooks.json no tiene objeto `hooks`"); sys.exit(1)
print("✅ hooks.json tiene los eventos dentro del objeto `hooks`")
PY

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

# 5. Todo script citado por un comando o un agente existe
#
# El hueco que tapa: el punto 4 solo mira los hooks, y un comando nuevo que invoque un
# script mal escrito se publica sin que nada chiste — el fallo aparece el día que alguien
# usa el comando, en otro proyecto, sin contexto para diagnosticarlo.
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

# 5b. Y que se citen POR LA RAÍZ DEL PLUGIN, no por una ruta del proyecto.
#
# El hueco que tapa, y que estuvo abierto desde que existe el punto 5: aquella comprobación
# solo mira las rutas que YA empiezan por `${CLAUDE_PLUGIN_ROOT}`. Verifica que lo bien
# citado exista, y no ve lo mal citado — que es el error más probable de los dos, porque los
# scripts vivieron dentro del proyecto antes de vivir en el plugin.
#
# Lo que costó: `agents/aceptacion.md` llevaba `bash Scripts/verifica.sh --informe`. Esa ruta
# no existe en ningún proyecto —`AppStarter` tiene un `Scripts/` con otra cosa dentro—, así
# que el juez de aceptación se quedaba sin el informe de duplicados y seguía dictaminando.
# Publicado en verde desde la 1.0.0 hasta la 1.6.1: las diez versiones que existen. Este
# punto 5 nació en la 1.0.1, así que estuvo ciego ante él nueve de ellas.
#
# Solo mira DENTRO de los bloques de código: en la prosa, `rodaja.sh` es un nombre, no una
# invocación, y exigirle la raíz del plugin obligaría a escribir peor.
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

# 6. Los agentes y comandos tienen frontmatter
#
# Se compara contra el contador de ANTES de este punto, no contra 0: comparar con 0 hace que
# un fallo de un punto anterior (un JSON roto, por ejemplo) silencie este ✅ aunque el
# frontmatter esté perfecto — el acumulado no es el de este punto.
ANTES_DEL_6=$FALLOS
for f in agents/*.md commands/*.md skills/*/SKILL.md; do
    head -1 "$f" | grep -q '^---$' && continue
    mal "$f no empieza con frontmatter ---"
done
[ "$FALLOS" -eq "$ANTES_DEL_6" ] && bien "agentes, comandos y skills con frontmatter"

echo
[ "$FALLOS" -eq 0 ] && echo "✅ kit sano — se puede publicar." || echo "❌ $FALLOS problema(s): NO publiques."

# El rojo es 1 SIEMPRE, no `$FALLOS` — igual que en `verifica.sh` y por la misma razón: si
# saliera con el recuento, tres problemas y una raíz inexistente (3) serían indistinguibles
# para quien solo mira el código. El número ya se imprimió arriba, que es donde se lee.
[ "$FALLOS" -eq 0 ] && exit 0 || exit 1
