# El juez deja de ser obligatorio

## Why

El owner decidió el 2026-09-14: **el paso obligatorio es el revisor; el juez se invoca cuando
haga falta.** Lo que hay detrás, medido:

- En la auditoría del kit —**cinco cambios y once commits, con catorce hallazgos en seis pasadas
  de revisor**— no se invocó al juez **ni una vez**. Todo lo encontró el revisor, incluidos dos
  agujeros en la puerta de commit y una colisión de huellas.

  *Aquí ponía «ocho hallazgos», que son los de los **tres** cambios del 2026-09-11 y no los de
  los cinco. El README ya llevaba esa frase corregida —«cuatro rondas y ocho hallazgos sobre
  tres cambios»— y este texto la reintroducía mezclada. Es la tercera vez que esta clase de
  censo se cuela; lo cazó el revisor.*
- Una ronda de juez cuesta lo que una de revisor y pregunta menos cosas: sobre prosa, que es la
  mitad de lo que se cambia en un kit, converge peor.
- Y el flujo se contradecía: la plantilla exigía `/kit-acepta` antes de archivar **siempre**,
  mientras `docs/FLUJO.md` decía que en un cambio pequeño de alcance claro no hacía falta. Esa
  contradicción se arregló el 2026-09-13 alineando la plantilla con FLUJO; esto va un paso más
  allá y cambia cuál es el valor por defecto.

**Lo que NO dice este cambio:** que el juez sobre. Sigue siendo la única pieza que pregunta «¿es
lo acordado?», y el caso que lo justifica está escrito en el `README`: un cambio que compilaba,
pasaba 144 tests y tenía el linter en verde, y hacía justo lo que su propio «fuera de alcance»
prohibía. Eso el revisor no lo ve, porque no es su pregunta. Lo que cambia es **quién decide
cuándo se paga esa ronda**: hasta hoy lo decidía una regla; a partir de ahora, quien orquesta.

## What Changes

El juez pasa de **paso del flujo** a **herramienta que se invoca con criterio**. Seis sitios, y
en todos se sustituye «hazlo siempre» por «hazlo cuando»:

- **`plantillas/openspec-config.yaml.ejemplo`**: la regla de archivar deja de exigirlo. Se
  conserva entera la segunda regla —no archivar con `ACUERDO-ROTO` ni con un `DEVUELTO` del
  producto—, que es condicional y solo aplica si hubo veredicto.
- **`docs/FLUJO.md`**: el paso 6 pasa a ser opcional y su tabla cambia la columna «¿juez?» por
  el criterio de cuándo conviene.
- **`commands/kit-acepta.md`** y **`commands/kit-revisa.md`**: el revisor es el paso obligatorio;
  el juez, el que se invoca cuando nadie va a comparar el acuerdo con lo entregado.
- **`README.md`** y **`docs/PIEZAS.md`**: el día a día y la ficha de la pieza lo dicen igual.

**El criterio que sustituye a la obligación**, y va escrito en los seis sitios en una línea: se
invoca al juez cuando **nadie vaya a leer el acuerdo contra lo entregado** — cambios grandes o
que tocan varias capas, alcance que se movió al implementar, o cuando quien orquesta no es quien
acordó.

## Capabilities

### Modified Capabilities

Ninguna, y esto se comprobó antes de escribirlo: **ninguna cláusula `SHALL` de las specs vivas
obliga a invocar al juez**. Las de `juicio-de-aceptacion` describen cómo se comporta *cuando se
le invoca* —entrada no vacía, rutas por la raíz del plugin, el tope, la línea de cada ronda— y
las dos de `coste-del-juicio` que hablan de archivar son condicionales: aplican *si hay
veredicto*. La obligatoriedad solo vivía en la plantilla y en la prosa de `docs/FLUJO.md`.

## Impact

- **Se editan:** `plantillas/openspec-config.yaml.ejemplo`, `docs/FLUJO.md`, `docs/PIEZAS.md`,
  `README.md`, `commands/kit-acepta.md`, `commands/kit-revisa.md` y `docs/PRIMER-CAMBIO.md`.

  *El séptimo entró tras la revisión: es el recorrido guiado de quien estrena el kit y presentaba
  al juez como un paso más del bucle. Va escrito en vez de colarse, igual que se hizo ayer con
  `README.md`.*
- **Proyectos que ya usan el kit:** su `openspec/config.yaml` es una copia y no cambia solo. El
  que quiera la regla nueva la copia de la plantilla o edita esas dos líneas.
- **El agente y su comando no se tocan:** `/kit-acepta` sigue haciendo exactamente lo que hacía.

## FUERA de alcance

- **Borrar el juez, su comando, sus specs o el modo `--entregado` de `rodaja.sh`.** Son 651
  líneas más lo enganchado en 21 ficheros, y el owner eligió el 2026-09-14 la opción
  reversible: que deje de ser obligatorio, no que desaparezca.
- **Las specs vivas.** No cambia ninguna cláusula; si algún día se retira el juez, ese será otro
  cambio con sus deltas `REMOVED`.
- **`AppStarter`**, cuyo `config.yaml` es una copia suya y no se actualiza solo.
- **Publicar.**

## Criterios de aceptación

- [ ] `plantillas/openspec-config.yaml.ejemplo` NO SHALL exigir `/kit-acepta` antes de archivar,
      SHALL decir cuándo conviene invocarlo, y SHALL seguir siendo YAML válido con sus dos reglas
      de `archive`.
- [ ] `docs/FLUJO.md` SHALL presentar el juez como paso opcional con ese criterio, y su tabla
      «Cuánto proceso pide cada cambio» NO SHALL responder «sí» o «no» en la columna del juez.
- [ ] El criterio —«cuando nadie vaya a leer el acuerdo contra lo entregado»— SHALL aparecer en
      los seis ficheros, para que quien lea cualquiera de ellos saque la misma regla. Se
      comprueba sobre el **texto**, no línea a línea, y **sin distinguir mayúsculas**:
      `tr '\n' ' ' < <fichero> | grep -ci 'nadie vaya a leer[[:space:]]*el acuerdo'`.

      *Esta comprobación ha fallado DOS veces sin que el texto estuviera mal: primero línea a
      línea —en `README.md` la frase queda partida dentro de un bloque de código— y después sin
      `-i`, porque la plantilla la escribe en mayúsculas. Con esta van cuatro veces en la
      auditoría que un criterio mío mide una cadena en vez de la cosa. La lección, ya que el
      número se repite: cuando un criterio necesita tres intentos de `grep`, lo que falla no es
      el comando — es que la regla no se deja medir por texto y habría que comprobarla leyendo.*
- [ ] `commands/kit-revisa.md` SHALL decir que el revisor es el paso obligatorio, sin dejar de
      decir que el juez pregunta otra cosa.
- [ ] Ninguna spec viva SHALL cambiar: `git diff openspec/specs/` sale vacío al terminar.
- [ ] `/kit-verifica` en verde con `LANG=` y con `LANG=en_US.UTF-8`.

## Presupuesto

Prosa, seis ficheros, sin código: **una pasada de revisor**. Este cambio se acoge además a la
regla que él mismo escribe —y a la que ya estaba vigente desde el 2026-09-13, que permite
archivar sin juez un cambio pequeño de alcance claro—, así que no lleva ronda de juez. Va dicho
porque un cambio que se beneficia de su propia regla tiene que declararlo, no aprovecharlo en
silencio.
