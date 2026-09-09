# Lo que nadie ha visto no se marca

## Why

Los pasos 5 y 6 del bucle ganaron dos obligaciones y `docs/FLUJO.md`, que es el documento que
los describe paso a paso, **no menciona ninguna**.

**La primera existe y no está escrita ahí.** La 1.9.2 hizo que `/kit-revisa` y `/kit-acepta`
manden anotar la ronda en el acuerdo. `FLUJO.md` describe los dos pasos con detalle —hasta el
`rodaja.sh --revisada`— y no lo dice.

**La segunda no existe todavía, y debería.** Hoy `FLUJO.md` dice, sin condición:

> Con GREEN o AMBER se marca el punto (`rodaja.sh --revisada`); con RED no.

Marcar significa «desde aquí no se vuelve a revisar». Y hay un caso frecuente que esa frase
deja pasar: **el revisor encuentra algo, lo arreglas, y ese arreglo cambia código que nadie ha
visto.** Marcar ahí le da paso franco.

### El caso que lo mide

El 2026-09-09, en `AppStarter`, quien implementaba lo hizo por su cuenta y lo escribió:

> «La revisión fue AMBER, que se marcaría — pero he cambiado código después de ella. Marcar
> ahora le daría paso franco a lo que no ha visto nadie.»

Volvió a pasarlo. **La segunda pasada encontró más cosas**, y una bloqueaba: la
spec se contradecía consigo misma, y al archivar esa contradicción se habría fundido en la spec
canónica, donde quien la implementara habría reintroducido el bug que la primera pasada acababa
de cerrar.

O sea que la regla no es prudencia teórica: en su primer uso real cazó un defecto que iba
camino de quedarse para siempre. Y quien la aplicó no la encontró en el kit, porque no está.

### La misma regla que el kit ya usa dos veces

No es una idea nueva, es la que ya sostiene otras dos piezas: la puerta de commit existe porque
«los tests pasan» es una afirmación sobre un árbol que pudo cambiar **después** de correrlos, y
la firma de verificación se liga al `sha256` del diff por lo mismo. Marcar una rodaja tras
cambiar código es exactamente ese error, en un punto del bucle donde todavía se puede
cometer.

## What Changes

- **`/kit-revisa` gana la condición que le falta a «se marca el punto»**: si arreglar lo que el
  revisor encontró movió el comportamiento, ese código no lo ha visto nadie — se vuelve a pasar
  antes de marcar.
- **`docs/FLUJO.md` describe los pasos 5 y 6 como son hoy**: con la anotación de la ronda y con
  esa condición. Y su cierre del presupuesto deja de decir que no hay ningún rastro, porque
  desde la 1.9.2 sí lo hay — lo que sigue sin haber es quien lo cuente.

### La decisión de diseño

**El disparador es «movió el comportamiento», el mismo eje que el tope del juez**, y no «tocaste
algún fichero». Qué cuenta se lee de esa tabla y no se reenuncia aquí: corregir una descripción no obliga a
repetir la pasada, y reescribir lo que una norma manda, sí. Reutilizar ese eje tiene dos ventajas y una
consecuencia asumida:

- Ya está definido, medido y con su tabla en `agents/aceptacion.md`. Inventar un
  segundo criterio para lo mismo sería la clase de duplicación que este repo ya se ha cobrado
  tres veces esta semana.
- Quien decide es quien arregló, que es el único que lo sabe — igual que en la anotación.
- Y la consecuencia: **el eje se aplica leyendo, no lo comprueba nadie.** Ver el límite.

## Fuera de alcance

- **Un tope para el revisor.** No lo tiene y esto no se lo pone. Lo que acota las pasadas es el
  presupuesto que `FLUJO.md` ya publica; si se agota, decide el owner, igual que hoy.
- **El prompt de `agents/reviewer.md`.** La condición es de quien orquesta —es quien arregla y
  quien marca—, no del revisor, que ya tiene escrito que no marca él.
- **El prompt de `agents/aceptacion.md`.** El eje se toma prestado de su tabla; no se toca.
- **Automatizar la condición.** Nada comprueba si marcaste sobre código sin revisar; ver el
  límite.
- **La tabla de rondas presupuestadas.** Sus números no cambian: esta regla puede añadir una
  pasada, y la fila de código ya presupuesta 1–2 por eso.

## Límite declarado

**Nadie comprueba que se cumpla.** `rodaja.sh --revisada` marca cuando se lo pidan, sin
preguntar qué pasó antes; el script no sabe si hubo revisión, ni si arreglaste después. Es una
instrucción en un comando, y este kit ya declara que sus prompts no los verifica ningún
detector.

**Y hay un caso que la regla no cubre y conviene decirlo:** si arreglas, vuelves a pasar, y el
segundo arreglo vuelve a mover comportamiento, la regla pide una tercera pasada — y así. Lo que
acota eso no es esta regla sino el presupuesto de `FLUJO.md`, que se agota y entonces decide el
owner. No se inventa aquí un tope de revisor porque el bucle ya tiene un mecanismo para pararse
y dos relojes que puedan discrepar son peores que uno.

## Criterios de aceptación

- [ ] `commands/kit-revisa.md` SHALL decir que no se marca el punto cuando arreglar lo que el
      revisor encontró movió el comportamiento, y SHALL decir qué hacer entonces.
- [ ] SHALL remitir al eje ya definido —la tabla de `agents/aceptacion.md`— en vez de definir
      uno nuevo.
- [ ] `docs/FLUJO.md`, en su paso 5, SHALL describir esa condición junto al `rodaja.sh
      --revisada` que ya menciona.
- [ ] `docs/FLUJO.md`, en sus pasos 5 y 6, SHALL decir que la ronda se anota en el acuerdo.
- [ ] El cierre del presupuesto de `docs/FLUJO.md` NO SHALL seguir afirmando que no queda
      rastro de las rondas, y SHALL decir qué sigue sin haber: quien las cuente.
- [ ] El caso del 2026-09-09 SHALL quedar escrito junto a la regla, con lo que la segunda
      pasada encontró.
- [ ] `agents/reviewer.md` y `agents/aceptacion.md` NO SHALL cambiar.
- [ ] `/kit-verifica` SHALL salir en verde y `autocomprueba.sh` limpio.
