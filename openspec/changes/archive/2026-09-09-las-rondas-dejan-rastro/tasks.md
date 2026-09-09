# Tareas

Dos comandos y ninguna línea de código. Va la lista porque el esquema del CLI la pide para
`apply`, y porque este cambio existe justo para que las listas de tareas lleven más cosas.

- [x] 1. **`commands/kit-revisa.md`**: tras la invocación del revisor, anotar la pasada, su
      veredicto y lo que encontró. Con el sitio —`tasks.md`, o el final de `proposal.md` si el
      cambio no lleva lista— y con quién escribe: el que invoca, nunca el sub-agente.

- [x] 2. **`commands/kit-acepta.md`**: lo mismo para el juez, y además **si la ronda movió el
      comportamiento**, que es lo que su tope cuenta y lo que él no puede saber desde dentro.

- [x] 3. **La razón de que escriba el orquestador, escrita en los dos.** No es reparto de
      tareas: los prompts de `agents/` les prohíben escribir a propósito, y el del juez lo
      llama el fraude que existe para impedir. Que quede dicho ahí para que nadie lo
      "simplifique" dándoles permiso.

- [x] 4. **La medición del 2026-09-09 junto a la instrucción**, con el comando que la
      reproduce — el bucle entero de `AppStarter` sin una sola línea de registro.

- [x] 5. **Cierre:** `git diff` sin tocar `agents/`, `/kit-verifica` en verde,
      `autocomprueba.sh` limpio. Y auditarme yo antes de invocar al juez, buscando lo de
      siempre: un predicado más ancho que la realidad.

## Auditoría propia, antes de invocar a nadie

- [x] 6. **Escribí «el bucle no se para nunca» y es falso.** Sin registro, lo que no se dispara
      es el TOPE; el bucle lo para quien mira la factura — que es exactamente lo que pasó el
      2026-09-08, cuando el owner preguntó «¿por qué tantas rondas?» tras seis. Decir «nunca»
      convierte una degradación en una avería, y de paso borra el único mecanismo que sí
      funcionó ese día. Corregido a lo que de verdad ocurre, con la razón: el tope existe
      justamente para no depender de que alguien esté mirando.

      Es mi clase de siempre —un predicado más ancho que la realidad— y esta vez la cazó el
      barrido de cuantificadores, no un juez.

- [x] 7. **Dos `❌` de la auditoría eran mis patrones, no el texto**: uno buscaba una frase que
      el markdown parte en dos líneas, y el otro tenía dos `sed` encadenados que se pisaban.
      Se anota porque una auditoría que no reporta sus falsos positivos se lee como más limpia
      de lo que fue.

## Del juez (ACUERDO-ROTO, 2026-09-09) — ronda 1

La ronda más útil de todas, porque le pedí que leyera **como consumidor del dato** y contestó
que no le bastaba. Es la única ronda en la que podía decirlo antes de archivar.

- [x] 8. **El flag colapsaba dos casos que su propia regla separa.** Yo mandaba anotar «movió
      comportamiento: sí/no», y su tope dice que una ronda es limpia «solo si él no pidió mover
      el comportamiento; si lo pidió y no se hizo, es un desacuerdo abierto y NO es limpia». Un
      «no» a secas junta las dos, y él empieza en blanco: contaría como limpia una ronda que su
      propia regla dice que no lo es. Ahora son tres casos.
      Comportamiento: sí.

- [x] 9. **Pedía el flag también al revisor, y el revisor no tiene tope.** Criterio más ancho
      que la necesidad, y el delta se contradecía consigo mismo: la cláusula decía «revisor o
      juez» y el escenario del revisor no lo pedía. Ceñido al juez en los dos sitios.
      Comportamiento: sí.

- [x] 10. **No se podía distinguir una pasada de revisor de una ronda de juez.** Si el
      orquestador numera la del revisor como «ronda 2», el tope cuenta pasadas de revisor y se
      dispara antes de tiempo — el error que su prompt llama el caro. Los bloques se
      identifican ahora por quién los produjo, y solo los de juez se numeran.
      Comportamiento: sí.

- [x] 11. **El momento estaba mal.** Decía «al volver, escribe … y si arreglar te hizo mover el
      comportamiento» — al volver todavía no has arreglado, así que ese dato no existe. Y con
      un ACEPTADO no hay nada que arreglar y el flag quedaba sin definir. Ahora dice cuándo
      («cuando hayas terminado con lo que dijo») y qué escribir en un ACEPTADO.
      Comportamiento: sí.

- [x] 12. **Una norma nueva que no respondía a ningún criterio.** Metí en `kit-revisa.md` un
      «si arreglar te hizo cambiar código, vuelve a pasarlo antes de marcar» que no está en
      «What Changes», ni en criterios, ni en el delta. Es cierto y es bueno —lo hizo solo el
      agente de `AppStarter`— pero es alcance que se cuela en un fichero permanente. **Fuera**,
      y anotado como candidato a su propio cambio.
      Comportamiento: sí.

- [x] 13. **Otro predicado más ancho que la realidad, y era la corrección a medias de la tarea
      6.** Estreché «el bucle no se para nunca» a «el tope no se disparará», y eso también es
      absoluto: existe un segundo canal medido —lo que le digas en el mensaje— que su prompt
      acepta. Sin registro el tope queda **frágil y no auditable**, no imposible.
      Comportamiento: no — estrechar un requisito que prometía de más es descripción.

- [x] 14. **Dos errores de hecho, y el segundo me retrata.** La cita del proposal decía «no lo
      llevas tú: lo lleva `tasks.md`» y el texto real es «no lo **guardas** tú: lo **guarda**».
      Y escribí «en este repositorio yo las anotaba»: de nueve cambios archivados, **dos están a
      cero** —los dos del 2026-09-07—. La costumbre empieza el 08, y yo la tomé por
      comportamiento del sistema. Es exactamente el error que este cambio existe para arreglar,
      cometido al describirlo.
      Comportamiento: no — dos errores de hecho en prosa.

- [x] 15. **Un censo en un fichero que no se archiva nunca.** `kit-revisa.md` decía «ocho
      hallazgos, cinco bugs reales»: fechado, que es la forma buena, pero el comando que
      acompaña reproduce el `0`, no el ocho. Dentro de un año nadie podría recomprobarlo.
      Fuera el número; se queda el hecho y el comando.
      Comportamiento: no — un censo en prosa justificativa.

## Del juez (DEVUELTO, 2026-09-09) — ronda 2

Un solo NO CUMPLIDO y cuatro observaciones, y la más dura es sobre el ejemplar que yo enseñaba
como prueba de que el cambio se come su propia comida.

- [x] 16. **El flag estaba en el eje equivocado.** Lo escribí como «lo pidió y se movió», es
      decir keyed en lo que el juez PIDIÓ; su tope está definido sobre lo que los arreglos
      HICIERON. Consecuencia medida por él: la casilla «el juez no lo pidió pero los arreglos sí
      movieron comportamiento» **se quedaba sin etiqueta**, quien escribiera pondría «no lo
      pidió», y dentro de tres meses el juez leería una ronda limpia que no lo era — el
      contador avanza y el tope se dispara pronto, el error que su propio prompt llama el caro.
      Comportamiento: sí — cambia lo que el comando manda escribir.

- [x] 17. **Mandaba rellenar un campo cuya definición no enseñaba.** «Movió el comportamiento»
      lo decide una tabla de cinco filas que vive en `agents/aceptacion.md`, y el comando ni la
      reproducía ni la citaba. Ahora la señala, nombra la fila que más se falla y repite la
      regla de la duda.
      Comportamiento: sí.

- [x] 18. **Y la prueba de que hacía falta: mi propio ejemplar estaba mal en 3 de 8.** Los
      items 13, 14 y 15 decían «Comportamiento: sí» y son «no» por esa tabla —estrechar un
      requisito que prometía de más, dos errores de hecho en prosa, y quitar un censo—.
      Estrené el formato y lo etiqueté mal a la primera, con la tabla en el mismo repositorio.
      Corregidos, y con la razón al lado en cada uno.

      Su lectura, que es la que importa: **ese registro es el ejemplar que los siguientes van a
      copiar, y si el sesgo por defecto es «sí», el tope no se dispara nunca — el mismo estado
      que antes, con papeleo.** El aviso queda escrito en el comando.
      Comportamiento: sí.

- [x] 19. **El arreglo del censo llegó a un hermano y no a los otros dos.** El item 15 lo quitó
      de `kit-revisa.md` y sobrevivía en `kit-acepta.md` y —peor— en el delta, que **se funde en
      la spec viva al archivar**: ese censo no se archivaba, se quedaba. Tercera vez en esta
      sesión que un arreglo llega a un fichero y no a su gemelo.
      Comportamiento: no — prosa justificativa en los tres sitios.

- [x] 20. **Una cita que no era cita**, la misma clase que el item 14 acababa de arreglar: el
      comando entrecomillaba una frase del prompt del juez cambiándole las palabras y el eje.
      Y dos absolutos más en `kit-revisa.md` —«impide que alguien lo vuelva a proponer» y «se
      disparará antes de tiempo»—, más el residuo del flag que el item 9 había quitado de allí.
      Comportamiento: no — todo prosa.

- [x] 21. **Un hueco de campo que él es el único que podía ver:** la lista pedía «qué veredicto
      dio», y **en la ronda donde su tope salta no hay veredicto** — su prompt le manda escribir
      una de sus tres salidas en vez de uno. Es justo la ronda que más falta hace registrar.
      Ahora se dice qué anotar ahí.
      Comportamiento: sí.

## Lo que queda fuera y anotado

- `docs/FLUJO.md` describe los pasos 5 y 6 del bucle sin mencionar la anotación, y su cierre
  del presupuesto sigue diciendo «no las cuenta nadie por ti». No es falso —este cambio no crea
  contador— pero es el hermano que queda. Candidato a su propio cambio, junto con la norma que
  el item 12 sacó de `kit-revisa.md`.
