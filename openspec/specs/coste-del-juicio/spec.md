# coste-del-juicio Specification

## Purpose
Que quien abre un cambio sepa **cuántas vueltas de juicio va a pagar** antes de empezar, y no
al final. El kit tenía una tabla para decidir qué artefactos escribir y ninguna para decidir
cuántas rondas presupuestar: la palabra «ronda» aparecía una sola vez en toda su documentación.

El coste está donde nadie miraba. Cargar el prompt del juez cuesta ~1,6k tokens; usarlo cuesta
entre cuarenta y ochenta veces eso, porque lo que se paga es la ronda entera. Las dos cifras
son ciertas y responden preguntas distintas, y publicar solo la primera hacía pensar que juzgar
es barato.

Lo que **no** pretende: automatizar nada. No hay contador de rondas ni de tokens, y no lo va a
haber por esto — el presupuesto lo lleva quien orquesta, a ojo, y un autor que no lo declare al
empezar se queda igual que antes de que esta capacidad existiera. Es una pregunta mejor, no un
detector, que es el orden que manda en esta casa.

Y lo que aprendió al nacer, porque vale más que las cifras: **la medición que la sostiene no se
puede recomprobar**. Salió de las notificaciones de unos sub-agentes que no viven en el
repositorio, así que no hay comando que correr — al contrario que la tabla hermana de coste de
las piezas, que sí lo tiene. Va declarado en los tres sitios donde se publica, porque el propio
kit exige que una medición fechada vaya con el comando que la produjo, y ésta no puede. Una
cifra que nadie puede rehacer no es falsa; es una cifra con dueño y con fecha de caducidad, y
hay que decirlo donde se lee.

## Requirements

### Requirement: El kit dice lo que cuesta juzgar, y presupuesta las rondas

La documentación del kit SHALL decir cuántas rondas de juicio presupuestar y qué cuesta una,
por separado de lo que cuesta tener el kit instalado.

1. `docs/FLUJO.md` SHALL llevar una tabla de rondas presupuestadas, al lado de la que ya decide
   qué artefactos escribir.
2. La tabla SHALL decidir por **qué se pone bajo juicio** —código con tests, prosa, una norma—
   y NO por el tamaño del cambio.
3. SHALL decir qué pasa al agotar el presupuesto: se para y decide el owner.
4. Toda cifra de coste de una ronda SHALL ir fechada y SHALL decir sobre qué se midió.
5. Ningún documento SHALL presentar esas cifras como media si se midieron sobre un solo tipo
   de artefacto.

La 2 no es intuición, pero tampoco es una ley: está medida con una muestra corta y así hay que
leerla. El 2026-09-08 hubo diecisiete rondas de juez en este repositorio; de nueve quedó cifra,
y esas nueve costaron entre 67,7k y 124,3k tokens. Comparando dos cambios de esa tanda, el de
veinticinco ficheros costó por ronda **una vez y media** lo que el de un fichero y una sección
—112,1k contra 73,9k de media, un **+52 %**—.

O sea: **el tamaño escala muy por debajo de lo lineal**, y por eso acotar las rondas rinde más
que acotar el alcance. NO dice que el tamaño dé igual —un 52 % no es nada— ni desmiente la
fórmula que el kit ya publica, «tamaño de lo revisado × número de rondas»: la matiza, diciendo
que su primer factor crece despacio. Una tabla que presupuestara por tamaño estaría midiendo el
factor que menos manda.

Y la muestra es la que es: dos cambios y cuatro rondas para el ratio —que según el
emparejamiento va de 1,25 a 1,83—, los cuatro poniendo **prosa normativa** bajo juicio. Sobre
código con tests no hay ni una medición.

La 4 y la 5 existen porque la cifra que ya había las incumplía sin querer. `docs/PIEZAS.md`
publicaba «~1,6k el juez al invocarlo» —cierto, y es el coste del **prompt**—, y quien lo leía
concluía que juzgar es barato: se equivocaba por un factor de entre cuarenta y ochenta. No estaba mal puesta;
respondía otra pregunta. Es la misma clase que estos cambios llevan persiguiendo todo el día
—una afirmación cierta que promete más de lo que da— y por eso las dos preguntas se separan en
vez de corregirse el número.

La 3 es lo que convierte esto en un mecanismo y no en un consejo. Es la forma del tope del
juez, movida al otro lado: **el tope detecta el no-avance desde dentro y al final; el
presupuesto lo declara desde fuera y antes.** Los dos paran igual, y los dos entregan la misma
decisión a la misma persona.

**Límite declarado, y son tres.** El primero es de procedencia y es el peor: **estas cifras no
se pueden recomprobar.** Salen de las notificaciones que dejaron los sub-agentes de aquel día,
que no viven en el repositorio, así que no hay comando que correr — al contrario que la tabla
hermana de coste de las piezas, que sí te manda correr uno. Quien las necesite ciertas tiene que
volver a medirlas.

El segundo: la medición es de un solo día, un solo repositorio y un solo tipo de artefacto
—prosa normativa, el caso que peor converge—, y de nueve rondas de las diecisiete de ese día.
Son un techo con muestra corta, no el coste típico. Las filas de la tabla que hablan de código
no tienen ninguna medición detrás.
Y nada de esto lo comprueba nadie: no hay contador de rondas ni de tokens, el presupuesto lo
lleva a ojo quien orquesta, y un autor que no lo declare se queda como estaba sin que salte
ninguna alarma.

#### Scenario: Alguien va a abrir un cambio y no sabe cuántas vueltas pagará

- **WHEN** consulta `docs/FLUJO.md` antes de empezar
- **THEN** encuentra cuántas rondas presupuestar según lo que va a poner bajo juicio
- **AND** encuentra qué hacer cuando se agoten

#### Scenario: Alguien quiere saber qué cuesta juzgar

- **WHEN** consulta el coste en `docs/PIEZAS.md`
- **THEN** distingue lo que cuesta tener el kit puesto de lo que cuesta una ronda de juicio
- **AND** la cifra de la ronda va fechada y dice sobre qué se midió

#### Scenario: Un cambio grande y uno pequeño

- **WHEN** se presupuestan las rondas de un cambio de muchos ficheros y las de uno de un solo
  fichero, y los dos ponen bajo juicio la misma clase de artefacto
- **THEN** el presupuesto no se decide por el tamaño

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

### Requirement: No se archiva sobre el arreglo de un juicio que no ha visto ningún revisor

Cuando arreglar lo que el juez señaló mueva el comportamiento, el cambio NO SHALL archivarse
sin que un revisor haya visto ese arreglo.

1. El disparador SHALL ser el mismo eje que usa el tope del juicio, leído de su tabla, y NO
   SHALL reenunciarse aquí en otros términos.
2. La comprobación SHALL hacerse leyendo el registro de las rondas, no de memoria, y NO SHALL
   describirse aquí como procedimiento: la hace `scripts/pasada-pendiente.sh`, cuyo contrato
   está en el requisito «Si falta una pasada de revisor, lo dice un script y no un párrafo».
   Este requisito SHALL limitarse a exigir que se invoque antes de archivar, y a fijar lo único
   que el script no puede deducir por sí solo: **los bloques SHALL escribirse al final del
   acuerdo y en un solo fichero**, sin agruparlos por tipo, porque «posterior» lo decide su
   orden en el fichero — una pasada de revisor y una
   ronda de juez del mismo día no se pueden ordenar por su contenido, ya que la del revisor no
   se numera a propósito.

   Cuando el script conteste que no se puede leer, el cambio NO SHALL archivarse sin mirarlo a
   mano. Esa salida es la razón de que exista: la versión en prosa de esta cláusula contestaba
   «no falta» en los casos que no sabía decidir, que es el lado que archiva.

3. `docs/FLUJO.md` SHALL describir la condición donde describe el archivado.
4. SHALL declararse que nada lo comprueba, y la razón SHALL ser la verdadera: no que el
   archivado sea imposible de interceptar, sino que el kit ha decidido no hacerlo.

Es el hermano del requisito que impide marcar una rodaja sobre código que no ha visto nadie, un
paso más adelante en el bucle: el juez devuelve, se arregla, y se archiva sin que ningún revisor
haya mirado ese arreglo. Lo destapó el juez del 2026-09-09 desmintiendo la frase «el único punto
del bucle donde todavía cabía» de aquel mismo cambio — no era el único, y él enseñó dónde
estaba el otro.

No va del todo a ciegas, y conviene decirlo para no inflar el agujero: al cambiar el árbol la
firma de verificación deja de valer y la puerta de commit obliga a re-verificar antes de
commitear, así que **build y tests lo acaban viendo** — aunque no necesariamente antes de
archivar. Lo que no lo ve es la pregunta del revisor —«¿esto rompe algo?»—, que es la que caza
lo que los tests no. En `AppStarter` esa diferencia tuvo precio el mismo día: una segunda pasada
de revisor encontró un defecto en una spec que ningún test podía ver y que al archivarse se
habría fundido en la canónica.

La 2 es lo que hace la regla barata. Desde que las rondas dejan rastro, comprobar si falta una
pasada no es acordarse de nada: se lee el acuerdo. Y es la composición de las tres piezas de
esta semana —el registro produce el dato, el tope lo consume para pararse, y estas dos reglas
para saber qué queda por mirar—, ninguna con un criterio propio.

**Lo que esta regla NO cubre**, dicho porque su título podría leerse como que sí: el código que
el autor cambia **por iniciativa propia** entre la última pasada de revisor y el archivado. Las
dos reglas hermanas se disparan por «arreglar lo que X señaló», así que una auditoría propia que
mueva comportamiento no dispara ninguna: se apoyan en «arreglar lo que X señaló», y una
auditoría propia no tiene X. El ejemplo con el que nació esta frase decía que el cambio que la
escribió «no tiene ni un bloque de revisor», y era falso —los tenía—; se quita el ejemplo y se
queda el hueco, que es lo que había que declarar.

**Límite declarado, y sigue siendo peor que el de su hermana.** Aquella se apoya en un gesto
del kit que se niega: `rodaja.sh --revisada` no marca. Aquí el script contesta pero no impide
nada, y solo contesta a quien lo llame, así que la regla sigue viviendo en unos prompts y quien
no los siga archiva igual sin que salte nada. Lo que el script quita no es ese hueco: quita que
la respuesta dependa de leer bien un párrafo.

Y la razón de que no haya puerta importa, porque la primera versión de esta cláusula decía que
el archivado **no se puede** interceptar y era falso: `/opsx:archive` corre el CLI por la
herramienta Bash, y el kit ya intercepta ahí `git commit`. Lo que lo impide es una política
escrita —`hooks/hooks.json`: «tres hooks y ninguno más; un cuarto tiene que traer escrito el
fallo que lo motiva»— y este todavía no lo trae: el fallo está observado, pero nadie ha medido
que la instrucción no baste. Deducir imposibilidad de una ausencia es la forma exacta del
defecto que originó este cambio, cometida al escribirlo.
Y hereda lo demás: si el arreglo posterior a la pasada vuelve a mover comportamiento, hace falta
otra, y lo que acota esa serie es el presupuesto de rondas, no esta regla.

#### Scenario: El arreglo de un DEVUELTO mueve el comportamiento

- **WHEN** el juez devuelve el cambio y arreglar lo que señaló cambia lo que alguna pieza hace
- **THEN** no se archiva sin que un revisor haya visto ese arreglo

#### Scenario: El arreglo de un juicio solo corrige una descripción

- **WHEN** arreglar lo que el juez señaló solo cambia comentarios, mensajes, o una cláusula que
  describía mal lo que ya se hacía
- **THEN** se archiva sin pasada nueva

#### Scenario: Saber si falta una pasada

- **WHEN** alguien va a archivar y quiere saber si el revisor ha visto lo último
- **THEN** lo lee en el registro de las rondas del acuerdo
- **AND** no depende de que nadie se acuerde

#### Scenario: El flujo lo dice donde se archiva

- **WHEN** alguien lee en `docs/FLUJO.md` el paso de archivar
- **THEN** encuentra la condición
- **AND** encuentra que nada la comprueba

### Requirement: Si falta una pasada de revisor, lo dice un script y no un párrafo

Saber si falta una pasada de revisor antes de archivar SHALL responderlo una pieza ejecutable, y
los documentos SHALL apuntar a ella en vez de explicar el procedimiento.

1. SHALL responder **una de tres cosas**: que falta una pasada, que no falta, o que **no se
   puede leer** — y SHALL distinguirlas en su código de salida con la misma forma que ya usa
   `verifica.sh` para «no pude mirar».
2. **La tercera SHALL ser la respuesta por defecto ante cualquier duda que el script pueda
   ver.** Un bloque **candidato** que no sepa clasificar, una ronda sin la etiqueta de
   comportamiento, o un acuerdo sin ningún bloque SHALL producirla — nunca «no falta». Candidato
   quiere decir que su encabezado nombre al juez, al revisor o a una revisión: es la única
   señal que el script tiene para saber que algo pretendía ser una ronda.

   **«Que pueda ver» está acotado por una medición, no por comodidad.** La versión anterior de
   esta cláusula decía «un bloque en formato desconocido», sin más, y era una promesa que el
   script no puede cumplir: `openspec/changes/archive/2026-09-09-lo-que-nadie-ha-visto-no-se-marca`
   y `.../2026-09-09-no-se-archiva-a-ciegas` tienen secciones `## Auditoría propia` que llevan la
   etiqueta de comportamiento y **no son rondas**. Tratar todo encabezado con etiqueta como una
   ronda que no sé leer daría falsa alarma sobre esas dos, así que la señal tiene que ser el
   vocabulario del encabezado. Lo que queda fuera se declara abajo; no se disfraza.
3. **SHALL mirar si ALGUNA ronda posterior a la última pasada movió el comportamiento, no solo
   la última.** Es el cuantificador, y la primera de las puertas que la versión en prosa no
   cerró: mirar solo la última no dispara nunca, porque para archivar en regla la última ronda
   es un ACEPTADO y un ACEPTADO por definición no arregló nada. El camino que esta regla existe
   para cerrar tiene esa forma exacta —DEVUELTO que mueve código, se arregla, ACEPTADO, se
   archiva—, así que sin acumular entre rondas el script contestaría «no falta» justo ahí. Su
   banco SHALL montar un caso con **dos** rondas de juez detrás de la última pasada: con una
   sola no se distingue acumular de mirar la última, y dos mutantes que reiniciaban los
   acumuladores en cada ronda pasaron el banco entero mientras faltó.

4. **Cuando NO haya ninguna pasada de revisor anotada, todas las rondas SHALL contar como
   posteriores.** Es el ancla que la versión en prosa tardó dos rondas en encontrar y el caso
   hoy mayoritario: sin ella, el acuerdo más frecuente del repositorio —rondas de juez y ningún
   bloque de revisor— se leería como «no falta».
5. SHALL reconocer las formas de bloque que existan en los acuerdos archivados —la cabecera y
   el item numerado, con o sin ordinal en medio—, y su banco SHALL montarlas como casos. Su
   veredicto NO SHALL depender del idioma de la máquina.
6. **Cuando los bloques estén repartidos entre `tasks.md` y `proposal.md`, SHALL contestar que
   no se puede leer.** Los dos ficheros se leen en un orden fijo que no es el cronológico, así
   que ahí «posterior» no está definido y concatenar fabrica una respuesta.
7. NO SHALL bloquear nada. Informa; decide quien archiva.

La 1 y la 2 son el cambio entero, y no son robustez: son el producto. El predicado que este
requisito sustituye llevaba **cuatro rondas** sin decidir en cuenta del revisor que la cerró
(`openspec/changes/archive/2026-09-09-no-se-archiva-a-ciegas/tasks.md`), y las cuatro fueron el mismo fallo —
faltaba el cuantificador, luego el ancla, luego el campo, luego el vocabulario del campo—. El
revisor que las cerró lo dijo mejor de lo que se puede parafrasear: **las cuatro puertas son
casos en los que la respuesta correcta era «no se puede leer, pregunta» y el texto contestó «no
falta»**. Un resultado binario obliga a elegir un lado cuando la respuesta honesta es que no se
sabe, y el lado que elige por defecto es el que archiva.

Que esto sea un script y no otro párrafo tampoco es preferencia. La regla de la casa exige que
un detector nazca solo si su clase falló dos veces y no hay forma más barata; falló cuatro, y la
forma barata se intentó: un `grep` de cabeceras puesto para no fiarse de la memoria, que
devuelve `0` sobre acuerdos archivados que **sí** tienen rondas —anotadas como item numerado— y
pierde variantes como «De la segunda revisión». En silencio y hacia el lado que archiva. **Un
instrumento que devuelve «cero» cuando quiere decir «no sé leer esto» es el mismo defecto, ahora
en shell.**

Y hay una razón que no es de corrección, cuyo síntoma se explica solo: **nadie sabía en cuántos
sitios estaba escrito** —el revisor contó cinco en un sitio y cuatro en otro; medido fichero a
fichero eran tres: `commands/kit-acepta.md`, `docs/FLUJO.md` y este documento—. Cada arreglo era
una edición a varias manos y la divergencia se cazó más de una vez,
incluida una en la que el arreglo no llegó al fichero principal. Un script no puede divergir
consigo mismo, y reduce esos enunciados a una invocación — que es la forma que este
repositorio ya adoptó dos veces esta semana: no reenunciar, apuntar.

**Límite declarado.** Es de alcance, y conviene no confundir sus partes. Por **forma**:
reconoce las dos que existen en los acuerdos archivados —la cabecera `## …` y el item numerado—,
y una tercera que alguien invente (`### …`, un item sin numerar) no la ve. Por **vocabulario**:
un encabezado con la forma buena pero cuyo título no nombre al juez, al revisor ni a una revisión
—`## Del árbitro supremo`, `## Segunda vuelta`— tampoco la ve. En los dos casos el bloque no
cuenta como ronda **ni dispara la tercera salida**, así que detrás de una pasada reconocida el
script contestaría «no falta» sobre una ronda que sí existía. Y por **contexto**: el script lee
líneas, no markdown, así que una cabecera de bloque escrita dentro de una valla de código —como
ejemplo del formato— cuenta como bloque, y una cabecera de revisor puesta ahí de ejemplo puede
cerrar rondas que sí estaban abiertas. Esta tercera parte la encontró la quinta pasada de
revisor; no ocurre en ningún acuerdo del repositorio, así que se declara y no se detecta —la
regla de la casa pide que su clase falle dos veces antes de que nazca un detector—.

Lo que ya **no** hace, porque era un defecto y no un límite: regalarle su etiqueta a la ronda
anterior. Cualquier encabezado cierra la ronda abierta, la sepa clasificar o no, así que un
bloque invisible ya no puede cancelar una tercera salida que estaba ganada.

Este límite no se cierra hoy y la razón está en la cláusula 2: la señal para decir «esto
pretendía ser una ronda» es el vocabulario del encabezado, y sin ella no se distingue una ronda
en forma rara de una sección legítima que no es una ronda. Se cierra el día que aparezca una
ronda escrita así, con su caso en el banco; el 2026-09-09 no había ninguna que medir en
`openspec/changes/archive/` —y este párrafo acaba en la spec canónica, donde envejece solo, así
que quien lo relea que lo recuente en vez de creerlo—, y por eso la cláusula 5 promete las formas archivadas y no «cualquier forma».

**Y un límite de fuerza, aparte.** Que alguien lo invoque no lo comprueba nadie: es un script, no una puerta,
y quien archive sin correrlo archiva igual. Lo que cambia no es que haya obligación, sino que la
respuesta deja de depender de leer bien un párrafo largo. Y «no se puede leer» saldrá a menudo al
principio, con razón: la etiqueta de comportamiento llegó con la 1.9.2 y la mayoría de los
acuerdos archivados no la tiene — antes esos mismos se leían como «no falta».

#### Scenario: Una ronda posterior movió el comportamiento

- **WHEN** el acuerdo tiene una pasada de revisor y, después, una ronda de juez cuya etiqueta
  dice que se movió el comportamiento
- **THEN** el script dice que falta una pasada

#### Scenario: Ninguna ronda posterior movió nada

- **WHEN** todas las rondas posteriores a la última pasada dicen que no se movió
- **THEN** el script dice que no falta

#### Scenario: Dos rondas detrás de la pasada, y la última limpia

- **WHEN** detrás de la última pasada hay una ronda que movió el comportamiento y, después, otra
  que no movió nada — que es la forma del camino normal: DEVUELTO, se arregla, ACEPTADO
- **THEN** el script dice que falta una pasada
- **AND** no se conforma con mirar la última

#### Scenario: Ninguna pasada anotada

- **WHEN** el acuerdo tiene rondas de juez que movieron el comportamiento y ningún bloque de
  revisor
- **THEN** el script dice que falta una pasada, porque sin pasada todas las rondas son
  posteriores

#### Scenario: Los bloques repartidos entre dos ficheros

- **WHEN** `tasks.md` y `proposal.md` tienen bloques cada uno
- **THEN** el script dice que no se puede leer, porque entre dos ficheros no hay orden

#### Scenario: Una ronda sin etiqueta

- **WHEN** una ronda posterior a la última pasada no lleva la etiqueta de comportamiento, o solo
  la cita dentro de una frase
- **THEN** el script dice que no se puede leer
- **AND** no dice que no falta

#### Scenario: Un bloque en un formato que no reconoce

- **WHEN** el acuerdo tiene un bloque candidato —su encabezado nombra al juez o al revisor—
  escrito de una forma que el script no sabe clasificar
- **THEN** dice que no se puede leer

#### Scenario: Un acuerdo sin ningún bloque

- **WHEN** el acuerdo no registra ninguna pasada ni ninguna ronda
- **THEN** dice que no se puede leer

#### Scenario: Los documentos apuntan en vez de explicar

- **WHEN** alguien lee el comando o el flujo para saber si falta una pasada
- **THEN** encuentra la invocación del script
- **AND** no un procedimiento que tenga que aplicar a mano
