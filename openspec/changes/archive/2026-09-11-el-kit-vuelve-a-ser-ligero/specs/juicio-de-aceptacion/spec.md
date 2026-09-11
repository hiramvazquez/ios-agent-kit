# Juicio de aceptación — delta

## MODIFIED Requirements

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

La 4 es la regla entera, y es estrecha a propósito. La versión anterior contaba como
comportamiento añadir un fixture a un banco y cambiar lo que una norma manda, y en la duda
desempataba hacia «sí»: con esa tabla el tope no se disparó ni una vez desde el 2026-09-08, porque
toda ronda que busca encuentra un caso sin prueba o una frase que reescribir. En prosa, cada
arreglo reescribe la norma, y reescribirla es lo que fabrica el hallazgo siguiente; ahí tiene que
decidir el owner, no otra ronda.

La 3 existe porque una lista de salidas que obliga a firmar la menos falsa es peor que no tener
lista: el 2026-09-08 un juez llegó al tope con dos etiquetas, las dos falsas, y se negó a firmar.

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

La 4 es la mitad que se retira. Anotar las pasadas del revisor con formato fijo servía a un script
que leía ese registro, y el script se retiró el 2026-09-11: sobre `AppStarter`, el único proyecto
real, no tenía nada que leer.

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
