## Context

Ver `proposal.md` — Why. Lo que condiciona el cómo:

- Git ejecuta `pre-commit` con el directorio de trabajo en la raíz del árbol y antes de crear
  el commit; con `-a` o un pathspec, el índice ya está actualizado (o es un índice temporal
  en `GIT_INDEX_FILE`) cuando corre el hook. Eso hace que «la huella del índice cambió» se
  detecte sola, sin analizar nada.
- El directorio de hooks lo da `git rev-parse --git-path hooks`, que respeta `core.hooksPath`
  y los worktrees.
- La herramienta Bash de Claude Code conserva el directorio entre llamadas y lo devuelve al
  proyecto si un `cd` sale de él, pero el comando que sale sí se ejecuta entero: por eso un
  `cd ~/otro && git commit` commitea en el otro repositorio. Un hook de git lo ve; un
  analizador del texto tenía que adivinarlo.
- `huella_diff` es una función de bash: `declare -f huella_diff` imprime su definición tal
  cual, así que el hook se puede generar con la definición del kit sin copiarla a mano.

## Goals / Non-Goals

**Goals:**
- Que la puerta no tenga que entender el comando. Cero análisis sintáctico.
- Que la huella siga definida una sola vez.
- Que un proyecto con un hook propio no se rompa.

**Non-Goals:**
- Mantener el `PreToolUse` en paralelo «por si acaso». Dos puertas para lo mismo son dos
  sitios donde equivocarse, y la segunda es la que no se puede hacer bien.
- Bloquear a quien se lo salta a propósito.

## Decisions

### D1. Quién instala el hook: `verifica.sh`, no `/kit-init`

Lo instala quien firma. Así el hook lleva siempre la definición de huella del plugin que está
corriendo —se regenera en cada firma—, un proyecto que actualice el kit no tiene que hacer
nada más que verificar, y no hay un paso de instalación que se pueda olvidar.
`/kit-init` ya termina con `/kit-verifica`, así que un proyecto nuevo queda con puerta.

*Alternativa descartada — `/kit-init` lo instala:* obliga a rehacer el init en cada proyecto
existente y deja el hook desincronizado de la huella si esta cambia.

### D2. Contenido del hook

Un `#!/usr/bin/env bash`, una línea de marca (`# ios-agent-kit: puerta de commit — la
regenera verifica.sh`), `set -u`, la definición de `huella_diff` tal como la imprime
`declare -f`, y la comprobación: existe el marker, su `diff:` es la huella de ahora y su
`resultado:` es verde. Si no, mensaje por `stderr` y `exit 1`. Menos de veinte líneas.

La marca es la que decide si el fichero es nuestro: se refresca si la lleva, se respeta si no.

### D3. Hook ajeno o `core.hooksPath`

No se toca. El informe imprime: el fichero que hay, y la línea a añadir
(`bash .git/hooks/pre-commit.ios-agent-kit` o equivalente). Para que esa línea tenga algo que
llamar, con hook ajeno el kit escribe el suyo al lado, como `pre-commit.ios-agent-kit`, y es
ese el que hay que invocar. Con `core.hooksPath`, escribe ahí mismo con el mismo nombre y da
la misma instrucción.

*Alternativa descartada — editar el hook ajeno para encadenar:* es código de otro; un `sed`
sobre él puede romperlo y nadie lo pidió.

### D4. Qué comprueba `/kit-estado`

Una línea: si el hook del kit está instalado en este repositorio, o no. Sale del mismo sitio
(`git rev-parse --git-path hooks`) y de la misma marca.

### D5. Los casos van a `verifica-salidas.sh`

Es el banco de `verifica.sh`, que es quien instala. Los casos de bloqueo se ejercitan con
`git commit` de verdad en el repositorio temporal, y se demuestran capaces de fallar
vaciando el hook generado. `verifica-puerta.sh` desaparece con lo que probaba.

## Risks / Trade-offs

- [Un proyecto con husky u otro gestor de hooks] → `core.hooksPath` se detecta y no se pisa;
  el informe dice la línea a añadir.
- [El hook queda viejo si cambia `huella_diff`] → se regenera en cada firma, y la marca lo
  identifica como regenerable.
- [`declare -f` imprime la función con formato de bash, no el original] → es bash válido y
  es lo que ejecuta bash; el banco lo prueba.
- [Alguien borra `.git/hooks/pre-commit`] → la siguiente verificación lo vuelve a escribir;
  entre medias no hay puerta, y `/kit-estado` lo dice.

## Migration Plan

1. Publicar. 2. En cada proyecto, `/kit-verifica` una vez: instala el hook. 3. Los proyectos
que no lo hagan siguen sin puerta hasta que lo hagan; no hay rotura, hay ausencia, y se ve en
`/kit-estado`.
Vuelta atrás: reinstalar la versión anterior y borrar el hook; el marker no cambia de formato.
