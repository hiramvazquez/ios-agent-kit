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
existe() { [ -e "$1" ]; }

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

# El hook se basta SOLO: lleva copiadas todas las funciones que usa. Si falta una, dentro del
# hook queda indefinida, la foto falla y la puerta bloquea cualquier commit —pasó al partir la
# foto en varias funciones—. Se comprueba corriéndolo en un shell limpio, sin la lib cargada.
SUELTO="$( cd "$TMP/puerta" && env -i HOME="$TMP" PATH="$PATH" bash "$HOOK" 2>&1 )"
if printf '%s' "$SUELTO" | grep -q "command not found"
then caso 1 "el hook no depende de nada que no lleve dentro" \
        "llamaba a funciones de lib-kit.sh que no se copiaron, y bloqueaba todos los commits"
else caso 0 "el hook no depende de nada que no lleve dentro"
fi
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
# Bloquea porque el ÁRBOL cambió después de firmar, no porque se stagee: stagear lo ya
# verificado no invalida nada, y eso lo fija la sección «stagear lo ya verificado», abajo.
edita dos-tris; ( cd "$TMP/puerta" && git add uno.txt ) >/dev/null 2>&1
C="$(commit "$TMP/puerta" commit -q -m dos)"
igual "$C" 1; caso $? "editar tras firmar bloquea aunque se stagee ($C)"
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
contiene "$MSG" "/kit-verifica"; caso $? "el mensaje del bloqueo dice cómo commitear"

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

echo "▶ lo que se escribe en openspec/ después de firmar no invalida la firma"

# El flujo de OpenSpec escribe en `openspec/` justo después de verificar —marcar la última
# tarea, archivar—, y nada de eso cambia lo que se compila. Lo de fuera sigue invalidando.
repo_base acuerdo no ; conf acuerdo 0
(
    cd "$TMP/acuerdo" || exit 1
    mkdir -p openspec/changes/x openspec/specs/y openspec-notas
    echo '- [ ] 1.1 algo' > openspec/changes/x/tasks.md
    echo '# y' > openspec/specs/y/spec.md
    echo nota > openspec-notas/n.txt
    git add -A && git commit -qm acuerdo
) >/dev/null 2>&1
codigo "$TMP/acuerdo" >/dev/null

echo '- [x] 1.1 algo' > "$TMP/acuerdo/openspec/changes/x/tasks.md"
C="$(codigo "$TMP/acuerdo" --comprueba)"
igual "$C" 0; caso $? "marcar una tarea en openspec/ después de firmar no invalida la firma ($C)"
( cd "$TMP/acuerdo" && git add openspec ) >/dev/null 2>&1
C="$(codigo "$TMP/acuerdo" --comprueba)"
igual "$C" 0; caso $? "stagearla tampoco ($C)"
C="$(commit "$TMP/acuerdo" commit -q -m tarea)"
igual "$C" 0; caso $? "y el commit que solo lleva eso pasa la puerta sin volver a verificar ($C)"

(
    cd "$TMP/acuerdo" || exit 1
    mkdir -p openspec/changes/archive
    git mv openspec/changes/x openspec/changes/archive/x
    echo fundido >> openspec/specs/y/spec.md
) >/dev/null 2>&1
C="$(codigo "$TMP/acuerdo" --comprueba)"
igual "$C" 0; caso $? "archivar el cambio y fundir su delta tampoco ($C)"

echo otra >> "$TMP/acuerdo/base.txt"
C="$(codigo "$TMP/acuerdo" --comprueba)"
igual "$C" 1; caso $? "con el acuerdo cambiado, un cambio fuera de openspec/ sí la invalida ($C)"
( cd "$TMP/acuerdo" && git checkout -q base.txt ) >/dev/null 2>&1

echo otra >> "$TMP/acuerdo/openspec-notas/n.txt"
C="$(codigo "$TMP/acuerdo" --comprueba)"
igual "$C" 1; caso $? "openspec-notas/ no es openspec/: tocarlo la invalida ($C)"

echo "▶ stagear lo ya verificado no invalida la firma"

# Nace de montar ListaPrueba desde cero (2026-09-20): la verificación avisó de que había
# ficheros sin stagear, se le hizo caso con `git add -A`, y la firma pasó a ser «de OTRO
# diff». Lo stageado era exactamente el árbol recién probado: el commit llevaba MÁS de lo
# verificado, nunca algo distinto.
repo_base indice no ; conf indice 0
( cd "$TMP/indice" && echo uno > uno.txt && git add uno.txt ) >/dev/null 2>&1
codigo "$TMP/indice" >/dev/null
commit "$TMP/indice" commit -q -m base >/dev/null

( cd "$TMP/indice" && echo dos >> uno.txt ) >/dev/null 2>&1   # árbol sucio, nada stageado
S="$(salida "$TMP/indice")"                                    # se firma ASÍ
contiene "$S" "ÁRBOL SUCIO"; caso $? "el informe avisa de lo que falta por stagear"

( cd "$TMP/indice" && git add uno.txt ) >/dev/null 2>&1        # se le hace caso
C="$(codigo "$TMP/indice" --comprueba)"
igual "$C" 0; caso $? "stagear lo ya verificado NO invalida la firma ($C)"
C="$(commit "$TMP/indice" commit -q -m dos)"
igual "$C" 0; caso $? "y el commit pasa la puerta sin volver a verificar ($C)"

# `git commit -am` sobre el árbol firmado, sin editar nada después: se lleva exactamente lo
# que se verificó. Antes bloqueaba, porque stagear movía la huella.
( cd "$TMP/indice" && echo tres >> uno.txt ) >/dev/null 2>&1
codigo "$TMP/indice" >/dev/null
C="$(commit "$TMP/indice" commit -q -am tres)"
igual "$C" 0; caso $? "commit -am sin editar nada tras firmar pasa ($C)"

echo "▶ el índice con contenido que nadie verificó"

# El agujero que cierra `indice_divergente`, y que la huella doble dejaba abierto cuando se
# FIRMABA con el índice ya divergente: el commit se llevaba el índice, que nadie compiló.
( cd "$TMP/indice" && echo veneno > uno.txt && git add uno.txt \
    && printf 'uno\ndos\ntres\n' > uno.txt ) >/dev/null 2>&1
S="$(salida "$TMP/indice")"                                    # se firma con el índice así
contiene "$S" "ÍNDICE DIVERGENTE"; caso $? "el informe avisa al firmar con el índice divergente"
contiene "$S" "uno.txt"; caso $? "y nombra la ruta"

C="$(codigo "$TMP/indice" --comprueba)"
igual "$C" 1; caso $? "esa firma no vale para commitear ($C)" \
    "sin la comprobación del índice, la huella del árbol cuadra y pasa veneno"
S="$(salida "$TMP/indice" --comprueba)"
contiene "$S" "uno.txt"; caso $? "y --comprueba nombra la ruta divergente"

MSG="$( cd "$TMP/indice" && HOME="$TMP" git commit -q -m veneno 2>&1 )"
C="$( cd "$TMP/indice" && HOME="$TMP" git log --oneline -1 --format=%s 2>/dev/null )"
igual "$C" "tres"; caso $? "la puerta no deja crear ese commit (último: $C)"
contiene "$MSG" "uno.txt"; caso $? "y el mensaje de la puerta nombra la ruta"

# Y en cuanto el índice vuelve a ser el árbol, la MISMA firma vale: no hubo que reverificar.
( cd "$TMP/indice" && git add uno.txt ) >/dev/null 2>&1
C="$(codigo "$TMP/indice" --comprueba)"
igual "$C" 0; caso $? "con el índice puesto al día, la firma de antes vale ($C)"

echo "▶ la huella es una foto del árbol, no del índice"

# El caso que destapó la prueba de ListaPrueba: `/kit-init` escribe ficheros NUEVOS —kit.conf,
# openspec/, .claude/— y `git add -A` después de verificar los stagea. Con la huella del diff,
# eso movía la huella (un fichero nuevo no está en `git diff HEAD` hasta que se stagea) y
# obligaba a repetir la verificación entera.
repo_base foto no ; conf foto 0
( cd "$TMP/foto" && echo uno > uno.txt && git add uno.txt ) >/dev/null 2>&1
codigo "$TMP/foto" >/dev/null
commit "$TMP/foto" commit -q -m base >/dev/null

( cd "$TMP/foto" && echo nuevo > nuevo.txt ) >/dev/null 2>&1   # fichero NUEVO, sin stagear
codigo "$TMP/foto" >/dev/null                                   # se verifica ASÍ
( cd "$TMP/foto" && git add nuevo.txt ) >/dev/null 2>&1         # y se stagea después
C="$(codigo "$TMP/foto" --comprueba)"
igual "$C" 0; caso $? "stagear un fichero NUEVO ya verificado no invalida ($C)" \
    "con la huella del diff, un fichero nuevo entra en ella al stagearlo y obliga a reverificar"
C="$(commit "$TMP/foto" commit -q -m nuevo)"
igual "$C" 0; caso $? "y su commit pasa la puerta ($C)"

# Y al revés: crear un fichero DESPUÉS de firmar sí invalida. Con la huella del diff no lo
# hacía —un fichero sin trackear no sale en `git diff HEAD`—, así que se podía commitear
# código que nadie había compilado con solo crearlo tras verificar y stagearlo en el commit.
codigo "$TMP/foto" >/dev/null
( cd "$TMP/foto" && echo tarde > tarde.txt ) >/dev/null 2>&1
C="$(codigo "$TMP/foto" --comprueba)"
igual "$C" 1; caso $? "crear un fichero tras firmar invalida la firma ($C)" \
    "sin la foto del árbol, el código creado después de verificar entraba sin verificar"

# Lo que git ignora no está en la foto: si estuviera, cualquier artefacto de build invalidaría
# la firma en cuanto alguien compilara.
( cd "$TMP/foto" && rm tarde.txt && printf 'basura/\n' > .gitignore && git add .gitignore ) >/dev/null 2>&1
codigo "$TMP/foto" >/dev/null
( cd "$TMP/foto" && mkdir -p basura && echo x > basura/artefacto.o ) >/dev/null 2>&1
C="$(codigo "$TMP/foto" --comprueba)"
igual "$C" 0; caso $? "un fichero ignorado no invalida la firma ($C)"

# Borrar también es cambiar el árbol.
( cd "$TMP/foto" && rm nuevo.txt ) >/dev/null 2>&1
C="$(codigo "$TMP/foto" --comprueba)"
igual "$C" 1; caso $? "borrar un fichero tras firmar invalida la firma ($C)"

# Y la firma vive en .agent-kit/, que queda fuera de la foto lo ignore el proyecto o no: si
# entrara, escribir la firma invalidaría la firma que se acaba de escribir.
( cd "$TMP/foto" && git checkout -q -- . 2>/dev/null; echo nuevo > nuevo.txt ) >/dev/null 2>&1
C="$(codigo "$TMP/foto")"
igual "$C" 0; caso $? "verificar deja una firma que vale para el árbol que verificó ($C)"
C="$(codigo "$TMP/foto" --comprueba)"
igual "$C" 0; caso $? "y escribirla no se invalida a sí misma ($C)" \
    "con .agent-kit/ dentro de la foto, ninguna firma valdría nunca"

echo "▶ rutas y entradas que no son un fichero normal"

# Dos rondas del revisor (2026-09-20) sobre esto, y la segunda tumbó los casos de la primera:
# probaban la PRIMERA transición de la ruta —limpia→modificada, ausente→creada— y esa se
# detecta aunque el contenido no se hashee, porque lo que mueve la huella es que la ruta
# ENTRE en la lista. Lo que discrimina es firmar con la ruta YA cambiada y volver a cambiarla:
# si el contenido no entra en la foto, las dos fotos son idénticas y el veneno pasa.
#
# Por eso cada caso de aquí es de DOS pasos. Con la implementación que leía rutas de
# `git diff --name-only`, todos salen rojos; con la foto que hace git, todos pasan.
repo_base raras no ; conf raras 0
(
    cd "$TMP/raras" || exit 1
    printf 'uno\n' > "Diseño.swift"
    printf 'uno\n' > 'com"illa.swift'
    printf 'uno\n' > "$(printf 'tab\there.swift')"
    ln -s destino-uno enlace.swift
    git add -A
) >/dev/null 2>&1
codigo "$TMP/raras" >/dev/null
commit "$TMP/raras" commit -q -m base >/dev/null

# Paso 1: se cambia y se VERIFICA con el cambio dentro. Paso 2: se vuelve a cambiar.
( cd "$TMP/raras" && printf 'dos\n' > "Diseño.swift" ) >/dev/null 2>&1
codigo "$TMP/raras" >/dev/null
( cd "$TMP/raras" && printf 'veneno\n' > "Diseño.swift" ) >/dev/null 2>&1
C="$(codigo "$TMP/raras" --comprueba)"
igual "$C" 1; caso $? "una ruta con ñ, cambiada dos veces, invalida la firma ($C)" \
    "leyendo rutas de git diff, la citada no se hasheaba y los dos contenidos daban la misma huella"

( cd "$TMP/raras" && printf 'dos\n' > 'com"illa.swift' ) >/dev/null 2>&1
codigo "$TMP/raras" >/dev/null
( cd "$TMP/raras" && printf 'veneno\n' > 'com"illa.swift' ) >/dev/null 2>&1
C="$(codigo "$TMP/raras" --comprueba)"
igual "$C" 1; caso $? "una ruta con comillas, cambiada dos veces, invalida la firma ($C)" \
    "git la cita aunque core.quotePath esté apagado: apagarlo no bastaba"

( cd "$TMP/raras" && printf 'dos\n' > "$(printf 'tab\there.swift')" ) >/dev/null 2>&1
codigo "$TMP/raras" >/dev/null
( cd "$TMP/raras" && printf 'veneno\n' > "$(printf 'tab\there.swift')" ) >/dev/null 2>&1
C="$(codigo "$TMP/raras" --comprueba)"
igual "$C" 1; caso $? "una ruta con tabulador, cambiada dos veces, invalida la firma ($C)" \
    "git también la cita, y el tabulador además partía la lista al leerla"

# Un enlace simbólico ROTO: `[ -e ]` es falso, así que la implementación vieja lo daba por
# borrado y repuntarlo no movía nada. Lo que se firma es su destino, exista o no.
( cd "$TMP/raras" && rm enlace.swift && ln -s destino-roto enlace.swift ) >/dev/null 2>&1
codigo "$TMP/raras" >/dev/null
( cd "$TMP/raras" && rm enlace.swift && ln -s otro-destino enlace.swift ) >/dev/null 2>&1
C="$(codigo "$TMP/raras" --comprueba)"
igual "$C" 1; caso $? "repuntar un enlace roto tras firmar invalida la firma ($C)" \
    "con [ -e ] el enlace roto caía en BORRADO y su destino no entraba en la huella"

# Y lo que sigue valiendo: stagear cualquiera de estas rutas después de verificar.
( cd "$TMP/raras" && git add -A ) >/dev/null 2>&1
codigo "$TMP/raras" >/dev/null
( cd "$TMP/raras" && git add -A ) >/dev/null 2>&1
C="$(codigo "$TMP/raras" --comprueba)"
igual "$C" 0; caso $? "stagear rutas raras ya verificadas no invalida ($C)"

echo "▶ un submódulo"

# El submódulo es el caso realista del segundo RED: `[ -e Vendor ]` es cierto, pero
# `git hash-object Vendor` falla —es un directorio— y su puntero no entraba en la huella. Con
# la foto que hace git, el gitlink entra como lo que es: el commit al que apunta.
mkdir -p "$TMP/subfuente"
(
    cd "$TMP/subfuente" || exit 1
    git init -q . ; git config user.email t@t.t ; git config user.name t
    echo v1 > f ; git add -A ; git commit -qm v1
) >/dev/null 2>&1
repo_base consub no ; conf consub 0
( cd "$TMP/consub" && git -c protocol.file.allow=always submodule add -q "$TMP/subfuente" Vendor && git add -A ) >/dev/null 2>&1
codigo "$TMP/consub" >/dev/null
commit "$TMP/consub" commit -q -m consub >/dev/null

# En DOS pasos, como los de arriba: la PRIMERA subida se detecta aunque el puntero no entre
# en la huella, porque la ruta entra en la lista. Lo que discrimina es firmar con el submódulo
# ya subido y volver a subirlo.
sube_submodulo() {
    ( cd "$TMP/subfuente" && echo "$1" > f && git add -A && git commit -qm "$1"
      cd "$TMP/consub/Vendor" && git fetch -q origin && git checkout -q FETCH_HEAD ) >/dev/null 2>&1
}
sube_submodulo v2
codigo "$TMP/consub" >/dev/null                                    # firma con el submódulo YA en v2
sube_submodulo v3
C="$(codigo "$TMP/consub" --comprueba)"
igual "$C" 1; caso $? "subir el submódulo dos veces invalida la firma ($C)" \
    "git hash-object no puede con un directorio: el puntero del submódulo no entraba en la huella"
C="$(commit "$TMP/consub" commit -q -am sube)"
igual "$C" 1; caso $? "y la puerta no deja commitear esa subida ($C)" \
    "con el puntero fuera de la huella la firma valía, y el commit se llevaba un submódulo que nadie compiló"

echo "▶ cuando el árbol no se puede fotografiar"

# RED del revisor (2026-09-20, tercera vuelta), con reproducción: el valor de fallo era una
# CONSTANTE, así que si la causa seguía ahí —un fichero sin permiso de lectura, un filtro de
# .gitattributes sin instalar— la firma guardaba esa cadena, quien comprobaba recalculaba la
# misma, cuadraban, y la puerta dejaba pasar CUALQUIER árbol. Ahora: no se firma, el valor es
# irrepetible, y todo el que juzga mira el código de salida.
repo_base sinfoto no ; conf sinfoto 0
( cd "$TMP/sinfoto" && echo bueno > bueno.txt && git add -A ) >/dev/null 2>&1
codigo "$TMP/sinfoto" >/dev/null
commit "$TMP/sinfoto" commit -q -m base >/dev/null
codigo "$TMP/sinfoto" >/dev/null                      # firma válida del árbol limpio
C="$(codigo "$TMP/sinfoto" --comprueba)"
igual "$C" 0; caso $? "antes de romper nada, la firma vale ($C)"

( cd "$TMP/sinfoto" && echo secreto > ilegible.txt && chmod 000 ilegible.txt ) >/dev/null 2>&1
C="$(codigo "$TMP/sinfoto" --comprueba)"
igual "$C" 1; caso $? "sin poder fotografiar, --comprueba rechaza ($C)" \
    "con un valor de fallo constante, la firma vieja cuadraba y la puerta se abría"
C="$(commit "$TMP/sinfoto" commit -q -am nada)"
igual "$C" 1; caso $? "y la puerta bloquea el commit ($C)"

C="$(codigo "$TMP/sinfoto")"
igual "$C" 3; caso $? "verificar en ese estado sale 3 — «no pude mirar» ($C)"
S="$(salida "$TMP/sinfoto")"
contiene "$S" "no se pudo fotografiar"; caso $? "y el informe dice por qué"

# Lo que NO puede pasar: que esa corrida deje una firma. Si la dejara, el siguiente
# --comprueba recalcularía el mismo fallo y cuadraría consigo mismo.
M="$TMP/sinfoto/.agent-kit/verificacion.txt"
if grep -q "^diff: SIN-HUELLA" "$M" 2>/dev/null
then caso 1 "no escribe una firma de un árbol que no pudo mirar" \
        "la firma guardaba el valor de fallo, y después cuadraba consigo misma"
else caso 0 "no escribe una firma de un árbol que no pudo mirar"
fi

# Y al arreglar la causa, todo vuelve a su sitio.
( cd "$TMP/sinfoto" && chmod 644 ilegible.txt ) >/dev/null 2>&1
C="$(codigo "$TMP/sinfoto")"
igual "$C" 0; caso $? "arreglado el permiso, vuelve a firmar ($C)"
C="$(codigo "$TMP/sinfoto" --comprueba)"
igual "$C" 0; caso $? "y esa firma vale ($C)"

echo "▶ dos fotos a la vez, y una firma que dice que no pudo mirar"

# AMBER del revisor (cuarta vuelta): el caché es único por repositorio, y con dos fotos
# simultáneas —una sesión y un `git commit` en otra terminal, o el digest y la puerta— `git add`
# perdía el `index.lock`: 8 de 20 fallaban, y el perdedor rechazaba un commit legítimo culpando
# a un fichero ilegible que no existía. Ahora cada foto trabaja sobre su copia del índice.
repo_base concurrente no ; conf concurrente 0
( cd "$TMP/concurrente" && echo uno > uno.txt && git add -A ) >/dev/null 2>&1
codigo "$TMP/concurrente" >/dev/null
commit "$TMP/concurrente" commit -q -m base >/dev/null

PAR_FALLOS=0
for _ in 1 2 3 4 5; do
    ( cd "$TMP/concurrente" && HOME="$TMP/home" bash "$VER" --comprueba >"$TMP/c1" 2>&1 ) &
    ( cd "$TMP/concurrente" && HOME="$TMP/home" bash "$VER" --comprueba >"$TMP/c2" 2>&1 ) &
    wait
    grep -q "no se pudo fotografiar" "$TMP/c1" "$TMP/c2" 2>/dev/null && PAR_FALLOS=$((PAR_FALLOS+1))
done
igual "$PAR_FALLOS" 0; caso $? "dos comprobaciones a la vez no se estorban ($PAR_FALLOS de 5 con fallo)" \
    "con un índice de caché compartido, una de las dos perdía el lock y rechazaba un commit bueno"

# Y el caché no se queda con restos de esas copias.
# El home del BANCO, no el de quien lo corre: `codigo`/`salida` lanzan verifica con
# HOME="$TMP/home", así que sus copias viven ahí. Mirando el home real, el caso no veía lo suyo
# —mutar el `mv` a `cp` lo dejaba en verde— y sí veía restos ajenos, que ponían el banco en
# rojo por algo que no era del cambio. Lo cazó el revisor.
RESTOS="$(find "$TMP/home/.cache/ios-agent-kit/foto" -name 'indice.*' 2>/dev/null | wc -l | tr -d ' ')"
igual "$RESTOS" 0; caso $? "y no dejan copias del índice tiradas ($RESTOS)"

# Una foto que no llega a terminar —un Ctrl-C, una sesión que se cae— sí deja la suya, y nada
# la podaba: se acumulaban para siempre. Verificar las tira, pero solo las de más de una hora:
# una foto en marcha no puede quedarse sin la suya. Lo cazó el revisor.
# El directorio del caché de ESTE repo, calculado como lo calcula el kit: el sha de la raíz
# que dice git, que en macOS es la de `/private/var/...` y no la de `$TMP`.
CACHE_BANCO="$TMP/home/.cache/ios-agent-kit/foto/$(
    cd "$TMP/concurrente" && git rev-parse --show-toplevel | tr -d '\n' | shasum -a 256 | cut -c1-16)"
VIEJA="$CACHE_BANCO/indice.abcdef"
: > "$VIEJA" 2>/dev/null
touch -t 202001010000 "$VIEJA" 2>/dev/null
RECIENTE="$(dirname "$VIEJA")/indice.zzzzzz"
: > "$RECIENTE" 2>/dev/null
codigo "$TMP/concurrente" >/dev/null
if [ -e "$VIEJA" ]
then caso 1 "verificar tira las copias viejas que dejó una foto interrumpida" \
        "nada las podaba: se acumulaban y acababan poniendo el propio banco en rojo"
else caso 0 "verificar tira las copias viejas que dejó una foto interrumpida"
fi
existe "$RECIENTE"; caso $? "y no toca las recientes, que pueden ser de una foto en marcha"
rm -f "$RECIENTE" 2>/dev/null

# La otra mitad del RED de la tercera vuelta: una firma que GUARDA un valor de fallo no puede
# valer nunca. Aquí se escribe a mano, como la habría dejado una versión anterior del kit.
( cd "$TMP/concurrente" && echo secreto > ilegible.txt && chmod 000 ilegible.txt ) >/dev/null 2>&1
{ echo "verificado: 2026-09-20T00:00:00Z"
  echo "diff: SIN-HUELLA-no-se-pudo-fotografiar-el-arbol"
  echo "rama: main"
  echo "resultado: verde"; } > "$TMP/concurrente/.agent-kit/verificacion.txt"
C="$(codigo "$TMP/concurrente" --comprueba)"
igual "$C" 1; caso $? "una firma con un valor de FALLO guardado no vale ($C)" \
    "si ese valor fuera constante, se recalcularía igual, cuadraría, y cualquier árbol pasaría"
( cd "$TMP/concurrente" && chmod 644 ilegible.txt ) >/dev/null 2>&1

resumen "verifica.sh" "la-firma-no-caduca-por-stagear"
