# El kit no adivina el cambio

## Why

La 2.0.0 se probó el 2026-09-18 con un cambio de verdad en AppStarter
(`los-snapshots-fijan-su-locale`), con otro cambio activo al lado. Dos piezas hablaron del
cambio equivocado, y una de ellas salió cara:

- **El hook de contexto** inyectó en cada turno las tareas y el «FUERA de alcance» de
  `el-ci-fija-el-xcode-con-el-que-prueba`, el primero por orden. Ese bloque decía, literal,
  `**El rojo de CartSnapshotTests.**`: la tarea de la sesión. Avisa —«este es el primero por
  orden, no necesariamente el tuyo»—, pero lo que pone delante es «tu tarea está fuera de
  alcance».
- **`rodaja.sh`** listó las tareas cerradas del otro cambio y le entregó al revisor
  `RODAJA A REVISAR (desde la última revisión): 1847 líneas de cambio` para un cambio de 12
  líneas de código y dos PNG. La revisión costó 113k tokens y 7 min 37 s.

Medido sobre el historial de AppStarter (`git diff <desde> 0461d2a`, líneas `+`/`-`):

| La rodaja empieza en… | todo | sin `openspec/changes/` |
|---|---|---|
| la marca que había (≈ `41ed19c`, del 2026-09-16, once commits atrás) | 1742 | 161 |
| el principio del cambio revisado (`ec117fa`) | 610 | **12** |

Son dos causas. La primera es común a las dos piezas: con varios cambios activos,
`cambio_activo` designa uno por orden y cada pieza actúa sobre él. La segunda es solo de la
rodaja: no es de ningún cambio. Abarca el repositorio entero desde una marca que solo avanza
con `/kit-revisa` en ese checkout, y el 91 % de lo que volcó eran ficheros de planificación,
que no pueden romper nada.

`contexto-inyectado` ya lo tiene escrito en su propósito: adivinar dónde trabaja el modelo
«sería peor que callarse». Designar un cambio por orden es adivinar.

## What Changes

- **`cambio_activo` deja de designar uno cuando hay varios.** Sigue dando la lista, en orden
  estable, y cuántos son; `ACTIVO` solo se rellena cuando hay exactamente uno. Así ninguna
  pieza puede actuar sobre el primero por descuido.
- **El hook, con varios cambios activos, nombra y no afirma.** Lista los cambios con su
  recuento de tareas y dice que el acuerdo de la sesión es el del cambio en el que se
  trabaja. No inyecta tareas pendientes ni «FUERA de alcance» de ninguno. Con un solo cambio
  activo no cambia nada.
- **`rodaja.sh` recibe la ruta del cambio en todos sus modos**, como ya hace `--entregado`.
  Sin ruta usa el único activo; con varios y sin ruta, los lista y pide cuál, en vez de
  elegir. **BREAKING** para quien invoque `rodaja.sh` o `rodaja.sh --revisada` a mano con
  varios cambios abiertos: antes elegía y avisaba, ahora para.
- **La rodaja se ciñe al cambio que se revisa.** No empieza antes del principio de ese cambio
  —el mismo que ya calcula `--entregado`—: una marca más vieja que eso no se usa. Y no vuelca
  `openspec/changes/`: las tareas cerradas ya van en su propia lista, y el acuerdo el revisor
  lo lee del disco.
- **`/kit-revisa` y el revisor pasan la ruta** en vez de explicar qué parte de la salida
  ignorar, y el revisor lee el `proposal.md` de ese cambio, no `openspec/changes/*/`.

## Capabilities

### Modified Capabilities

- `cambio-activo`: el requisito «Cuál es el cambio activo se resuelve en un solo sitio» deja
  de prometer «siempre el mismo» cuando hay varios y pasa a prometer «ninguno, y la lista».
- `contexto-inyectado`: requisito nuevo —con varios cambios activos, el digest no afirma el
  acuerdo de ninguno—.
- `coste-del-juicio`: requisito nuevo —la rodaja es del cambio que se revisa—.

## Fuera de alcance

- **Decirle al hook cuál es el cambio de la sesión.** No hay canal: el hook no recibe nada
  que lo diga, e inferirlo del árbol de trabajo es una heurística con sus propios casos.
  Decidido por el owner el 2026-09-18: solo los nombres.
- **`--entregado` y lo que ve el juez.** Su salida no cambia, tampoco su `openspec/changes/`:
  es la única evidencia del juez y aquí no se toca. Lo único que cambia para él es que, con
  varios cambios y sin ruta, ya no recibe el primero por orden.
- **La marca cuando no hay ningún cambio activo.** Sin cambio no hay principio que calcular:
  la rodaja sigue yendo desde la marca, tenga la edad que tenga.
- **Que la marca sea una por checkout.** Una revisión hecha en otro worktree sigue sin mover
  la de este. El suelo del cambio lo vuelve inofensivo; unificarlas es otra conversación.
- **Los otros hallazgos del cuaderno de la prueba**: el presupuesto de rondas que
  `/kit-revisa` cita sin que nadie lo pida, y el «166 ficheros Swift que toque este cambio»
  de `busca-duplicados.py`. Son de redacción y van aparte.
- **AppStarter.** Este cambio es del kit.

## Criterios de aceptación

- [ ] Con dos cambios activos, el digest del hook nombra los dos con su recuento, y **no**
      contiene «Cambio activo:», ni «FUERA de alcance», ni ninguna línea de tarea pendiente.
      Con uno solo, el digest es idéntico al de hoy. Hay un caso de banco para cada mitad.
- [ ] Con dos cambios activos, `rodaja.sh` y `rodaja.sh --revisada` sin ruta salen distinto
      de 0, nombran los dos y no imprimen tareas ni diff; con la ruta, las tareas son las de
      ese cambio. `grep -rn 'primero por orden' scripts commands agents docs` sale vacío.
- [ ] En un repositorio de banco con una marca anterior al principio del cambio, la rodaja
      no incluye lo commiteado antes de ese principio; con una marca posterior, empieza en la
      marca, como hoy.
- [ ] La rodaja no contiene ninguna ruta bajo `openspec/changes/`, ni de ficheros trackeados
      ni de nuevos sin trackear; `--entregado` las sigue conteniendo.
- [ ] Reproducida la prueba real: en un clon desechable de AppStarter puesto como estaba al
      revisar —`fafee38` con el arreglo de `0461d2a` en el árbol de trabajo y la marca en
      `41ed19c`—, `rodaja.sh openspec/changes/los-snapshots-fijan-su-locale` da 12 líneas de
      cambio, no 1847, y ninguna bajo `openspec/changes/`. La cifra queda anotada en
      `tasks.md`.
- [ ] `commands/kit-revisa.md`, `agents/reviewer.md`, `docs/PIEZAS.md` y la cabecera de
      `rodaja.sh` describen el uso con ruta, y el párrafo de `kit-revisa.md` que explicaba qué
      ignorar con varios cambios activos ya no está.
- [ ] `/kit-verifica` en verde, y una ronda de `/kit-revisa`.

## Impact

- `scripts/lib-kit.sh` (`cambio_activo`), `scripts/inyecta-contexto.sh`, `scripts/rodaja.sh`.
- `scripts/verifica-contexto.sh` y `scripts/verifica-rodaja.sh`: el caso «elige el primero
  por orden estable» pasa a exigir lo contrario, y entran los casos de los criterios. Nacen
  de un fallo que llegó a un proyecto real.
- `commands/kit-revisa.md`, `agents/reviewer.md`, `docs/PIEZAS.md`. `agents/aceptacion.md` ya
  pasa la ruta y no cambia.
- `scripts/estado.sh` solo usa la lista y el recuento: no cambia.
- Las tres specs de Capabilities, y el propósito de `cambio-activo`, que hoy dice que elegir
  entre varios es «arbitrario pero estable».
- Versión: es un cambio de comportamiento visible para quien tenga varios cambios abiertos.
  Qué número lleva lo decide el owner al publicar.
