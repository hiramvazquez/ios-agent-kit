#!/usr/bin/env bash
# Qué ha cambiado desde la última revisión — la "rodaja" que toca revisar ahora.
#
# EL PROBLEMA QUE RESUELVE. Revisar al final significa revisar el cambio entero, y volver a
# revisarlo entero en cada vuelta. El coste es «tamaño de lo revisado × número de rondas», y
# al final los dos factores están al máximo. Medido en un cambio real: 700 líneas revisadas
# nueve veces entre revisor y juez, cuando los bugs vivían en tres tareas concretas.
#
# Peor que el coste es el momento: un hallazgo al final llega cuando el contexto ya se
# perdió, cuando el arreglo toca código que se escribió encima, y cuando devolver una cosa
# devuelve las siete que venían detrás.
#
# Esto no añade proceso: `tasks.md` YA trocea el trabajo. Solo hace visible dónde acaba la
# rodaja anterior, para poder revisar una tarea recién cerrada en vez del cambio entero.
#
# Uso:  rodaja.sh              qué hay sin revisar (tareas cerradas + diff)
#       rodaja.sh --revisada   marca este punto como revisado
#       rodaja.sh --reinicia   olvida la marca (vuelve a "todo sin revisar")
set -uo pipefail
cd "$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "❌ no es un repo git"; exit 1; }

ESTADO=".agent-kit"; mkdir -p "$ESTADO"
MARCA="$ESTADO/.ultima-revision"
TAREAS="$ESTADO/.ultima-revision-tareas"

# `git stash create` fabrica un objeto commit con el árbol actual SIN tocar índice ni
# working tree ni la pila de stash. Es la forma limpia de decir "guarda dónde estoy" sin
# obligar a commitear cada tarea: commitear exigiría verificar entera cada rodaja, que es
# justo el coste que esto viene a evitar.
instantanea() { git stash create 2>/dev/null | head -1; }

case "${1:-}" in
--revisada)
    S="$(instantanea)"; [ -z "$S" ] && S="$(git rev-parse HEAD)"
    echo "$S" > "$MARCA"
    ACT="$(find openspec/changes -maxdepth 1 -mindepth 1 -type d ! -name archive 2>/dev/null | head -1)"
    [ -n "$ACT" ] && cp "$ACT/tasks.md" "$TAREAS" 2>/dev/null
    echo "✅ punto marcado como revisado. La próxima rodaja empieza aquí."
    exit 0 ;;
--reinicia)
    rm -f "$MARCA" "$TAREAS"; echo "✅ marca olvidada: todo vuelve a contar como sin revisar."
    exit 0 ;;
esac

DESDE=""
[ -f "$MARCA" ] && DESDE="$(cat "$MARCA")"
if [ -n "$DESDE" ] && ! git cat-file -e "$DESDE" 2>/dev/null; then
    # El objeto de `stash create` no está anclado por ninguna referencia: un `gc` puede
    # llevárselo. Si pasa, se dice y se revisa todo, que es el lado seguro.
    echo "⚠️  la marca anterior ya no existe (git gc). Se revisa todo desde HEAD."
    DESDE=""
fi

ACT="$(find openspec/changes -maxdepth 1 -mindepth 1 -type d ! -name archive 2>/dev/null | head -1)"

if [ -n "$ACT" ] && [ -f "$TAREAS" ]; then
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
else
    D="$(git diff HEAD)"
    ORIGEN="desde HEAD (nada revisado todavía en esta rama)"
fi

# Los ficheros NUEVOS sin trackear no salen en ningún `git diff`, y en un cambio que crea
# código son justamente todo el cambio. La primera prueba sobre una feature nueva reportó
# 26 líneas cuando había cerca de setecientas: el revisor no habría visto la feature.
#
# Se añaden aparte, sin tocar el índice. Un `git add -N` los haría visibles de golpe, pero
# deja entradas intent-to-add que rompen el `git stash create` del que depende la marca.
#
# Consecuencia asumida: un fichero que siga sin trackear aparece entero en CADA rodaja
# hasta que se stagee. Se repite trabajo, no se pierde — y ese es el lado correcto en el
# que equivocarse.
NUEVOS=""
HAY_NUEVOS=0
while IFS= read -r nuevo; do
    [ -n "$nuevo" ] || continue
    TROZO="$(git diff --no-index /dev/null "$nuevo" 2>/dev/null || true)"
    [ -n "$TROZO" ] && HAY_NUEVOS=1
    NUEVOS="${NUEVOS}${TROZO}"$'\n'
done < <(git ls-files --others --exclude-standard)

# Bandera puesta en el bucle, y no un `${NUEVOS//[[:space:]]/}` al final: esa sustitución
# de patrones sobre el diff entero tarda MINUTOS en bash en cuanto pasa de unas decenas de
# KB. Colgó el script en su primer uso real con 43 KB de ficheros nuevos.
if [ "$HAY_NUEVOS" -eq 1 ]; then
    D="${D}"$'\n'"${NUEVOS}"
fi

N="$(printf '%s\n' "$D" | grep -c '^[+-][^+-]' || true)"

if [ -z "$D" ]; then
    echo "Nada nuevo que revisar $ORIGEN."
    exit 0
fi

echo "RODAJA A REVISAR ($ORIGEN): $N líneas de cambio"
if [ "$N" -gt 400 ]; then
    cat <<'GORDA'

⚠️  Esta rodaja ya es un cambio entero, no una tarea. Se puede revisar igual, pero el
   hallazgo llegará tarde y caro. Si quedan tareas por cerrar, revisa ahora lo que hay y
   marca (`rodaja.sh --revisada`) al terminar: la siguiente será pequeña.
GORDA
fi
echo
printf '%s\n' "$D"
