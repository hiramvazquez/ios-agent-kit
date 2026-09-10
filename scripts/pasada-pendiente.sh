#!/usr/bin/env bash
# ¿Falta una pasada de revisor antes de archivar este cambio?
#
# POR QUÉ EXISTE, y por qué es un script y no otro párrafo. La regla que responde esta pregunta
# —«no se archiva sobre el arreglo de un juicio que no ha visto ningún revisor»— llevaba CUATRO
# rondas sin decidir en cuenta del revisor que la cerró —el cambio archivado
# `2026-09-09-no-se-archiva-a-ciegas`—, y las cuatro fueron el mismo fallo a distinta
# profundidad: le faltaba el
# cuantificador, luego el ancla, luego el campo, luego el vocabulario del campo. El revisor que
# las cerró lo dijo así:
#
#     «Las cuatro puertas son casos en los que la respuesta correcta era NO SE PUEDE LEER,
#      pregunta, y el texto contestó NO FALTA.»
#
# Por eso la tercera salida no es robustez: es el producto. Un sí/no obliga a elegir un lado
# cuando la respuesta honesta es que no se sabe, y el lado que elige por defecto es el que
# archiva.
#
# La regla de la casa dice que un detector solo nace si su clase falló dos veces Y no hay forma
# más barata de verlo. Falló en esas cuatro, y la forma barata se midió fallando: un `grep` de
# cabeceras
# puesto para no fiarse de la memoria devuelve 0 sobre acuerdos que SÍ tienen rondas —anotadas
# como item numerado— y pierde variantes como «De la segunda revisión». En silencio y hacia el
# lado que archiva.
#
# Uso:  pasada-pendiente.sh <ruta-del-cambio>
#       pasada-pendiente.sh                    ← el cambio activo
#
# Salidas, con la forma que `verifica.sh` ya tiene decidida para «no pude mirar»:
#   0  NO FALTA          ninguna ronda posterior a la última pasada movió el comportamiento
#   1  FALTA             alguna sí, y ese arreglo no lo ha visto ningún revisor
#   3  NO SE PUEDE LEER  el registro que sé leer no permite decidir — pregunta, no archives a
#                        ciegas. Lo que no sé leer está en el LÍMITE de aquí abajo: eso no lo
#                        aviso, y por eso el límite se declara en vez de prometerse.
#
# LÍMITE, y es el que más incomoda. Un bloque es candidato por su FORMA —cabecera `## …` o item
# `- [x] N. **…**`— y por su VOCABULARIO —que el título nombre al juez, al revisor o a una
# revisión—. Lo que falle cualquiera de las dos es invisible: ni cuenta como ronda ni dispara la
# tercera salida, así que detrás de una pasada reconocida el script contesta 0 sobre una ronda
# que sí existía. `### Del juez …` falla por forma; `## Del árbitro supremo` falla por
# vocabulario, y esa mitad es fácil de pasar por alto porque su forma es la buena. Y hay una
# tercera parte, de contexto: esto lee líneas, no markdown, así que una cabecera escrita dentro
# de una valla de código como EJEMPLO del formato cuenta igual que una de verdad. No pasa en
# ningún acuerdo del repositorio; se declara y no se detecta.
#
# Y no se cierra tratando todo encabezado con etiqueta como una ronda ilegible, que es lo obvio:
# `## Auditoría propia` lleva etiquetas y NO es una ronda: dos de los acuerdos archivados tienen
# una así, medido el 2026-09-09. El recuento se repite, no se recuerda — y tiene que mirar DENTRO
# de la sección, no solo si el título sale en el fichero, que da seis y no dos:
#   awk '/^## Auditoría propia/{d=1;next} /^## /{d=0} d && /Comportamiento:/{print FILENAME}' \
#       openspec/changes/archive/*/tasks.md | sort -u
#
# El vocabulario es la única señal que
# hay de que algo pretendía ser una ronda. Se cierra el día que aparezca una escrita así, con su
# caso; el día que esto se escribió no había ninguna que medir.
#
# NO BLOQUEA NADA. Informa; decide quien archiva. Es un script que se invoca, como
# `rodaja.sh --revisada`, no un cuarto hook: `hooks/hooks.json` declara que un cuarto tiene que
# traer escrito el fallo que lo motiva, y este no lo trae.
set -uo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
. "$DIR/lib-kit.sh"

RAIZ="$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "❌ no es un repo git"; exit 3; }
cd "$RAIZ" || exit 3

CAMBIO="${1:-}"
if [ -z "$CAMBIO" ]; then
    cambio_activo
    CAMBIO="$ACTIVO"
    [ -n "$CAMBIO" ] || { echo "NO SE PUEDE LEER — no hay cambio activo y no me has dicho cuál"; exit 3; }
    [ "$ACTIVOS_N" -gt 1 ] && echo "⚠️  hay $ACTIVOS_N cambios activos; miro «${CAMBIO##*/}»."
fi
CAMBIO="${CAMBIO%/}"
[ -d "$CAMBIO" ] || { echo "NO SE PUEDE LEER — no existe «$CAMBIO»"; exit 3; }

# El registro vive en `tasks.md`, o al final del `proposal.md` cuando el cambio no lleva lista.
# Se leen los dos: un cambio puede tener lista y haber anotado en el proposal por error, y
# leer solo uno lo daría por vacío — que es «no falta», la respuesta prohibida.
FUENTES=()
for f in "$CAMBIO/tasks.md" "$CAMBIO/proposal.md"; do [ -f "$f" ] && FUENTES+=("$f"); done
[ ${#FUENTES[@]} -gt 0 ] || { echo "NO SE PUEDE LEER — «$CAMBIO» no tiene ni tasks.md ni proposal.md"; exit 3; }

# Nada de aquí dentro lleva una clase de caracteres con acento, y esa es la corrección: el awk
# de macOS trata los corchetes por bytes, así que `[oó]` no casa contra «revisión» según el
# idioma de la máquina, y el mismo fichero daba dos veredictos. Las alternativas —`(ón|on)`—
# son secuencias literales y casan igual en cualquier locale.
#
# `LC_ALL=C` va fijado además, como `lib-kit.sh` fija el suyo para ordenar, pero es red y no
# suelo: quitarlo hoy no cambia ningún veredicto, así que **ningún caso del banco lo fija**.
# Está para que una clase con acento que entre mañana falle igual en las dos máquinas.
RESULTADO="$(LC_ALL=C awk '
    # Un bloque candidato es una cabecera `## …` o un item `- [x] N. **…**` que hable del
    # revisor o del juez. Si es candidato y no lo sé clasificar, la respuesta es NO SE PUEDE
    # LEER — nunca «no falta». Ese es el punto entero de este script.
    # Quién firma el bloque se decide por su TÍTULO —lo que va justo detrás del `## ` o del
    # `- [x] N. **`—, no por lo que la línea mencione más adelante. Sin este anclaje, un bloque
    # de juez que cite en negrita al revisor («volvió sobre lo que **De la revisión** dejó
    # abierto») se clasificaba como pasada de revisor, borraba las rondas acumuladas y contestaba
    # NO FALTA sobre un acuerdo sin ninguna pasada. Era la respuesta prohibida, en silencio.
    function titulo(l,   t) {
        if (l ~ /^## /)                      { t = l; sub(/^## */, "", t); return t }
        if (l ~ /^- \[[ x]\] [0-9]+\. \*\*/) { t = l; sub(/^- \[[ x]\] [0-9]+\. \*+/, "", t); return t }
        return ""
    }
    function candidato(l) {
        # En la cabecera basta que se mencione: `## Segunda ronda del juez` no la sé clasificar,
        # y quiero que caiga en DESCONOCIDO en vez de pasar de largo.
        if (l ~ /^## /)                      return (l ~ /[Jj]uez|[Rr]evisor|[Rr]evisi(ón|on)/)
        # En el item la mención tiene que abrir el título: una tarea que cite al juez en negrita
        # a media línea —«**Lo que quedó abierto**, y que **Del juez** salió en la ronda 2»— se
        # daba por candidata y no se sabía clasificar, o sea falsa alarma sobre una tarea normal.
        # El ordinal va en medio: «**De la segunda revisión**» es una pasada real del archivo que
        # la primera versión de esta línea no veía.
        if (l ~ /^- \[[ x]\] [0-9]+\. \*\*/) return (titulo(l) ~ /^(Del|De la) +([^ ]+ +)?(juez|revisor|revisi(ón|on))/)
        return 0
    }
    function es_juez(l)   { return (titulo(l) ~ /^Del juez/) }
    function es_revisor(l){ return (titulo(l) ~ /^(Del revisor|De la +([^ ]+ +)?revisi(ón|on))/) }

    candidato($0) { vistos[FILENAME] = 1 }

    candidato($0) {
        # Una pasada de revisor BORRA lo acumulado: lo que ella vio ya está revisado, y la
        # pregunta es siempre «¿qué ha pasado DESPUÉS de la última?». Sin este reinicio, una
        # ronda vieja seguiría contando para siempre y el script diría FALTA sobre un cambio
        # que sí pasó por el revisor al final — que es como salió en su primera corrida.
        if (es_revisor($0))   { hubo = 1; enronda = 0
                                rondas = 0; movio = 0; discrepa = 0; mudas = 0; raras = 0; next }
        if (es_juez($0))      { hubo = 1; if (enronda && !visto) mudas++
                                rondas++; enronda = 1; visto = 0; next }
        print "DESCONOCIDO:" $0; salir = 1; exit
    }
    # CUALQUIER encabezado cierra la ronda abierta, lo sepa clasificar o no. Sin esto, un
    # encabezado que el script no reconoce —`### Del juez, tercera ronda`, o una sección legítima
    # como `## Auditoría propia`, que existe en dos de los acuerdos archivados el 2026-09-09
    # —el comando que lo recuenta está en la cabecera— y lleva etiquetas sin ser
    # una ronda— deja la ronda anterior abierta, y su etiqueta se le atribuye a ella. Medido: eso
    # convertía una ronda muda —que vale 3— en una ronda con etiqueta «no», que vale 0. Un bloque
    # invisible no solo no contaba: CANCELABA una tercera salida ya ganada.
    /^#+ / && !candidato($0) {
        if (enronda && !visto) mudas++
        enronda = 0
    }

    # La etiqueta vive dentro del bloque, en cualquiera de sus líneas, pero AL PRINCIPIO de la
    # suya: si no se ancla, un bloque que la cite de pasada —«el item 7 decía Comportamiento:
    # no»— convierte una ronda muda en un «no», que es la respuesta que archiva. En el archivo
    # de 2026-09-09 todas las etiquetas de verdad empiezan su línea y las citas en prosa no;
    # el reparto exacto se recuenta, no se recuerda:
    #   grep -rho '.\{0,24\}Comportamiento:' openspec/changes/archive/ | sort | uniq -c
    enronda && /^[[:space:]]*\**Comportamiento:/ {
        visto = 1
        # El valor tiene que ser la palabra ENTERA y nada más. Con solo `[^a-zA-Z]` detrás, «no
        # aplica» y «no del todo — movió una pieza» se leían como «no movió», que es la respuesta
        # que archiva; y «sin cambios» se leía como «sí». Detrás del valor solo caben el final de
        # línea o un signo: así se escriben todas las del archivo —`sí.`, `no.`, `no — …`,
        # `sí — …`— y cualquier otra cosa cae en `raras`, o sea en la tercera salida, que es lo
        # que es. Las formas se recuentan, no se recuerdan:
        #   grep -rh '^[[:space:]]*\**Comportamiento:' openspec/changes/archive/ | sort | uniq -c
        #
        # El guion largo va como alternativa y NO dentro de un corchete: una clase con un carácter
        # multibyte se lee por bytes y el veredicto pasaría a depender del idioma de la máquina,
        # que es el defecto que este script ya tuvo una vez.
        if ($0 ~ /Comportamiento: *s(í|i) *([.,;]|—|-|$)/)           { movio = 1 }
        else if ($0 ~ /Comportamiento: *no, se pidi(ó|o)/)           { discrepa = 1 }
        else if ($0 ~ /Comportamiento: *no *([.,;]|—|-|$)/)          { }
        else                                                        { raras++ }
    }
    END {
        if (salir) exit
        # `tasks.md` y `proposal.md` se leen en ese orden fijo, que NO es el cronológico: si hay
        # bloques en los dos, «posterior» deja de estar definido y la respuesta honesta es que
        # no se puede leer, no la que sale de concatenar.
        for (f in vistos) nficheros++
        if (nficheros > 1) { print "REPARTIDO"; exit }
        if (enronda && !visto) mudas++
        printf "hubo=%d rondas=%d movio=%d discrepa=%d mudas=%d raras=%d\n", hubo, rondas, movio, discrepa, mudas, raras
    }
' "${FUENTES[@]}")"

case "$RESULTADO" in
  REPARTIDO)
    echo "NO SE PUEDE LEER — «${CAMBIO##*/}» tiene bloques en tasks.md Y en proposal.md."
    echo "   «Posterior» se decide por el orden en el fichero, y entre dos ficheros no hay orden."
    echo "   Júntalos en uno y vuelve a preguntar."
    exit 3 ;;
  DESCONOCIDO:*)
    echo "NO SE PUEDE LEER — hay un bloque que no sé clasificar:"
    echo "   ${RESULTADO#DESCONOCIDO:}"
    echo "   Léelo tú y decide. No lo doy por «no falta»: esa es la respuesta que archiva a ciegas."
    exit 3 ;;
esac

eval "$(printf '%s\n' "$RESULTADO" | tr ' ' '\n' | grep '=')"

# Dos cosas distintas que es fácil confundir, y confundirlas fue el primer fallo de este
# script en su propia corrida: «no hay ningún bloque» es no poder leer; «no hay ninguna ronda
# DESPUÉS de la última pasada» es que el revisor ya lo vio todo, que es NO FALTA.
if [ "${hubo:-0}" -eq 0 ]; then
    echo "NO SE PUEDE LEER — «${CAMBIO##*/}» no registra ninguna pasada ni ninguna ronda."
    echo "   Si las hubo y no se anotaron, el registro no puede decirte nada: pregunta."
    exit 3
fi
if [ "${rondas:-0}" -eq 0 ]; then
    echo "NO FALTA — no hay ninguna ronda de juez posterior a la última pasada de revisor."
    exit 0
fi
if [ "${mudas:-0}" -gt 0 ] || [ "${raras:-0}" -gt 0 ]; then
    echo "NO SE PUEDE LEER — hay ronda(s) sin la etiqueta de comportamiento, o con un valor que"
    echo "   no reconozco. La etiqueta llegó con la 1.9.2 y los acuerdos anteriores no la tienen."
    echo "   Una ronda muda no dice «no»: míralo tú."
    exit 3
fi
if [ "${movio:-0}" -gt 0 ]; then
    echo "FALTA una pasada de revisor: alguna ronda posterior a la última movió el comportamiento."
    echo "   Pásalo por /kit-revisa antes de archivar."
    exit 1
fi
if [ "${discrepa:-0}" -gt 0 ]; then
    echo "FALTA — hay un desacuerdo abierto anotado (el juez pidió mover comportamiento y no se hizo)."
    echo "   Eso no es una ronda limpia: resuélvelo antes de archivar."
    exit 1
fi
echo "NO FALTA — ninguna ronda posterior a la última pasada movió el comportamiento."
exit 0
