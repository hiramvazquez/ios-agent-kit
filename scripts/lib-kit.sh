#!/usr/bin/env bash
# Piezas compartidas por los scripts del kit que corren DENTRO del repositorio de un
# proyecto. `lib-banco.sh` es el arnés de los bancos de pruebas; esto es para producción.
#
# No se carga solo: cada script hace `. "$DIR/lib-kit.sh"`, con `$DIR` resuelto ANTES de
# cambiar de directorio.

# cambio_activo — deja dos variables puestas:
#     ACTIVO     ruta del cambio OpenSpec activo, o vacío si no hay ninguno
#     ACTIVOS_N  cuántos hay
#
# Se llama SIN subshell —`cambio_activo` y luego `$ACTIVO`, nunca `$(cambio_activo)`— porque
# devuelve dos cosas y una sustitución de comandos se comería la segunda.
#
# Vive aquí porque la usan el hook de contexto y `rodaja.sh`, y copiada ya se cobró un fallo:
# cada copia elegía con `head -1` sobre un `find`, o sea por el orden del sistema de ficheros,
# así que con dos cambios abiertos el digest podía hablar de uno mientras la marca de revisión
# copiaba las tareas del otro.
#
# El orden lo fija `LC_ALL=C sort`, para que no dependa del sistema de ficheros ni del idioma
# de la máquina. Cuál es «el» activo cuando hay varios sigue siendo arbitrario, pero arbitrario
# y ESTABLE, y quien llama puede decir que hay más de uno en vez de callárselo.
cambio_activo() {
    ACTIVO=""
    ACTIVOS_N=0
    local d
    while IFS= read -r d; do
        [ -n "$d" ] || continue
        ACTIVOS_N=$((ACTIVOS_N + 1))
        [ -z "$ACTIVO" ] && ACTIVO="$d"
    done < <(find openspec/changes -maxdepth 1 -mindepth 1 -type d ! -name archive 2>/dev/null \
             | LC_ALL=C sort)
}

# huella_diff — el sha256 de lo que hay que firmar: el ÁRBOL DE TRABAJO **y** el ÍNDICE, los dos.
#
# LOS DOS, y cada uno cierra un agujero distinto:
#
#   - El ÁRBOL es lo que `verificaciones()` compila, y lo que se lleva un `git commit -a` o un
#     pathspec. Firmando solo el índice, verificar sin nada stageado firma el diff VACÍO y esa
#     firma sigue valiendo después de editar.
#   - El ÍNDICE es lo que se lleva un `git commit` a secas. Firmando solo el árbol, stagear
#     veneno y devolver el fichero a su contenido de HEAD deja la huella igual, y se commitea
#     algo que nunca se compiló.
#
# EL SEPARADOR TAMPOCO ES ADORNO: pegados sin marca, el hunk del último fichero por orden puede
# migrar del diff del árbol al del índice sin cambiar un byte, y la huella no se mueve.
#
# CONSECUENCIA ASUMIDA: stagear después de firmar cambia el índice y por tanto invalida la
# firma. Por eso stagear, verificar y commitear van en comandos separados. Es el lado correcto
# en el que equivocarse: lo contrario es dejar pasar contenido que nadie miró.
#
# Sin ningún commit todavía no hay `HEAD` con el que comparar —`git diff HEAD` falla—, y ahí el
# índice es la única referencia que existe.
#
# Vive aquí porque la usan `verifica.sh` —que firma— y el hook de contexto —que dice si la firma
# vale—: si las dos no dan el mismo número, el digest anuncia «la firma es de OTRO árbol» en
# cada turno de un árbol recién firmado.
huella_diff() {
    if git rev-parse --verify --quiet HEAD >/dev/null 2>&1; then
        { git diff HEAD; echo '--- índice ---'; git diff --cached; }
    else
        git diff --cached
    fi | shasum -a 256 | cut -d' ' -f1
}

# derivados_propios <raíz> — deja una variable puesta:
#     DD_PROPIO  array con los directorios de DerivedData que son de ESE repositorio
#
# Se llama SIN subshell, por lo mismo que `cambio_activo`: un array no sobrevive a una
# sustitución de comandos.
#
# POR QUÉ EXISTE. Sin acotar, un `find` sobre `~/Library/Developer/Xcode/DerivedData` devuelve
# los paquetes de TODOS los proyectos de la máquina, y el kit anuncia a un repositorio las
# dependencias de otro. Vive aquí y no copiada en los dos sitios que la usan —el hook de
# contexto y `doc-paquetes.sh`— porque copiarla ya dejó una de las dos sin arreglar.
#
# LA HEURÍSTICA, DECLARADA. Xcode nombra cada carpeta `<Proyecto>-<hash>`, donde `<Proyecto>`
# es el nombre del `.xcodeproj` o `.xcworkspace` — un dato que no se tiene sin abrir el
# proyecto. Se aproxima con el nombre del directorio del repositorio, que coincide en el caso
# común: clonar y abrir sin renombrar la carpeta.
#
# QUÉ SE PIERDE, en tres formas y NO todas seguras:
#
#   (a) Falso negativo si el `.xcodeproj` se llama distinto de la carpeta que lo contiene —un
#       monorepo, una carpeta renombrada—: no encuentra su propio DerivedData y se calla.
#       Este sí es el lado seguro del error.
#
#   (b) Dos repositorios con el mismo nombre de carpeta comparten el filtro; Xcode los
#       distingue por el hash y esto no.
#
#   (c) **Y este NO es seguro, así que va escrito y no disimulado:** el hash de Xcode no está
#       restringido en el patrón, así que un proyecto cuyo nombre EMPIECE por el tuyo más un
#       guion casa igual. Un repositorio llamado `spm` recibe lo de `spm-pro-<hash>`. Acotarlo
#       de verdad —exigir la forma del hash, o leer el `info.plist` de cada carpeta— es otra
#       decisión con su propia medición. Lo que no se puede es seguir diciendo por ahí que
#       «falla hacia el lado seguro», porque en (c) no lo hace.
#
# `nullglob` hace que, sin ninguna carpeta que case, el array quede VACÍO en vez de con el
# patrón literal. Quien lo use debe expandirlo con `${DD_PROPIO[@]+"${DD_PROPIO[@]}"}`: en bash
# 3.2 expandir `"${arr[@]}"` de un array vacío bajo `set -u` es «unbound variable» y aborta el
# script entero, y `"${arr[@]:-}"` pasa un argumento vacío que no todo `find` tiene por qué
# tolerar.
derivados_propios() {
    local proyecto="${1##*/}" _ng
    # Se RESTAURA el estado previo en vez de apagarlo: un `shopt -u` incondicional destruye el
    # `nullglob` de quien llame, y `shopt -p` imprime justo el comando que lo deja como estaba.
    _ng="$(shopt -p nullglob)"
    shopt -s nullglob
    # SC2034: shellcheck no ve el uso porque está en los scripts que cargan esta lib, no aquí.
    # `cambio_activo` no lo necesita porque lee `ACTIVO` dentro de su propio bucle.
    # shellcheck disable=SC2034
    DD_PROPIO=("$HOME/Library/Developer/Xcode/DerivedData/${proyecto}-"*)
    eval "$_ng"
}
