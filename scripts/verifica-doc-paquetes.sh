#!/usr/bin/env bash
# Banco de pruebas de `doc-paquetes.sh`.
#
# Por qué existe: era el único script de producción del kit sin banco, y no es coincidencia
# que fuera también el único con una rama muerta. Su `find` de `.build/checkouts` llevaba un
# `-depth 1` que en el `find` de BSD (macOS) significa profundidad EXACTAMENTE 1,
# incompatible con un `-path "*/.build/checkouts/*"` que necesita profundidad ≥3: la
# condición era insatisfacible y esa rama nunca devolvió nada. Un proyecto SwiftPM puro —el
# que resuelve con `swift build` y no abre Xcode— recibía «Sin paquetes resueltos todavía»
# teniéndolos resueltos. Comprobado el 2026-09-08 montando un `.build/checkouts/MiPaquete/`
# con su `Package.swift` y su `AGENTS.md`: no aparecía.
#
# También llevaba la misma guarda muerta que `rodaja.sh`: `cd "$(git rev-parse …)" || …` no
# dispara fuera de un repo porque `cd ""` devuelve 0 en bash.
#
# Uso:  bash scripts/verifica-doc-paquetes.sh
#       DOC_BAJO_PRUEBA=<ruta> bash scripts/verifica-doc-paquetes.sh   ← contra otra versión
#
# Para comprobar que los casos que fijan el fallo salen en rojo por lo que dicen y no por otra
# cosa (hoy son los del acotado, no el primero — decía «el primero» y era falso):
#
#   git show HEAD:scripts/doc-paquetes.sh > /tmp/doc-viejo.sh
#   DOC_BAJO_PRUEBA=/tmp/doc-viejo.sh bash scripts/verifica-doc-paquetes.sh
set -uo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
. "$DIR/lib-banco.sh"

DOC="${DOC_BAJO_PRUEBA:-$DIR/doc-paquetes.sh}"
[ -f "$DOC" ] || { echo "no encuentro doc-paquetes.sh en $DOC"; exit 2; }

# --- montaje ------------------------------------------------------------------------------

# paquete_resuelto <repo> <nombre>   → un .build/checkouts/<nombre> con Package.swift y AGENTS.md
paquete_resuelto() {
    local r="$1" nombre="$2"
    mkdir -p "$r/.build/checkouts/$nombre"
    echo "// swift-tools-version:5.9" > "$r/.build/checkouts/$nombre/Package.swift"
    echo "# reglas de $nombre" > "$r/.build/checkouts/$nombre/AGENTS.md"
}

# doc <repo>   → la salida de doc-paquetes.sh sobre ese repo
#
# `HOME` apunta a un directorio del propio `$TMP`, para que el banco no salga a mirar el
# `DerivedData` REAL de la máquina donde corre: eso dejaría de medir el código para medir la
# máquina.
#
# Aquí ponía además que acotar esa búsqueda era «harina de otro costal (el hook de contexto, no
# este script)», y que ese `HOME` estaba vacío. Las dos cosas dejaron de ser ciertas en el
# mismo cambio: acotarla aquí es exactamente lo que ese cambio hace, y el `HOME` monta ahora
# los DerivedData de prueba que lo miden. El nombre `home-vacio` se queda como recordatorio.
doc() { ( cd "$1" && HOME="$TMP/home-vacio" bash "$DOC" 2>&1 ); }

mkdir -p "$TMP/home-vacio"

# EL HOME DE PRUEBA YA NO ESTÁ VACÍO, y esa es la corrección que trae este banco.
#
# Fijarlo a un temporal sin nada dentro dejaba la rama de DerivedData sin ejercitar NUNCA, así
# que el banco estaba ciego a que ese `find` no estuviera acotado. Lo estuvo, y `/kit-doc`
# anunció durante toda la 1.8.0 los paquetes de otros proyectos de la máquina — medido en
# `spm-pro` e `iOSandbox`, que recibían los de `AppStarter`.
#
# Es exactamente lo que el proposal de `donde-la-regla-solo-llego-a-un-hermano` escribió sobre
# el banco del hook —«su caso de aislamiento pasaba por el fixture, no por el código»—
# reproducido en el banco que ese mismo cambio creó. El nombre `home-vacio` se queda como
# recordatorio de lo que fue.
#
# `monta_derivados <carpeta> <paquete>` los monta todos; la carpeta es lo que decide de quién
# es. Aquí iban dos nombres de función que nunca existieron —se escribieron al diseñar y se
# implementó una sola—; lo cazó el juez de aceptación haciendo `grep`.
DD="$TMP/home-vacio/Library/Developer/Xcode/DerivedData"
monta_derivados() {   # monta_derivados <carpeta-de-DerivedData> <paquete>
    mkdir -p "$DD/$1/SourcePackages/checkouts/$2"
    echo "// swift-tools-version:5.9" > "$DD/$1/SourcePackages/checkouts/$2/Package.swift"
    echo "# reglas de $2" > "$DD/$1/SourcePackages/checkouts/$2/AGENTS.md"
}
monta_derivados OtroProyecto-abc123def456 PaqueteAjeno

# Y uno cuyo nombre empieza por el de un repo del banco PERO SIN el guion: `vacioextra-…`, no
# `vacio-extra-…`. La diferencia es el caso entero.
#
# Sin este fixture, el patrón `${proyecto}*` —el mismo sin el guion— pasaba el banco ENTERO en
# verde, y con él un repo llamado `App` se llevaría lo de `AppStarter-<hash>`. Lo midió el
# revisor mutando la lib. (Aquí ponía un recuento de casos a mano, y había caducado para
# cuando el juez lo miró: el banco cuenta los suyos, un comentario no.) El fixture anterior solo distinguía `vacio` de `OtroProyecto`, dos
# nombres sin relación ninguna: medía lo fácil.
#
# Y tiene que ser SIN guion, porque `vacio-extra-…` casa también con el patrón correcto: ese es
# el límite (c) declarado en `lib-kit.sh`, que este cambio deja abierto a propósito. Un caso
# escrito así no probaría el mutante, probaría el agujero que no se arregla — y saldría rojo
# contra el código bueno. Se escribió así primero, y el banco lo devolvió.
monta_derivados vacioextra-99887766 PaqueteDePrefijo

repo_base con_paquete no
paquete_resuelto "$TMP/con_paquete" MiPaquete

repo_base vacio no

# Un repositorio cuyo DerivedData SÍ es suyo: Xcode lo nombra `<Proyecto>-<hash>`.
repo_base con_derivados no
monta_derivados con_derivados-f00ba7cafe PaquetePropio

# Un paquete con paquetes DENTRO. `swift-syntax` es el caso real: trae `CodeGeneration/` y
# `SwiftParserCLI/`, cada uno con su `Package.swift`. Sin acotar la profundidad, los tres se
# anuncian como dependencias del proyecto — y el banco no lo veía porque todos sus fixtures
# eran paquetes planos.
repo_base anidado no
paquete_resuelto "$TMP/anidado" swift-syntax
mkdir -p "$TMP/anidado/.build/checkouts/swift-syntax/CodeGeneration"
echo "// swift-tools-version:5.9" > "$TMP/anidado/.build/checkouts/swift-syntax/CodeGeneration/Package.swift"

# --- los casos ------------------------------------------------------------------------------

echo "▶ el sitio que la cabecera promete y la rama muerta nunca miraba"

S="$(doc "$TMP/con_paquete")"
if contiene "$S" "MiPaquete" && contiene "$S" "AGENTS.md"; then
    caso 0 "un paquete resuelto en .build/checkouts del repo aparece, con su AGENTS.md, sin DerivedData por medio"
else
    caso 1 "un paquete resuelto en .build/checkouts del repo aparece, con su AGENTS.md, sin DerivedData por medio" \
        "el -depth 1 del find (BSD) exige profundidad exactamente 1, incompatible con -path .../checkouts/*: la rama nunca devolvía nada"
fi

S="$(doc "$TMP/anidado")"
if contiene "$S" "swift-syntax" && ! contiene "$S" "CodeGeneration"; then
    caso 0 "un paquete con paquetes dentro se cuenta UNA vez, no una por subdirectorio"
else
    caso 1 "un paquete con paquetes dentro se cuenta UNA vez, no una por subdirectorio" \
        "-path '*/checkouts/*' casa tambien con lo de DENTRO del checkout: tres directorios internos de swift-syntax salian como tres dependencias"
fi

# Aquí había un caso aparte —«un repositorio sin nada resuelto en ningún sitio recibe el
# mensaje, no una lista vacía»— y se ha fundido con el de abajo, que afirma eso Y que tampoco
# recibe los de un proyecto de otro nombre. Al dejar de estar vacío el HOME de prueba, su premisa («en ningún
# sitio») dejó de describir a su propio fixture: ahora hay paquetes en la máquina, solo que no
# son suyos. Dos aserciones sobre el mismo escenario, y una con la premisa caducada.

echo "▶ los paquetes anunciados se acotan al prefijo del repositorio"

S="$(doc "$TMP/vacio")"
if contiene "$S" "Sin paquetes resueltos todavía" && ! contiene "$S" "PaqueteAjeno"; then
    caso 0 "un repo sin dependencias propias recibe el mensaje, y no las de OTRO nombre"
else
    caso 1 "un repo sin dependencias propias recibe el mensaje, y no las de OTRO nombre" \
        "el find recorria TODO el DerivedData sin filtrar: spm-pro recibia los paquetes de AppStarter"
fi

# El vecino de PREFIJO, aparte del vecino sin relación: son dos formas distintas de colarse y
# solo la segunda la cazaba el fixture anterior.
if contiene "$S" "PaqueteDePrefijo"; then
    caso 1 "un repo cuyo nombre es prefijo de otro SIN guion no recibe los de aquel" \
        "sin el guion en el patron, un repo 'App' se llevaria lo de 'AppStarter-<hash>'"
else
    caso 0 "un repo cuyo nombre es prefijo de otro SIN guion no recibe los de aquel"
fi

# La otra mitad, y no es redundante: sin este caso, un mutante que borrase la rama de
# DerivedData entera pasaría el de arriba con nota.
S="$(doc "$TMP/con_derivados")"
if contiene "$S" "PaquetePropio" && ! contiene "$S" "PaqueteAjeno"; then
    caso 0 "un repo con DerivedData propio SI recibe los suyos, y no los de OTRO nombre"
else
    caso 1 "un repo con DerivedData propio SI recibe los suyos, y no los de OTRO nombre" \
        "acotar de mas: dejaria a los proyectos de Xcode sin la doc de sus dependencias"
fi

echo "▶ fuera de un repositorio git"

FUERA="$TMP/fuera-de-repo"; mkdir -p "$FUERA"
ANTES="$(ls -A "$FUERA")"
S="$( cd "$FUERA" && HOME="$TMP/home-vacio" bash "$DOC" 2>&1 )"
COD=$?
if contiene "$S" "no es un repo git" && [ "$COD" -ne 0 ]; then
    caso 0 "invocado fuera de un repositorio git, lo dice y sale con código distinto de 0"
else
    caso 1 "invocado fuera de un repositorio git, lo dice y sale con código distinto de 0" \
        "cd \"\$(git rev-parse …)\" || … no dispara: cd \"\" devuelve 0 en bash, y seguía sin decir nada"
fi

DESPUES="$(ls -A "$FUERA")"
[ "$ANTES" = "$DESPUES" ]; caso $? \
    "y no deja nada escrito en el directorio desde el que se le invocó"

resumen "doc-paquetes.sh" "el-hermano-que-quedaba"
