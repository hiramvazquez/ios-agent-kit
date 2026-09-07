---
description: Revisa la rodaja pendiente — lo que ha cambiado desde la última revisión, no el cambio entero.
---

Lanza el sub-agente `reviewer` sobre **la rodaja pendiente**: lo que ha cambiado desde la
última revisión marcada, no el cambio completo.

Empieza mirando qué hay:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/rodaja.sh"
```

Pásale al reviewer esa rodaja, el informe de `/kit-verifica` y el `proposal.md` del cambio
activo. Su única pregunta es **¿esto rompe algo?** — corrección, seguridad o un requisito
explícito del encargo.

Cuando devuelva **GREEN o AMBER**, marca el punto:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/rodaja.sh" --revisada
```

Con **RED no se marca**: se arregla y se vuelve a pasar, y así lo arreglado entra en la
siguiente revisión en vez de darse por bueno.

**Úsalo al cerrar cada tarea de `tasks.md`, no al final del cambio.** Revisar al final
significa revisar todo, y volver a revisarlo todo en cada vuelta. Un hallazgo tardío además
llega cuando el contexto se perdió y cuando devolver una cosa devuelve las que vinieran
detrás.

No sustituye a `/kit-acepta`: el reviewer pregunta si el código está bien; el juez de
aceptación pregunta si es lo que se acordó. Un cambio puede estar impecable y no ser lo
pedido.
