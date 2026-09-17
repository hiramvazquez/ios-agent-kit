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

# La huella la calcula la MISMA función que firma en producción. Escrita aparte aquí, este
# banco mediría su propia copia de la fórmula y no la del kit.
# shellcheck source=/dev/null
. "$DIR/lib-kit.sh"

PUERTA="${PUERTA_BAJO_PRUEBA:-$DIR/puerta-commit.sh}"
[ -f "$PUERTA" ] || { echo "no encuentro la puerta en $PUERTA"; exit 2; }

# --- montaje --------------------------------------------------------------------------

# repo <nombre> <kit_conf:si|no> <firma:valida|rota|ninguna>
#
# Deja algo STAGEADO: sin nada que firmar, todos los repos compartirían la misma huella.
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
                    h="$(huella_diff)"
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

# Como `espera`, pero con HOME apuntando al TMP del banco: así `~` y `$HOME` expanden a
# repositorios de prueba y no hace falta ensuciar el home de verdad. La expansión la hace la
# puerta, no este script — que es justo lo que se está probando.
espera_home() {
    local esperado="$1" cwd="$2" cmd="$3" desc="$4" conocido="${5:-}" real salida
    salida="$(
        cd "$cwd" || exit 1
        HOME="$TMP" python3 -c 'import json,sys; print(json.dumps({"tool_input":{"command":sys.argv[1]}}))' "$cmd" \
            | HOME="$TMP" bash "$PUERTA" 2>/dev/null
    )"
    case "$salida" in
        *'"permissionDecision":"deny"'*|*'"permissionDecision": "deny"'*) real=bloquea ;;
        *) real=pasa ;;
    esac
    [ "$real" = "$esperado" ]
    caso $? "$desc" "${conocido:+$conocido (esperado: $esperado · real: $real)}"
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
repo kit_editado    si valida   # se le edita el árbol DESPUÉS de firmar, más abajo
repo kit_indice     si valida   # se le envenena el ÍNDICE dejando el árbol igual que HEAD

# --- los casos ------------------------------------------------------------------------

echo "▶ el caso normal, que no puede romperse"
espera pasa    "$TMP/kit_firmado"    "git $C -m x"  "repo del kit con firma válida → pasa"
espera bloquea "$TMP/kit_sin_firma"  "git $C -m x"  "repo del kit sin firma → bloquea"
espera bloquea "$TMP/kit_firma_rota" "git $C -m x"  "repo del kit con firma de otro diff → bloquea"
espera pasa    "$TMP/kit_firmado"    'ls -la'       "un comando que no es un commit → pasa"
espera pasa    "$TMP/kit_firmado"    "git status"   "otro subcomando de git → pasa"

echo "▶ la firma cubre el árbol, no el índice"

# El agujero que cierran estos casos: con la huella del índice, verificar sin nada stageado
# firmaba el diff VACÍO y esa firma seguía valiendo después de editar. Reproducido el
# 2026-09-11 en un repositorio temporal: `-am`, `-a -m` y un pathspec pasaban los tres.
echo "editado despues de firmar" >> "$TMP/kit_editado/nuevo.txt"
espera bloquea "$TMP/kit_editado" "git $C -am x" \
     "editado el árbol sin stagear, un commit con -a → bloquea" \
     "la huella era la del índice, que no había cambiado, así que la firma seguía valiendo"
espera bloquea "$TMP/kit_editado" "git $C nuevo.txt -m x" \
     "lo mismo con un pathspec → bloquea" \
     "mismo motivo: el commit stagea él, y el índice firmado estaba sin tocar"

# Y la otra mitad, que es la que impide «arreglarlo» bloqueando todo `-a`: con el árbol
# limpio, un commit con -a no tiene nada que añadir y la firma vale.
espera pasa "$TMP/kit_firmado" "git $C -am x" \
     "con el árbol limpio, un commit con -a → pasa"

# El agujero del otro lado, y el que se coló en la PRIMERA versión de este mismo arreglo:
# firmando solo el árbol, `git diff HEAD` no ve el índice. Se stagea veneno y se devuelve el
# fichero a su contenido de HEAD: el árbol vuelve a estar como estaba, la huella no se movía, y
# `git commit` a secas commitea el índice — contenido que nunca se compiló. Lo reprodujo el
# revisor de punta a punta el 2026-09-11.
(
    cd "$TMP/kit_indice" || exit 1
    printf 'VENENO\n' > base.txt
    git add base.txt
    printf 'base\n' > base.txt     # el árbol vuelve a ser el de HEAD; el índice se queda con el veneno
) >/dev/null 2>&1
espera bloquea "$TMP/kit_indice" "git $C -m x" \
     "con el índice envenenado y el árbol igual que HEAD → bloquea" \
     "la huella solo miraba el árbol, así que no veía lo que el commit iba a llevarse"

# Y el tercero de la misma familia, que ya no es «qué mira la huella» sino «cómo lo pega»: sin
# un separador entre los dos diffs, el hunk del ÚLTIMO fichero por orden migra del árbol al
# índice sin cambiar un byte, y la huella no se mueve. Lo reprodujo el revisor.
repo_base kit_migra si
(
    cd "$TMP/kit_migra" || exit 1
    printf 'uno\n' > a.txt
    printf 'dos\n' > z.txt
    git add a.txt z.txt
    git commit -qm ficheros
    printf 'X\n' > a.txt        # el estado que se verifica: los dos ficheros tocados en el árbol
    printf 'Y\n' > z.txt
    mkdir -p .agent-kit
    { echo "verificado: $(date -u +%FT%TZ)"
      echo "diff: $(huella_diff)"
      echo "resultado: verde"; } > .agent-kit/verificacion.txt
    git add z.txt                          # el hunk de z migra al índice…
    git cat-file -p HEAD:z.txt > z.txt     # …y el árbol vuelve al contenido de HEAD
) >/dev/null 2>&1
espera bloquea "$TMP/kit_migra" "git $C -m x" \
     "un hunk que migra del árbol al índice → bloquea" \
     "los dos diffs se concatenaban sin separador, así que los bytes cuadraban igual"

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

echo "▶ la ruta escrita como la escribe cualquiera"
espera_home bloquea "$TMP/kit_firmado" "cd ~/kit_sin_firma && git $C -m x" \
     "cd ~/… a un repo sin firma → bloquea" \
     "la pista iba sin expandir a git -C, no resolvía repo y caía al fallo abierto"
espera_home bloquea "$TMP/kit_firmado" 'cd $HOME/kit_sin_firma && git '"$C"' -m x' \
     "cd \$HOME/… a un repo sin firma → bloquea" \
     "mismo motivo: la variable no se expandía"
espera_home pasa    "$TMP/kit_sin_firma" "cd ~/kit_firmado && git $C -m x" \
     "cd ~/… a un repo CON firma → pasa" \
     "expandir no puede convertirse en bloquear de más"

echo "▶ el cd y el commit en líneas distintas"
espera bloquea "$TMP/kit_firmado" "cd $TMP/kit_sin_firma
git $C -m x" \
     "cd en una línea y commit en la siguiente → bloquea" \
     "shlex se come el salto, así que cd y commit caían en el mismo segmento y el commit no se miraba"
espera pasa "$TMP/kit_sin_firma" "cd $TMP/kit_firmado
git $C -m x" \
     "lo mismo hacia un repo CON firma → pasa"

echo "▶ varios comandos en líneas distintas, que es como se escribe de verdad"
espera bloquea "$TMP/kit_firmado" "cd $TMP/kit_sin_firma
git add -A
git $C -m x" \
     "cd + add + commit en tres líneas → bloquea" \
     "el escaneo se detenía en el «add» y dejaba pasar el commit"
espera bloquea "$TMP/kit_sin_firma" "git add -A
git $C -m x" \
     "add + commit en dos líneas, sin cd → bloquea" \
     "preexistente: no se comprobaba ni el repo de la sesión, y es la forma más común"
espera bloquea "$TMP/kit_firmado" "cd $TMP/kit_sin_firma
git status
git $C -m x" \
     "cd + otro subcomando + commit → bloquea"

echo "▶ el control que descarta que el bloqueo venga del montaje"
espera_home pasa "$TMP/kit_sin_firma" "cd $TMP/kit_firmado && git $C -m x" \
     "con HOME apuntado al banco, un repo firmado por ruta absoluta → pasa" \
     "si HOME=\$TMP rompiera verifica.sh, los dos «bloquea» de arriba bloquearían por el montaje"

echo "▶ el límite que SIGUE abierto, y a propósito"
espera pasa "$TMP/kit_firmado" "D=$TMP/kit_sin_firma; cd \$D && git $C -m x" \
     "ruta construida en una variable del propio comando → pasa (fallo abierto declarado)"
espera bloquea "$TMP/kit_firmado" "cd $TMP/kit_sin_firma
echo hola
git $C -m x" \
     "un comando cualquiera entre el cd y el commit → bloquea" \
     "era un límite declarado hasta que partir por líneas lo hizo innecesario"
espera pasa "$TMP/kit_sin_firma" "cat > /tmp/nota.md <<EOF
git $C -m x va en el cuerpo
EOF" \
     "un heredoc DETRÁS de nada, con el commit en el cuerpo → pasa"
espera pasa "$TMP/kit_sin_firma" "git add -A
cat > /tmp/nota.md <<EOF
un git $C de ejemplo
EOF" \
     "un heredoc tras un git add, con el commit en el cuerpo → pasa" \
     "el salto hacia delante lo bloqueaba: rompía el caso que la enmienda protegía"
espera pasa "$TMP/kit_sin_firma" "git status
grep -rn git $C ." \
     "un grep tras un git status → pasa" \
     "mismo fallo: el salto entraba en los argumentos del grep"

resumen "la puerta" "la-puerta-mira-el-repo-del-commit"
