# coste-del-juicio Specification

## Purpose
Que quien abre un cambio sepa **cuántas vueltas de juicio va a pagar** antes de empezar, y no
al final, y que el coste de una ronda se diga por separado del de tener el kit instalado: cargar
el prompt del juez es barato y usarlo cuesta mucho más, porque lo que se paga es la ronda entera.

Lo que **no** pretende: automatizar nada —no hay contador de rondas ni de tokens; el presupuesto
lo lleva quien orquesta, a ojo—.

## Requirements

### Requirement: El kit dice lo que cuesta juzgar, y presupuesta las rondas

La documentación del kit SHALL decir cuántas rondas de juicio presupuestar y qué orden de
magnitud cuesta una, por separado de lo que cuesta tener el kit instalado.

1. `docs/FLUJO.md` SHALL llevar una tabla de rondas presupuestadas, al lado de la que decide
   qué artefactos escribir.
2. La tabla SHALL decidir por **qué se pone bajo juicio** —código con tests, prosa, una norma—
   y NO por el tamaño del cambio.
3. SHALL decir qué pasa al agotar el presupuesto: se para y decide el owner, que puede pagar otra
   ronda, partir el cambio, o **archivar con un DEVUELTO que no sea del producto, dejando la deuda
   escrita en el acuerdo**. Un DEVUELTO del producto —una pieza que no hace lo acordado— y un
   ACUERDO-ROTO NO SHALL archivarse.
4. El coste de una ronda SHALL decirse como orden de magnitud respecto a cargar el prompt del
   agente, sin cifras: las que hubo no se podían recomprobar. Lo que sí se puede medir —lo que
   ocupa cada pieza cargada— SHALL remitirse al comando que lo da.

**Límite declarado.** No hay contador de rondas ni de tokens: el presupuesto lo lleva quien
orquesta.

#### Scenario: Alguien va a abrir un cambio y no sabe cuántas vueltas pagará

- **WHEN** consulta `docs/FLUJO.md` antes de empezar
- **THEN** encuentra cuántas rondas presupuestar según lo que va a poner bajo juicio
- **AND** encuentra qué hacer cuando se agoten

#### Scenario: Alguien quiere saber qué cuesta juzgar

- **WHEN** consulta el coste en `docs/PIEZAS.md`
- **THEN** distingue lo que cuesta tener el kit puesto de lo que cuesta una ronda de juicio
- **AND** encuentra el orden de magnitud de una ronda y el comando que mide lo demás

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
4. El kit NO SHALL contar las rondas: las cuenta quien orquesta.

**Límite declarado.** Nadie lo comprueba: `rodaja.sh --revisada` marca cuando se lo piden. Lo que
acota la serie es el presupuesto de rondas, y al agotarse decide el owner.

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

- **WHEN** alguien busca en el kit un contador de rondas
- **THEN** no existe: las cuenta quien orquesta contra el presupuesto que declaró

### Requirement: No se archiva sobre el arreglo de un juicio que no ha visto ningún revisor

Cuando arreglar lo que el juez señaló cambie lo que el código hace, el cambio NO SHALL archivarse
sin que un revisor haya visto ese arreglo.

1. El disparador SHALL ser el mismo que usa el tope del juicio.
2. `docs/FLUJO.md` SHALL describir la condición donde describe el archivado, y SHALL decir que
   nada la comprueba.

**Límite declarado.** Lo sabe quien arregló, y nada más: no hay script que lo lea ni hook que lo
impida. El kit ha decidido no poner un hook en el archivado —`hooks/hooks.json` exige que uno
nuevo traiga escrito el fallo que lo motiva—. Tampoco cubre el código que el autor cambia por
iniciativa propia entre la última pasada y el archivado.

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

### Requirement: La rodaja es del cambio que se revisa

Lo que paga una ronda de revisión es el tamaño de lo que se le entrega. La rodaja que
`rodaja.sh` entrega al revisor SHALL ser la del cambio que se revisa, no la del repositorio.

1. `rodaja.sh` SHALL aceptar la ruta del cambio en todos sus modos. Sin ruta SHALL usar el
   único cambio activo; con varios activos y sin ruta SHALL nombrarlos, pedir cuál, y NO SHALL
   imprimir tareas ni diff ni mover la marca.
2. Las tareas cerradas que lista SHALL ser las de ese cambio.
3. La rodaja NO SHALL empezar antes del principio de ese cambio: una marca de revisión
   anterior a él NO SHALL usarse, y una posterior SHALL usarse como hoy. «El principio del
   cambio» SHALL calcularse de una sola manera para la rodaja y para `--entregado`. Cuando
   ese principio no se conoce —la propuesta aún sin commitear— la marca SHALL usarse: una
   rodaja NO SHALL dejar fuera lo commiteado desde la última revisión.
4. La rodaja NO SHALL volcar ficheros de `openspec/changes/`, trackeados o nuevos. La salida
   de `--entregado` NO SHALL cambiar por este requisito.
5. Sin ningún cambio activo y sin ruta, la rodaja SHALL seguir yendo desde la marca.

**Límite declarado.** Lo que se commiteó antes de que el cambio empezara y nadie revisó deja de
entrar en la siguiente revisión: la rodaja ya no barre el repositorio. Y un commit ajeno al
cambio hecho a mitad de él sí entra, porque nada dice de quién es cada línea.

#### Scenario: Una marca más vieja que el cambio

- **WHEN** la última revisión marcada es anterior al commit que introdujo la propuesta del
  cambio, y en medio hay commits de otros cambios
- **THEN** la rodaja no contiene esos commits
- **AND** contiene todo lo del cambio que se revisa

#### Scenario: Una marca dentro del cambio

- **WHEN** la última revisión marcada es posterior al principio del cambio
- **THEN** la rodaja empieza en la marca, y solo trae lo hecho desde entonces

#### Scenario: La propuesta sigue sin commitear y hay un commit tras la marca

- **WHEN** el `proposal.md` del cambio no está commiteado, se marcó una revisión y después se
  commiteó código del cambio
- **THEN** la rodaja empieza en la marca
- **AND** contiene ese commit

#### Scenario: La propuesta va en un commit aparte, antes que el código

- **WHEN** el `proposal.md`, el diseño y las tareas del cambio se commitearon antes de
  implementarlo
- **THEN** la rodaja no vuelca esos ficheros
- **AND** las tareas cerradas siguen saliendo en su lista

#### Scenario: Dos cambios activos y nadie dice cuál

- **WHEN** se invoca `rodaja.sh` sin ruta con dos cambios activos
- **THEN** nombra los dos y pide la ruta
- **AND** no imprime tareas ni diff
