# Cuántas rondas merece esto

## Why

`docs/FLUJO.md` tiene una tabla que decide **si** un cambio necesita juez. No hay ninguna que
diga **cuántas rondas**, y la palabra «ronda» aparece una sola vez en toda la documentación del
kit.

El 2026-09-08 eso se cobró su primera factura. De los cambios que se cerraron ese día, uno —un
arreglo de unas 300 líneas— se llevó **cinco rondas de juez y una auditoría propia** sin
converger: cada una encontraba algo real, y
cinco de las nueve frases corregidas estaban en texto escrito por el arreglo de la ronda
anterior. Lo paró el owner preguntando «¿por qué tantas rondas?», no el kit.

### Lo que cuesta, medido

El 2026-09-08 hubo diecisiete rondas de juez en este repositorio. De nueve quedó cifra
registrada, y son esas nueve —una muestra por disponibilidad, no un censo— las que dan esto:

| | |
|---|---|
| coste de una ronda | **67k – 124k tokens** (9 rondas de 17) |
| el cambio de 25 ficheros | rondas de 124k y 99k |
| el cambio de 1 fichero y 1 sección | rondas de 67k y 79k |

**Veinticinco veces más grande, una vez y media más caro por ronda** —112k contra 74k de
media, un +52 %—. Ese es el hallazgo, y cambia dónde está la palanca: **el tamaño escala muy por
debajo de lo lineal**, así que acotar las rondas rinde mucho más que acotar el alcance.

No dice que el tamaño dé igual: un 52 % no es nada, y son dos cambios y cuatro rondas —según el
emparejamiento, el ratio va de 1,25 a 1,83—. La fórmula que `docs/FLUJO.md` ya publica
—«tamaño de lo revisado × número de rondas»— sigue siendo la buena; lo que se aprende es que su
primer factor crece despacio.

### Por qué la documentación no prepara para esto

`docs/PIEZAS.md` tiene una sección `## Coste` con los tokens de las piezas —«~1,6k el juez al
invocarlo»—. Es cierta y es la del **prompt**. Quien la lee concluye que juzgar es barato, y se
equivoca por un factor de entre cuarenta y ochenta, porque lo que se paga es la ronda entera: el juez leyendo
el acuerdo, corriendo los scripts y midiendo contra el repositorio.

No es una cifra mal puesta; es una cifra que responde otra pregunta. Y es exactamente la clase
que estos tres cambios han estado persiguiendo todo el día: **una afirmación cierta que promete
más de lo que da**, porque quien la lee saca la conclusión que no es.

## What Changes

- **`docs/FLUJO.md` gana una tabla hermana de la que ya tiene**: cuántas rondas presupuestar,
  según lo que se vaya a juzgar.
- **La regla que no depende del número**: el presupuesto se decide ANTES de invocar, y al
  agotarse la decisión de seguir es del owner. Es la misma forma que el tope del juez, movida
  al otro lado — el tope lo DETECTA desde dentro; el presupuesto lo DECLARA desde fuera y antes.
- **`docs/PIEZAS.md` separa las dos preguntas de coste**: lo que cuesta tener el kit puesto, y
  lo que cuesta una ronda de juicio. Con la medición fechada.

### Lo que la tabla dice, y por qué esas filas

El predictor no es el tamaño —eso está medido arriba—, es **qué se pone bajo juicio**:

- **Código con tests** converge rápido: hay verdad de campo. El juez mide contra algo.
- **Prosa y normas** no: el autor vuelve a redactar en cada arreglo, y redactar es lo que
  fabrica el hallazgo siguiente. Es el caso de las seis rondas.
- **Un cambio que reescribe un prompt o una spec** es el peor de los dos, porque el artefacto
  juzgado ES prosa normativa.

### La decisión de diseño

**El presupuesto es una declaración del autor, no una regla que el juez aplique.** No se toca
el prompt del juez: ya tiene su tope, que detecta el no-avance desde dentro, y ponerle además
un contador de presupuesto sería darle dos relojes que pueden discrepar. El presupuesto vive
en el flujo, lo pone quien abre el cambio, y quien lo agota es quien decide.

## Fuera de alcance

- **El prompt del juez.** No se toca: el tope de `juicio-de-aceptacion` ya cubre el no-avance
  desde dentro, y este cambio cubre el coste desde fuera. Dos mecanismos, un reloj cada uno.
- **El prompt del reviewer.** No tiene tope ni presupuesto y este cambio no se los pone.
- **Automatizar el presupuesto.** Nada cuenta rondas ni tokens por ti; ver el límite.
- **La tabla de «cuánto proceso pide cada cambio»** que ya existe. La nueva va al lado, no la
  sustituye: una decide qué artefactos escribes, la otra cuántas vueltas pagas.
- **El prompt del reviewer, que publica la misma fórmula de coste** («tamaño de lo revisado ×
  número de rondas»). No se toca porque la fórmula sigue siendo cierta y este cambio no la
  contradice: la matiza, y el matiz se escribe donde vive la tabla.
- **Volver a medir el coste de una ronda sobre código Swift**, que es el número que de verdad
  falta. Se declara como pendiente y no se inventa.

## Límite declarado

**Las cifras no se pueden recomprobar.** Salen de las notificaciones de los sub-agentes de
aquel día, que no viven en el repositorio, así que no hay comando que correr — al revés que la
tabla de coste de las piezas, que sí lo tiene. Va declarado donde se publican, porque el propio
kit exige que una medición fechada vaya con el comando que la produjo y esta no puede.

**Y es de un solo día, un solo repositorio, un solo tipo de artefacto, y nueve rondas de las
diecisiete de ese día.** Los tres
cambios del 2026-09-08 fueron sobre el kit, cuyo producto es en buena parte prosa: prompts,
specs y documentos. Es justo el caso que peor converge, así que **estas cifras son el techo, no
la media**, y sobre código Swift con tests deberían bajar — pero eso no está medido y la tabla
lo dice donde se lee.

**Y nada de esto lo comprueba nadie.** No hay contador de rondas ni de tokens: el presupuesto lo
lleva quien orquesta, a ojo. Un autor que no lo declare se queda como estaba, y eso no dispara
ninguna alarma.

## Criterios de aceptación

- [ ] `docs/FLUJO.md` SHALL tener una tabla de rondas presupuestadas, junto a la de proceso.
- [ ] La tabla SHALL decidir por **qué se pone bajo juicio**, no por el tamaño del cambio, y
      SHALL decir por qué — con la medición que lo sostiene.
- [ ] SHALL decir qué hacer al agotar el presupuesto: para y decide el owner.
- [ ] `docs/PIEZAS.md` SHALL distinguir el coste de tener el kit puesto del coste de una ronda
      de juicio, y la cifra de la ronda SHALL ir fechada.
- [ ] Ningún documento SHALL presentar las cifras del 2026-09-08 como media: SHALL decir que
      son de prosa normativa y que sobre código no están medidas.
- [ ] `agents/aceptacion.md` y `agents/reviewer.md` NO SHALL cambiar.
- [ ] `/kit-verifica` SHALL salir en verde y `autocomprueba.sh` limpio.
