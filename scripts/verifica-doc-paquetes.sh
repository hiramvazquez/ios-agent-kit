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
# Para comprobar que el primer caso está en rojo por lo que dice y no por otra cosa:
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
# `HOME` apunta a un directorio vacío del propio `$TMP`, sin `DerivedData` dentro. Sin esto,
# el banco saldría a mirar el `DerivedData` REAL de la máquina donde corre —lo mismo que
# `doc-paquetes.sh` hace sin acotar—, y el caso dejaría de medir el código para medir la
# máquina. Acotar esa búsqueda es harina de otro costal (el hook de contexto, no este
# script): aquí solo se neutraliza para poder medir el `.build/checkouts` en aislamiento.
doc() { ( cd "$1" && HOME="$TMP/home-vacio" bash "$DOC" 2>&1 ); }

mkdir -p "$TMP/home-vacio"

repo_base con_paquete no
paquete_resuelto "$TMP/con_paquete" MiPaquete

repo_base vacio no

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

echo "▶ lo que ya funcionaba, y no puede romperse"

S="$(doc "$TMP/vacio")"
contiene "$S" "Sin paquetes resueltos todavía"; caso $? \
    "un repositorio sin nada resuelto en ningún sitio recibe el mensaje, no una lista vacía"

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

resumen "doc-paquetes.sh" "donde-la-regla-solo-llego-a-un-hermano"
