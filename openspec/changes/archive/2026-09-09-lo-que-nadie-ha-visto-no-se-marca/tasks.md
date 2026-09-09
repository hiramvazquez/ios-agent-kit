# Tareas

Un comando y un documento. Ninguna línea de código.

- [x] 1. **`commands/kit-revisa.md`**: la condición para marcar. Si arreglar movió el
      comportamiento, no se marca — se vuelve a pasar. Con el caso del 2026-09-09 al lado, que
      es lo que la justifica, y remitiendo al eje de `agents/aceptacion.md` en vez de definir
      uno nuevo.

- [x] 2. **`docs/FLUJO.md`, paso 5**: la misma condición donde ya dice «con GREEN o AMBER se
      marca el punto», que hoy va sin condición ninguna.

- [x] 3. **`docs/FLUJO.md`, pasos 5 y 6**: que la pasada y la ronda se anotan en el acuerdo.
      Es de la 1.9.2 y el documento que describe esos pasos no lo dice.

- [x] 4. **El cierre del presupuesto de `docs/FLUJO.md`**: deja de decir que no queda rastro
      —desde la 1.9.2 sí queda— y pasa a decir lo que sigue faltando, que es quien lo cuente.

- [x] 5. **Cierre:** `git diff` sin tocar `agents/`, `/kit-verifica` en verde,
      `autocomprueba.sh` limpio. Y auditarme yo antes de invocar al juez: predicados más anchos
      que la realidad, censos, y punteros que se hayan movido.

## Auditoría propia, antes de invocar a nadie

- [x] 6. **«El único punto del bucle donde todavía cabía»** — absoluto que no puedo verificar.
      La puerta cubre el commit, la firma cubre la verificación y esta regla cubre el marcado,
      pero afirmar que no queda ningún otro sitio exige un barrido del bucle entero que no he
      hecho. «Un punto», que es lo que sí sé.
      Comportamiento: no — estrechar una afirmación que prometía de más.

- [x] 7. **«La segunda pasada encontró cuatro cosas más»** — el mismo censo que el juez me
      quitó ayer, reescrito con otro número. Y peor que aquel: el suceso ocurrió en un chat de
      `AppStarter` y **el bucle de aquel cambio no dejó rastro anotado**, así que ni siquiera
      hay dónde recomprobarlo. Se queda el hecho —la segunda pasada encontró más, y una
      bloqueaba— sin la cuenta.

      Tiene su ironía: el cambio que arregla que las rondas no dejen rastro cita un número que
      no dejó rastro. Es el argumento de este cambio, en contra mía.
      Comportamiento: no — un censo en prosa justificativa.

- [x] 8. **Un `❌` de la auditoría era mi regex**, otra vez: la frase que remite al eje va
      partida en dos líneas por el markdown. Se anota porque una auditoría que esconde sus
      falsos positivos se lee como más limpia de lo que fue.

## Del juez (DEVUELTO, 2026-09-09) — ronda 1

- [x] 9. **BLOQUEANTE. Mi texto de `FLUJO.md` contradecía a los dos comandos que describe.**
      Escribí que la pasada del revisor «es de donde el juez saca en qué ronda va» y que «la
      ronda se anota igual que la pasada del revisor». Las dos son falsas y por la misma razón:
      los dos comandos mandan encabezar la del revisor **como del revisor y no numerarla**,
      justamente para que el juez NO la cuente. Mi redacción empujaba a la fusión que ellos
      prohíben, y `FLUJO.md` no mencionaba el aviso en ninguna línea.

      Es la tercera vez esta semana que una regla llega a un fichero y no a su hermano — y esta
      vez el hermano es el documento que existe para describir al primero.
      Comportamiento: sí — cambia lo que el flujo manda hacer.

- [x] 10. **BLOQUEANTE. Mis dos arreglos de la auditoría propia se quedaron a medias**, y la
      mitad que faltaba es la que se archiva: llegaron a `commands/kit-revisa.md` y a
      `docs/FLUJO.md`, y no al `proposal.md` ni al **delta**, que es el que `/opsx:archive`
      funde en `openspec/specs/`. O sea que el censo que yo mismo declaré irrecomprobable iba
      camino de spec canónica. Las dos tareas estaban marcadas `[x]`.
      Comportamiento: no — prosa en los cuatro sitios.

- [x] 11. **Y «el único punto del bucle» no era solo inverificable: era falso, y lo demostró.**
      El mismo peligro existe en el tramo juez → arreglo → archivar: el paso 7 de `FLUJO.md` no
      pide ninguna pasada de revisor sobre el código escrito para responder a un DEVUELTO, y
      `kit-acepta.md` tampoco. **Se archiva sobre código que no ha revisado nadie.** Verificado:
      cero menciones a revisión en ese paso.

      Mi estrechamiento a «un punto» era el correcto; lo que fallaba es que no había llegado a
      los ficheros que se archivan. Y el agujero que destapa queda anotado abajo.
      Comportamiento: no.

- [x] 12. **Su observación del desempate, aceptada.** «En la duda, cuenta como comportamiento»
      estaba inlineado en `kit-acepta.md` y en `kit-revisa.md` solo se llegaba a él siguiendo el
      puntero. Es la pregunta exacta que se hace quien tiene el arreglo delante. Inlineado aquí
      también; la asimetría era gratuita.
      Comportamiento: sí.

- [x] 13. **Dos menores suyos:** `FLUJO.md` decía «el mismo error que la puerta de commit»
      donde el comando dice «la puerta de commit **y la firma de verificación**» —la divergencia
      empieza cuando la misma garantía se enuncia en dos sitios, que es la lección que este repo
      ya tiene escrita—; y el caso se cortaba antes de su consecuencia, que es lo que lo hace
      convincente. Los dos alineados.
      Comportamiento: no.

## Lo que queda fuera y anotado

- **Se archiva sobre código sin revisar.** El tramo juez → arreglo → `/opsx:archive` tiene el
  mismo agujero que este cambio cierra en el tramo del revisor, y lo destapó el juez al
  desmentir mi «único punto». Es su propio cambio: toca el paso 7 y `kit-acepta.md`, no estos
  dos ficheros.
- Un «un» huérfano al final de una línea de `commands/kit-acepta.md`, de la 1.9.2. Fuera de
  alcance es fuera de alcance, incluso para una errata de una letra.
- La tensión preexistente que señaló: el presupuesto se declara sobre revisor **y** juez, pero
  todo lo medido son rondas de juez. Esta regla añade pasadas de revisor, así que esa fila
  envejece más rápido de lo que su medición respalda.

## Del juez (DEVUELTO, 2026-09-09) — ronda 2

- [x] 14. **BLOQUEANTE: el predicado de la excepción era más ancho que la norma, y en el
      escenario del delta — que es lo que se archiva.** La norma dice «una cláusula que
      **describía mal** lo que ya se hacía»; yo escribí en tres sitios «comentarios o **texto
      del acuerdo**», que junta las dos filas que la tabla separa a propósito: describir mal
      (no cuenta) y **mandar algo nuevo** (sí cuenta).

      En este kit un `SHALL` del acuerdo se funde en `openspec/specs/`, así que reescribirlo
      es cambiar lo que una norma manda. Mi redacción eximía de repasar **justo la clase de
      artefacto donde este repositorio encuentra sus defectos** — el bloqueante del caso
      fundacional vivía en una spec, no en el código.

      Y el delta se contradecía consigo mismo: cláusula cerrada, escenario abierto. Es
      literalmente el fallo que ese mismo caso narra dos párrafos más abajo.
      Comportamiento: sí — cambia lo que la spec canónica va a mandar.

- [x] 15. **Y el arreglo NO es otro parche de redacción.** Su diagnóstico: la excepción estaba
      enunciada en **seis sitios** y tres eran parciales, así que corregir las palabras solo
      mueve el problema. La forma que corta la serie es **dejar la tabla como única enunciación
      y que los demás apunten** — que es la que `kit-acepta.md` ya tenía, y la misma lección que
      este repositorio aprendió ayer con la garantía de acotado.

      Hecho: `kit-revisa.md`, `FLUJO.md` y el `proposal.md` dejan de repetir la excepción y
      remiten a la tabla, diciendo por qué no la repiten. El delta gana un escenario para el
      caso que la redacción ancha eximía. Barrido comprobado en los cinco ficheros.
      Comportamiento: sí.

- [x] 16. **Sus tres menores.** Un censo —«su tabla de **cinco** filas»— en dos ficheros que no
      se archivan, cuando su hermano `kit-acepta.md` apunta a la misma tabla sin contarla;
      `FLUJO.md` decía «Anota la ronda» sin dónde ni «del juez», rompiendo la simetría con el
      paso 5; y el desempate «en la duda, cuenta como comportamiento» no estaba en `FLUJO.md`.
      Los tres cerrados.
      Comportamiento: no — prosa y simetría.

- [x] 17. **Su jab, aceptado y anotado:** este cambio, que obliga a anotar las pasadas de
      revisor, **no tiene ninguna**. `.agent-kit/.ultima-revision` es de otro cambio. Ningún
      criterio la exige y no bloquea, pero conviene que quede escrito quién lo dijo.

- [x] 18. **Y su medición de convergencia, que es lo más útil:** dos rondas de la misma clase
      —`FLUJO.md` enuncia la norma con otras palabras que sus hermanos—, con los hallazgos
      bajando de dos bloqueantes a uno. Converge, pero no cerraba, y la causa era estructural.
      Añadió que **no puede medir cuántas instancias las escribió el arreglo anterior**, porque
      no hay nada commiteado de la ronda 0: que este cambio no pueda medir su propia
      convergencia es, otra vez, su propio argumento en contra.
