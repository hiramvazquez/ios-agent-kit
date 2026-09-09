# El tope mide comportamiento, no ficheros

## Why

El tope del juez existe para cortar un bucle concreto, y lo dice él mismo: «un juez riguroso y
un autor complaciente iteran indefinidamente sobre la redacción mientras el código lleva rondas
correcto, y eso no es rigor, es ceremonia con veredicto».

El 2026-09-08, juzgando `el-hermano-que-quedaba`, ocurrió exactamente eso durante **seis
rondas** y el tope no se disparó ni una vez. El contador se quedó en cero.

### Por qué no se disparó

La cláusula 6 del requisito dice: «Cuando lo encontrado en la ronda haga **tocar código**, el
tope NO SHALL aplicar». El juez leyó «tocar código» como «editar un fichero de código», y tenía
razones para hacerlo: lo que encontró vivía en `.sh` y en `kit.conf`, ficheros que **se quedan
en el repositorio para siempre** y no se archivan con el proposal. Un comentario caducado ahí
es un defecto real —este mismo kit tiene documentado uno que pasó diez versiones publicadas—,
así que «los comentarios no cuentan» habría sido igual de falso.

Pero lo que se movió en las dos primeras rondas fue **lo que el kit dice, no lo que hace**: mensajes de casos de banco, comentarios, notas de `kit.conf`, cláusulas de specs. El
producto llevaba correcto y verificado en tres repositorios reales desde antes de la primera
ronda.

O sea: el eje estaba mal elegido. «Hallazgo de código» se leyó como **en qué fichero vive** la
línea, cuando la pregunta que el tope necesita responder es **si la ronda cambió lo que alguna
pieza HACE**.

### La medición

Las seis rondas, clasificadas por el eje nuevo:

| ronda | qué encontró | ¿cambió comportamiento? |
|---|---|---|
| 1 | ámbito de un requisito, tres comentarios caducados, dos errores del proposal | no |
| 2 | la cláusula falsa de la spec hermana, tres recuentos | no |
| 3 | **al banco del hook le faltaba el fixture que mide la función compartida** | **sí** |
| 4 | cabeceras y mensajes de banco, nota de `kit.conf`, **y ensanchar lo que una norma prohíbe** | sí |
| 5 | una paráfrasis en `kit.conf`, un mensaje de caso, **y una cláusula normativa escrita de cero** | sí |
| propia | la cláusula recién escrita convertía en infractores al README y a PIEZAS | sí |

Con el eje nuevo el tope habría saltado **al final de la ronda 2**, que es lo que importa: para
que salte solo hace falta que la 1 y la 2 sean «no», y lo son. Con el viejo no saltó nunca.

Las tres últimas filas dicen «sí» por la fila de los prompts y las normas, y esa clasificación
la trajo el juez de este mismo cambio: la primera versión de esta tabla las daba por «no»
—metiendo «cláusulas de spec» en el saco de lo que el kit dice— y era falsa contra la regla que
la propia tabla justifica.

Y un dato que el propio juez midió en la ronda 5, y que es lo más transferible de todo esto:
de las nueve frases defectuosas que se corrigieron, **cinco estaban en texto escrito por el
arreglo de la ronda anterior** — dos de ellas dentro del parche de la instancia previa. No se
estaba vaciando un conjunto fijo de prosa vieja: cada arreglo volvía a **reformular** la
garantía, y reformularla era lo que fabricaba la instancia siguiente. Un paseo aleatorio, no
una búsqueda.

Ese diagnóstico apareció porque el owner preguntó si aquello convergía. No lo pide el prompt, y
fue el hallazgo más valioso de las seis rondas.

## What Changes

- **El disparador se mide por comportamiento.** Una ronda cuenta como «sin hallazgos» cuando
  ninguno de sus arreglos cambia lo que una pieza HACE — viva la línea en un `.md`, en un
  `.sh` o en `kit.conf`.
- **Se dan los ejemplos que separan las mitades dentro de un mismo fichero**, porque es donde
  la regla vieja se rompió: cambiar lo que un caso de banco **comprueba** es comportamiento;
  cambiar lo que **imprime**, no. Y la pareja que hacía falta en un kit hecho de prompts:
  cambiar lo que un prompt o una norma **mandan hacer** cuenta; corregir una cláusula que
  **describía mal** lo que ya se hacía, no.
- **Se declara qué hacer en la duda:** contar como comportamiento. El error caro de este tope
  es dispararse pronto.
- **El juez gana la obligación de decir si la búsqueda converge** cuando dos rondas devuelven
  la misma clase de hallazgo, con la medición que lo sostiene — incluida la pregunta que la
  destapó: cuántas instancias nuevas las escribió el arreglo de la ronda anterior.

### La decisión de diseño, y la objeción que trae

**El tope se disparará antes, y eso significa parar rondas que todavía habrían encontrado
cosas.** En la medición de arriba, la ronda 3 encontró un defecto real —un banco que no medía
la función que decía medir— y con la regla nueva el tope habría saltado antes de llegar ahí.

Se acepta, por lo que el tope ES: no archiva el cambio ni cierra el juicio. **Para y le pasa
la decisión al owner**, que puede pagar otra ronda con la información delante. Lo que la regla
nueva cambia no es cuánto se puede encontrar, es **quién decide si merece la pena seguir
buscando** — y esa decisión, tras dos rondas sin mover el producto, es del owner y no del juez.

La alternativa —dejarlo como está— ya se midió: seis rondas, cero disparos, y el owner
enterándose al final.

## Fuera de alcance

- **El número del disparador.** Dos rondas se queda. Lo que falló fue la clasificación, no el
  umbral, y subirlo o bajarlo sin medirlo sería repetir el error que la versión anterior de
  esta regla ya cometió contando vueltas.
- **Las tres salidas y la regla de «si ninguna encaja».** Funcionaron: la tercera se usó dos
  veces y bien, y la cuarta vía no hizo falta. No se tocan.
- **El resto del prompt del juez.** Sus preguntas, sus tres veredictos y la sección de los
  números del acuerdo no cambian.
- **El prompt del reviewer.** No tiene tope y este cambio no se lo pone.
- **Cualquier mecanismo que compruebe que un juez obedece el tope.** No existe; ver el límite.

## Límite declarado

**Que un juez cuente bien sus rondas no lo comprueba nadie**, y con esta regla menos: la
distinción entre «lo que hace» y «lo que dice» la aplica él leyendo, no un script. `autocomprueba.sh`
mira frontmatter, rutas y recuentos de piezas del kit; nada de esto entra en su alcance, y
extenderlo sería escribir un detector para una clase que ha fallado una vez.

Lo segundo: **el contador no lo lleva el juez, lo lleva `tasks.md`**. Es un sub-agente y cada
invocación empieza en blanco, así que la memoria duradera de cuántas rondas van es lo que el
autor haya anotado ahí — y su «Entrada» ya le manda leerlo. Hay un segundo canal, que quien lo
invoca se lo diga en el mensaje, pero no es auditable ni queda escrito. Funciona, y está medido: el tope se
alcanzó y se declaró entre dos invocaciones distintas usando esas cabeceras. Lo que no está
cubierto es el otro lado: **un autor que no anote sus rondas desarma el tope sin querer**, y
eso no lo comprueba nadie.

Y lo tercero: este cambio se juzgará con el prompt del plugin **instalado**, que es el viejo.
El juez que lo mire no tendrá delante la regla que está juzgando.

## Criterios de aceptación

- [ ] La sección «Tope» de `agents/aceptacion.md` SHALL definir la ronda que cuenta por si sus
      arreglos cambian el **comportamiento** de alguna pieza, y NO por el fichero en el que
      viven.
- [ ] SHALL dar los ejemplos que separan las mitades dentro de un mismo fichero: lo que un caso
      de banco comprueba frente a lo que imprime, y lo que un prompt o una norma MANDAN hacer
      frente a una cláusula que describía mal lo que ya se hacía.
- [ ] SHALL decir qué hacer cuando el caso no encaje claramente: contar como comportamiento.
- [ ] SHALL decir explícitamente que un comentario, un mensaje de prueba o un ejemplo **no**
      cuentan como cambio de comportamiento, y que eso NO los convierte en irrelevantes. Una
      cláusula de spec cuenta o no según MANDE algo nuevo o describa lo que ya se hacía.
- [ ] SHALL obligar al juez a decir si la búsqueda converge cuando dos rondas devuelven la
      misma clase, y a mirar cuántas instancias nuevas las escribió el arreglo anterior.
- [ ] El caso del 2026-09-08 SHALL quedar escrito junto a la regla, con su medición.
- [ ] El disparador SHALL seguir siendo dos rondas, sin cambios.
- [ ] Los tres límites declarados —nadie comprueba que el juez cuente así, el contador vive en
      `tasks.md` y un autor que no anote sus rondas desarma el tope, y este cambio se juzga con
      el prompt anterior— SHALL estar escritos en el propio fichero, y SHALL ser ciertos.
- [ ] `git diff agents/aceptacion.md` NO SHALL tocar ninguna sección que no sea «Tope».
- [ ] `/kit-verifica` SHALL seguir en verde y `autocomprueba.sh` limpio.
