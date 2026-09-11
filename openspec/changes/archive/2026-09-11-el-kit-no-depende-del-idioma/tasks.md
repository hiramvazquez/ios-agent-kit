# Tareas

- [x] 1. **Reproducir primero, arreglar después.** Un caso que falle hoy: correr un banco con
      `LANG=en_US.UTF-8` y ver el `unbound variable`. Sin eso, lo que sigue es fe.

- [x] 2. **Las llaves, en las catorce apariciones.** Se listan con
      `grep -rnP '\$[A-Za-z_][A-Za-z0-9_]*[^\x00-\x7F]' scripts/`. No se toca nada más: ni
      `LC_ALL`, ni los mensajes, ni el orden de nada.

- [x] 3. **El detector**, como paso de `kit.conf`. Una línea de `grep`, y el comentario de por
      qué existe: su clase falló más de dos veces y `bash -n` y `shellcheck` salen con 0.

- [x] 4. **Su banco**, con los seis caracteres medidos —`»`, `—`, `·`, `…`, `á`, `€`— y con el
      caso que de verdad distingue: `${A}»` NO se marca y `$A»` SÍ. Un detector que marcara los
      dos sería inútil, porque el mensaje correcto lleva el mismo carácter.

- [x] 5. **Su lista de mutantes**, en `scripts/mutantes/`. Al menos el que quita la comprobación
      entera, y el que la deja marcar también la forma correcta. **Su artefacto no está en lo
      publicado como 1.9.6**: `scripts/mutantes/` y el arnés que lo corre son del cambio
      `los-mutantes-se-commitean`, que todavía no ha salido. Se dice aquí para que la marca de
      hecha no engañe a quien lea solo el acuerdo.

- [x] 6. **`docs/PIEZAS.md`**: la pieza y su límite —los scripts del kit, no el proyecto—.

- [x] 7. **Cierre:** todos los bancos en verde **en los dos locales** —cuántos hay se cuenta con
      `ls scripts/verifica-*.sh`, que no se queda corto cuando nace uno—, `/kit-verifica` firmada en
      los dos, `autocomprueba.sh` limpio. Auditarme antes de invocar a nadie, con el barrido de
      siempre, y con el que esta sesión ha añadido por las malas: **para cada caso que escriba,
      el mutante que debe matarlo, comprobado ejecutándolo**.

## Lo que salió al implementarlo, y no del informe

- [x] 8. **El arreglo repitió el fallo que venía a arreglar.** La primera versión del detector
      usaba `grep -rnoP` y **no encontraba nada nunca**: el `grep` de macOS es BSD y no tiene
      `-P`. Salía con «invalid option», el `|| true` se lo comía, y contestaba «✅ ninguna» sobre
      ficheros que sí las tenían. No se vio porque **el `grep` del agente es otro, uno que sí
      soporta `-P`** — la misma forma exacta del bug: algo que funciona en un entorno y revienta
      en el otro. Reescrito en Python, que ya es dependencia del kit y lee BYTES, sin depender de
      ningún locale.

- [x] 9. **Y el banco lo tapaba.** Comparaba contra «pegado a un carácter no-ASCII», que está en
      el mensaje de éxito **y** en el de fallo: doce casos en verde con el detector muerto. Lo
      destapó **el único caso que miraba el código de salida**, no el mensaje. Todas las
      aserciones van ahora contra el código, y el par que mira texto compara trozos que no son
      subcadena de su contraria.

- [x] 10. **El detector se denunciaba a sí mismo**, porque su cabecera enseña el fallo. Añadida
      la marca `pegada-de-ejemplo`, **por línea y no por fichero** —marcar un ejemplo no puede
      cegar el resto del script—, con dos casos y dos mutantes. Y acotado a `.sh` y `.py`:
      escaneaba los `.pyc`, que nadie escribe a mano.

- [x] 11. **El arreglo rompió la deducción de `muta.sh`.** Su `banco_de` buscaba `$DIR/` y los
      ficheros que ya llevan llaves escriben `${DIR}/`. Cazado al ejecutar; acepta las dos.
      (Vive en el cambio de los mutantes, que es su dueño.)

- [x] 12. **Y uno que solo existía en el árbol de publicación.** El banco nuevo usaba `igual()`
      de `lib-banco.sh`, donde lo mueve el cambio de los mutantes — que no se publica aquí. Al
      reconstruir la 1.9.6 desde HEAD, 18 de 21 casos en rojo. Se definió localmente, como los
      otros bancos de entonces. **Eso quedó en lo publicado**: en el árbol de trabajo ya no está,
      porque el cambio de los mutantes —su dueño— consolidó `igual()` en `lib-banco.sh`. **Solo se vio por verificar el
      árbol que se publica en vez de dar por bueno el de desarrollo.**

**Cierre, medido el 2026-09-10 contra `868d2d7`**, cuando los bancos eran nueve: `/kit-verifica`
firmada y los nueve en verde **con `LANG` vacío y con
`LANG=en_US.UTF-8`**, que era el criterio de aceptación de verdad. `autocomprueba.sh` limpio.

## Del revisor (AMBER, 2026-09-10) — sobre lo ya publicado

Pasada tardía: el cambio ya estaba fuera como 1.9.6. Confirmó, corriéndolo en un worktree del
commit publicado y no en el árbol de trabajo, que **nada de lo publicado rompe**: los nueve
bancos con salida **byte a byte idéntica** en los dos locales, la firma en los dos, y las **diez**
sustituciones dentro de cadenas entre comillas dobles — ninguna en `sed`, heredoc ni regex, o sea
sintaxis pura sin cambio de significado. Y verificó los censos: diez llaves en cinco scripts, 21
casos, seis caracteres.

Su veredicto sobre lo que importaba: **no hay motivo para una 1.9.7 urgente**, porque ninguno de
los huecos que encontró tiene una instancia viva. Aun así son huecos de un detector, que es la
clase que más engaña —uno que no detecta da confianza—, y se cierran aquí.

- [x] 13. **Falso negativo: la continuación de línea.** `$VAR` al final de una línea con `\` y el
      carácter multibyte al principio de la siguiente rompe igual —`bash` une antes de parsear el
      nombre— y el detector, que leía línea a línea, no lo veía nunca. Ahora une las
      continuaciones antes de mirar, y reporta la primera línea, que es donde está la variable.
      Comportamiento: sí.

- [x] 14. **`kit.conf` quedaba fuera, y es donde el fallo es PEOR.** El detector miraba `.sh` y
      `.py`; `kit.conf` no es ninguna de las dos, pero `verifica.sh` lo carga con `.` y con
      `set -u`, así que una variable pegada ahí no da unos pasos en rojo: **mata la verificación
      antes de correr nada**, sin informe y sin firma. Y es el único fichero que el kit le pide a
      cada proyecto que escriba, o sea el más probable de todos. La cláusula 1 dice «ningún script
      del kit» y `kit.conf` lo es: el que prometía de menos era el código, así que se corrige el
      código. Dentro del ámbito, con `kit.conf.ejemplo`.
      Comportamiento: sí.

- [x] 15. **«No pude leerlo» se contestaba como «no tiene ninguna».** Un fichero sin permisos se
      tragaba en silencio y el detector salía con 0. Es la regla que este repositorio escribe en
      dos sitios y que **el propio banco de esta pieza ya fija** para el directorio que no existe,
      rota por la otra puerta de la misma pieza. Ahora sale con 3 y dice qué no pudo leer.
      Comportamiento: sí.

- [x] 16. **Cuatro rangos que ningún caso sujetaba.** Escribió cuatro mutantes y los cuatro
      sobrevivían a los 21 casos, porque todos los fixtures eran iguales: `.sh`, variable de una
      letra, un fichero por directorio, y solo los seis caracteres del bucle. El peor de los
      cuatro: de las diez apariciones reales **la mitad eran de varias letras** —`$RAIZ`,
      `$CAMBIO`, `$CAMBIO_PEDIDO`—, así que recortar el patrón a una letra perdía cinco y el
      banco pasaba en verde porque sus fixtures usaban `A` y `B`. Cuatro casos nuevos, uno por rango.
      Comportamiento: sí.

- [x] 17. **Dos censos y una tarea.** «Catorce apariciones en seis scripts» es cierto en el árbol
      de trabajo y **no en lo publicado**, donde son diez en cinco: las otras cuatro viven en
      `scripts/muta.sh`, que es de otro cambio. Y el item 5 —la lista de mutantes— está marcado
      hecho con su artefacto **fuera de lo publicado**, igual que los items 11 y 12: vive en el
      cambio de los mutantes, que es su dueño, y se publicará con él.
      Comportamiento: no — prosa.

**Lo que declaró como límite y no se arregla:** el detector marca de más en tres formas que
`bash` no rompe —comilla simple, `\$` escapado, y comentario—. Van en la dirección segura: obligan
a poner llaves donde no hacía falta, no dejan pasar donde sí. Se declara y no se persigue.

**Y una observación de proceso que hay que registrar sin adorno:** `pasada-pendiente.sh` sobre
este mismo acuerdo contestaba `NO SE PUEDE LEER — no registra ninguna pasada ni ninguna ronda`, y
se publicó a `main` igualmente. La regla se saltó a conciencia, con el owner decidiéndolo, porque
lo publicado arreglaba algo roto en producción. Queda escrito aquí, que es donde toca.

**Banco: 28 casos. Trece mutantes, todos mueren.**

## Del juez (DEVUELTO, 2026-09-10) — ronda 1

Juzgó por separado lo publicado y el árbol de trabajo, que era lo que hacía falta. **Lo publicado
cumple**: barrido propio sobre el árbol de `868d2d7` entero → cero apariciones; los nueve bancos
con salida byte a byte idéntica en los dos locales; firma en los dos. Y confirmó que **no hace
falta una 1.9.7**, con un argumento que el revisor no había dado: el árbol de trabajo era en un
punto **peor** que lo publicado, y una 1.9.7 de este cambio sola ni siquiera se puede construir
—25 de 28 casos en rojo sin el `lib-banco.sh` del otro cambio—.

- [x] 18. **DEVUELTO — el arreglo del item 14 era inerte.** Añadí `kit.conf` a los nombres
      vigilados, le puse su caso y su mutante… y **en producción esa rama no se ejecutaba nunca**:
      el detector barre por defecto su propio directorio, `scripts/`, y `kit.conf` vive en la
      raíz. `kit.conf:184` lo invoca sin argumento. El caso lo probaba pasándole un directorio a
      mano; **el cableado real, no**. Reproducido por el juez con un `kit.conf` roto: el detector
      decía «✅ sin variables pegadas» y `verifica.sh` moría sin informe y sin firma.

      Arreglado el ámbito por defecto —la raíz del kit, no `scripts/`— y añadido **el caso que
      faltaba**: montar un kit de juguete y correr el detector **sin argumento**, como lo corre
      `kit.conf`. Es el que deja de ser decorativos a todos los demás.
      Comportamiento: sí.

- [x] 19. **Regresión mía: la marca volvió a cegar más de una línea.** El item 10 fijó «por línea
      y no por fichero»; el item 13, al pasar a mirar líneas lógicas, hizo que un
      `pegada-de-ejemplo` escrito en la continuación cegara el `$VAR` de la línea de arriba. **La
      1.9.6 sí lo cazaba y el árbol de trabajo no**: mi arreglo empeoró lo publicado. Ahora la
      marca y el número de línea son de la línea **física**, y los hallazgos se reparten por
      posición al trozo donde empiezan.
      Comportamiento: sí.

- [x] 20. **Tres ramas más sin ningún caso**, todas nacidas en el parche anterior: el directorio
      que no se puede recorrer —la tercera puerta de la regla del item 15—, el último trozo sin
      volcar cuando el fichero acaba en continuación, y la línea que se reporta. Con sus casos.
      Comportamiento: sí.

- [x] 21. **El escenario «dice en qué fichero y en qué línea» no lo fijaba nada.** Dos mutantes
      —línea siempre 1, y sin nombre de fichero— pasaban el banco entero. Con su caso.
      Comportamiento: sí.

- [x] 22. **El censo que se funde en la canónica, y no se puede volver a medir.** El delta decía
      «catorce apariciones en seis scripts, diez ya publicadas», y **cuatro de las catorce nunca
      estuvieron commiteadas**: ningún `git log` puede devolver ese número, así que quien lo lea
      dentro de un año no tiene forma de comprobarlo. Fuera el recuento, dentro el criterio —«su
      clase reincidió en varios scripts y en varios cambios»— y el comando que sí se puede correr
      hoy y siempre. Lo mismo en `kit.conf`, `docs/PIEZAS.md` y la cabecera del detector, que son
      ficheros permanentes. Y «los nueve bancos» caducó en cuanto nació uno más: pasa a contarse
      con `ls`.
      Comportamiento: no — prosa, pero en la canónica.

**Su diagnóstico de convergencia, que es el que hay que mirar:** *cuatro de sus cinco hallazgos
viven dentro del parche de la ronda anterior.* No es una búsqueda que converja: es la misma clase
—un detector que no detecta— reapareciendo en cada capa de arreglo. Y nombró lo estructural, que
no es un sexto parche: **ningún caso del banco ejercitaba el cableado real** —`kit.conf` → el
detector → la raíz de barrido—; todos probaban la pieza contra fixtures que le pasaban un
directorio a mano. Ese caso ya existe, y es el item 18.

**Su encargo sobre el registro**, cumplido aquí: esta es la ronda 1 del juez y queda anotada, para
que el siguiente —que arranca en blanco— no empiece contando uno.

**Y su grieta sobre `pasada-pendiente.sh`**, que conviene no tapar: hoy contesta `NO FALTA` sobre
este acuerdo porque la sección del revisor se añadió *después* de publicar. La herramienta ya no
puede distinguir «se pasó revisor a tiempo» de «se publicó sin pasada y se anotó luego»; el único
rastro es la prosa. Lo que faltaría para que el registro fuese correcto y no solo honesto es que
la anotación de una pasada lleve **contra qué commit** se hizo. No es de este cambio: queda
apuntado.

**Banco al cerrar esta ronda: 33 casos y diecinueve mutantes**, medido entonces. El estado de
hoy lo dicen el banco y `muta.sh` al correrlos; aquí no se reescribe.

## Del juez (DEVUELTO, 2026-09-10) — ronda 2

Verificó los siete criterios y las cuatro cláusulas ejecutando, y dio el dato que cambia la
lectura: **la severidad converge**. En la ronda 1 los hallazgos de dentro del parche eran código
equivocado; en esta, el único que mueve comportamiento es *una prueba que falta para código que
es correcto*. «El detector aguantó todo lo que le tiré —cinco fixtures multilínea, siete mutantes
escritos a mano, dos locales, diez bancos byte a byte, y el árbol publicado entero.»

- [x] 23. **El reparto de `revisa()` no lo sujetaba nadie: se podía borrar entero con el banco en
      verde.** Un mutante que atribuyera siempre al primer trozo convierte en falso negativo
      cualquier pegada escrita en una continuación bajo una línea marcada — la regresión del item
      19 al revés. Y su gemelo fino, el límite `<=` frente a `<`, falla cuando el `$VAR` es el
      **primer carácter** de la continuación. Dos casos y dos mutantes; el segundo necesitó un
      fixture propio, porque es el único borde que los distingue.
      Comportamiento: sí.

- [x] 24. **`docs/PIEZAS.md` declaraba un ámbito más estrecho que el código, y omitía `kit.conf`.**
      Quien leyera el documento concluía que su `kit.conf` no se mira — que es justo donde el
      fallo mata la verificación antes de correr nada. Reescrito con las dos formas —extensión y
      nombre— y con la raíz por defecto.
      Comportamiento: no — prosa, pero era un criterio de aceptación incumplido.

- [x] 25. **Dos números míos, falsos y medibles, en cinco ficheros permanentes.** «Cuatro pasos en
      rojo» eran **tres** —el cuarto era del otro cambio y no existía en la 1.9.5—, y «ninguna de
      las diez era de una sola letra» resultó que **cinco lo eran**. Medidos los dos antes de
      tocarlos, y corregidos.

      Y el juez nombró el mecanismo mejor de lo que yo lo tenía: *el item 22 atacó esto buscando
      la palabra «catorce» en vez de preguntar «¿qué números hay escritos junto a esta pieza?»*.
      Por eso sobrevivieron. Esta vez se enumeraron **todos** los números de los ocho ficheros de
      la pieza, no una palabra.
      Comportamiento: no — prosa.

**Su medida de convergencia:** ronda 1, cuatro de cinco hallazgos dentro del parche anterior;
ronda 2, tres de seis. El ratio apenas se mueve, pero la severidad sí. Lo que no converge es el
mecanismo: cada arreglo reescribe la justificación en prosa y la ronda siguiente encuentra un
número falso en ella.

## Del revisor (AMBER, 2026-09-10) — sobre las dos rondas de juez

La pidió el propio kit: `pasada-pendiente.sh` contestaba FALTA. Y contestó primero la pregunta
que más importaba, con un **diferencial de 4.000 fixtures** entre el detector publicado y el del
árbol: **cero hallazgos que solo cace el publicado**, veintiséis que solo caza el nuevo. Ningún
arreglo hizo que cazara menos — que ya había pasado una vez.

- [x] 26. **Dos ramas con nombre y sin caso.** `kit.conf.ejemplo` era el segundo nombre vigilado
      y el banco solo montaba el primero; y el ámbito estaba fijado por abajo pero no por arriba,
      así que subir un `dirname` de más pasaba en verde. Lo segundo enmascarado por una razón
      fina: el kit de juguete vivía dentro del temporal de los demás fixtures, que sí tienen
      pegadas, así que un ámbito ensanchado salía con 1 por la razón equivocada. Ahora va en su
      propio temporal, con un vecino limpio al lado que fija el límite superior.
      Comportamiento: sí.

- [x] 27. **El banco codificaba el basename del detector**, así que un mutante guardado con otro
      nombre hacía fallar el caso por «fichero no encontrado» y salía «muerto» por la razón
      equivocada. **Me pasó mientras verificaba estos dos hallazgos**: los medí primero con otro
      nombre, salieron «muertos», y solo el apunte del revisor me hizo repetirlo bien. Es la
      forma más silenciosa de que un banco deje de medir. Arreglado, y comprobado corriendo el
      banco con el detector renombrado.
      Comportamiento: sí.

- [x] 28. **La cabecera del detector contradecía su propio arreglo**, y la ronda 2 del juez no
      estaba registrada. Lo primero: decía «por defecto, el `scripts/` del kit» desde que el item
      18 la cambió a la raíz — la línea de «uso» de la pieza, mintiendo. Lo segundo: había tres
      casos y dos mutantes sin item que los explicara, y el censo de cierre midiendo el estado
      anterior. Los dos corregidos; la ronda 2 queda anotada arriba.
      Comportamiento: no — prosa, pero rompía el registro del que depende `pasada-pendiente.sh`.

**Límite que el revisor declaró y no se persigue:** una continuación con CRLF no se caza, porque
el `\r` queda pegado antes de la barra. Lo publicado tampoco la cazaba, y un script con CRLF
rompe en `bash` por otras razones antes de llegar a esto.

**Banco y mutantes: los cuenta el banco y `muta.sh`.** Aquí no se escribe el número, que es la
lección que este cambio ha pagado tres veces.

## Del juez (DEVUELTO, 2026-09-10) — ronda 3

Verificó los siete criterios, las cuatro cláusulas y los tres escenarios ejecutando, y los ocho
hallazgos anteriores cerrados uno a uno. Y **rehizo el censo de números completo: ninguno falso.
Es la primera ronda que lo consigue** — cuatro rondas costó.

- [x] 29. **El banco fugaba un directorio temporal en cada corrida.** El `mktemp -d` que metí en
      el item 26 para aislar el kit de juguete no tenía `trap` ni `rm`: dejaba en disco el
      directorio con sus fixtures **en cada `/kit-verifica`**, o sea en cada puerta de commit, y
      `muta.sh` lo corre veinticuatro veces seguidas. Era el único `mktemp` del repositorio sin
      limpieza —`lib-banco.sh` y `muta.sh` ponen los dos el suyo— y lo escribió el parche de la
      ronda anterior.

      No se arregla con un `trap` más: se arregla con el helper que el juez propuso. `kit_aislado`
      monta la raíz de juguete **dentro de `${TMP}`**, que `lib-banco.sh` ya limpia, y da un solo
      sitio donde montarlas. Comprobado: tres corridas del banco, cero temporales nuevos.
      Comportamiento: sí.

- [x] 30. **El tercer parámetro del reparto, libre dos rondas.** `revisa()` tiene tres: a qué
      trozo se atribuye, con qué límite, y **por dónde se mide la coincidencia**. La ronda 1
      escribió el bucle, la ronda 2 fijó los dos primeros, y el tercero se quedó sin caso:
      repartir por donde **acaba** en vez de por donde **empieza** mete el hallazgo en el trozo
      siguiente, y si ese lleva la marca, lo tapa. Falso negativo. Con su caso —una coincidencia
      que cruza el corte— y su mutante.
      Comportamiento: sí.

- [x] 31. **El `proposal.md` describía el ámbito viejo**, tercera instancia de la clase que el
      item 24 cerró en `PIEZAS.md` y el 28 en la cabecera del detector. Y seguía diciendo «una
      línea de `grep`» para 170 líneas de Python. Los dos corregidos, el segundo contando por qué
      dejó de ser una línea de `grep`.
      Comportamiento: no — prosa.

**Su diagnóstico, que es el que hay que leer y no el ratio:**

| ronda | hallazgos | dentro del parche anterior |
|---|---|---|
| juez 1 | 5 | 4 |
| juez 2 | 6 | 3 |
| juez 3 | 3 | 2 |

> «La severidad bajó mucho —la ronda 1 encontró código equivocado; esta, una fuga de 4 KB y una
> prueba que falta—, pero el mecanismo no converge: cada ronda añade andamiaje a esta pieza y la
> siguiente encuentra el defecto en lo añadido. Son 606 líneas de detector + banco + mutantes
> para una expresión regular de una línea, y **el riesgo residual está todo en el andamiaje, no
> en la regex**.»

Por eso el arreglo del item 29 no es un `trap`: es el helper. Un solo sitio donde montar una raíz
aislada hace imposible la clase entera, que es lo que `lib-banco.sh` ya hacía para lo demás y que
esta pieza se saltó por montar sus fixtures a mano.

**Y confirmó por tercera vez que no hace falta una 1.9.7**, ahora con tres medidas: el detector de
hoy —más estricto— sobre lo publicado da cero hallazgos; `verifica.sh` sale verde y firmada ahí
con `LANG=en_US.UTF-8`; y un diferencial propio de 1500 fixtures da **0 hallazgos que solo cace
lo publicado** y 356 que solo caza el nuevo.

## Del juez (DEVUELTO, 2026-09-10) — ronda 4

**Cambió de método**, y eso es lo que hay que leer de esta ronda: en vez de revisar el parche
anterior, escribió **diecinueve mutantes contra la pieza entera**. Sobrevivieron ocho, cinco de
ellos huecos reales — y ninguno lo fabricó el último arreglo. Son viejos.

- [x] 32. **El caso del que depende todo el banco pasaba en verde sin montar nada.** El del
      cableado comparaba `$? == 1`, y **un `cd` que falla devuelve 1**: con el kit de juguete
      inexistente salía ✅. Lo demostró rompiendo `kit_aislado` a propósito. Es el caso que el
      item 18 llamó «el que deja de ser decorativos a todos los demás», y era el que menos medía.
      Tercera vez de esta clase en este cambio, y la misma que `muta.sh` cita como el peor de sus
      tres ejemplos. Ahora comprueba el **mensaje**, no el código de salida.
      Comportamiento: sí.

- [x] 33. **Cuatro mutantes más, todos de código correcto sin prueba.** Solo el primer fichero de
      cada carpeta —el tercero de los cuatro rangos que el item 16 dijo cerrar, y que su caso no
      cerraba porque montaba un fichero por directorio—; solo la primera coincidencia de una
      línea lógica; `break` en vez de `continue` tras una marca; y la precedencia de «no pude
      mirar» sobre «hay alguna». Los cuatro con su fixture y su mutante, comprobados muriendo. El
      primero necesitó fixture propio: en el que había, otro roto en un subdirectorio lo salvaba.
      Comportamiento: sí.

- [x] 34. **«Dice cuál y dónde» solo fijaba el dónde.** Vaciar el texto del hallazgo pasaba los
      39 casos. Con su aserción.
      Comportamiento: sí.

- [x] 35. **Siete correcciones de prosa**, entre ellas dos que el item 25 dio por cerradas y
      sobrevivieron en el acuerdo —el bloque de reproducción con cuatro ❌ y un paso de otro
      cambio, y el item 14 diciendo «cuatro pasos»—, un criterio de aceptación con el ámbito
      viejo (cuarta instancia de esa clase), un puntero roto que nació en el item 31, un
      **mojibake** de raya doblemente codificada escrito por el item 30, y la cabecera del banco
      nombrando la pieza con la extensión equivocada.
      Comportamiento: no — prosa.

**Su diagnóstico del método, que es lo que este cambio deja para el siguiente:**

> «El ratio baja y el número absoluto se cuadruplica, y eso no es convergencia: es que cambié el
> método. Las tres rondas anteriores leyeron el parche anterior; esta escribió mutantes contra la
> pieza entera, y los huecos que salieron son **viejos** —el rango del item 16, el bucle
> `finditer` de la ronda 1, la aserción del caso del cableado—. No los fabricó el último arreglo:
> llevaban ahí desde el principio y cuatro rondas de leer diffs no los vieron.
>
> Lo estructural no es el andamiaje: es que **la lista de mutantes es un registro de bugs pasados
> y no un instrumento de cobertura.** Sus entradas se escribieron una por defecto encontrado,
> siempre después. Nada en el kit pregunta «¿qué ramas no tienen mutante?», y por eso cada ronda
> encuentra supervivientes nuevos sin que el código se mueva.»

Eso es un agujero de `muta.sh`, la pieza que el otro cambio entrega, nombrado por quien la estaba
usando. **Va anotado ahí**, no aquí: el arnés sabe decir si un mutante escrito muere, y no sabe
decir qué ramas no tiene ningún mutante.

**Y su recomendación, que se acata:** una pasada corta y parar. *«Después de esta pasada, no
volver a juzgar el andamiaje de esta pieza: la siguiente ronda encontrará otro superviviente, y
eso seguirá siendo verdad indefinidamente.»* Son 637 líneas de detector, banco y mutantes para
una expresión regular de una línea, y el riesgo residual está todo en el andamiaje.

**Cuarta confirmación de que no hace falta una 1.9.7**: diferencial de 1200 fixtures entre el
detector publicado y el de hoy → **cero hallazgos que solo cace el publicado**, 221 que solo caza
el nuevo.

## Del revisor (AMBER, 2026-09-11) — sobre la ronda 4

Acotada a los items 32–35. Lo que hicieron aguanta, y lo comprobó rompiendo: el caso del cableado
sale rojo con `kit_aislado` roto, los 29 mutantes mueren igual en los dos locales, el banco no
fuga y el bloque de reproducción de la 1.9.5 es cierto.

- [x] 36. **Un puntero seguía roto en `proposal.md`** —el del paso de `grep` a Python—, que el
      item 35 dio por arreglado. No se arregla la frase: la renegociación de abajo retira ese
      párrafo.
      Comportamiento: no — prosa.

- [x] 37. **Límite: un detector que barriera `.` en vez de su raíz pasaba los 43 casos.** En
      producción daba lo mismo. Se anota sin tocar, por la decisión del owner del 2026-09-11 —una
      prueba que falta para código correcto se anota, no se arregla—, y queda sin objeto con la
      renegociación, igual que un mojibake y un comentario desfasado del banco.
      Comportamiento: no.

## Renegociado el 2026-09-11 — el detector es una línea

La auditoría del kit de ese día —scripts, reglas, flujo e historia— encontró que casi todo lo
añadido desde el 2026-09-08 salió del kit revisándose a sí mismo y no había corrido nunca en un
proyecto real. Aquí eran 711 líneas de detector, banco y mutantes para una expresión regular, y
cuatro rondas de juez sobre el andamiaje con el arreglo —las llaves— publicado y correcto desde la
1.9.6. Lo decidió el owner.

- [x] 38. **El detector pasa a ser un paso de una línea en `kit.conf`**, con el mismo ámbito —no
      hay `.sh` ni `.py` fuera de `scripts/`, medido con `git ls-files`—. Se retiran
      `scripts/variables-pegadas.py`, su banco y su sección de `docs/PIEZAS.md`. Sustituye a los
      items 3, 4 y 6; el 5 se fue con `los-mutantes-se-commitean`, que salió del árbol el mismo día
      (copia en la rama local `guardado/2026-09-11-antes-de-la-dieta`).

- [x] 39. **Dos cosas que la línea necesitaba y no traía**, las dos medidas: tal como la propuso la
      auditoría salía con 0 aunque encontrara algo —el `END` la pone en rojo—; y sin `-C0`, con
      `PERL_UNICODE=SDA`, solo veía tres de los seis caracteres —`—`, `…` y `€` quedan fuera de
      `[\x80-\xff]` cuando perl decodifica—.

- [x] 40. **Lo que no ve, escrito** junto al paso y en la spec: el proyecto que usa el kit, un
      `.sh` fuera de `scripts/`, una variable partida con `\` al final de línea y un fichero que no
      pueda abrir.

- [x] 41. **Comprobado sin banco**, con el paso tal cual está en `kit.conf`: sale rojo con las
      seis formas rotas y no marca las seis correctas, en los dos locales. En la 1.9.5 señala las
      mismas 9 líneas que el detector en Python; en el árbol, ninguna.

```bash
L=$(grep '^ *paso "variables pegadas"' kit.conf); d=$(mktemp -d); mkdir -p "$d/scripts" "$d/plantillas"
printf 'X=1\n' > "$d/kit.conf"; : > "$d/plantillas/kit.conf.ejemplo"; : > "$d/scripts/p.py"
for c in » — · … á €; do printf 'echo "$A%s"\n' "$c" >> "$d/scripts/rota.sh"; printf 'echo "${A}%s"\n' "$c" >> "$d/scripts/bien.sh"; done
corre() { for l in "" en_US.UTF-8; do LANG=$l bash -c 'paso() { shift; "$@"; }; cd "$1"; eval "$2"' _ "$d" "$L"; echo "código $?"; done; }
corre                            # rotas y correctas: solo las seis rotas, y código 1, en cada locale
rm "$d/scripts/rota.sh"; corre   # solo las correctas: nada, y código 0, en cada locale
rm -rf "$d"
```

## Del revisor (AMBER, 2026-09-11) — sobre la renegociación

Acotada a los items 36–41, al paso nuevo de `kit.conf` y a la renegociación. El paso funciona
pasando por `verifica.sh` en los dos locales, quitar el detector y su banco no rompe nada, y las
notas citan bien lo que decían los criterios.

- [x] 42. **El comando del item 41 no podía dar verde**, y el criterio quinto dice que lo
      comprueba: montaba las formas rotas y las correctas en el mismo directorio. Se arregla el
      comando, no el criterio: una segunda corrida solo con las correctas, que sale con 0 en los
      dos locales.
      Comportamiento: no — el comando del acuerdo, no una pieza.

- [x] 43. **Límite, ya declarado:** con un fichero que perl no puede abrir, el paso sale en verde
      sin avisar.
      Comportamiento: no.

## Del juez (DEVUELTO, 2026-09-11) — ronda 5

Sobre la renegociación. Da por cumplidos, ejecutándolos, seis de los siete criterios y los cuatro
puntos de la spec, en los dos locales, y juzga la renegociación honesta: las notas citan bien lo
que decía el acuerdo. Tres de sus cuatro hallazgos los escribió o los dejó desfasados el parche de
la renegociación.

- [x] 44. **El paso se saltaba las líneas con `pegada-de-ejemplo`, y la spec no lo decía**, que es
      lo que exige el criterio sexto. No se documenta: se quita. Ningún fichero barrido usa la
      marca —solo el propio paso y su comentario—, y sin ella el árbol sigue en 0 y la 1.9.5 en sus
      9 líneas, medido. Decidido por el owner.
      Comportamiento: sí.

- [x] 45. **La nota de renegociación se quedaba corta**: no contaba entre lo perdido la variable
      partida con `\` ni los scripts fuera de `scripts/`, y «no la exigencia» exageraba. Corregida.
      Comportamiento: no — prosa.

- [x] 46. **«Las llaves, en las catorce»**: se entregan diez; las otras cuatro eran de `muta.sh`.
      Corregido en What Changes, diciendo lo que ponía.
      Comportamiento: no — prosa.

- [x] 47. **Items viejos desfasados** —el 3, el 4 y el 6 con sus ficheros retirados; el 5 y el 17
      diciendo que la lista de mutantes se publicará con su cambio—. No se reescriben: el 38 los
      sustituye, y el cambio de los mutantes salió del árbol el 2026-09-11.
      Comportamiento: no.

**Límites que anota, y no se arreglan:** ningún banco caza que alguien rompa la línea de `perl`
—decisión del owner—; una variable pegada dentro de `kit.conf` aborta la verificación en UTF-8
antes de que corra el paso, con error y sin firma; y `verifica.sh` enseña solo las últimas 15
líneas de un paso en rojo.

## Del revisor (GREEN, 2026-09-11) — sobre la ronda 5

Acotada a los items 44–47. Cargó el paso como lo carga `verifica.sh`, con `bash` 3.2 y en los dos
locales: rojo con las seis formas rotas —y ya también con la marca—, verde con las correctas, y el
árbol en verde. «Diez llaves» y la lista de pérdidas de la nota, comprobadas contra la 1.9.5 y la
rama de la copia.

- [x] 48. **Un límite escrito se quedaba corto:** el detector en Python también entraba en las
      subcarpetas de `scripts/`, y `scripts/*.sh` no. Hoy no hay ninguna. Como el criterio sexto
      pide escribir lo que el paso no ve, se precisa junto al paso, en la spec y en la nota: «un
      script fuera de `scripts/` o en una subcarpeta suya».
      Comportamiento: no — prosa.

## Del juez (ACEPTADO, 2026-09-11) — ronda 6

Todo ejecutado con `bash` 3.2 en los dos locales: los siete criterios y los cuatro puntos de la
spec, cumplidos; las notas de renegociación, honestas; y nada staged que nadie pidiera.

- [x] 49. **«Están anotadas» ya no apuntaba a nada**: las clases pendientes que cita el FUERA de
      alcance estaban anotadas en el cambio de los mutantes, que salió del árbol. No bloqueaba. Se
      corrige la frase, diciendo lo que ponía.
      Comportamiento: no — prosa.

**Límites que anota:** ningún banco vigila la línea de `perl` —decisión del owner—, y el comando
del item 41 solo prueba `scripts/*.sh`; `.py`, `kit.conf` y la plantilla los probó el juez a mano.
