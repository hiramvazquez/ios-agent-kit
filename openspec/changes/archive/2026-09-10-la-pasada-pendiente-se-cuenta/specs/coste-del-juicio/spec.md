# coste-del-juicio — delta

## ADDED Requirements

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

## MODIFIED Requirements

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
