# Tareas

Dos documentos y ninguna línea de código. Por la tabla de `docs/FLUJO.md` este cambio podría
saltarse esta lista; va porque el esquema del CLI la pide para `apply`.

- [x] 1. **La tabla de rondas en `docs/FLUJO.md`**, hermana de la de proceso y al lado de ella:
      cuántas presupuestar según lo que se ponga bajo juicio —código con tests, prosa, una
      norma—, con la medición que lo sostiene y por qué el eje no es el tamaño.

- [x] 2. **La regla que no depende del número**: el presupuesto se decide antes de invocar, y al
      agotarse para y decide el owner. Decir que es la forma del tope del juez movida al otro
      lado, para que nadie los confunda ni los duplique.

- [x] 3. **Separar las dos preguntas de coste en `docs/PIEZAS.md`**: lo que cuesta tener el kit
      puesto —lo que ya está— y lo que cuesta una ronda de juicio, fechado y diciendo sobre qué
      se midió.

- [x] 4. **Declarar los dos límites donde se leen**: que las cifras son de prosa normativa y son
      un techo, no una media; y que nadie cuenta rondas ni tokens por ti.

- [x] 5. **Cierre:** `git diff` sin tocar `agents/`, `/kit-verifica` en verde,
      `autocomprueba.sh` limpio. Y auditarme yo antes de invocar al juez, buscando lo de
      siempre: un predicado más ancho que la realidad.

## Auditoría propia, antes de invocar a nadie

- [x] 6. **Los criterios, comprobados uno a uno con `grep` contra los ficheros**, y un barrido
      de absolutos —«siempre», «nunca», «todo cambio», «garantiza»— sobre la sección nueva: no
      queda ninguno sin su límite al lado, que es mi fallo recurrente y el que tres jueces
      seguidos me han cazado.

      Dos `❌` de la auditoría resultaron ser mis propios patrones de búsqueda, no el texto —el
      «techo, no media» de `FLUJO.md` parte a mitad de línea, y la comprobación de `agents/`
      estaba mal escrita—. Se dicen porque una auditoría que no reporta sus falsos positivos se
      lee como más limpia de lo que fue.

## Del juez (DEVUELTO, 2026-09-08)

La mejor ronda de las que ha habido. Seis hallazgos, ninguno cosmético, y **tres de ellos son
números que yo había publicado como censo**. La auditoría propia de la tarea 6 no los vio, y el
juez explicó por qué: barrí «siempre/nunca/garantiza», y lo que se me escapaba era el
**cuantificador implícito** —«nueve» presentado como todas, «casi nada» como magnitud—, que
ningún barrido de absolutos encuentra.

- [x] 7. **«Nueve rondas» eran diecisiete.** Publiqué las nueve de las que tenía cifra como si
      fueran las del día, así que la media era de una muestra por disponibilidad presentada
      como censo. También «tres cambios» cuando el archivo tiene seis carpetas de ese día, y
      «seis rondas de juez» cuando fueron cinco más una auditoría mía. Los tres corregidos, y
      la muestra va ahora escrita en la propia tabla: «9 rondas de las 17».

- [x] 8. **Mi titular estaba inflado, y él lo midió.** «No pagas por el tamaño, pagas por la
      ronda» sobre un **+52 %** —112k contra 74k— llamándolo «apenas más caro» y «casi nada».
      El dato sostiene «el tamaño escala muy por debajo de lo lineal», que ya es
      contraintuitivo y útil; no sostiene que el tamaño dé igual. Y mi «1,6» era el
      emparejamiento más favorable: las medias dan 1,52 y el rango va de 1,25 a 1,83.

- [x] 9. **La tesis contradecía una norma que el kit ya publica, en el mismo fichero.**
      `docs/FLUJO.md:144` y `agents/reviewer.md:21` dicen «el coste es tamaño de lo revisado ×
      número de rondas»; mi texto decía «no pagas por el tamaño», a 140 líneas de distancia y
      sin nada que las reconciliara. Ahora se reconcilian donde vive la tabla: **la fórmula
      sigue siendo la buena, y lo que se aprende es que su primer factor crece despacio**. El
      prompt del reviewer se queda fuera de alcance, y eso se declara con su razón.

- [x] 10. **Un párrafo ajeno quedó dentro de mi sección y pasó a apuntar al cambio
      equivocado.** «No escribas números de línea en la prosa… en ese mismo cambio, añadir un
      `import` los desplazó» colgaba del cambio de cuatro líneas; mi inserción lo dejó bajo
      «Qué hacer cuando se agote», donde «ese mismo cambio» solo podía leerse como el de 300
      líneas de shell — en el que un `import` no significa nada. Devuelto a su antecedente.

- [x] 11. **La tabla no tenía fila para el caso normal.** Un cambio con código, tests y una
      spec nueva dispara dos filas a la vez, y el flujo **nunca** deja saltarse el delta de
      spec: casi todo cambio pone prosa bajo juicio. El desempate estaba en el `proposal.md` y
      no había llegado al documento que lee el usuario. Cuarta fila: **manda la prosa**, con la
      razón — el código lo cierran los tests, la norma la cierra alguien leyendo.

- [x] 12. **Y el que más vergüenza da: las cifras no se pueden recomprobar.** Salen de las
      notificaciones de los sub-agentes, que no viven en el repositorio. El propio kit exige que
      una medición fechada vaya con **el comando que la produjo** —y la tabla hermana de
      `PIEZAS.md` lo cumple, mandándote correr `claude plugin details`—. La mía iba en el mismo
      formato, con la misma autoridad tipográfica, sin comando y sin decir que no lo tiene.
      Declarado ahora en los tres sitios donde se publican.

## Del juez, segunda ronda (DEVUELTO, 2026-09-08)

Dos bloqueantes, tres errores de hecho —dos de ellos suyos, y lo dice él— y el cuantificador
implícito que quedaba vivo.

- [x] 13. **BLOQUEANTE. Mi cuarta fila se comía las otras tres.** La justifiqué diciendo «el
      flujo nunca te deja saltarte el delta de spec, así que casi todo cambio pone prosa bajo
      juicio» — y con eso la fila 4 dispara **siempre** y las filas de código son inalcanzables:
      el «1–2» que este cambio quiere que use un equipo de Swift no se puede presupuestar jamás.

      La distinción que perdí estaba en mi propio `proposal.md` y no llegó al documento que lee
      el usuario: **una cosa es que el delta sea la vara con la que se mide el código —caso
      normal, filas 1 y 2— y otra que el delta sea el producto juzgado —fila 3—.** Escrita
      ahora donde vive la tabla. Y es, otra vez, un predicado más ancho que la realidad metido
      **por el arreglo de la ronda anterior**: el patrón que este mismo cambio documenta.

- [x] 14. **BLOQUEANTE, y el que más duele: el delta llegó sin el barrido.** Corregí el titular,
      el censo y el «casi nada» en `FLUJO.md`, en `PIEZAS.md` y en el `proposal.md`, y **el
      delta se quedó fuera** — con las cuatro afirmaciones tumbadas intactas.

      Su argumento de por qué eso sí bloquea es irrebatible: **al archivar, la prosa del delta
      se copia verbatim a `openspec/specs/`**, y lo demostró con un archivo anterior línea a
      línea. Archivar habría publicado como norma permanente una frase que contradice el
      `FLUJO.md` que este mismo cambio acaba de escribir. Y la cláusula 5 del delta dice
      «**ningún** documento»: un delta que se exceptúa a sí mismo vacía su propia cláusula.

      Barrido, y al hacerlo apareció una quinta instancia en el `proposal.md`. Cinco ficheros,
      y el barrido se me quedó corto en dos.

- [x] 15. **F5 era mío: «dos órdenes de magnitud» son 42–78 veces.** 67,7k/1,6k = 42×;
      124,3k/1,6k = 78×. Dos órdenes es 100×. Redondear en la dirección que favorece la tesis es
      exactamente lo que me tumbó en la ronda 1, cometido en la misma frase que lo denuncia.
      «Entre cuarenta y ochenta veces» ya es demoledor y además es cierto.

- [x] 16. **F3 y F4 eran suyos, y lo compruebo aquí porque aceptar una corrección falsa es tan
      malo como rechazar una cierta.** Dijo que la media pequeña es 73k y no 74k, y que el ratio
      máximo es 1,85 y no 1,83. Recalculado desde los datos brutos: 73.858 → **74k**, y el
      emparejamiento máximo 124.294/67.741 = **1,83**. Mis cifras eran correctas; él las
      recalculó desde mis valores **redondeados** de la tabla, donde sí salen 73k y 1,85.

      Pero debajo hay un hallazgo real y suyo: **lo publicado no se podía reproducir
      leyéndolo.** Ahora las cuatro cifras van con decimal —124,3 · 100,0 · 67,7 · 80,0— y se
      dice por qué, con el caso que lo destapó.

- [x] 17. **El cuantificador implícito que seguía vivo, y es de segundo orden.** «El eje es qué
      se juzga, no cuánto ocupa, **y eso está medido**»: lo medido descarta el tamaño, no mide
      el eje. La fila de prosa se apoya en n=1 y **las dos filas de código en n=0**. No cuenta
      cosas, cuenta cuánta evidencia hay, y la presentaba como más de la que es. Dicho ahora al
      lado de la tabla: esas dos filas son una apuesta razonada, no un dato.
