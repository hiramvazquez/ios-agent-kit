# juicio-de-aceptacion Specification

## Purpose

Que el veredicto del juez de aceptación sea **comprobable**: lo que se juzga tiene que ser lo
entregado, y cuando no haya nada entregado hay que decirlo en vez de dictaminar sobre lo que se
encuentre leyendo ficheros sueltos, porque un veredicto que nadie puede rebatir ni confirmar es
peor que uno equivocado.

Lo que **no** pretende: filtrar el diff por el cambio que se juzga. Lo entregado es una ventana
de tiempo —desde antes de que existiera la propuesta—, no un filtro por rutas, y quien juzgue
tiene que saber que puede estar viendo trabajo de otro cambio abierto antes de llamarlo «lo que
nadie pidió».

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

La 1 y la 2 describen el mismo fallo por dos caminos: en este flujo el commit es posterior al
juicio, así que `git diff main...HEAD` está vacío, y los ficheros nuevos sin trackear no salen
en ningún `git diff`.

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

La 4 es la otra mitad de la 1: un argumento que llega vacío devuelve el juicio sobre otro cambio
bajo un encabezado que dice «EN ESTE CAMBIO».

#### Scenario: Se nombra el cambio y hay otros abiertos

- **WHEN** se pide lo entregado de un cambio concreto y hay varios activos
- **THEN** la lista de tareas es la de ese cambio
- **AND** no se avisa de los demás, porque no se está eligiendo

#### Scenario: Se nombra algo que no es un cambio

- **WHEN** se pide lo entregado de una ruta que no existe o no tiene `proposal.md`
- **THEN** se dice y se para

### Requirement: El tope del juicio nombra los tres estados que lo disparan

Cuando dos rondas seguidas terminen sin que sus arreglos cambien lo que el código hace, el juez
SHALL parar y decir en cuál de tres estados está el cambio, en vez de emitir un veredicto.

1. Las salidas SHALL ser tres, dichas en una frase cada una: el acuerdo es incoherente y hay que
   reescribirlo; el alcance está mal y son dos cambios; o el código y el acuerdo están bien y lo
   que queda son errores de hecho en el texto, cada uno con su evidencia.
2. Las tres SHALL parar el bucle y pasar la decisión al owner.
3. Cuando ninguna de las tres encaje, el juez SHALL decirlo, describir lo que ve y parar igual, y
   NO SHALL elegir la más parecida.
4. Una ronda cuenta como «sin hallazgos» SI Y SOLO SI ninguno de sus arreglos cambia lo que hace
   el código que se entrega. Añadir o corregir pruebas NO es cambiar ese código, y corregir prosa
   —un prompt, una spec, un comentario, un mensaje— tampoco, aunque cambie lo que la prosa manda.
5. Si el juez pidió cambiar lo que el código hace y no se hizo, esa ronda NO SHALL contar como
   limpia: es un desacuerdo abierto, y se dice.
6. Cuando dos rondas devuelvan hallazgos de la misma clase, el juez SHALL decir si la búsqueda
   converge, mirando cuántas de las instancias nuevas las escribió el arreglo de la ronda anterior.

La 4 es la regla entera, y es estrecha a propósito: en prosa, cada arreglo reescribe la norma, y
reescribirla es lo que fabrica el hallazgo siguiente; ahí tiene que decidir el owner, no otra
ronda.

La 3 existe porque una lista de salidas que obliga a firmar la menos falsa es peor que no tener
lista.

**Límite declarado.** Que un juez cuente bien sus rondas no lo comprueba nadie. El contador no lo
lleva él —cada invocación empieza en blanco— sino la línea de cada ronda en el acuerdo: quien no la
escriba desarma el tope sin querer. Y un cambio a esta sección se juzga con el prompt del plugin
instalado, que es el anterior.

#### Scenario: Dos rondas que solo corrigen lo que el kit dice

- **WHEN** dos rondas seguidas terminan y ninguno de sus arreglos cambia lo que el código hace
- **THEN** el tope se alcanza
- **AND** el juez para y elige una de las tres salidas

#### Scenario: Una ronda que arregla lo que un banco comprueba

- **WHEN** la ronda hace añadir un fixture o una aserción, y el código que prueban no cambia
- **THEN** esa ronda NO cuenta como hallazgo de comportamiento

#### Scenario: Una ronda que solo cambia el mensaje de un caso

- **WHEN** la ronda hace corregir lo que un caso de banco imprime
- **THEN** esa ronda NO cuenta como hallazgo de comportamiento
- **AND** el hallazgo se reporta igual

#### Scenario: Una ronda que cambia lo que un prompt manda hacer

- **WHEN** la ronda hace reescribir una instrucción de un prompt o una cláusula de una spec, sin
  que el código cambie
- **THEN** esa ronda NO cuenta como hallazgo de comportamiento
- **AND** el hallazgo se reporta igual

#### Scenario: Una ronda que corrige una cláusula que describía mal lo que ya se hacía

- **WHEN** la ronda estrecha un requisito que prometía más de lo que el código da, sin que el
  código cambie
- **THEN** esa ronda NO cuenta como hallazgo de comportamiento

#### Scenario: El acuerdo aguanta y quedan errores de hecho

- **WHEN** el juez llega al tope, el acuerdo se sostiene y el alcance no hay que partirlo
- **THEN** escribe que lo que queda son errores de hecho en el texto
- **AND** lista cada uno con su evidencia

#### Scenario: La ronda del tope encuentra un fallo de código

- **WHEN** el juez llega a la ronda en la que se cumpliría el tope y encuentra algo que cambia lo
  que el código hace
- **THEN** el tope no aplica
- **AND** emite un veredicto normal

#### Scenario: El juez pide cambiar el código y no se hace

- **WHEN** el juez señala algo que cambiaría lo que el código hace y quien lo invocó no lo hace
- **THEN** esa ronda no cuenta como limpia

#### Scenario: Ninguna de las tres salidas describe lo que hay

- **WHEN** el juez llega al tope y ninguna de las tres etiquetas es cierta
- **THEN** lo dice, describe lo que ve y para
- **AND** no firma la menos falsa

#### Scenario: La misma clase de hallazgo en dos rondas

- **WHEN** dos rondas devuelven hallazgos de la misma clase
- **THEN** el juez dice si la búsqueda converge
- **AND** dice cuántas de las instancias nuevas las escribió el arreglo de la ronda anterior

### Requirement: Cada ronda deja escrito su veredicto en el acuerdo

Tras cada ronda del juez, quien lo invoca SHALL anotar el resultado en el acuerdo del cambio, en
una línea.

1. La línea SHALL decir qué ronda es, qué veredicto dio y qué pasó con el comportamiento: que algún
   arreglo cambió lo que hace el código que se entrega, que ninguno lo cambió, o que el juez pidió
   cambiarlo y no se hizo.
2. SHALL escribirla **quien invoca**, NO el sub-agente.
3. El sitio SHALL ser `tasks.md`, o el final de `proposal.md` cuando el cambio no lleve lista de
   tareas.
4. Las pasadas del revisor NO SHALL tener que anotarse, ni seguir un formato. Quien orquesta puede
   anotarlas si le sirve.

Existe porque el tope del juicio cuenta rondas y el juez es un sub-agente que empieza en blanco en
cada invocación: sin esa línea no tiene contador. Es el único dato que el tope consume, y por eso es
lo único que se pide.

La 2 protege algo: los prompts de `agents/` prohíben escribir a los agentes a propósito, porque
editar el acuerdo que se juzga es el fraude que el juez existe para impedir.

**Límite declarado.** Nadie comprueba que se anote. Un orquestador que se lo salte deja el tope sin
contador.

#### Scenario: Una ronda de juez que devuelve el cambio

- **WHEN** el juez devuelve un veredicto y quien lo invocó termina con lo que señaló
- **THEN** el acuerdo gana una línea con la ronda, el veredicto y qué pasó con el comportamiento

#### Scenario: El juez pide mover el comportamiento y no se mueve

- **WHEN** el juez señala algo que cambiaría lo que el código hace y quien lo invocó no lo hace
- **THEN** la línea lo dice como desacuerdo abierto
- **AND** esa ronda no cuenta como limpia para el tope

#### Scenario: Una pasada de revisor

- **WHEN** el revisor devuelve GREEN, AMBER o RED
- **THEN** nada obliga a anotarla

#### Scenario: Un cambio sin lista de tareas

- **WHEN** el cambio se acogió a saltarse `tasks.md` y pasa por el juez
- **THEN** la línea va al final de `proposal.md`

#### Scenario: El sub-agente no escribe

- **WHEN** termina una invocación del juez
- **THEN** el sub-agente no ha modificado ningún fichero del acuerdo
- **AND** la línea la ha escrito quien lo invocó
