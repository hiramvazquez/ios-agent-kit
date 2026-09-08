# El tope del juez tiene una tercera salida

## Why

El 2026-09-08, juzgando el cambio `el-kit-se-aplica-a-si-mismo`, el juez de aceptación
alcanzó su tope —dos rondas sin hallazgos de código— y **se negó a obedecerlo**. Su prompt le
obliga, al llegar ahí, a escribir *una de dos frases* y parar. Midió las dos y las dos eran
falsas:

- **«El acuerdo necesita reescribirse entero»** — no. Recorrió los 17 criterios del proposal
  y las cláusulas de los seis deltas contra el código y contra tres repositorios reales, y
  todo cuadraba, incluida la tabla que la ronda anterior había corregido.
- **«Esto son dos cambios»** — tampoco. El propio proposal declaraba dónde cortaría y nadie
  había necesitado cortarlo; nada del diff caía fuera del encargo.

Lo que de verdad quedaba eran **tres errores de hecho en la prosa**: un «seis versiones» que
eran diez, un «100 y 130 líneas» que eran 98 y 141, y un puntero a un recuento que el arreglo
de la ronda anterior había quitado a propósito. Tres ediciones de una línea, ninguna de ellas
un problema de acuerdo ni de alcance.

Escribió esto:

> Lo que no hago es firmar una de sus dos frases para cumplir la forma: eso sería reescribir
> el hallazgo para que encaje con la plantilla, que es el fraude que este agente existe para
> impedir.

Y tiene razón, porque esa frase es literalmente la última línea de su propio prompt. **La
regla del tope le pedía cometer el fraude que la última línea le prohíbe.** Aplicó la mitad
operativa del tope —parar y que decida el owner—, que es lo único que salvaba el caso, y
propuso la salida que le falta.

### Por qué no es un caso raro

El tope se dispara por un síntoma —«dos rondas y el código no se ha movido»— y sus dos
salidas nombran dos causas posibles: el acuerdo es incoherente, o el alcance está mal. Pero
hay una tercera causa que produce el mismo síntoma y no tiene nombre: **el acuerdo está bien,
el código está bien, y lo que queda es un residuo de errores de hecho en el texto**. Es
además el estado más probable al final de un cambio largo, precisamente porque las dos
primeras causas se van corrigiendo por el camino.

Sin un nombre para ese estado, el juez tiene tres opciones y las tres son malas: mentir
eligiendo la etiqueta menos falsa, no parar —lo que el tope existe para impedir—, o salirse
de su propio guion, que es lo que hizo. Que funcionara fue mérito suyo, no del prompt.

## What Changes

- La sección «Tope» de `agents/aceptacion.md` pasa a tener **tres** salidas, cada una con la
  causa que la justifica.
- Se escribe qué hacer cuando **ninguna** encaja: decirlo, no elegir la más parecida.
- La tercera salida llega con las condiciones que impiden que sea una escapatoria.
- El caso del 2026-09-08 queda escrito al lado de la regla, como ya está el que desmintió a
  la versión anterior.

### La decisión de diseño que este cambio toma

**Que la tercera salida no se convierta en la puerta de atrás del tope.** El riesgo es obvio:
si el juez puede decir siempre «son errores de hecho, que decida el owner», el tope deja de
morder y volvemos a la ceremonia con veredicto que la regla existe para cortar. Tres
condiciones lo impiden, y las tres salen de lo que este juez hizo por su cuenta:

1. **Las tres salidas PARAN.** La tercera no es una forma de seguir iterando: cierra la ronda
   igual que las otras dos. Lo que cambia es qué se le dice al owner, no cuánto dura el
   bucle.
2. **Usarla obliga a descartar las otras dos, medido.** No basta con no elegirlas: hay que
   decir por qué no aplican, con la comprobación hecha. Este juez recorrió los criterios y
   los deltas antes de decir que el acuerdo aguantaba.
3. **Cada error de hecho va con su evidencia.** «Error de hecho» es una afirmación sobre un
   hecho, y se sostiene como cualquier otra: con el comando que lo mide. Un defecto que no se
   puede reducir a eso no es un error de hecho — es un problema de acuerdo, y entonces la
   salida es la primera.

**Y una regla por encima de las tres:** si ninguna encaja, el juez lo dice y describe lo que
ve. La plantilla está para ayudarle a parar, no para obligarle a mentir. Esto es lo único de
este cambio que no es «una salida más»: es la diferencia entre un guion y una camisa de
fuerza, y ya se ha cobrado un caso.

## Fuera de alcance

- **El disparador del tope.** «Dos rondas sin hallazgos de código» se queda como está: acertó
  en este caso —el código llevaba dos rondas quieto— y lo que falló fue la salida, no la
  detección.
- **El resto del prompt del juez.** Se toca la sección «Tope» y nada más. Las preguntas que
  hace, sus tres veredictos y la sección de los números del acuerdo no cambian.
- **Documentar el tope en `docs/PIEZAS.md` o en `docs/FLUJO.md`.** Hoy no está en ninguno de
  los dos, así que no hay nada que sincronizar; añadirlo es otra decisión y merece pensarse
  aparte.
- **El prompt del reviewer.** Tiene sus propios veredictos y no tiene tope. No se toca.
- **Cualquier mecanismo que compruebe que un juez obedece esta regla.** No existe y este
  cambio no lo inventa; ver el límite declarado abajo.

## Límite declarado

**Que un juez siga esta sección no lo comprueba nadie**, y puede ignorarla igual que cualquier
otra parte de su prompt. Lo único mecánico que roza lo que la sección dice es el lint de
censos de `autocomprueba.sh`, y hay que declararlo con precisión porque es fácil creerle de
más: mira los documentos del kit —README, `docs/`, agentes, comandos y skills—, busca
recuentos **de las piezas del kit**, no entra en `openspec/`, y no corre en los proyectos donde
este prompt se instala, porque no está en la plantilla de `kit.conf`. El censo a mano dentro de
un acuerdo, que es justo el que la tercera salida manda mirar, no lo caza nada.

Lo que este cambio mejora es la pregunta, no un detector — que es el orden que manda la regla
de la casa: primero se mejora la pregunta, después, si hace falta y la clase ya falló dos
veces, se escribe el detector.

La comprobación real es la de siempre: leerlo. Por eso los criterios de abajo se pueden
verificar mirando el fichero, y ninguno pretende ser una prueba automática.

## Criterios de aceptación

- [ ] La sección «Tope» de `agents/aceptacion.md` SHALL ofrecer tres salidas, cada una con la
      causa que la justifica escrita al lado.
- [ ] La tercera SHALL exigir las tres condiciones: que pare igual que las otras, que se
      descarten las otras dos con la comprobación hecha, y que cada error de hecho vaya con
      la evidencia que lo mide.
- [ ] La sección SHALL decir qué hacer cuando ninguna de las tres encaja: decirlo y describir
      lo que se ve, nunca elegir la más parecida.
- [ ] El caso del 2026-09-08 SHALL quedar escrito junto a la regla, con lo que el juez midió
      para descartar las dos salidas viejas — igual que ya está el caso que desmintió a la
      versión anterior de este tope.
- [ ] El disparador SHALL seguir siendo «dos rondas sin hallazgos de código», sin cambios.
- [ ] `git diff agents/aceptacion.md` NO SHALL tocar ninguna sección que no sea «Tope».
- [ ] El límite —que nada mecánico comprueba que un juez obedezca— SHALL quedar declarado en
      el propio fichero, no solo en este acuerdo.
- [ ] `/kit-verifica` SHALL seguir en verde, con `autocomprueba.sh` incluido.

## Nota sobre el proceso

Por la tabla de `docs/FLUJO.md`, un cambio de un solo fichero y alcance claro puede saltarse
`tasks.md`. Va con una lista mínima igualmente porque el esquema del CLI la pide para
`apply`, no porque el cambio la necesite.
