#!/usr/bin/env bash
# Banco de `pasada-pendiente.sh`.
#
# Su corpus no es inventado: los formatos de bloque salen de `openspec/changes/archive/`, donde
# hoy conviven cabeceras (`## Del juez, tercera ronda`, `## De la revisión de la rodaja`) e items
# numerados (`- [x] 7. **Del juez (DEVUELTO, …)**`). Un `grep` de cabeceras devolvía 0 sobre los
# segundos, en silencio — ese fue el argumento para escribir el script.
#
# Y las cuatro puertas que la prosa dejó abiertas están aquí como casos: el **cuantificador**
# —alguna ronda posterior, no solo la última, que pide un acuerdo con DOS rondas detrás de la
# pasada—, el **ancla** —qué pasa cuando NO hay ninguna pasada anotada: todas las rondas cuentan
# como posteriores—, el **campo** —la ronda sin etiqueta— y el **vocabulario del campo** —el
# valor que no se sabe leer, en sus dos formas—. Más las formas de «no se puede decidir» que la prosa contestaba como «no falta»:
# formato desconocido, cita en prosa, registro vacío y bloques repartidos entre dos ficheros.
#
# Uso:  bash scripts/verifica-pasada-pendiente.sh
#       PASADA_BAJO_PRUEBA=<ruta> bash scripts/verifica-pasada-pendiente.sh
set -uo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
. "$DIR/lib-banco.sh"

BAJO="${PASADA_BAJO_PRUEBA:-$DIR/pasada-pendiente.sh}"
[ -f "$BAJO" ] || { echo "no encuentro pasada-pendiente.sh en $BAJO"; exit 2; }

# --- montaje ------------------------------------------------------------------------------
#
# El script pide un repositorio git porque resuelve el cambio activo cuando no le dicen cuál.
repo_base fixtures no
CAMBIOS="$TMP/fixtures/openspec/changes"

# acuerdo <nombre> <contenido de tasks.md>
acuerdo() { mkdir -p "$CAMBIOS/$1"; printf '# Tareas\n\n%s\n' "$2" > "$CAMBIOS/$1/tasks.md"; }

igual() { [ "$1" = "$2" ]; }

# veredicto <cambio> → la primera palabra de la respuesta, o el código si no dice nada
veredicto() { ( cd "$TMP/fixtures" && bash "$BAJO" "openspec/changes/$1" 2>&1 | head -1 ); }
codigo()    { ( cd "$TMP/fixtures" && bash "$BAJO" "openspec/changes/$1" >/dev/null 2>&1; echo $? ); }

acuerdo movio '## Del revisor (AMBER, 2026-09-09)

- [x] 1. algo.

## Del juez (DEVUELTO, 2026-09-09) — ronda 1

- [x] 2. lo que sea.
      Comportamiento: sí.'

# LA PUERTA 1, el cuantificador, y es el camino NORMAL de la regla: DEVUELTO que mueve código,
# lo arreglas, ACEPTADO, archivas. Ningún otro fixture tiene dos bloques de juez detrás de la
# última pasada, y sin eso no se prueba que el script acumule entre rondas en vez de mirar solo
# la última — que es el primer fallo que la versión en prosa tuvo, y el que más veces se coló.
# Dos mutantes que reiniciaban los acumuladores en cada ronda pasaban el banco entero mientras
# faltó este caso — lo encontró la primera ronda de juez, el 2026-09-09.
acuerdo dos_rondas_la_ultima_limpia '## Del revisor (AMBER, 2026-09-09)

- [x] 1. lo que vio.

## Del juez (DEVUELTO, 2026-09-09) — ronda 1

- [x] 2. y el arreglo movió el comportamiento.
      Comportamiento: sí.

## Del juez (ACEPTADO, 2026-09-09) — ronda 2

- [x] 3. sin tocar nada.
      Comportamiento: no.'

# Su gemela con la ronda muda: lo que no se puede olvidar tampoco se olvida al pasar de ronda.
acuerdo dos_rondas_la_primera_muda '## Del revisor (AMBER, 2026-09-09)

- [x] 1. lo que vio.

## Del juez (DEVUELTO, 2026-09-09) — ronda 1

- [x] 2. arreglado, y sin etiqueta ninguna.

## Del juez (ACEPTADO, 2026-09-09) — ronda 2

- [x] 3. sin tocar nada.
      Comportamiento: no.'

# El espejo de `dos_rondas_la_primera_muda`: aquí la muda va DESPUÉS de una ronda con etiqueta.
# Sin esto, borrar el `visto = 0` al abrir cada ronda dejaba el banco entero en verde y el
# script contestaba 0 donde toca 3 — la etiqueta de la ronda anterior valía por la de esta.
acuerdo dos_rondas_la_ultima_muda '## Del revisor (AMBER, 2026-09-09)

- [x] 1. lo que vio.

## Del juez (DEVUELTO, 2026-09-09) — ronda 1

- [x] 2. nada que tocar.
      Comportamiento: no.

## Del juez (ACEPTADO, 2026-09-09) — ronda 2

- [x] 3. y esta se quedó sin etiqueta.'

# Ronda, pasada, ronda: lo único que fija el reinicio del revisor VARIABLE A VARIABLE. Con los
# fixtures anteriores, quitar cualquiera de los cinco reinicios de esa línea dejaba el banco en
# verde, porque el `rondas = 0` tapaba a los otros cuatro.
acuerdo ronda_pasada_ronda '## Del juez (DEVUELTO, 2026-09-09) — ronda 1

- [x] 1. esta movió el comportamiento.
      Comportamiento: sí.

## Del juez (DEVUELTO, 2026-09-09) — ronda 2

- [x] 2. y aquí se pidió y se discrepó.
      Comportamiento: no, se pidió y se discrepó.

## Del juez (DEVUELTO, 2026-09-09) — ronda 3

- [x] 3. y esta se quedó sin etiqueta ninguna.

## Del juez (DEVUELTO, 2026-09-09) — ronda 4

- [x] 4. y esta con un valor que no se sabe leer.
      Comportamiento: a medias.

## Del revisor (AMBER, 2026-09-09)

- [x] 3. y el revisor vio TODO lo anterior.

## Del juez (ACEPTADO, 2026-09-09) — ronda 5

- [x] 5. sin tocar nada.
      Comportamiento: no.'

acuerdo no_movio '## Del revisor (AMBER, 2026-09-09)

- [x] 1. algo.

## Del juez (DEVUELTO, 2026-09-09) — ronda 1

- [x] 2. prosa.
      Comportamiento: no.'

acuerdo item_numerado '- [x] 3. **De la revisión (AMBER, 2026-09-08).** algo.

- [x] 7. **Del juez (DEVUELTO, 2026-09-08).** lo que sea.
      Comportamiento: sí.'

acuerdo revisor_al_final '## Del juez (DEVUELTO, 2026-09-09) — ronda 1

- [x] 1. lo que sea.
      Comportamiento: sí.

## Del revisor (AMBER, 2026-09-09)

- [x] 2. y esto ya lo vio.'

acuerdo sin_pasada '## Del juez, segunda ronda (DEVUELTO, 2026-09-09)

- [x] 1. lo que sea.
      Comportamiento: sí.'

acuerdo muda '## Del revisor (AMBER, 2026-09-09)

- [x] 1. algo.

## Del juez de aceptación, primera ronda

- [x] 2. sin etiqueta ninguna.'

# Estas tres las pidió el revisor de este mismo cambio, y cada una mata a un mutante que los
# banco de entonces dejaba vivos:

# 1) el revisor anotado como item numerado, AL FINAL. Sin reconocerlo, el veredicto se vuelve
#    FALTA: es el único caso donde el bloque de revisor lleva la carga del resultado.
acuerdo revisor_item_final '## Del juez (DEVUELTO, 2026-09-08) — ronda 1

- [x] 1. lo que sea.
      Comportamiento: sí.

- [x] 7. **De la segunda revisión (AMBER, 2026-09-08).** y esto ya lo vio.'

# 2) la variante con ordinal en la cabecera, que el `grep` de la 1.9.4 perdía y que la primera
#    versión de este script perdía también según el idioma de la máquina.
acuerdo revisor_ordinal '## Del juez (DEVUELTO, 2026-09-09) — ronda 1

- [x] 1. lo que sea.
      Comportamiento: sí.

## De la segunda revisión (AMBER, 2026-09-09)

- [x] 2. y esto ya lo vio.'

# 3) el bloque que CITA la etiqueta sin llevarla. Es una ronda muda, y leerla como «no» es
#    exactamente la respuesta que archiva a ciegas.
acuerdo cita_en_prosa '## Del revisor (AMBER, 2026-09-09)

- [x] 1. algo.

## Del juez (DEVUELTO, 2026-09-09) — ronda 1

- [x] 2. me olvidé de ponerla.
      El juez señaló que el item 7 decía «Comportamiento: no» y era falso.'

# El fixture tiene que ser CANDIDATO y a la vez inclasificable, o no entra en la rama que dice
# cubrir: «## Del árbitro supremo» no menciona ni juez ni revisor, así que salía por «no hay
# bloques» —el mismo camino que `vacio`— y dejaba vivos dos mutantes que ignoraban la rama.
# Esta cabecera sí menciona al juez, y no la sabe clasificar: es el caso de verdad.
# Un encabezado que el script no reconoce NO puede cerrar en falso la ronda anterior.
#
# OJO, y lo midió la cuarta ronda de juez: este caso fija el `mudas++` de esa regla, no el
# `enronda = 0`. Revertir solo el `enronda = 0` deja el banco entero en verde. El fixture que lo
# cazaría está anotado como deuda en el acuerdo, para el cambio de la prueba de mutación. Aquí la
# ronda 2 es muda y la etiqueta viene debajo de un `###` que no es candidato: sin cerrar la ronda
# al encabezado, esa etiqueta se le atribuía y la muda —que vale 3— pasaba a valer 0. Un bloque
# invisible cancelaba una tercera salida ya ganada. Lo mismo pasa con `## Auditoría propia`, que
# es una sección legítima con etiquetas y existe en dos de los acuerdos archivados el
# 2026-09-09 — el comando que lo recuenta está en la cabecera de `pasada-pendiente.sh`.
acuerdo cancela_la_muda '## Del revisor (AMBER, 2026-09-09)

- [x] 1. lo que vio.

## Del juez (DEVUELTO, 2026-09-09) — ronda 2

- [x] 2. arreglado, y sin etiqueta ninguna.

### Del juez (DEVUELTO, 2026-09-09) — ronda 3

- [x] 3. y esta otra.
      Comportamiento: no.'

# Un item de tarea que cite en negrita al juez a media línea NO es un bloque. El regex anterior
# al anclaje miraba la línea entera, así que lo daba por candidato, no lo sabía clasificar y
# contestaba 3: una falsa alarma sobre una tarea normal.
# Los valores de la etiqueta van anclados a palabra: «sin cambios» empieza por s-i y se leía
# como «sí»; «nota al margen» empieza por n-o y se leía como «no». Los dos son lecturas falsas.
acuerdo valor_raro '## Del revisor (AMBER, 2026-09-09)

- [x] 1. lo que vio.

## Del juez (DEVUELTO, 2026-09-09) — ronda 1

- [x] 2. lo que sea.
      Comportamiento: sin cambios.'

# El otro valor que se leía mal: «nota al margen» empieza por n-o. El item 27 ancló los dos
# valores y montó caso solo para el de «sí»; este es el de «no», y su mutante contesta 0 donde
# toca 3, que es el lado que archiva.
acuerdo valor_raro_no '## Del revisor (AMBER, 2026-09-09)

- [x] 1. lo que vio.

## Del juez (DEVUELTO, 2026-09-09) — ronda 1

- [x] 2. lo que sea.
      Comportamiento: nota al margen.'

# «no aplica» y «no del todo — movió una pieza» empiezan por la palabra «no», y con el anclaje
# anterior —solo «no» seguido de algo que no fuese letra— se leían como «no movió»: la respuesta
# que archiva, sobre una etiqueta que nadie escribió. El valor tiene que ser la palabra entera.
# Y su gemelo por la rama «sí», que el arreglo tocó igual y nadie defendía: un mutante que
# revirtiera SOLO esa rama pasaba el banco entero. Novena vez de la clase en este cambio, y la
# escribió el arreglo de la anterior.
acuerdo valor_que_empieza_por_si '## Del revisor (AMBER, 2026-09-10)

- [x] 1. lo que vio.

## Del juez (DEVUELTO, 2026-09-10) — ronda 1

- [x] 2. lo que sea.
      Comportamiento: sí aplica, pero solo a medias.'

acuerdo valor_que_empieza_por_no '## Del revisor (AMBER, 2026-09-10)

- [x] 1. lo que vio.

## Del juez (DEVUELTO, 2026-09-10) — ronda 1

- [x] 2. lo que sea.
      Comportamiento: no del todo — movió una pieza.'

# El anclaje de `es_juez` al TÍTULO, no a la línea: una cabecera que nombre al juez sin empezar
# por él es candidata y no se sabe clasificar. Sin el anclaje se tragaba por juez.
acuerdo juez_a_media_cabecera '## Del revisor (AMBER, 2026-09-09)

- [x] 1. lo que vio.

## Ronda 2 — Del juez (DEVUELTO, 2026-09-09)

- [x] 2. lo que sea.
      Comportamiento: no.'

acuerdo cita_a_media_linea '## Del revisor (AMBER, 2026-09-09)

- [x] 1. lo que vio.

- [x] 5. **Lo que quedó abierto**, y que **Del juez** salió en la ronda 2.'

acuerdo desconocido '## Del revisor (AMBER, 2026-09-09)

- [x] 1. lo que vio.

## Segunda ronda del juez (DEVUELTO, 2026-09-09)

- [x] 2. arreglado, y movió el comportamiento.
      Comportamiento: sí.'

# Un bloque de juez que CITE al revisor en negrita en su propia línea. Se clasificaba como
# pasada, borraba las rondas acumuladas y contestaba NO FALTA sobre un acuerdo con cero pasadas.
acuerdo cita_al_revisor '- [x] 12. **Del juez, segunda ronda (DEVUELTO, 2026-09-09).** Volvió sobre lo que **De la revisión** dejó abierto.
      Comportamiento: sí.'

# Y su espejo: una tarea normal que hable del juez no es un bloque.
acuerdo tarea_que_habla_del_juez '## Del revisor (AMBER, 2026-09-09)

- [x] 1. **El juez lee lo entregado**, y esto es una tarea, no una ronda.'

acuerdo vacio '- [x] 1. una tarea normal y nada más.'

# El reparto entre los dos ficheros: `tasks.md` y `proposal.md` se leen en orden fijo, que no es
# el cronológico, así que «posterior» deja de estar definido.
acuerdo repartido '## Del juez (DEVUELTO, 2026-09-09) — ronda 1

- [x] 1. lo que sea.
      Comportamiento: sí.'
printf '## Del revisor (AMBER, 2026-09-09)\n\n- [x] 2. la pasada, anotada aquí por error.\n' \
    > "$CAMBIOS/repartido/proposal.md"

acuerdo discrepancia '## Del revisor (AMBER, 2026-09-09)

- [x] 1. algo.

## Del juez (DEVUELTO, 2026-09-09) — ronda 1

- [x] 2. no lo hice.
      Comportamiento: no, se pidió y se discrepó.'

# --- los casos ----------------------------------------------------------------------------
#
# Las aserciones de veredicto van contra un trozo que NO sea prefijo de la respuesta contraria.
# `contiene "$V" "FALTA"` se cumple también con «NO FALTA», así que cuatro casos pasaban en
# verde con la lógica que decían fijar borrada. Cuando el texto no basta para distinguir, se
# comprueba el código de salida, que no tiene esa ambigüedad.

echo "▶ lo que el registro sí puede decidir"

contiene "$(veredicto movio)" "FALTA una pasada"; caso $? \
    "una ronda posterior que movió el comportamiento: falta una pasada"
igual "$(codigo movio)" 1; caso $? "y sale con 1"

contiene "$(veredicto no_movio)" "NO FALTA"; caso $? \
    "una ronda posterior que no movió nada: no falta"
igual "$(codigo no_movio)" 0; caso $? "y sale con 0"

# La última ronda es un ACEPTADO que no arregló nada, y aun así falta una pasada: lo que cuenta
# es ALGUNA ronda posterior, no la última. Para archivar en regla la última es siempre un
# ACEPTADO, así que un script que mirase solo esa no dispararía nunca.
contiene "$(veredicto dos_rondas_la_ultima_limpia)" "FALTA una pasada"; caso $? \
    "con dos rondas detrás de la pasada, cuenta ALGUNA, no la última" \
    "miró solo la última —un ACEPTADO— y dio el cambio por revisado"
contiene "$(veredicto dos_rondas_la_primera_muda)" "NO SE PUEDE LEER"; caso $? \
    "y una ronda muda no se olvida porque venga otra detrás" \
    "la ronda sin etiqueta se perdió al pasar de ronda"
contiene "$(veredicto dos_rondas_la_ultima_muda)" "NO SE PUEDE LEER"; caso $? \
    "ni una ronda muda hereda la etiqueta de la ronda anterior" \
    "la etiqueta de la ronda 1 valió por la 2, que no tenía: 0 donde tocaba 3"
igual "$(codigo dos_rondas_la_ultima_muda)" 3; caso $? "   y sale con 3"

# El reinicio del revisor son cinco variables en una línea, y hasta aquí ningún caso las fijaba
# por separado: quitar cuatro de las cinco dejaba el banco en verde porque `rondas = 0` tapaba
# el resto. Este acuerdo lleva las cuatro clases delante de la pasada y una ronda limpia detrás.
contiene "$(veredicto ronda_pasada_ronda)" "NO FALTA"; caso $? \
    "la pasada borra TODO lo anterior: las cuatro clases de ronda, una por una" \
    "algo de antes de la pasada sobrevivió y contaminó el veredicto"
igual "$(codigo ronda_pasada_ronda)" 0; caso $? "   y sale con 0"

contiene "$(veredicto revisor_al_final)" "NO FALTA"; caso $? \
    "la ronda es ANTERIOR a la última pasada: el revisor ya la vio"

contiene "$(veredicto sin_pasada)" "FALTA una pasada"; caso $? \
    "sin ninguna pasada, todas las rondas cuentan como posteriores"

contiene "$(veredicto discrepancia)" "FALTA — hay un desacuerdo"; caso $? \
    "un desacuerdo abierto tampoco es una ronda limpia"

echo "▶ el formato de item numerado, que un grep de cabeceras no ve"

# El caso que motivó el script: dos acuerdos archivados reales anotan así, y el `grep` que había
# devolvía 0 sobre ellos — en silencio y hacia el lado que archiva.
contiene "$(veredicto item_numerado)" "FALTA una pasada"; caso $? \
    "los bloques anotados como item numerado se leen igual que las cabeceras"

echo "▶ las formas de bloque de revisor que llevan la carga del veredicto"

# Sin estos dos, un mutante que ignore al revisor en item numerado o con ordinal pasa los
# banco de entonces: en todos sus casos el resultado lo decidía el bloque del juez.
contiene "$(veredicto revisor_item_final)" "NO FALTA"; caso $? \
    "un revisor en item numerado al final cierra la ronda anterior"
contiene "$(veredicto revisor_ordinal)" "NO FALTA"; caso $? \
    "y «De la segunda revisión», con el ordinal en medio, también"

# El veredicto no puede depender del idioma de la máquina. Correr el script dos veces con dos
# `LC_ALL` NO lo comprueba: fija su propio locale dentro, así que las dos corridas recorren el
# mismo camino y el caso pasaría igual con el defecto puesto. Lo que sí lo comprueba es quitarle
# el pin a una copia y correr ESA en los dos idiomas: lo que queda a prueba es el clasificador,
# que es donde vivía el defecto —`revisi[oó]n` casaba o no según el locale, y el mismo fichero
# daba dos veredictos—. Con el clasificador limpio, la copia sin pin contesta lo mismo en ambos.
# La copia tiene que poder correr: `pasada-pendiente.sh` hace `source` de `lib-kit.sh` desde su
# propio directorio, así que sin copiarla al lado las dos corridas fallan con el MISMO error y
# `igual` se cumple siempre. Así estaba entregado este caso, y no cazaba nada: lo encontró la
# tercera ronda de juez, en el mismo caso que se había declarado «no tautológico».
SINPIN="$TMP/sin-pin.sh"
sed 's/LC_ALL=C awk/awk/' "$BAJO" > "$SINPIN"
cp "$DIR/lib-kit.sh" "$TMP/"
A="$(cd "$TMP/fixtures" && LC_ALL=C           bash "$SINPIN" openspec/changes/revisor_ordinal 2>&1 | head -1)"
B="$(cd "$TMP/fixtures" && LC_ALL=en_US.UTF-8 bash "$SINPIN" openspec/changes/revisor_ordinal 2>&1 | head -1)"
# Y antes de comparar, que lo comparado sea un veredicto y no un error: si la copia no arranca
# —porque `lib-kit.sh` se mueva, por ejemplo— las dos corridas devuelven el MISMO error y este
# caso vuelve a ser la tautología que fue. Sin esta línea, el arreglo no se protege a sí mismo.
contiene "$A" "FALTA"; caso $? "la copia sin pin arranca y devuelve un veredicto" \
    "devolvió «$A», que no es un veredicto: la comparación de abajo sería cierta para cualquier código"
igual "$A" "$B"; caso $? "el clasificador contesta igual en los dos idiomas, sin el pin puesto" \
    "con LC_ALL=C dijo «$A» y con UTF-8 «$B»: hay una clase de caracteres que se lee por bytes"


contiene "$(veredicto cita_al_revisor)" "FALTA una pasada"; caso $? \
    "un bloque de juez que cita al revisor en negrita sigue siendo del juez"
contiene "$(veredicto tarea_que_habla_del_juez)" "NO FALTA"; caso $? \
    "y una tarea que habla del juez no es un bloque"
contiene "$(veredicto cita_a_media_linea)" "NO FALTA"; caso $? \
    "ni una que lo cite en negrita a media línea"
contiene "$(veredicto valor_raro)" "NO SE PUEDE LEER"; caso $? \
    "«Comportamiento: sin cambios» no es «sí»: es un valor que no sé leer" \
    "se leyó como «sí» por empezar por s-i, y disparó FALTA sobre una etiqueta que nadie escribió"
contiene "$(veredicto valor_raro_no)" "NO SE PUEDE LEER"; caso $? \
    "ni «nota al margen» es «no»" \
    "se leyó como «no» por empezar por n-o: 0 donde tocaba 3, el lado que archiva"
contiene "$(veredicto valor_que_empieza_por_no)" "NO SE PUEDE LEER"; caso $? \
    "ni «no del todo — movió una pieza», que dice justo lo contrario" \
    "la etiqueta decía que movió y se leyó como que no: 0 donde tocaba 3"
igual "$(codigo valor_que_empieza_por_no)" 3; caso $? "   y sale con 3"
contiene "$(veredicto valor_que_empieza_por_si)" "NO SE PUEDE LEER"; caso $? \
    "y por la rama «sí» igual: «sí aplica, pero solo a medias» tampoco es «sí»" \
    "se leyó como «sí» por empezar por s-í: una lectura falsa de una etiqueta que nadie escribió"
contiene "$(veredicto juez_a_media_cabecera)" "NO SE PUEDE LEER"; caso $? \
    "una cabecera que nombra al juez sin empezar por él no se clasifica sola" \
    "se tragó por juez una cabecera que solo lo menciona"
contiene "$(veredicto cancela_la_muda)" "NO SE PUEDE LEER"; caso $? \
    "un encabezado no reconocido no deja muda una ronda sin contarla" \
    "la ronda muda se leyó como «no» — un bloque invisible canceló una tercera salida ganada"

echo "▶ las puertas que pedían la tercera salida: cuando no se puede leer, se dice"

for c in muda cita_en_prosa desconocido vacio repartido; do
    case "$c" in
      muda)          d="una ronda SIN etiqueta de comportamiento" ;;
      cita_en_prosa) d="una ronda que CITA la etiqueta sin llevarla" ;;
      desconocido)   d="un bloque en un formato que no reconoce" ;;
      vacio)         d="un acuerdo sin ningún bloque" ;;
      repartido)     d="bloques repartidos entre tasks.md y proposal.md" ;;
    esac
    V="$(veredicto $c)"
    if contiene "$V" "NO SE PUEDE LEER"; then
        caso 0 "$d → no se puede leer"
    else
        caso 1 "$d → no se puede leer" \
            "dijo «$(printf '%s' "$V" | cut -c1-40)» — un binario contesta «no falta», que es la respuesta que archiva a ciegas"
    fi
    igual "$(codigo $c)" 3; caso $? "   y sale con 3, el código de «no pude mirar»"
done

# Y que cada puerta salga por SU rama, no por la de al lado. Sin esto, el caso del formato
# desconocido pasaba en verde saliendo por «no hay ningún bloque», y un mutante que ignorase el
# bloque irreconocible —o que lo diera por «no falta»— pasaba el banco entero.
contiene "$(veredicto desconocido)" "no sé clasificar"; caso $? \
    "el formato desconocido sale por su rama, y dice cuál es el bloque" \
    "salió por otra: «$(veredicto desconocido)»"
contiene "$(veredicto vacio)" "no registra ninguna pasada"; caso $? \
    "y el registro vacío por la suya"

resumen "pasada-pendiente.sh" "la-pasada-pendiente-se-cuenta"
