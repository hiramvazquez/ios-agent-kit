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
elige el primero por orden y solo avisa —no acepta que se le diga cuál—, así que el aviso, que
antes salía aquí, ahora lo ve solo él. Que se quede con la ruta que le has dado: lo único que
depende de esa elección es la lista de tareas cerradas; el diff es del repositorio entero.

Cuando devuelva **GREEN o AMBER**, marca el punto:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/rodaja.sh" --revisada
```

Con **RED no se marca**: se arregla y se vuelve a pasar, y así lo arreglado entra en la
siguiente revisión en vez de darse por bueno.

**Y con GREEN o AMBER tampoco, si arreglar lo que encontró cambió lo que hace el código que se
entrega.** Marcar significa «desde aquí no se vuelve a revisar», y ese arreglo no lo ha visto
nadie: vuelve a pasarlo y marca entonces. Corregir pruebas o prosa no obliga. Es el mismo eje que
el tope del juez, en `agents/aceptacion.md`.

Salió de un caso real: el 2026-09-09, en `AppStarter`, quien implementaba volvió a pasarlo después
de arreglar, y la segunda pasada encontró una spec que se contradecía consigo misma y que al
archivar se habría fundido en la canónica.

Si el segundo arreglo vuelve a cambiar el código, toca otra pasada; lo que acota la serie es el
presupuesto de rondas de `docs/FLUJO.md`.

Anotar la pasada en el acuerdo es opcional, y sin formato: hazlo si te sirve.

**Úsalo al cerrar cada tarea de `tasks.md`, no al final del cambio.** Revisar al final
significa revisar todo, y volver a revisarlo todo en cada vuelta. Un hallazgo tardío además
llega cuando el contexto se perdió y cuando devolver una cosa devuelve las que vinieran
detrás.

No sustituye a `/kit-acepta`: el reviewer pregunta si el código está bien; el juez de
aceptación pregunta si es lo que se acordó. Un cambio puede estar impecable y no ser lo
pedido.
