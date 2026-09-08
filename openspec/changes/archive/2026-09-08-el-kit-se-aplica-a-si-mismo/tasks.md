# Tareas

Cada tarea se cierra con `/kit-revisa` sobre su rodaja, no al final del cambio.

El orden no es cosmético. **Las dos primeras hacen falsificable todo lo demás** y tienen que
poder correrse contra el código SIN arreglar y salir rojas en los sitios esperados; si se
escriben después, se escriben para que pasen. Es el mismo orden que siguió el cambio de la
puerta, y por la misma razón.

---

## Fase 1 — Primero lo que detecta, y en rojo

- [x] 1. **Banco de pruebas para `busca-duplicados.py`.** Hoy no tiene ninguno: es el único
      script con lógica de verdad que nunca se ha probado, y esta tarea va a cambiarle la
      semántica. Un `scripts/verifica-duplicados.sh` sobre `lib-banco.sh` —que ya monta
      repos temporales y cuenta sus casos— con al menos: un fichero alcanzable por un
      symlink (🔴 contra el detector actual), dos cuerpos idénticos en ficheros distintos de
      verdad (✅), un cuerpo por debajo del suelo de ruido (✅), y `--tocados` filtrando lo
      que no toca el diff (✅). Añadirlo a `verificaciones()` de `kit.conf`.

- [x] 2. **Ampliar `autocomprueba.sh` con el criterio que le falta.** Su punto 5 dice
      comprobar que todo script citado por un comando o un agente existe, pero su expresión
      regular solo mira rutas que **empiezan** por `${CLAUDE_PLUGIN_ROOT}`: detecta la ruta
      mal escrita y no la que omite la raíz, que es el error más probable. Debe cazar
      `bash Scripts/verifica.sh` en `agents/aceptacion.md` —dos veces— y salir en rojo
      contra el repositorio tal como está hoy. Es el detector que este cambio se ha ganado:
      la clase ya falló dos veces, en dos ficheros distintos.

## Fase 2 — Lo que rompe algo

- [x] 3. **El juez lee lo entregado de verdad.** Sustituir `git diff main...HEAD` de
      `agents/aceptacion.md` por la rodaja acumulada desde el principio del cambio, con los
      ficheros nuevos sin trackear dentro. Reutiliza `rodaja.sh` —que ya resolvió esa
      ceguera para el revisor— con un modo que no dependa de la marca de revisión.
      Y en el mismo fichero: `bash Scripts/verifica.sh --informe` pasa a
      `bash "${CLAUDE_PLUGIN_ROOT}/scripts/verifica.sh" --informe`, en sus dos apariciones
      (líneas 25 y 55). Con esto, la tarea 2 pasa a verde.

- [x] 4. **El detector deja de contar dos veces el mismo fichero.** Descartar los symlinks —o
      deduplicar por ruta real— en el `rglob` de `busca-duplicados.py`. Medido antes del
      arreglo en `spm-pro`: 28 grupos reportados, 21 de ellos el mismo fichero visto dos
      veces. Y en la misma pasada, el suelo de ruido **subió de 3 a 4 líneas, no a 5** — y se
      revirtió en la tarea 20, cuando el juez demostró que esa medición era mala; se deja
      escrito lo que se hizo entonces para que la tarea 20 se entienda. La
      medición del 2026-09-08 dice que 4 elimina el único falso positivo observado —dos
      dobles de test de `AppStarter`, cuerpo de tres líneas— y que 5 se habría llevado por
      delante los tres hallazgos verdaderos de `iOSandbox`, que son de cuatro. El delta de
      spec se renegoció por esto ANTES de implementar. Con esto, la tarea 1 pasa a verde.

- [x] 5. **Códigos de salida distinguibles en `verifica.sh`.** `3` conserva su significado
      documentado —«no pude mirar»— y el rojo pasa a `1`, sea cual sea el número de pasos
      fallidos. El recuento sigue en el informe y en la línea `resultado:` de la firma, que
      es donde se lee. Actualizar `docs/PIEZAS.md`, que hoy documenta el contrato viejo.

- [x] 6. **La resolución del cambio activo, una sola vez.** Hoy está copiada en
      `inyecta-contexto.sh:50`, `rodaja.sh:36` y `rodaja.sh:54`, y las tres arrastran el
      mismo `find … | head -1`: orden del sistema de ficheros, no determinista. Extraer a un
      `scripts/lib-kit.sh` compartido —hay precedente con `lib-banco.sh`—, ordenar de forma
      estable, y **decir cuándo hay más de un cambio activo** en vez de elegir uno en
      silencio. Es el único duplicado real que la auditoría encontró en las 1.400 líneas de
      bash, y ya se cobró un defecto.

- [x] 7. **Fuera el fichero temporal de `/tmp`.** `inyecta-contexto.sh:57` escribe
      `/tmp/.ic.$$` en un hook que corre en cada turno de cualquier repositorio: nombre
      derivable del PID en un directorio compartido. El rodeo además no hace falta — ese
      bloque se resuelve sin fichero intermedio. Un caso del banco de contexto que lo fije.

## De la revisión de la rodaja (2026-09-08)

`/kit-revisa` sobre las tareas 1-7 devolvió **AMBER** con cinco hallazgos, los cinco
reproducidos con comandos. Se arreglan aquí y no en el siguiente cambio: los tres primeros
viven dentro de tareas que ya estaban marcadas como cerradas, y cerrarlas con un defecto
conocido dentro es exactamente lo que este cambio existe para no hacer.

- [x] 14. **Banco para `rodaja.sh`** (`scripts/verifica-rodaja.sh`, alta como paso 8 de
      `kit.conf`). Era el hallazgo 4 y es el que explica los otros: `--entregado` es la única
      fuente de evidencia del juez y nació sin una sola prueba. Los casos los cuenta el banco; tres salen rojos
      contra la versión sin arreglar.

- [x] 15. **Los cuatro arreglos que salieron de la revisión:**
      1. `--entregado` acepta la ruta del cambio que se juzga, y `agents/aceptacion.md` le
         pasa `$CAMBIO`. Sin eso, con dos cambios abiertos el juez leía el acuerdo de uno y
         la lista de tareas del otro, bajo un encabezado que dice «EN ESTE CAMBIO».
      2. `git log --follow` al buscar el commit del proposal: un `git mv` del directorio del
         cambio hacía desaparecer del juicio todo lo commiteado antes del renombrado, sin
         aviso. El mismo modo de fallo que el modo existe para cerrar, en pequeño.
      3. El caso «dos invocaciones eligen el mismo cambio» pasaba igual con el código roto
         —dos `find` seguidos devuelven el mismo orden—. Ahora el banco monta CINCO cambios
         en orden inverso y exige el mínimo por `LC_ALL=C`: contra la versión vieja sale rojo
         con la evidencia (`find` devuelve `ccc-tercero`).
      4. `kit.conf` afirmaba que el paso 7 «está en rojo» cuando la tarea 4 ya lo había
         puesto en verde en la misma rodaja. Una afirmación falsa sobre sí mismo, escrita en
         el cambio cuya tesis es justo esa.

      Y los tres opcionales que el revisor marcó sin bloquear: el censo `REPOS=4` del banco
      de contexto pasa a contarse (decía 4 con 5 repos, y solo colaba por el orden de los
      bloques), la tabla de `scripts/` del README incorpora los tres ficheros nuevos, y queda
      escrito aquí que el punto 5b de `autocomprueba.sh` **solo mira dentro de bloques de
      código**: en la prosa, `rodaja.sh` es un nombre y no una invocación, así que de las dos
      apariciones de `Scripts/verifica.sh` caza una y la otra se resolvió reescribiendo la
      frase. La tarea 2 decía «dos veces» y esto lo matiza.

---

## Fase 3 — Lo que el kit predica y no cumple

- [x] 8. **Fuera los censos escritos a mano.** `README.md:54` dice «5 skills» donde hoy hay 6
      comandos y 1 skill. `README.md:66` y la tabla de coste de `docs/PIEZAS.md` fijan un
      número de tokens que envejece igual. Se sustituyen por el comando que los cuenta
      (`claude plugin details ios-agent-kit`), o se fechan como medición. Y una comprobación
      en `autocomprueba.sh` que falle si reaparece un censo: es la misma clase que ya
      escribió «once casos» en dos sitios y «diez» en un tercero el mismo día.

- [x] 9. **`archlint` fuera del prompt del juez.** `agents/aceptacion.md:13` lo cita como si
      todo proyecto lo tuviera; existe en `AppStarter` y no en `iOSAppBaseline`. Un juez que
      da por hecho un filtro inexistente afloja el suyo.

- [x] 10. **El mecanismo de la huella, contado bien.** `docs/PIEZAS.md:88` afirma que
      sustituir un literal por una constante «no cambia la huella». Es falso —la
      normalización conserva los tokens, así que el sha1 cambia—; lo cierto es que el
      **grupo** sobrevive, porque las dos copias cambian igual y siguen siendo idénticas
      entre sí. La conclusión que la doc saca es correcta y el mecanismo que enseña no, y
      alguien va a razonar desde el mecanismo.

- [x] 11. **`kit.conf`: de límite dramático a medición fechada.** Hoy declara que la
      duplicación en bash «no la está buscando nadie». Se buscó, el 2026-09-08: un solo
      duplicado real en 1.400 líneas —el de la tarea 6— y el idioma compartido de los dos
      bancos, deliberado. Se escribe el resultado con el comando que lo produce y la fecha,
      que es exactamente lo que el juez de aceptación exige de cualquier censo.

- [x] 12. **Declarar los dos límites que faltan.** Primero: `verifica.sh` hace `. kit.conf`,
      así que verificar ejecuta código del repositorio en el que estés — irrelevante en los
      propios, relevante el día que alguien corra `/kit-verifica` sobre un repositorio
      clonado de fuera. Segundo: el hook de contexto recorre `DerivedData` con `-maxdepth 6`
      una vez al día **antes** de que salga tu prompt, y ese coste no está medido, mientras
      que el de la puerta sí lo está (12,6 ms sobre 30 iteraciones). Medirlo y escribirlo,
      o declarar el recorrido como límite conocido.

---

## De la segunda revisión (2026-09-08)

`/kit-revisa` sobre la fase 3 y los arreglos de la primera revisión devolvió **AMBER** otra
vez, con cuatro hallazgos y siete opcionales, todos reproducidos. Dos merecen quedar
escritos por lo que dicen del proceso, no solo del código:

- **La tarea 8 estaba marcada `[x]` sin terminar.** Nombraba `README.md:66` y ese número
  siguió ahí, sin fecha y sin comando, mientras la copia de `PIEZAS.md` sí se fechaba. El
  detector nuevo tampoco podía cazarlo: «tokens» no está en su lista de piezas. Marcar como
  hecha una tarea que nombra un sitio concreto y no tocarlo es exactamente el «requisito a
  medias» que el juez de aceptación busca a propósito.
- **Otro caso de banco pasaba con el código roto**, y por la misma causa que el de la primera
  revisión: miraba la salida entera en vez de la cabecera, y el `tasks.md` sin trackear se
  inlinea en el diff. Un mutante con la cabecera borrada pasaba en verde.

- [x] 16. **Los cuatro hallazgos:** `README.md:66` remitido a la medición fechada; el caso de
      las tareas mira ya solo la cabecera (comprobado contra un mutante); el punto 7 de
      `autocomprueba.sh` admite ahora la **medición fechada** que su propio mensaje ofrecía
      —antes fechar no salvaba de nada— y caza los censos con adornos de markdown
      (`**6** comandos`, «6 `comandos`»); y su LÍMITE DECLARADO dice lo que de verdad se le
      escapa, que era más de lo que decía.

- [x] 17. **Los opcionales que valían la pena:** las instrucciones del juez escriben la ruta
      literal, porque `$CAMBIO` no sobrevive entre invocaciones de Bash y un argumento vacío
      devuelve el fallo que la tarea 15 arregló; `--entregado` valida que la ruta tenga
      `proposal.md` y no solo que exista (un caso más de banco); fuera un `ACTIVOS_N=1` que
      no leía nadie; las dos huellas de `PIEZAS.md` van con el cuerpo que las produce; la
      fila de `scripts/` del README deja de ser un inventario a mano —ya se había quedado
      corta— y el delta de `juicio-de-aceptacion` recoge el requisito de juzgar el cambio que
      se nombra, que hasta ahora solo vivía en `tasks.md`.

## De la tercera revisión (2026-09-08)

Rodaja acotada a mano a ~250 líneas —los arreglos de la ronda anterior— en vez de re-revisar
el cambio entero por tercera vez. **AMBER**, dos hallazgos, y los dos en el texto que
acompaña al código, que es justo lo que cabe esperar de algo que ya pasó dos rondas.

- [x] 18. **El delta prometía un filtro que no existe.** Decía que «la lista de tareas y el
      conjunto de cambios» serían los del cambio nombrado. La lista sí; el conjunto es una
      **ventana temporal** desde la propuesta, no un filtro por rutas, así que con dos
      cambios abiertos contiene trabajo del otro. El revisor lo reprodujo, y el consumidor
      era inmediato: la tarea 13 es correr el juez, cuyo prompt le manda buscar «lo que nadie
      pidió» — habría llamado ACUERDO-ROTO al trabajo del vecino. Reescrita la cláusula para
      decir lo que el código hace, y por qué filtrar por rutas sería peor: dejaría fuera
      precisamente lo que el juez busca.

- [x] 19. **El límite declarado del punto 7 se contradecía a sí mismo**, en el comentario que
      esta misma rodaja escribió «para decir lo que de verdad se le escapa»: afirmaba que
      «19 casos de prueba» se le escapa cuando `casos?` está en el patrón. Cazar `N casos` es
      deliberado —«once» contra «diez» fue la primera vez que la clase falló—, así que se
      corrige la frase y no el patrón. De paso, el límite dice ahora dos cosas más que eran
      ciertas y no estaban: que la exención por fecha es gruesa (basta una fecha ISO en la
      línea, no se exige el comando que la regla pide), y que los ficheros que no son
      markdown no los mira nadie.

      Con los opcionales: dos casos nuevos de banco para las cláusulas que ningún caso
      miraba (que no se avise de los demás cuando se nombra el cambio, y que un cambio sin
      `tasks.md` se diga en vez de pintar una cabecera vacía); el README deja de prometer un
      banco «por cada pieza con lógica», que no es verdad; y las mediciones de `kit.conf` y
      `lib-kit.sh` se actualizan, porque el propio cambio añadió tres scripts y dejó viejo el
      número que había escrito tres días antes — fechado y todo.

## Del juez de aceptación, primera ronda (2026-09-08)

**DEVUELTO**, con dos NO CUMPLIDOS. Los dos son de la clase que el juez existe para ver y que
ni el compilador ni tres rondas de revisión habían visto.

- [x] 20. **El suelo de ruido vuelve a 3, y la medición que lo subió era mala.** La tabla del
      acuerdo decía que subirlo a 4 no se llevaba por delante ningún hallazgo verdadero. El
      juez fue a mirar **cuáles** desaparecían en vez de cuántos y encontró dos duplicados
      reales de tres líneas en `spm-pro` —`pascalCase()` y `displayPath()`, copiados entre
      `Sources/ArchInitSupport` y `Plugins/GenerateFeature`—, que son exactamente la clase que
      el detector existe para cazar. El trato era perder dos verdaderos para quitarse uno
      falso.

      Se revierte el suelo, se asume el ruido conocido, y el delta gana una cláusula que no
      estaba: **toda medición que mueva el suelo tiene que decir QUÉ grupos cambian de lado,
      no solo cuántos**. Mi medición original —28→5, 6→5, 3→3— cuadraba perfectamente sin
      decir nada de lo que importaba. Los casos del banco pasan a fijar el suelo real: dos
      líneas no se reportan, tres sí, cuatro también.

      Y el número quedaba escrito en dos sitios que sobreviven al archivado —un comentario de
      `busca-duplicados.py` y `docs/PIEZAS.md`—, que es justo lo que el propio prompt del juez
      manda decir aparte. Corregidos los dos.

- [x] 21. **El censo que se coló por el predicado.** `README.md:6` decía «las **cuatro**
      piezas que OpenSpec no trae» y la tabla de once líneas más abajo enumera cinco. Sin
      comando, sin fecha, caducado, y en el primer párrafo del documento principal. No es un
      fallo del detector: el punto 7 cuenta en términos **léxicos** (dígitos pegados a una
      pieza) y el criterio está escrito en términos **semánticos** («ningún documento afirmará
      cuántas piezas trae»). Es el mismo hueco léxico/semántico que el prompt del juez
      describe como su hallazgo más fino, esta vez contra el kit.

      Se reescribe la frase para que no cuente, y con ella las «diez líneas» de `kit.conf` de
      `README.md` y `INSTALACION.md` —la plantilla tiene 44 y el de AppStarter 35—. El
      detector no se ensancha: cazar censos escritos con letra chocaría con «tres hooks», que
      es un invariante de diseño, y eso ya está declarado como límite.

      De paso, la atribución de los rojos del banco de contexto, que nombraba al cambio
      anterior en vez de a este.

## Del juez, segunda ronda (2026-09-08)

**DEVUELTO** otra vez, y esta ronda **no tocó código**: los tres hallazgos son
inconsistencias que introdujo el arreglo de la ronda anterior. Vale la pena mirarlas juntas,
porque las tres son la misma forma de fallo — corregir en un sitio y dejar la afirmación
vieja en otro.

- [x] 22. **El acuerdo se contradecía a sí mismo.** Se revirtió el suelo en el código y en el
      delta, y el `proposal.md` se quedó pidiendo lo contrario: su criterio exigía que el
      suelo SUBIERA y dejara fuera los cuerpos de tres líneas, que es justo lo que la ronda
      anterior demostró que era un mal trato. Reescritos el criterio y el resumen del cambio,
      con las dos renegociaciones contadas.

- [x] 23. **«10 líneas» sobrevivió a «diez líneas».** La tarea 21 arregló las apariciones
      escritas con letra en `README.md` e `INSTALACION.md` y dejó intactas las escritas con
      dígito, en esos mismos dos ficheros. Es el hueco léxico/semántico de la ronda anterior,
      cometido dentro del arreglo del hueco léxico/semántico. (Medido: la plantilla tiene 44
      líneas, el `kit.conf` de AppStarter 35, el de este repo 119.)

- [x] 24. **El banco no nació con dos rojos, sino con uno.** `kit.conf` y la cabecera de
      `verifica-duplicados.sh` afirmaban dos casos rojos —symlink y suelo— y que «los dos se
      cerraron». Medido contra la versión vieja: uno. Los tres casos del suelo pasan también
      contra ella, y es correcto que pasen: fijan un comportamiento que al final no cambió.
      Reescritas las dos cabeceras con lo que de verdad ocurrió, incluido que el segundo
      defecto resultó no serlo.

      Y con ellas, la cláusula 4 del propio delta —«decir QUÉ grupos cambian de lado»— que la
      tabla del delta incumplía contando «los 3 de iOSandbox»: ahora van con nombre y fichero.
      Más una nota de vocabulario que el juez pidió: «un cuerpo de N líneas» son N saltos de
      línea, o sea N−1 sentencias.

## Del juez, tercera ronda (2026-09-08)

**DEVUELTO**, y esta vez sí con hallazgos de código: el contador de rondas vuelve a cero por
su propia regla, y con razón.

- [x] 25. **`verifica.sh` cambió de contrato y no tenía ni una prueba.** Es la pieza que
      decide si hay firma, y por tanto si la puerta deja commitear. Este cambio le tocó los
      códigos de salida, abrió TRES bancos para cerrar ese mismo agujero en otras piezas, y
      dejó abierto justo el suyo. Nuevo `scripts/verifica-salidas.sh`, doce casos, paso 9 de
      `kit.conf`: los códigos (`3` sin `kit.conf`, `1` con rojos sea cual sea el número, `0`
      en verde), que el recuento sobreviva en el informe y en la firma, y que `--comprueba`
      rechace tanto una firma de otro diff como una de una verificación en rojo —este último
      es el falso verde que ya mordió una vez—. Un caso sale rojo contra la versión anterior.

      El banco se cazó a sí mismo en su primera corrida: el repositorio «verde» nacía con dos
      pasos rojos dentro porque `seq 1 0` **cuenta hacia atrás** en BSD e imprimía «1 0».

- [x] 26. **El delta le encargaba al juez saber algo que nadie le decía.** La cláusula que se
      escribió en la ronda anterior dice que quien juzgue «tiene que saber» que lo entregado
      es una ventana temporal y puede contener trabajo de otro cambio abierto — y eso estaba
      solo en el delta, que el juez no lee como instrucción. Su prompt le decía «te da el
      cambio entero» y, tres párrafos después, que cazara «lo que nadie pidió». Ahora
      `agents/aceptacion.md` lo explica y le dice qué hacer: mirar `openspec/changes/` antes
      de llamar a algo «lo que nadie pidió».

- [x] 27. **La fila 5 de la tabla del suelo seguía omitiendo un grupo.** Con suelo 5 se
      pierde también `load()`, copiado entre dos snippets de `spm-pro` — medido: 5 grupos
      pasan a 4. La cláusula 4 pide nombrar QUÉ cambia de lado, y la fila que la incumplía
      estaba un renglón debajo de donde se escribió. Nombrado, en el delta y en `PIEZAS.md`.

## Del juez, cuarta ronda (2026-09-08)

**DEVUELTO**, con un NO CUMPLIDO y tres apuntes — y los cuatro son **la misma clase**: un
recuento sobre sí mismo, escrito a mano, dentro de ficheros que sobreviven al archivado. Tres
de ellos viven en arreglos que se hicieron para esa clase, lo cual es el resumen de este
cambio entero.

- [x] 28. **Los cuatro recuentos:**
      1. `kit.conf` declaraba mal el alcance de su propia medición: «14 scripts… el cambio
         añadió tres». Son 15 y añadió cuatro — la ronda 3 metió el cuarto banco y la nota no
         se movió. Se corrigió poniendo el número bueno… y caducó en nueve minutos, porque
         las ediciones de esta misma tarea subieron el fichero. Así que el número **se ha
         quitado**: la nota lleva la fecha, el comando con el que se cuenta al leer, y el
         resultado, que es lo único que no caduca. Tres intentos de escribir bien un tamaño
         y la respuesta era no escribirlo — que es literalmente la regla que este cambio vino
         a aplicarle al kit.
      2. `verifica-duplicados.sh` presumía de ser «el único script con lógica que nunca se ha
         probado». Eran tres: `verifica.sh` y `rodaja.sh` tampoco tenían banco, y los suyos
         los escribió este mismo cambio, uno de ellos porque lo pidió el juez.
      3. La tarea 13 —la única abierta, la que cierra— mandaba verificar «con los dos bancos
         nuevos dentro». Son tres.
      4. El README prometía «un banco por cada pieza cuyo fallo ya costó algo».
         `autocomprueba.sh` no tiene, y su punto ciego costó seis versiones publicando una
         invocación muerta en el prompt del juez. Ahora lo dice.

      El detector del punto 7 no caza ninguno de los cuatro, y está declarado: solo mira
      markdown. Escribir un segundo detector para los `.sh` sería la reacción que la regla de
      la casa prohíbe — la clase ha fallado aquí una vez, y la respuesta barata es la que ya
      existe: contar con el comando que está escrito al lado.

Y lo que el juez dijo sin que se lo preguntara nadie, que importa más que los cuatro: **el
acuerdo aguanta**. No hay que reescribirlo entero ni son dos cambios; el `proposal.md` y los
seis deltas son coherentes entre sí, todo lo del diff responde a un criterio, y no entró ni
un refactor de paso. Lo que ha degenerado es este `tasks.md`, que ya es cuaderno de
laboratorio — y eso se archiva sin contaminar la spec.

## Del juez, quinta ronda (2026-09-08) — el tope, y lo que el tope no previó

El juez alcanzó su tope de **dos rondas sin hallazgos de código** y se negó a escribir
ninguna de las dos frases que su prompt le obliga a elegir, midiendo por qué las dos serían
falsas: recorrió los criterios y las cláusulas de los seis deltas contra el código y contra
tres repositorios reales, y todo cuadraba. Aplicó la parte operativa de la regla —parar y que
decida el owner— y escribió que le falta una tercera salida:

> «el código está bien y quedan errores de hecho en el texto; que el owner decida si se
> corrigen o se archivan con ellos»

Negarse a firmar una frase falsa para cumplir la forma es exactamente lo que el prompt de ese
agente pide en su última línea. **Esa observación no se arregla aquí**: toca el prompt del
juez, que este cambio declaró fuera de alcance, y merece su propio cambio con el caso escrito.

- [x] 29. **Los tres errores de hecho que traía, medidos por él y confirmados por mí:**
      1. «seis versiones» en `autocomprueba.sh:94` y en el README. Medido: la invocación
         muerta entró en la 1.0.0 y sobrevivió las **diez** versiones publicadas;
         `autocomprueba.sh` nació en la 1.0.1, así que estuvo ciego ante ella nueve. El
         «seis» es correcto en el punto 7 —el «5 skills» dejó de cuadrar en la 1.3.0— y de
         ahí se copió a dos sitios donde el hecho era otro. Uno de ellos, un comentario de
         un `.sh`, no se archiva nunca.
      2. El «Fuera de alcance» del proposal decía «100 y 130 líneas» de los agentes. Medido
         antes del cambio: 98 y 141. Corregido, y es el sitio donde se mira para decidir si
         algo se ha colado.
      3. `lib-kit.sh` remitía a «el comando **y el recuento**» de `kit.conf`, y el recuento se
         había quitado a propósito la ronda anterior. El puntero apuntaba a lo que el arreglo
         borró.

---

## Cierre

- [x] 13. **`/kit-verifica` en verde con los bancos nuevos dentro** —son los de
      `busca-duplicados.py`, `rodaja.sh` y `verifica.sh`, y el recuento lo imprime cada uno—, y `/kit-acepta`
      sobre este cambio — que fue, en efecto, la primera vez que el juez corrió con una
      entrada que de verdad contenía lo entregado: 1.496 líneas donde `git diff main...HEAD`
      daba 0. Cerrado con la verificación en verde y cinco rondas de juicio, la última de las
      cuales paró en el tope y devolvió la decisión al owner.
