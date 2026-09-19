#!/usr/bin/env bash
# Qué ha cambiado desde la última revisión — la "rodaja" que toca revisar ahora.
#
# Revisar al final significa revisar el cambio entero, y volver a revisarlo entero en cada
# vuelta: el coste es «tamaño de lo revisado × número de rondas». `tasks.md` YA trocea el
# trabajo; esto solo hace visible dónde acaba la rodaja anterior.
#
# Uso:  rodaja.sh [<ruta-del-cambio>]              qué hay sin revisar de ese cambio
#       rodaja.sh --revisada [<ruta-del-cambio>]   marca este punto como revisado
#       rodaja.sh --reinicia                       olvida la marca ("todo sin revisar")
#       rodaja.sh --entregado [<ruta-del-cambio>]
#                              TODO lo que ese cambio ha entregado, ignorando la marca
#
# Sin ruta se usa el único cambio activo. Con varios activos y sin ruta NO se elige: se
# nombran y se pide cuál, porque las tareas y el principio del cambio son de uno concreto.
#
# La rodaja es del cambio que se revisa: no empieza antes de su principio —una marca más
# vieja que eso no se usa— y no vuelca `openspec/changes/`, que es planificación: las tareas
# cerradas ya van en su lista y el acuerdo se lee del disco.
#
# LÍMITE DECLARADO: lo commiteado antes de que el cambio empezara no es de esta rodaja, lo
# haya revisado alguien o no. Y un commit ajeno hecho a mitad del cambio sí entra: nada dice
# de quién es cada línea. El principio solo se conoce con la propuesta ya commiteada: sin
# eso, o sin ningún cambio activo, la rodaja va desde la marca, tenga la edad que tenga.
#
# `--entregado` es para el juez de aceptación: juzga el cambio entero contra el acuerdo, así
# que la marca no le sirve, y no puede usar `git diff main...HEAD`, que está VACÍO cuando se
# le invoca porque el commit es posterior al juicio. Su salida sí incluye `openspec/changes/`.
set -uo pipefail

# `$DIR` antes del `cd`: después, una invocación relativa desde un subdirectorio ya no
# encontraría la lib.
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
. "$DIR/lib-kit.sh"

# Se comprueba la RESOLUCIÓN, no el `cd`: `cd ""` devuelve 0 en bash, y este script seguiría
# hasta `mkdir -p .agent-kit` en el directorio donde estuvieras.
RAIZ="$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "❌ no es un repo git"; exit 1; }
cd "$RAIZ" || exit 1

ESTADO=".agent-kit"; mkdir -p "$ESTADO"
MARCA="$ESTADO/.ultima-revision"
TAREAS="$ESTADO/.ultima-revision-tareas"

# `git stash create` fabrica un objeto commit con el árbol actual SIN tocar índice ni
# working tree ni la pila de stash: "guarda dónde estoy" sin obligar a commitear cada tarea.
instantanea() { git stash create 2>/dev/null | head -1; }

MODO="rodaja"

CAMBIO_PEDIDO=""

case "${1:-}" in
--entregado) MODO="entregado"; CAMBIO_PEDIDO="${2:-}" ;;
--revisada)  MODO="revisada";  CAMBIO_PEDIDO="${2:-}" ;;
--reinicia)
    rm -f "$MARCA" "$TAREAS"; echo "✅ marca olvidada: todo vuelve a contar como sin revisar."
    exit 0 ;;
*) CAMBIO_PEDIDO="${1:-}" ;;
esac

# De QUÉ cambio se habla: el que dice quien invoca, o el único activo. Se resuelve antes de
# imprimir nada y antes de tocar la marca.
cambio_activo; ACT="$ACTIVO"
if [ -n "$CAMBIO_PEDIDO" ]; then
    CAMBIO_PEDIDO="${CAMBIO_PEDIDO%/}"
    [ -d "$CAMBIO_PEDIDO" ] || { echo "❌ no existe el cambio «${CAMBIO_PEDIDO}»"; exit 1; }
    # Y que sea un cambio, no un directorio cualquiera.
    [ -f "$CAMBIO_PEDIDO/proposal.md" ] || {
        echo "❌ «${CAMBIO_PEDIDO}» no parece un cambio: no tiene proposal.md"; exit 1; }
    ACT="$CAMBIO_PEDIDO"
elif [ "$ACTIVOS_N" -gt 1 ]; then
    echo "❌ hay $ACTIVOS_N cambios activos y nadie ha dicho cuál. Repite la orden con su ruta:"
    printf '%s' "$ACTIVOS" | sed 's/^/     /'
    exit 1
fi

if [ "$MODO" = revisada ]; then
    S="$(instantanea)"; [ -z "$S" ] && S="$(git rev-parse HEAD)"
    echo "$S" > "$MARCA"
    [ -n "$ACT" ] && cp "$ACT/tasks.md" "$TAREAS" 2>/dev/null
    echo "✅ punto marcado como revisado. La próxima rodaja empieza aquí."
    exit 0
fi

# El principio del cambio es el commit ANTERIOR al que introdujo su `proposal.md`. Si el
# proposal todavía no está commiteado —el caso normal cuando se juzga— el cambio entero vive
# en el árbol de trabajo y el principio es HEAD: `SUELO` se queda vacío. Única definición: la
# usan lo entregado y la rodaja.
SUELO=""
if [ -n "$ACT" ]; then
    # `--follow`: sin él, un `git mv` del directorio del cambio cuenta como la ADICIÓN del
    # proposal, y todo lo commiteado antes de renombrar desaparece.
    INTRO="$(git log --follow --diff-filter=A --format=%H -- "$ACT/proposal.md" 2>/dev/null | tail -1)"
    [ -n "$INTRO" ] && SUELO="$(git rev-parse --verify --quiet "${INTRO}^" || echo "$INTRO")"
fi

DESDE=""
MARCA_VIEJA=0
if [ "$MODO" = entregado ]; then
    DESDE="$SUELO"
else
    [ -f "$MARCA" ] && DESDE="$(cat "$MARCA")"
    if [ -n "$DESDE" ] && ! git cat-file -e "$DESDE" 2>/dev/null; then
        # El objeto de `stash create` no está anclado por ninguna referencia: un `gc` puede
        # llevárselo. Si pasa, se dice y se revisa todo, que es el lado seguro.
        echo "⚠️  la marca anterior ya no existe (git gc). Se revisa todo desde HEAD."
        DESDE=""
    fi
    # La marca solo vale si es del cambio o posterior: si su principio NO es ancestro de la
    # marca, la marca es de antes —o de otra rama— y lo que hay en medio no es de esta rodaja.
    # Sin principio conocido —la propuesta aún sin commitear— la marca se respeta: descartarla
    # dejaría fuera lo commiteado desde entonces, y eso no lo volvería a ver nadie.
    if [ -n "$DESDE" ] && [ -n "$SUELO" ] \
        && ! git merge-base --is-ancestor "$SUELO" "$DESDE" 2>/dev/null; then
        DESDE="$SUELO"
        MARCA_VIEJA=1
    fi
fi

if [ "$MODO" = entregado ] && [ -n "$ACT" ]; then
    # El juez recorre la lista, no el diff: el diff enseña lo que se hizo y solo la lista
    # enseña lo que falta. Por eso aquí van las dos, y las pendientes se nombran.
    if [ ! -f "$ACT/tasks.md" ]; then
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
elif [ -n "$ACT" ] && [ -f "$TAREAS" ] && [ "$MARCA_VIEJA" -eq 0 ]; then
    NUEVAS="$(diff <(grep '^- \[x\]' "$TAREAS" 2>/dev/null) <(grep '^- \[x\]' "$ACT/tasks.md" 2>/dev/null) \
              | grep '^>' | sed 's/^> /   /')"
    if [ -n "$NUEVAS" ]; then
        echo "TAREAS CERRADAS DESDE LA ÚLTIMA REVISIÓN:"
        printf '%s\n' "$NUEVAS"
        echo
    fi
elif [ -n "$ACT" ]; then
    echo "TAREAS DEL CAMBIO (primera revisión: ninguna marca de este cambio):"
    grep '^- \[x\]' "$ACT/tasks.md" 2>/dev/null | sed 's/^/   /'
    echo
fi

# diferencia <desde> — la rodaja no vuelca `openspec/changes/`; lo entregado, sí: el juez
# compara contra el acuerdo y su salida no se toca.
diferencia() {
    if [ "$MODO" = entregado ]; then git diff "$1"
    else git diff "$1" -- . ':(exclude)openspec/changes'; fi
}

if [ -n "$DESDE" ]; then
    D="$(diferencia "$DESDE")"
    ORIGEN="desde la última revisión"
    [ "$MARCA_VIEJA" -eq 1 ] && ORIGEN="desde el principio de este cambio: la marca era anterior a él"
    [ "$MODO" = entregado ] && ORIGEN="el cambio entero, desde antes de su propuesta"
else
    D="$(diferencia HEAD)"
    ORIGEN="desde HEAD (nada revisado todavía en esta rama)"
    [ "$MODO" = entregado ] && ORIGEN="el cambio entero, todavía sin commitear"
fi

# Los ficheros NUEVOS sin trackear no salen en ningún `git diff`, y en un cambio que crea
# código son justamente todo el cambio. Se añaden aparte, sin tocar el índice: un
# `git add -N` deja entradas intent-to-add que rompen el `git stash create` de la marca.
#
# Consecuencia asumida: un fichero que siga sin trackear aparece entero en CADA rodaja
# hasta que se stagee. Se repite trabajo, no se pierde.
NUEVOS=""
HAY_NUEVOS=0
OMITIDOS=""
while IFS= read -r nuevo; do
    [ -n "$nuevo" ] || continue
    # `.claude/` es estado de herramientas, nunca código del proyecto, y no está en el
    # .gitignore de todos los proyectos: se excluye aquí.
    case "$nuevo" in .claude/*|*/.claude/*) continue ;; esac
    # La planificación tampoco entra en la rodaja (ver `diferencia`).
    if [ "$MODO" != entregado ]; then
        case "$nuevo" in openspec/changes/*) continue ;; esac
    fi

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
        # Que el juez lo vea escrito y pare: un veredicto sobre una entrada vacía no es falso,
        # es incomprobable.
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
