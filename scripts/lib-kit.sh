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
