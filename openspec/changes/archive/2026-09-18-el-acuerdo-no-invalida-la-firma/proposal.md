## Why

La huella de la firma cubre todo el árbol, y el flujo de OpenSpec escribe en `openspec/` justo
después de verificar: marcar la última tarea, anotar la ronda del revisor, archivar el cambio.
Cada una de esas escrituras invalida una firma verde que no ha cambiado de sentido, y obliga a
verificar otra vez algo que solo movió markdown. En este repositorio son 20 segundos; en
`AppStarter` son minutos de build y tests. Es el hallazgo 6 de la prueba real del 2026-09-18:
se verifica dos veces por construcción.

## What Changes

- **La huella deja fuera `openspec/`.** Lo que vive ahí es el acuerdo —propuestas, tareas,
  specs—, no lo que se compila. Cambiarlo después de firmar ya no invalida la firma, ni en el
  árbol ni en el índice.
- **Todo lo demás sigue igual:** un cambio fuera de `openspec/` después de firmar la invalida,
  y la puerta de commit lo bloquea como hasta ahora. La firma sigue siendo del diff contra
  `HEAD` y deja de valer cuando un commit se lleva el código firmado, así que el acuerdo se
  commitea junto con el código; archivar en un commit aparte, después, pide otra verificación
  como hoy.
- **Las firmas que ya existen siguen valiendo** mientras `openspec/` no tenga cambios: con ese
  directorio limpio, la huella nueva es idéntica a la vieja.
- **El hook `pre-commit` de cada proyecto** recibe la definición nueva la próxima vez que se
  verifique con esta versión, porque se regenera en cada firma.

## Capabilities

### New Capabilities

Ninguna.

### Modified Capabilities

- `verificacion-firmada`: la huella deja fuera `openspec/`, y un cambio ahí después de firmar
  no la invalida. Se declara lo que eso deja sin firmar.
- `puerta-de-commit`: stagear en el propio commit después de firmar bloquea solo si toca algo
  fuera de `openspec/`; un commit que lleva el acuerdo actualizado pasa con la firma que había.

## Fuera de alcance

- Hacer configurable qué se excluye. Es un directorio fijo, el que el propio kit usa.
- Excluir otras rutas de planificación o de herramientas (`.claude/`, `docs/`).
- Validar `openspec/` dentro de la verificación. Si un proyecto pone `openspec validate` en su
  `kit.conf`, esa parte deja de quedar firmada, y se declara; no se compensa.
- Las frases de README y FLUJO que dicen que otra terminal se salta la puerta.
- Subir la versión del plugin.

## Criterios de aceptación

- [ ] En `scripts/verifica-salidas.sh`, sobre un repositorio temporal con firma verde: editar un `tasks.md` de `openspec/changes/` deja `--comprueba` en 0; stagearlo también; commitearlo pasa por el hook; mover el cambio a `archive/` y tocar `openspec/specs/` también pasa.
- [ ] En el mismo banco: tras tocar `openspec/`, un cambio fuera de él sigue invalidando la firma, y un directorio que solo empieza por `openspec` (`openspec-notas/`) no queda excluido.
- [ ] Esos casos salen en rojo con la huella de antes de este cambio, y en verde después.
- [ ] Con `openspec/` sin cambios, la huella nueva y la vieja dan el mismo número: comprobado con el script de medición del diseño.
- [ ] `huella_diff` sigue teniendo una sola definición, y el hook generado la lleva copiada con la exclusión dentro.
- [ ] `docs/PIEZAS.md`, `commands/kit-verifica.md` y los comentarios de `scripts/lib-kit.sh` y `scripts/verifica.sh` dicen que la norma de stagear, verificar y commitear aparte vale para lo que está fuera de `openspec/`, y el límite queda declarado en `lib-kit.sh` y en PIEZAS.
- [ ] `openspec validate --all` limpio y `/kit-verifica` en verde.

## Impact

- `scripts/lib-kit.sh`: `huella_diff` con la exclusión, y su comentario.
- `scripts/verifica.sh`: su cabecera.
- `scripts/verifica-salidas.sh`: los casos.
- `docs/PIEZAS.md`, `commands/kit-verifica.md`: la norma con su excepción y el límite.
- `openspec/specs/verificacion-firmada/spec.md`, `openspec/specs/puerta-de-commit/spec.md`: vía delta.
- Para los proyectos: nada que hacer; llega con la próxima versión que se publique.
