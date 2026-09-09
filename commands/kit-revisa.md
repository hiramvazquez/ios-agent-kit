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

## Anota la pasada antes de marcar nada

Escribe en el acuerdo del cambio —en `tasks.md`, o al final del `proposal.md` si este cambio
no lleva lista de tareas— qué pasada fue, qué veredicto dio y qué encontró.

**Lo escribes TÚ, no el revisor.** Su prompt le prohíbe ejecutar nada que cambie el estado del
repositorio, y eso no se toca: un revisor con permiso de escritura en lo que revisa es
superficie que no hace falta abrir. Tú ya escribes.

Encabeza el bloque como **del revisor**, y no lo numeres como ronda: el tope del juez cuenta
rondas de juicio, y si se mezclan puede contar pasadas de revisor y dispararse antes de tiempo.

Por qué no es papeleo: el 2026-09-09, en el primer uso del kit fuera de su repositorio, el
bucle entero de un cambio de `AppStarter` —pasadas de revisor y ronda de juez— no dejó ni una
línea en su acuerdo archivado. Reproducible sobre cualquier cambio:

```bash
grep -cE '^## Del |AMBER|ACEPTADO|ronda' openspec/changes/archive/<cambio>/tasks.md
```

Se perdió, entre otras cosas, que el revisor propuso un arreglo **equivocado** y que quien
implementaba lo midió y usó otro. Eso es justo lo que un cambio futuro necesita saber para no
volver a proponerlo.

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
