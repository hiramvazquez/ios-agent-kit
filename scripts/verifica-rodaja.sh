#!/usr/bin/env bash
# Banco de pruebas de `rodaja.sh`, y sobre todo de su modo `--entregado`.
# Por qué existe: `--entregado` es la ÚNICA fuente de evidencia del juez de aceptación; si se
# equivoca, el juez dictamina sobre otra cosa y su veredicto deja de significar nada.
#
# Uso:  bash scripts/verifica-rodaja.sh
#       ROD_BAJO_PRUEBA=<ruta> bash scripts/verifica-rodaja.sh   ← contra otra versión; la
#       copia va DENTRO de `scripts/`, porque rodaja.sh carga `lib-kit.sh` de su directorio.
set -uo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
. "$DIR/lib-banco.sh"

ROD="${ROD_BAJO_PRUEBA:-$DIR/rodaja.sh}"
[ -f "$ROD" ] || { echo "no encuentro rodaja.sh en $ROD"; exit 2; }

# --- montaje ------------------------------------------------------------------------------

# cambio <repo> <nombre> <linea_de_tarea>
cambio() {
    mkdir -p "$1/openspec/changes/$2"
    printf '# P\n\n## Fuera de alcance\n\n- nada\n' > "$1/openspec/changes/$2/proposal.md"
    printf '# T\n\n- [x] 1. %s\n- [ ] 2. pendiente de %s\n' "$3" "$2" \
        > "$1/openspec/changes/$2/tasks.md"
}

commitea() { ( cd "$1" && git add -A >/dev/null 2>&1 && git commit -qm "$2" >/dev/null 2>&1 ); }

# entregado <repo> [ruta-del-cambio]
entregado() { ( cd "$1" && bash "$ROD" --entregado ${2:+"$2"} 2>&1 ); }

# 1. El proposal aún no está commiteado: es el caso NORMAL cuando se juzga, porque en este
#    flujo el commit es el último paso, posterior al juicio.
repo_base sin_commitear no
cambio "$TMP/sin_commitear" cambio-uno "hecha en el arbol"
echo "linea nueva" >> "$TMP/sin_commitear/base.txt"
echo "contenido" > "$TMP/sin_commitear/NuevoSinTrackear.txt"

# 2. Trabajo commiteado DESPUÉS del proposal: tiene que entrar en el juicio.
repo_base commiteado no
cambio "$TMP/commiteado" cambio-dos "hecha y commiteada"
commitea "$TMP/commiteado" propuesta
echo "codigo del cambio" > "$TMP/commiteado/src.txt"
commitea "$TMP/commiteado" trabajo

# 3. Lo mismo, pero renombrando el directorio del cambio a mitad.
repo_base renombrado no
cambio "$TMP/renombrado" cambio-viejo "hecha antes del renombrado"
commitea "$TMP/renombrado" propuesta
echo "codigo del cambio" > "$TMP/renombrado/src.txt"
commitea "$TMP/renombrado" trabajo
( cd "$TMP/renombrado" && git mv openspec/changes/cambio-viejo openspec/changes/cambio-nuevo )
commitea "$TMP/renombrado" renombra

# 4. Dos cambios abiertos a la vez, y se juzga el segundo por orden.
repo_base dos_activos no
cambio "$TMP/dos_activos" aaa-viejo "del viejo"
cambio "$TMP/dos_activos" zzz-nuevo "del nuevo"
commitea "$TMP/dos_activos" propuestas
echo "trabajo" > "$TMP/dos_activos/b.txt"

# 6. Una marca MÁS VIEJA que el cambio: se revisó algo, después se commiteó trabajo de otro
#    cambio sin pasar por el revisor, y después empezó este. Es lo que llegó a un proyecto
#    real: la rodaja de un cambio de 12 líneas traía 1847, casi todas de antes de empezarlo.
repo_base marca_vieja no
( cd "$TMP/marca_vieja" && bash "$ROD" --revisada >/dev/null 2>&1 )
echo "de otro cambio, anterior" > "$TMP/marca_vieja/ajeno.txt"
commitea "$TMP/marca_vieja" "trabajo de otro cambio"
cambio "$TMP/marca_vieja" cambio-seis "commiteada del seis"
commitea "$TMP/marca_vieja" "propuesta aparte, antes que el codigo"
echo "commiteado del cambio" > "$TMP/marca_vieja/src.txt"
commitea "$TMP/marca_vieja" "primera tarea"
echo "sin commitear del cambio" >> "$TMP/marca_vieja/base.txt"

# 7. Una marca DENTRO del cambio: es el uso normal, y no puede cambiar. Con ficheros
#    trackeados, porque `git stash create` no guarda los que están sin trackear.
repo_base marca_dentro no
cambio "$TMP/marca_dentro" cambio-siete "del siete"
commitea "$TMP/marca_dentro" propuesta
echo "tarea uno, ya revisada" >> "$TMP/marca_dentro/base.txt"
( cd "$TMP/marca_dentro" && bash "$ROD" --revisada >/dev/null 2>&1 )
echo "tarea dos, por revisar" >> "$TMP/marca_dentro/base.txt"

# 8. La propuesta SIN commitear, una marca, y después un commit del propio cambio: el principio
#    del cambio no se conoce, y si la marca se descartara ese commit no lo vería nadie.
repo_base prop_sin_commitear no
cambio "$TMP/prop_sin_commitear" cambio-ocho "del ocho"
( cd "$TMP/prop_sin_commitear" && bash "$ROD" --revisada >/dev/null 2>&1 )
echo "commiteado tras la marca" > "$TMP/prop_sin_commitear/src.txt"
( cd "$TMP/prop_sin_commitear" && git add src.txt >/dev/null 2>&1 && git commit -qm "tarea dos" >/dev/null 2>&1 )
echo "sin commitear" >> "$TMP/prop_sin_commitear/base.txt"

# 5. Nada que juzgar: ningún cambio activo y el árbol limpio.
#
#    Ojo con lo que NO es este caso: un cambio cuyo proposal está commiteado y sin código
#    encima SÍ entrega algo —el propio acuerdo— y así tiene que verse. «Nada entregado» es
#    no tener ni eso.
repo_base nada no

# --- los casos ----------------------------------------------------------------------------

echo "▶ lo que el juez tiene que recibir"

S="$(entregado "$TMP/sin_commitear")"
contiene "$S" "LO ENTREGADO"; caso $? \
    "con el cambio sin commitear, entrega algo (no un diff vacío)"
contiene "$S" "NuevoSinTrackear.txt"; caso $? \
    "incluye los ficheros nuevos sin trackear"
# Solo la CABECERA, por lo mismo que el caso del cambio pedido: el `tasks.md` del cambio va
# sin trackear, así que el diff lo inlinea entero y las dos cadenas aparecen ahí. Mirando la
# salida completa, este caso pasaría aunque se borrara la cabecera entera.
CABECERA="$(printf '%s\n' "$S" | sed -n '1,/^LO ENTREGADO/p')"
contiene "$CABECERA" "TAREAS CERRADAS" && contiene "$CABECERA" "hecha en el arbol" \
    && contiene "$CABECERA" "TAREAS SIN CERRAR" && contiene "$CABECERA" "pendiente de cambio-uno"
caso $? "lista las tareas cerradas Y las que siguen abiertas"

S="$(entregado "$TMP/commiteado")"
contiene "$S" "codigo del cambio"; caso $? \
    "incluye lo commiteado después del proposal"

S="$(entregado "$TMP/nada")"
contiene "$S" "NADA ENTREGADO"; caso $? \
    "sin cambio activo y con el árbol limpio, lo dice en vez de callarse"

echo "▶ la rodaja del revisor"

# rodaja <repo> [args…]
rodaja() { local r="$1"; shift; ( cd "$r" && bash "$ROD" "$@" 2>&1 ); }

S="$(rodaja "$TMP/sin_commitear")"
contiene "$S" "RODAJA A REVISAR"; caso $? \
    "sin flag sigue siendo la rodaja del revisor"

echo "▶ con varios cambios activos, no elige"

S="$(rodaja "$TMP/dos_activos")"; COD=$?
if [ "$COD" -ne 0 ] && contiene "$S" "aaa-viejo" && contiene "$S" "zzz-nuevo" \
    && ! contiene "$S" "TAREAS" && ! contiene "$S" "RODAJA A REVISAR"; then
    caso 0 "con dos cambios activos y sin ruta, los nombra, pide cuál y para (cod $COD)"
else
    caso 1 "con dos cambios activos y sin ruta, los nombra, pide cuál y para (cod $COD)" \
        "elegía uno por su cuenta y avisaba: el revisor recibía las tareas de otro cambio"
fi

S="$(rodaja "$TMP/dos_activos" --revisada)"; COD=$?
if [ "$COD" -ne 0 ] && [ ! -f "$TMP/dos_activos/.agent-kit/.ultima-revision" ]; then
    caso 0 "con dos cambios activos y sin ruta, --revisada no mueve la marca"
else
    caso 1 "con dos cambios activos y sin ruta, --revisada no mueve la marca" \
        "marcaba, y guardaba como revisadas las tareas de un cambio elegido por su cuenta"
fi

S="$(rodaja "$TMP/dos_activos" openspec/changes/zzz-nuevo)"
CABECERA="$(printf '%s\n' "$S" | sed -n '1,/^RODAJA A REVISAR/p')"
contiene "$CABECERA" "del nuevo" && ! contiene "$CABECERA" "del viejo"; caso $? \
    "con dos cambios activos y la ruta de uno, las tareas son las de ese" \
    "la ruta solo valía para --entregado: la rodaja listaba las tareas de otro cambio"

echo "▶ la rodaja es del cambio que se revisa"

S="$(rodaja "$TMP/marca_vieja")"
if contiene "$S" "commiteado del cambio" && contiene "$S" "sin commitear del cambio" \
    && ! contiene "$S" "de otro cambio, anterior"; then
    caso 0 "con una marca anterior al cambio, no trae lo commiteado antes de que empezara"
else
    caso 1 "con una marca anterior al cambio, no trae lo commiteado antes de que empezara" \
        "iba desde la marca, tuviera la edad que tuviera: el revisor pagaba el trabajo de otros cambios"
fi

S="$(rodaja "$TMP/marca_dentro")"
contiene "$S" "tarea dos, por revisar" && ! contiene "$S" "+tarea uno, ya revisada"; caso $? \
    "con una marca dentro del cambio, empieza en la marca" \
    "descartaba también las marcas buenas y volvía a traer lo ya revisado"

S="$(rodaja "$TMP/prop_sin_commitear")"
contiene "$S" "commiteado tras la marca"; caso $? \
    "con la propuesta sin commitear, lo commiteado tras la marca sigue en la rodaja" \
    "sin principio conocido tomaba HEAD de suelo y descartaba la marca: ese commit no lo veía nadie"

# Las dos mitades: la propuesta commiteada aparte (`marca_vieja`) y la que sigue sin trackear
# (`sin_commitear`). Y lo entregado, que SÍ la lleva: es la evidencia del juez.
S1="$(rodaja "$TMP/marca_vieja")"
S2="$(rodaja "$TMP/sin_commitear")"
S3="$(entregado "$TMP/sin_commitear")"
! contiene "$S1" "openspec/changes/" && ! contiene "$S2" "openspec/changes/" \
    && contiene "$S3" "openspec/changes/"; caso $? \
    "la rodaja no vuelca openspec/changes/, y lo entregado sí" \
    "volcaba la planificación entera: en la prueba real era el 91 % de lo que recibió el revisor"

echo "▶ se juzga el cambio que se pide"

S="$(entregado "$TMP/dos_activos" openspec/changes/zzz-nuevo)"
# Solo la cabecera: el diff incluye la creación de los dos directorios de cambio, así que
# el nombre del otro aparece ahí legítimamente. Lo que el juez recorre es la lista.
CABECERA="$(printf '%s\n' "$S" | sed -n '1,/^LO ENTREGADO/p')"
if contiene "$CABECERA" "del nuevo" && ! contiene "$CABECERA" "del viejo"; then
    caso 0 "con dos cambios activos, juzga el que se le nombra"
else
    caso 1 "con dos cambios activos, juzga el que se le nombra" \
        "ignoraba el argumento y elegía por su cuenta: el juez leía el acuerdo de uno y las tareas del otro"
fi

S="$(entregado "$TMP/dos_activos" openspec/changes/no-existe)"
contiene "$S" "no existe el cambio"; caso $? \
    "una ruta de cambio inexistente se dice, no se ignora" \
    "no había argumento que validar: se ignoraba en silencio"

S="$(entregado "$TMP/dos_activos" openspec)"
contiene "$S" "no parece un cambio"; caso $? \
    "un directorio que no es un cambio se dice, no se juzga a medias" \
    "solo se comprobaba que el directorio existiera: apuntar a openspec/ daba una cabecera vacía"

# La cláusula está en la spec, y sin estos dos casos un mutante que quitara la condición
# dejaría el banco en verde.
S="$(entregado "$TMP/dos_activos" openspec/changes/zzz-nuevo)"
if contiene "$S" "cambios activos"; then
    caso 1 "cuando se nombra el cambio, NO avisa de los demás" \
        "avisaba igual: se está juzgando el que se ha pedido, no eligiendo entre varios"
else
    caso 0 "cuando se nombra el cambio, NO avisa de los demás"
fi

rm -f "$TMP/dos_activos/openspec/changes/zzz-nuevo/tasks.md"
S="$(entregado "$TMP/dos_activos" openspec/changes/zzz-nuevo)"
contiene "$S" "no lleva lista de tareas"; caso $? \
    "un cambio sin tasks.md se dice, no se pinta una cabecera vacía" \
    "imprimía «TAREAS CERRADAS EN ESTE CAMBIO:» sin nada debajo y seguía"

echo "▶ el punto de partida sobrevive a un renombrado"

S="$(entregado "$TMP/renombrado")"
if contiene "$S" "codigo del cambio"; then
    caso 0 "con el directorio del cambio renombrado, lo commiteado antes sigue en el juicio"
else
    caso 1 "con el directorio del cambio renombrado, lo commiteado antes sigue en el juicio" \
        "sin --follow, el git mv contaba como la adición del proposal y el trabajo anterior desaparecía sin aviso"
fi

echo "▶ fuera de un repositorio git"

# `cd "$(git rev-parse …)" || …` NO dispara fuera de un repo, porque `cd ""` devuelve 0 en
# bash: una guarda escrita así no se ejecuta nunca, y el `mkdir -p .agent-kit` que viene
# después crearía un directorio donde estuvieras. Es la misma regla que cumple el hook de
# contexto: no escribir donde nadie pidió el kit. Los dos casos van juntos a propósito: el
# mensaje sin el «no deja nada escrito» dejaría pasar una versión que avisa y ensucia igual.
PELADO="$TMP/pelado"
mkdir -p "$PELADO"
S="$( cd "$PELADO" && bash "$ROD" 2>&1 )"
COD=$?
if contiene "$S" "no es un repo git" && [ "$COD" -ne 0 ]; then
    caso 0 "fuera de un repositorio, lo dice y sale distinto de 0 (cod $COD)"
else
    caso 1 "fuera de un repositorio, lo dice y sale distinto de 0 (cod $COD)" \
        "la guarda no disparaba: seguía y volcaba el usage de git diff con codigo 0"
fi

RESTOS="$(find "$PELADO" -mindepth 1 2>/dev/null)"
if [ -z "$RESTOS" ]; then
    caso 0 "fuera de un repositorio, no deja ningun fichero ni directorio"
else
    caso 1 "fuera de un repositorio, no deja ningun fichero ni directorio" \
        "creaba .agent-kit/ donde estuvieras: $(printf '%s' "$RESTOS" | tr '\n' ' ')"
fi

resumen "rodaja.sh" "donde-la-regla-solo-llego-a-un-hermano"
