#!/usr/bin/env bash
# Qué ha cambiado desde la última revisión — la "rodaja" que toca revisar ahora.
#
# EL PROBLEMA QUE RESUELVE. Revisar al final significa revisar el cambio entero, y volver a
# revisarlo entero en cada vuelta: el coste es «tamaño de lo revisado × número de rondas», y así
# los dos factores están al máximo. Y peor que el coste es el momento — un hallazgo al final
# llega cuando el contexto ya se perdió y cuando devolver una cosa devuelve las que venían
# detrás.
#
# Esto no añade proceso: `tasks.md` YA trocea el trabajo. Solo hace visible dónde acaba la
# rodaja anterior, para poder revisar una tarea recién cerrada en vez del cambio entero.
#
# Uso:  rodaja.sh              qué hay sin revisar (tareas cerradas + diff)
#       rodaja.sh --revisada   marca este punto como revisado
#       rodaja.sh --reinicia   olvida la marca (vuelve a "todo sin revisar")
#       rodaja.sh --entregado [<ruta-del-cambio>]
#                              TODO lo que ese cambio ha entregado, ignorando la marca
#
# `--entregado` es para el juez de aceptación, no para el revisor: el revisor juzga rodajas y el
# juez el cambio entero contra el acuerdo, así que la marca no le sirve. Y no puede usar
# `git diff main...HEAD`, que está VACÍO cuando se le invoca —el commit es posterior al juicio—:
# un juez con Read y Grep dictaminaría igual sin enterarse de que su fuente estaba vacía.
set -uo pipefail

# `$DIR` antes del `cd`, por lo mismo que en el hook: después, una invocación relativa desde
# un subdirectorio ya no encontraría la lib.
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
. "$DIR/lib-kit.sh"

# Se comprueba la RESOLUCIÓN, no el `cd`: `cd "$(git rev-parse …)" || …` no dispara fuera de un
# repositorio, porque `cd ""` devuelve 0 en bash, y este script seguiría hasta `mkdir -p
# .agent-kit` en el directorio donde estuvieras. La asignación sí propaga el código de git.
RAIZ="$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "❌ no es un repo git"; exit 1; }
cd "$RAIZ" || exit 1

ESTADO=".agent-kit"; mkdir -p "$ESTADO"
MARCA="$ESTADO/.ultima-revision"
TAREAS="$ESTADO/.ultima-revision-tareas"

# `git stash create` fabrica un objeto commit con el árbol actual SIN tocar índice ni
# working tree ni la pila de stash. Es la forma limpia de decir "guarda dónde estoy" sin
# obligar a commitear cada tarea: commitear exigiría verificar entera cada rodaja, que es
# justo el coste que esto viene a evitar.
instantanea() { git stash create 2>/dev/null | head -1; }

MODO="rodaja"

CAMBIO_PEDIDO=""

case "${1:-}" in
--entregado) MODO="entregado"; CAMBIO_PEDIDO="${2:-}" ;;
--revisada)
    S="$(instantanea)"; [ -z "$S" ] && S="$(git rev-parse HEAD)"
    echo "$S" > "$MARCA"
    cambio_activo; ACT="$ACTIVO"
    [ -n "$ACT" ] && cp "$ACT/tasks.md" "$TAREAS" 2>/dev/null
    echo "✅ punto marcado como revisado. La próxima rodaja empieza aquí."
    exit 0 ;;
--reinicia)
    rm -f "$MARCA" "$TAREAS"; echo "✅ marca olvidada: todo vuelve a contar como sin revisar."
    exit 0 ;;
esac

DESDE=""
[ "$MODO" = rodaja ] && [ -f "$MARCA" ] && DESDE="$(cat "$MARCA")"
if [ -n "$DESDE" ] && ! git cat-file -e "$DESDE" 2>/dev/null; then
    # El objeto de `stash create` no está anclado por ninguna referencia: un `gc` puede
    # llevárselo. Si pasa, se dice y se revisa todo, que es el lado seguro.
    echo "⚠️  la marca anterior ya no existe (git gc). Se revisa todo desde HEAD."
    DESDE=""
fi

cambio_activo; ACT="$ACTIVO"
[ "$ACTIVOS_N" -gt 1 ] && [ -z "$CAMBIO_PEDIDO" ] && \
    echo "⚠️  hay $ACTIVOS_N cambios activos; se mira «${ACT##*/}», el primero por orden."

# El principio del cambio es el commit ANTERIOR al que introdujo su `proposal.md`. Si el
# proposal todavía no está commiteado —el caso normal cuando se juzga, porque el commit es
# el último paso del flujo— el cambio entero vive en el árbol de trabajo y el punto de
# partida es HEAD.
if [ "$MODO" = entregado ]; then
    # Si quien juzga dice QUÉ cambio juzga, manda él. Sin esto, con dos cambios abiertos el
    # juez leía el `proposal.md` de uno y la lista de tareas del otro, bajo un encabezado que
    # dice «EN ESTE CAMBIO»: el aviso de que había dos estaba, pero nada le decía que la
    # lista no era la suya, justo cuando su prompt le acaba de ordenar recorrer la lista y no
    # el diff. Lo encontró el revisor de esta misma rodaja.
    if [ -n "$CAMBIO_PEDIDO" ]; then
        CAMBIO_PEDIDO="${CAMBIO_PEDIDO%/}"
        [ -d "$CAMBIO_PEDIDO" ] || { echo "❌ no existe el cambio «${CAMBIO_PEDIDO}»"; exit 1; }
        # Y que sea un cambio, no un directorio cualquiera: apuntar a `openspec` a secas
        # imprimía una cabecera de tareas vacía sin decir nada.
        [ -f "$CAMBIO_PEDIDO/proposal.md" ] || {
            echo "❌ «${CAMBIO_PEDIDO}» no parece un cambio: no tiene proposal.md"; exit 1; }
        ACT="$CAMBIO_PEDIDO"
    fi

    DESDE=""
    if [ -n "$ACT" ]; then
        # `--follow`: sin él, un `git mv` del directorio del cambio cuenta como la ADICIÓN del
        # proposal, y todo lo commiteado antes de renombrar desaparece del juicio en silencio.
        INTRO="$(git log --follow --diff-filter=A --format=%H -- "$ACT/proposal.md" 2>/dev/null | tail -1)"
        [ -n "$INTRO" ] && DESDE="$(git rev-parse --verify --quiet "${INTRO}^" || echo "$INTRO")"
    fi
fi

if [ "$MODO" = entregado ] && [ -n "$ACT" ]; then
    # El juez recorre la lista, no el diff: el diff enseña lo que se hizo y solo la lista
    # enseña lo que falta. Por eso aquí van las dos, y las pendientes se nombran.
    if [ ! -f "$ACT/tasks.md" ]; then
        # Decirlo. Un encabezado de tareas vacío es el mismo síntoma silencioso que la
        # validación del argumento vino a cerrar, entrando por la otra puerta.
        echo "SIN tasks.md en ${ACT##*/}: este cambio no lleva lista de tareas."
    else
        echo "TAREAS CERRADAS EN ESTE CAMBIO:"
        grep '^- \[x\]' "$ACT/tasks.md" 2>/dev/null | sed 's/^/   /'
        SIN_CERRAR="$(grep '^- \[ \]' "$ACT/tasks.md" 2>/dev/null)"
        if [ -n "$SIN_CERRAR" ]; then
            echo
            echo "TAREAS SIN CERRAR — míralas antes de dictaminar:"
            printf '%s\n' "$SIN_CERRAR" | sed 's/^/   /'
        fi
    fi
    echo
elif [ -n "$ACT" ] && [ -f "$TAREAS" ]; then
    NUEVAS="$(diff <(grep '^- \[x\]' "$TAREAS" 2>/dev/null) <(grep '^- \[x\]' "$ACT/tasks.md" 2>/dev/null) \
              | grep '^>' | sed 's/^> /   /')"
    if [ -n "$NUEVAS" ]; then
        echo "TAREAS CERRADAS DESDE LA ÚLTIMA REVISIÓN:"
        printf '%s\n' "$NUEVAS"
        echo
    fi
elif [ -n "$ACT" ]; then
    echo "TAREAS DEL CAMBIO (primera revisión, ninguna marca previa):"
    grep '^- \[x\]' "$ACT/tasks.md" 2>/dev/null | sed 's/^/   /'
    echo
fi

if [ -n "$DESDE" ]; then
    D="$(git diff "$DESDE")"
    ORIGEN="desde la última revisión"
    [ "$MODO" = entregado ] && ORIGEN="el cambio entero, desde antes de su propuesta"
else
    D="$(git diff HEAD)"
    ORIGEN="desde HEAD (nada revisado todavía en esta rama)"
    [ "$MODO" = entregado ] && ORIGEN="el cambio entero, todavía sin commitear"
fi

# Los ficheros NUEVOS sin trackear no salen en ningún `git diff`, y en un cambio que crea código
# son justamente todo el cambio: una feature de setecientas líneas se reportaba como 26.
#
# Se añaden aparte, sin tocar el índice. Un `git add -N` los haría visibles de golpe, pero deja
# entradas intent-to-add que rompen el `git stash create` del que depende la marca.
#
# Consecuencia asumida: un fichero que siga sin trackear aparece entero en CADA rodaja
# hasta que se stagee. Se repite trabajo, no se pierde — y ese es el lado correcto en el
# que equivocarse.
NUEVOS=""
HAY_NUEVOS=0
OMITIDOS=""
while IFS= read -r nuevo; do
    [ -n "$nuevo" ] || continue
    # `.claude/` es estado de herramientas, nunca código del proyecto: un `worktrees/` ahí
    # dentro metió 26.000 líneas de OTRO repositorio en una rodaja de 900. No está en el
    # .gitignore de todos los proyectos, así que se excluye aquí en vez de confiar en que lo esté.
    case "$nuevo" in .claude/*|*/.claude/*) continue ;; esac

    LINEAS="$(wc -l < "$nuevo" 2>/dev/null || echo 0)"
    if [ "$LINEAS" -gt 1500 ]; then
        # Un fichero enorme sin trackear no se inlinea: se nombra. Volcarlo entero empuja
        # fuera de la ventana justamente lo que hay que mirar.
        OMITIDOS="${OMITIDOS}   $nuevo ($LINEAS líneas — léelo directamente)"$'\n'
        HAY_NUEVOS=1
        continue
    fi

    TROZO="$(git diff --no-index /dev/null "$nuevo" 2>/dev/null || true)"
    [ -n "$TROZO" ] && HAY_NUEVOS=1
    NUEVOS="${NUEVOS}${TROZO}"$'\n'
done < <(git ls-files --others --exclude-standard)

if [ -n "$OMITIDOS" ]; then
    NUEVOS="${NUEVOS}"$'\n'"FICHEROS NUEVOS DEMASIADO GRANDES PARA VOLCARLOS AQUÍ:"$'\n'"${OMITIDOS}"
fi

# Bandera puesta en el bucle, y no un `${NUEVOS//[[:space:]]/}` al final: esa sustitución de
# patrones sobre el diff entero tarda MINUTOS en bash en cuanto pasa de unas decenas de KB.
if [ "$HAY_NUEVOS" -eq 1 ]; then
    D="${D}"$'\n'"${NUEVOS}"
fi

N="$(printf '%s\n' "$D" | grep -c '^[+-][^+-]' || true)"

if [ -z "$D" ]; then
    if [ "$MODO" = entregado ]; then
        # Que el juez lo vea escrito y pare. Un veredicto emitido sobre una entrada vacía no
        # es necesariamente falso: es incomprobable, que es peor.
        echo "NADA ENTREGADO: no hay ni una línea de cambio ($ORIGEN)."
        echo "No hay nada que juzgar. Dilo y para."
    else
        echo "Nada nuevo que revisar $ORIGEN."
    fi
    exit 0
fi

if [ "$MODO" = entregado ]; then
    echo "LO ENTREGADO POR ESTE CAMBIO ($ORIGEN): $N líneas"
else
    echo "RODAJA A REVISAR ($ORIGEN): $N líneas de cambio"
fi
if [ "$MODO" = rodaja ] && [ "$N" -gt 400 ]; then
    cat <<'GORDA'

⚠️  Esta rodaja ya es un cambio entero, no una tarea. Se puede revisar igual, pero el
   hallazgo llegará tarde y caro. Si quedan tareas por cerrar, revisa ahora lo que hay y
   marca (`rodaja.sh --revisada`) al terminar: la siguiente será pequeña.
GORDA
fi
echo
printf '%s\n' "$D"
