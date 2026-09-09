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
2. La comprobación SHALL hacerse leyendo el registro de las rondas, no de memoria, y SHALL
   mirar **si alguna ronda posterior a la última pasada de revisor movió el comportamiento** —
   «posterior» por el orden en que los bloques están escritos en el acuerdo: una pasada de
   revisor y una ronda de juez del mismo día no se pueden ordenar por su contenido, porque la
   del revisor no se numera a propósito —
   no solo la última. Y cuando NO haya ninguna pasada anotada, todas las rondas SHALL contar
   como posteriores. Una ronda **sin** ese dato NO SHALL leerse como «no»: SHALL contar como
   «sí», o preguntarse. La etiqueta llegó con la 1.9.2 y la mayoría de los acuerdos anteriores
   no la tiene, así que un registro mudo leído como «no» archivaría a ciegas justo lo que este
   requisito impide — es el mismo desempate que ya tienen las dos reglas hermanas. Las dos mitades cierran caminos por los que el predicado no decidía: mirar
   solo la última no dispara nunca —para archivar en regla la última es un ACEPTADO, que por
   definición no arregló nada—, y sin decir qué pasa con cero pasadas se queda sin ancla justo
   en el caso que hoy es mayoritario.
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
mueva comportamiento no dispara ninguna. Este mismo cambio es el ejemplo: su `tasks.md` no tiene
ni un bloque de revisor.

**Límite declarado, y es peor que el de su hermana.** Aquella se apoya al menos en un gesto del
kit: `rodaja.sh --revisada` es un script propio que alguien tiene que invocar. Aquí no hay
ninguno, así que la regla vive enteramente en dos prompts y quien no los siga archiva igual sin
que salte nada.

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
