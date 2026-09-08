#!/usr/bin/env bash
# Banco de pruebas de `puerta-commit.sh`.
#
# Por qué existe: la puerta se ha cambiado a ojo desde que nació, y el 2026-09-07 se
# descubrió que fallaba de CUATRO formas distintas a la vez — dos de ellas dejando pasar
# commits sin verificar. Ninguna se veía leyendo el script; todas se ven aquí.
#
# Se escribió ANTES del arreglo, a propósito: hasta que se cierre el cambio
# `la-puerta-mira-el-repo-del-commit`, este banco sale en ROJO en los casos que fijan los
# fallos, y en VERDE en los que no pueden romperse. Un banco que naciera verde no habría
# demostrado nada.
#
# Uso:  bash scripts/verifica-puerta.sh
set -uo pipefail

# Se puede apuntar a otra versión del script con PUERTA_BAJO_PRUEBA. Es lo que permite
# comprobar, caso por caso, que cada prueba nueva falla contra la versión SIN arreglar:
#
#   git show <commit>:scripts/puerta-commit.sh > scripts/.puerta-vieja.sh
#   PUERTA_BAJO_PRUEBA="$PWD/scripts/.puerta-vieja.sh" bash scripts/verifica-puerta.sh
#
# La copia tiene que quedar DENTRO de `scripts/`, no en `/tmp`. La puerta busca a
# `verifica.sh` como vecino suyo (`dirname "$BASH_SOURCE"`), así que una copia en otro
# directorio no lo encuentra, el `if` falla y TODO acaba bloqueado: sale un rojo que parece
# un hallazgo y es el montaje. Pasó al escribir esto.
PUERTA="${PUERTA_BAJO_PRUEBA:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/puerta-commit.sh}"
[ -f "$PUERTA" ] || { echo "no encuentro la puerta en $PUERTA"; exit 2; }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

FALLOS=0
ROJOS_ESPERADOS=0

# --- utilidades -------------------------------------------------------------------------

# repo <nombre> <con_kit_conf:si|no> <firma:valida|rota|ninguna>
#
# Deja el repo con algo STAGEADO, porque la firma se calcula sobre `git diff --cached` y un
# índice vacío haría que todos los repos compartieran la misma huella.
repo() {
    local nombre="$1" conf="$2" firma="$3"
    local r="$TMP/$nombre"
    mkdir -p "$r" || return 1
    (
        cd "$r" || exit 1
        git init -q .
        git config user.email t@t.t
        git config user.name t
        echo "base" > base.txt
        git add base.txt
        git commit -qm base
        [ "$conf" = "si" ] && echo 'verificaciones() { :; }' > kit.conf
        echo "cambio" > nuevo.txt
        git add nuevo.txt
        case "$firma" in
            valida)
                mkdir -p .agent-kit
                { echo "verificado: $(date -u +%FT%TZ)"
                  echo "diff: $(git diff --cached | shasum -a 256 | cut -d' ' -f1)"
                  echo "resultado: verde"; } > .agent-kit/verificacion.txt ;;
            rota)
                mkdir -p .agent-kit
                { echo "verificado: $(date -u +%FT%TZ)"
                  echo "diff: 0000000000000000000000000000000000000000000000000000000000000000"
                  echo "resultado: verde"; } > .agent-kit/verificacion.txt ;;
            ninguna) : ;;
        esac
    )
}

# decision <cwd> <comando>  → imprime "pasa" o "bloquea"
decision() {
    local cwd="$1" cmd="$2" salida
    salida="$(
        cd "$cwd" || exit 1
        python3 -c 'import json,sys; print(json.dumps({"tool_input":{"command":sys.argv[1]}}))' "$cmd" \
            | bash "$PUERTA" 2>/dev/null
    )"
    case "$salida" in
        *'"permissionDecision":"deny"'*|*'"permissionDecision": "deny"'*) echo bloquea ;;
        *) echo pasa ;;
    esac
}

# caso <esperado> <cwd> <comando> <descripción> [conocido]
#
# `conocido` marca los casos que HOY fallan porque la puerta no está arreglada. Se cuentan
# aparte y no se disimulan: el banco los enseña en cada corrida para que se vea qué queda.
caso() {
    local esperado="$1" cwd="$2" cmd="$3" desc="$4" conocido="${5:-}" real
    real="$(decision "$cwd" "$cmd")"
    if [ "$real" = "$esperado" ]; then
        printf '  ✅ %s\n' "$desc"
    elif [ -n "$conocido" ]; then
        printf '  🔴 %s\n     esperado: %s · real: %s — %s\n' "$desc" "$esperado" "$real" "$conocido"
        ROJOS_ESPERADOS=$((ROJOS_ESPERADOS+1))
    else
        printf '  ❌ %s\n     esperado: %s · real: %s\n' "$desc" "$esperado" "$real"
        FALLOS=$((FALLOS+1))
    fi
}

# --- los repos --------------------------------------------------------------------------

repo kit_firmado    si valida
repo kit_sin_firma  si ninguna
repo kit_firma_rota si rota
repo ajeno          no ninguna

# --- los casos --------------------------------------------------------------------------

echo "▶ el caso normal, que no puede romperse"
caso pasa    "$TMP/kit_firmado"    'git commit -m "x"' \
     "repo del kit con firma válida → pasa"
caso bloquea "$TMP/kit_sin_firma"  'git commit -m "x"' \
     "repo del kit sin firma → bloquea"
caso bloquea "$TMP/kit_firma_rota" 'git commit -m "x"' \
     "repo del kit con firma de otro diff → bloquea"
caso pasa    "$TMP/kit_firmado"    'ls -la' \
     "un comando que no es un commit → pasa"

echo "▶ el commit va a OTRO repo (criterios 1-3)"
caso bloquea "$TMP/kit_firmado" "git -C $TMP/kit_sin_firma commit -m x" \
     "-C a un repo sin firma → bloquea" \
     "hoy no casa el patrón de subcadena y sale por exit 0 sin comprobar nada"
caso pasa    "$TMP/kit_firmado" "git -C $TMP/kit_firmado commit -m x" \
     "-C a un repo con firma válida → pasa"
# Este es el que DISCRIMINA de verdad en la familia `-C`: el de arriba pasaba también con la
# puerta rota, pero porque se colaba sin mirar nada, no porque la firma fuera buena.
caso bloquea "$TMP/kit_firmado" "git -C $TMP/kit_firma_rota commit -m x" \
     "-C a un repo con firma de OTRO diff → bloquea" \
     "hoy se cuela igual: sin reconocer la invocación, la firma no llega a mirarse"
caso bloquea "$TMP/kit_firmado" "cd $TMP/kit_sin_firma && git commit -m x" \
     "cd a un repo sin firma → bloquea" \
     "hoy mira el cwd, no el repo de destino, y el cwd sí tiene firma"

echo "▶ texto que no es una invocación (criterio 5)"
caso pasa "$TMP/kit_sin_firma" 'echo "git commit no se ejecuta aquí"' \
     "un echo que menciona las palabras → pasa" \
     "hoy el case casa contra la cadena entera y lo bloquea"
caso pasa "$TMP/kit_sin_firma" 'grep -rn "git commit" docs/' \
     "un grep que busca las palabras → pasa" \
     "mismo motivo que el anterior"

echo "▶ repos que no usan el kit (criterio 4)"
caso pasa "$TMP/ajeno" 'git commit -m "x"' \
     "repo sin kit.conf → pasa" \
     "hoy bloquea y no hay salida: verifica.sh no puede firmar sin kit.conf"

# --- resumen ----------------------------------------------------------------------------

echo
if [ "$ROJOS_ESPERADOS" -gt 0 ]; then
    printf '🔴 %s caso(s) en rojo por el fallo que este banco existe para fijar.\n' "$ROJOS_ESPERADOS"
    printf '   Se cierran con el cambio «la-puerta-mira-el-repo-del-commit».\n'
fi
if [ "$FALLOS" -gt 0 ]; then
    printf '❌ %s caso(s) fallan por algo que NO estaba previsto — míralos.\n' "$FALLOS"
fi
[ "$((FALLOS+ROJOS_ESPERADOS))" -eq 0 ] && echo "✅ la puerta cumple los once casos."
exit $(( FALLOS + ROJOS_ESPERADOS > 0 ? 1 : 0 ))
