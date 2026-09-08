#!/usr/bin/env bash
# Banco de pruebas de `inyecta-contexto.sh`.
#
# Por qué existe: ese hook corre en CADA turno y nadie lo invoca, así que cuando se
# equivoca no hay quien lo corrija — solo un digest que afirma cosas sobre el trabajo en
# curso. El 2026-09-07 estuvo una sesión entera diciendo «Sin cambio OpenSpec activo»
# mientras el repositorio donde se trabajaba tenía uno con siete tareas hechas, y además
# dejó un `.agent-kit/` en un repositorio que no usa el kit.
#
# Se escribe ANTES del arreglo: contra la versión sin arreglar tiene que salir rojo en los
# casos que fijan esos dos fallos, y verde en los que no pueden romperse.
#
# Uso:  bash scripts/verifica-contexto.sh
#
# Se puede apuntar a otra versión con HOOK_BAJO_PRUEBA, para comprobar caso por caso que
# cada prueba nueva falla contra la versión vieja:
#
#   git show <commit>:scripts/inyecta-contexto.sh > scripts/.contexto-viejo.sh
#   HOOK_BAJO_PRUEBA="$PWD/scripts/.contexto-viejo.sh" bash scripts/verifica-contexto.sh
set -uo pipefail

HOOK="${HOOK_BAJO_PRUEBA:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/inyecta-contexto.sh}"
[ -f "$HOOK" ] || { echo "no encuentro el hook en $HOOK"; exit 2; }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

FALLOS=0
ROJOS_ESPERADOS=0

# --- utilidades -------------------------------------------------------------------------

# repo <nombre> <openspec:sin|vacio|activo> <kit_conf:si|no> [nombre_dependencia]
repo() {
    local nombre="$1" ospec="$2" conf="$3" dep="${4:-}"
    local r="$TMP/$nombre"
    mkdir -p "$r" || return 1
    (
        cd "$r" || exit 1
        git init -q .
        git config user.email t@t.t
        git config user.name t
        echo base > base.txt
        git add base.txt
        git commit -qm base
        [ "$conf" = "si" ] && echo 'verificaciones() { :; }' > kit.conf
        case "$ospec" in
            vacio)  mkdir -p openspec/changes/archive ;;
            activo)
                mkdir -p openspec/changes/mi-cambio
                printf '# Tareas\n\n- [x] 1. hecha\n- [ ] 2. pendiente\n' \
                    > openspec/changes/mi-cambio/tasks.md
                printf '# P\n\n## Fuera de alcance\n\n- no tocar la caja fuerte\n\n## Otra\n' \
                    > openspec/changes/mi-cambio/proposal.md ;;
            sin) : ;;
        esac
        if [ -n "$dep" ]; then
            mkdir -p ".build/checkouts/$dep"
            echo "reglas de $dep" > ".build/checkouts/$dep/AGENTS.md"
        fi
        git add -A >/dev/null 2>&1
        git commit -qm contenido >/dev/null 2>&1
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

# caso <nombre> <resultado:0|1> <descripción> [conocido]
caso() {
    local ok="$1" desc="$2" conocido="${3:-}"
    if [ "$ok" -eq 0 ]; then
        printf '  ✅ %s\n' "$desc"
    elif [ -n "$conocido" ]; then
        printf '  🔴 %s\n     %s\n' "$desc" "$conocido"
        ROJOS_ESPERADOS=$((ROJOS_ESPERADOS+1))
    else
        printf '  ❌ %s\n' "$desc"
        FALLOS=$((FALLOS+1))
    fi
}

contiene() { case "$1" in *"$2"*) return 0 ;; *) return 1 ;; esac; }

# --- los repos --------------------------------------------------------------------------

repo con_cambio  activo si  PaqueteUno
repo sin_cambio  vacio  si
repo ajeno       sin    no
repo otro_dep    vacio  si  PaqueteDos

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

echo "▶ el digest dice de qué repo habla (criterio 1)"

for r in con_cambio sin_cambio ajeno; do
    D="$(digest "$TMP/$r")"
    contiene "$D" "$r"; caso $? \
        "en «${r}», el digest nombra el repo" \
        "hoy no lo nombra: sus afirmaciones flotan y se leen como si fueran del repo donde se trabaja"
done

echo "▶ un repo sin OpenSpec no recibe órdenes de OpenSpec (criterio 2)"

D="$(digest "$TMP/ajeno")"
if contiene "$D" "/opsx:propose"; then caso 1 \
    "sin openspec/, NO manda proponer" \
    "hoy da la misma orden que a un repo del kit, y ahí nadie puede seguirla"
else caso 0 "sin openspec/, NO manda proponer"; fi

if contiene "$D" "no usa OpenSpec" || contiene "$D" "no tiene OpenSpec"; then caso 0 \
    "sin openspec/, dice que ese repo no usa OpenSpec"
else caso 1 \
    "sin openspec/, dice que ese repo no usa OpenSpec" \
    "hoy sale por la misma rama que «sin cambio activo» y no distingue una cosa de la otra"; fi

echo "▶ no escribir en repos ajenos (criterio 4)"

digest "$TMP/ajeno" >/dev/null
SUCIO="$(cd "$TMP/ajeno" && git status --porcelain)"
if [ -z "$SUCIO" ]; then caso 0 "tras correr en un repo ajeno, git status sigue limpio"
else caso 1 "tras correr en un repo ajeno, git status sigue limpio" \
    "hoy le crea .agent-kit/ sin preguntar: $(printf '%s' "$SUCIO" | tr '\n' ' ')"; fi

echo "▶ el caché no se sirve de un repo a otro (criterios 5-6)"

D1="$(digest "$TMP/con_cambio")"     # depende de PaqueteUno
D2="$(digest "$TMP/otro_dep")"       # depende de PaqueteDos
if contiene "$D1" "PaqueteUno" && contiene "$D2" "PaqueteDos" \
   && ! contiene "$D2" "PaqueteUno"; then
    caso 0 "cada repo recibe SUS dependencias, no las del vecino"
else
    caso 1 "cada repo recibe SUS dependencias, no las del vecino" \
        "D1=[$(printf '%s' "$D1" | grep -o 'Paquete[A-Za-z]*' | tr '\n' ' ')] D2=[$(printf '%s' "$D2" | grep -o 'Paquete[A-Za-z]*' | tr '\n' ' ')]"
fi

# --- resumen ----------------------------------------------------------------------------

echo
if [ "$ROJOS_ESPERADOS" -gt 0 ]; then
    printf '🔴 %s caso(s) en rojo por el fallo que este banco existe para fijar.\n' "$ROJOS_ESPERADOS"
    printf '   Se cierran con el cambio «el-contexto-dice-de-que-repo-habla».\n'
fi
if [ "$FALLOS" -gt 0 ]; then
    printf '❌ %s caso(s) fallan por algo que NO estaba previsto — míralos.\n' "$FALLOS"
fi
[ "$((FALLOS+ROJOS_ESPERADOS))" -eq 0 ] && echo "✅ el hook cumple los trece casos."
exit $(( FALLOS + ROJOS_ESPERADOS > 0 ? 1 : 0 ))
