# Tareas

El primer cambio de esta tanda que produce código ejecutable, y por tanto el primero cuyo banco
puede fijar lo que la prosa no pudo.

- [x] 1. **`scripts/pasada-pendiente.sh`**: lee el acuerdo del cambio que se le pase, ordena los
      bloques por su aparición en el fichero, lee la etiqueta de comportamiento, y responde una
      de tres cosas. Códigos de salida con la forma de `verifica.sh` —el que reserva uno propio
      para «no pude mirar»— y su razón citada, que es la misma.

- [x] 2. **La tercera salida por defecto ante cualquier duda**: formato que no reconoce, ronda
      sin etiqueta, acuerdo sin bloques. Nunca «no falta». Con el porqué escrito en la cabecera:
      las cuatro puertas de la 1.9.4 son casos en los que la respuesta correcta era esa.

- [x] 3. **`scripts/verifica-pasada-pendiente.sh`**, con el corpus real de formatos que hoy
      existe en `openspec/changes/archive/` —cabeceras y items numerados, con sus variantes— y
      los casos que la prosa no cerró. El caso del formato desconocido tiene que salir en rojo
      contra un detector que lo diera por «no falta», que es el mutante evidente.

- [x] 4. **`kit.conf`**: el paso del banco nuevo, con el comentario de por qué existe — un
      detector que nace porque su clase falló las cuatro veces que el revisor enumera en
      `2026-09-09-no-se-archiva-a-ciegas` y la forma barata se midió fallando.

- [x] 5. **`commands/kit-acepta.md` y `docs/FLUJO.md`**: fuera el procedimiento, dentro la
      invocación. Es uno de los sitios donde el
      predicado estaba enunciado —tres, contados fichero a fichero; el revisor de la 1.9.4 dijo
      cinco en un sitio y cuatro en otro—; pasa a estar en uno.

- [x] 5b. **El requisito vigente, o el procedimiento sobrevive donde más manda.** `MODIFIED` de
      «No se archiva sobre el arreglo de un juicio que no ha visto ningún revisor»: la cláusula 2
      deja de describir cómo se lee y pasa a exigir la invocación, más lo único que el script no
      puede deducir —los bloques van al final—. Sin esto, `openspec/specs/coste-del-juicio/spec.md`
      seguiría enunciándolo después de archivar y este cambio no habría hecho lo que dice.
      Renegociado por escrito aquí, no en silencio.

- [x] 6. **Cierre:** `git diff` sin tocar `agents/` ni `hooks/hooks.json`, `/kit-verifica` en
      verde, `autocomprueba.sh` limpio. Auditarme antes de invocar a nadie, con el barrido de
      siempre — y esta vez además: **correr el script sobre los acuerdos archivados reales** y
      comprobar que lo que dice de cada uno es cierto.

## Del revisor (RED, 2026-09-09)

Siete hallazgos, dos rojos. Los cinco que movían comportamiento están arreglados y con caso en
el banco; los de prosa, corregidos.

- [x] 8. **RED — el diff borraba el invariante de posición del bloque del juez.** Al sacar el
      procedimiento de `commands/kit-acepta.md` se llevó por delante «escríbela al final, no
      agrupada con las rondas anteriores», que era un arreglo con `Comportamiento: sí` del
      cambio anterior (item 18 de `2026-09-09-no-se-archiva-a-ciegas`). Con las rondas agrupadas
      el script contesta `NO FALTA` y no avisa. Repuesto, y ampliado: al final **y en un solo
      fichero**.
      Comportamiento: sí.

- [x] 9. **RED — el veredicto dependía del idioma de la máquina.** El awk de macOS trata los
      corchetes por bytes, así que `revisi[oó]n` no casa contra «revisión» con `LC_ALL=C`: el
      mismo fichero daba dos veredictos. Siete bloques reales del archivo quedaban invisibles.
      Fuera **todas** las clases con acento del script —también `s[ií]` y `pidi[oó]`, que solo
      funcionaban bajo C por accidente—, sustituidas por alternativas literales `(ón|on)`, que
      casan igual en cualquier locale. `LC_ALL=C` va fijado además, como `lib-kit.sh` fija el
      suyo, pero es red y no suelo: quitarlo hoy no cambia ningún veredicto y **ningún caso del
      banco lo fija**, dicho en su cabecera.
      Comportamiento: sí.

- [x] 10. **El ordinal en item numerado no se veía ni como candidato.** `**De la segunda
      revisión (AMBER)**` daba `candidato=0` y `es_revisor=0` — una pasada real de
      `2026-09-08-el-que-comprueba-tambien-se-comprueba`. Añadido el hueco del ordinal.
      Comportamiento: sí.

- [x] 11. **Una cita de la etiqueta en prosa convertía una ronda muda en «no».** `Comportamiento:`
      disparaba en cualquier posición de la línea. Medido en el archivo: las 41 etiquetas de
      verdad empiezan su línea y las 3 citas en prosa no. Anclada al principio de línea.
      Comportamiento: sí.

- [x] 12. **Leer `tasks.md` y luego `proposal.md` fabricaba un orden.** Con bloques en los dos,
      «posterior» no está definido y el script contestaba `0`. Ahora contesta que no se puede
      leer y dice por qué.
      Comportamiento: sí.

- [x] 13. **El banco no distinguía el código bueno del malo en el caso que decía cubrir.** Los
      14 casos pasaban con el clasificador ciego al revisor en item numerado: en todos ellos la
      carga la llevaba el bloque del juez. Añadidos los dos casos donde la lleva el revisor, el
      de los dos locales, el de la cita en prosa y el del reparto. 21 casos, y mueren los mutantes
      `binario`, `ciego a «De la … revisión»` y `etiqueta sin anclar`.
      Comportamiento: sí.

- [x] 14. **El `MODIFIED` soltaba la garantía del «cero pasadas» y nada la recogía.** Era el
      bloqueante de la ronda 2 del juez anterior y no estaba ni en la cláusula ni en los
      escenarios. Escrita como cláusula del `ADDED` —la 4 desde que el item 30 metió el
      cuantificador delante—, con escenario. Y con ella las dos
      conductas nuevas: el reparto entre ficheros y la independencia del idioma.
      Comportamiento: no — contrato.

- [x] 15. **Tres afirmaciones que este cambio volvía falsas.** «El formato no importa» dejó de
      serlo al haber clasificador; el «límite declarado» de `kit-acepta.md` seguía diciendo que
      de este lado no hay script, ya corregido en `FLUJO.md` y en el delta pero no aquí —el
      patrón de siempre, en el fichero principal—; y `tasks.md` arrastraba el censo «quinto
      sitio» que el proposal ya había desmentido.
      Comportamiento: no — prosa, en tres sitios.

**Su respuesta a la pregunta directa**, que era «¿hay algún acuerdo donde conteste NO FALTA
faltando una pasada?»: sí, tres caminos, los tres reproducidos con `exit=0` —agrupar, repartir,
citar la etiqueta—. Sobre los 12 acuerdos archivados no disparaba ninguno: los 12 códigos eran
correctos entonces y lo siguen siendo ahora, idénticos en los dos locales. El agujero era en
escrituras futuras.

**Quedaba una pasada pendiente** cuando se escribió esto: los arreglos 8–13 movieron el
comportamiento y ningún revisor los había visto. La hizo la segunda revisión, anotada debajo.

## De la segunda revisión (RED, 2026-09-09)

Dos rojos, y uno era **regresión de la ronda anterior**: el revisor lo midió contra el script
pre-arreglo, no contra el texto.

- [x] 16. **RED, y mío de la ronda pasada — un bloque de juez que cita al revisor en negrita se
      clasificaba como pasada.** `es_revisor` aceptaba `**` en cualquier posición de la línea y
      se consultaba antes que `es_juez`, así que `- [x] 12. **Del juez, segunda ronda.** Volvió
      sobre lo que **De la revisión** dejó abierto.` borraba las rondas acumuladas y contestaba
      `NO FALTA` sobre un acuerdo con cero pasadas. Bajo `LC_ALL=C` el script viejo acertaba por
      accidente —`revisi[oó]n` no casaba—, y los arreglos 9 y 10 quitaron esa protección sin
      anclar nada en su lugar. Ahora quién firma el bloque lo decide su **título**, lo que va
      justo detrás del `## ` o del `- [x] N. **`, no lo que la línea mencione después.
      Comportamiento: sí.

- [x] 17. **RED — el caso del «formato desconocido» no entraba en la rama que decía cubrir.**
      El fixture era `## Del árbitro supremo`, que no menciona ni juez ni revisor: no era
      candidato y salía por «no hay ningún bloque», el mismo camino que el fixture vacío. La
      rama es portante, no defensa de un caso imposible, y los mutantes que la anulaban
      —ignorarla, contestarla «no falta», salir con 0— pasaban los 21 casos en verde; los dos
      primeros los encontré yo, el tercero lo midió la tercera pasada. Fixture cambiado a uno candidato e inclasificable
      (`## Segunda ronda del juez`), y añadidos dos casos que comprueban que **cada puerta sale
      por su rama** y no por la de al lado.
      Comportamiento: sí.

- [x] 18. **El invariante nuevo solo llegó a la mitad del juez.** «Y en un solo fichero» entró en
      `kit-acepta.md` y en el paso 7 de `FLUJO.md`, pero no en `kit-revisa.md` ni en el paso 5,
      que es donde se anota la mitad del revisor. Es el espejo exacto del item 18 del cambio
      anterior. Repuesto en los dos.
      Comportamiento: no — prosa, en dos sitios.

- [x] 19. **«Fuera las clases con acento» era más ancho que el arreglo.** Quedaban tres: el
      `[a-zé]` del ordinal, `s[ií]` y `pidi[oó]`. **No divergían**, y la tercera pasada midió por
      qué: casan igual bajo `C` y bajo UTF-8, así que el pin no las estaba salvando. La
      sustitución es preventiva, no correctiva; decir que sin el pin se rompían era falso.
      Fuera las tres, sustituidas por alternativas literales. Ahora el código no tiene ninguna,
      el pin es red y no suelo, y eso está dicho donde se lee: **ningún caso del banco lo fija**,
      y el mutante que lo quita sobrevive a propósito.
      Comportamiento: sí.

- [x] 20. **Límite de alcance, declarado en vez de descubierto.** Una forma de bloque que nadie
      ha escrito todavía —`### Del juez`, un item sin numerar— no es candidata: no cuenta como
      ronda ni dispara la tercera salida, y detrás de una pasada reconocida contestaría «no
      falta». Es el mismo silencio que el script existe para quitar, reducido a los formatos que
      no existen. Escrito en la cabecera del script y como primer límite del requisito. No se
      arregla hoy: no hay ninguno que medir, y la cláusula que promete las formas archivadas —la 5
      desde la renumeración del item 30— no promete «cualquier forma».
      Comportamiento: no — se declara, no se disfraza.

**Lo que verificó y se sostiene**, dicho porque cuenta igual: el ancla de la etiqueta (41
legítimas, 3 citas, ninguna legítima perdida), los «siete bloques invisibles» del item 9 (29
candidatos con el patrón viejo bajo C, 36 con el nuevo), y que REPARTIDO no dispara de más —
clasificó las 36 líneas candidatas de todo el archivo: 36 aciertos, 0 falsos positivos.

**Banco: 25 casos**, que los cuenta él al terminar. Mueren los dos mutantes que sobrevivían a
los 21 y los cuatro de la ronda anterior; sobrevive el que quita `LC_ALL=C`, a propósito y
dicho en la cabecera. El total no se escribe: ver el item 32.

**Y una nota de proceso que el revisor dio sin que se le pidiera**: la rodaja iba por 4696 líneas
sin marcar, y los dos rojos eran locales a una tarea cada uno — se habrían visto en rodajas de
100 líneas. El presupuesto de rondas de `docs/FLUJO.md` no es lo que ha fallado aquí; es el
tamaño de lo que se le da a mirar de una vez.

## De la tercera revisión (RED, 2026-09-09) — acotada a los items 16–20

La primera pasada que contesta **no hay regresión**: midió los arreglos contra el árbol anterior
reconstruido, con un fuzz diferencial de 3584 acuerdos, y las 768 divergencias van todas al lado
seguro. El rojo no es el código: es que el acuerdo escrito prometía lo contrario de lo que el
script hace, en el lado que archiva.

- [x] 21. **RED — la cláusula 2 prometía algo que el script no puede cumplir.** Decía «un bloque
      en formato desconocido SHALL producir no se puede leer, nunca no falta», y `### Del juez,
      segunda ronda` con etiqueta detrás de una pasada contesta `NO FALTA`, código 0. El Scenario
      decía lo mismo. Renegociado por escrito, no acotado por comodidad: **la señal para saber
      que algo pretendía ser una ronda es el vocabulario de su encabezado**, y la razón está
      medida — `lo-que-nadie-ha-visto-no-se-marca` y `no-se-archiva-a-ciegas` tienen secciones
      `## Auditoría propia` que llevan la etiqueta y NO son rondas, así que tratar todo
      encabezado con etiqueta como ronda ilegible daría falsa alarma sobre las dos.
      Comportamiento: no — el código no cambia; cambia lo que el acuerdo promete, y por qué.

- [x] 22. **Un bloque invisible CANCELABA una tercera salida ya ganada.** Este sí era código, y
      peor de lo declarado: la etiqueta de un bloque no reconocido se le atribuía a la ronda
      anterior, así que una ronda muda —que vale 3— pasaba a valer 0. Control ejecutado: quitar
      el bloque invisible devolvía el 3. Arreglado — **cualquier encabezado cierra la ronda
      abierta**, lo sepa clasificar o no —, con su caso y su mutante.
      Comportamiento: sí.

- [x] 23. **El límite declarado era más estrecho que la realidad, en las dos direcciones.** Lo
      escribí como límite de forma, y también es de **vocabulario**: `## Del árbitro supremo`
      tiene la forma buena y es invisible igual. Reescrito con las dos mitades, y con la razón
      de por qué no se cierra hoy en vez de dejarlo como pendiente vago.
      Comportamiento: no — declarar, no disfrazar.

- [x] 24. **Cobertura decorativa, tercera vez en este cambio.** El revisor revirtió el regex de
      `candidato()` al de antes del anclaje y pasó los 25 casos en verde: mi caso nuevo no
      mataba el mutante que el arreglo 16 introdujo. Añadido el que sí lo mata —un item que cita
      al juez en negrita a media línea—, comprobado ejecutándolo. Y el comentario que lo
      justificaba era más ancho que la realidad: corregido.
      Comportamiento: sí.

- [x] 25. **El sitio N-ésimo, tercera vez en este cambio.** «Al final y en un solo fichero» estaba
      en `kit-acepta.md` y en el paso 7, el item 18 lo llevó a `kit-revisa.md` y al paso 5, y
      quedaba el paso 6 de `FLUJO.md`, que es donde se le dice al juez dónde anotar. Repuesto.
      Comportamiento: no — prosa, el cuarto sitio.

- [x] 26. **Dos afirmaciones mías, falsas.** «Solo por el `LC_ALL=C`» —medido: `s[ií]` y `pidi[oó]`
      casan igual en los dos locales, así que el pin no las salvaba y la sustitución es
      preventiva, no correctiva—, y «dos mutantes» donde eran tres. Corregidas.
      Comportamiento: no — prosa.

- [x] 27. **Y dos valores de etiqueta se leían mal.** `Comportamiento: sin cambios` empieza por
      s-i y se leía como «sí»; `nota al margen` como «no». Anclados a palabra: ahora caen en la
      tercera salida, que es lo que son. Con su caso.
      Comportamiento: sí.

- [x] 28. **El caso del idioma era tautológico, y el primer intento de arreglarlo tenía el
      defecto que detectaba.** El revisor lo vio: el script fija su propio `LC_ALL` dentro, así
      que correrlo con dos idiomas recorre el mismo camino y el caso pasaría igual con el fallo
      puesto. Lo sustituí por una comprobación de que no queden clases con acento en el fuente y
      **el detector salió escrito con una clase con acento** —el mismo defecto, por tercera vez
      en este cambio, y puso el banco en rojo—. La forma que sí comprueba algo: quitarle el pin a
      una copia y correr ESA en los dos idiomas, que deja a prueba el clasificador, donde vivía
      el defecto. Mata al mutante que devuelve `revisi[oó]n`.
      Comportamiento: sí.

**Y un pendiente que no es de este banco:** comprobar que ningún script del kit lleve clases de
caracteres con acento es una regla de todos a la vez, no de este. Va en su propio cambio, junto
con la prueba de mutación.

**Banco: 28 casos** en el momento de cerrar esta pasada —lo cuenta el propio banco al terminar,
no está escrito a mano—. El censo de mutantes que puse aquí decía «quince, y sobrevive uno», y
**era falso**: lo desmintió la primera ronda de juez, que encontró dos supervivientes más. Ver
su bloque, debajo.

**Y lo que estas tres rondas dicen del proceso, que importa más que los hallazgos.** Tres clases
mordieron en las tres pasadas —cobertura decorativa, el sitio N-ésimo, y locale/bytes en `awk`— y
las tres veces se arregló el caso concreto, no la clase. La regla de la casa dice que un detector
nace cuando su clase falla dos veces: dos de estas van por tres sin detector. Se cierra este
cambio y se propone aparte el primero de ellos, la prueba de mutación como paso del banco, que es
el que habría cazado a los otros dos.

## Del juez (DEVUELTO, 2026-09-09) — ronda 1

Tres criterios NO CUMPLIDOS, ninguno del clasificador: el código estaba bien y el banco no lo
fijaba. Y desmintió un censo mío, que es la razón de que los censos no se escriban a mano.

- [x] 29. **La primera puerta —el cuantificador— no tenía ningún caso.** Dos mutantes que
      reiniciaban los acumuladores en cada ronda de juez pasaban los 28 casos en verde. La causa
      era estructural, no un caso suelto: **ningún fixture tenía dos bloques de juez detrás de la
      última pasada**, y con uno solo no se distingue «acumular entre rondas» de «mirar la
      última». Y es el camino NORMAL de la regla —DEVUELTO que mueve código, se arregla,
      ACEPTADO, se archiva—, o sea la trayectoria que el predicado existe para cerrar. Añadidos
      los dos casos, con sus dos mutantes comprobados muriendo.
      Comportamiento: sí.

- [x] 30. **El cuantificador se había caído del acuerdo, no solo del banco.** El requisito
      vigente lo enunciaba como texto normativo con su porqué; el `MODIFIED` lo soltó al delegar
      en el `ADDED`, y el `ADDED` no lo recogía como cláusula — quedaba implícito en dos
      escenarios. Es el mismo agujero que cazó el item 14, en la garantía de al lado y esta vez
      sin recoger. Ahora es la cláusula 3, con su escenario y con la exigencia de que el banco
      monte el caso de **dos** rondas.
      Comportamiento: no — contrato.

- [x] 31. **El criterio 3 del `proposal.md` seguía con la promesa vieja.** La cláusula 2 se
      renegoció en la tercera pasada de revisor y el arreglo llegó al delta y no al proposal:
      el criterio decía «un bloque en un formato que NO reconozca», sin «candidato». Alineado,
      con la razón y el límite escritos donde antes estaba la promesa incumplible.
      Comportamiento: no — prosa, el sitio N-ésimo por cuarta vez en este cambio.

- [x] 32. **Mi censo de mutantes era falso, y lo desmintió midiendo.** Decía «mueren quince,
      sobrevive uno»; sobrevivían tres, y los dos no declarados eran de la puerta 1. Medido
      ahora corriéndolos. **Y el total no se vuelve a escribir**, que es la única forma de no
      equivocarlo otra vez sin herramienta —la otra salida que el juez dio es que lo produzca
      una corrida con los mutantes commiteados, y esa es el cambio siguiente—: un censo de
      mutantes solo vale si lo produce una corrida, igual que
      el de casos lo produce el banco — y los mutantes no viven en el repositorio, así que ningún
      número escrito aquí es recomprobable. Esa es la carencia; el número era el síntoma.
      Comportamiento: no — pero es el que más duele.

- [x] 33. **Números en comentarios de código, que el archivado no se lleva.** El juez señaló que
      `las 41 etiquetas`, `en dos acuerdos archivados` y `en los doce` viven en un fichero que se
      queda para siempre y envejecen solos. Fechados al 2026-09-09 y acompañados del comando que
      los recuenta, que es la forma que este repositorio ya adoptó para los censos en prosa.
      Comportamiento: no — prosa.

**Lo que el juez confirmó, y conviene que quede escrito**: la renegociación de la cláusula 2
**está justificada**, no es un acuerdo reescrito para que encaje. Comprobó él la medición —las
secciones `## Auditoría propia` con etiqueta que no son rondas, en dos acuerdos archivados— y
que la promesa vieja era incumplible, ejecutándola. También confirmó que el `MODIFIED` no pierde
ninguna otra garantía del vigente, y que la atribución de «cuatro rondas» al revisor de
`no-se-archiva-a-ciegas` es fiel a lo que aquel escribió.

**Observación suya que no arreglo**: `tasks.md` salta del item 6 al 8. Es cierto; renumerar
rompería las referencias cruzadas que los bloques posteriores hacen por número, así que se queda
y se dice.

**Banco: 30 casos**, que los cuenta él. El total de mutantes no se escribe: ver el item 32.

## De la cuarta revisión (AMBER, 2026-09-09) — acotada a los items 29–33

Confirmó primero que los arreglos del juez cierran lo suyo, midiendo: los dos mutantes del
cuantificador mueren contra el árbol actual y sobreviven contra el reconstruido, ninguno de los
dos casos nuevos es decorativo, el censo «17/1» era exacto y el criterio 3 quedó alineado. **Y
ningún arreglo rompió nada**: 36 mutantes contra los dos árboles, ni uno que muriera antes
sobrevive ahora. Todo lo que encontró es del banco o de la prosa; el script está sano.

- [x] 34. **Cuatro aserciones se cumplían con la respuesta contraria.** `contiene "$V" "FALTA"`
      es verdadero también con «NO FALTA», así que cuatro casos pasaban en verde con la lógica
      que decían fijar borrada — entre ellos `discrepancia`, que sobrevivía a dos mutantes
      independientes. No es un caso suelto: es un fallo sistemático de forma de aserción.
      Ancladas a un trozo que no sea prefijo de su contraria, y dicho en la cabecera de la
      sección para que el próximo caso no repita la forma.
      Comportamiento: sí.

- [x] 35. **La otra mitad de la ronda muda no tenía caso.** Borrar `visto = 0` al abrir cada
      ronda dejaba los 30 en verde: la etiqueta de la ronda anterior valía por la de esta, y el
      script contestaba 0 donde tocaba 3. Faltaba el espejo del fixture del juez —ronda limpia
      primero, muda después—. Añadido.
      Comportamiento: sí.

- [x] 36. **El reinicio del revisor son cinco variables y ninguna estaba fijada por separado.**
      Quitar cuatro de los cinco reinicios dejaba el banco verde, porque `rondas = 0` tapaba a
      los otros. Añadido `ronda_pasada_ronda`, que lleva las cuatro clases de ronda —movida,
      discrepada, muda y con valor raro— delante de la pasada y una limpia detrás. Con él mueren
      los cuatro. Y hubo que ampliarlo una vez: la primera versión no llevaba muda ni valor raro
      y dos seguían vivos.
      Comportamiento: sí.

- [x] 37. **El comando de recuento que añadí no recontaba lo que la prosa afirma.** Remitía a
      `grep -rl 'Auditoría propia'`, que da **seis** ficheros, mientras el texto dice dos. El dos
      es el correcto —solo dos llevan la etiqueta dentro de la sección— y el comando era el
      equivocado: quien lo corriera concluiría que el censo miente. Sustituido por uno que mira
      dentro de la sección y devuelve dos. El otro comando, el de las etiquetas, sí devolvía lo
      que dice.
      Comportamiento: no — pero era prosa que se autodesmentía.

- [x] 38. **El sitio N-ésimo, quinta vez.** El mismo hecho sin fechar seguía en otros dos
      ficheros permanentes. Fechados y remitidos al comando.
      Comportamiento: no — prosa.

- [x] 39. **La renumeración dejó dos referencias cruzadas atrás, y una se contradecía.** El item
      14 decía «cláusula 3» de una garantía que hoy es la 4, mientras el item 30 dice que la 3 es
      el cuantificador: el mismo fichero afirmaba que dos cláusulas distintas son la 3. Y el item
      20 decía «cláusula 4» donde hoy es la 5, con la frase gemela del delta ya corregida — otra
      vez la misma afirmación en dos sitios y solo uno arreglado. Las dos reescritas apuntando
      al hecho —qué garantía es— y diciendo desde cuándo tienen el número que tienen. Siguen
      nombrándolo, porque sirve para encontrarla; lo que se quita es que el número vaya solo. Barrido completo de «cláusula N» en el repo:
      el resto apunta al `MODIFIED` o a otras specs y la renumeración no las toca.
      Comportamiento: no — prosa.

- [x] 40. **La cabecera del banco enumeraba tres puertas y el proposal cuatro.** Reescrita con
      las cuatro y sus nombres —cuantificador, ancla, campo y vocabulario del campo—, que son los
      cuatro hallazgos que el revisor de la 1.9.4 enumeró.
      Comportamiento: no — prosa.

**Banco: 34 casos**, que los cuenta él. Los acuerdos archivados siguen dando `333333333110` en
los dos locales, y `verifica.sh` los 13 pasos en verde. El total de mutantes no se escribe: ver
el item 32.

**Y una observación suya que no se arregla aquí y vale más que cualquiera de los hallazgos**: la
lista de mutantes no vive en el repositorio, así que ningún censo suyo lo puede recomprobar un
lector futuro aunque hoy sea cierto. Es exactamente la lección del item 32 girada
—un censo solo vale si lo produce una corrida— y el argumento entero del cambio que viene
después: **la prueba de mutación tiene que ser un paso del banco, con sus mutantes escritos al
lado, no un gesto que alguien recuerda hacer.** En este cambio la clase «cobertura decorativa»
apareció en los items 13, 17, 24, 29, 34, 36 y 42 — más de la mitad encontradas por otro, y el
contador se queda obsoleto cada vez que alguien mira, que es justamente el argumento.

## Del juez (DEVUELTO, 2026-09-10) — ronda 2

Confirmó cerrado todo lo que devolvió en la ronda 1 —el criterio 3 alineado, la puerta 1 con sus
dos mutantes muriendo, el cuantificador como cláusula 3, la renumeración sin referencias sueltas,
el `MODIFIED` sin soltar ninguna garantía— y las once cláusulas y criterios una por una,
ejecutando. Y devolvió tres cosas más.

- [x] 41. **La frase que este cambio añadió a un prompt ya divergía del script.** `kit-acepta.md`
      decía «cualquier otra cosa no la clasifica y contesta que no se puede leer». Es falsa, y
      hacia el lado que archiva: `### Del juez …` y `## Del árbitro supremo` contestan `NO FALTA`,
      código 0. Es el límite que el delta y la cabecera del script declaran, negado en el prompt.
      **Otra instancia del sitio N-ésimo**, y con una ironía que conviene no tapar: el
      argumento del cambio es «un script no puede divergir consigo mismo», y la primera
      reenunciación que añadí a un prompt divergía. Reescrita para decir lo que pasa —el script
      no lo ve y no avisa— y para apuntar al límite en vez de repetirlo.
      Comportamiento: no — prosa, pero era la promesa que el criterio 3 prohíbe hacer.

- [x] 42. **Dos mutantes vivos más, los dos contestando 0 donde toca 3.** Quitar el anclaje a
      palabra del valor «no» —`nota al margen` se leía como «no»— y quitar el anclaje de
      `es_juez` al título —`## Ronda 2 — Del juez` se tragaba por juez—. El primero era media
      tarea sin caso: el item 27 ancló los dos valores y montó caso solo para el de «sí». Los dos
      casos añadidos, los dos mutantes comprobados muriendo.
      Comportamiento: sí.

- [x] 43. **Tres errores de hecho en ficheros que se quedan.** La glosa del **ancla** en la
      cabecera del banco describía otro caso —decía «la ronda anterior a la pasada» cuando el
      ancla es «qué pasa con CERO pasadas»—; el item 39 se atribuía un remedio que no aplicó
      («reescritas sin número fijo», y siguen nombrando el número); y el delta decía «en los
      doce acuerdos archivados», un censo a mano, sin fecha y sin comando, **en un párrafo que
      se funde en la spec canónica** — peor que los comentarios del item 33, porque allí se
      queda para siempre. Los tres corregidos; el del delta, fechado y con el aviso de que lo
      recuente quien lo relea.
      Comportamiento: no — prosa.

- [x] 44. **El censo de mutantes, tercera vez desmentido, se BORRA en vez de reescribirse.** Fue
      «quince/uno» (falso), «17/1» y «23/1» (no recomprobable, y falso tal como se leía). La
      instrucción del juez fue literal: «no lo reescribáis a mano una cuarta vez; o se borra el
      número, o lo produce una corrida con los mutantes commiteados». Borrado de las cuatro
      líneas de cierre donde estaba. Lo que queda escrito son los mutantes **con nombre** que
      motivaron un caso concreto, que sí son recomprobables uno a uno, y el superviviente
      declarado. Quedan además dos totales dentro del relato de rondas anteriores —«17/1» y «36
      mutantes contra los dos árboles»—: son lo que otro midió entonces, no el estado de hoy, y
      se dejan como parte de su narración. **Lo que no vuelve es un total presentado como estado
      actual**, y para que vuelva hace falta una corrida que lo produzca — el cambio siguiente,
      no este.
      Comportamiento: no — pero es el arreglo que más importa de esta ronda: se quita la práctica,
      no el número.

**Su diagnóstico sobre la convergencia, que es el dato que decide si se sigue:** son las mismas
tres clases por tercera vez —cobertura decorativa, el sitio N-ésimo, censo falso— pero de las
instancias nuevas **solo una la escribió el arreglo de la ronda anterior**; las otras dos venían
de pasadas viejas (items 15 y 27). No es un paseo aleatorio. El censo sí lo era por sí solo
—tres redacciones, tres fallos, cada una fabricando la siguiente—, y por eso se ha quitado la
práctica entera en vez de corregir el número una cuarta vez.

**Banco: 36 casos**, que los cuenta él. Los acuerdos archivados siguen dando `333333333110` en
los dos locales; `verifica.sh`, 13 pasos en verde.

## De la quinta revisión (AMBER, 2026-09-10) — acotada a los items 41–44

Empezó midiendo lo que importaba: **`scripts/pasada-pendiente.sh` es byte a byte idéntico al del
árbol anterior**. La rodaja no tocó el ejecutable — solo el banco y prosa —, así que no hay
regresión posible, y lo confirmó igualmente corriendo los mutantes contra los dos árboles.
Verificó además que los dos casos del item 42 son cada uno el **único** que mata a su mutante
—ninguno decorativo—, que no queda un tercer valor de etiqueta con el mismo agujero (probó seis
formas más), y que las tres correcciones del item 43 dicen la verdad.

- [x] 45. **El item 41 arregló uno de tres sitios.** La promesa que
      quitó de un sitio seguía en pie en otros dos, uno de ellos **cien líneas más arriba del
      mismo fichero**: `kit-acepta.md` decía «sale cuando el registro no permite decidir» y
      `docs/FLUJO.md` «cuando el registro no alcanza para decidir lo dice en vez de suponer que
      no falta». Las dos las desmiente el mismo fixture con el que el juez devolvió el 41. La
      cláusula 2 del delta sí lleva la acotación —«ante cualquier duda **que el script pueda
      ver**»— y los prompts no la habían recibido. Acotadas las dos. Es la séptima instancia de
      la clase, y arreglar una de tres es su definición exacta.
      Comportamiento: no — prosa.

- [x] 46. **La frase nueva del 41 fallaba por el otro lado: enumeraba dos categorías y son tres.**
      Decía «lo que se salga de ahí el script no lo ve y no te avisa», pero `## Segunda ronda del
      juez` sale de las dos formas reconocidas y **sí se ve y sí avisa** —contesta que no se puede
      leer, código 3—. Reescrita con las tres: la que avisa, la que falla por forma y la que falla
      por vocabulario.
      Comportamiento: no — prosa.

- [x] 47. **Un tercer camino a código 0, y el límite decía «dos mitades».** El script lee líneas,
      no markdown: una cabecera de bloque escrita **dentro de una valla de código**, como ejemplo
      del formato, cuenta como bloque de verdad. Reproducido: exit 0 faltando una pasada. Medido
      además que **no ocurre en ningún acuerdo del repositorio**, así que por la regla de la casa
      —una clase tiene que fallar dos veces antes de que nazca un detector— se declara y no se
      detecta. Añadido como tercera parte del límite, en el requisito y en la cabecera del script.
      Comportamiento: no — se declara, no se disfraza.

- [x] 48. **Y el item 44 prometía más de lo que cumplía.** Decía «lo que queda escrito son los
      mutantes con nombre», y quedaban dos totales sin nombre en el relato de rondas anteriores
      —«17/1» y «36 mutantes»—. Acotado: esos son lo que otro midió entonces y se quedan como
      parte de su narración; lo que no vuelve es **un total presentado como estado actual**. De
      paso, «la única forma de no equivocarlo» era más ancha que la realidad —el juez dio dos, y
      la otra es la herramienta del cambio siguiente—, y los dos «tres mutantes» sin nombrar de
      rondas viejas pasan a nombrarlos.
      Comportamiento: no — prosa.

**El dato que decide si hay una tercera ronda de juez: ninguno de estos cuatro arreglos mueve el
comportamiento.** El ejecutable no ha cambiado en toda la rodaja salvo un comentario, y el banco
no ha cambiado en absoluto. Si la ronda 3 del juez encuentra solo cosas de esta naturaleza, su
tope —dos rondas que no mueven comportamiento— queda a una ronda de dispararse.

**Su lista de números no recomprobables**, que dejo escrita porque es el inventario de lo que la
herramienta del cambio siguiente tiene que producir: «17/1», «36 mutantes», «los 28 casos
anteriores», «los 21 casos», «Banco: 25 / 30 / 34 casos» —históricos, correctos en su momento— y los contadores a mano de instancias por clase, que quedan obsoletos en cuanto alguien mira.

**Banco: 36 casos**, que los cuenta él. Los acuerdos archivados, `333333333110` en los dos
locales. `verifica.sh`, 13 pasos en verde.

## Del juez (DEVUELTO, 2026-09-10) — ronda 3

Verificó las once cláusulas y criterios ejecutando, el `MODIFIED` pieza a pieza contra el
vigente, y corrió su propia batería de 18 mutantes. El script está sano. Devolvió por una cosa
que no es prosa, y tenía razón.

- [x] 49. **El caso del idioma no medía nada, y era el que declaré «no tautológico».** Crea una
      copia del script sin el pin de `LC_ALL` y la corre en dos idiomas, pero **no copiaba
      `lib-kit.sh` al lado**, así que las dos corridas morían con el MISMO error de `source` y
      `igual "$A" "$B"` era cierto para cualquier implementación. Control del juez: con el
      mutante `revisi[oó]n` y sin el pin, el mismo fichero daba `NO SE PUEDE LEER` bajo `C` y
      **`NO FALTA` bajo UTF-8** —el lado que archiva— y el caso seguía en verde. Arreglado con
      dos líneas; ahora el mutante muere con el pin puesto y sin él. **Octava vez de la clase
      «cobertura decorativa» en este cambio, y en el mismo caso que el item 28 dio por cerrado.**
      Comportamiento: sí.

- [x] 50. **Un tercer valor de etiqueta con el hueco léxico.** El anclaje del item 42 pedía que
      detrás del valor no hubiera una letra, y eso deja pasar `Comportamiento: no aplica.` y
      `Comportamiento: no del todo — movió una pieza.`: los dos empiezan por la palabra «no» y se
      leían como «no movió», código 0. El segundo dice literalmente lo contrario de como se leía.
      La quinta pasada probó seis formas y no dio con ninguno; el juez enumeró 22 y dio con dos.
      Ahora el valor tiene que ser la palabra entera, seguida de final de línea o de un signo —
      que es como se escriben los del archivo—. El guion largo va como alternativa y no dentro de
      un corchete, que es el defecto de locale que este script ya tuvo.
      Comportamiento: sí.

- [x] 51. **Una frase heredada del requisito vigente era falsa bajo las dos lecturas.** «Este
      mismo cambio es el ejemplo: su `tasks.md` no tiene ni un bloque de revisor» — este acuerdo
      tiene cinco, y el que la escribió tenía dos. Iba a fundirse en la spec canónica tal cual,
      re-entregada sin mirar. Fuera el ejemplo, se queda el hueco, que es lo que había que
      declarar.
      Comportamiento: no — prosa, pero en la canónica.

- [x] 52. **Los residuos que el juez reportó sin devolver.** La cabecera del script decía «el
      registro no permite decidir» sin acotar, y `docs/FLUJO.md` conservaba la formulación de dos
      categorías que el item 46 había sustituido por tres en el otro fichero — el sitio N-ésimo
      otra vez, esta vez cazado antes de que hiciera daño. Y tres números históricos a mano en el
      banco («los 28 casos anteriores», «los 21 casos»), que pasan a decir «el banco entero», que
      no envejece.
      Comportamiento: no — prosa.

**Lo que confirmó cerrado**, y conviene que quede porque son tres rondas de trabajo: no queda un
cuarto sitio de la promesa (barrió el repo entero); los dos mutantes del item 42 mueren; las tres
correcciones del item 43 dicen la verdad; **no queda ningún total de mutantes presentado como
estado actual**, y juzgó la acotación del item 48 «honesta, no una excusa». Verificó también la
medición del item 47 —cero ocurrencias de cabecera dentro de valla de código en los 26 ficheros
de acuerdo del repositorio— y dictaminó que declarar y no detectar es **aplicación correcta** de
la regla de la casa, no un agujero escondido.

**El tope, y lo dijo explícitamente:** sigue en cero. Sus tres rondas han pedido arreglos que
mueven comportamiento, así que faltan dos rondas seguidas sin moverlo.

**Su lectura de la convergencia, que es el dato:** de sus cuatro instancias nuevas, **ninguna la
escribió el parche de la ronda anterior**. La del banco viene del item 28, tres pasadas atrás; la
frase falsa viene del acuerdo anterior; y el hueco léxico desciende del item 27. *«La búsqueda
está sacando sedimento viejo, no su propia cola.»*

**Banco: 38 casos.** Los acuerdos archivados, `333333333110` en los dos locales.

## De la sexta revisión (AMBER, 2026-09-10) — acotada a los items 49–52

Contestó las tres preguntas midiendo. **Nada se rompe**: en todo el diff cambian dos líneas
ejecutables, y clasificó 44 formas de etiqueta con el regex viejo y el nuevo — *toda* diferencia
va de un valor decidido a `raras`, o sea a la tercera salida. **El cambio solo puede convertir
una decisión en «pregunta», nunca en «archiva».** Los 12 archivados, idénticos antes y después,
en los dos locales. **Y el caso del idioma mide de verdad**: instrumentó `$A` y `$B` y son
veredictos reales, no errores de `source`; el mutante `revisi[oó]n` deja el caso en verde en el
árbol anterior y lo pone en rojo en este.

- [x] 53. **Un número a mano, falso, en el cambio cuya tesis es que los números a mano se
      pudren.** El comentario del item 50 decía «así se escriben los 38 del archivo» y en el
      archivo hay **41** — el 38 era el número de casos del banco, escrito en la misma ronda.
      Fuera el número, dentro el comando que lo recuenta. La forma que afirmaba sí era cierta.
      Comportamiento: no — prosa, pero se publicaba en el entregable.

- [x] 54. **Cobertura decorativa, novena vez, y la escribió el arreglo anterior.** El item 50
      cambió las dos ramas del valor —«sí» y «no»— y solo montó caso para la de «no»: un mutante
      que revirtiera **solo** la rama «sí» pasaba el banco entero. Añadido `sí aplica, pero solo
      a medias`, y comprobado que ahora muere.
      Comportamiento: sí.

- [x] 55. **El caso del idioma no se protegía a sí mismo.** El `cp` de `lib-kit.sh` va sin
      comprobar: si mañana esa librería se mueve, las dos corridas vuelven a fallar con el mismo
      error y el caso vuelve a ser la tautología que fue, en verde. Añadida una aserción de que
      lo comparado es un veredicto y no un error — comprobado quitando el `cp`: el banco se pone
      en rojo en vez de mentir.
      Comportamiento: sí.

- [x] 56. **El item 52 dijo «tres» y barrió dos.** Quedaban dos «catorce casos anteriores» en el
      mismo fichero, la misma construcción que acababa de sustituir. Barridos. Y un «y»
      duplicado y un comentario que se quedó huérfano al insertar un fixture entre medias.
      Comportamiento: no — prosa.

**Lo que dictaminó sobre archivar**, que es para lo que se le llamó: *«ninguno de los siete
hallazgos rompe nada»*, y a la spec canónica **no se lleva nada que no deba** — verificó que el
párrafo del item 51 es ahora cierto—. Y zanjó que el tope no es condición de archivado:
`agents/aceptacion.md` dice que **el tope no archiva ni cierra, para y le pasa la decisión al
owner**, así que cerrar sin agotarlo no viola ninguna cláusula.

**Y dejó dos hechos de proceso sobre la mesa**, que es lo que un revisor debe hacer en vez de
decidir por el owner:

1. **`docs/FLUJO.md` dice «No archiva con DEVUELTO»**, y el último veredicto de juez de este
   acuerdo es DEVUELTO. Sus cuatro items están cerrados y una pasada de revisor los ha visto,
   pero ningún juez ha dicho ACEPTADO sobre ellos. Es una regla escrita del repositorio.
2. **El orden importa**: `pasada-pendiente.sh` contestaba FALTA sobre este mismo acuerdo antes de
   anotar esta pasada, y contesta 0 después. Anotar primero, archivar después — que es lo que se
   ha hecho.

**Banco: 40 casos.** Los acuerdos archivados, `333333333110` en los dos locales.

## Del juez (ACEPTADO, 2026-09-10) — ronda 4

Verificó los once criterios del proposal, las siete cláusulas del `ADDED` con sus nueve
escenarios, y el `MODIFIED` frase a frase contra el vigente — **no suelta ninguna garantía**: las
cuatro que desaparecen de su cláusula 2 están las cuatro en el `ADDED`. Confirmó cerrados sus
cuatro hallazgos de la ronda 3, midiendo cada uno:

- el caso del idioma da **veredictos reales**, no errores de `source`, y su mutante muere con el
  pin puesto y sin él;
- clasificó las **41** etiquetas reales del archivo, 16 formas distintas, y **ninguna legítima se
  rechaza**; barrió ~55 valores adversarios y ninguno que signifique «movió» se lee como 0;
- la frase heredada falsa está fuera y el hueco sigue declarado;
- y el barrido de la promesa está completo: cero ocurrencias del predicado en `commands/`,
  `docs/` y `agents/`.

Todos los censos que quedan son recomprobables o los produce una corrida, y **no queda ningún
total de mutantes presentado como estado actual**.

- [x] 57. **El mensaje de un caso nombraba la mitad que no mide.** Decía «un encabezado no
      reconocido cierra la ronda: no le regala su etiqueta», y el caso fija el `mudas++`, no el
      `enronda = 0`: revertir solo esa asignación deja el banco en verde. Corregido el mensaje, y
      anotado en el propio banco cuál de las dos mitades fija, para que el próximo lector no lo
      dé por cubierto.
      Comportamiento: no — prosa.

## DEUDA, escrita antes de archivar para que no se pierda

El juez encontró **dos mutantes vivos** y los dejó como deuda explícita, no como bloqueo: yerran
hacia `FALTA` y `NO SE PUEDE LEER` —nunca hacia el código 0, que es el lado que archiva— y no
cambian el veredicto de ninguno de los doce acuerdos archivados. Son el primer objetivo del
cambio que viene, y van aquí con su reproducción para que se puedan montar sin volver a
descubrirlos:

1. **`scripts/pasada-pendiente.sh:145`** — el `enronda = 0` de la regla `/^#+ / && !candidato($0)`.
   Fixture que lo caza: ronda de juez con `Comportamiento: no.`, seguida de `## Auditoría propia`
   con `Comportamiento: sí.`. El árbol contesta **0**; el mutante, **1**. Es exactamente la forma
   que existe de verdad en dos acuerdos archivados.
2. **`scripts/pasada-pendiente.sh:130`** — el `enronda = 0` de la rama del revisor, que es el
   sexto reinicio de esa rama: el banco fija los cinco de la línea siguiente y este no. Fixture:
   ronda muda → pasada de revisor → ronda etiquetada. El árbol contesta **0**; el mutante, **3**.

**Y su lectura de la convergencia, que es el argumento del cambio siguiente escrito por quien no
tenía por qué darlo:** son la décima y la undécima instancia de «cobertura decorativa» en este
cambio, y ninguna la escribió el arreglo de la ronda anterior —las dos descienden del item 22,
cuatro pasadas atrás—. Sigue siendo sedimento viejo y no la propia cola. Pero once instancias de
la misma clase en diez rondas ya no es un problema de parches: **es la medida de que la
herramienta que falta es la prueba de mutación**, y estos dos mutantes son su mejor primer
objetivo porque son reproducibles y están fechados.

**El tope no se disparó**: sus cuatro rondas pidieron arreglos que mueven comportamiento, así que
el contador sigue en cero. Se archiva porque el juez dice ACEPTADO, no porque el tope se agotara.
