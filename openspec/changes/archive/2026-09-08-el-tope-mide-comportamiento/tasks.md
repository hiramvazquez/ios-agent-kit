# Tareas

Un solo fichero y una sola sección, como el cambio que trajo la tercera salida. La lista va
porque el esquema del CLI la pide para `apply`, no porque el cambio la necesite.

- [x] 1. **Reescribir el disparador de la sección «Tope» de `agents/aceptacion.md`** para que
      la ronda se cuente por si sus arreglos cambian el COMPORTAMIENTO de alguna pieza, y no
      por el fichero en el que vive la línea.

- [x] 2. **Dar el par de ejemplos que separa las mitades dentro de un mismo fichero**: lo que
      un caso de banco comprueba (comportamiento) frente a lo que imprime (no). Y decir que no
      contar no es ser irrelevante — un comentario caducado del kit pasó diez versiones
      publicadas.

- [x] 3. **Añadir la obligación de decir si la búsqueda converge** cuando dos rondas devuelven
      la misma clase, con la pregunta concreta que lo destapó: cuántas instancias nuevas las
      escribió el arreglo de la ronda anterior.

- [x] 4. **Dejar el caso del 2026-09-08 junto a la regla**, con el dato de las cinco instancias
      de nueve, en el mismo sitio y la misma forma que los dos casos que ya están ahí — prosa,
      como ellos. (La tabla de las seis rondas se queda en el `proposal.md`, que es donde vive
      la medición; esta tarea pedía las dos cosas a la vez y eran incompatibles.)

- [x] 5. **Declarar los tres límites en el propio fichero**: que nadie comprueba que el juez
      cuente bien, que el contador no sobrevive a la sesión, y que un cambio a esta sección se
      juzga con el prompt anterior.

- [x] 6. **Cierre:** `git diff agents/aceptacion.md` sin tocar otras secciones, `/kit-verifica`
      en verde, revisión por rodajas y juez de aceptación.

## Auditoría propia, antes de invocar a nadie

- [x] 7. **Escribí «sin excepción» y mi propio texto lo desmentía dos párrafos después.** «Lo
      que se movió en esas seis rondas fue, sin excepción, lo que el kit dice y no lo que
      hace» — falso: la ronda 3 añadió el fixture que faltaba, que es comportamiento, y el
      párrafo siguiente lo dice. Un predicado más ancho que la realidad, la clase exacta que
      seis rondas de juicio me cazaron en el cambio anterior.

      Corregido a «en casi todas», con la excepción nombrada. **Y esta vez la encontré yo**,
      que es el punto: el owner preguntó si podía auditarme antes de invocar al juez, y esto es
      lo que sale de hacerlo.

- [x] 8. **Los criterios, comprobados uno a uno contra el fichero** con `grep`, no
      leyéndolos. Y un barrido de absolutos —«siempre», «nunca», «ninguna ronda»— sobre la
      sección: ninguno queda sin su límite al lado.

## Del juez (DEVUELTO, 2026-09-08)

Una sola ronda, y encontró cuatro cosas que mi auditoría propia no vio. Vale la pena decir qué
tipo de cosas son, porque justifica que el juez exista aunque el autor se audite: **las cuatro
son de lectura completa del fichero**, no de la sección que yo estaba mirando.

- [x] 9. **La frase que este cambio existe para matar seguía viva, en imperativo.**
      `agents/aceptacion.md:190` — «si lo que has encontrado esta ronda hace **tocar código**,
      el tope no aplica». Yo reescribí la cabecera y el disparador, y esa instrucción vive cien
      líneas más abajo. La sección entregada le daba al juez dos reglas incompatibles. Corregida.

- [x] 10. **Mi límite 2 era falso en las DOS mitades, y el juez lo midió.** Decía «el juez lleva
      la cuenta dentro de una sesión; si el owner corta y vuelve mañana, empieza de cero y nada
      se lo dice».

      Ni una cosa ni la otra: es un sub-agente, así que **cada invocación** empieza en blanco
      —ni siquiera dentro de la misma sesión—, y el contador **sí** tiene memoria: la lleva
      `tasks.md`, que su propia «Entrada» le manda leer. Está medido: el tope del cambio
      anterior se alcanzó y se declaró entre dos invocaciones distintas, con las cabeceras «Del
      juez, N ronda» como única continuidad.

      El límite reescrito dice lo que sí es cierto y lo que sí queda descubierto: **un autor que
      no anote sus rondas desarma el tope sin querer.** El criterio C7 arrastraba el mismo
      error y se corrige con él.

- [x] 11. **Y el que más pesa: la tabla no cubría el caso frecuente de ESTE repositorio.**
      Clasificaba comentarios y cláusulas de spec como «no comportamiento», pero en un kit
      hecho de prompts, **lo que un prompt manda hacer ES lo que el agente hace**. Sin esa fila,
      la mitad de los hallazgos de esta casa quedaban sin lado claro — y peor: la medición de
      seis rondas que justifica el cambio dejaba de ser reproducible desde la regla.

      Dos filas nuevas: cambiar lo que un prompt o una norma **mandan hacer** cuenta; corregir
      una cláusula que **describía mal** lo que ya se hacía, no. Y una regla para el borde:
      **en la duda, cuenta como comportamiento**, porque el error caro de este tope es
      dispararse pronto.

- [x] 12. **El «sin excepción» que me auto-audité solo aterrizó en un sitio.** Lo corregí en
      `agents/aceptacion.md` y lo dejé en `proposal.md:21`. Arreglar en un fichero y no en su
      gemelo — el mismo defecto que ocupó los dos cambios anteriores, cometido mientras
      escribía la regla para cazarlo.

- [x] 13. **Dos menores suyos:** la tarea 4 se contradecía (pedía «la tabla de las seis rondas»
      Y «la misma forma que los dos casos que ya están», que son prosa); y la sección usaba tres
      palabras para el mismo eje —comportamiento, producto, código—. Una sola ahora.

## Del juez, segunda ronda (DEVUELTO, 2026-09-08)

Le pedí que separase lo que no se puede archivar de lo que aguanta. Lo hizo, y señaló **una**
cosa de la primera clase. Arreglada esa, y las de la segunda que costaban una línea.

- [x] 14. **BLOQUEANTE, y con razón: el ejemplo trabajado contradecía la regla.**
      `agents/aceptacion.md` metía «cláusulas de specs» en el saco de «lo que el kit dice» y
      remataba con «**Solo una** movió comportamiento», falso por la fila de los prompts que
      está 45 líneas más arriba: las rondas 4 y 5 escribieron cláusulas **normativas nuevas**
      —una ensanchó lo que una norma prohíbe, otra la escribió de cero— y hoy viven en
      `openspec/specs/doc-de-paquetes/spec.md`.

      Su argumento de por qué esto sí bloqueaba, que es el bueno: **un juez no calibra con la
      tabla, calibra con el caso**, y ese caso vive en el fichero que no se archiva nunca. Era
      el hallazgo de la ronda anterior —dos reglas incompatibles en la misma sección—
      sobreviviendo en el ejemplo después de corregirse en el imperativo.

      Reescrito sin censo: las dos primeras rondas fueron descripción, **y el tope salta al
      final de la segunda, que es el argumento entero**; las de después movieron comportamiento
      y se nombran como el ejemplo de la fila difícil. La tabla del `proposal.md` reclasificada
      igual.

- [x] 15. **Y el absoluto de la memoria, desmentido por la invocación que lo juzgaba.** El
      límite decía «la **única** memoria de cuántas rondas van es lo que el autor haya escrito
      en `tasks.md`», y el juez lo tumbó con el caso que tenía delante: yo le dije en el prompt
      que era su segunda ronda. Hay un segundo canal —no auditable, no escrito— y ahora está
      declarado, con la regla para cuando discrepen: manda `tasks.md`, y se dice.

      Es la tercera vez en este cambio que escribo un predicado más ancho que la realidad, y la
      segunda que el arreglo llega a los dos ficheros a la primera.

- [x] 16. **Lo que él mismo etiquetó como «aguanta hasta un cambio siguiente»** se arregló
      igualmente donde costaba una línea: el criterio C4, que se había quedado con el absoluto
      viejo mientras C2 sí se actualizó, y un «los nueve criterios» de la tarea 8 que eran diez.
