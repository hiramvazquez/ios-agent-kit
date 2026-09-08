# Tareas

Cinco bloques que no comparten fichero, a propósito: se pueden implementar en paralelo sin
pisarse. Entre paréntesis, quién los toca.

## A. El hook que inyecta el contexto

*(`scripts/inyecta-contexto.sh`, `scripts/verifica-contexto.sh`)*

- [x] 1. **El digest sobrevive al cambio terminado.** Arreglar el `$(grep -c … || echo 0)`
      que deja `"0\n0"` y aborta el compound en bash 3.2. Con cero tareas pendientes tienen
      que seguir saliendo la línea `tareas:` y el bloque «FUERA de alcance», y no puede
      escribirse nada en stderr. Dejar escrito en el script por qué `|| true` y `|| echo 0`
      no son lo mismo detrás de un `grep -c` — es el fallo, y `rodaja.sh` ya lo tiene bien.

- [x] 2. **Las dependencias son las de ESTE repositorio.** Acotar la búsqueda al repositorio
      observado en vez de a toda la máquina. Declarar en el script cómo se acota y qué se
      pierde con ello, que es lo que la casa pide de cualquier heurística.

- [x] 3. **El JSON declara el evento que lo invoca.** `SessionStart` cuando lo llama
      `SessionStart`, `UserPromptSubmit` en el resto. Declarar en el script el límite: que el
      efecto solo se ve compactando una sesión real.

- [x] 4. **Los tres, en el banco.** Un fixture con cero tareas pendientes; un caso que
      compruebe que un repositorio sin dependencias no recibe las del vecino aunque el
      `DerivedData` del `HOME` de prueba tenga paquetes; y los dos nombres de evento. El
      primero y el segundo tienen que salir **en rojo** contra la versión de hoy.

## B. La raíz del repositorio, y `/kit-doc`

*(`scripts/rodaja.sh`, `scripts/doc-paquetes.sh`, `scripts/verifica-doc-paquetes.sh`, `kit.conf`)*

- [x] 5. **Resucitar las dos guardas muertas.** `cd ""` devuelve 0, así que la comprobación
      tiene que mirar si la raíz se resolvió, no si se pudo entrar en ella. Con eso,
      `rodaja.sh` deja de crear `.agent-kit/` fuera de un repositorio.

- [x] 6. **Quitar el `-depth 1`** del `find` de `.build/checkouts` en `doc-paquetes.sh`, que
      lo hace insatisfacible, sin ensanchar el recorrido más de lo que ya estaba previsto.

- [x] 7. **Banco nuevo de `doc-paquetes.sh`**, con `lib-banco.sh` como los demás: un paquete
      en `.build/checkouts` sin `DerivedData` por medio, un repositorio sin nada resuelto, y
      la invocación fuera de un repositorio. El primero tiene que salir **en rojo** contra la
      versión de hoy. Añadir el paso a `kit.conf` con la nota de por qué existe.

## C. La puerta de publicación

*(`scripts/autocomprueba.sh`, `scripts/verifica-autocomprueba.sh`)*

- [x] 8. **Separar «no pude mirar» de «hay problemas»** en el código de salida, con la misma
      forma que `verifica.sh` y citando por qué se hereda de ahí. El recuento no se pierde:
      sigue en la salida.

- [x] 9. **El `bien` del frontmatter mira el contador acumulado**, así que un fallo anterior
      lo silencia aunque el frontmatter esté bien. Una línea. No gana delta: es cosmético.

- [x] 10. **Fijar los códigos en el banco**, incluida la raíz inexistente.

## D. El acuerdo del detector de duplicados

*(`scripts/busca-duplicados.py`)*

- [x] 11. **Declarar el suelo de 60 en el script**, con su razón, al lado del de 3 que ya la
      tiene. Sin mover ningún número: el delta de spec es el que renegocia el acuerdo, y este
      cambio no toca el comportamiento. Si el banco necesita un caso que fije el suelo de
      caracteres, va aquí.

## E. La prosa que afirma cosas falsas

*(`docs/PIEZAS.md`, `skills/swift-swiftui/SKILL.md`)*

- [x] 12. **`docs/PIEZAS.md`: la puerta.** Describe el reconocimiento por subcadena, que es
      lo anterior al arreglo y lo que `puerta-de-commit` cl.3 prohíbe. Sustituir por lo que
      hace hoy, sin prometer más de lo que cubre.

- [x] 13. **`docs/PIEZAS.md`: el hook.** «Inyecta tres cosas y ninguna más» son cuatro; falta
      la atribución del repositorio.

- [x] 14. **`skills/swift-swiftui/SKILL.md`: de qué proyecto habla.** «Esta app», «este repo»
      y «este proyecto» describen un proyecto que no es el que la lee — la skill viaja a los
      proyectos de los usuarios. Nombrar el proyecto medido y fechar la medición, o decir que
      el objetivo de despliegue lo pone cada proyecto.

## Cierre

- [x] 15. **`/kit-verifica` en verde** con todos los bancos, los que había y el nuevo, y
      `autocomprueba.sh` limpio. Revisión por rodajas y juez de aceptación antes de archivar.

## De la revisión (2026-09-08)

Los dos los encontré revisando el diff, no un banco, y los dos son de la misma clase que este
cambio persigue: una regla que la casa ya tenía escrita en un fichero y que no llegó al otro.

- [x] 16. **El hook arrancaba DOS intérpretes por turno.** El arreglo del `hookEventName`
      añadió un `python3` solo para leer el evento, además del que ya serializa la salida.
      `analiza-invocacion.py` lleva escrito en su cabecera por qué eso no se paga —«dos
      arranques de intérprete en CADA comando: +12,6 ms sobre 30 iteraciones»— y este hook
      corre en cada turno. Medido aquí: **20,9 ms por turno**, más caro que lo que aquella
      cabecera ya rechazó. Plegado en la llamada que ya existía: 108,8 → 87,2 ms, con el
      digest byte a byte idéntico y los 24 casos del banco intactos.

- [x] 17. **Y esa lectura de stdin colgaba el hook para siempre.** `[ -t 0 ]` solo reconoce el
      caso terminal: con un pipe ABIERTO que nunca cierra, esperar EOF es esperar
      indefinidamente, y este hook corre ANTES de cada turno. Reproducido con
      `bash inyecta-contexto.sh < <(sleep 300)`: ocho minutos vivo hasta matarlo a mano.
      **Lo encontró una medición de coste que se quedó parada, no una prueba** — la clase de
      hallazgo que solo aparece usando la pieza. Es además una regresión que NACE con la
      tarea 3: antes el hook no leía stdin y no podía colgarse. Acotado con
      `read -t 1 -d ''`, y fijado en el banco con un caso que mata al mutante del `cat` sin
      tope.

      El primer intento de escribir ese caso detectaba el cuelgue y **se colgaba él**, porque
      mataba el pid del hook y no el proceso que sujetaba el pipe. Rehecho con un grupo de
      procesos. Vale la pena decirlo: un caso que caza el fallo y deja el banco inservible es
      peor que no tenerlo.

- [x] 18. **Tres arreglos de coherencia míos, al revisar lo entregado.** El bit de ejecución
      del banco nuevo (ningún otro lo tiene — la premisa que le di al agente era falsa, y él
      la devolvió); el caso de `rodaja.sh` fuera de un repositorio, que ningún banco fijaba
      porque el fichero no era de quien lo arregló; y las etiquetas de `resumen` de tres
      bancos, que nombraban el cambio anterior — un puntero a algo que se había movido, que es
      justo lo que el juez caza como error de hecho.

- [x] 19. **`docs/PIEZAS.md`: la medición de coste del hook.** Era de hoy mismo y describía el
      recorrido sin acotar. Vuelta a medir y publicada **como rango**, porque el antes/después
      exacto salió contaminado: la primera corrida deja DerivedData caliente en la caché del
      sistema y la segunda mide eso. Se publica lo que se pudo medir sin trampa, y se dice por
      qué no hay un número único.

## Del revisor (AMBER, 2026-09-08)

Tres hallazgos, los tres reales y los tres locales a su tarea. Confirmó además, midiéndolo,
lo que este cambio afirma de las tres partes delicadas del hook y de los códigos de salida.

- [x] 20. **Quitar el `-depth 1` ensanchaba, y el comentario decía que no.** `-path
      "*/.build/checkouts/*"` casa también con lo de DENTRO de un checkout, así que cualquier
      `Package.swift` anidado salía como dependencia del proyecto. Medido con el layout real
      de `swift-syntax`: `CodeGeneration` y `SwiftParserCLI` anunciados como dependencias de
      quien consume el paquete. Acotado con `! -path ".../*/*"` —lo que la rama de DerivedData
      ya conseguía con su `-maxdepth 1 -mindepth 1`— y fijado con un fixture anidado, que es lo
      que le faltaba al banco. El comentario que afirmaba lo contrario, reescrito.

- [x] 21. **El censo del hook seguía mal: son CINCO, no cuatro.** Faltaba la línea de las
      dependencias. Se le escapó a la tarea 13 porque en un repositorio sin dependencias
      resueltas —como este— solo salen cuatro, así que quien cuenta aquí cuenta mal. Corregido
      en el script y en `docs/PIEZAS.md`, los dos diciendo ahora que la quinta es condicional,
      que es la razón por la que esta cuenta ya ha fallado dos veces. El lint de censos no lo
      habría cazado nunca: ignora a propósito los recuentos escritos con letra.

- [x] 22. **Mi caso del cuelgue era el único que no usaba el arnés.** Escribía en el caché REAL
      del usuario y, peor, pasaba en falso desde cualquier cwd sin repositorio git — porque el
      hook sale en `git rev-parse` antes de llegar a leer stdin. Un caso que protege contra
      colgar la sesión y pierde los dientes según desde dónde se le invoque no protege nada.
      Ahora corre dentro del repo de fixture, con el `HOME` y el caché del banco, como los
      otros; comprobado que sigue matando al mutante desde un cwd sin repositorio.

- [x] 23. **Su opcional, aceptado:** `"${DD_PROPIO[@]:-}"` pasaba a `find` un argumento de ruta
      vacío. BSD find lo tolera, pero el idiom correcto —`${arr[@]+"${arr[@]}"}`— ya estaba
      escrito en `doc-paquetes.sh`. Es otra vez la regla de la casa: mirar si ya existe antes
      de escribirlo.

      El otro opcional se deja como está: el caso «no deja nada escrito» de
      `verifica-doc-paquetes.sh` no puede fallar hoy, y vale como guarda de que siga sin poder.

- [x] 24. **Y una observación suya sobre el proceso, que hay que anotar sin excusa:**
      diecinueve tareas cerradas de una vez, en una rodaja de 1.354 líneas. Los tres hallazgos
      eran locales a su tarea y se habrían visto igual de bien en rodajas de cien. La
      paralelización en cuatro bloques compró tiempo y pagó el precio que este kit tiene
      medido: revisar tarde.

## Del juez (ACUERDO-ROTO, 2026-09-08)

Los quince criterios CUMPLIDOS con evidencia, y un NO VERIFICABLE. No es el código: son dos
frases, y las dos de la clase que este cambio persigue.

- [x] 25. **Mi requisito de `raiz-de-trabajo` decía «TODO script del kit», y era una trampa
      puesta a futuro.** Con ese ámbito, `inyecta-contexto.sh` y `puerta-commit.sh` quedan como
      infractores — y su silencio lo exigen otras dos specs: al hook se lo manda
      `contexto-inyectado`, y la puerta lleva escrito en su comentario que ahí falla ABIERTO a
      propósito. Al archivarse, esto queda como norma permanente, y el argumento del juez es
      el que hay que retener: la próxima auditoría de esta casa, cuyo método declarado es
      buscar la regla que llegó a un fichero y no a su hermano, habría encontrado exactamente
      esos dos hermanos y los habría «arreglado», rompiendo dos contratos. **El modo de fallo
      que este cambio existe para cerrar, plantado en el acuerdo que lo cierra.**

      Acotado a los scripts que invoca una persona, con la excepción de los hooks declarada y
      razonada, y con las cláusulas 2 y 3 aplicándoles igual — que es lo que de verdad
      cumplen. El criterio del `proposal.md` ya estaba bien acotado; el defecto era solo del
      delta.

- [x] 26. **La nota de duplicación de `kit.conf` volvió a caducar el mismo día, por este
      cambio.** Afirmaba «los dos deliberados» y el comando que ella misma publica devuelve
      ahora cuatro: la guarda de raíz de repositorio y una aserción de banco, las dos añadidas
      aquí y las dos a propósito. Lo cazó el juez corriendo ese comando. Es la cuarta vez que
      esta nota caduca, así que deja de enumerar: se corre el comando y lo que salga se juzga
      leyendo. La lección es la que la propia nota ya predicaba y no se aplicaba a sí misma.

- [x] 27. **Su observación sobre el suelo de 60, aceptada:** la nota citaba «un cuerpo de tres
      líneas con 36 caracteres normalizados» y el fixture del banco tiene 25. Las dos podían
      ser ciertas —son cuerpos distintos—, pero el 36 no se puede reproducir desde el repo.
      Ahora remite al fixture. Un número con fecha y sin fixture envejece igual que uno sin
      fecha.

- [x] 28. **Lo que NO se toca, y por qué.** `skills/swift-swiftui/SKILL.md:14` dice «los 88
      ficheros Swift del proyecto donde se probó esta skill»: el juez señala que queda una
      medición sin sujeto, y la tarea 14 ofrecía nombrar el proyecto. Se deja así a propósito
      —**no tengo evidencia de cuál era**, y ponerle un nombre a ojo cambiaría una medición sin
      sujeto por una afirmación falsa con sujeto, que es peor. El criterio está CUMPLIDO: ya
      no miente sobre el proyecto del lector, que era el defecto.

- [x] 15. **Cierre:** `/kit-verifica` en verde con los once pasos, revisor AMBER con sus tres
      hallazgos cerrados, y juez ACUERDO-ROTO con sus dos frases corregidas. Listo para una
      segunda vuelta del juez.

## Del juez, segunda ronda — tope alcanzado (2026-09-08)

Dos rondas seguidas sin mover una línea de código, así que el juez **no dio veredicto**: usó
la tercera salida —«el código y el acuerdo están bien; lo que queda son errores de hecho en el
texto»— y paró. Descartó las otras dos con la comprobación hecha, y trajo cada error con lo
que lo mide. Es la segunda vez que se usa esa salida desde que existe, y funcionó como está
escrita. El owner decidió corregir los cuatro y archivar.

- [x] 29. **Los cuatro errores de hecho, corregidos.** Los cuatro eran míos, del delta, y los
      cuatro se archivaban como norma permanente:

      1. «hoy `rodaja.sh` y `doc-paquetes.sh`» — son **tres**: `verifica.sh:20` también exige
         repositorio, lo invoca una persona por `/kit-verifica`, y ya cumplía las tres
         cláusulas. El inciso omitía al único de la clase que estaba bien desde antes.
      2. «Dos ficheros la aplican y dos no» — eran **tres**: `git show
         HEAD:scripts/inyecta-contexto.sh` ya traía la asignación correcta **y** el
         `[ -n "$RAIZ" ]`. Y se contradecía con la cláusula 4 dos párrafos más arriba, que
         cuenta a ese mismo hook como cumplidor. El requisito lo sumaba y lo restaba.
      3. El puntero a `contexto-inyectado` como razón del silencio del hook: esa spec exige
         **no crear ficheros**, no dice nada de salir en silencio ni con 0. El argumento bueno
         —romper el JSON que la herramienta espera— estaba en la misma frase y se sostiene
         solo, así que se queda él y se va el puntero.
      4. El «36 caracteres normalizados»: arreglé el comentario del script en la ronda
         anterior y dejé el delta, o sea que arreglé el artefacto que se relee y dejé el que se
         archiva. Ahora remite al fixture, que mide 25 y es reproducible.

      **Los dos censos se quitan, no se recuentan**, que es lo que el juez recomendaba y lo
      que la nota de `kit.conf` acaba de hacer en esta misma tanda: la norma se sostiene sin
      ellos, y poner el número correcto solo reinicia el reloj. Nadie más los habría cazado —
      `autocomprueba.sh` excluye `openspec/` a propósito, con el comentario de que el acuerdo
      vivo ya tiene quien lo mire: este juez.
