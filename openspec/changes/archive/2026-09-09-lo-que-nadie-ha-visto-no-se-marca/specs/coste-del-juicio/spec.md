# coste-del-juicio — delta

## ADDED Requirements

### Requirement: Una rodaja no se marca sobre código que no ha visto nadie

Cuando arreglar lo que el revisor encontró mueva el comportamiento, la rodaja NO SHALL marcarse
como revisada sin volver a pasarla.

1. El disparador SHALL ser **que los arreglos movieran el comportamiento**, con el mismo eje
   que usa el tope del juicio, y SHALL remitir a él en vez de definir uno nuevo.
2. Qué arreglos NO obligan a repetir la pasada SHALL leerse de esa misma tabla y NO SHALL
   reenunciarse en otros términos. En particular: reescribir una cláusula normativa **sí**
   cuenta —en este kit un `SHALL` del acuerdo se funde en `openspec/specs/`, así que cambiarlo
   es cambiar lo que una norma manda—, mientras que corregir una que describía mal lo que ya se
   hacía, no.
3. `docs/FLUJO.md` SHALL describir esa condición donde ya describe el marcado, y SHALL decir
   que cada pasada y cada ronda se anotan en el acuerdo.
4. Ningún documento del kit SHALL afirmar que de las rondas no queda rastro. Lo que SHALL
   decirse es lo que sigue faltando: que nadie las cuenta.

Marcar una rodaja significa «desde aquí no se vuelve a revisar». Hacerlo después de cambiar
código convierte el marcado en una afirmación sobre un árbol que ya no es el revisado — que es
**exactamente el error que la puerta de commit y la firma de verificación existen para cerrar**,
cometido en un punto del bucle donde todavía cabía.

Medido el 2026-09-09 en `AppStarter`, y no por el kit: quien implementaba se dio cuenta solo,
escribió «marcar ahora le daría paso franco a lo que no ha visto nadie» y volvió a pasarlo. **La
segunda pasada encontró más cosas, y una bloqueaba**: la spec se contradecía consigo
misma, y al archivar esa contradicción se habría fundido en la spec canónica, donde quien la
implementara habría reintroducido el defecto que la primera pasada acababa de cerrar.

La 1 no es pereza: el eje ya está definido, medido y con su tabla en `agents/aceptacion.md`.
Inventar un segundo criterio para la misma pregunta es la clase de duplicación que este
repositorio se ha cobrado tres veces esta semana, y las tres en documentos que se archivan.

La 2 impide dos cosas a la vez. Que esto se vuelva ceremonia —si repetir dependiera de haber
tocado un fichero, corregir una errata pediría revisión nueva, y una regla que obliga a lo
obvio deja de aplicarse también en lo que importa—. Y que la excepción se ensanche al
reenunciarla: la primera versión de este delta decía «comentarios o **texto del acuerdo**», que
junta las dos filas que la tabla separa a propósito. En un kit donde el acuerdo lleva cláusulas
que se archivan como norma, esa redacción eximía de repasar justamente la clase de artefacto
donde este repositorio encuentra sus defectos — el bloqueante del caso fundacional de aquí
abajo vivía en una spec, no en el código. Lo cazó el juez de este mismo cambio.

**Límite declarado, y son dos.** Nadie comprueba nada: `rodaja.sh --revisada` marca cuando se
lo piden, sin saber si hubo revisión ni si alguien arregló después. Y la regla no acota su
propia repetición —si el segundo arreglo vuelve a mover comportamiento, pide una tercera
pasada—: lo que acota eso es el presupuesto de rondas que el flujo ya publica, y al agotarse
decide el owner. No se inventa aquí un tope de revisor, porque dos relojes que puedan discrepar
son peores que uno.

#### Scenario: El arreglo de una revisión mueve el comportamiento

- **WHEN** el revisor devuelve AMBER y arreglar lo que señaló cambia lo que alguna pieza hace
- **THEN** la rodaja no se marca
- **AND** se vuelve a pasar antes de marcarla

#### Scenario: El arreglo solo corrige una descripción

- **WHEN** arreglar lo que el revisor señaló solo cambia comentarios, mensajes, o una cláusula
  que describía mal lo que ya se hacía
- **THEN** la rodaja se marca sin repetir la pasada

#### Scenario: El arreglo reescribe lo que una norma manda

- **WHEN** arreglar lo que el revisor señaló cambia una cláusula del acuerdo que manda algo
  nuevo, y esa cláusula se fundirá en la spec canónica
- **THEN** la rodaja no se marca sin volver a pasarla

#### Scenario: El flujo describe el paso como es

- **WHEN** alguien lee en `docs/FLUJO.md` el paso del revisor
- **THEN** encuentra la condición para marcar
- **AND** encuentra que la pasada se anota en el acuerdo

#### Scenario: Lo que sigue faltando

- **WHEN** un documento del kit habla de lo que no hay sobre las rondas
- **THEN** no dice que no quede rastro de ellas
- **AND** dice que lo que falta es quien las cuente
