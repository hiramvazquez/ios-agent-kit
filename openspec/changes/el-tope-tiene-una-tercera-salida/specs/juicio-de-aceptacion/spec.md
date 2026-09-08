## ADDED Requirements

### Requirement: El tope del juicio nombra los tres estados que lo disparan

Al alcanzar el tope de rondas sin hallazgos de código, el juez SHALL parar y decir en cuál de
tres estados está el cambio, en vez de elegir entre dos etiquetas que pueden no aplicar.

1. Las salidas SHALL ser tres: el acuerdo es incoherente y hay que reescribirlo; el alcance
   está mal y son dos cambios; o **el código y el acuerdo están bien y lo que queda son
   errores de hecho en el texto**.
2. Las tres SHALL parar el bucle. La tercera NO es una forma de seguir iterando.
3. Usar la tercera SHALL exigir haber descartado las otras dos **con la comprobación hecha**,
   y decir qué se comprobó.
4. Cada error de hecho que se liste SHALL ir con la evidencia que lo mide. Un defecto que no
   se pueda reducir a un hecho comprobable no es un error de hecho: es un problema de
   acuerdo, y entonces la salida es la primera.
5. Cuando ninguna de las tres encaje, el juez SHALL decirlo, describir lo que ve **y parar
   igual**, y NO SHALL elegir la más parecida.
6. Cuando lo encontrado en la ronda haga tocar código, el tope NO SHALL aplicar: esa ronda no
   cuenta como «sin hallazgos de código», y lo que toca es un veredicto normal.

La 5 es la que de verdad importa, y las otras cuatro existen para que casi nunca haga falta.
El 2026-09-08 un juez alcanzó el tope con dos salidas disponibles y las dos falsas —lo midió:
recorrió los criterios y las cláusulas de los deltas contra el código y contra tres
repositorios reales, y lo único que quedaba eran tres errores de hecho en la prosa—. Se negó a
firmar ninguna, porque hacerlo habría sido reescribir el hallazgo para que encajara con la
plantilla, que es exactamente el fraude que ese agente existe para impedir. Una plantilla que
obliga a mentir cuando la realidad no está en su lista es peor que no tener plantilla.

La 2 y la 3 existen por el riesgo evidente de la tercera salida: sin ellas, un juez
complaciente la usa siempre y el tope deja de morder. Con ellas, la tercera cuesta más trabajo
que las otras dos y no alarga el bucle ni una ronda.

El disparador no cambia: sigue siendo dos rondas seguidas sin que el código se mueva.

#### Scenario: El acuerdo aguanta y quedan errores de hecho

- **WHEN** el juez alcanza el tope, comprueba que el acuerdo es coherente y que el alcance no
  hay que partirlo, y lo que queda son afirmaciones falsas comprobables en el texto
- **THEN** para
- **AND** dice que el código y el acuerdo están bien
- **AND** lista cada error de hecho con la evidencia que lo mide
- **AND** deja la decisión de corregirlos o archivar con ellos al owner

#### Scenario: Ninguna de las tres salidas describe lo que hay

- **WHEN** el juez alcanza el tope y ninguna de las tres salidas describe el estado del cambio
- **THEN** lo dice y describe lo que ve
- **AND** para, sin veredicto
- **AND** no elige la salida más parecida

#### Scenario: La ronda del tope encuentra un fallo de código

- **WHEN** el juez llega a la ronda en la que se cumpliría el tope y encuentra algo que hace
  tocar código
- **THEN** emite un veredicto normal
- **AND** no usa ninguna salida de tope, porque el contador vuelve a cero
