# Tareas

Un comando y un documento. Ninguna línea de código. Es el hermano de
`lo-que-nadie-ha-visto-no-se-marca` y se escribe con la lección que aquel dejó: **no
reenunciar la excepción, apuntar a la tabla.**

- [x] 1. **`commands/kit-acepta.md`**: la condición para archivar. Si arreglar lo que el juez
      señaló movió el comportamiento, ningún revisor lo ha visto — se pasa antes. Remitiendo a
      la tabla del tope, sin repetirla.

- [x] 2. **La comprobación se hace leyendo, no recordando**: desde la 1.9.2 cada ronda anota qué
      pasó con el comportamiento, así que la respuesta está en el acuerdo. Decirlo ahí.

- [x] 3. **`docs/FLUJO.md`, paso 7**: la misma condición junto al `/opsx:archive` que ya
      menciona, y que hoy no habla de revisión en ninguna línea.

- [x] 4. **El límite, en los dos**: nada lo comprueba, y `/opsx:archive` es de OpenSpec — el kit
      no tiene hook que lo intercepte. Es peor que el de su hermana y hay que decirlo.

- [x] 5. **Cierre:** `git diff` sin tocar `agents/`, `/kit-verifica` en verde,
      `autocomprueba.sh` limpio. Auditarme antes de invocar al juez, con el barrido que ya sé
      que hace falta: predicados anchos, censos, punteros movidos, y **la misma frase enunciada
      en dos sitios**.

## Auditoría propia, antes de invocar a nadie

- [x] 6. **El mismo límite, con dos redacciones.** `kit-acepta.md` decía «el kit no tiene
      **ningún** hook que lo intercepte» y `FLUJO.md` «el kit no tiene hook que lo intercepte».
      Es la clase que me cazaron ayer —la divergencia empieza cuando la misma garantía se
      enuncia en dos sitios— y la cacé aquí con el cuarto barrido, que existe justo por eso.
      Alineadas.
      Comportamiento: no — prosa.

- [x] 7. **Dos «reenunciaciones» que el barrido señaló y NO se tocan, dicho para que el juez no
      lo re-derive.** Las de `commands/kit-acepta.md:55,61` no las añade este cambio: son el
      inline del flag que trajo la 1.9.2, y el juez de entonces las aprobó **a propósito**
      frente a fiarlo todo al puntero, porque son la pregunta que se hace quien tiene el arreglo
      delante. Y la del escenario del delta es la lista **precisa** que casa con la norma, no la
      ancha que bloqueó a su hermano — un escenario que dijera «mira la tabla» no sería un
      escenario.

## Del juez (DEVUELTO, 2026-09-09) — ronda 1

El más afilado de la semana. Dos bloqueantes, y los dos son la misma clase que este cambio
existe para arreglar, cometida al escribirlo.

- [x] 8. **BLOQUEANTE: mi regla no disparaba nunca en el único camino que el flujo permite.**
      Escribí «si **la última** ronda anotada dice que sí, falta una pasada». Encadenado con lo
      que ya dicen los otros dos documentos: para archivar en regla la última ronda es un
      ACEPTADO, y un ACEPTADO es siempre «no» porque no arregló nada. El camino normal
      —DEVUELTO que mueve código → arreglas → ACEPTADO → archivas— pasaba limpio por delante, y
      **el agujero que esto cierra vive entero en ese camino**.

      «Alguna» en vez de «la última», y la razón escrita. Y era además una divergencia
      semántica: `FLUJO.md` decía «cada ronda queda anotada», que da la respuesta correcta. La
      misma regla con dos redacciones que responden distinto — mi barrido la cazó en su versión
      léxica y no en esta.
      Comportamiento: sí.

- [x] 9. **BLOQUEANTE: «no se puede interceptar `/opsx:archive`» es falso, y se archivaba.**
      Lo deduje de una ausencia, que es **la forma exacta del «único punto del bucle»** que dio
      origen a este cambio. Él lo desmontó con dos líneas del repo:
      `.claude/commands/opsx/archive.md` declara `allowed-tools: Bash(openspec:*)`, y
      `hooks/hooks.json` ya intercepta Bash con la puerta de commit. **El kit intercepta a
      diario un comando que tampoco es suyo, por ese mismo canal.**

      Lo cierto es otra cosa y es mejor: no hay puerta porque `hooks.json` declara «tres hooks y
      ninguno más; un cuarto tiene que traer escrito el fallo que lo motiva», y este no lo trae
      —el fallo está observado, pero nadie ha medido que la instrucción no baste—. Reescrito en
      los tres sitios, y el criterio con ellos: pedía declarar algo falso.
      Comportamiento: sí.

- [x] 10. **Y un censo, cuando yo había declarado que no había ninguno.** «Los **seis** cambios
      de esta semana. **Cada uno** tuvo rondas de juez que hicieron tocar código.» Contado: ningún
      corte de los cambios archivados da seis y cumple «cada uno» — hay más, y varios sin
      ninguna ronda de juez. El comando que lo cuenta está en el `proposal.md`; el número no se
      escribe aquí, que es justo lo que esta tarea vino a arreglar.

      Peor: solo dos de los once llevan etiqueta `Comportamiento:`, así que «cada arreglo movió
      código» **no se puede leer** — se apoyaba en mi memoria, en el cambio cuya tesis es que la
      memoria no vale. Sustituido por lo que sí es verificable, con su comando.
      Comportamiento: no — prosa justificativa.

- [x] 11. **El título del requisito prometía más que su cláusula.** «No se archiva sobre código
      que no ha visto ningún revisor» sugiere cubrir todo el código; la cláusula solo cubre el
      arreglo de un juicio. **El código que el autor cambia por iniciativa propia no lo cubre
      ninguna de las dos reglas hermanas** — y este cambio es el ejemplo vivo: su `tasks.md` no
      tiene ni un bloque de revisor. Título acotado, y el hueco declarado.
      Comportamiento: sí.

- [x] 12. **El «después» solo se podía leer por posición.** Las cabeceras llevan fecha de día y
      la del revisor no se numera a propósito, así que **una pasada y una ronda del mismo día**
      no se ordenan por su contenido. (Dos rondas de juez sí: van numeradas. Escribí que era de
      cualquier par y era más ancho de lo cierto.) Hoy no dolía porque en los acuerdos que
      tienen los dos tipos, todas las pasadas preceden a todas las rondas — **pero esta regla
      ejercita ese caso siempre**, que es su propósito. Dicho ahora, con la instrucción de
      escribir al final, y también en `kit-revisa.md`, que es quien escribe la otra mitad.
      Comportamiento: sí.

- [x] 13. **Su observación de asimetría, aceptada:** `kit-revisa.md` dice inline que si el
      siguiente arreglo vuelve a mover comportamiento toca otra pasada; la sección nueva de
      `kit-acepta.md` lo tenía solo en el acuerdo, y quien archiva lee el comando. Inlineado.
      Comportamiento: sí.

## Lo que queda anotado

- `commands/kit-acepta.md` dice «cinco filas» de la tabla del tope. No lo trae este cambio, pero
  es un censo en un fichero que no se archiva nunca, y su hermano apunta sin contar.
- En la spec canónica quedarán dos escenarios de título casi idéntico bajo requisitos distintos.
  Se ha acotado el de aquí («el arreglo **de un juicio**»), pero conviene saberlo.

## Del juez (DEVUELTO, 2026-09-09) — ronda 2

- [x] 14. **BLOQUEANTE: la regla seguía sin decidir, ahora con CERO pasadas.** Ejecutó mi propio
      predicado sobre este acuerdo: su ancla —«la última pasada de revisor»— no existe aquí, y de
      ahí salen dos lecturas opuestas. La verdad es que falta una pasada; la lectura literal
      archiva. Es la misma forma del bloqueante anterior, desplazada de «última ronda = ACEPTADO»
      a «cero pasadas», **y es el caso mayoritario en los archivados.** Añadida la rama.
      Comportamiento: sí.

- [x] 15. **La razón del límite llegó a tres sitios y no al cuarto.** `docs/FLUJO.md` seguía
      dando la propiedad del comando como el diferenciador, que es justo lo que la ronda 1
      desmontó. Y el criterio nombra «los dos documentos», así que ese cuarto era uno de ellos.
      Comportamiento: no.

- [x] 16. **Dos censos nuevos, en el propio parche que arreglaba un censo.** «Ocho con rondas de
      juez» eran siete; «los tres acuerdos con ambos tipos» dependía de si se cuenta
      «De la revisión» además de «Del revisor» — defendible pero ambiguo, que es peor. Fuera los
      números, dentro el comando. Y su hallazgo de que «dos bloques del mismo día no se ordenan
      por contenido» era más ancho de lo cierto: **dos rondas de juez sí**, van numeradas.
      Comportamiento: no.

## Del revisor (RED, 2026-09-09)

Le invoqué **porque la regla que este cambio introduce me obligaba**: dos rondas de juez con
arreglos que movieron comportamiento y ninguna pasada. El juez lo había dicho — «no puede
archivarse a sí mismo sin incumplir lo que introduce».

- [x] 17. **RED: una ronda SIN etiqueta se leía como «no», y archivaba a ciegas.** Mi predicado
      tenía rama para cero pasadas y ninguna para el registro **mudo**. La etiqueta
      `Comportamiento:` llegó con la 1.9.2: **9 de 11 acuerdos archivados no la tienen.**

      Lo reprodujo sobre un fichero real —`el-hermano-que-quedaba`, una pasada, cinco rondas,
      cero etiquetas—: mi regla lo archiva, y el propio kit dice de ese cambio que aquellas
      rondas sí movieron comportamiento. Y lo que lo hacía RED y no impreciso: la frase «no lo
      decidas de memoria, está escrito» **empujaba activamente** a preferir el registro mudo
      sobre lo que quien archiva sí sabe. Las dos reglas hermanas tienen ese desempate; esta no.
      Comportamiento: sí.

- [x] 18. **El invariante de posición solo estaba mandado para la mitad del revisor.** Quien
      escribe el bloque del juez no leía en ninguna parte dónde ponerlo, y agrupar por tipo
      —lo que hacen varios acuerdos archivados— rompe el orden del que depende todo.
      Comportamiento: sí.

- [x] 19. **`FLUJO.md` llevaba la condición sin el procedimiento**, así que quien archivara con
      ese documento delante tenía que inventárselo — y el valor por defecto es el que la ronda 1
      llamó bloqueante. Tercera vez que ese documento se desincroniza de los comandos.
      Comportamiento: sí.

- [x] 20. **Tres de sus opcionales, afilados.** Un ACEPTADO con observaciones que **sí** se
      arreglan quedaba etiquetado «no» por instrucción y el predicado lo perdía; «build y tests
      lo miran» es cierto en el paso 8 y no antes de archivar; y «pásalo antes de archivar» no
      nombraba `/kit-revisa`.
      Comportamiento: sí.

- [x] 21. **Y el patrón, en directo y en mí:** el arreglo del RED falló al escribirse y aterrizó
      en `FLUJO.md` y el delta **pero no en `kit-acepta.md`**, que es el fichero principal. Lo
      detecté comprobando uno a uno en vez de fiarme del script. Cuarta vez hoy que un arreglo
      llega a unos ficheros y no a su hermano.

## Del revisor (AMBER, 2026-09-09) — segunda pasada

Confirmó primero lo que sí funciona: probó el predicado contra los once acuerdos archivados,
caso por caso, y las tres ramas nuevas cubren lo que dicen cubrir. Después encontró cuatro
cosas, y contestó la pregunta que se le hizo.

- [x] 22. **La plantilla ofrecía un valor que derrota al predicado.** Los valores del párrafo
      son «sí | no | no, se pidió y se discrepó», y la plantilla de más abajo —de la 1.9.2—
      ofrecía **«no, no lo pidió»**, que codifica el eje que ese mismo párrafo prohíbe. Caso
      concreto, y es el que este cambio acababa de añadir: ACEPTADO con observaciones que sí
      arreglas y el arreglo mueve comportamiento. El párrafo dice «sí»; la plantilla ofrece la
      descripción literalmente exacta de lo ocurrido, que empieza por «no». Una palabra.
      Comportamiento: sí.

- [x] 23. **«Build y tests sí ven el arreglo» es falso en el paso donde se lee.** El arreglo 20
      aterrizó en `kit-acepta.md` y **en ninguno de los otros tres sitios**. El paso 7 precede al
      8: quien archiva lee una garantía que todavía no existe, justo en el párrafo cuyo trabajo
      es no inflar el hueco. **Quinta vez hoy del patrón**, y en la misma tanda que mi item 21 lo
      documentaba.
      Comportamiento: no — prosa, en cuatro sitios.

- [x] 24. **Mi propio `grep` mentía, en silencio y hacia el lado que archiva.** Puse un snippet
      para no fiarme de la memoria, y devuelve `0` sobre dos acuerdos que **sí** tienen rondas —
      las anotaron como item numerado en vez de cabecera— y pierde «De la **segunda** revisión»
      en un tercero. Con sus números el censo que lo acompañaba sobrevivía; con todos los
      formatos, era falso.

      **Un instrumento que devuelve «cero» cuando la respuesta es «no sé leer esto» es el mismo
      defecto de las cuatro rondas, ahora en shell.** Fuera el snippet y fuera el censo; queda
      el aviso de por qué no se cuenta así.
      Comportamiento: sí.

- [x] 25. **Y el registro VACÍO sigue sin rama**, que es la puerta de al lado de la que él mismo
      cerró: la rama muda cubre «ronda anotada sin la línea», no «ronda no anotada». No lo llamó
      bloqueante porque el «o pregunta» deja al lector de buena fe en el sitio correcto — pero el
      lector literal archiva. Queda anotado, no arreglado: es el argumento de abajo.

## Su respuesta a la pregunta, que es lo que decide

Se le preguntó explícitamente: si encuentras una cuarta puerta, ¿falta otro parche o es que
esto no debería vivir en prosa? Contestó lo segundo, con tres razones:

1. **Los cuatro hallazgos son el mismo a distinta profundidad** —el cuantificador, el ancla, el
   campo, el vocabulario del campo—. No es una spec que se afina: es **una función parcial que
   se extiende caso a caso**, y cada extensión la descubre el siguiente lector, no el autor. La
   serie no converge porque la prosa no tiene forma de enumerar su dominio.
2. **El coste no es escribir el parche, es hacerlo aterrizar.** El predicado vive en cinco
   sitios, así que cada arreglo es una edición a cuatro manos, y **la tasa de divergencia es de
   una por ronda y no baja** — items 6, 15, 19, 21 y ahora 23.
3. **Y el que decide:** ya intenté mecanizarlo, y el instrumento falló por la misma razón.

Su propuesta, que no choca con la política de `hooks.json` porque no es un hook sino un script
que alguien invoca —el precedente de `rodaja.sh --revisada`—: **`scripts/pasada-pendiente.sh`
con TRES salidas: `FALTA` / `NO FALTA` / `NO SE PUEDE LEER`.** La tercera es la que la prosa
lleva cuatro rondas sin conseguir producir: **las cuatro puertas son casos en los que la
respuesta correcta era «no se puede leer, pregunta» y el texto contestó «no falta».**

Y su cierre, que es el que hace la decisión honesta: nada de lo encontrado rompe el predicado en
los casos para los que se escribió. Archivar esto deja en el repo una regla mejor que la que
había. **Lo que no recomienda es archivarlo Y darlo por terminado.**
