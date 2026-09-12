#!/usr/bin/env bash
# Banco de pruebas de `inyecta-contexto.sh`.
#
# Por qué existe: ese hook corre en CADA turno y nadie lo invoca, así que cuando se
# equivoca no hay quien lo corrija — solo un digest que afirma cosas sobre el trabajo en
# curso. El 2026-09-07 estuvo una sesión entera diciendo «Sin cambio OpenSpec activo»
# mientras el repositorio donde se trabajaba tenía uno con siete tareas hechas, y además
# dejó un `.agent-kit/` en un repositorio que no usa el kit.
#
# Uso:  bash scripts/verifica-contexto.sh
#
# Se puede apuntar a otra versión con HOOK_BAJO_PRUEBA, para comprobar caso por caso que
# cada prueba que fija un fallo sale roja contra la versión sin arreglar:
#
#   git show <commit>:scripts/inyecta-contexto.sh > scripts/.contexto-viejo.sh
#   HOOK_BAJO_PRUEBA="$PWD/scripts/.contexto-viejo.sh" bash scripts/verifica-contexto.sh
set -uo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
. "$DIR/lib-banco.sh"

HOOK="${HOOK_BAJO_PRUEBA:-$DIR/inyecta-contexto.sh}"
[ -f "$HOOK" ] || { echo "no encuentro el hook en $HOOK"; exit 2; }

# --- montaje ----------------------------------------------------------------------------

# repo <nombre> <openspec:sin|vacio|activo> <kit_conf:si|no> [nombre_dependencia]
repo() {
    local nombre="$1" ospec="$2" conf="$3" dep="${4:-}"
    repo_base "$nombre" "$conf" || return 1
    (
        cd "$TMP/$nombre" || exit 1
        case "$ospec" in
            vacio)  mkdir -p openspec/changes/archive ;;
            activo)
                mkdir -p openspec/changes/mi-cambio
                printf '# Tareas\n\n- [x] 1. hecha\n- [ ] 2. pendiente\n' \
                    > openspec/changes/mi-cambio/tasks.md
                printf '# P\n\n## Fuera de alcance\n\n- no tocar la caja fuerte\n\n## Otra\n' \
                    > openspec/changes/mi-cambio/proposal.md ;;
            activo_cero)
                # La rama que ningún fixture montaba: un cambio activo con CERO tareas
                # pendientes, que es el estado normal cuando el cambio está terminado y se
                # va a llamar al juez. `grep -c` sobre cero coincidencias imprime "0" Y sale
                # con 1; el `$(... || echo 0)` de antes de este cambio no lo sabía y sumaba
                # un segundo "0", lo que en bash 3.2 abortaba el `if` entero y se perdían
                # "tareas:", la lista de pendientes y "FUERA de alcance" en silencio. Este
                # fixture existe para que ese caso deje de pasar por accidente.
                #
                # Y su cabecera va en MAYÚSCULAS a propósito: 3 de las 16 propuestas de este
                # repositorio la escriben así —la activa el 2026-09-11 entre ellas— y el `sed`
                # de antes distinguía mayúsculas, así que el bloque desaparecía sin decir nada.
                # El fixture de `activo` la deja en minúsculas: entre los dos cubren las dos.
                mkdir -p openspec/changes/mi-cambio
                printf '# Tareas\n\n- [x] 1. hecha\n- [x] 2. tambien hecha\n' \
                    > openspec/changes/mi-cambio/tasks.md
                printf '# P\n\n## FUERA de alcance\n\n- no tocar la caja fuerte\n\n## Otra\n' \
                    > openspec/changes/mi-cambio/proposal.md ;;
            dos)
                # CINCO cambios abiertos a la vez, creados en orden inverso al
                # alfabético. OpenSpec permite varios, y el kit elegía uno con `head -1`
                # sobre un `find`: por el orden del sistema de ficheros.
                #
                # Cinco y no dos, y esto salió de la revisión: con dos, el orden que APFS
                # devuelve coincidía con el alfabético y el caso pasaba igual con el código
                # roto — cobertura decorativa. Con cinco no coincide (`find` devuelve
                # `ccc-tercero` primero aquí), así que el caso distingue de verdad.
                for c in ccc-tercero eee-quinto bbb-segundo ddd-cuarto aaa-primero; do
                    mkdir -p "openspec/changes/$c"
                    printf '# Tareas\n\n- [ ] 1. pendiente de %s\n' "$c" \
                        > "openspec/changes/$c/tasks.md"
                    printf '# P\n\n## Fuera de alcance\n\n- nada\n\n## Otra\n' \
                        > "openspec/changes/$c/proposal.md"
                done ;;
            sin) : ;;
        esac
        if [ -n "$dep" ]; then
            mkdir -p ".build/checkouts/$dep"
            echo "reglas de $dep" > ".build/checkouts/$dep/AGENTS.md"
        fi
        git add -A >/dev/null 2>&1
        git -c user.name=t -c user.email=t@t.t commit -qm contenido >/dev/null 2>&1
        exit 0
    )
}

# digest <repo> → imprime el additionalContext que produciría el hook
#
# HOME se fija al temporal a propósito: el hook rastrea `DerivedData` bajo $HOME y en una
# máquina real eso tarda y contamina el resultado con dependencias que no son del test.
# XDG_CACHE_HOME va aparte para poder comprobar dónde acaba el caché.
#
# `</dev/null` a propósito: el hook ahora lee stdin para saber qué evento lo invocó, y sin
# redirigir aquí heredaría el stdin de ESTE banco. Si algún día se corre a mano desde una
# terminal en vez de en CI, sin esto el banco entero se quedaría esperando EOF.
digest() {
    local r="$1"
    (
        cd "$r" || exit 1
        HOME="$TMP/home" XDG_CACHE_HOME="$TMP/cache" bash "$HOOK" </dev/null 2>/dev/null \
            | python3 -c 'import json,sys
try:
    d = json.load(sys.stdin)
    print(d["hookSpecificOutput"]["additionalContext"])
except Exception:
    print("")'
    )
}

# digest_stderr <repo> → imprime SOLO lo que el hook escribió en stderr, para el caso que
# exige que con cero tareas pendientes no escriba nada ahí. `digest()` lo descarta a
# propósito porque el resto de casos no lo necesitan; separarlo evita tocar su firma.
digest_stderr() {
    local r="$1"
    (
        cd "$r" || exit 1
        HOME="$TMP/home" XDG_CACHE_HOME="$TMP/cache" bash "$HOOK" </dev/null 2>&1 1>/dev/null
    )
}

# evento_emitido <repo> <hook_event_name> → el hookEventName que el hook devuelve cuando
# stdin trae ese campo. Simula lo que Claude Code manda de verdad: un JSON con
# `hook_event_name`, no una bandera ni una variable de entorno.
evento_emitido() {
    local r="$1" nombre="$2"
    (
        cd "$r" || exit 1
        printf '{"hook_event_name":"%s"}' "$nombre" \
            | HOME="$TMP/home" XDG_CACHE_HOME="$TMP/cache" bash "$HOOK" 2>/dev/null \
            | python3 -c 'import json,sys
try:
    d = json.load(sys.stdin)
    print(d["hookSpecificOutput"]["hookEventName"])
except Exception:
    print("")'
    )
}

# --- los repos --------------------------------------------------------------------------

repo con_cambio       activo      si  PaqueteUno
repo sin_cambio       vacio       si
repo ajeno            sin         no
repo otro_dep         vacio       si  PaqueteDos
repo dos_cambios      dos         si
repo con_cambio_hecho activo_cero si
repo sin_deps_propias vacio       si

mkdir -p "$TMP/home"

# Un DerivedData de una máquina con OTROS proyectos Xcode, ninguno de los cuales es un repo
# de este banco: el nombre no coincide con nada de aquí a propósito. Si el `find` del hook
# recorriera la máquina entera en vez de acotarse al repositorio observado, cualquier
# repositorio de este banco lo vería — empezando por `sin_deps_propias`, que no tiene ni una
# dependencia propia. Medido el 2026-09-08 con el repo real: `ios-agent-kit` (cero .swift)
# anunciaba paquetes de `AppStarter` y `DemoMulti`, y un repositorio vacío en /tmp recibía la
# misma frase.
mkdir -p "$TMP/home/Library/Developer/Xcode/DerivedData/OtroProyectoDeLaMaquina-a1b2c3/SourcePackages/checkouts/PaqueteAjeno"
echo "reglas de un proyecto que no es ninguno de estos repos" \
    > "$TMP/home/Library/Developer/Xcode/DerivedData/OtroProyectoDeLaMaquina-a1b2c3/SourcePackages/checkouts/PaqueteAjeno/AGENTS.md"

# Y otro cuyo nombre EMPIEZA por el de un repo del banco, sin guion en medio:
# `sin_deps_propiasextra-…`. Sin él, este banco no mide el borde del acotado, solo que se
# distinguen dos nombres sin relación ninguna — «medir lo fácil».
#
# Y desde que la resolución vive en `lib-kit.sh` esto tiene una consecuencia concreta: los dos
# bancos miden LA MISMA función. Medido el 2026-09-08 mutándola a `${proyecto}*` (sin el
# guion): el banco de `doc-paquetes.sh` la cazaba y este pasaba en verde los suyos. Un banco
# que dice «las dependencias son las de ESTE repositorio» y no mide dónde acaba «este» no está
# midiendo lo que anuncia. Lo encontró el juez de aceptación.
mkdir -p "$TMP/home/Library/Developer/Xcode/DerivedData/sin_deps_propiasextra-b4d1dea/SourcePackages/checkouts/PaqueteDePrefijo"
echo "reglas de un proyecto cuyo nombre empieza por el de un repo del banco" \
    > "$TMP/home/Library/Developer/Xcode/DerivedData/sin_deps_propiasextra-b4d1dea/SourcePackages/checkouts/PaqueteDePrefijo/AGENTS.md"

# --- los casos --------------------------------------------------------------------------

echo "▶ lo que ya hacía, y no puede romperse"

D="$(digest "$TMP/con_cambio")"
contiene "$D" "Reglas que ningún linter puede comprobar por ti"; caso $? \
    "las reglas innegociables siguen inyectándose"
contiene "$D" "Un hallazgo se arregla en su causa"; caso $? \
    "entre ellas, qué hacer con un hallazgo de revisión" \
    "la cláusula la afirmaba el acuerdo y no la medía nada: borrar la línea dejaba el banco verde"
contiene "$D" "mi-cambio"; caso $? \
    "con cambio activo, lo nombra"
contiene "$D" "2. pendiente"; caso $? \
    "con cambio activo, lista lo que queda"
contiene "$D" "no tocar la caja fuerte"; caso $? \
    "con cambio activo, recuerda el fuera de alcance"

D="$(digest "$TMP/sin_cambio")"
contiene "$D" "Sin cambio OpenSpec activo"; caso $? \
    "con openspec/ y sin cambio activo, lo dice"
contiene "$D" "/opsx:propose"; caso $? \
    "con openspec/ y sin cambio activo, manda proponer"

echo "▶ el cambio terminado no rompe el digest (cero tareas pendientes)"

# La rama que ningún fixture montaba: `con_cambio` (arriba) siempre tuvo UNA tarea
# pendiente, y con cero — el estado normal cuando el cambio está terminado y se va a llamar
# al juez — `grep -c` imprime "0" Y sale con 1. El `$(... || echo 0)` de antes de este
# cambio no distinguía eso de "no hubo salida" y sumaba un segundo "0", que en bash 3.2
# aborta el `if` entero: se perdían "tareas:", la lista de pendientes y "FUERA de alcance"
# en el mismo turno en que más importan. Reproducido el 2026-09-08 contra el hook de antes
# de este cambio con `HOOK_BAJO_PRUEBA`.
D="$(digest "$TMP/con_cambio_hecho")"
contiene "$D" "tareas:"; caso $? \
    "con cero tareas pendientes, el digest sigue diciendo cuántas hay hechas" \
    "el compound abortaba antes de llegar a esta línea: el digest saltaba directo a la verificación"
contiene "$D" "FUERA de alcance:"; caso $? \
    "con cero tareas pendientes, el digest sigue incluyendo el bloque FUERA de alcance" \
    "era la línea que más costaba perder: una de las reglas innegociables que este hook existe para inyectar"

# Y su CONTENIDO, que es lo que mide la caja de la cabecera: la línea de arriba comprueba la
# etiqueta que pone el propio hook, y esa sale igual aunque el bloque venga vacío.
contiene "$D" "no tocar la caja fuerte"; caso $? \
    "con la cabecera escrita en MAYÚSCULAS, el bloque sale igual" \
    "el sed distinguía mayúsculas: con «## FUERA de alcance» el bloque desaparecía en silencio"

ERR="$(digest_stderr "$TMP/con_cambio_hecho")"
if [ -z "$ERR" ]; then
    caso 0 "con cero tareas pendientes, el hook no escribe nada en stderr"
else
    caso 1 "con cero tareas pendientes, el hook no escribe nada en stderr" \
        "escribía el error de expansión aritmética ahí: $(printf '%s' "$ERR" | tr '\n' ' ')"
fi

echo "▶ un cambio activo sin lista de tareas"

# `docs/FLUJO.md` recomienda saltarse `tasks.md` en un cambio pequeño de alcance claro, y ahí el
# digest decía «tareas: 0/0 hechas»: se lee como «no queda nada por hacer» cuando lo cierto es
# que ese cambio no lleva lista. Se le quita la lista al repo del caso anterior, que ya no se
# usa más abajo.
rm -f "$TMP/con_cambio_hecho/openspec/changes/mi-cambio/tasks.md"
D="$(digest "$TMP/con_cambio_hecho")"
if contiene "$D" "tareas:"; then
    caso 1 "sin tasks.md, el digest NO cuenta tareas" \
        "decía «tareas: 0/0 hechas» sobre un cambio que no tiene lista"
else
    caso 0 "sin tasks.md, el digest NO cuenta tareas"
fi
contiene "$D" "no tocar la caja fuerte"; caso $? \
    "sin tasks.md, el resto del digest sigue saliendo" \
    "el bloque FUERA de alcance se perdió al quitar la lista"

echo "▶ el digest dice de qué repo habla"

for r in con_cambio sin_cambio ajeno; do
    D="$(digest "$TMP/${r}")"
    contiene "$D" "${r}"; caso $? \
        "en «${r}», el digest nombra el repo" \
        "no lo nombraba: sus afirmaciones flotaban y se leían como del repo donde se trabaja"
done

echo "▶ un repo sin OpenSpec no recibe órdenes de OpenSpec"

D="$(digest "$TMP/ajeno")"
if contiene "$D" "/opsx:propose"; then caso 1 \
    "sin openspec/, NO manda proponer" \
    "daba la misma orden que a un repo del kit, y ahí nadie puede seguirla"
else caso 0 "sin openspec/, NO manda proponer"; fi

if contiene "$D" "no usa OpenSpec" || contiene "$D" "no tiene OpenSpec"; then caso 0 \
    "sin openspec/, dice que ese repo no usa OpenSpec"
else caso 1 \
    "sin openspec/, dice que ese repo no usa OpenSpec" \
    "salía por la misma rama que «sin cambio activo» y no distinguía una cosa de la otra"; fi

echo "▶ no escribir en repos ajenos"

digest "$TMP/ajeno" >/dev/null
SUCIO="$(cd "$TMP/ajeno" && git status --porcelain)"
if [ -z "$SUCIO" ]; then caso 0 "tras correr en un repo ajeno, git status sigue limpio"
else caso 1 "tras correr en un repo ajeno, git status sigue limpio" \
    "le creaba .agent-kit/ sin preguntar: $(printf '%s' "$SUCIO" | tr '\n' ' ')"; fi

echo "▶ el caché"

D1="$(digest "$TMP/con_cambio")"     # depende de PaqueteUno
D2="$(digest "$TMP/otro_dep")"       # depende de PaqueteDos
if contiene "$D1" "PaqueteUno" && contiene "$D2" "PaqueteDos" \
   && ! contiene "$D2" "PaqueteUno"; then
    caso 0 "cada repo recibe SUS dependencias, no las de un proyecto de OTRO nombre"
else
    caso 1 "cada repo recibe SUS dependencias, no las de un proyecto de OTRO nombre" \
        "D1=[$(printf '%s' "$D1" | grep -o 'Paquete[A-Za-z]*' | tr '\n' ' ')] D2=[$(printf '%s' "$D2" | grep -o 'Paquete[A-Za-z]*' | tr '\n' ' ')]"
fi

# El criterio decía que el caché «evita el recorrido en turnos consecutivos» y NADIE lo
# comprobaba: solo se afirmaba en un comentario. Lo señaló un juez de aceptación. Se fija
# añadiendo una dependencia DESPUÉS del primer turno: si el segundo la ve, es que ha vuelto
# a recorrer y el caché no sirve para nada.
mkdir -p "$TMP/con_cambio/.build/checkouts/PaqueteTardio"
echo reglas > "$TMP/con_cambio/.build/checkouts/PaqueteTardio/AGENTS.md"
D3="$(digest "$TMP/con_cambio")"
# Se exige la PRESENCIA de la vieja además de la ausencia de la nueva. Solo con la
# ausencia, un hook que dejara de inyectar la línea de paquetes pasaría este caso sin
# haber cacheado nada — lo encontró un juez probando ese mutante.
if contiene "$D3" "PaqueteUno" && ! contiene "$D3" "PaqueteTardio"; then
    caso 0 "el segundo turno no vuelve a recorrer: usa el caché"
else
    caso 1 "el segundo turno no vuelve a recorrer: usa el caché" \
        "vio una dependencia añadida tras el primer turno (recorrió otra vez), o dejó de inyectar la línea"
fi

echo "▶ las dependencias se acotan al prefijo del repositorio"

# `sin_deps_propias` no depende de ningún paquete y se digesta aquí por PRIMERA vez, con el
# DerivedData ajeno ya montado — así el `find` corre de verdad y no se limita a leer un
# caché escrito antes de montar `PaqueteAjeno`. Medido el 2026-09-08 contra el hook de antes
# de este cambio: `ios-agent-kit` (cero ficheros .swift) anunciaba paquetes de AppStarter y
# DemoMulti, y un repositorio vacío en /tmp recibía la misma frase — el `find` recorría todo
# `~/Library/Developer/Xcode/DerivedData` sin filtrar por proyecto.
D="$(digest "$TMP/sin_deps_propias")"
if contiene "$D" "PaqueteAjeno"; then
    caso 1 "un repo sin dependencias propias no recibe las de un proyecto de OTRO nombre" \
        "el find recorría TODO DerivedData sin acotar al repositorio observado"
else
    caso 0 "un repo sin dependencias propias no recibe las de un proyecto de OTRO nombre"
fi

# La otra mitad del borde, y la que mide de verdad la función compartida: un vecino cuyo
# nombre empieza por el del repo pero SIN el guion. Tiene que ser sin guion — con él
# (`sin_deps_propias-algo`) casaría también con el patrón correcto, que es el límite declarado
# en `lib-kit.sh` y que este cambio deja abierto a propósito.
if contiene "$D" "PaqueteDePrefijo"; then
    caso 1 "ni las de uno cuyo nombre empieza por el suyo SIN guion" \
        "sin el guion en el patrón, un repo 'App' se llevaría lo de 'AppStarter-<hash>'"
else
    caso 0 "ni las de uno cuyo nombre empieza por el suyo SIN guion"
fi

echo "▶ el JSON declara el evento que lo invoca"

# El mismo script está registrado en dos eventos de `hooks.json`: `UserPromptSubmit` en
# cada turno y `SessionStart` con el matcher `compact`. Antes de este cambio, `hookEventName`
# era literal en el script y salía "UserPromptSubmit" sin mirar el JSON de stdin — así que
# el segundo caso de abajo salía en rojo contra esa versión, y el primero pasaba por
# casualidad (es el mismo valor que el literal de antes).
E="$(evento_emitido "$TMP/con_cambio" UserPromptSubmit)"
if [ "$E" = "UserPromptSubmit" ]; then
    caso 0 "invocado como UserPromptSubmit, el hookEventName emitido es UserPromptSubmit"
else
    caso 1 "invocado como UserPromptSubmit, el hookEventName emitido es UserPromptSubmit" \
        "emitió «${E}»"
fi

E="$(evento_emitido "$TMP/con_cambio" SessionStart)"
if [ "$E" = "SessionStart" ]; then
    caso 0 "invocado como SessionStart, el hookEventName emitido es SessionStart"
else
    caso 1 "invocado como SessionStart, el hookEventName emitido es SessionStart" \
        "emitía siempre UserPromptSubmit, aunque hooks.json registra el mismo script también en SessionStart(compact) — emitió «${E}»"
fi

echo "▶ con varios cambios activos, elige estable y lo dice"

D1="$(digest "$TMP/dos_cambios")"
D2="$(digest "$TMP/dos_cambios")"
E1="$(printf '%s' "$D1" | sed -n 's/.*Cambio activo: \([a-z-]*\).*/\1/p')"
E2="$(printf '%s' "$D2" | sed -n 's/.*Cambio activo: \([a-z-]*\).*/\1/p')"
# Se exige el MÍNIMO por `LC_ALL=C`, no solo que dos corridas coincidan entre sí.
#
# La primera versión de este caso comparaba `E1` con `E2` y ya está, y el revisor de la
# rodaja lo cazó: dos `find` seguidos sobre un directorio que no ha cambiado devuelven el
# mismo orden en cualquier sistema de ficheros, así que la aserción pasaba igual con el
# código roto. Cobertura decorativa. Los directorios se crean a propósito en orden inverso
# al alfabético (`bbb-segundo` antes que `aaa-primero`), que es lo que separa «ordenado» de
# «lo que devolvió el sistema de ficheros».
if [ "$E1" = "aaa-primero" ] && [ "$E1" = "$E2" ]; then
    caso 0 "elige el primero por orden estable, no el que devuelva el sistema de ficheros"
else
    caso 1 "elige el primero por orden estable, no el que devuelva el sistema de ficheros" \
        "elegía con head -1 sobre un find: el orden lo ponía el sistema de ficheros [$E1|$E2]"
fi

contiene "$D1" "5 cambios activos"; caso $? \
    "con varios cambios activos, avisa de cuántos hay" \
    "elegía uno y se lo callaba: el digest hablaba de un acuerdo mientras se trabajaba en el otro"

echo "▶ no escribe en directorios compartidos"

# LÍMITE DECLARADO de este caso: es LÉXICO, no dinámico. El fichero que había se creaba y se
# borraba dentro de la misma corrida, así que mirar qué queda en el temporal del sistema no
# lo habría visto nunca. Lo que se comprueba es que el hook no NOMBRE `/tmp`, que es la
# única señal mecánica disponible de que vuelva a escribir ahí.
if grep -v '^[[:space:]]*#' "$HOOK" | grep -q '/tmp/'; then
    caso 1 "el hook no escribe en el temporal compartido del sistema" \
        "usaba /tmp/.ic.\$\$ —nombre derivable del PID— en cada turno de cualquier repositorio"
else
    caso 0 "el hook no escribe en el temporal compartido del sistema"
fi

# El número de repos se CUENTA. Escrito a mano decía 4 cuando ya había 5, y solo pasaba
# porque el quinto se digestaba después de contar: se rompía en cuanto alguien moviera un
# bloque. Es el mismo censo a mano que este kit prohíbe en los acuerdos.
REPOS="$(find "$TMP" -maxdepth 2 -name .git -type d 2>/dev/null | wc -l | tr -d ' ')"
CACHES="$(find "$TMP/cache/ios-agent-kit" -type f 2>/dev/null | wc -l | tr -d ' ')"
if [ "$CACHES" -eq "$REPOS" ]; then IGUALES=0; else IGUALES=1; fi
caso "$IGUALES" "el caché vive fuera del repo, un fichero por repositorio ($CACHES de $REPOS)" \
    "vivía en .agent-kit/ dentro del repo observado, así que fuera no hay ninguno"

# Los rojos que quedan por cerrar son de ESTE cambio, no del que trajo el banco: los tres
# casos nuevos —orden estable, aviso de varios activos, y no escribir en /tmp— los añadió
# `el-kit-se-aplica-a-si-mismo`.
echo "▶ no se cuelga esperando una entrada que no llega"

# El hook lee stdin desde que declara el evento invocante, y `[ -t 0 ]` solo reconoce el caso
# terminal: con un pipe ABIERTO que nunca cierra, esperar EOF es esperar para siempre. Corre
# ANTES de cada turno, así que colgarlo es colgar la sesión. Lo encontró una medición de coste
# que se quedó parada ocho minutos, no una prueba — que es justo por qué este caso existe.
#
# Contra la versión de HEAD sale VERDE, y es correcto: allí el hook no leía stdin y no podía
# colgarse. Lo que fija no es un fallo vivo, es que la lectura nueva no traiga el cuelgue.
#
# `set -m` pone el job en su PROPIO grupo de procesos, y se mata el GRUPO —no el pid—. Sin
# eso, matar el shell del hook deja vivo el proceso que está leyendo el pipe, y es él quien
# cuelga a este banco: el primer intento de escribir este caso detectaba el cuelgue
# correctamente y luego se colgaba él, que es peor que no tenerlo.
# Y corre DENTRO de un repo de fixture, con el `HOME` y el caché del banco, como los otros
# casos. La primera versión no lo hacía y el revisor la cazó por partida doble: escribía en el
# caché REAL del usuario, y —peor— pasaba en falso desde cualquier cwd sin repositorio git,
# porque el hook sale en `git rev-parse` ANTES de llegar a leer stdin. Un caso que protege
# contra colgar la sesión y pierde los dientes según desde dónde se le invoque no protege nada.
MARCA_FIN="$TMP/hook-termino"
rm -f "$MARCA_FIN"
set -m
{ cd "$TMP/con_cambio" && HOME="$TMP/home" XDG_CACHE_HOME="$TMP/cache" \
      bash "$HOOK" >/dev/null 2>&1; : > "$MARCA_FIN"; } < <(sleep 30) &
GRUPO=$!
set +m
# El tope del hook es de un segundo; se le dan cuatro antes de declararlo colgado, para que
# una máquina cargada no dé un rojo falso.
ESPERAS=0
while [ "$ESPERAS" -lt 8 ] && [ ! -f "$MARCA_FIN" ]; do sleep 0.5; ESPERAS=$((ESPERAS+1)); done
kill -9 -"$GRUPO" 2>/dev/null
wait "$GRUPO" 2>/dev/null

if [ -f "$MARCA_FIN" ]; then
    caso 0 "con stdin abierto y sin EOF, termina solo en vez de esperar para siempre"
else
    caso 1 "con stdin abierto y sin EOF, termina solo en vez de esperar para siempre" \
        "esperaba EOF sin tope, y este hook corre antes de CADA turno: cuelga la sesión"
fi
rm -f "$MARCA_FIN"

resumen "el hook" "donde-la-regla-solo-llego-a-un-hermano"
