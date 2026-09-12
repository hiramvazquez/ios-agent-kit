# La firma cubre lo que se commitea

## Why

Tres fallos encontrados en la auditoría del 2026-09-11, los tres reproducidos:

- **La puerta deja pasar `git commit -am` con código sin verificar.** La huella se calcula sobre
  el índice (`git diff --cached`), así que si al firmar no había nada stageado, la firma es la del
  diff vacío y **sigue siendo válida** después de editar el árbol. Reproducido en un repositorio
  temporal: `git commit -am x`, `git commit -a -m x` y `git commit a.txt -m x` pasan los tres.
- **El «FUERA de alcance» no se inyecta si la cabecera va en mayúsculas.** El `sed` del hook
  distingue mayúsculas y 3 de las 16 propuestas del repo escriben `## FUERA de alcance`, entre
  ellas la activa. Se ve en el digest de cualquier sesión abierta sobre este repositorio.
- **El digest dice `tareas: 0/0 hechas` cuando el cambio no lleva `tasks.md`**, que es justo lo
  que `docs/FLUJO.md` recomienda para un cambio pequeño.

## What Changes

- **La huella pasa a cubrir el árbol de trabajo Y el índice.** El árbol porque es lo que
  `verificaciones()` compila y lo que commitea un `-a`; el índice porque es lo que commitea un
  `git commit` a secas. Sin commits todavía, solo el índice.

  *La primera versión de este cambio firmaba solo el árbol, y el revisor encontró que eso abría
  un agujero nuevo por el otro lado: stagear veneno y devolver el fichero a su contenido de
  `HEAD` dejaba la huella igual. Se arregla el código, y el criterio de abajo lo fija.*
- **La huella tiene una sola definición**, en `scripts/lib-kit.sh`. Hoy está escrita dos veces,
  en `verifica.sh` y en el hook.
- **El hook reconoce la cabecera del fuera de alcance en cualquier caja**, y solo cuenta tareas
  si hay `tasks.md`.
- **Los bancos fijan los tres**: `commit -am` en el de la puerta; la cabecera en mayúsculas y el
  cambio sin `tasks.md` en el del hook.

## Capabilities

### Modified Capabilities

- `verificacion-firmada`: una cláusula nueva sobre qué se firma. Su `Purpose` dice «diff staged»
  y se corrige en su sitio, como hace el cambio `la-doc-dice-lo-que-hay` con el suyo.
- `contexto-inyectado`: dos cláusulas nuevas en el requisito del digest.
- `puerta-de-commit`: sus escenarios dicen «diff staged»; se reescriben. El comportamiento de la
  puerta no cambia — delega en `verifica.sh --comprueba`.

## Impact

- **Se editan:** `scripts/lib-kit.sh`, `scripts/verifica.sh`, `scripts/inyecta-contexto.sh`,
  `scripts/verifica-puerta.sh`, `scripts/verifica-salidas.sh`, `scripts/verifica-contexto.sh`,
  `README.md`, `docs/PIEZAS.md`, `docs/FLUJO.md`, `docs/PRIMER-CAMBIO.md`,
  `docs/INSTALACION.md` y `commands/kit-verifica.md`.
- **Proyectos que ya usan el kit:** la fórmula de la huella cambia, así que la firma anterior deja
  de valer. Se arregla corriendo `/kit-verifica` otra vez.

## FUERA de alcance

- **Los puntos 2 y 3 de la auditoría** —ahorro de tokens y quitar líneas—. Son cambios aparte.
- **Quitar el aviso de árbol sucio.** Sigue siendo cierto: se puede commitear un subconjunto de
  lo verificado, y eso es lo único que lo dice.
- **Los límites declarados de la puerta** (`--no-verify`, otra terminal, invocación construida en
  tiempo de ejecución). Siguen abiertos y siguen escritos.
- **Publicar.** Versión y push, cuando se decida.

## Criterios de aceptación

- [ ] Con firma verde y un cambio posterior **sin stagear**, `git commit -am x` SHALL quedar
      bloqueado por la puerta. Fijado como caso en `scripts/verifica-puerta.sh`.
- [ ] Lo mismo con un pathspec: `git commit a.txt -m x` SHALL quedar bloqueado.
- [ ] Con firma verde, stagear contenido distinto y devolver el fichero a su contenido de `HEAD`
      SHALL invalidar la firma: el commit queda bloqueado aunque el árbol esté igual que antes.
      Fijado como caso en `scripts/verifica-puerta.sh`.
- [ ] En un repositorio **sin commits**, `verifica.sh` SHALL firmar y la puerta SHALL dejar pasar
      el primer commit; y stagear algo más SHALL invalidar esa firma —el caso que distingue el
      código bueno del que firma la huella del vacío—.
- [ ] La huella SHALL calcularse en un solo sitio: `scripts/verifica.sh` y
      `scripts/inyecta-contexto.sh` NO SHALL calcularla, SHALL pedírsela a `huella_diff`, y esa
      función SHALL estar definida únicamente en `scripts/lib-kit.sh`.

      *Este criterio se escribió dos veces midiendo una palabra, y las dos salieron falsas por
      motivos que no tienen que ver con la huella: «`shasum` solo en lib-kit.sh» choca con la
      clave del caché del hook, y «`diff HEAD` solo en lib-kit.sh» choca con `rodaja.sh`, que lo
      usa para el diff de la rodaja. Corregido por escrito el 2026-09-11 —las dos veces antes de
      darlo por cumplido— para que mida lo que importa: quién calcula la firma. Es el mismo
      hueco léxico-semántico que el prompt del juez tiene escrito como la trampa más fina de los
      censos, cometido en un criterio propio.*
- [ ] El digest SHALL incluir el bloque «FUERA de alcance» tanto con `## Fuera de alcance` como
      con `## FUERA de alcance`. Fijado en `scripts/verifica-contexto.sh`.
- [ ] Con un cambio activo **sin `tasks.md`**, el digest NO SHALL llevar la línea `tareas:`, y
      SHALL seguir llevando el bloque «FUERA de alcance».
- [ ] `README.md`, `docs/` y `commands/kit-verifica.md` NO SHALL decir que la firma es del «diff
      staged»: `grep -rn 'diff staged' README.md docs/ commands/` no devuelve nada.
- [ ] `/kit-verifica` en verde con `LANG=` y con `LANG=en_US.UTF-8`.

## Lo que queda sin revisar, dicho porque es una decisión y no un descuido

Dos pasadas de revisor, AMBER las dos, y sus cinco hallazgos están cerrados. La primera encontró
que firmar solo el árbol abría un agujero por el otro lado; la segunda, que pegar los dos diffs
sin separador dejaba migrar un hunk del árbol al índice sin mover la huella.

**Lo que no ha visto ningún revisor es el arreglo de la segunda**: el separador de `huella_diff`,
su caso de banco `kit_migra`, y tres correcciones de prosa. `coste-del-juicio` pide otra pasada
antes de marcar la rodaja cuando el arreglo cambia lo que el código hace, y aquí lo cambia. El
owner decidió el 2026-09-11 parar: la colisión está reproducida —las huellas con separador y sin
él, sobre los dos estados— y fijada por un caso que sale rojo si se quita el separador. El
presupuesto de este cambio era una pasada y se han pagado dos.

## Presupuesto

Cambio pequeño de alcance claro: sin `tasks.md`, **una pasada de revisor**, y juez solo si el
alcance se mueve al implementar.
