---
description: Revisa la rodaja pendiente — lo que ha cambiado desde la última revisión, no el cambio entero.
---

Lanza el sub-agente `reviewer` sobre **la rodaja pendiente**: lo que ha cambiado desde la
última revisión marcada, no el cambio completo.

**No ejecutes `rodaja.sh` aquí.** Lo hace el revisor dentro de su propio contexto, que es donde
hace falta el diff. Ejecutarlo antes lo vuelca también en esta conversación, donde se queda para
siempre, y el diff se acaba pagando dos veces.

Dile qué cambio se está implementando —por su ruta— y que corra él la rodaja, el informe de
`/kit-verifica` y el `proposal.md`. Su única pregunta es **¿esto rompe algo?** — corrección,
seguridad o un requisito explícito del encargo.

**Y dile qué hacer si la rodaja avisa de varios cambios activos:** `rodaja.sh` sin argumentos
elige el primero por orden y solo avisa. Que se quede con la ruta que le has dado: lo único que
depende de esa elección es la lista de tareas cerradas; el diff es del repositorio entero.

## Qué hacer con lo que devuelva, antes de tocar nada

Un veredicto no es una lista de tareas. Para cada hallazgo, decide **en este orden**:

1. **¿Cuál es la causa?** Si dos hallazgos tienen la misma, se arregla una vez, no dos.
2. **¿Se puede restar?** Borrar lo que sobra cierra más hallazgos que añadir lo que falta.
3. **¿Hace falta un fichero nuevo?** Casi nunca. Un hallazgo no lo justifica por sí solo: se
   arregla donde vive el defecto.

Y cuenta las rondas contra el presupuesto que declaraste (`docs/FLUJO.md`). El modo de fallo
caro no es el hallazgo: es que **tu arreglo fabrique el siguiente**. Si la segunda ronda solo
devuelve redacción, para y que decida el owner.

Cuando devuelva **GREEN o AMBER**, marca el punto:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/rodaja.sh" --revisada
```

Con **RED no se marca**: se arregla y se vuelve a pasar, y así lo arreglado entra en la
siguiente revisión en vez de darse por bueno.

**Y con GREEN o AMBER tampoco, si arreglar lo que encontró cambió lo que hace el código que se
entrega.** Marcar significa «desde aquí no se vuelve a revisar», y ese arreglo no lo ha visto
nadie: vuelve a pasarlo y marca entonces. Corregir pruebas o prosa no obliga. Es el mismo eje que
el tope del juez, en `agents/aceptacion.md`. Lo que acota la serie es el presupuesto de rondas.

**Úsalo al cerrar cada tarea de `tasks.md`, no al final del cambio.** Revisar al final
significa revisar todo, y volver a revisarlo todo en cada vuelta. Un hallazgo tardío además
llega cuando el contexto se perdió y cuando devolver una cosa devuelve las que vinieran
detrás.

**Este es el paso obligatorio antes de archivar.** `/kit-acepta` pregunta otra cosa —si es lo
acordado— y es opcional: cuándo merece pagarlo lo dice él.
