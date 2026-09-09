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

Encabeza el bloque como **del revisor**, escríbelo **al final** de lo que haya —el orden en el
fichero es lo único que dice qué vino antes— y no lo numeres como ronda: el tope del juez cuenta
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

**Y con GREEN o AMBER tampoco, si arreglar lo que encontró movió el comportamiento.** Marcar
significa «desde aquí no se vuelve a revisar»: hacerlo después de cambiar código convierte la
marca en una afirmación sobre un árbol que ya no es el revisado — el mismo error que la puerta
de commit y la firma de verificación existen para cerrar, en un punto del bucle donde todavía
cabía. Vuelve a pasarlo, y marca entonces.

Qué cuenta como mover el comportamiento **no lo decidas a ojo, ni lo deduzcas de aquí**: es el
mismo eje que usa el tope del juez, y su tabla está en `agents/aceptacion.md`, sección «Tope».
Léela ahí. Este comando no la repite a propósito — reenunciarla en otras palabras es como se
ensanchó una vez, eximiendo de repasar cláusulas del acuerdo que sí mandan algo nuevo.

Lo que sí conviene saber sin ir a mirar: corregir una errata **no** obliga a repetir la pasada.
Si obligara, una regla que pide lo obvio dejaría de aplicarse también en lo que importa.

**Y en la duda, cuenta como comportamiento**: vuelve a pasarlo. Es el mismo desempate que esa
tabla declara, y empuja hacia el mismo lado — una pasada de más cuesta menos que marcar sobre
algo que nadie ha visto.

Lo midió el 2026-09-09 quien implementaba un cambio en `AppStarter`, sin que el kit se lo
pidiera: «la revisión fue AMBER, que se marcaría — pero he cambiado código después». Volvió a
pasarlo, y **la segunda pasada encontró más cosas**. Una bloqueaba: la spec se
contradecía consigo misma, y al archivar esa contradicción se habría fundido en la spec
canónica, donde quien la implementara habría reintroducido el defecto que la primera pasada
acababa de cerrar.

Si el segundo arreglo vuelve a mover el comportamiento, toca otra — y lo que acota eso no es
esta regla, es el presupuesto de rondas de `docs/FLUJO.md`. Cuando se agote, decide el owner.

**Úsalo al cerrar cada tarea de `tasks.md`, no al final del cambio.** Revisar al final
significa revisar todo, y volver a revisarlo todo en cada vuelta. Un hallazgo tardío además
llega cuando el contexto se perdió y cuando devolver una cosa devuelve las que vinieran
detrás.

No sustituye a `/kit-acepta`: el reviewer pregunta si el código está bien; el juez de
aceptación pregunta si es lo que se acordó. Un cambio puede estar impecable y no ser lo
pedido.
