# Tareas

- [x] 1. **Extraer a `lib-kit.sh`** la resolución de qué DerivedData pertenece a un
      repositorio, con el patrón que `cambio_activo` ya usa: deja una variable puesta y se
      llama sin subshell, porque un array no sobrevive a una sustitución de comandos en bash
      3.2. La heurística y sus límites se mueven con ella; no cambian.

- [x] 2. **`inyecta-contexto.sh` la usa** en vez de resolverla en línea. El digest sale
      idéntico — es un movimiento, no un cambio de comportamiento.

- [x] 3. **`doc-paquetes.sh` la usa**, que es el arreglo. Carga `lib-kit.sh` como hacen los
      demás, con `$DIR` resuelto ANTES del `cd`.

- [x] 4. **El banco monta un DerivedData AJENO** bajo su `HOME` de prueba. Es el punto ciego
      que dejó pasar esto: fijar `HOME` a un temporal vacío hacía que la rama de DerivedData
      no se ejercitara nunca. El caso tiene que salir en rojo contra la 1.8.0.

- [x] 5. **Cierre:** `/kit-verifica` en verde, `autocomprueba.sh` limpio, y el digest
      comprobado idéntico contra la versión publicada.

## Nota de implementación

- [x] 6. **Se fundieron dos casos del banco.** Al dejar de estar vacío el `HOME` de prueba, el
      caso «un repositorio sin nada resuelto **en ningún sitio** recibe el mensaje» dejó de
      describir a su propio fixture: ahora hay paquetes en la máquina, solo que no son suyos.
      Era la misma aserción que el caso nuevo, con la premisa caducada, y salía como fallo
      imprevisto contra la 1.8.0. Fundidos en uno que afirma las dos mitades — que sale el
      mensaje **y** que no aparece el paquete del vecino.

- [x] 7. **El caso de «SÍ recibe los suyos» no es redundante.** Sin él, un mutante que borrase
      la rama de DerivedData entera pasaría con nota el caso de arriba: no anunciaría los
      ajenos porque no anunciaría nada, y dejaría a todo proyecto de Xcode sin la doc de sus
      dependencias. Acotar de más es el otro lado del mismo error.

## Del revisor (AMBER, 2026-09-08)

Dos hallazgos, los dos sobre el mismo punto y ninguno sobre el arreglo en sí. Confirmó además,
midiéndolo, que `shopt` no muerde hoy, que `$DIR` resuelve bien desde un subdirectorio, que el
digest sale byte a byte idéntico, y que `find` sin rutas falla en BSD en vez de caer al cwd.

- [x] 8. **La heurística deja pasar el mismo fallo cuando un proyecto se llama como el tuyo
      MÁS UN GUION.** `spm-*` casa con `spm-pro-<hash>`, así que un repositorio llamado `spm`
      recibe lo de `spm-pro` — el caso del proposal con los nombres al revés. Reproducido.

      No es regresión: el glob viene tal cual de la 1.8.0, y arreglar la heurística está
      declarado fuera de alcance. Lo que **sí** es de este cambio es que `lib-kit.sh` es ahora
      la declaración canónica de los límites y no lo listaba, y que `README.md` y
      `docs/PIEZAS.md` afirmaban que la heurística «falla hacia el lado seguro» — falso en este
      caso, y lo escribí yo. Los tres límites quedan declarados, y las dos frases corregidas.

- [x] 9. **Un mutante sin el guion pasaba el banco entero en verde.** `${proyecto}*` en vez de
      `${proyecto}-*`, con el que un repo `App` se llevaría lo de `AppStarter-<hash>`. La causa
      era el fixture: montaba el ajeno como `OtroProyecto-…`, sin relación de nombre con ningún
      repo del banco, así que medía lo fácil.

      **Y el primer intento de arreglarlo estuvo mal**: monté `vacio-extra-…`, que casa también
      con el patrón correcto, o sea que probaba el agujero de la tarea 8 —el que se deja abierto
      a propósito— y salía rojo contra el código bueno. El banco lo devolvió en el acto. El
      fixture correcto es `vacioextra-…`, sin guion, y ahí está la diferencia entera.

- [x] 10. **Sus tres opcionales, aceptados.** `shopt` restaura el estado previo con
      `shopt -p` en vez de apagarlo —hoy no muerde, pero es una trampa para el que venga—; se
      documenta que `find` sin rutas es un error de uso en BSD y que **en GNU find recorrería el
      cwd**, que es de lo que depende que esa rama sea correcta; y la aserción del banco vuelve
      a la cadena entera que publica el escenario de la spec.

- [x] 11. **Su nota de proceso:** `rodaja.sh` reportó 1914 líneas porque la marca es anterior al
      commit de la 1.8.0. Lo nuevo eran 306. La marca quedó desincronizada al publicar sin
      marcar.

## Del juez (ACUERDO-ROTO, 2026-09-08)

Cuatro criterios CUMPLIDOS y dos NO CUMPLIDOS, los dos por la misma causa. El código
funciona —lo midió en `spm-pro`, `iOSandbox` y `AppStarter` reales—; lo roto era el acuerdo.

- [x] 12. **Mi requisito era un absoluto que el código no cumple.** Decía «los paquetes que
      PERTENECEN al repositorio» y «no anuncia NINGÚN paquete», y el acotado es por **prefijo**:
      un repositorio `sinada` recibe lo de `sinada-pro-555`. Reproducido por el juez. Al
      archivarse habría quedado como norma permanente falsa que nadie iba a volver a medir.

      **Es el mismo vicio que el juez anterior encontró en el cambio anterior** —el predicado
      del requisito más ancho que el del código— y me lo volvió a colar. El requisito dice
      ahora lo que el acotado hace, con el límite nombrado en su propia cláusula 4 y un
      escenario que lo fija.

      Y la vuelta de tuerca, que se queda escrita: el `Why` de este cambio usa `spm`/`spm-pro`
      como prueba del defecto que viene a cerrar, y ese par es exactamente por el que su
      arreglo se sigue colando, con los nombres al revés.

- [x] 13. **Tres comentarios caducados en el banco, que son código y no se archivan.**
      Nombraba dos funciones que **nunca existieron** —`derivados_ajenos` y
      `derivados_propios_de`, escritas al diseñar cuando la implementada es `monta_derivados`—;
      afirmaba que el `HOME` de prueba estaba vacío y que acotar la búsqueda era «harina de otro
      costal, el hook y no este script», las dos desmentidas por este mismo cambio; y decía que
      «el primer caso» sale en rojo cuando los rojos son el tercero, el cuarto y el quinto.

- [x] 14. **Dos errores de hecho en el proposal**, que sí se archiva: «arregló seis defectos»
      —el cambio anterior arregló once, y el «todos» estaba afirmado de los once, no del
      subconjunto de código—, y «con los mismos límites ya declarados», cuando el tercero no
      estaba declarado en ningún sitio hasta que lo encontró el revisor.

- [x] 15. **Su nota, aceptada:** `docs/PIEZAS.md` decía «una heurística con TRES límites …
      declarados los tres». Es un recuento a mano de piezas de otro fichero, y no lo caza nadie
      —`autocomprueba.sh` solo lintea recuentos de piezas del kit—. Fuera el número.

## Del juez, segunda ronda (DEVUELTO, 2026-09-08)

- [x] 16. **La regla volvió a llegar a un solo hermano, ahora en la capa del acuerdo.** Corregí
      cuatro instancias de la promesa de acotado —el requisito de `doc-de-paquetes`,
      `lib-kit.sh`, `README.md` y `docs/PIEZAS.md`— y se me escapó la quinta:
      `openspec/specs/contexto-inyectado/spec.md` cláusula 5, «NO SHALL recibir las de otro
      proyecto de la misma máquina». Reproducido: repo `spm` sin dependencias propias recibe
      `PaqueteDelVecino` desde `spm-pro-555444`.

      No es regresión —era falsa ya en la 1.8.0— pero **es de este cambio**: es el que hizo que
      las dos piezas compartan la MISMA función y el que declaró sus límites como canon.
      Archivar dejando la norma del hermano diciendo lo contrario sobre esa función es el
      defecto que este cambio persigue, cometido en el acuerdo. Se corrige aquí, con un
      `MODIFIED` que reparte la vieja cláusula 5 en 5 y 6.

- [x] 17. **Y por qué se coló, que es lo transferible.** Mi criterio estaba escrito en términos
      **léxicos** —«que ningún documento diga que falla hacia el lado seguro»— mientras lo que
      protege es **semántico**: que nadie prometa una garantía de acotado que el código no da.
      La spec del hermano no dice esa frase; dice algo más fuerte y más falso, y por el hueco
      pasó.

      Es exactamente la trampa que el prompt del juez ya tiene escrita para los censos —«si lo
      cuentas por cómo se LLAMA algo y el requisito habla de lo que SIGNIFICA, no cubren el
      mismo conjunto»— aplicada a una promesa en vez de a un número. El criterio está reescrito
      en términos de lo que se promete.

- [x] 18. **Tres recuentos a mano, quitados en vez de corregidos.** «Los seis casos» en un
      comentario del banco —ya eran siete cuando el juez los contó— y en su tarea gemela, y
      «los seis criterios» cuando el proposal tiene siete. El del banco es código y no se
      archiva nunca. La salida sigue siendo la de siempre: el banco cuenta los suyos, un
      comentario no.

## Del juez, tercera ronda (DEVUELTO, 2026-09-08)

- [x] 19. **La sexta instancia estaba DENTRO del arreglo de la quinta.** El escenario «Dos
      proyectos con dependencias distintas», que copié literal del requisito base, dice
      «ninguno recibe las del otro» — el mismo absoluto, con otras palabras, doce líneas debajo
      de la cláusula 6 que dice lo contrario. Medido: `spm` recibe `PaqueteDeSpm` **y**
      `PaqueteDeSpmPro`. Al archivarse habría afirmado y negado lo mismo en el mismo requisito.

      La ronda entera consistió en revisar ese requisito buscando exactamente esta clase, y se
      me coló dos escenarios más abajo. El escenario acota ahora su premisa.

- [x] 20. **Y el hermano otra vez, ahora entre bancos.** Desde que la resolución vive en
      `lib-kit.sh`, los dos bancos miden LA MISMA función — y solo uno la medía. Mutándola a
      `${proyecto}*`:

          doc-paquetes: 🔴 2 de 7        el hook: ✅ 25 casos

      El banco del hook imprimía «las dependencias son las de ESTE repositorio, no las de la
      máquina» y un caso con la frase **palabra por palabra** de la cláusula falsa que este
      cambio corrige, sin un fixture que midiera dónde acaba «este». Su vecino tenía un nombre
      sin relación con ningún repo del banco: medía lo fácil, igual que el otro banco antes de
      la tarea 9.

      Cerrado con el fixture `sin_deps_propiasextra-…` —sin guion, por lo mismo que en el otro
      banco— y la frase acotada. Ahora el mutante muere en los dos: 🔴 2 de 7 y 🔴 1 de 26.

- [x] 21. **Un censo dentro de la norma permanente.** «Se corrigieron CUATRO instancias … y
      esta QUINTA se escapó», escrito en un fichero que se funde con `openspec/specs/` y era
      falso al escribirse: faltaban el escenario de la tarea 19 y las cuatro líneas del banco
      del hermano. Fuera el número; lo que queda es el criterio, que es la forma que aguanta.

- [x] 22. **Y me pilló recontando lo que dije haber quitado.** La tarea 18 decía que los
      recuentos se quitaron, y en un comentario del banco había sustituido «los seis casos» por
      «ya eran siete». Fuera también ese.

## Del juez, cuarta ronda (DEVUELTO, 2026-09-08)

Cerró con una lista explícita de lo que **descartó** —README, PIEZAS, `kit-doc.md`, la spec base
y el `MODIFIED`—, que es la primera vez en cuatro rondas que la búsqueda se declara exhaustiva.

- [x] 23. **La séptima instancia, y esta vez entre los dos bancos hermanos.** La cabecera que
      ESTE cambio escribió en `verifica-doc-paquetes.sh` —«los paquetes anunciados son los de
      ESTE repositorio»— es la misma frase que la ronda 3 condenó en el banco del hook y que
      allí sí acoté. Encabeza justo los casos que miden el borde del acotado, y es falsa.
      Acotada. Y con ella dos mensajes de caso que decían «el vecino» habiendo dos vecinos
      montados: ahora dicen «de OTRO nombre», que es lo que se mide.

- [x] 24. **`kit.conf` describía el banco por lo que era.** «Su primer caso nace en rojo» —el
      mismo error que corregí dentro del banco y no en su hermano— y un «el resto fija…» que ya
      no describe lo que hay. Deja de enumerar: lo dice el banco al correrlo.

- [x] 25. **Y la que más pesa: la reescritura semántica llegó al criterio y no a la norma.**
      El `proposal.md` se archiva como historia; la cláusula 4 del delta se funde con
      `openspec/specs/` y **se queda**. La cláusula conservaba la prohibición **léxica** —«que
      ningún documento diga que falla hacia el lado seguro»—, o sea justo la forma que la tarea
      17 identificó como insuficiente, y que en tres rondas dejó pasar seis instancias, una de
      ellas dentro del arreglo de otra.

      La norma que sobrevive era la que ya se había demostrado que no funciona. Reescrita en
      términos de lo que se promete, con las seis instancias como la medición que lo justifica.

## Del juez, quinta ronda (DEVUELTO, 2026-09-08) — y el cambio de enfoque

Le pregunté si esto converge. Contestó que **no**, con el dato: de las nueve instancias de la
promesa, **cinco estaban en texto escrito o reescrito por el arreglo de la ronda anterior** —la
sexta dentro del arreglo de la quinta, la octava dentro del arreglo de la séptima—. Cazarlas de
una en una es un paseo aleatorio, no una búsqueda: cada arreglo vuelve a **reformular** la
garantía, y reformularla es lo que fabrica la instancia siguiente.

- [x] 26. **Las dos instancias vivas, cerradas.** `kit.conf` —escrita en la ronda anterior como
      arreglo del hallazgo 24, y palabra por palabra la promesa que la ronda 2 condenó— ahora
      **apunta** a `lib-kit.sh` en vez de parafrasear. Y «recibe los suyos, y **solo** los
      suyos» en el banco, que es acotado por identidad cuando el código acota por prefijo: su
      gemelo del otro banco se había acotado en la ronda 4 y este no. El mismo par de ficheros,
      la misma clase, otra vez.

- [x] 27. **El arreglo estructural, que es lo que de verdad cierra esto.** Cláusula 5 nueva:
      **la garantía se enuncia en UN solo sitio —donde vive la resolución— y los demás apuntan
      ahí en vez de parafrasearla.** Una sola declaración no puede desincronizarse consigo
      misma; nueve paráfrasis sí.

      Es la tesis de este cambio —extraer en vez de copiar— aplicada a la prosa, y llegó por el
      mismo camino que la del código: alguien midiendo, no un detector. No lo comprueba nadie,
      y eso queda escrito en la cláusula.

- [x] 28. **Y el borde de la norma, que el juez midió y sin el cual no termina nunca.** Se
      exceptúan los enunciados de propósito —«los paquetes de los que depende este proyecto»—:
      dicen para qué existe una pieza, no qué excluye. Sin esa excepción la cláusula cubriría
      toda frase del kit que hable de dependencias.

## Auditoría propia, antes de invocar a nadie (2026-09-08)

El owner preguntó por qué siempre hacen falta cinco o seis rondas, y si no puedo auditarme yo
antes. Se hizo, mecánicamente: un `grep` de toda frase del kit que prometa exclusión sobre
dependencias, clasificada por si lleva su límite al lado o no.

- [x] 29. **La cláusula 5 que yo mismo acababa de escribir la incumplían `README.md` y
      `docs/PIEZAS.md`.** Decía «apuntar **en vez de** parafrasear», y los dos documentos
      enuncian la garantía, nombran el límite Y apuntan a la lista — que es lo correcto, porque
      un documento de usuario que solo dijera «mira `lib-kit.sh`» no le sirve a nadie.

      O sea: una norma escrita para cortar esta deriva, estrenada convirtiendo en infractores a
      los dos documentos que mejor la cumplen. **La misma clase que las nueve instancias —un
      predicado más ancho que la realidad— cometida en la cláusula que venía a cerrarla**, y la
      sexta vez en este cambio.

      La cláusula prohíbe ahora lo que de verdad hace daño —**el absoluto suelto**, sin la
      premisa que lo hace cierto y sin decir dónde está la lista— y declara sus dos bordes: los
      enunciados de propósito, y que explicar no es parafrasear.

- [x] 30. **Y el resultado de la auditoría con la cláusula ya corregida: ninguna infracción.**
      Toda mención de la garantía en el kit lleva su límite al lado o apunta a `lib-kit.sh`.
      Esta es la primera vez en seis rondas que la búsqueda sale limpia, y la primera que la
      hace el autor y no el juez.
