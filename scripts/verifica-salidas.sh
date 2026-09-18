#!/usr/bin/env bash
# Banco de pruebas de `verifica.sh`: sus códigos de salida y su firma.
# Por qué existe: es la pieza que decide si hay firma y por tanto si la puerta deja
# commitear, y su contrato tiene que estar fijado por algo más que la doc.
#
# Uso:  bash scripts/verifica-salidas.sh
#       VERIFICA_BAJO_PRUEBA=<ruta> bash scripts/verifica-salidas.sh   ← contra otra versión;
#       la copia va DENTRO de `scripts/`, porque busca a `busca-duplicados.py` como vecino.
set -uo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
. "$DIR/lib-banco.sh"

VER="${VERIFICA_BAJO_PRUEBA:-$DIR/verifica.sh}"
[ -f "$VER" ] || { echo "no encuentro verifica.sh en $VER"; exit 2; }

mkdir -p "$TMP/home"

# HOME al temporal a propósito: nada de lo que se mide aquí debe depender de la máquina de
# quien corre el banco.
# Un `[ … ]` suelto seguido de `caso $?` hace que shellcheck avise con razón (SC2319: ese
# `$?` viene de una condición, no de un comando). Con una función el aviso desaparece y la
# línea se lee mejor.
igual() { [ "$1" = "$2" ]; }

codigo() { ( cd "$1" || exit 9; shift; HOME="$TMP/home" bash "$VER" "$@" >/dev/null 2>&1; echo $? ); }
salida() { ( cd "$1" || exit 9; shift; HOME="$TMP/home" bash "$VER" "$@" 2>&1 ); }

# conf <repo> <pasos_en_rojo>
conf() {
    local r="$TMP/$1" n="$2" i
    {
        echo 'FUENTES="."'
        echo 'verificaciones() {'
        echo '    paso "uno bueno" true'
        # Nada de `seq 1 $n`: el `seq` de BSD cuenta HACIA ATRÁS cuando el primero es
        # mayor que el último, así que `seq 1 0` imprime «1 0» y el repo «verde» nacería con
        # dos pasos rojos dentro.
        i=0
        while [ "$i" -lt "$n" ]; do i=$((i+1)); echo "    paso \"malo $i\" false"; done
        echo '}'
    } > "$r/kit.conf"
}

repo_base verde   no ; conf verde 0
repo_base un_rojo no ; conf un_rojo 1
repo_base tres_rojos no ; conf tres_rojos 3
repo_base sin_conf no
repo_base sin_funcion no ; echo 'FUENTES="."' > "$TMP/sin_funcion/kit.conf"

echo "▶ «no pude mirar» no se confunde con «está mal»"

C="$(codigo "$TMP/sin_conf")"
igual "$C" 3; caso $? "sin kit.conf sale 3 — «no pude mirar» ($C)"

C="$(codigo "$TMP/sin_funcion")"
igual "$C" 3; caso $? "un kit.conf sin verificaciones() sale 3 ($C)"

C="$(codigo "$TMP/tres_rojos")"
if igual "$C" 1; then
    caso 0 "TRES pasos en rojo salen 1, no 3 ($C)"
else
    caso 1 "TRES pasos en rojo salen 1, no 3 ($C)" \
        "salía con el número de fallos, así que tres rojos eran indistinguibles de «no hay kit.conf»"
fi

C="$(codigo "$TMP/un_rojo")"
igual "$C" 1; caso $? "un paso en rojo sale 1 ($C)"

C="$(codigo "$TMP/verde")"
igual "$C" 0; caso $? "todo en verde sale 0 ($C)"

echo "▶ el recuento no se pierde: se mueve al informe y a la firma"

S="$(salida "$TMP/tres_rojos")"
contiene "$S" "3 paso(s) en rojo"; caso $? "el informe dice cuántos pasos fallaron"
contiene "$(cat "$TMP/tres_rojos/.agent-kit/verificacion.txt")" "resultado: rojo (3 paso(s))"
caso $? "la firma también lo dice"

contiene "$(cat "$TMP/verde/.agent-kit/verificacion.txt")" "resultado: verde"
caso $? "en verde, la firma lo dice"

echo "▶ la firma solo vale para este diff y para un verde"

C="$(codigo "$TMP/verde" --comprueba)"
igual "$C" 0; caso $? "tras un verde, --comprueba acepta ($C)"

C="$(codigo "$TMP/tres_rojos" --comprueba)"
igual "$C" 1; caso $? "tras un rojo, --comprueba rechaza ($C)" \
    "el marker conservaba su línea diff: y esto respondía «firma válida» sobre un árbol roto"

echo nuevo > "$TMP/verde/otro.txt"
( cd "$TMP/verde" && git add otro.txt >/dev/null 2>&1 )
C="$(codigo "$TMP/verde" --comprueba)"
igual "$C" 1; caso $? "si el árbol cambia, la firma deja de valer ($C)"

echo "▶ un repositorio sin commits todavía"

# Sin `HEAD` no hay árbol contra el que comparar, y `git diff HEAD` falla: la huella tiene que
# caer al índice, que es la única referencia que existe ahí. Sin esa caída, un repositorio
# recién creado firmaría la huella del vacío — la misma para cualquier contenido.
mkdir -p "$TMP/virgen"
(
    cd "$TMP/virgen" || exit 1
    git init -q .
    git config user.email t@t.t
    git config user.name t
    echo hola > a.txt
    git add a.txt
) >/dev/null 2>&1
conf virgen 0

C="$(codigo "$TMP/virgen")"
igual "$C" 0; caso $? "sin ningún commit, la verificación firma ($C)"

C="$(codigo "$TMP/virgen" --comprueba)"
igual "$C" 0; caso $? "sin ningún commit, esa firma vale ($C)"

# Y que DISTINGA: se stagea algo más y la firma tiene que dejar de valer. Contra una huella que
# mire solo el árbol, este caso sale rojo — los dos de arriba no, y por eso hace falta.
#
# Lo que este caso NO fija: quitar la caída al índice. El `git diff --cached` sigue en la
# tubería, así que sin el `if` lo único que se gana es un «fatal: ambiguous argument HEAD» en
# stderr.
( cd "$TMP/virgen" && echo otro > otro.txt && git add otro.txt ) >/dev/null 2>&1
C="$(codigo "$TMP/virgen" --comprueba)"
igual "$C" 1; caso $? "sin ningún commit, stagear algo más invalida la firma ($C)" \
    "sin la caída al índice la huella es la del vacío, y cualquier contenido cuadra con ella"

C="$(codigo "$TMP/sin_conf" --comprueba)"
igual "$C" 1; caso $? "sin nada verificado, --comprueba rechaza ($C)"

echo "▶ la firma declara su alcance"

# Lo que se prueba aquí no es el formato por el formato: es que un verde no se pueda leer sin
# leer con qué se consiguió, porque el CI puede compilar con otro toolchain.
FIRMA="$(cat "$TMP/verde/.agent-kit/verificacion.txt")"
contiene "$FIRMA" "toolchain: "; caso $? "la cabecera de la firma dice con qué se verificó"
contiene "$FIRMA" "limites: sin declarar"
caso $? "sin LIMITES en kit.conf, la cabecera lo dice en vez de callarlo"

S="$(salida "$TMP/verde")"
contiene "$S" "no declara los límites de su firma"
caso $? "y el informe se lo dice a quien lo lee"
contiene "$S" "toolchain: Swift"
caso $? "la línea del verde nombra el toolchain"
contiene "$S" "no dice nada de otros toolchains"
caso $? "y dice que no habla de los demás" \
    "sin esto, «verificación en verde» se lee como «esto pasa» y no como «esto pasó aquí»"

C="$(salida "$TMP/verde" --comprueba)"
contiene "$C" "toolchain: "; caso $? "--comprueba también dice con qué se firmó"

# Con límites declarados: el texto del proyecto viaja al informe.
repo_base con_limites no ; conf con_limites 0
{
    echo 'LIMITES="Los tests de UI no entran: tardan minutos y van en CI."'
    cat "$TMP/con_limites/kit.conf"
} > "$TMP/con_limites/kit.conf.nuevo" && mv "$TMP/con_limites/kit.conf.nuevo" "$TMP/con_limites/kit.conf"
S="$(salida "$TMP/con_limites")"
contiene "$S" "LO QUE ESTA FIRMA NO CUBRE"
caso $? "con LIMITES declarado, el informe trae su rótulo"
contiene "$S" "Los tests de UI no entran"
caso $? "y trae el texto que escribió el proyecto"
contiene "$(cat "$TMP/con_limites/.agent-kit/verificacion.txt")" "limites: declarados"
caso $? "la cabecera de la firma dice que los declara"

# Una firma ANTERIOR a estos campos sigue valiendo. Se simula quitándole las dos líneas a un
# marker verde, sin tocar el árbol.
grep -v "^toolchain: \|^limites: " "$TMP/verde/.agent-kit/verificacion.txt" > "$TMP/verde/.agent-kit/v.viejo" \
    && mv "$TMP/verde/.agent-kit/v.viejo" "$TMP/verde/.agent-kit/verificacion.txt"
C="$(codigo "$TMP/verde" --comprueba)"
igual "$C" 0; caso $? "un marker sin los campos nuevos sigue siendo válido ($C)" \
    "si esto rechaza, actualizar el kit invalida la firma de todos los proyectos a la vez"

# La divergencia entre el `swift` del PATH y el de Xcode se simula con un shim que anuncia
# otra versión, y lo que se exige es que lo DIGA y que NO bloquee — hay proyectos que usan un
# toolchain de swift.org a propósito.
FALSO="$TMP/falso_swift"; mkdir -p "$FALSO"
# Sin «Apple» a propósito: es el banner de un toolchain de swift.org, y el patrón de
# `version_swift` tiene que leerlo sin exigir ese prefijo. Un caso cubre las dos cosas.
printf '#!/bin/sh\necho "Swift version 9.9.9 (swiftlang-9.9.9)"\n' > "$FALSO/swift"
chmod +x "$FALSO/swift"
S="$( cd "$TMP/verde" && HOME="$TMP/home" PATH="$FALSO:$PATH" bash "$VER" 2>&1 )"
contiene "$S" "OJO: el swift del PATH"
caso $? "si el swift del PATH no es el de Xcode, la firma lo dice"
contiene "$S" "✅ verde · toolchain: Swift 9.9.9"
caso $? "y avisa sin bloquear: la verificación sigue firmando" \
    "bloquear aquí rompería a quien usa un toolchain de swift.org a propósito"
# Y en el MARKER, no solo en la salida: es la firma la que tiene que llevarlo, porque es lo que
# se lee después.
contiene "$(cat "$TMP/verde/.agent-kit/verificacion.txt")" "OJO: el swift del PATH"
caso $? "y la firma se lo queda, no solo la salida"

echo "▶ la puerta de commit es un hook de git del repositorio"

# Lo que se prueba es el hook DE VERDAD: `git commit` en el repositorio temporal, con la firma
# en el estado que toque. `--comprueba` no vale aquí, porque la puerta ya no la invoca nadie.
# HOME apunta al temporal para que `cd ~/puerta` resuelva ahí.
commit() { ( cd "$1" || exit 9; shift; HOME="$TMP" git "$@" >/dev/null 2>&1; echo $? ); }
ejecutable() { [ -x "$1" ]; }
ausentes() { [ ! -e "$1" ] && [ ! -e "$2" ]; }
HOOK_MARCA="ios-agent-kit: puerta de commit"

repo_base puerta no ; conf puerta 0
HOOK="$TMP/puerta/.git/hooks/pre-commit"

S="$(salida "$TMP/puerta")"
ejecutable "$HOOK" && grep -q "$HOOK_MARCA" "$HOOK"
caso $? "tras verificar existe .git/hooks/pre-commit, ejecutable y con la marca del kit"
contiene "$S" "puerta de commit instalada"; caso $? "y el informe lo dice la primera vez"
S="$(salida "$TMP/puerta")"
! contiene "$S" "puerta de commit instalada"; caso $? "la segunda vez la refresca sin anunciarla"

( cd "$TMP/puerta" && echo uno > uno.txt && git add uno.txt ) >/dev/null 2>&1
codigo "$TMP/puerta" >/dev/null
C="$(commit "$TMP/puerta" commit -q -m uno)"
igual "$C" 0; caso $? "con el índice firmado, git commit pasa ($C)"

# Cada caso de bloqueo hace su PROPIA edición: si el anterior se hubiera colado, el siguiente
# no tendría nada que commitear y saldría 1 sin que la puerta hubiera hecho nada.
edita() { ( cd "$TMP/puerta" && echo "$1" >> uno.txt ) >/dev/null 2>&1; }
codigo "$TMP/puerta" >/dev/null                     # firma del árbol limpio tras el commit
edita dos
C="$(commit "$TMP/puerta" commit -q -am dos)"
igual "$C" 1; caso $? "editar tras firmar y commitear con -am bloquea ($C)"
edita dos-bis
C="$(commit "$TMP/puerta" commit -q -m dos -- uno.txt)"
igual "$C" 1; caso $? "editar tras firmar y commitear con pathspec bloquea ($C)"
edita dos-tris; ( cd "$TMP/puerta" && git add uno.txt ) >/dev/null 2>&1
C="$(commit "$TMP/puerta" commit -q -m dos)"
igual "$C" 1; caso $? "stagear después de firmar y commitear aparte bloquea ($C)"
codigo "$TMP/puerta" >/dev/null
C="$(commit "$TMP/puerta" commit -q -m dos)"
igual "$C" 0; caso $? "tras volver a firmar con eso stageado, pasa ($C)"

edita tres; ( cd "$TMP/puerta" && git add uno.txt ) >/dev/null 2>&1
C="$( HOME="$TMP" git -C "$TMP/puerta" commit -q -m tres >/dev/null 2>&1; echo $? )"
igual "$C" 1; caso $? "git -C desde fuera del repositorio, sin firma, bloquea ($C)"
edita tres-bis; ( cd "$TMP/puerta" && git add uno.txt ) >/dev/null 2>&1
C="$( cd / && HOME="$TMP" bash -c 'cd ~/puerta && git commit -q -m tres' >/dev/null 2>&1; echo $? )"
igual "$C" 1; caso $? "cd ~/… && git commit dentro de un bash -c, sin firma, bloquea ($C)"
codigo "$TMP/puerta" >/dev/null
C="$( cd / && HOME="$TMP" bash -c 'cd ~/puerta && git commit -q -m tres' >/dev/null 2>&1; echo $? )"
igual "$C" 0; caso $? "la misma forma, con firma válida, pasa ($C)"

# Un repositorio sin ningún commit: la verificación firma el índice, instala el hook y el
# primer commit pasa.
mkdir -p "$TMP/primero"
( cd "$TMP/primero" && git init -q . && git config user.email t@t.t && git config user.name t \
  && echo hola > a.txt && git add a.txt ) >/dev/null 2>&1
conf primero 0
codigo "$TMP/primero" >/dev/null
C="$(commit "$TMP/primero" commit -q -m primero)"
igual "$C" 0; caso $? "sin ningún commit previo, firma, instala y el primer commit pasa ($C)"

# Un pre-commit ajeno no se toca; el hook del kit queda aparte y el informe dice qué línea añadir.
repo_base ajeno no ; conf ajeno 0
printf '#!/bin/sh\nexit 0\n' > "$TMP/ajeno/.git/hooks/pre-commit"; chmod +x "$TMP/ajeno/.git/hooks/pre-commit"
ANTES="$(cksum < "$TMP/ajeno/.git/hooks/pre-commit")"
S="$(salida "$TMP/ajeno")"
igual "$ANTES" "$(cksum < "$TMP/ajeno/.git/hooks/pre-commit")"
caso $? "un pre-commit que no es del kit queda byte a byte igual"
contiene "$S" "bash .agent-kit/pre-commit"; caso $? "y el informe dice la línea que hay que añadirle"
ejecutable "$TMP/ajeno/.agent-kit/pre-commit"; caso $? "el hook del kit queda escrito en .agent-kit/pre-commit"

# Con core.hooksPath configurado, no se escribe ningún pre-commit en ningún sitio.
repo_base hookspath no ; conf hookspath 0
( cd "$TMP/hookspath" && mkdir -p .githooks && git config core.hooksPath .githooks ) >/dev/null 2>&1
S="$(salida "$TMP/hookspath")"
ausentes "$TMP/hookspath/.git/hooks/pre-commit" "$TMP/hookspath/.githooks/pre-commit"
caso $? "con core.hooksPath no se escribe ningún pre-commit"
contiene "$S" "bash .agent-kit/pre-commit"; caso $? "y el informe dice dónde engancharlo"

# El mensaje del bloqueo dice qué hacer: si el heredoc quedara vacío, todo lo de arriba
# seguiría en verde.
edita cuatro; ( cd "$TMP/puerta" && git add uno.txt ) >/dev/null 2>&1
MSG="$( cd "$TMP/puerta" && HOME="$TMP" git commit -q -m cuatro 2>&1 )"
contiene "$MSG" "comando aparte"; caso $? "el mensaje del bloqueo dice cómo commitear"

# Sin kit.conf el hook se abre: el repositorio ya no usa el kit, y un hook que sobrevive a
# desinstalarlo no puede ser un muro.
( cd "$TMP/puerta" && mv kit.conf kit.conf.fuera ) >/dev/null 2>&1
C="$(commit "$TMP/puerta" commit -q -m cuatro)"
igual "$C" 0; caso $? "sin kit.conf, el hook deja pasar ($C)"
( cd "$TMP/puerta" && mv kit.conf.fuera kit.conf ) >/dev/null 2>&1

# Si no se puede escribir el hook, el informe lo dice, y NO dice «instalada».
repo_base sin_permiso no ; conf sin_permiso 0
chmod 500 "$TMP/sin_permiso/.git/hooks"
S="$(salida "$TMP/sin_permiso")"
chmod 755 "$TMP/sin_permiso/.git/hooks"
contiene "$S" "queda SIN puerta"; caso $? "si no se puede escribir el hook, el informe lo dice"
! contiene "$S" "puerta de commit instalada"; caso $? "y no afirma haberla instalado"

# Con core.hooksPath el informe nombra el fichero, no solo la línea.
contiene "$(salida "$TMP/hookspath")" ".githooks/pre-commit"
caso $? "con core.hooksPath el informe nombra el fichero al que añadir la línea"

# Una verificación en rojo instala el hook igual, y el hook bloquea.
ejecutable "$TMP/un_rojo/.git/hooks/pre-commit"; caso $? "una verificación en rojo también instala el hook"
( cd "$TMP/un_rojo" && echo x > x.txt && git add x.txt ) >/dev/null 2>&1
codigo "$TMP/un_rojo" >/dev/null
C="$(commit "$TMP/un_rojo" commit -q -m rojo)"
igual "$C" 1; caso $? "y bloquea el commit de un árbol cuya verificación salió en rojo ($C)"

resumen "verifica.sh" "la-puerta-es-de-git"
