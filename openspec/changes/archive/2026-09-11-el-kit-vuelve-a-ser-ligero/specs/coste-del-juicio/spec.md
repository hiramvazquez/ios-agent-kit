# Coste del juicio — delta

## MODIFIED Requirements

### Requirement: El kit dice lo que cuesta juzgar, y presupuesta las rondas

La documentación del kit SHALL decir cuántas rondas de juicio presupuestar y qué cuesta una,
por separado de lo que cuesta tener el kit instalado.

1. `docs/FLUJO.md` SHALL llevar una tabla de rondas presupuestadas, al lado de la que ya decide
   qué artefactos escribir.
2. La tabla SHALL decidir por **qué se pone bajo juicio** —código con tests, prosa, una norma—
   y NO por el tamaño del cambio.
3. SHALL decir qué pasa al agotar el presupuesto: se para y decide el owner, que puede pagar otra
   ronda, partir el cambio, o **archivar con un DEVUELTO que no sea del producto, dejando la deuda
   escrita en el acuerdo**. Un DEVUELTO del producto —una pieza que no hace lo acordado— y un
   ACUERDO-ROTO NO SHALL archivarse.
4. Las cifras de coste de una ronda SHALL vivir solo en `docs/PIEZAS.md`, fechadas y diciendo
   sobre qué se midieron. `docs/FLUJO.md` NO SHALL copiarlas.
5. Ningún documento SHALL presentar esas cifras como media si se midieron sobre un solo tipo de
   artefacto.

La 2 está medida con una muestra corta: el 2026-09-08, un cambio veinticinco veces más grande que
otro costó por ronda una vez y media lo que él, así que acotar las rondas rinde más que acotar el
alcance. El detalle y sus límites viven con las cifras, en `docs/PIEZAS.md`.

La 3 cierra una contradicción que el flujo tuvo escrita: «no se archiva con DEVUELTO» en el paso
de archivar, y «archivar con la deuda anotada» al agotar el presupuesto. Sin la salida del owner,
un cambio cuyo producto está bien y cuya prosa sigue dando hallazgos no termina nunca, que es el
bucle que el tope y el presupuesto existen para cortar.

**Límite declarado.** Nada de esto lo comprueba nadie: no hay contador de rondas ni de tokens, el
presupuesto lo lleva quien orquesta, y las cifras no se pueden recomprobar —salen de
notificaciones de sub-agentes que no viven en el repositorio—.

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

#### Scenario: Se agota el presupuesto y lo que queda no es del producto

- **WHEN** se agota el presupuesto y el juez devuelve el cambio solo por prosa
- **THEN** el owner puede archivarlo
- **AND** la deuda queda escrita en el acuerdo

#### Scenario: Se agota el presupuesto y el producto no cumple

- **WHEN** se agota el presupuesto y el juez devuelve el cambio porque una pieza no hace lo
  acordado, o dice ACUERDO-ROTO
- **THEN** el cambio no se archiva

### Requirement: Una rodaja no se marca sobre código que no ha visto nadie

Cuando arreglar lo que el revisor encontró cambie lo que el código hace, la rodaja NO SHALL
marcarse como revisada sin volver a pasarla.

1. El disparador SHALL ser el mismo que usa el tope del juicio —que un arreglo cambie lo que hace
   el código que se entrega— y SHALL remitir a él en vez de definir uno nuevo.
2. Corregir pruebas, prosa, comentarios, mensajes o una cláusula —también una que cambie lo que la
   norma manda— NO SHALL obligar a repetir la pasada.
3. `docs/FLUJO.md` SHALL describir esa condición donde describe el marcado.
4. Ningún documento del kit SHALL decir que el kit cuenta las rondas: las cuenta quien orquesta.

Marcar una rodaja significa «desde aquí no se vuelve a revisar». Hacerlo después de cambiar código
convierte el marcado en una afirmación sobre un árbol que ya no es el revisado.

Medido el 2026-09-09 en `AppStarter`, y no por el kit: quien implementaba se dio cuenta solo y
volvió a pasarlo, y **la segunda pasada encontró un defecto que bloqueaba** —la spec se contradecía
consigo misma, y al archivar se habría fundido en la canónica—.

**Límite declarado.** Nadie lo comprueba: `rodaja.sh --revisada` marca cuando se lo piden. Y la
regla no acota su propia repetición: lo que la acota es el presupuesto de rondas, y al agotarse
decide el owner.

#### Scenario: El arreglo de una revisión mueve el comportamiento

- **WHEN** el revisor devuelve AMBER y arreglar lo que señaló cambia lo que el código hace
- **THEN** la rodaja no se marca
- **AND** se vuelve a pasar antes de marcarla

#### Scenario: El arreglo solo corrige una descripción

- **WHEN** arreglar lo que el revisor señaló solo cambia pruebas, comentarios, mensajes, prosa o
  una cláusula que describía mal lo que ya se hacía
- **THEN** la rodaja se marca sin repetir la pasada

#### Scenario: El arreglo reescribe lo que una norma manda

- **WHEN** arreglar lo que el revisor señaló cambia lo que manda una cláusula del acuerdo o un
  prompt, sin que el código cambie
- **THEN** la rodaja se marca sin repetir la pasada
- **AND** si esa prosa sigue dando hallazgos, lo que acota la serie es el presupuesto

#### Scenario: El flujo describe el paso como es

- **WHEN** alguien lee en `docs/FLUJO.md` el paso del revisor
- **THEN** encuentra la condición para marcar

#### Scenario: Lo que sigue faltando

- **WHEN** un documento del kit habla de las rondas
- **THEN** no dice que el kit las cuente

### Requirement: No se archiva sobre el arreglo de un juicio que no ha visto ningún revisor

Cuando arreglar lo que el juez señaló cambie lo que el código hace, el cambio NO SHALL archivarse
sin que un revisor haya visto ese arreglo.

1. El disparador SHALL ser el mismo que usa el tope del juicio, y NO SHALL reenunciarse aquí en
   otros términos.
2. `docs/FLUJO.md` SHALL describir la condición donde describe el archivado.
3. SHALL declararse que nada lo comprueba, y la razón SHALL ser la verdadera: no que el archivado
   sea imposible de interceptar, sino que el kit ha decidido no hacerlo.

Es el hermano del requisito de la rodaja, un paso más adelante: el juez devuelve, se arregla, y se
archiva sin que ningún revisor haya mirado ese arreglo. Build y tests lo acaban viendo —la firma se
invalida y la puerta de commit obliga a re-verificar—, pero no la pregunta del revisor, que es la
que caza lo que los tests no.

**Límite declarado.** Lo sabe quien arregló, y nada más: no hay script que lo lea ni hook que lo
impida. `/opsx:archive` corre por la herramienta Bash, donde la puerta de commit ya intercepta
`git commit`; lo que impide poner otra puerta es la política de `hooks/hooks.json` —un hook nuevo
tiene que traer escrito el fallo que lo motiva—, y este no lo trae. Tampoco cubre el código que el
autor cambia por iniciativa propia entre la última pasada y el archivado.

#### Scenario: El arreglo de un DEVUELTO mueve el comportamiento

- **WHEN** el juez devuelve el cambio y arreglar lo que señaló cambia lo que el código hace
- **THEN** no se archiva sin que un revisor haya visto ese arreglo

#### Scenario: El arreglo de un juicio solo corrige una descripción

- **WHEN** arreglar lo que el juez señaló solo cambia pruebas, comentarios, mensajes, prosa o una
  cláusula
- **THEN** se archiva sin pasada nueva

#### Scenario: Saber si falta una pasada

- **WHEN** alguien va a archivar y quiere saber si el revisor ha visto lo último
- **THEN** lo decide quien arregló, según si su arreglo cambió lo que el código hace
- **AND** no hay script ni registro que lo lea por él

#### Scenario: El flujo lo dice donde se archiva

- **WHEN** alguien lee en `docs/FLUJO.md` el paso de archivar
- **THEN** encuentra la condición
- **AND** encuentra que nada la comprueba

## REMOVED Requirements

### Requirement: Si falta una pasada de revisor, lo dice un script y no un párrafo

**Reason**: `scripts/pasada-pendiente.sh` lee un registro de pasadas y rondas que solo se escribió
en el repositorio del kit. Sobre los ocho cambios archivados de `AppStarter`, el único proyecto
real, contesta «no se puede leer» en los ocho (medido el 2026-09-11), y no cazó nada fuera del
propio kit. Con la anotación reducida a la ronda del juez, el registro que leía deja de existir
también aquí.

**Migration**: Quien arregló sabe si su arreglo cambió lo que el código hace; si lo cambió, pasa
el revisor antes de archivar. La condición sigue en «No se archiva sobre el arreglo de un juicio
que no ha visto ningún revisor».
