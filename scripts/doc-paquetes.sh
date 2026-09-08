#!/usr/bin/env bash
# Localiza la documentación de los paquetes de los que depende este proyecto.
#
# EL PROBLEMA QUE RESUELVE. Un SPM propio bien documentado —AGENTS.md, DocC, ejemplos,
# plantillas de skill— es invisible desde el proyecto que lo consume. Se declara por URL
# (`.package(url: ...)`), así que sus fuentes acaban en `.build/checkouts/` o en
# `DerivedData/.../SourcePackages/checkouts/`: dos sitios que están en `.gitignore`, que no
# existen hasta que alguien resuelve o compila, y que cualquiera —persona o agente— trata
# como ruido de build y salta.
#
# El resultado observado es que el AGENTS.md del proyecto remite a rutas como
# `Sources/AppFoundation/Documentation.docc/`, que NO existen desde la raíz del repo. La
# doc está escrita, es buena, y nadie la lee: no por desobediencia, por geografía.
#
# Esto imprime las rutas que existen AHORA MISMO, resueltas. Nada más. No resume la doc ni
# la inyecta: un digest de documentación ajena envejece y miente. Da direcciones.
set -uo pipefail
# `cd "$(git rev-parse …)" || …` NO dispara fuera de un repo: `cd ""` devuelve 0 en bash, así
# que la guarda nunca ve el fallo de git y este script seguiría buscando `.build/checkouts` a
# partir de donde se le invoque. La asignación SÍ propaga el código de git —`verifica.sh` ya
# lo hace así—, así que se comprueba la resolución, no el `cd`.
RAIZ="$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "no es un repo git"; exit 1; }
cd "$RAIZ" || exit 1

# Los dos sitios donde SPM deja las fuentes resueltas, más las dependencias por ruta local.
CHECKOUTS=()
while IFS= read -r d; do CHECKOUTS+=("$d"); done < <(
    # `-depth 1` en el `find` de BSD (macOS) significa profundidad EXACTAMENTE 1, incompatible
    # con `-path "*/.build/checkouts/*"` (necesita profundidad ≥3): la condición era
    # insatisfacible y esa rama nunca devolvió nada. Comprobado el 2026-09-08 montando
    # `.build/checkouts/MiPaquete/` con su `Package.swift` y su `AGENTS.md`: no aparecía.
    #
    # El `! -path ".../*/*"` es lo que impide que quitarlo ensanche de más, y no es teórico:
    # `-path "*/.build/checkouts/*"` casa también con los subdirectorios DE DENTRO de un
    # checkout, así que cualquier `Package.swift` anidado se anunciaba como dependencia del
    # proyecto. Medido el 2026-09-08 con el layout real de `swift-syntax`, que trae
    # `CodeGeneration/` y `SwiftParserCLI/` con el suyo: tres directorios internos de UN
    # paquete listados como tres dependencias. Lo encontró el revisor; la primera versión de
    # este arreglo afirmaba en este mismo comentario que no ensanchaba, y era falso.
    #
    # Es lo que la rama de DerivedData de abajo ya consigue con su `-maxdepth 1 -mindepth 1`:
    # quedarse en el nivel del checkout y no bajar.
    find . -maxdepth 5 -type d -path "*/.build/checkouts/*" \
         ! -path "*/.build/checkouts/*/*" 2>/dev/null
    find "$HOME/Library/Developer/Xcode/DerivedData" -maxdepth 3 -type d \
         -name checkouts -path "*SourcePackages*" 2>/dev/null \
      | while read -r c; do find "$c" -maxdepth 1 -mindepth 1 -type d; done
)

if [ ${#CHECKOUTS[@]} -eq 0 ]; then
    cat <<'VACIO'
Sin paquetes resueltos todavía.

Las fuentes de las dependencias aparecen después de resolver o compilar. Corre el build
del proyecto (o `swift package resolve` en el paquete que las declara) y vuelve a probar.
VACIO
    exit 0
fi

# Un mismo paquete puede estar resuelto en dos sitios (SwiftPM y Xcode). Se muestra uno.
declare -a VISTOS=()
ya_visto() { local n; for n in ${VISTOS[@]+"${VISTOS[@]}"}; do [ "$n" = "$1" ] && return 0; done; return 1; }

# Se separa por si el paquete trae AGENTS.md, y no por si es "tuyo".
#
# Es el único criterio que se sostiene sin una lista escrita a mano que envejezca: un
# AGENTS.md dice que alguien escribió instrucciones PARA UN AGENTE sobre ese código. Sin él,
# lo que hay es documentación de usuario, útil pero de otra clase. En la prueba real esto
# separaba AppFoundation y CoreNetworking de swift-syntax y compañía, que ocupaban diez
# veces más pantalla sin aportar una regla que seguir.
CON_INSTRUCCIONES=""
SIN=""

for dir in ${CHECKOUTS[@]+"${CHECKOUTS[@]}"}; do
    nombre="$(basename "$dir")"
    ya_visto "$nombre" && continue
    [ -f "$dir/Package.swift" ] || continue
    VISTOS+=("$nombre")

    if [ ! -f "$dir/AGENTS.md" ]; then
        SIN="${SIN}${nombre} "
        continue
    fi

    B="── $nombre"$'\n'"   (raíz: $dir)"$'\n'
    B="${B}   AGENTS.md      ← las reglas de ESE paquete; léelo antes de usar sus tipos"$'\n'
    [ -f "$dir/README.md" ]    && B="${B}   README.md"$'\n'
    [ -f "$dir/CHANGELOG.md" ] && B="${B}   CHANGELOG.md   ← qué cambió entre versiones"$'\n'

    # DocC: los artículos son la referencia de verdad (reglas de lint, arquitectura, FAQ).
    while IFS= read -r docc; do
        [ -n "$docc" ] || continue
        arts="$(find "$docc" -maxdepth 1 -name '*.md' -exec basename {} .md \; | sort | tr '\n' ' ')"
        B="${B}   ${docc#$dir/}"$'\n'"      $arts"$'\n'
    done < <(find "$dir/Sources" -maxdepth 3 -type d -name "*.docc" 2>/dev/null)

    # Plantillas de skill: existen para copiarse al proyecto consumidor.
    while IFS= read -r sk; do
        [ -n "$sk" ] && B="${B}   ${sk#$dir/}   ← plantilla, pensada para copiarse"$'\n'
    done < <(find "$dir" -maxdepth 2 \( -name "*.skill.md" -o -name "SKILL.md" \) 2>/dev/null)

    # Ejemplos: código que ya resuelve el caso, mejor referencia que la prosa.
    ej="$(find "$dir/Examples" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | sort | xargs -n1 basename 2>/dev/null | tr '\n' ' ')"
    [ -n "$ej" ] && B="${B}   Examples/      $ej"$'\n'

    CON_INSTRUCCIONES="${CON_INSTRUCCIONES}${B}"$'\n'
done

if [ -n "$CON_INSTRUCCIONES" ]; then
    echo "PAQUETES CON INSTRUCCIONES PARA AGENTES (traen AGENTS.md):"
    echo
    printf '%s' "$CON_INSTRUCCIONES"
else
    echo "Ninguna dependencia trae AGENTS.md."
    echo
fi

[ -n "$SIN" ] && { echo "Resto de dependencias (doc de usuario, sin instrucciones): $SIN"; echo; }

cat <<'COLA'
Cómo usarlo: son rutas de solo lectura, léelas con Read/grep como cualquier fichero. Si el
AGENTS.md del proyecto cita un artículo por nombre ("el artículo Lint de DocC"), está aquí.

Ojo: son las rutas de la versión RESUELTA hoy. Si el proyecto sube la versión del paquete,
cambian — no las copies a ningún fichero del repo, vuelve a preguntar.
COLA
