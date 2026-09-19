#!/usr/bin/env bash
# Banco de pruebas de `inyecta-contexto.sh`.
# Por qué existe: el hook corre en CADA turno sin que nadie lo invoque, así que lo que afirma
# sobre el trabajo en curso solo lo corrige un banco.
#
# Uso:  bash scripts/verifica-contexto.sh
#       HOOK_BAJO_PRUEBA=<ruta> bash scripts/verifica-contexto.sh   ← contra otra versión
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
                # Un cambio activo con CERO tareas pendientes: el estado normal cuando el
                # cambio está terminado y se va a llamar al juez. Con cero coincidencias
                # `grep -c` imprime "0" Y sale con 1, y el digest tiene que sobrevivir a eso.
                #
                # La cabecera va en MAYÚSCULAS a propósito: hay propuestas que la escriben
                # así. El fixture de `activo` la deja en minúsculas: entre los dos cubren las
                # dos formas.
                mkdir -p openspec/changes/mi-cambio
                printf '# Tareas\n\n- [x] 1. hecha\n- [x] 2. tambien hecha\n' \
                    > openspec/changes/mi-cambio/tasks.md
                printf '# P\n\n## FUERA de alcance\n\n- no tocar la caja fuerte\n\n## Otra\n' \
                    > openspec/changes/mi-cambio/proposal.md ;;
            dos)
                # CINCO cambios abiertos a la vez, creados en orden inverso al alfabético.
                # OpenSpec permite varios, y el hook tiene que listarlos en orden estable, no
                # en el que devuelva el sistema de ficheros.
                #
                # Cinco y no dos: con dos, el orden que APFS devuelve coincide con el
                # alfabético y el caso pasaría igual con el código roto. Con cinco no
                # coincide (`find` devuelve `ccc-tercero` primero aquí).
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
# `</dev/null` a propósito: el hook lee stdin para saber qué evento lo invocó, y sin
# redirigir aquí heredaría el stdin de ESTE banco; corrido a mano desde una terminal, el
# banco entero se quedaría esperando EOF.
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
# propósito porque el resto de casos no lo necesitan.
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
# dependencia propia.
mkdir -p "$TMP/home/Library/Developer/Xcode/DerivedData/OtroProyectoDeLaMaquina-a1b2c3/SourcePackages/checkouts/PaqueteAjeno"
echo "reglas de un proyecto que no es ninguno de estos repos" \
    > "$TMP/home/Library/Developer/Xcode/DerivedData/OtroProyectoDeLaMaquina-a1b2c3/SourcePackages/checkouts/PaqueteAjeno/AGENTS.md"

# Y otro cuyo nombre EMPIEZA por el de un repo del banco, sin guion en medio:
# `sin_deps_propiasextra-…`. Sin él, este banco no mide el borde del acotado, solo que se
# distinguen dos nombres sin relación ninguna.
#
# La resolución vive en `lib-kit.sh`, así que este banco y el de `doc-paquetes.sh` miden LA
# MISMA función: un banco que dice «las dependencias son las de ESTE repositorio» tiene que
# medir dónde acaba «este».
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
contiene "$D" "Cambio activo: mi-cambio" && ! contiene "$D" "Cambios activos:"; caso $? \
    "con UN cambio activo, lo nombra como el de la sesión" \
    "con un solo cambio pasaba a la forma de varios: nombres sin tareas ni fuera de alcance"
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

# `con_cambio` (arriba) siempre tiene UNA tarea pendiente. Con cero —el estado normal cuando
# el cambio está terminado y se va a llamar al juez— `grep -c` imprime "0" Y sale con 1; si
# el hook trata eso como «no hubo salida», el `if` aborta en bash 3.2 y se pierden "tareas:",
# la lista de pendientes y "FUERA de alcance" en el turno en que más importan.
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

# `docs/FLUJO.md` recomienda saltarse `tasks.md` en un cambio pequeño de alcance claro, y
# «tareas: 0/0 hechas» se leería como «no queda nada por hacer» cuando lo cierto es que ese
# cambio no lleva lista. Se le quita la lista al repo del caso anterior, que ya no se usa
# más abajo.
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

# El caché tiene que evitar el recorrido en turnos consecutivos, y eso se mide añadiendo una
# dependencia DESPUÉS del primer turno: si el segundo la ve, es que ha vuelto a recorrer.
mkdir -p "$TMP/con_cambio/.build/checkouts/PaqueteTardio"
echo reglas > "$TMP/con_cambio/.build/checkouts/PaqueteTardio/AGENTS.md"
D3="$(digest "$TMP/con_cambio")"
# Se exige la PRESENCIA de la vieja además de la ausencia de la nueva: solo con la ausencia,
# un hook que dejara de inyectar la línea de paquetes pasaría este caso sin haber cacheado
# nada.
if contiene "$D3" "PaqueteUno" && ! contiene "$D3" "PaqueteTardio"; then
    caso 0 "el segundo turno no vuelve a recorrer: usa el caché"
else
    caso 1 "el segundo turno no vuelve a recorrer: usa el caché" \
        "vio una dependencia añadida tras el primer turno (recorrió otra vez), o dejó de inyectar la línea"
fi

echo "▶ las dependencias se acotan al prefijo del repositorio"

# `sin_deps_propias` no depende de ningún paquete y se digesta aquí por PRIMERA vez, con el
# DerivedData ajeno ya montado — así el `find` corre de verdad y no se limita a leer un
# caché escrito antes de montar `PaqueteAjeno`.
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
# en `lib-kit.sh` y que queda abierto a propósito.
if contiene "$D" "PaqueteDePrefijo"; then
    caso 1 "ni las de uno cuyo nombre empieza por el suyo SIN guion" \
        "sin el guion en el patrón, un repo 'App' se llevaría lo de 'AppStarter-<hash>'"
else
    caso 0 "ni las de uno cuyo nombre empieza por el suyo SIN guion"
fi

echo "▶ el JSON declara el evento que lo invoca"

# El mismo script está registrado en dos eventos de `hooks.json`: `UserPromptSubmit` en
# cada turno y `SessionStart` con el matcher `compact`. `hookEventName` tiene que salir del
# JSON de stdin, no de un literal: con un literal, el primer caso pasa por casualidad y el
# segundo no.
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

echo "▶ con varios cambios activos, nombra y no afirma"

D1="$(digest "$TMP/dos_cambios")"
ORDEN="$(printf '%s\n' "$D1" | sed -n 's/^    - \([a-z][a-z-]*\).*/\1/p' | tr '\n' ' ')"
# Se exige el orden `LC_ALL=C` ENTERO, no que dos corridas coincidan entre sí: dos `find`
# seguidos sobre un directorio que no ha cambiado devuelven el mismo orden en cualquier
# sistema de ficheros, así que compararlas pasaría igual con el código roto. Los directorios
# se crean a propósito en orden inverso al alfabético, que es lo que separa «ordenado» de «lo
# que devolvió el sistema de ficheros».
OK=1; [ "$ORDEN" = "aaa-primero bbb-segundo ccc-tercero ddd-cuarto eee-quinto " ] && OK=0
caso "$OK" "lista los cambios en orden estable, no en el que devuelva el sistema de ficheros" \
    "el orden lo ponía el sistema de ficheros [$ORDEN]"

contiene "$D1" "Cambios activos: 5" && contiene "$D1" "aaa-primero (0/1)"; caso $? \
    "con varios cambios activos, dice cuántos hay y el recuento de cada uno" \
    "no decía cuántos eran o no daba las tareas de cada cambio"

# El fallo que llegó a un proyecto real: con dos cambios abiertos, el digest ponía delante
# el «fuera de alcance» del otro, que nombraba justo la tarea de la sesión.
FUGA=""
for t in "Cambio activo:" "FUERA de alcance" "- [ ]" "pendiente de"; do
    contiene "$D1" "$t" && FUGA="$FUGA «${t}»"
done
OK=1; [ -z "$FUGA" ] && OK=0
caso "$OK" "con varios cambios activos, no afirma el acuerdo de ninguno" \
    "inyectaba las tareas y el fuera de alcance de un cambio que podía no ser el de la sesión:$FUGA"

contiene "$D1" "el del cambio en el que trabajas"; caso $? \
    "con varios cambios activos, dice de quién es el acuerdo de la sesión" \
    "listaba los cambios sin decir que el acuerdo es el del cambio en el que se trabaja"

# Más de cinco: el digest se paga en cada turno, así que nombra cinco y cuenta el resto. El
# hook lee el disco, no git: basta con crear los directorios.
mkdir -p "$TMP/dos_cambios/openspec/changes/fff-sexto" "$TMP/dos_cambios/openspec/changes/ggg-septimo"
D7="$(digest "$TMP/dos_cambios")"
contiene "$D7" "Cambios activos: 7" && contiene "$D7" "… y 2 más" && ! contiene "$D7" "fff-sexto"
caso $? "con más de cinco cambios activos, nombra cinco y dice cuántos quedan" \
    "la lista crecía con cada cambio abierto, y el digest va en cada turno"

echo "▶ no escribe en directorios compartidos"

# LÍMITE DECLARADO de este caso: es LÉXICO, no dinámico. Un fichero que se crea y se borra
# dentro de la misma corrida no se ve mirando qué queda en el temporal del sistema. Lo que se
# comprueba es que el hook no NOMBRE `/tmp`, que es la única señal mecánica disponible.
if grep -v '^[[:space:]]*#' "$HOOK" | grep -q '/tmp/'; then
    caso 1 "el hook no escribe en el temporal compartido del sistema" \
        "usaba /tmp/.ic.\$\$ —nombre derivable del PID— en cada turno de cualquier repositorio"
else
    caso 0 "el hook no escribe en el temporal compartido del sistema"
fi

# El número de repos se CUENTA, no se escribe a mano: un censo a mano se rompe en cuanto
# alguien mueve un bloque, y es el mismo censo que este kit prohíbe en los acuerdos.
REPOS="$(find "$TMP" -maxdepth 2 -name .git -type d 2>/dev/null | wc -l | tr -d ' ')"
CACHES="$(find "$TMP/cache/ios-agent-kit" -type f 2>/dev/null | wc -l | tr -d ' ')"
if [ "$CACHES" -eq "$REPOS" ]; then IGUALES=0; else IGUALES=1; fi
caso "$IGUALES" "el caché vive fuera del repo, un fichero por repositorio ($CACHES de $REPOS)" \
    "vivía en .agent-kit/ dentro del repo observado, así que fuera no hay ninguno"

echo "▶ no se cuelga esperando una entrada que no llega"

# El hook lee stdin para saber qué evento lo invoca, y `[ -t 0 ]` solo reconoce el caso
# terminal: con un pipe ABIERTO que nunca cierra, esperar EOF es esperar para siempre. Corre
# ANTES de cada turno, así que colgarlo es colgar la sesión.
#
# `set -m` pone el job en su PROPIO grupo de procesos, y se mata el GRUPO —no el pid—. Sin
# eso, matar el shell del hook deja vivo el proceso que está leyendo el pipe, y es él quien
# cuelga a este banco.
#
# Corre DENTRO de un repo de fixture, con el `HOME` y el caché del banco, como los otros
# casos: desde un cwd sin repositorio git el hook sale en `git rev-parse` ANTES de llegar a
# leer stdin y el caso pasaría en falso, y sin el `HOME` del banco escribiría en el caché
# REAL del usuario.
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

echo "▶ la línea de verificación dice con qué se firmó"

# La línea de verificación es la que más se lee: llega en cada turno. Se firma de verdad
# —`verifica.sh` con un kit.conf trivial— en vez de fabricar el marker a mano, porque la
# huella tiene que cuadrar con el árbol.
repo firmado vacio si
( cd "$TMP/firmado" && HOME="$TMP/home" bash "$DIR/verifica.sh" ) >/dev/null 2>&1
TC_MARKER="$(sed -n 's/^toolchain: //p' "$TMP/firmado/.agent-kit/verificacion.txt" | head -1)"
D="$(digest "$TMP/firmado")"
contiene "$D" "Verificación: firmada contra el árbol actual (toolchain: $TC_MARKER)"
caso $? "el digest nombra el toolchain que dice el marker" \
    "sin esto, «firmada» se lee como «esto pasa» y el CI puede estar rojo con otro toolchain"

# Y NO lo detecta por su cuenta: interrogar al compilador en cada turno costaría 0,3 s por turno.
# `caso` recibe el código explícito y no `$?`: después de un `[ ]`, shellcheck avisa (SC2319)
# de que ese `$?` es de una condición y no de un comando, y tiene razón.
if [ "$(grep -c 'swift --version\|xcodebuild' "$HOOK")" = 0 ]
then caso 0 "el hook no interroga a ningún compilador"
else caso 1 "el hook no interroga a ningún compilador" \
    "detectar el toolchain en el hook costaría 0,3 s en cada turno"
fi

# Un marker sin el campo `toolchain`: la línea queda como estaba, sin inventarse un dato.
grep -v "^toolchain: " "$TMP/firmado/.agent-kit/verificacion.txt" > "$TMP/firmado/.agent-kit/v" \
    && mv "$TMP/firmado/.agent-kit/v" "$TMP/firmado/.agent-kit/verificacion.txt"
D="$(digest "$TMP/firmado")"
contiene "$D" "Verificación: firmada contra el árbol actual."
caso $? "con un marker sin ese campo, la línea queda como antes"

resumen "el hook" "donde-la-regla-solo-llego-a-un-hermano"
