---
description: Revisa la rodaja pendiente — lo que ha cambiado desde la última revisión, no el cambio entero.
---

**Antes de lanzar al revisor, di cuántas rondas presupuestas para este cambio** —si no lo has
dicho ya—. La tabla está en `${CLAUDE_PLUGIN_ROOT}/docs/FLUJO.md`, bajo
«rondas a presupuestar», y decide por lo que se pone bajo juicio, no por el tamaño. Las
rondas no las cuenta el kit: las cuentas tú.

Lanza el sub-agente `reviewer` sobre **la rodaja pendiente**: lo que ha cambiado desde la
última revisión marcada, no el cambio completo.

**No ejecutes `rodaja.sh` aquí.** Lo hace el revisor dentro de su propio contexto, que es donde
hace falta el diff. Ejecutarlo antes lo vuelca también en esta conversación, donde se queda para
siempre, y el diff se acaba pagando dos veces.

Dile qué cambio se está implementando —por su ruta— y que corra él la rodaja **de ese cambio**,
el informe de `/kit-verifica` y su `proposal.md`. Su única pregunta es **¿esto rompe algo?** —
corrección, seguridad o un requisito explícito del encargo.

## Qué hacer con lo que devuelva, antes de tocar nada

Un veredicto no es una lista de tareas. Para cada hallazgo, decide **en este orden**:

1. **¿Cuál es la causa?** Si dos hallazgos tienen la misma, se arregla una vez, no dos.
2. **¿Se puede restar?** Borrar lo que sobra cierra más hallazgos que añadir lo que falta.
3. **¿Hace falta un fichero nuevo?** Casi nunca. Un hallazgo no lo justifica por sí solo: se
   arregla donde vive el defecto.

Y cuenta las rondas contra ese presupuesto. El modo de fallo caro no es el hallazgo: es que
**tu arreglo fabrique el siguiente**. Si la segunda ronda solo devuelve redacción, para y que
decida el owner.

Cuando devuelva **GREEN o AMBER**, marca el punto, con la misma ruta:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/rodaja.sh" --revisada openspec/changes/<nombre>
```

Con **RED no se marca**: se arregla y se vuelve a pasar, y así lo arreglado entra en la
siguiente revisión en vez de darse por bueno.

**Y con GREEN o AMBER tampoco, si arreglar lo que encontró cambió lo que hace el código que se
entrega.** Marcar significa «desde aquí no se vuelve a revisar», y ese arreglo no lo ha visto
nadie: vuelve a pasarlo y marca entonces. Corregir pruebas o prosa no obliga. Es el mismo eje que
el tope del juez, en `${CLAUDE_PLUGIN_ROOT}/agents/aceptacion.md`. Lo que acota la serie es el
presupuesto de rondas.

**Úsalo al cerrar cada tarea de `tasks.md`, no al final del cambio.** Revisar al final
significa revisar todo, y volver a revisarlo todo en cada vuelta. Un hallazgo tardío además
llega cuando el contexto se perdió y cuando devolver una cosa devuelve las que vinieran
detrás.

**Este es el paso obligatorio antes de archivar.** `/kit-acepta` pregunta otra cosa —si es lo
acordado— y es opcional: cuándo merece pagarlo lo dice él.
