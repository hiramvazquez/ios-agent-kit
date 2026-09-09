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

### Requirement: Cada ronda deja escrito su veredicto en el acuerdo

Tras cada invocación del revisor o del juez, quien la invoca SHALL anotar el resultado en el
acuerdo del cambio.

1. La anotación SHALL decir qué ronda es, qué veredicto dio y qué encontró.
2. La anotación de una ronda de **juez** SHALL decir además qué pasó con el comportamiento,
   medido por **lo que los arreglos hicieron** y no por lo que el juez pidió, y SHALL
   distinguir tres casos: que algún arreglo cambiara lo que una pieza hace; que ninguno lo
   cambiara; y que se pidiera moverlo y no se hiciera. El tope no cuenta lo mismo en los dos últimos —el tercero es un desacuerdo
   abierto y su propia regla dice que NO es una ronda limpia— y un sí/no los colapsa.
   Las pasadas de **revisor** no llevan este dato: el revisor no tiene tope.
2bis. Los dos bloques SHALL identificarse por quién los produjo, y solo los de juez SHALL
   numerarse como rondas. Mezclarlos hace que el tope cuente pasadas de revisor y se dispare
   antes de tiempo, que es el error que su prompt llama el caro.
3. SHALL escribirla **quien invoca**, NO el sub-agente.
4. El sitio SHALL ser `tasks.md`, o el final de `proposal.md` cuando el cambio no lleve lista
   de tareas.

Esto existe porque el tope del juicio se apoya en un registro que **nadie escribía**. Su propio
texto dice que el contador lo lleva `tasks.md` porque el juez es un sub-agente y cada
invocación empieza en blanco; lo que faltaba era que alguien lo escribiera.

Medido el 2026-09-09 en el primer uso del kit fuera de este repositorio: en `AppStarter`, el
bucle entero del cambio `descuento-visible-en-carrito` —pasadas de revisor y ronda de juez— no
dejó ni una línea en su acuerdo archivado. El detalle de qué encontró cada una se perdió con
él, que es la mitad del daño. Reproducible sobre cualquier cambio archivado:

```
grep -cE '^## Del |AMBER|ACEPTADO|ronda' openspec/changes/archive/<cambio>/tasks.md
```

Y no lo pedía nadie: ni los dos comandos que lanzan a esos agentes, ni los dos prompts. En este
repositorio se anotaba porque quien orquestaba lo hacía por su cuenta, no porque el kit lo
pidiera — y eso hizo pasar por normal lo que era una costumbre de una sola casa.

La 3 es la cláusula que protege algo, no una preferencia de reparto. Los prompts de `agents/`
les prohíben escribir a propósito: el del juez termina diciendo que editar el acuerdo para que
encaje con lo entregado «es exactamente el fraude que este agente existe para impedir», y el
del revisor que no ejecuta nada que cambie estado del repositorio. Darles permiso de escritura
en la carpeta que juzgan abriría esa superficie para resolver un problema que se resuelve sin
ella. Quien invoca ya escribe, y además es el único que sabe si la ronda le hizo tocar código.

La 2 y la 2bis son las que hacen que el registro sirva al tope y no solo al historial, y las
dos las trajo el juez de este cambio leyéndolo **como consumidor del dato**: la primera versión
mandaba anotar un sí/no y pedía el flag también al revisor. El sí/no colapsaba dos casos que su
regla separa, y el revisor no tiene tope que alimentar — el criterio era más ancho que la
necesidad. Es la única ronda en la que quien consume el dato puede decir si le sirve, y dijo
que no del todo.

**Límite declarado.** Nadie comprueba que se anote: es una instrucción en un prompt, y
`autocomprueba.sh` —que mira frontmatter, rutas y recuentos de piezas— no entra aquí. Un
orquestador que se la salte deja el tope como estaba. Y queda un segundo canal, medido y no
cerrado: quien invoca puede decirle al juez en qué ronda va dentro del propio mensaje, sin que
eso quede escrito ni sea auditable; la regla de que en caso de discrepancia manda el acuerdo ya
está escrita y no cambia aquí.

#### Scenario: Una ronda de juez que devuelve el cambio

- **WHEN** el juez devuelve un veredicto y quien lo invocó arregla lo señalado
- **THEN** el acuerdo gana un bloque con la ronda, el veredicto y los hallazgos
- **AND** dice si esos arreglos movieron el comportamiento

#### Scenario: Una pasada de revisor

- **WHEN** el revisor devuelve GREEN, AMBER o RED
- **THEN** el acuerdo gana un bloque con esa pasada y lo que encontró
- **AND** el bloque dice que es del revisor, y no se numera como ronda de juicio

#### Scenario: El juez pide mover el comportamiento y no se mueve

- **WHEN** el juez señala algo que haría tocar comportamiento y quien lo invocó no lo hace
- **THEN** la anotación lo dice como desacuerdo abierto
- **AND** esa ronda no cuenta como limpia para el tope

#### Scenario: Un cambio sin lista de tareas

- **WHEN** el cambio se acogió a saltarse `tasks.md` y pasa por el revisor o el juez
- **THEN** la anotación va al final de `proposal.md`

#### Scenario: El sub-agente no escribe

- **WHEN** termina una invocación del revisor o del juez
- **THEN** el sub-agente no ha modificado ningún fichero del acuerdo
- **AND** la anotación la ha escrito quien lo invocó
