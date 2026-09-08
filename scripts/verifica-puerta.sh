#!/usr/bin/env bash
# Banco de pruebas de `puerta-commit.sh`.
#
# Por qué existe: la puerta se ha cambiado a ojo desde que nació, y el 2026-09-07 se
# descubrió que fallaba de CUATRO formas distintas a la vez — dos de ellas dejando pasar
# commits sin verificar. Ninguna se veía leyendo el script; todas se ven aquí.
#
# Y aun con este banco en verde, un juez de aceptación encontró una quinta: `(cd X && …)`
# caía al directorio heredado porque el primer token del segmento era `(`. Los casos que
# empiezan por «agrupada» y «envuelta» salen de ahí. La lección, escrita para el siguiente:
# un banco verde dice que lo probado funciona, no que se haya probado lo que importa.
#
# Uso:  bash scripts/verifica-puerta.sh
#
# Se puede apuntar a otra versión con PUERTA_BAJO_PRUEBA, para comprobar caso por caso que
# cada prueba que fija un fallo sale roja contra la versión sin arreglar:
#
#   git show <commit>:scripts/puerta-commit.sh > scripts/.puerta-vieja.sh
#   PUERTA_BAJO_PRUEBA="$PWD/scripts/.puerta-vieja.sh" bash scripts/verifica-puerta.sh
#
# La copia tiene que quedar DENTRO de `scripts/`, no en `/tmp`. La puerta busca a
# `verifica.sh` y a `analiza-invocacion.py` como vecinos suyos, así que una copia en otro
# directorio no los encuentra, el `if` falla y TODO acaba bloqueado: sale un rojo que parece
# un hallazgo y es el montaje. Pasó al escribir esto.
set -uo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
. "$DIR/lib-banco.sh"

PUERTA="${PUERTA_BAJO_PRUEBA:-$DIR/puerta-commit.sh}"
[ -f "$PUERTA" ] || { echo "no encuentro la puerta en $PUERTA"; exit 2; }

# --- montaje --------------------------------------------------------------------------

# repo <nombre> <kit_conf:si|no> <firma:valida|rota|ninguna>
#
# Deja algo STAGEADO, porque la firma se calcula sobre `git diff --cached` y un índice vacío
# haría que todos los repos compartieran la misma huella.
repo() {
    local nombre="$1" conf="$2" firma="$3"
    repo_base "$nombre" "$conf" || return 1
    (
        cd "$TMP/$nombre" || exit 1
        echo cambio > nuevo.txt
        git add nuevo.txt
        case "$firma" in
            valida|rota)
                mkdir -p .agent-kit
                local h
                if [ "$firma" = "valida" ]; then
                    h="$(git diff --cached | shasum -a 256 | cut -d' ' -f1)"
                else
                    h="0000000000000000000000000000000000000000000000000000000000000000"
                fi
                { echo "verificado: $(date -u +%FT%TZ)"
                  echo "diff: $h"
                  echo "resultado: verde"; } > .agent-kit/verificacion.txt ;;
            ninguna) : ;;
        esac
        exit 0
    )
}

# decision <cwd> <comando>  → "pasa" o "bloquea"
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

# espera <esperado> <cwd> <comando> <descripción> [conocido]
espera() {
    local esperado="$1" cwd="$2" cmd="$3" desc="$4" conocido="${5:-}" real
    real="$(decision "$cwd" "$cmd")"
    [ "$real" = "$esperado" ]
    caso $? "$desc" "${conocido:+$conocido (esperado: $esperado · real: $real)}"
}

# El literal que dispara el reconocimiento se compone en tiempo de ejecución. Escrito
# entero, la propia puerta bloquea cualquier comando que abra este fichero — que es el
# tercer fallo que se arregló, y que muerde al escribir sus pruebas.
C="comm""it"

repo kit_firmado    si valida
repo kit_sin_firma  si ninguna
repo kit_firma_rota si rota
repo ajeno          no ninguna

# --- los casos ------------------------------------------------------------------------

echo "▶ el caso normal, que no puede romperse"
espera pasa    "$TMP/kit_firmado"    "git $C -m x"  "repo del kit con firma válida → pasa"
espera bloquea "$TMP/kit_sin_firma"  "git $C -m x"  "repo del kit sin firma → bloquea"
espera bloquea "$TMP/kit_firma_rota" "git $C -m x"  "repo del kit con firma de otro diff → bloquea"
espera pasa    "$TMP/kit_firmado"    'ls -la'       "un comando que no es un commit → pasa"
espera pasa    "$TMP/kit_firmado"    "git status"   "otro subcomando de git → pasa"

echo "▶ el commit va a OTRO repo"
espera bloquea "$TMP/kit_firmado" "git -C $TMP/kit_sin_firma $C -m x" \
     "-C a un repo sin firma → bloquea" \
     "no casaba el patrón de subcadena y salía por exit 0 sin comprobar nada"
espera pasa    "$TMP/kit_firmado" "git -C $TMP/kit_firmado $C -m x" \
     "-C a un repo con firma válida → pasa"
espera bloquea "$TMP/kit_firmado" "git -C $TMP/kit_firma_rota $C -m x" \
     "-C a un repo con firma de OTRO diff → bloquea" \
     "el de arriba pasaba también con la puerta rota, pero por colarse sin mirar nada"
espera bloquea "$TMP/kit_firmado" "cd $TMP/kit_sin_firma && git $C -m x" \
     "cd a un repo sin firma → bloquea" \
     "miraba el cwd, no el repo de destino, y el cwd sí tiene firma"

echo "▶ la misma cadena, agrupada o envuelta (lo que encontró el juez)"
espera bloquea "$TMP/kit_firmado" "(cd $TMP/kit_sin_firma && git $C -m x)" \
     "cd dentro de ( … ) → bloquea" \
     "el primer token del segmento era «(» y el cd no se registraba"
espera bloquea "$TMP/kit_firmado" "{ cd $TMP/kit_sin_firma && git $C -m x; }" \
     "cd dentro de { …; } → bloquea" \
     "mismo motivo que el anterior, con «{»"
espera bloquea "$TMP/kit_firmado" "pushd $TMP/kit_sin_firma && git $C -m x" \
     "pushd en vez de cd → bloquea" \
     "solo se reconocía «cd»"
espera bloquea "$TMP/kit_firmado" "bash -c 'cd $TMP/kit_sin_firma && git $C -m x'" \
     "bash -c '…' → bloquea" \
     "no se miraba dentro del -c, así que se colaba entero"
espera pasa    "$TMP/kit_firmado" "(cd $TMP/kit_firmado && git $C -m x)" \
     "cd agrupado a un repo CON firma → pasa"

echo "▶ texto que no es una invocación"
espera pasa "$TMP/kit_sin_firma" "echo 'git $C no se ejecuta aquí'" \
     "un echo que menciona las palabras → pasa" \
     "el case casaba contra la cadena entera y lo bloqueaba"
espera pasa "$TMP/kit_sin_firma" "grep -rn 'git $C' docs/" \
     "un grep que busca las palabras → pasa" \
     "mismo motivo que el anterior"
espera pasa "$TMP/kit_sin_firma" "cat > /tmp/x <<'EOF'
git $C va aquí dentro
EOF" \
     "un heredoc que las contiene → pasa" \
     "era el caso que destapó el fallo, y no estaba en el banco"

echo "▶ repos que no usan el kit"
espera pasa "$TMP/ajeno" "git $C -m x" \
     "repo sin kit.conf → pasa" \
     "bloqueaba sin salida: verifica.sh no puede firmar sin kit.conf"

echo "▶ el motivo del bloqueo dice qué repo miró"
SALIDA="$(
    cd "$TMP/kit_firmado" || exit 1
    python3 -c 'import json,sys; print(json.dumps({"tool_input":{"command":sys.argv[1]}}))' \
        "git -C $TMP/kit_sin_firma $C -m x" | bash "$PUERTA" 2>/dev/null
)"
contiene "$SALIDA" "kit_sin_firma"
caso $? "el motivo nombra el repositorio comprobado, no el heredado" \
    "el spec lo exige y no lo fijaba ninguna prueba"

resumen "la puerta" "la-puerta-mira-el-repo-del-commit"
