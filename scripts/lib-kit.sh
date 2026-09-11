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
# Se llama SIN subshell —`cambio_activo` y luego `$ACTIVO`, nunca `$(cambio_activo)`—
# porque devuelve dos cosas y una sustitución de comandos se comería la segunda.
#
# POR QUÉ EXISTE. Esta resolución estaba copiada en tres sitios —el hook que inyecta el
# contexto y dos puntos de `rodaja.sh`— y las tres elegían con `head -1` sobre un `find`:
# es decir, por el orden en que el sistema de ficheros devolvía las entradas. Con dos
# cambios abiertos, el digest podía hablar de uno mientras la marca de revisión copiaba las
# tareas del otro, y nada lo decía.
#
# Era además el ÚNICO duplicado real del bash del kit, medido el 2026-09-08. El comando con
# el que se vuelve a medir está en `kit.conf`, junto a `FUENTES`; el tamaño del repo de aquel
# día no está escrito en ningún sitio, y eso es deliberado — se cuenta al leer. Que fuera justo este tiene su gracia: la regla que este
# mismo kit inyecta en cada turno —«antes de escribir una función, busca si ya existe»— se
# escribió mientras esto se copiaba por tercera vez.
#
# El orden se fija con `LC_ALL=C sort`, para que no dependa del sistema de ficheros ni del
# idioma de la máquina. Cuál es «el» activo cuando hay varios sigue siendo arbitrario, pero
# arbitrario y ESTABLE, y quien llama puede decir que hay más de uno en vez de callárselo.
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
#   - El ÁRBOL, porque es lo que `verificaciones()` compila y porque es lo que se commitea con
#     `git commit -a` o con un pathspec. Firmando solo el índice, verificar sin nada stageado
#     firmaba el diff VACÍO y esa firma seguía valiendo después de editar: `git commit -am`
#     metía código sin verificar. Reproducido el 2026-09-11.
#   - El ÍNDICE, porque un `git commit` a secas commitea el índice y no el árbol. Firmando solo
#     el árbol, stagear veneno y devolver el fichero a su contenido de HEAD deja la huella
#     igual —`git diff HEAD` no ve el índice— y se commitea algo que nunca se compiló. Lo
#     reprodujo el revisor el 2026-09-11, de punta a punta, sobre la versión que firmaba solo
#     el árbol.
#
# CONSECUENCIA ASUMIDA: stagear después de firmar cambia el índice y por tanto la huella, así
# que invalida la firma. Por eso stagear, verificar y commitear van en comandos separados. Es
# molesto y es el lado correcto en el que equivocarse: lo contrario es dejar pasar contenido
# que nadie miró.
#
# EL SEPARADOR NO ES ADORNO. Pegados sin marca, el punto de corte entre los dos diffs no existe
# para el `shasum`, y el hunk del último fichero por orden puede migrar del diff del árbol al del
# índice sin cambiar un byte: se stagea ese fichero y se devuelve al contenido de HEAD, y la
# huella no se mueve. Lo reprodujo el revisor el 2026-09-11 sobre la primera versión de esta
# función. Lo que se alcanzaba así era commitear un SUBCONJUNTO de lo verificado —no contenido
# nuevo, porque los bytes que migran tienen que ser idénticos—, pero la norma promete que un
# cambio posterior a la firma la invalida, y sin separador eso era falso.
#
# Sin ningún commit todavía no hay `HEAD` con el que comparar —`git diff HEAD` falla—, y ahí el
# índice es la única referencia que existe.
#
# Vive aquí porque la usan `verifica.sh` —que firma— y el hook de contexto —que dice si la firma
# vale—. Si las dos no dan el mismo número, el digest anuncia «la firma es de OTRO árbol» en
# cada turno de un árbol recién firmado. Estaba escrita dos veces.
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
# los paquetes de TODOS los proyectos de la máquina. El hook de contexto lo arregló en
# `donde-la-regla-solo-llego-a-un-hermano`… y `doc-paquetes.sh`, que hace la misma búsqueda, se
# quedó sin arreglar en ese mismo cambio. Medido el 2026-09-08 con la 1.8.0 ya publicada:
# `spm-pro` e `iOSandbox`, sin dependencias propias resueltas, recibían las de `AppStarter`.
#
# Vive aquí y no copiada en los dos sitios porque copiarla es exactamente la clase de defecto
# que la dejó a medias, y la que ya se cobró un fallo con `cambio_activo` — la regla que este
# kit inyecta en cada turno dice «antes de escribir una función, busca si ya existe».
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
#       guion casa igual. Un repositorio llamado `spm` recibe lo de `spm-pro-<hash>`. Es el
#       mismo fallo que esta función existe para cerrar, entrando por la puerta de al lado.
#       Reproducido el 2026-09-08 por el revisor.
#
#       Se declara en vez de arreglarse porque acotarlo de verdad —exigir la forma del hash,
#       o leer el `info.plist` de cada carpeta— es otra decisión con su propia medición, y
#       este cambio ya declaró fuera de alcance tocar la heurística. Lo que no se puede es
#       seguir diciendo por ahí que «falla hacia el lado seguro», porque en (c) no lo hace.
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
    # Hoy ningún llamador lo tiene puesto —lo comprobó el revisor—, así que esto no arregla un
    # fallo: cierra una trampa para el que venga.
    _ng="$(shopt -p nullglob)"
    shopt -s nullglob
    # SC2034: shellcheck no ve el uso porque está en los scripts que cargan esta lib, no aquí.
    # `cambio_activo` no lo necesita porque lee `ACTIVO` dentro de su propio bucle.
    # shellcheck disable=SC2034
    DD_PROPIO=("$HOME/Library/Developer/Xcode/DerivedData/${proyecto}-"*)
    eval "$_ng"
}
