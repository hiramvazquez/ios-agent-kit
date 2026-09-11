# Tareas

Casi todo es quitar. Primero se quitan las citas y después los ficheros citados: al revés,
`autocomprueba.sh` —que exige que todo script citado por un comando exista— saldría en rojo a
mitad del cambio.

## 1. Retirar la pasada pendiente

- [x] 1.1 En `commands/kit-acepta.md`, la sección «Antes de archivar» queda en pocas líneas y sin
      script: si arreglar lo que el juez señaló cambió lo que hace el código que se entrega,
      `/kit-revisa` antes de archivar. Se verifica con `grep -n 'pasada-pendiente'
      commands/kit-acepta.md` vacío.
- [x] 1.2 Quitar de `docs/PIEZAS.md` la sección de `pasada-pendiente.sh`, y de `docs/FLUJO.md` §7 el
      párrafo que la explica. Se verifica con `grep -n 'pasada-pendiente' docs/` vacío.
- [x] 1.3 Borrar `scripts/pasada-pendiente.sh` y `scripts/verifica-pasada-pendiente.sh`, y su paso
      con su comentario en `kit.conf`. Se verifica con `ls` y con `grep -n 'pasada' kit.conf` vacío.

## 2. El tope del juez, en una regla

- [x] 2.1 Reescribir la sección «Tope» de `agents/aceptacion.md` según la spec: la regla en una
      frase —cuenta lo que hace el código que se entrega; pruebas y prosa no—, el desacuerdo
      abierto, las tres salidas en una frase cada una, «si ninguna encaja, dilo y para», la pregunta
      de convergencia, y que el contador es la línea de cada ronda en el acuerdo. Fuera la tabla,
      «en la duda», la historia, el coste de usar la tercera salida y el límite que describe el lint
      de censos. Se verifica con `grep -nE 'fixture o una aserción|en la duda|MANDAN hacer|descartado
      las otras dos' agents/ commands/ docs/` vacío.

## 3. Anotar solo la ronda del juez

- [x] 3.1 En `commands/kit-acepta.md`, «Anota la ronda» queda en quién la escribe y una línea de
      ejemplo —ronda, veredicto, y comportamiento: sí, no, o se pidió y no se hizo—. Se verifica
      leyendo el comando: no impone formato a nada más.
- [x] 3.2 En `commands/kit-revisa.md`, anotar la pasada deja de ser obligación, y la regla de no
      marcar tras cambiar lo que hace el código queda en pocas líneas, remitiendo al tope sin
      repetirlo. Se verifica con `grep -nE 'en la duda|pasada-pendiente|Anota la pasada'
      commands/kit-revisa.md` vacío.

## 4. Los documentos

- [x] 4.1 `docs/FLUJO.md` §5 y §6: la condición de marcar y la línea de la ronda, sin repetir lo que
      dicen los comandos. §7: con ACUERDO-ROTO o con un DEVUELTO del producto no se archiva; con el
      presupuesto agotado y un DEVUELTO que no es del producto, decide el owner y la deuda queda
      escrita. Se verifica leyendo §5–§7 contra la spec `coste-del-juicio`.
- [x] 4.2 `docs/FLUJO.md`, «Cuántas rondas merece esto»: quedan la tabla y «Qué hacer cuando se
      agote», sin las cifras ni su discusión, que siguen en `docs/PIEZAS.md`. Se verifica con
      `grep -nE 'tokens|[0-9],[0-9]k|%' docs/FLUJO.md` sin cifras de coste de rondas, y con el enlace
      de `docs/PIEZAS.md` a esa sección todavía resolviendo a un encabezado que existe.
- [x] 4.3 `README.md`: el día a día en el orden de `docs/FLUJO.md` —`/kit-verifica` antes que
      `/kit-revisa`—, y la fila de `scripts/` de «Qué trae el plugin» sin decir que toda pieza con
      lógica tiene banco, porque `autocomprueba.sh` se queda sin el suyo. Se verifica leyendo las
      dos partes.

## 5. La autocomprobación, sin censo ni banco

- [x] 5.1 Quitar la comprobación 7 de `scripts/autocomprueba.sh`. Se verifica con `bash
      scripts/autocomprueba.sh` diciendo «kit sano» con `LANG=` y con `LANG=en_US.UTF-8`.
- [x] 5.2 Borrar `scripts/verifica-autocomprueba.sh` y su paso con su comentario en `kit.conf`. Se
      verifica con `ls` y con `grep -n 'verifica-autocomprueba' kit.conf` vacío.
- [x] 5.3 Quitar del `Purpose` de `openspec/specs/autocomprobacion-del-kit/spec.md` la frase sobre
      contar piezas a mano, que ya no describe lo que hace. Se verifica leyéndolo.

## 6. Cierre

- [x] 6.1 `/kit-verifica` en verde y firmada con `LANG=` y con `LANG=en_US.UTF-8`, y
      `openspec validate el-kit-vuelve-a-ser-ligero --strict` en verde.
- [x] 6.2 Los criterios medibles del proposal, corriéndolos: el `grep` de `pasada-pendiente` y
      `verifica-autocomprueba` vacío fuera del archivo, de este cambio y de las specs, y el peso del
      kit por debajo de 5.779 líneas con el comando de «Why». *(Decía «fuera del archivo y de este
      cambio»; renegociado el 2026-09-11, ver la nota del primer criterio. Después de archivar se
      repite el `grep` sin excluir `specs`.)*
- [x] 6.3 Una pasada de revisor sobre la rodaja entera y una ronda de juez, que es el presupuesto;
      la ronda se anota en una línea. Una sola pasada al final y no una por tarea, a propósito: son
      recortes pequeños y el presupuesto es uno.

**Pasada del revisor (AMBER, 2026-09-11).** Arreglado lo que rompía: la plantilla de `/kit-init` y
`docs/PRIMER-CAMBIO.md` prohibían archivar con cualquier DEVUELTO, y `autocomprueba.sh` remitía a un
punto 7 que ya no existe. Arreglado también un límite que, leído al revés, desarmaba el tope: «añadir
pruebas no cuenta» se podía entender como que esa ronda no suma; ahora dice que suma, en el prompt y
en la delta, sin cambiar lo que la delta exige. Anotados sin arreglo: `docs/FLUJO.md` §6 no dice
dónde va la línea si el cambio no lleva `tasks.md` —`/kit-acepta` sí—, y el prompt del juez ya no
dice que las notas del revisor en acuerdos viejos no son rondas.

- Ronda 1 del juez: ACEPTADO · comportamiento: no

Anotado sin arreglo, solo prosa: el «Impact» del proposal no nombra `plantillas/openspec-config.yaml.ejemplo`
ni `docs/PRIMER-CAMBIO.md`, que se tocaron porque contradecían el cuarto criterio.
