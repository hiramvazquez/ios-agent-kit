# coste-del-juicio — delta

## ADDED Requirements

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
