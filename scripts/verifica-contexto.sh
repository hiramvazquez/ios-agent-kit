#!/usr/bin/env bash
# Banco de pruebas de `inyecta-contexto.sh`.
#
# Por qué existe: ese hook corre en CADA turno y nadie lo invoca, así que cuando se
# equivoca no hay quien lo corrija — solo un digest que afirma cosas sobre el trabajo en
# curso. El 2026-09-07 estuvo una sesión entera diciendo «Sin cambio OpenSpec activo»
# mientras el repositorio donde se trabajaba tenía uno con siete tareas hechas, y además
# dejó un `.agent-kit/` en un repositorio que no usa el kit.
#
# Uso:  bash scripts/verifica-contexto.sh
#
# Se puede apuntar a otra versión con HOOK_BAJO_PRUEBA, para comprobar caso por caso que
# cada prueba que fija un fallo sale roja contra la versión sin arreglar:
#
#   git show <commit>:scripts/inyecta-contexto.sh > scripts/.contexto-viejo.sh
#   HOOK_BAJO_PRUEBA="$PWD/scripts/.contexto-viejo.sh" bash scripts/verifica-contexto.sh
set -uo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
. "$DIR/lib-banco.sh"

HOOK="${HOOK_BAJO_PRUEBA:-$DIR/inyecta-contexto.sh}"
[ -f "$HOOK" ] || { echo "no encuentro el hook en $HOOK"; exit 2; }

# --- montaje ----------------------------------------------------------------------------

# repo <nombre> <openspec:sin|vacio|activo> <kit_conf:si|no> [nombre_dependencia]
repo() {
    local nombre="$1" ospec="$2" conf="$3" dep="${4:-}"
    repo_base "$nombre" "$conf" || return 1
    (
        cd "$TMP/$nombre" || exit 1
        case "$ospec" in
            vacio)  mkdir -p openspec/changes/archive ;;
            activo)
                mkdir -p openspec/changes/mi-cambio
                printf '# Tareas\n\n- [x] 1. hecha\n- [ ] 2. pendiente\n' \
                    > openspec/changes/mi-cambio/tasks.md
                printf '# P\n\n## Fuera de alcance\n\n- no tocar la caja fuerte\n\n## Otra\n' \
                    > openspec/changes/mi-cambio/proposal.md ;;
            dos)
                # CINCO cambios abiertos a la vez, creados en orden inverso al
                # alfabético. OpenSpec permite varios, y el kit elegía uno con `head -1`
                # sobre un `find`: por el orden del sistema de ficheros.
                #
                # Cinco y no dos, y esto salió de la revisión: con dos, el orden que APFS
                # devuelve coincidía con el alfabético y el caso pasaba igual con el código
                # roto — cobertura decorativa. Con cinco no coincide (`find` devuelve
                # `ccc-tercero` primero aquí), así que el caso distingue de verdad.
                for c in ccc-tercero eee-quinto bbb-segundo ddd-cuarto aaa-primero; do
                    mkdir -p "openspec/changes/$c"
                    printf '# Tareas\n\n- [ ] 1. pendiente de %s\n' "$c" \
                        > "openspec/changes/$c/tasks.md"
                    printf '# P\n\n## Fuera de alcance\n\n- nada\n\n## Otra\n' \
                        > "openspec/changes/$c/proposal.md"
                done ;;
            sin) : ;;
        esac
        if [ -n "$dep" ]; then
            mkdir -p ".build/checkouts/$dep"
            echo "reglas de $dep" > ".build/checkouts/$dep/AGENTS.md"
        fi
        git add -A >/dev/null 2>&1
        git -c user.name=t -c user.email=t@t.t commit -qm contenido >/dev/null 2>&1
        exit 0
    )
}

# digest <repo> → imprime el additionalContext que produciría el hook
#
# HOME se fija al temporal a propósito: el hook rastrea `DerivedData` bajo $HOME y en una
# máquina real eso tarda y contamina el resultado con dependencias que no son del test.
# XDG_CACHE_HOME va aparte para poder comprobar dónde acaba el caché.
digest() {
    local r="$1"
    (
        cd "$r" || exit 1
        HOME="$TMP/home" XDG_CACHE_HOME="$TMP/cache" bash "$HOOK" 2>/dev/null \
            | python3 -c 'import json,sys
try:
    d = json.load(sys.stdin)
    print(d["hookSpecificOutput"]["additionalContext"])
except Exception:
    print("")'
    )
}

# --- los repos --------------------------------------------------------------------------

repo con_cambio  activo si  PaqueteUno
repo sin_cambio  vacio  si
repo ajeno       sin    no
repo otro_dep    vacio  si  PaqueteDos
repo dos_cambios dos    si

mkdir -p "$TMP/home"

# --- los casos --------------------------------------------------------------------------

echo "▶ lo que ya hacía, y no puede romperse"

D="$(digest "$TMP/con_cambio")"
contiene "$D" "Reglas que ningún linter puede comprobar por ti"; caso $? \
    "las reglas innegociables siguen inyectándose"
contiene "$D" "mi-cambio"; caso $? \
    "con cambio activo, lo nombra"
contiene "$D" "2. pendiente"; caso $? \
    "con cambio activo, lista lo que queda"
contiene "$D" "no tocar la caja fuerte"; caso $? \
    "con cambio activo, recuerda el fuera de alcance"

D="$(digest "$TMP/sin_cambio")"
contiene "$D" "Sin cambio OpenSpec activo"; caso $? \
    "con openspec/ y sin cambio activo, lo dice"
contiene "$D" "/opsx:propose"; caso $? \
    "con openspec/ y sin cambio activo, manda proponer"

echo "▶ el digest dice de qué repo habla"

for r in con_cambio sin_cambio ajeno; do
    D="$(digest "$TMP/${r}")"
    contiene "$D" "${r}"; caso $? \
        "en «${r}», el digest nombra el repo" \
        "no lo nombraba: sus afirmaciones flotaban y se leían como del repo donde se trabaja"
done

echo "▶ un repo sin OpenSpec no recibe órdenes de OpenSpec"

D="$(digest "$TMP/ajeno")"
if contiene "$D" "/opsx:propose"; then caso 1 \
    "sin openspec/, NO manda proponer" \
    "daba la misma orden que a un repo del kit, y ahí nadie puede seguirla"
else caso 0 "sin openspec/, NO manda proponer"; fi

if contiene "$D" "no usa OpenSpec" || contiene "$D" "no tiene OpenSpec"; then caso 0 \
    "sin openspec/, dice que ese repo no usa OpenSpec"
else caso 1 \
    "sin openspec/, dice que ese repo no usa OpenSpec" \
    "salía por la misma rama que «sin cambio activo» y no distinguía una cosa de la otra"; fi

echo "▶ no escribir en repos ajenos"

digest "$TMP/ajeno" >/dev/null
SUCIO="$(cd "$TMP/ajeno" && git status --porcelain)"
if [ -z "$SUCIO" ]; then caso 0 "tras correr en un repo ajeno, git status sigue limpio"
else caso 1 "tras correr en un repo ajeno, git status sigue limpio" \
    "le creaba .agent-kit/ sin preguntar: $(printf '%s' "$SUCIO" | tr '\n' ' ')"; fi

echo "▶ el caché"

D1="$(digest "$TMP/con_cambio")"     # depende de PaqueteUno
D2="$(digest "$TMP/otro_dep")"       # depende de PaqueteDos
if contiene "$D1" "PaqueteUno" && contiene "$D2" "PaqueteDos" \
   && ! contiene "$D2" "PaqueteUno"; then
    caso 0 "cada repo recibe SUS dependencias, no las del vecino"
else
    caso 1 "cada repo recibe SUS dependencias, no las del vecino" \
        "D1=[$(printf '%s' "$D1" | grep -o 'Paquete[A-Za-z]*' | tr '\n' ' ')] D2=[$(printf '%s' "$D2" | grep -o 'Paquete[A-Za-z]*' | tr '\n' ' ')]"
fi

# El criterio decía que el caché «evita el recorrido en turnos consecutivos» y NADIE lo
# comprobaba: solo se afirmaba en un comentario. Lo señaló un juez de aceptación. Se fija
# añadiendo una dependencia DESPUÉS del primer turno: si el segundo la ve, es que ha vuelto
# a recorrer y el caché no sirve para nada.
mkdir -p "$TMP/con_cambio/.build/checkouts/PaqueteTardio"
echo reglas > "$TMP/con_cambio/.build/checkouts/PaqueteTardio/AGENTS.md"
D3="$(digest "$TMP/con_cambio")"
# Se exige la PRESENCIA de la vieja además de la ausencia de la nueva. Solo con la
# ausencia, un hook que dejara de inyectar la línea de paquetes pasaría este caso sin
# haber cacheado nada — lo encontró un juez probando ese mutante.
if contiene "$D3" "PaqueteUno" && ! contiene "$D3" "PaqueteTardio"; then
    caso 0 "el segundo turno no vuelve a recorrer: usa el caché"
else
    caso 1 "el segundo turno no vuelve a recorrer: usa el caché" \
        "vio una dependencia añadida tras el primer turno (recorrió otra vez), o dejó de inyectar la línea"
fi

echo "▶ con varios cambios activos, elige estable y lo dice"

D1="$(digest "$TMP/dos_cambios")"
D2="$(digest "$TMP/dos_cambios")"
E1="$(printf '%s' "$D1" | sed -n 's/.*Cambio activo: \([a-z-]*\).*/\1/p')"
E2="$(printf '%s' "$D2" | sed -n 's/.*Cambio activo: \([a-z-]*\).*/\1/p')"
# Se exige el MÍNIMO por `LC_ALL=C`, no solo que dos corridas coincidan entre sí.
#
# La primera versión de este caso comparaba `E1` con `E2` y ya está, y el revisor de la
# rodaja lo cazó: dos `find` seguidos sobre un directorio que no ha cambiado devuelven el
# mismo orden en cualquier sistema de ficheros, así que la aserción pasaba igual con el
# código roto. Cobertura decorativa. Los directorios se crean a propósito en orden inverso
# al alfabético (`bbb-segundo` antes que `aaa-primero`), que es lo que separa «ordenado» de
# «lo que devolvió el sistema de ficheros».
if [ "$E1" = "aaa-primero" ] && [ "$E1" = "$E2" ]; then
    caso 0 "elige el primero por orden estable, no el que devuelva el sistema de ficheros"
else
    caso 1 "elige el primero por orden estable, no el que devuelva el sistema de ficheros" \
        "elegía con head -1 sobre un find: el orden lo ponía el sistema de ficheros [$E1|$E2]"
fi

contiene "$D1" "5 cambios activos"; caso $? \
    "con varios cambios activos, avisa de cuántos hay" \
    "elegía uno y se lo callaba: el digest hablaba de un acuerdo mientras se trabajaba en el otro"

echo "▶ no escribe en directorios compartidos"

# LÍMITE DECLARADO de este caso: es LÉXICO, no dinámico. El fichero que había se creaba y se
# borraba dentro de la misma corrida, así que mirar qué queda en el temporal del sistema no
# lo habría visto nunca. Lo que se comprueba es que el hook no NOMBRE `/tmp`, que es la
# única señal mecánica disponible de que vuelva a escribir ahí.
if grep -v '^[[:space:]]*#' "$HOOK" | grep -q '/tmp/'; then
    caso 1 "el hook no escribe en el temporal compartido del sistema" \
        "usaba /tmp/.ic.\$\$ —nombre derivable del PID— en cada turno de cualquier repositorio"
else
    caso 0 "el hook no escribe en el temporal compartido del sistema"
fi

# El número de repos se CUENTA. Escrito a mano decía 4 cuando ya había 5, y solo pasaba
# porque el quinto se digestaba después de contar: se rompía en cuanto alguien moviera un
# bloque. Es el mismo censo a mano que este kit prohíbe en los acuerdos.
REPOS="$(find "$TMP" -maxdepth 2 -name .git -type d 2>/dev/null | wc -l | tr -d ' ')"
CACHES="$(find "$TMP/cache/ios-agent-kit" -type f 2>/dev/null | wc -l | tr -d ' ')"
if [ "$CACHES" -eq "$REPOS" ]; then IGUALES=0; else IGUALES=1; fi
caso "$IGUALES" "el caché vive fuera del repo, un fichero por repositorio ($CACHES de $REPOS)" \
    "vivía en .agent-kit/ dentro del repo observado, así que fuera no hay ninguno"

# Los rojos que quedan por cerrar son de ESTE cambio, no del que trajo el banco: los tres
# casos nuevos —orden estable, aviso de varios activos, y no escribir en /tmp— los añadió
# `el-kit-se-aplica-a-si-mismo`.
resumen "el hook" "el-kit-se-aplica-a-si-mismo"
