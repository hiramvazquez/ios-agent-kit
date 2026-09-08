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
# La raíz opcional existe para poder probarlo. Mientras este script solo supiera ir a su
# propia raíz, cualquier banco habría comprobado el kit de verdad en vez de fixtures rotos —
# y por eso fue, hasta que existió su banco, la única pieza con lógica sin nadie que la
# mirase — justo la que dice «se puede publicar». `kit.conf` lo invoca sin argumentos y no se entera.
set -uo pipefail
RAIZ="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
# La guarda es por si la resolución por defecto falla: si ese `cd … && pwd` no imprime nada,
# `RAIZ` queda vacía, y `cd ""` devuelve 0 en bash — comprobaría el directorio actual en
# silencio. (Un argumento vacío NO llega hasta aquí: `${1:-…}` sustituye cuando está sin
# definir *o* vacío, al revés de lo que ponía esta nota antes. Lo midió un juez corriendo
# `autocomprueba.sh ""`.)
[ -n "$RAIZ" ] || { echo "❌ raíz vacía: pásame un directorio o ningún argumento"; exit 1; }
cd "$RAIZ" || { echo "❌ no existe la raíz «$RAIZ»"; exit 1; }
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
# punto 5 nació en la 1.0.1, así que estuvo ciego ante él nueve de ellas. (El «seis» que hay
# más abajo, en el punto 7, es de otro hallazgo distinto y sí es correcto: el «5 skills»
# dejó de cuadrar en la 1.3.0. Estuvo copiado aquí una ronda, y lo cazó un juez contando.)
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
for f in agents/*.md commands/*.md skills/*/SKILL.md; do
    head -1 "$f" | grep -q '^---$' && continue
    mal "$f no empieza con frontmatter ---"
done
[ "$FALLOS" -eq 0 ] && bien "agentes, comandos y skills con frontmatter"

# 7. Que ningún documento escriba a mano cuántas piezas trae el kit.
#
# La clase ya falló dos veces. La primera: «once casos» escrito a mano en el banco de la
# puerta y en `kit.conf`, y «diez» en el README, contradiciéndose los tres el mismo día — se
# cerró haciendo que el banco CUENTE sus casos. La segunda: `README.md` e `INSTALACION.md`
# anunciaban cinco skills, dos agentes y tres hooks cuando ya eran seis comandos y una
# skill, y nadie lo vio en seis versiones.
#
# Es la misma regla que el juez de aceptación le impone a cualquier acuerdo: un criterio que
# cuenta cosas caduca en el momento de escribirse. Aquí se aplica al kit, que es de donde
# salió la regla. Y por eso mismo se admite la salida que la regla admite: una MEDICIÓN
# FECHADA. Una línea con una fecha ISO al lado del número pasa, porque el que la lea sabe
# que es una foto. Sin eso, el mensaje de error ofrecería una salida que no existe — lo probó
# el revisor escribiendo «6 comandos (medición del 2026-09-07)» y viéndolo salir en rojo.
#
# LÍMITE DECLARADO. Caza el número pegado a la pieza, con o sin adornos de markdown en medio
# (`**6** comandos`, «6 `comandos`»), y **también** «10 casos» — eso es deliberado y no un
# accidente: «once casos» contra «diez casos» fue la primera vez que esta clase falló. Si
# alguna vez hay que escribir cuántos casos tiene un banco, se fecha o se deja que lo cuente
# el banco, que es lo que ya hace.
#
# NO caza:
#   - el censo escrito con letra («tres hooks»), y eso es deliberado: `hooks.json` dice
#     «tres hooks y ninguno de adorno» como invariante de diseño, no como recuento;
#   - el número separado de la pieza por otras palabras («los 3 primeros hooks»);
#   - la tabla que pone la pieza en una celda y el número en otra;
#   - los ficheros que no son markdown: un censo dentro de un `.sh` o de `kit.conf` no lo ve
#     nadie, y ahí ya ha envejecido alguno;
#   - **`openspec/`, y esto es una decisión, no un olvido**, con dos razones distintas para
#     sus dos mitades. El **archivo** no se lintea porque es historia: sus números describen
#     lo que se midió aquel día, no envejecen ellos, envejece el repositorio. Medido: al pasar
#     este patrón por `openspec/**`, casi todos los disparos caen ahí. El **acuerdo vivo** no
#     se lintea porque ya tiene quien lo mire —un juez de aceptación, y es su trabajo—, no
#     porque el patrón se equivocaría: cuando se midió, el único disparo sobre un acuerdo
#     activo era un acierto, un recuento caducado que el juez cazó él mismo. Si algún día el
#     juez deja de cazarlos, la respuesta es extender esto, y entonces habrá que aceptar que
#     el patrón no distingue el alcance legítimo de un cambio —«se tocan estos dos ficheros»—
#     del censo usado como justificación.
# Ensanchar más el patrón empieza a cazar «3 líneas» o «en 3+ ficheros», y un detector que
# grita lo que no se va a arreglar deja de leerse.
#
# Y la exención por fecha es GRUESA: basta una fecha ISO en cualquier punto de la línea, no
# se comprueba que acompañe al número ni que venga con el comando que lo produjo, que es lo
# que la regla pide. Es un lint de publicación, no una prueba: lo que evita es reintroducir
# sin darse cuenta el número copiado de la salida de un comando.
python3 - <<'PY4' || FALLOS=$((FALLOS+1))
import glob, re, sys
PIEZAS = r"(?:skills?|agentes?|hooks?|comandos?|scripts?|casos?)"
CENSO = re.compile(r"\b\d+[\s*_`~]*" + PIEZAS + r"\b")
FECHA = re.compile(r"\d{4}-\d{2}-\d{2}")
malas = []
for f in (["README.md"] + glob.glob("docs/*.md") + glob.glob("agents/*.md")
          + glob.glob("commands/*.md") + glob.glob("skills/*/SKILL.md")):
    for n, linea in enumerate(open(f).read().splitlines(), 1):
        m = CENSO.search(linea)
        if m and not FECHA.search(linea):
            malas.append(f"{f}:{n} → «{m.group(0).strip()}»")
if malas:
    print("❌ documentos con un censo de piezas escrito a mano:")
    for x in malas: print(f"     {x}")
    print("     sustitúyelo por el comando que lo cuenta, o féchalo en la misma línea")
    sys.exit(1)
print("✅ ningún documento cuenta las piezas del kit a mano")
PY4

echo
[ "$FALLOS" -eq 0 ] && echo "✅ kit sano — se puede publicar." || echo "❌ $FALLOS problema(s): NO publiques."
exit "$FALLOS"
