## Why

La puerta de commit deduce a qué repositorio va un `git commit` leyendo el texto del comando
con un analizador de shell escrito a mano. Ese analizador no frena `cd ~/repo && git commit`,
ni `git add` y `git commit` en líneas distintas, ni nada que no pase por la herramienta Bash de
Claude Code. El 2026-09-16 se intentó cerrar eso cuatro veces; cada intento rompió un caso que
el anterior acertaba, y se revirtió. El diagnóstico que quedó escrito es correcto: el problema
no es el analizador, es tener que adivinar el repositorio desde el texto. Git ya sabe en qué
repositorio se está commiteando, y tiene un sitio para preguntar antes de hacerlo.

## What Changes

- **La puerta pasa a ser un hook `pre-commit` de git** en el repositorio del proyecto,
  generado por `verifica.sh` cada vez que firma. Comprueba lo mismo que hoy —firma del árbol y
  del índice, y resultado verde— desde cualquier terminal, cualquier directorio y cualquier
  forma de escribir el comando. No hay nada que analizar.
- **Desaparece el hook `PreToolUse`** y con él `scripts/puerta-commit.sh`,
  `scripts/analiza-invocacion.py` y `scripts/verifica-puerta.sh`. Quedan dos hooks en
  `hooks/hooks.json`.
- La huella sigue teniendo **una sola definición** (`huella_diff` en `lib-kit.sh`): el hook
  generado la lleva copiada por `declare -f` al escribirse, no reescrita a mano.
- **BREAKING para los proyectos que ya usan el kit:** hasta que corran `/kit-verifica` una vez
  con esta versión no tienen puerta. El informe lo dice la primera vez que la instala.
- Un repositorio con un `pre-commit` ajeno, o con `core.hooksPath` configurado, no se toca:
  el informe dice qué línea añadir y dónde.
- `--no-verify` y un commit hecho sin pasar por git siguen fuera, y se declaran donde se
  declaraban.

## Capabilities

### New Capabilities

Ninguna.

### Modified Capabilities

- `puerta-de-commit`: los dos requisitos actuales —juzgar el repo al que va el commit
  analizando la invocación, y vigilar solo los repositorios con `kit.conf`— se retiran. Los
  sustituyen dos: la puerta es un hook de git del repositorio, y la instala la verificación.

## Fuera de alcance

- Cambiar qué se firma o cómo. `huella_diff`, el marker y `--comprueba` quedan como están.
- Bloquear `--no-verify` o commits hechos con un git que no lea `.git/hooks/`. No se puede
  desde dentro de la máquina, igual que antes.
- Encadenar con un `pre-commit` ajeno de forma automática. Se avisa y se dice la línea; no
  se edita un hook que no es nuestro.
- Los otros dos hooks y lo que inyectan.

## Criterios de aceptación

- [ ] Tras `bash scripts/verifica.sh` en verde sobre un repositorio sin hook previo, existe `.git/hooks/pre-commit` ejecutable, y `git commit` a secas con el índice firmado pasa.
- [ ] Con firma verde, editar un fichero trackeado y `git commit -am` bloquea con un mensaje que dice qué hacer; lo mismo con `git commit <pathspec>` y con `git add` seguido de `git commit` en otro comando. Se prueba con el hook de verdad, no con `--comprueba`.
- [ ] El bloqueo no depende del directorio ni de la forma del comando: desde fuera del repositorio con `git -C`, con `cd ~/…`, y desde un `bash -c`, el resultado es el mismo que desde dentro.
- [ ] Un repositorio sin ningún commit: la verificación firma, instala el hook y el primer commit pasa.
- [ ] Un `pre-commit` que no lleva la marca del kit no se modifica, y el informe de verificación nombra el fichero y la línea que hay que añadir. Con `core.hooksPath` configurado, lo mismo.
- [ ] Una verificación en rojo instala o refresca el hook igual, y el hook bloquea.
- [ ] `scripts/puerta-commit.sh`, `scripts/analiza-invocacion.py` y `scripts/verifica-puerta.sh` no existen; `hooks/hooks.json` declara solo `UserPromptSubmit` y `SessionStart`; `bash scripts/autocomprueba.sh` en verde.
- [ ] `grep -rn 'PreToolUse\|puerta-commit\|analiza-invocacion' README.md docs commands agents kit.conf plantillas openspec/specs` no encuentra nada salvo en `openspec/changes/archive/`.
- [ ] Los casos nuevos viven en `scripts/verifica-salidas.sh` y se demuestran capaces de fallar: con el hook generado vacío, los de bloqueo caen.
- [ ] `/kit-verifica` en verde.

## Impact

- `scripts/verifica.sh`: instala o refresca el hook al firmar; avisa si no puede.
- `scripts/lib-kit.sh`: sin cambios en `huella_diff`; el hook la copia con `declare -f`.
- `scripts/puerta-commit.sh`, `scripts/analiza-invocacion.py`, `scripts/verifica-puerta.sh`: borrados. `hooks/hooks.json`: dos hooks. `kit.conf`: sin el paso «puerta de commit».
- `scripts/verifica-salidas.sh`: los casos de la puerta.
- `scripts/estado.sh`: una línea que diga si la puerta está instalada.
- `README.md`, `docs/PIEZAS.md`, `docs/FLUJO.md`, `docs/INSTALACION.md`, `commands/kit-verifica.md`, `openspec/config.yaml` (la nota de «tres hooks»): describen la puerta nueva.
- Para los proyectos: correr `/kit-verifica` una vez. Los que no lo hagan no tienen puerta y el informe se lo dice.
