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
# Uso:  bash scripts/autocomprueba.sh     (desde la raíz del kit)
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.." || exit 1
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

# 6. Los agentes y comandos tienen frontmatter
for f in agents/*.md commands/*.md skills/*/SKILL.md; do
    head -1 "$f" | grep -q '^---$' && continue
    mal "$f no empieza con frontmatter ---"
done
[ "$FALLOS" -eq 0 ] && bien "agentes, comandos y skills con frontmatter"

echo
[ "$FALLOS" -eq 0 ] && echo "✅ kit sano — se puede publicar." || echo "❌ $FALLOS problema(s): NO publiques."
exit "$FALLOS"
