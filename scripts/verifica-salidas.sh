#!/usr/bin/env bash
# Banco de pruebas de `verifica.sh`: sus códigos de salida y su firma.
#
# Por qué existe, y por qué tan tarde: es la pieza central del kit —la que decide si hay
# firma y por tanto si la puerta deja commitear— y era la única cuyo contrato cambió en este
# cambio sin que ninguna prueba lo fijara. El juez de aceptación lo señaló: se abrieron tres
# bancos para cerrar ese agujero en otras piezas y se dejó abierto justo aquí.
#
# Los dos casos que importan tienen historia:
#   - «tres pasos en rojo no es 3»: el script salía con el NÚMERO de fallos, así que tres
#     pasos rojos eran indistinguibles de «no hay kit.conf», mientras la doc pública prometía
#     que se distinguían.
#   - «--comprueba tras una verificación en rojo»: el marker se quedaba con su línea `diff:`
#     y la puerta respondía «firma válida» sobre un árbol que había fallado. Ese ya lo cazó
#     un juez en su día; aquí queda fijado para que no vuelva.
#
# Uso:  bash scripts/verifica-salidas.sh
#       VERIFICA_BAJO_PRUEBA=<ruta> bash scripts/verifica-salidas.sh   ← contra otra versión
#
# La copia bajo prueba va DENTRO de `scripts/`: `verifica.sh` busca a `busca-duplicados.py`
# como vecino suyo.
set -uo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
. "$DIR/lib-banco.sh"

VER="${VERIFICA_BAJO_PRUEBA:-$DIR/verifica.sh}"
[ -f "$VER" ] || { echo "no encuentro verifica.sh en $VER"; exit 2; }

mkdir -p "$TMP/home"

# HOME al temporal a propósito: si no, `verifica.sh` sale a mirar los marketplaces instalados
# de la máquina —y hasta a hacer un `git fetch`— para avisar de versiones desfasadas. Eso no
# es lo que se está midiendo, y mete red en un banco.
# Un `[ … ]` suelto seguido de `caso $?` hace que shellcheck avise con razón (SC2319: ese
# `$?` viene de una condición, no de un comando). Con una función el aviso desaparece y la
# línea se lee mejor.
igual() { [ "$1" = "$2" ]; }

codigo() { ( cd "$1" || exit 9; shift; HOME="$TMP/home" bash "$VER" "$@" >/dev/null 2>&1; echo $? ); }
salida() { ( cd "$1" || exit 9; shift; HOME="$TMP/home" bash "$VER" "$@" 2>&1 ); }

# conf <repo> <pasos_en_rojo>
conf() {
    local r="$TMP/$1" n="$2" i
    {
        echo 'FUENTES="."'
        echo 'verificaciones() {'
        echo '    paso "uno bueno" true'
        # Nada de `seq 1 $n`: el `seq` de BSD cuenta HACIA ATRÁS cuando el primero es
        # mayor que el último, así que `seq 1 0` imprime «1 0» y el repo «verde» nacía con
        # dos pasos rojos dentro. Lo cazó este mismo banco en su primera corrida.
        i=0
        while [ "$i" -lt "$n" ]; do i=$((i+1)); echo "    paso \"malo $i\" false"; done
        echo '}'
    } > "$r/kit.conf"
}

repo_base verde   no ; conf verde 0
repo_base un_rojo no ; conf un_rojo 1
repo_base tres_rojos no ; conf tres_rojos 3
repo_base sin_conf no
repo_base sin_funcion no ; echo 'FUENTES="."' > "$TMP/sin_funcion/kit.conf"

echo "▶ «no pude mirar» no se confunde con «está mal»"

C="$(codigo "$TMP/sin_conf")"
igual "$C" 3; caso $? "sin kit.conf sale 3 — «no pude mirar» ($C)"

C="$(codigo "$TMP/sin_funcion")"
igual "$C" 3; caso $? "un kit.conf sin verificaciones() sale 3 ($C)"

C="$(codigo "$TMP/tres_rojos")"
if igual "$C" 1; then
    caso 0 "TRES pasos en rojo salen 1, no 3 ($C)"
else
    caso 1 "TRES pasos en rojo salen 1, no 3 ($C)" \
        "salía con el número de fallos, así que tres rojos eran indistinguibles de «no hay kit.conf»"
fi

C="$(codigo "$TMP/un_rojo")"
igual "$C" 1; caso $? "un paso en rojo sale 1 ($C)"

C="$(codigo "$TMP/verde")"
igual "$C" 0; caso $? "todo en verde sale 0 ($C)"

echo "▶ el recuento no se pierde: se mueve al informe y a la firma"

S="$(salida "$TMP/tres_rojos")"
contiene "$S" "3 paso(s) en rojo"; caso $? "el informe dice cuántos pasos fallaron"
contiene "$(cat "$TMP/tres_rojos/.agent-kit/verificacion.txt")" "resultado: rojo (3 paso(s))"
caso $? "la firma también lo dice"

contiene "$(cat "$TMP/verde/.agent-kit/verificacion.txt")" "resultado: verde"
caso $? "en verde, la firma lo dice"

echo "▶ la firma solo vale para este diff y para un verde"

C="$(codigo "$TMP/verde" --comprueba)"
igual "$C" 0; caso $? "tras un verde, --comprueba acepta ($C)"

C="$(codigo "$TMP/tres_rojos" --comprueba)"
igual "$C" 1; caso $? "tras un rojo, --comprueba rechaza ($C)" \
    "el marker conservaba su línea diff: y esto respondía «firma válida» sobre un árbol roto"

echo nuevo > "$TMP/verde/otro.txt"
( cd "$TMP/verde" && git add otro.txt >/dev/null 2>&1 )
C="$(codigo "$TMP/verde" --comprueba)"
igual "$C" 1; caso $? "si el diff staged cambia, la firma deja de valer ($C)"

C="$(codigo "$TMP/sin_conf" --comprueba)"
igual "$C" 1; caso $? "sin nada verificado, --comprueba rechaza ($C)"

resumen "verifica.sh" "el-kit-se-aplica-a-si-mismo"
