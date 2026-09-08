# juicio-de-aceptacion Specification

## Purpose

Que el veredicto del juez de aceptación sea **comprobable**. Un juez que dictamina sobre una
entrada vacía no miente: emite un veredicto que nadie puede rebatir ni confirmar, y eso es
peor que equivocarse, porque no deja rastro. Lo que se juzga tiene que ser lo entregado, y
cuando no haya nada entregado hay que decirlo en vez de dictaminar sobre lo que se encuentre
leyendo ficheros sueltos.

Lo que **no** pretende: filtrar el diff por el cambio que se juzga. Lo entregado es una
ventana de tiempo —desde antes de que existiera la propuesta—, no un filtro por rutas, y
filtrar dejaría fuera precisamente lo que el juez busca: el código que no responde a ningún
criterio. Quien juzgue tiene que saber que puede estar viendo trabajo de otro cambio abierto,
y mirarlo antes de llamarlo «lo que nadie pidió».

## Requirements

### Requirement: El juez recibe lo entregado, no un diff vacío

El conjunto de cambios que se le da al juez de aceptación SHALL contener el trabajo que se
está juzgando en el momento en que se le invoca.

1. Con el trabajo del cambio SIN commitear, ese conjunto NO SHALL estar vacío.
2. SHALL incluir los ficheros nuevos que aún no están trackeados.
3. SHALL abarcar desde el principio del cambio, no desde la última marca de revisión: el
   revisor juzga rodajas, el juez juzga el cambio entero.
4. Cuando el conjunto esté vacío de verdad —no hay nada entregado—, el juez SHALL decirlo y
   parar, en vez de dictaminar leyendo ficheros sueltos.

La 1 y la 2 describen el mismo fallo por dos caminos. `git diff main...HEAD` está vacío
mientras el trabajo no esté commiteado, y en este flujo el commit es posterior al juicio;
y aunque estuviera commiteado, los ficheros nuevos sin trackear no salen en ningún `git
diff` —es la ceguera que ya costó una revisión de 700 líneas vista como 26.

La 4 es la que convierte el fallo en visible. Un juez con `Read` y `Grep` puede dictaminar
sin diff y no enterarse de que le falta la fuente; y un veredicto emitido sobre una entrada
vacía no es falso necesariamente, es **incomprobable**, que es peor.

#### Scenario: El trabajo del cambio está sin commitear

- **WHEN** se invoca al juez con el cambio implementado y sin commitear
- **THEN** recibe un conjunto de cambios no vacío
- **AND** ese conjunto incluye los ficheros nuevos sin trackear

#### Scenario: No hay nada entregado

- **WHEN** se invoca al juez y no hay ningún cambio en el árbol
- **THEN** el juez lo dice y para
- **AND** no emite veredicto sobre los criterios

### Requirement: El juez invoca los scripts del kit por la raíz del plugin

Todo fichero del kit que el prompt de un agente mande ejecutar SHALL citarse por una ruta
que se resuelva desde la raíz del plugin.

1. Ninguna ruta relativa al repositorio del proyecto SHALL usarse para invocar un script del
   kit, porque los scripts no viven ahí.
2. Un fallo al ejecutar esa invocación SHALL ser visible en la salida del agente, no
   silencioso.

`Scripts/verifica.sh` es la ruta que hay hoy en el prompt del juez, dos veces. En un proyecto
real esa ruta o no existe, o existe y es otra cosa: `AppStarter` tiene un `Scripts/` con
otros dos scripts dentro.

#### Scenario: El juez pide el informe de verificación

- **WHEN** el juez ejecuta la línea que le da el informe de `verifica.sh`
- **THEN** la ruta se resuelve desde la raíz del plugin
- **AND** el informe llega, o el fallo se ve

### Requirement: El juicio recae sobre el cambio que se nombra

Cuando se le diga al juez QUÉ cambio juzga, todo lo que reciba SHALL ser de ese cambio.

1. La lista de tareas SHALL ser la del cambio nombrado, aunque haya otros abiertos.
2. El conjunto de cambios SHALL abarcar desde la propuesta de ese cambio, y PUEDE contener
   trabajo de cambios abiertos después: es una ventana temporal, no un filtro por rutas.
   Quien juzgue tiene que saberlo antes de llamar «lo que nadie pidió» a lo que ve.
3. Una ruta que no exista, o que no sea un cambio, SHALL producir un error visible y no un
   juicio sobre otra cosa.
4. Las instrucciones del juez SHALL escribir esa ruta literalmente en cada comando, no en una
   variable de shell: cada invocación de Bash es un shell nuevo y una variable de la llamada
   anterior llega vacía.

Sin la 1, con dos cambios abiertos el juez leía el acuerdo de uno y la lista de tareas del
otro, bajo un encabezado que dice «EN ESTE CAMBIO» — y justo después de que su prompt le
ordenara recorrer la lista y no el diff. La 4 es la otra mitad del mismo fallo: un argumento
que llega vacío devuelve exactamente el comportamiento que la 1 arregla.

La 2 se escribió después de que un revisor la reprodujera: la redacción anterior prometía que
«el diff» sería el del cambio nombrado, y no lo es ni puede serlo sin filtrar por rutas —cosa
que dejaría fuera precisamente lo que el juez busca, el código que no responde a ningún
criterio—. Prometer un filtro que no existe es peor que declarar la ventana: con dos cambios
abiertos, el juez habría llamado ACUERDO-ROTO al trabajo del vecino.

#### Scenario: Se nombra el cambio y hay otros abiertos

- **WHEN** se pide lo entregado de un cambio concreto y hay varios activos
- **THEN** la lista de tareas es la de ese cambio
- **AND** no se avisa de los demás, porque no se está eligiendo

#### Scenario: Se nombra algo que no es un cambio

- **WHEN** se pide lo entregado de una ruta que no existe o no tiene `proposal.md`
- **THEN** se dice y se para

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
