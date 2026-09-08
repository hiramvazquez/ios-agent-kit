#!/usr/bin/env bash
# Banco de pruebas de `rodaja.sh`, y sobre todo de su modo `--entregado`.
#
# Por qué existe: `--entregado` es la ÚNICA fuente de evidencia del juez de aceptación. Si
# se equivoca, el juez dictamina sobre otra cosa y su veredicto deja de significar nada —
# que es el fallo que el modo se escribió para cerrar. Nació sin banco, y el revisor de la
# rodaja encontró dos defectos en él que un banco de cuatro casos habría cazado solo:
#
#   - con dos cambios abiertos juzgaba el primero por orden alfabético, aunque le dijeran
#     cuál juzgar: el juez leía el acuerdo de uno y la lista de tareas del otro;
#   - sin `--follow`, un `git mv` del directorio del cambio hacía desaparecer del juicio
#     todo lo commiteado antes del renombrado, sin decir nada.
#
# Uso:  bash scripts/verifica-rodaja.sh
#       ROD_BAJO_PRUEBA=<ruta> bash scripts/verifica-rodaja.sh   ← contra otra versión
#
# La copia bajo prueba tiene que quedar DENTRO de `scripts/`, como la de la puerta: rodaja.sh
# carga `lib-kit.sh` de su propio directorio, así que una copia en `/tmp` se queda sin
# `cambio_activo` y falla entera por una razón que no es la que se está midiendo. Costó una
# corrida entender eso.
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
# salida completa, este caso pasaba aunque se borrara la cabecera entera — lo cazó el revisor
# probando justo ese mutante.
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

echo "▶ el modo rodaja no se toca"

S="$( cd "$TMP/sin_commitear" && bash "$ROD" 2>&1 )"
contiene "$S" "RODAJA A REVISAR"; caso $? \
    "sin flag sigue siendo la rodaja del revisor"

echo "▶ se juzga el cambio que se pide"

S="$(entregado "$TMP/dos_activos" openspec/changes/zzz-nuevo)"
# Solo la cabecera: el diff incluye la creación de los dos directorios de cambio, así que
# el nombre del otro aparece ahí legítimamente. Lo que el juez recorre es la lista.
CABECERA="$(printf '%s\n' "$S" | sed -n '1,/^LO ENTREGADO/p')"
if contiene "$CABECERA" "del nuevo" && ! contiene "$CABECERA" "del viejo"; then
    caso 0 "con dos cambios activos, juzga el que se le nombra"
else
    caso 1 "con dos cambios activos, juzga el que se le nombra" \
        "ignoraba el argumento y cogía el primero por orden: el juez leía el acuerdo de uno y las tareas del otro"
fi

S="$(entregado "$TMP/dos_activos" openspec/changes/no-existe)"
contiene "$S" "no existe el cambio"; caso $? \
    "una ruta de cambio inexistente se dice, no se ignora" \
    "no había argumento que validar: se ignoraba en silencio"

S="$(entregado "$TMP/dos_activos" openspec)"
contiene "$S" "no parece un cambio"; caso $? \
    "un directorio que no es un cambio se dice, no se juzga a medias" \
    "solo se comprobaba que el directorio existiera: apuntar a openspec/ daba una cabecera vacía"

# Estos dos los pidió la tercera revisión: la cláusula estaba en el delta de spec y ningún
# caso la miraba, así que un mutante que quitara la condición dejaba el banco en verde.
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

resumen "rodaja.sh" "el-kit-se-aplica-a-si-mismo"
