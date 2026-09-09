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
