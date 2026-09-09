# juicio-de-aceptacion — delta

## MODIFIED Requirements

### Requirement: El tope del juicio nombra los tres estados que lo disparan

Al alcanzar el tope de rondas que no cambian el comportamiento, el juez SHALL parar y decir en
cuál de tres estados está el cambio, en vez de elegir entre dos etiquetas que pueden no
aplicar.

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
6. Una ronda cuenta como «sin hallazgos» SI Y SOLO SI ninguno de sus arreglos cambia **lo que
   alguna pieza tiene que hacer**. El criterio SHALL ser ese, NO el fichero donde vive la
   línea: un comentario, un mensaje de prueba o un ejemplo no cuentan, vivan en un `.md`, en un
   `.sh` o en un `.conf`.
6bis. En un kit hecho en parte de prompts y de acuerdos, cambiar **lo que un prompt o una norma
   MANDAN hacer** SHALL contar como comportamiento; corregir una cláusula que **describía mal**
   lo que ya se hacía, NO. Y cuando el caso no encaje con claridad, SHALL contarse como
   comportamiento: el error caro de este tope es dispararse pronto.
7. Cuando dos rondas devuelvan hallazgos de la MISMA clase, el juez SHALL decir si la búsqueda
   converge, y SHALL mirar **cuántas de las instancias nuevas las escribió el arreglo de la
   ronda anterior**.

La 5 es la que de verdad importa, y las otras existen para que casi nunca haga falta.
El 2026-09-08 un juez alcanzó el tope con dos salidas disponibles y las dos falsas —lo midió:
recorrió los criterios y las cláusulas de los deltas contra el código y contra tres
repositorios reales, y lo único que quedaba eran tres errores de hecho en la prosa—. Se negó a
firmar ninguna, porque hacerlo habría sido reescribir el hallazgo para que encajara con la
plantilla, que es exactamente el fraude que ese agente existe para impedir. Una plantilla que
obliga a mentir cuando la realidad no está en su lista es peor que no tener plantilla.

La 2 y la 3 existen por el riesgo evidente de la tercera salida: sin ellas, un juez
complaciente la usa siempre y el tope deja de morder. Con ellas, la tercera cuesta más trabajo
que las otras dos y no alarga el bucle ni una ronda.

**La 6 sustituye a una que decía «cuando lo encontrado haga tocar código, el tope NO aplica», y
el cambio es el eje, no el umbral.** «Tocar código» se leyó —razonablemente— como «editar un
fichero de código», y con esa lectura el tope no se disparó en SEIS rondas seguidas sobre
`el-hermano-que-quedaba`: lo que se movía eran mensajes de casos de banco, comentarios y notas
de `kit.conf`, ficheros que se quedan en el repositorio y no se archivan. El producto llevaba
correcto y verificado en tres repositorios reales desde antes de la primera ronda. Es
literalmente el bucle que este tope existe para cortar, colándose por una tecnicalidad.

La otra lectura —«los comentarios no cuentan»— habría sido igual de falsa: este kit tiene
documentado un comentario caducado que pasó diez versiones publicadas. Lo que separa las dos
mitades no es el fichero: es si el arreglo cambia lo que la pieza hace. Cambiar lo que un caso
de banco **comprueba** es comportamiento; cambiar lo que **imprime**, no. Los dos importan; solo
uno paga la ronda siguiente.

**Y la 7 sale del mismo caso, de la única pregunta que lo desatascó.** En la quinta ronda el
owner preguntó si aquello convergía, y el juez lo midió: de las nueve frases defectuosas
corregidas, **cinco estaban en texto escrito por el arreglo de la ronda anterior**, dos de ellas
dentro del parche de la instancia previa. Cada arreglo volvía a reformular la garantía, y
reformularla era lo que fabricaba la siguiente. Con ese dato en la mano el arreglo dejó de ser
otro parche y pasó a ser estructural. **Ninguna de las seis rondas lo habría producido, porque
el prompt no lo pedía.**

**Límite declarado, y son tres.** Que un juez cuente bien sus rondas no lo comprueba nadie, y
con esta regla menos, porque la distinción la aplica él leyendo. El contador no lo lleva él
—es un sub-agente y cada invocación empieza en blanco— sino `tasks.md`, que su «Entrada» ya le
manda leer: funciona, y por eso un autor que no anote sus rondas desarma el tope sin querer. Y
un cambio que toque esta sección se juzgará con el prompt del plugin instalado, que es el
anterior — el juez no tendrá delante la regla que está juzgando.

El disparador no cambia: siguen siendo dos rondas seguidas.

#### Scenario: Dos rondas que solo corrigen lo que el kit dice

- **WHEN** dos rondas seguidas terminan y ninguno de sus arreglos cambia lo que alguna pieza
  hace, aunque las líneas corregidas vivan en scripts y en `kit.conf`
- **THEN** el tope se alcanza
- **AND** el juez para y elige una de las tres salidas

#### Scenario: Una ronda que arregla lo que un banco comprueba

- **WHEN** la ronda hace añadir un fixture o una aserción que el banco no tenía
- **THEN** esa ronda cuenta como hallazgo de comportamiento
- **AND** el contador vuelve a cero

#### Scenario: Una ronda que solo cambia el mensaje de un caso

- **WHEN** la ronda hace corregir lo que un caso de banco imprime, sin tocar lo que comprueba
- **THEN** esa ronda NO cuenta como hallazgo de comportamiento
- **AND** el hallazgo se reporta igual, porque el mensaje se queda en el repositorio

#### Scenario: La misma clase de hallazgo en dos rondas

- **WHEN** dos rondas devuelven hallazgos de la misma clase
- **THEN** el juez dice si la búsqueda converge
- **AND** dice cuántas de las instancias nuevas las escribió el arreglo de la ronda anterior

#### Scenario: El acuerdo aguanta y quedan errores de hecho

- **WHEN** el juez llega al tope y comprueba que el acuerdo se sostiene y el alcance no hay que
  partirlo
- **THEN** escribe que lo que queda son errores de hecho en el texto
- **AND** lista cada uno con la evidencia que lo mide

#### Scenario: Ninguna de las tres salidas describe lo que hay

- **WHEN** el juez llega al tope y ninguna de las tres etiquetas es cierta
- **THEN** lo dice, describe lo que ve y para
- **AND** no firma la menos falsa

#### Scenario: Una ronda que cambia lo que un prompt manda hacer

- **WHEN** la ronda hace corregir una instrucción que un prompt del kit da a un agente
- **THEN** esa ronda cuenta como hallazgo de comportamiento

#### Scenario: Una ronda que corrige una cláusula que describía mal lo que ya se hacía

- **WHEN** la ronda estrecha un requisito que prometía más de lo que el código da, sin que el
  código cambie
- **THEN** esa ronda NO cuenta como hallazgo de comportamiento

#### Scenario: La ronda del tope encuentra un fallo de código

- **WHEN** el juez llega a la ronda en la que se cumpliría el tope y encuentra algo que mueve
  el comportamiento
- **THEN** el tope no aplica
- **AND** emite un veredicto normal
