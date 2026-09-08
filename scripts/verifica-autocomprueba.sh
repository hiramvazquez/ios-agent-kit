#!/usr/bin/env bash
# Banco de pruebas de `autocomprueba.sh`, la puerta de publicación del kit.
#
# Por qué existe, y por qué tan tarde: es el script que dice «kit sano — se puede publicar», y
# fue, desde la primera versión publicada hasta este banco, la única pieza con lógica que
# nadie miraba. Su punto ciego —comprobar solo las rutas que ya empezaban por `${CLAUDE_PLUGIN_ROOT}` y no ver
# las que omitían la raíz— dejó pasar todo ese tiempo una invocación muerta en el prompt del
# juez de aceptación.
#
# No tenía banco por una razón concreta, y hubo que quitarla antes de escribir este: el script
# hacía `cd` a SU propia raíz, así que no se le podía apuntar a un árbol de prueba. Ahora
# acepta una raíz opcional.
#
# Este banco NO nace en rojo, y eso es correcto: no fija un fallo, cubre una pieza que nadie
# cubría. Cada caso monta un árbol de kit falso con UN defecto y exige que el detector lo vea;
# el último monta uno sano y exige que salga limpio, que es el que impide que todo esto pase
# por construcción — un detector que devolviera rojo siempre aprobaría todos los demás casos.
#
# Uso:  bash scripts/verifica-autocomprueba.sh
set -uo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
. "$DIR/lib-banco.sh"

AUTO="$DIR/autocomprueba.sh"
[ -f "$AUTO" ] || { echo "no encuentro autocomprueba.sh en $AUTO"; exit 2; }

# Los tres códigos que este cambio le da a `autocomprueba.sh`, con la misma forma —y la misma
# razón— que ya tenía `scripts/verifica.sh`: 0 sano, 1 hay problemas (sea cual sea cuántos), 3
# no pude mirar. Antes de este cambio el «hay problemas» era `$FALLOS`, así que un único
# problema y una raíz inexistente competían por el mismo 1.
COD_SANO=0
COD_PROBLEMAS=1
COD_NO_PUDE_MIRAR=3

# --- montaje ------------------------------------------------------------------------------

# kit_sano <nombre>   → un árbol de kit mínimo y correcto, que pasa TODAS las comprobaciones
kit_sano() {
    local r="$TMP/$1"
    mkdir -p "$r/.claude-plugin" "$r/hooks" "$r/scripts" "$r/commands" "$r/agents" \
             "$r/skills/una-skill" "$r/docs"
    printf '{\n  "name": "kit-de-prueba",\n  "version": "1.0.0"\n}\n' \
        > "$r/.claude-plugin/plugin.json"
    printf '{\n  "name": "mercado",\n  "plugins": []\n}\n' \
        > "$r/.claude-plugin/marketplace.json"
    printf '{\n  "hooks": {\n    "UserPromptSubmit": [\n      { "hooks": [\n        { "type": "command", "command": "bash \\"${CLAUDE_PLUGIN_ROOT}/scripts/algo.sh\\"" }\n      ] }\n    ]\n  }\n}\n' \
        > "$r/hooks/hooks.json"
    printf '#!/usr/bin/env bash\necho algo\n' > "$r/scripts/algo.sh"
    chmod +x "$r/scripts/algo.sh"
    printf -- '---\ndescription: un comando\n---\n\n```bash\nbash "${CLAUDE_PLUGIN_ROOT}/scripts/algo.sh"\n```\n' \
        > "$r/commands/un-comando.md"
    printf -- '---\nname: un-agente\n---\n\nUn agente que no cuenta piezas.\n' \
        > "$r/agents/un-agente.md"
    printf -- '---\nname: una-skill\n---\n\nUna skill.\n' > "$r/skills/una-skill/SKILL.md"
    printf '# Kit de prueba\n\nSin recuentos escritos a mano.\n' > "$r/README.md"
    printf '# Doc\n\nTampoco aquí.\n' > "$r/docs/algo.md"
}

# comprueba <árbol> → salida del detector sobre ese árbol; su código de salida queda en $?
comprueba() { bash "$AUTO" "$TMP/$1" 2>&1; }

# falla_con <árbol> <descripción> <patrón esperado>  … monta ya roto por quien llama, y juzga
#
# EXIGE LAS DOS COSAS: que el detector lo diga Y que salga distinto de 0.
#
# La primera versión solo miraba el mensaje, y el revisor la tumbó con un mutante de una
# línea —`exit "$FALLOS"` → `exit 0`—: el detector imprimía «❌ 3 problema(s): NO publiques»,
# salía con 0, y este banco daba 11/11. Lo que `kit.conf` lee es EXACTAMENTE lo otro: su
# `paso()` solo mira el estado de salida. O sea que un kit con los tres manifiestos rotos
# habría pasado la puerta de publicación con el banco en verde. Un banco que comprueba el
# mensaje y no el veredicto es peor que no tenerlo, porque tranquiliza.
falla_con() {
    local arbol="$1" desc="$2" patron="$3" S codigo
    S="$(comprueba "$arbol")"; codigo=$?
    if [ "$codigo" -eq 0 ]; then
        caso 1 "$desc — lo DIJO pero salió con 0, y kit.conf solo mira el código: habría publicado"
    elif [ "$codigo" -ne "$COD_PROBLEMAS" ]; then
        # Cada fixture de aquí abajo monta UN defecto distinto; si alguno saliera con un código
        # que no es el fijo de «hay problemas», ya no se distinguiría de «no pude mirar» —que
        # es exactamente la cláusula 2 del delta: el código no puede depender de CUÁL problema.
        caso 1 "$desc — lo dijo, pero con código $codigo en vez de $COD_PROBLEMAS: se confunde con «no pude mirar»"
    elif contiene "$S" "$patron"; then
        caso 0 "$desc"
    else
        caso 1 "$desc — falló, pero por otra cosa: $(printf '%s' "$S" | grep '❌' | head -1)"
    fi
}

# --- los casos ----------------------------------------------------------------------------

echo "▶ los manifiestos, que es por lo que este detector nació"

kit_sano json_roto
# marketplace.json y no hooks.json: este solo lo lee la comprobación 1, así que el caso falla
# por lo que dice fallar. Romper hooks.json tumbaba además la 3 y la 4.
printf '{ esto no es json\n' > "$TMP/json_roto/.claude-plugin/marketplace.json"
falla_con json_roto "un JSON que no parsea se caza" "NO parsea"

kit_sano rutas_redundantes
printf '{\n  "name": "k",\n  "version": "1.0.0",\n  "agents": "./agents"\n}\n' \
    > "$TMP/rutas_redundantes/.claude-plugin/plugin.json"
falla_con rutas_redundantes "plugin.json con rutas que ya son las de por defecto" "usa las rutas por defecto"

kit_sano eventos_arriba
printf '{\n  "UserPromptSubmit": []\n}\n' > "$TMP/eventos_arriba/hooks/hooks.json"
falla_con eventos_arriba "hooks.json con los eventos fuera del objeto hooks" "nivel superior"

# La comprobación 3 tiene DOS ramas con mensajes distintos y solo se ejercía la de arriba. Un
# mutante de un carácter en la otra —`sys.exit(1)` → `sys.exit(0)`— dejaba el banco en 12/12
# mientras la puerta aprobaba un kit cuyos hooks no carga ninguno.
kit_sano hooks_sin_objeto
printf '{\n  "config": { "algo": 1 }\n}\n' > "$TMP/hooks_sin_objeto/hooks/hooks.json"
falla_con hooks_sin_objeto "hooks.json sin objeto hooks" "no tiene objeto"

kit_sano hook_sin_script
# se cambia el hook, no se borra el script: borrarlo rompía también la cita del comando, y el
# caso habría podido pasar por la comprobación equivocada.
printf '{\n  "hooks": {\n    "UserPromptSubmit": [\n      { "hooks": [\n        { "type": "command", "command": "bash \\"${CLAUDE_PLUGIN_ROOT}/scripts/fantasma.sh\\"" }\n      ] }\n    ]\n  }\n}\n' \
    > "$TMP/hook_sin_script/hooks/hooks.json"
falla_con hook_sin_script "un hook que apunta a un script que no existe" "no existen o no son ejecutables"

kit_sano hook_no_ejecutable
chmod -x "$TMP/hook_no_ejecutable/scripts/algo.sh"
falla_con hook_no_ejecutable "un hook que apunta a un script no ejecutable" "no existen o no son ejecutables"

echo "▶ lo que citan comandos y agentes"

kit_sano cita_inexistente
printf -- '---\nname: a\n---\n\n```bash\nbash "${CLAUDE_PLUGIN_ROOT}/scripts/no-existe.sh"\n```\n' \
    > "$TMP/cita_inexistente/agents/un-agente.md"
falla_con cita_inexistente "una cita a un fichero del kit que no existe" "citan ficheros que no existen"

kit_sano cita_sin_raiz
printf -- '---\nname: a\n---\n\n```bash\nbash Scripts/algo.sh --informe\n```\n' \
    > "$TMP/cita_sin_raiz/agents/un-agente.md"
falla_con cita_sin_raiz "una cita a un fichero del kit SIN la raíz del plugin" "sin \${CLAUDE_PLUGIN_ROOT}"

echo "▶ los censos y el frontmatter"

kit_sano censo
printf '# Kit\n\nTrae 5 skills.\n' > "$TMP/censo/README.md"
falla_con censo "un censo a mano en el README" "censo de piezas"

# El mismo mutante de arriba, aplicado a la lista de ficheros del lint: reducirla a
# `["README.md"]` dejaba el banco verde y un censo en `docs/` se publicaba.
#
# Un caso por cada sitio donde el lint mira, y no por gusto: aquí ponía un LÍMITE DECLARADO
# diciendo que los tres que faltaban «comparten bucle con el frontmatter, así que sus mutantes
# ya mueren allí». Era falso —el frontmatter es el punto 6 y el censo la lista del punto 7, que
# no comparten nada— y el juez lo demostró: quitando agentes, comandos y skills de esa lista,
# el banco seguía verde y un censo en `agents/` se publicaba. Una justificación que tapa un
# hueco es peor que el hueco.
kit_sano censo_en_docs
printf '# Doc\n\nEl kit trae 3 hooks.\n' > "$TMP/censo_en_docs/docs/algo.md"
falla_con censo_en_docs "un censo a mano en docs/" "censo de piezas"

kit_sano censo_en_agente
printf -- '---\nname: a\n---\n\nEste kit trae 3 hooks.\n' > "$TMP/censo_en_agente/agents/un-agente.md"
falla_con censo_en_agente "un censo a mano en un agente" "censo de piezas"

kit_sano censo_en_comando
printf -- '---\ndescription: c\n---\n\nEste kit trae 3 hooks.\n' > "$TMP/censo_en_comando/commands/un-comando.md"
falla_con censo_en_comando "un censo a mano en un comando" "censo de piezas"

kit_sano censo_en_skill
printf -- '---\nname: s\n---\n\nEste kit trae 3 hooks.\n' > "$TMP/censo_en_skill/skills/una-skill/SKILL.md"
falla_con censo_en_skill "un censo a mano en una skill" "censo de piezas"

kit_sano censo_fechado
printf '# Kit\n\nMedición del 2026-09-08: trae 5 skills.\n' > "$TMP/censo_fechado/README.md"
S="$(comprueba censo_fechado)"; CODIGO=$?
if [ "$CODIGO" -ne 0 ] || contiene "$S" "censo de piezas"; then
    caso 1 "un recuento FECHADO pasa — lo cazó igual, y su mensaje ofrece una salida que no existe"
else
    caso 0 "un recuento FECHADO pasa: es una medición, no un censo"
fi

# Tres casos y no uno, uno por cada glob que mira esa comprobación: con un solo fixture,
# reducir el bucle a `agents/*.md` dejaba el banco verde y un comando sin frontmatter se
# publicaba. Un mutante que quita un glob solo muere si el fichero roto está en ESE glob.
kit_sano sin_frontmatter_agente
printf 'Un agente sin frontmatter.\n' > "$TMP/sin_frontmatter_agente/agents/un-agente.md"
falla_con sin_frontmatter_agente "un agente sin frontmatter" "no empieza con frontmatter"

kit_sano sin_frontmatter_comando
printf 'Un comando sin frontmatter.\n' > "$TMP/sin_frontmatter_comando/commands/un-comando.md"
falla_con sin_frontmatter_comando "un comando sin frontmatter" "no empieza con frontmatter"

kit_sano sin_frontmatter_skill
printf 'Una skill sin frontmatter.\n' > "$TMP/sin_frontmatter_skill/skills/una-skill/SKILL.md"
falla_con sin_frontmatter_skill "una skill sin frontmatter" "no empieza con frontmatter"

echo "▶ y el árbol sano, que es el que impide que todo lo anterior pase por construcción"

kit_sano sano
S="$(comprueba sano)"; CODIGO=$?
if [ "$CODIGO" -eq "$COD_SANO" ] && contiene "$S" "kit sano"; then
    caso 0 "un árbol de kit correcto sale limpio, y con código $COD_SANO"
else
    caso 1 "un árbol de kit correcto sale limpio — si falla, los casos de arriba pasan por construcción: $(printf '%s' "$S" | grep '❌' | head -1)"
fi

echo "▶ los tres códigos de salida, que es lo que arregla este cambio"

# El escenario del delta: MÁS DE UN problema real, y el código tiene que seguir siendo el
# mismo «hay problemas» que un solo defecto — no el número de fallos, que es lo que rompía
# esto antes de este cambio.
kit_sano varios_defectos
printf '{ esto no es json\n' > "$TMP/varios_defectos/.claude-plugin/marketplace.json"
printf '{\n  "name": "k",\n  "version": "1.0.0",\n  "agents": "./agents"\n}\n' \
    > "$TMP/varios_defectos/.claude-plugin/plugin.json"
S="$(comprueba varios_defectos)"; CODIGO=$?
if [ "$CODIGO" -eq "$COD_PROBLEMAS" ] && contiene "$S" "2 problema"; then
    caso 0 "un árbol con VARIOS defectos sale con el mismo código que uno solo, y dice cuántos"
else
    caso 1 "un árbol con varios defectos — código $CODIGO (se esperaba $COD_PROBLEMAS) o no contó bien: $(printf '%s' "$S" | tail -1)"
fi

# La raíz inexistente: antes de este cambio salía con 1, el MISMO código que un único
# problema real. Es la colisión que dispara todo el arreglo.
S="$(bash "$AUTO" "$TMP/esta-raiz-no-existe" 2>&1)"; CODIGO=$?
if [ "$CODIGO" -eq "$COD_NO_PUDE_MIRAR" ] && contiene "$S" "no existe la raíz"; then
    caso 0 "una raíz que no existe sale con el código de «no pude mirar», no con el de «hay problemas»"
else
    caso 1 "una raíz que no existe — código $CODIGO (se esperaba $COD_NO_PUDE_MIRAR): $(printf '%s' "$S" | tail -1)"
fi

# El escenario «sin argumento» del delta no lo ejercía ningún caso: todos los de arriba pasan
# raíz explícita. Se invoca desde `/` a propósito — si la raíz por defecto se resolviera con
# `$PWD` en vez de con la del propio script, aquí saldría en rojo y en `verifica.sh` no, porque
# allí el cwd ya es la raíz del kit. Depende de que ESTE kit esté sano, que es una precondición
# de publicar y la comprueba el paso 4.
# Se comparan las DOS salidas en vez de exigir verde. Exigiendo verde, el caso dependía de que
# este kit estuviera sano: un censo en el README lo ponía en rojo diciendo «resolvió otra
# raíz», que es falso —resolvió la buena, el kit estaba roto—. Comparando, se mide lo único
# que este caso quiere medir, y sigue muriendo con el mutante `RAIZ="${1:-$PWD}"`.
PROPIA="$(cd "$DIR/.." && pwd)"
A="$( cd / && bash "$AUTO" 2>&1 )"
B="$( bash "$AUTO" "$PROPIA" 2>&1 )"
if [ "$A" = "$B" ]; then
    caso 0 "sin argumento resuelve su propia raíz, se le invoque desde donde se le invoque"
else
    caso 1 "sin argumento resuelve su propia raíz — desde / dijo otra cosa que apuntándolo a ella"
fi

resumen "autocomprueba.sh" "donde-la-regla-solo-llego-a-un-hermano"
