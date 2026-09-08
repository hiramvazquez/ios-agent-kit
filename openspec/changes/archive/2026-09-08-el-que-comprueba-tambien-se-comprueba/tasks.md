# Tareas

- [x] 1. **Hacer apuntable `autocomprueba.sh`**: raíz opcional como argumento, y sin argumento
      la suya, como hoy. `kit.conf` no cambia.

- [x] 2. **`scripts/verifica-autocomprueba.sh`**, sobre `lib-banco.sh`: un árbol de kit falso
      por clase de fallo —JSON que no parsea, `plugin.json` con rutas redundantes, eventos
      fuera del objeto `hooks`, hook apuntando a un script que no existe, agente citando un
      fichero del kit sin `${CLAUDE_PLUGIN_ROOT}`, documento con un censo a mano, fichero sin
      frontmatter— y **un árbol sano que salga limpio**, que es el que impide que el banco
      pase por construcción. Alta en `verificaciones()`.

- [x] 3. **Declarar el alcance del lint de censos** donde vive: `openspec/` queda fuera, y por
      qué. La decisión está en el proposal; aquí va la versión corta.

- [x] 4. **`docs/INSTALACION.md`**: dónde se abre la sesión, qué depende de eso y qué se ve
      cuando está mal, con el «Unknown command» literal para que sea buscable.

- [x] 6. **De la revisión (RED, 2026-09-08).** El banco comprobaba que el detector **dijera**
      algo, nunca que **saliera rojo** — y `paso()` de `verifica.sh` solo mira el código de
      salida. El revisor lo tumbó con un mutante de una línea, `exit "$FALLOS"` → `exit 0`:
      el detector imprimía «❌ 3 problema(s): NO publiques», salía con 0, y el banco daba
      11/11. Un kit con los tres manifiestos rotos habría pasado la puerta de publicación con
      el banco en verde. Un banco que comprueba el mensaje y no el veredicto es peor que no
      tenerlo, porque tranquiliza.

      `falla_con` exige ahora las dos cosas. Comprobado contra los dos mutantes que el
      revisor usó: el `exit 0` universal tumba la mayoría de los casos y el más realista —una
      comprobación que deja de sumar a `FALLOS` al añadirla— tumba exactamente el suyo, con el
      diagnóstico escrito. Los números los imprime el banco al correrlo; aquí no se escriben,
      porque la ronda siguiente añadió casos y los que había puestos caducaron.

      Y su AMBER: el escenario «Sin argumento» estaba en el delta y no lo ejercía ningún caso,
      porque todos los demás pasan raíz explícita. Se invoca ahora desde `/`, que es donde
      se nota la diferencia entre resolver la raíz con `$PWD` y con la del propio script — en
      `verifica.sh` no se notaría, porque allí el cwd ya es la raíz.

      Los tres opcionales, cerrados: el fixture del censo tenía dos censos en una línea y
      podía pasar por el segundo; `json_roto` rompía `hooks.json` y tumbaba tres
      comprobaciones a la vez —ahora rompe `marketplace.json`, que solo lee una—; y
      `hook_sin_script` borraba el script en vez de cambiar el hook, rompiendo de paso la cita
      del comando.

- [x] 7. **De la segunda revisión (AMBER, 2026-09-08).** Corrió veinte mutantes contra el
      banco y encontró tres huecos, todos de la misma forma: **una comprobación que se
      ejercía por una sola de sus ramas o de sus rutas.**

      1. **La comprobación 3 tiene dos ramas** —eventos fuera del objeto, y no haber objeto
         `hooks`— y solo se cubría la primera. Con `sys.exit(1)` → `sys.exit(0)` en la
         segunda, el banco daba 12/12 mientras la puerta aprobaba un kit cuyos hooks no carga
         ninguno. Fixture nuevo.
      2. **El frontmatter se comprueba sobre tres globs y el fixture rompía uno.** Reducir el
         bucle a `agents/*.md` dejaba el banco verde y un comando sin frontmatter se
         publicaba. Ahora hay un caso por glob — un mutante que quita uno solo muere si el
         fichero roto está en ESE. Lo mismo con el lint de censos, que se ejercía solo por el
         README: se añade uno en `docs/`, y queda declarado por qué no se cubren sus cinco
         listas una a una.
      3. **El caso «sin argumento» mentía sobre el motivo.** Exigía verde, así que si el kit
         estaba roto por otra cosa decía «resolvió otra raíz», que es falso. Ahora compara la
         salida desde `/` con la de apuntarlo a su raíz: mide lo único que quiere medir, y
         sigue muriendo con el mutante `RAIZ="${1:-$PWD}"`.

      Y los tres opcionales: `censo_fechado` era el único caso que afirmaba un PASE sin
      comprobar el código de salida; el patrón de `cita_inexistente` era subcadena del mensaje
      de otra comprobación; y `cd ""` devuelve 0 en bash, así que un argumento vacío —que no
      cae al valor por defecto— habría comprobado el directorio actual en silencio. Guardado.

      Comprobado después, con un arnés de mutación propio: los cinco mutantes que importan
      —los cuatro que sobrevivían y el `exit 0` del RED— mueren ahora.

- [x] 8. **Del juez (DEVUELTO, 2026-09-08).** Un NO CUMPLIDO y tres afirmaciones falsas más,
      y el NO CUMPLIDO es de los que escuecen: **el recuento de casos escrito a mano, en
      cuatro sitios y caducado en tres** — en el cambio cuyo propio criterio dice «el recuento
      NO se escribirá a mano en ningún sitio». Dos de los cuatro estaban en este `tasks.md` y
      dos en el banco, que son justamente los dos puntos ciegos que este cambio acababa de
      declarar: los `.sh` y `openspec/`. Nadie los vigila. Sustituidos por formas que no
      cuentan.

      Las otras tres:

      1. **Una afirmación falsa sobre bash.** Escribí que `${1:-…}` «solo mira si está sin
         definir»; sustituye cuando está sin definir **o vacío**, y el juez lo midió corriendo
         `autocomprueba.sh ""`. La guarda que esa nota justificaba no se dispara nunca por esa
         vía — pero sí protege de otra: si la resolución por defecto falla, `RAIZ` queda vacía
         y `cd ""` devuelve 0. La guarda se queda; la nota dice ahora de qué protege.
      2. **El LÍMITE DECLARADO del par de censos tapaba un hueco real con un motivo falso.**
         Decía que los tres globs no cubiertos «comparten bucle con el frontmatter»: no, el
         frontmatter es el punto 6 y el censo la lista del punto 7. El juez lo demostró con un
         mutante que dejaba el banco verde y publicaba un censo en `agents/`. En vez de
         declarar mejor el límite, se cierra: un caso por sitio.
      3. **`README.md` decía que `autocomprueba.sh` sigue sin banco**, en la entrega que ES su
         banco, y en el fichero que el propio lint vigila.

      Y su medición sobre la decisión de no extender el lint a `openspec/`, que acepto entera:
      de los disparos sobre `openspec/**`, casi todos caen en el archivo —historia— y el único
      sobre un acuerdo vivo era **un acierto**, el recuento caducado de arriba. O sea que mi
      argumento «dispararía sobre prosa legítima» no sostiene la mitad viva. La decisión no
      cambia; la razón archivada sí, y ahora dice la que aguanta: el archivo no se lintea
      porque es historia, y el acuerdo vivo no se lintea porque ya tiene quien lo mire.

- [x] 5. **Cierre**: `/kit-verifica` en verde con el banco nuevo, y `/kit-revisa`.
