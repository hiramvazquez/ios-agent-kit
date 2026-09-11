# El kit vuelve a ser ligero

## Why

**El kit ha crecido revisándose a sí mismo, y parte de lo que creció impide terminar en verde.**
La auditoría del 2026-09-11 —cuatro pasadas de solo lectura sobre scripts, reglas, flujo e
historia— midió que el kit pasó de 2.488 líneas en la 1.6.0 a 7.603 aquella mañana, y que de lo
que entró desde el 2026-09-08 casi nada salió de trabajar en un proyecto real: `AppStarter`, el
único que lo usa, no se ha tocado desde el 2026-09-09. El owner ya abandonó un workflow anterior
por este mismo patrón: reglas duras contra sí mismo, nunca verde, y cada vez más grande.

Lo que más pesa en eso no son las líneas: es que el tope del juez **no se ha disparado ni una vez**
desde que su tabla cuenta como comportamiento añadir un fixture a un banco, y que el flujo dice a
la vez «no se archiva con DEVUELTO» y «archivar con la deuda anotada».

Los pasos 1 y 2 de la dieta ya están hechos: el cambio de mutantes salió del árbol y el detector
de variables pegadas cabe en una línea (`167ada4`). Este cambio es el resto.

Medido con `git ls-files -- agents docs scripts skills commands hooks | xargs cat | wc -l`: 5.779
líneas el 2026-09-11, tras el paso 2.

## What Changes

Las cuatro decisiones de diseño las tomó el owner el 2026-09-11.

- **Se retira `scripts/pasada-pendiente.sh`**, con su banco y su paso de `kit.conf`. Sobre los
  ocho cambios archivados de `AppStarter` contesta «no se puede leer» en los ocho (medido el
  2026-09-11): allí nunca se han anotado rondas. La regla a la que servía se queda, sin script:
  si después de revisar cambias lo que el código hace, vuelves a pasar el revisor antes de marcar
  la rodaja o de archivar.
- **El tope del juez, en una regla**: dos rondas seguidas cuyos arreglos no cambian lo que el
  código hace → para y decide el owner. Se quedan las tres salidas, en una frase cada una, la de
  «si ninguna encaja, dilo y para», y la pregunta de si la búsqueda converge. Se van la tabla de
  filas —con la del fixture, que era la que impedía que saltara—, «en la duda, cuenta», la
  historia y el coste de usar la tercera salida.
- **Anotar deja de ser una obligación con formato.** Queda solo la ronda del juez, en una línea
  —veredicto y qué pasó con el comportamiento—, que es lo único que el tope necesita porque el
  juez empieza en blanco en cada invocación. Las pasadas del revisor se anotan si quien orquesta
  quiere, sin formato.
- **Con el presupuesto agotado, el owner puede archivar con un DEVUELTO que no sea del producto**,
  dejando la deuda escrita en el acuerdo. Con ACUERDO-ROTO sigue sin archivarse.
- **Los docs, sin contenido de mantenedor.** `docs/FLUJO.md` vuelve a sus pasos 0–8 con esa regla
  de repasar; «Cuántas rondas merece esto» se queda en la tabla y en qué hacer al agotarlas, sin
  cifras —siguen en `docs/PIEZAS.md`, fechadas—; y fuera lo que explicaba el script retirado y lo
  que repetía los comandos. `docs/PIEZAS.md` pierde la sección del script. `README.md` ordena el
  día a día como `docs/FLUJO.md`: verificar antes de revisar.
- **`autocomprueba.sh` sin el censo de piezas y sin banco.** Se van su comprobación 7 y
  `scripts/verifica-autocomprueba.sh` con su paso de `kit.conf`. Sigue cazando manifiestos rotos,
  invocaciones que no pasan por la raíz del plugin y frontmatter, que es lo que llegó a romper al
  instalar.

## Capabilities

### New Capabilities

Ninguna.

### Modified Capabilities

- `coste-del-juicio`: se quita el requisito del script de la pasada pendiente; los requisitos de
  repasar antes de marcar y antes de archivar dejan de depender de la tabla del tope y de las
  anotaciones; el del presupuesto deja las cifras en `docs/PIEZAS.md` y añade archivar con la
  deuda anotada.
- `juicio-de-aceptacion`: el tope pasa a una regla con sus tres salidas, sin tabla ni desempate;
  la anotación queda en la ronda del juez, en una línea.
- `autocomprobacion-del-kit`: se quitan el lint de censos y su declaración de alcance; apuntar la
  autocomprobación a un árbol deja de exigir un banco.

## Impact

- **Se borran:** `scripts/pasada-pendiente.sh`, `scripts/verifica-pasada-pendiente.sh`,
  `scripts/verifica-autocomprueba.sh`.
- **Se editan:** `agents/aceptacion.md` (sección del tope), `commands/kit-acepta.md`,
  `commands/kit-revisa.md`, `docs/FLUJO.md`, `docs/PIEZAS.md`, `README.md`, `kit.conf` (los pasos
  de los dos bancos retirados), `scripts/autocomprueba.sh` (comprobación 7), y el `Purpose` de
  `openspec/specs/autocomprobacion-del-kit/spec.md`, que nombra el censo.
- **Proyectos que usan el kit:** su `kit.conf` no cambia de contrato. Al actualizar reciben el
  prompt del juez y los dos comandos más cortos.
- **El juez de este cambio** cargará el prompt del plugin instalado, con las reglas viejas delante.
  Ya pasó una vez y está escrito en el propio prompt; se dice para leer su veredicto con eso.

## FUERA de alcance

- **Recortar comentarios** de `kit.conf`, `scripts/lib-kit.sh` y `scripts/inyecta-contexto.sh`.
  La auditoría los marcó por proporción de comentario, pero no están en la lista que se aprobó.
- **El resto de `agents/aceptacion.md`** —entrada, las tres cosas que se escapan, los números del
  acuerdo, salida— y `agents/reviewer.md`: cazaron defectos reales en `AppStarter`.
- **`rodaja.sh`, `verifica.sh`, la puerta de commit, el detector de duplicados, `doc-paquetes.sh` y
  la skill.** Se quedan como están.
- **Frases desfasadas que este recorte no toque** —«hoy hay un solo detector propio» en
  `README.md`, por ejemplo—. Se arreglan cuando alguien pase por ahí.
- **Publicar.** Versión y push son el paso 4.
- **`/kit-init` sin estrenar y el prefijo `spm` que se come los paquetes `spm-pro`.** Son lo
  siguiente, y cada uno en su cambio.

## Criterios de aceptación

- [ ] `scripts/pasada-pendiente.sh`, `scripts/verifica-pasada-pendiente.sh` y
      `scripts/verifica-autocomprueba.sh` NO SHALL existir, y NO SHALL citarse fuera del archivo,
      de este cambio y de las specs: `grep -rnE 'pasada-pendiente|verifica-autocomprueba'
      --exclude-dir=.git --exclude-dir=archive --exclude-dir=el-kit-vuelve-a-ser-ligero
      --exclude-dir=specs .` no devuelve nada.

> **Renegociado el 2026-09-11, durante la implementación.** Este criterio no excluía `specs`, y así
> no podía cumplirse antes de archivar: la spec canónica `coste-del-juicio` nombra
> `pasada-pendiente.sh` dentro de un requisito que la delta de este cambio reescribe sin esa
> mención, y la mención solo desaparece al archivar, que es después del juicio. No se pierde de
> vista: después de archivar se repite el mismo `grep` sin excluir `specs`. Lo decidió el owner.
- [ ] La sección del tope de `agents/aceptacion.md` SHALL decir la regla en una frase, con las tres
      salidas en una frase cada una, la de «ninguna encaja» y la pregunta de convergencia; y NO
      SHALL quedar en `agents/`, `commands/` ni `docs/` la tabla de filas, «en la duda», ni la
      exigencia de descartar las otras dos salidas antes de usar la tercera.
- [ ] `commands/kit-acepta.md` SHALL pedir anotar la ronda del juez en una línea —veredicto y
      comportamiento— y NO SHALL imponer formato a nada más; `commands/kit-revisa.md` NO SHALL
      obligar a anotar la pasada.
- [ ] `docs/FLUJO.md` SHALL decir que, con el presupuesto agotado y un DEVUELTO que no es del
      producto, el owner puede archivar dejando la deuda escrita; y ningún documento del kit SHALL
      decir lo contrario. Con ACUERDO-ROTO no se archiva.
- [ ] `docs/FLUJO.md` SHALL mantener la regla de repasar antes de marcar o de archivar cuando se
      cambió lo que el código hace, y NO SHALL llevar cifras de coste de rondas.
- [ ] `scripts/autocomprueba.sh` NO SHALL tener la comprobación del censo de piezas, y `kit.conf`
      NO SHALL correr ninguno de los dos bancos retirados.
- [ ] `README.md` SHALL ordenar el día a día como `docs/FLUJO.md`: verificar antes de revisar.
- [ ] `/kit-verifica` en verde y `autocomprueba.sh` limpio, con `LANG=` y con `LANG=en_US.UTF-8`.
- [ ] El kit SHALL pesar menos que al empezar este cambio, medido con el comando de «Why»: por
      debajo de las 5.779 líneas del 2026-09-11.

## Presupuesto

**Una pasada de revisor y una ronda de juez**, declarado antes de empezar. Si al agotarse el juez
devuelve el cambio solo por prosa, decide el owner — con la salida que este mismo cambio deja
escrita.
