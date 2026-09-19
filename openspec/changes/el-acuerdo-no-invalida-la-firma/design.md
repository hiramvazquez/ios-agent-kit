## Context

Ver `proposal.md` — Why. `huella_diff` vive en `scripts/lib-kit.sh` y la usan tres sitios: la
firma de `verifica.sh`, el hook `pre-commit` que genera (la copia con `declare -f`) y el digest
de cada turno. Los tres llaman con el directorio de trabajo en la raíz del repositorio.

Medido el 2026-09-18 con git 2.54 y bash 3.2, en un repositorio temporal
(`mide-exclusion.sh`, en el scratchpad de la sesión que abrió este cambio; su contenido está
resumido aquí):

| caso | huella vieja | `-- . ':(exclude)openspec'` | `-- ':(top)' ':(top,exclude)openspec'` |
|---|---|---|---|
| `openspec/` sin cambios | A | A | A |
| solo `openspec/` cambiado, o stageado | B | A | A |
| llamada desde un subdirectorio | — | solo ve ese subdirectorio | la de la raíz |
| `openspec-notas/` cambiado | — | dentro | dentro |
| copiada con `declare -f`, ejecutada en `/bin/bash` 3.2 | — | — | el mismo número |

## Goals / Non-Goals

**Goals:** que escribir el acuerdo después de firmar no obligue a verificar de nuevo, sin
aflojar nada de lo que se compila.

**Non-Goals:** cambiar el formato del marker, añadir una marca de versión de huella, o
cualquier migración: la compatibilidad sale sola (fila 1 de la tabla).

## Decisions

### D1. Pathspec con `:(top)`, no relativo

`git diff HEAD -- ':(top)' ':(top,exclude)openspec'`. La forma con `.` depende del directorio
de trabajo: hoy los tres llamadores están en la raíz, pero una firma que cambia según desde
dónde se calcula es un fallo esperando a un llamador nuevo. La positiva `:(top)` es explícita
aunque git ya asuma el árbol entero con solo exclusiones: no depende de esa regla.

### D2. Se excluye `openspec/` entero, no `openspec/changes/`

Archivar escribe en `openspec/specs/` al fundir los deltas, y `openspec/config.yaml` es
también acuerdo. Excluir solo `changes/` dejaría el archivado invalidando la firma, que es la
mitad del problema.

### D3. Sin opción de configuración

Una ruta configurable en `kit.conf` tendría que viajar también al hook generado, y nadie la ha
pedido. `openspec/` es el directorio que el propio kit crea con `/kit-init`.

### D4. Lo que se deja sin firmar, declarado

Un commit que solo cambia `openspec/` pasa con la firma que hubiera. Si un proyecto verifica
algo de ese directorio en su `kit.conf` —un `openspec validate`—, esa parte ya no queda
firmada. Va declarado junto a `huella_diff` y en PIEZAS, no compensado.

## Risks / Trade-offs

- [Un proyecto guarda algo compilable dentro de `openspec/`] → no es el uso de OpenSpec ni del
  kit; queda declarado como límite.
- [Durante una actualización, el digest calcula con la huella nueva y el marker es de la vieja]
  → solo difieren si `openspec/` tiene cambios; el digest dice «la firma es de OTRO árbol»
  hasta la siguiente verificación, y el hook, que es el que bloquea, se regenera en esa misma
  verificación.
- [Un hook del kit que no se pudo refrescar conserva la huella vieja] → con `openspec/`
  cambiado bloquea aunque la firma sea buena: falla cerrado, y el informe ya avisa de que no se
  pudo refrescar.
