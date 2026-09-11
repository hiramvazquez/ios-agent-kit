#!/usr/bin/env bash
# Banco de `variables-pegadas.sh`.
#
# Sus casos van contra lo único que hace que el detector sirva — pegada-de-ejemplo: `$A»` frente
# a `${A}»`, y la marca de esta línea es lo que evita que el detector se denuncie a sí mismo. Un
# detector que marcara las dos formas sería inútil, porque el mensaje correcto lleva el mismo
# carácter — la diferencia son exactamente las llaves.
#
# Y montan los SEIS caracteres con los que se midió el fallo, no uno: `»` fue el que apareció en
# el repositorio, pero el defecto es de cualquier carácter multibyte y un banco con un solo
# carácter dejaría creer que es cosa del guillemet.
#
# Las aserciones van contra trozos que NO son subcadena de su contraria. La primera versión de
# este banco comparaba contra «pegado a un carácter no-ASCII», que está EN LOS DOS mensajes: los
# doce casos pasaban en verde con el detector roto —no encontraba nada, porque usaba `grep -P` y
# el `grep` de macOS no lo tiene—. Lo destapó el único caso que miraba el código de salida.
#
# Uso:  bash scripts/verifica-variables-pegadas.sh
#       PEGADAS_BAJO_PRUEBA=<ruta> bash scripts/verifica-variables-pegadas.sh
set -uo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
. "${DIR}/lib-banco.sh"

DETECTOR="${PEGADAS_BAJO_PRUEBA:-${DIR}/variables-pegadas.py}"
[ -f "${DETECTOR}" ] || { echo "no encuentro variables-pegadas.py en ${DETECTOR}"; exit 2; }

# `igual` local, como los demás bancos: en el kit hay cuatro copias idénticas y consolidarlas en
# `lib-banco.sh` es otro cambio —el de los mutantes— que todavía no está publicado.
igual()  { [ "$1" = "$2" ]; }
mira()   { python3 "${DETECTOR}" "$1" 2>&1; }
codigo() { python3 "${DETECTOR}" "$1" >/dev/null 2>&1; echo $?; }

pon() { mkdir -p "${TMP}/$1"; printf '%s\n' "$2" > "${TMP}/$1/s.sh"; }

# --- los casos ------------------------------------------------------------------------------

echo "▶ el fallo, con los seis caracteres con los que se midió"

# Uno por carácter. Si solo se montara `»` —el que apareció en el repositorio— el banco dejaría
# creer que el defecto es del guillemet, y es de cualquier byte alto pegado a la variable.
for ch in '»' '—' '·' '…' 'á' '€'; do
    pon "roto_${ch}" "A=ok; echo \"«\$A${ch}\""
    igual "$(codigo "${TMP}/roto_${ch}")" 1; caso $? \
        "marca \$A pegado a «${ch}»" \
        "lo dejó pasar: con LANG UTF-8 ese script aborta con «unbound variable»"
done
contiene "$(mira "${TMP}/roto_»")" '❌ hay'; caso $? "   y dice cuál y dónde"

echo "▶ y la forma correcta, que es de lo que depende que sirva de algo"

# El caso que de verdad distingue. Sin él, un detector que marcase las dos formas pasaría todos
# los de arriba y sería inútil: el mensaje bueno lleva el mismo carácter.
for ch in '»' '—' '·' '…' 'á' '€'; do
    pon "bien_${ch}" "A=ok; echo \"«\${A}${ch}\""
    igual "$(codigo "${TMP}/bien_${ch}")" 0; caso $? \
        "NO marca \${A} pegado a «${ch}»" \
        "marcó la forma correcta: un detector que marca las dos no distingue nada"
done
contiene "$(mira "${TMP}/bien_»")" '✅ sin variables pegadas'; caso $? "   y lo dice"

echo "▶ lo que no tiene que confundir"

# Una variable seguida de un carácter ASCII no tiene el problema, y marcarla sería ruido.
pon ascii 'A=ok; echo "[$A]"; echo "$A, y $A."'
igual "$(codigo "${TMP}/ascii")" 0; caso $? \
    "no marca una variable seguida de ASCII" \
    "marcó de más: el fallo es del carácter multibyte, no de la variable"

# Un carácter multibyte que NO va detrás de una variable tampoco es el fallo.
pon suelto 'echo "« esto es prosa » y ya"'
igual "$(codigo "${TMP}/suelto")" 0; caso $? \
    "ni un carácter multibyte suelto"

echo "▶ la marca de ejemplo, y sus dos límites"

# Los sitios que documentan el fallo tienen que poder ENSEÑARLO. Sin la marca, el detector se
# denuncia a sí mismo: su propia cabecera lleva el ejemplo.
# El carácter va en una variable, como en el bucle de arriba: así el fuente de este banco no
# contiene literalmente la forma rota y no se denuncia a sí mismo. Es más limpio que marcar cada
# línea, y deja la marca para lo que de verdad la necesita — la prosa que explica el fallo.
G='»'
pon marcada "A=ok; echo \"«\$A${G}\"   # pegada-de-ejemplo"
igual "$(codigo "${TMP}/marcada")" 0; caso $? \
    "una línea marcada no se cuenta" \
    "el detector no puede documentarse sin denunciarse"

# Y va por LÍNEA, no por fichero: marcar un ejemplo no puede cegar el resto del script.
pon marcada_y_rota "A=ok; echo \"«\$A${G}\"   # pegada-de-ejemplo
B=ok; echo \"«\$B${G}\""
igual "$(codigo "${TMP}/marcada_y_rota")" 1; caso $? \
    "pero la marca es por línea: la de al lado sigue contando" \
    "una marca cegó el fichero entero, que es como un opt-out se vuelve una alfombra"

# Límite: solo fuente. Un `.pyc` lleva bytes altos por todas partes y nadie lo escribe a mano.
mkdir -p "${TMP}/solo_fuente"
printf '%s\n' "A=ok; echo \"«\$A${G}\"" > "${TMP}/solo_fuente/no-es-fuente.txt"
igual "$(codigo "${TMP}/solo_fuente")" 0; caso $? \
    "no mira ficheros que no son .sh ni .py" \
    "miró algo que nadie escribe a mano: eso es ruido, no un hallazgo"

echo "▶ cuando no puede mirar, lo dice"

igual "$(codigo "${TMP}/no-existe-este-directorio")" 3; caso $? \
    "un directorio que no existe sale con 3, no con 0" \
    "«no pude mirar» no es «no hay ninguna»"

echo "▶ y el repositorio de verdad, que es para lo que se escribió"

# El detector sobre el propio kit. Si esto se pone rojo es que alguien escribió una nueva, que es
# exactamente para lo que existe.
igual "$(codigo "${DIR}")" 0; caso $? \
    "los scripts del kit no tienen ninguna" \
    "hay una nueva: ponle llaves antes de commitear"

resumen "variables-pegadas.py" "el-kit-no-depende-del-idioma"
