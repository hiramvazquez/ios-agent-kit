# Las rondas dejan rastro

## Why

El tope del juez, publicado ayer en la 1.9.0, se apoya en un registro que **nadie escribe**.

Su propio texto lo dice: «El contador no lo guardas tú: lo guarda `tasks.md`. Eres un
sub-agente y cada invocación empieza en blanco». Lo declaré como límite —«un autor que no anote
sus rondas desarma el tope sin querer»— dando por hecho que anotarlas era lo normal.

**No lo es, y ni siquiera era lo normal aquí.** De los nueve cambios archivados en este
repositorio, dos no anotan ninguna ronda: los dos del 2026-09-07. La costumbre empieza el 08 y
la tuve por comportamiento del sistema. Medido el 2026-09-09, en el primer uso del kit fuera
de su propia casa:

- `AppStarter`, cambio `descuento-visible-en-carrito`: el bucle corrió entero — **dos pasadas
  de revisor con ocho hallazgos** (cinco bugs reales de producto) y **una ronda de juez con
  veredicto ACEPTADO**.
- El acuerdo archivado no menciona ninguna:
  `grep -cE '^## Del |AMBER|ACEPTADO|ronda' tasks.md proposal.md` → **0 y 0**.

Y al buscar quién debería haberlo pedido, no lo pide nadie: ni `commands/kit-revisa.md`, ni
`commands/kit-acepta.md`, ni `agents/reviewer.md`, ni `agents/aceptacion.md`.

O sea que el tope no tiene de dónde contar, y el presupuesto de rondas que publicamos el mismo
día tampoco tiene contra qué compararse. Las dos piezas nuevas de ayer dependen de un dato que
el kit no produce.

### Lo que se pierde además del contador

El registro no es solo un número. En ese cambio de `AppStarter` se perdió, entre otras cosas,
que el revisor propuso un arreglo **equivocado** —`.toNearestOrEven` para una frontera de
céntimos— y que quien implementaba lo midió, encontró 1.192 desacuerdos en 180.000 pares y usó
otro predicado. Eso es exactamente lo que un cambio futuro necesita saber para no volver a
proponerlo, y hoy vive únicamente en un chat que se cierra.

## What Changes

- **`/kit-revisa` y `/kit-acepta` mandan anotar el resultado en el acuerdo**, tras cada
  invocación: qué ronda, qué veredicto, qué se encontró y —lo que el tope necesita— **si esa
  ronda movió el comportamiento**.
- **Lo escribe el orquestador, no los agentes.** Ver la decisión de abajo.
- El sitio es `tasks.md`; cuando un cambio no lo tenga —el flujo permite saltárselo—, el final
  del `proposal.md`. Los dos están en la «Entrada» del juez, así que los lee de todas formas.

### La decisión de diseño

**Los sub-agentes siguen siendo de solo lectura, y esto no los toca.** La alternativa evidente
—que el juez escriba su propio veredicto— rompe algo deliberado: su prompt termina diciendo
«no editas el proposal para que encaje con lo entregado, eso es exactamente el fraude que este
agente existe para impedir», y el del revisor dice «no ejecutas nada que cambie estado del
repo». Un juez con permiso de escritura en la carpeta que juzga es una superficie que no hace
falta abrir para resolver esto.

Lo escribe quien ya escribe: el que invoca. Es también quien sabe si la ronda le hizo tocar
código, que es el dato que el tope necesita y que el juez, desde dentro de su invocación, no
puede saber.

## Fuera de alcance

- **Los prompts de `agents/`.** No se tocan, por la decisión de arriba.
- **El tope y el presupuesto.** Ya están escritos; esto solo produce el dato del que dependen.
  Ni el disparador ni las filas de la tabla cambian.
- **Cualquier automatismo que cuente rondas o compruebe que se anotaron.** No existe y este
  cambio no lo inventa; ver el límite.
- **El formato exacto del bloque.** Se da una forma mínima y un ejemplo, no una plantilla
  rígida: lo que importa es que estén el veredicto, los hallazgos y si movió comportamiento.

## Límite declarado

**Nadie comprueba que se anote.** Es una instrucción más en un prompt, y este kit ya declara
que sus prompts no los verifica ningún detector: `autocomprueba.sh` mira frontmatter, rutas y
recuentos de piezas, y nada de esto entra en su alcance. Un orquestador que se salte la
anotación deja el tope exactamente como está hoy — que es el estado que este cambio viene a
mejorar, no a garantizar.

**Y hay un segundo canal que este cambio no cierra**, y conviene decirlo porque ya se midió: el
juez también puede enterarse de en qué ronda va porque quien lo invoca se lo diga en el
mensaje. Ese canal no es auditable ni queda escrito. La regla —si discrepan, manda el
acuerdo— ya está en `agents/aceptacion.md` desde la 1.9.0 y no se toca aquí.

## Criterios de aceptación

- [ ] `commands/kit-revisa.md` SHALL mandar anotar, tras cada invocación del revisor, el
      veredicto y los hallazgos, y SHALL mandar identificar el bloque como del revisor sin
      numerarlo como ronda. NO SHALL pedirle el dato del comportamiento: el revisor no tiene
      tope al que alimentarlo.
- [ ] `commands/kit-acepta.md` SHALL mandar lo mismo para el juez, y además qué pasó con el
      comportamiento **distinguiendo tres casos**: se movió; no se pidió moverlo; se pidió y no
      se hizo. SHALL decir que se escribe tras arreglar, no al volver.
- [ ] Los dos SHALL decir dónde: `tasks.md`, o el final del `proposal.md` cuando el cambio no
      lleve lista de tareas.
- [ ] Los dos SHALL decir que lo escribe **quien invoca**, no el sub-agente, y por qué —
      porque los prompts de `agents/` les prohíben escribir y eso no cambia.
- [ ] `agents/aceptacion.md` y `agents/reviewer.md` NO SHALL cambiar.
- [ ] La medición del 2026-09-09 sobre `AppStarter` SHALL quedar escrita junto a la
      instrucción, con el comando que la produce.
- [ ] `/kit-verifica` SHALL salir en verde y `autocomprueba.sh` limpio.
