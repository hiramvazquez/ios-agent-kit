#!/usr/bin/env bash
# Banco de pruebas de `doc-paquetes.sh`.
# Por qué existe: es el script que dice qué paquetes tiene resueltos el proyecto, y sus dos
# ramas —`.build/checkouts` y `DerivedData`— solo se miden montándolas.
#
# Uso:  bash scripts/verifica-doc-paquetes.sh
#       DOC_BAJO_PRUEBA=<ruta> bash scripts/verifica-doc-paquetes.sh   ← contra otra versión
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
# máquina. El nombre `home-vacio` es solo el del directorio: debajo se montan los DerivedData
# de prueba.
doc() { ( cd "$1" && HOME="$TMP/home-vacio" bash "$DOC" 2>&1 ); }

mkdir -p "$TMP/home-vacio"

# El HOME de prueba lleva DerivedData de OTROS proyectos: con un temporal sin nada dentro la
# rama de DerivedData no se ejercita nunca, y el banco queda ciego a que ese `find` no esté
# acotado al repositorio.
#
# `monta_derivados <carpeta> <paquete>` los monta todos; la carpeta es lo que decide de quién
# es.
DD="$TMP/home-vacio/Library/Developer/Xcode/DerivedData"
monta_derivados() {   # monta_derivados <carpeta-de-DerivedData> <paquete>
    mkdir -p "$DD/$1/SourcePackages/checkouts/$2"
    echo "// swift-tools-version:5.9" > "$DD/$1/SourcePackages/checkouts/$2/Package.swift"
    echo "# reglas de $2" > "$DD/$1/SourcePackages/checkouts/$2/AGENTS.md"
}
monta_derivados OtroProyecto-abc123def456 PaqueteAjeno

# Y uno cuyo nombre empieza por el de un repo del banco PERO SIN el guion: `vacioextra-…`, no
# `vacio-extra-…`. Sin este fixture, el patrón `${proyecto}*` —el mismo sin el guion— pasa el
# banco entero en verde, y con él un repo llamado `App` se llevaría lo de `AppStarter-<hash>`.
# Distinguir `vacio` de `OtroProyecto`, dos nombres sin relación ninguna, es medir lo fácil.
#
# Tiene que ser SIN guion, porque `vacio-extra-…` casa también con el patrón correcto: ese es
# el límite (c) declarado en `lib-kit.sh`, que queda abierto a propósito. Un caso escrito con
# guion no probaría el mutante, probaría el agujero que no se arregla — y saldría rojo contra
# el código bueno.
monta_derivados vacioextra-99887766 PaqueteDePrefijo

repo_base con_paquete no
paquete_resuelto "$TMP/con_paquete" MiPaquete

repo_base vacio no

# Un repositorio cuyo DerivedData SÍ es suyo: Xcode lo nombra `<Proyecto>-<hash>`.
repo_base con_derivados no
monta_derivados con_derivados-f00ba7cafe PaquetePropio

# Un paquete con paquetes DENTRO. `swift-syntax` es el caso real: trae `CodeGeneration/` y
# `SwiftParserCLI/`, cada uno con su `Package.swift`. Sin acotar la profundidad, los tres se
# anunciarían como dependencias del proyecto.
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

echo "▶ los paquetes anunciados se acotan al prefijo del repositorio"

S="$(doc "$TMP/vacio")"
if contiene "$S" "Sin paquetes resueltos todavía" && ! contiene "$S" "PaqueteAjeno"; then
    caso 0 "un repo sin dependencias propias recibe el mensaje, y no las de OTRO nombre"
else
    caso 1 "un repo sin dependencias propias recibe el mensaje, y no las de OTRO nombre" \
        "el find recorria TODO el DerivedData sin filtrar: spm-pro recibia los paquetes de AppStarter"
fi

# El vecino de PREFIJO, aparte del vecino sin relación: son dos formas distintas de colarse.
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
