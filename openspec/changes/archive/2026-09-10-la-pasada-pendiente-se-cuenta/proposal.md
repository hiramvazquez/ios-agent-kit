# La pasada pendiente se cuenta

## Why

La regla que la 1.9.4 acaba de publicar —«no se archiva sobre el arreglo de un juicio que no ha
visto ningún revisor»— lleva, en cuenta del revisor que la cerró, **cuatro rondas** sin decidir
(`openspec/changes/archive/2026-09-09-no-se-archiva-a-ciegas/tasks.md`), y las cuatro fueron el mismo fallo a
distinta profundidad:

| ronda | qué le faltaba al predicado |
|---|---|
| juez, 1 | el cuantificador: miraba «la última ronda», y la última es siempre un ACEPTADO |
| juez, 2 | el ancla: no decía qué hacer con **cero** pasadas, que es el caso mayoritario |
| revisor, 1 | el campo: una ronda **sin** etiqueta se leía como «no» |
| revisor, 2 | el vocabulario del campo: la plantilla ofrecía un valor que significa lo contrario |

Preguntado a la cara si faltaba un quinto parche, el revisor contestó que no, con tres razones
y una conclusión que es la que abre este cambio:

> «Las cuatro puertas son casos en los que la respuesta correcta era **no se puede leer,
> pregunta** y el texto contestó **no falta**.»

### Por qué un detector, que en esta casa hay que justificar

La regla dice que un detector solo nace si su clase **ya falló dos veces** y **no hay forma más
barata de verlo**. Las dos condiciones se cumplen y están medidas:

- **Falló las cuatro veces que el revisor enumera**, documentadas arriba, todas en el mismo
  predicado.
- **La forma barata se intentó y falló por la misma razón.** Puse un `grep` en el comando para
  no fiarme de la memoria, y devuelve `0` sobre dos acuerdos archivados que **sí** tienen rondas
  —las anotaron como item numerado en vez de cabecera— y pierde «De la **segunda** revisión» en
  un tercero. En silencio, y hacia el lado que archiva.

Ese último punto es el argumento entero: **un instrumento que devuelve «cero» cuando la
respuesta es «no sé leer esto» es el mismo defecto de aquellas pasadas, ahora en shell.**

Y hay una razón estructural además de la de corrección, con un síntoma que se explica solo:
**nadie sabe en cuántos sitios está escrito.** El revisor contó cinco en su cierre y cuatro en su
item 23; medido hoy, fichero a fichero, son tres —`commands/kit-acepta.md`, `docs/FLUJO.md` y
`openspec/specs/coste-del-juicio/spec.md`—. Da igual cuál sea el bueno: cada arreglo es una
edición a varias manos y **la tasa de divergencia no baja** — se cazó más de una vez, incluida
una en la que el arreglo no llegó al
fichero principal. Un script no puede divergir consigo mismo.

## What Changes

- **`scripts/pasada-pendiente.sh`**, nuevo. Lee el acuerdo de un cambio, ordena sus bloques,
  lee la etiqueta de comportamiento, y responde **una de tres cosas**: falta una pasada, no
  falta, o **no se puede leer**.
- **Su banco**, con el corpus real: las variantes de cabecera y de item numerado que existen hoy
  en los acuerdos archivados, más los casos que ninguna existe todavía —registro vacío, etiqueta
  ausente, formato desconocido, bloques repartidos entre los dos ficheros—, que es la situación
  que el revisor describe: donde la respuesta correcta era «no se puede leer», el texto
  contestaba «no falta». Y un caso que fija el idioma de la máquina, porque el awk de macOS
  trata los corchetes por bytes y la primera versión daba dos veredictos según `LC_ALL`.
- **`kit.conf`** lo corre, como a los demás bancos.
- **`/kit-acepta` y `docs/FLUJO.md`** dejan de explicar el procedimiento y **apuntan al script**.
- **El requisito vigente «No se archiva sobre el arreglo de un juicio que no ha visto ningún
  revisor»** se modifica en el mismo sentido, porque si no el procedimiento sobrevive en la spec
  canónica y el cambio no consigue lo que dice: su cláusula 2 pasa a exigir que se invoque el
  script y a fijar lo único que el script no puede deducir —que los bloques van al final—. Y su
  «límite declarado» deja de decir «aquí no hay ningún script», que a partir de este cambio es
  falso; lo que sigue sin haber es una puerta.

### Las decisiones de diseño

**La tercera salida es el producto.** No es un detalle de robustez: es lo que aquellas rondas
no consiguieron escribir en prosa. Un `FALTA`/`NO FALTA` binario reproduce el defecto — obliga a
elegir un lado cuando la respuesta honesta es «no lo sé». Y hereda la forma que este repositorio
ya tiene decidida: `verifica.sh` reserva un código propio para «no pude mirar», por la misma
razón y con el mismo argumento escrito.

**No bloquea nada.** Informa, y decide quien archiva — igual que el detector de duplicados, que
avisa y no para. La política de `hooks/hooks.json` («tres hooks y ninguno más») no se toca: esto
es un script que alguien invoca, con el precedente de `rodaja.sh --revisada`.

**Y los prompts dejan de explicar el procedimiento.** Es la lección que este mismo repositorio
aprendió dos veces esta semana: no reenunciar, apuntar. El predicado pasa a vivir en un sitio, y
los enunciados que haya se reducen a una invocación.

## Fuera de alcance

- **Poner una puerta al archivado.** Sigue fuera, por la política de `hooks.json`, y este script
  no la acerca: no bloquea nada.
- **Los prompts de `agents/`.** El script lo invoca quien orquesta.
- **Normalizar el formato de los bloques.** El script lee lo que hay; no manda escribir de otra
  forma ni migra los acuerdos archivados.
- **El tope del juez y el presupuesto.** Consumen el mismo registro y no cambian.
- **Contar rondas para el tope.** Este script responde una sola pregunta —¿falta una pasada?—,
  no lleva el contador del tope. Son dos consumidores del mismo dato y conviene no fundirlos.

## Límite declarado

**Que alguien lo invoque no lo comprueba nadie.** Es un script, no una puerta: quien archive sin
correrlo archiva igual. Lo que cambia respecto a hoy no es que haya obligación, es que la
respuesta deja de depender de leer bien un párrafo largo.

**Y `NO SE PUEDE LEER` va a salir mucho al principio**, con razón: la etiqueta de comportamiento
llegó con la 1.9.2 y la mayoría de los acuerdos archivados no la tiene. Eso es correcto y es el
punto — antes esos mismos acuerdos se leían como «no falta».

## Criterios de aceptación

- [ ] `scripts/pasada-pendiente.sh` SHALL responder exactamente una de tres cosas, y SHALL
      distinguirlas también en su código de salida, con la misma forma que `verifica.sh`.
- [ ] SHALL reconocer las variantes de bloque que existen hoy en `openspec/changes/archive/`,
      tanto de cabecera como de item numerado, y el banco SHALL montarlas como casos.
- [ ] Un bloque **candidato** —su encabezado nombra al juez, al revisor o a una revisión— que
      no sepa clasificar SHALL producir «no se puede leer», nunca «no falta». Lo que no es
      candidato queda fuera de su alcance y SHALL declararse como límite, no prometerse: la
      señal de que algo pretendía ser una ronda es el vocabulario de su encabezado, y sin ella
      no se distingue una ronda en forma rara de una sección legítima que no lo es —
      `## Auditoría propia` lleva la etiqueta y no es una ronda, en dos acuerdos archivados.
- [ ] Una ronda de juez sin etiqueta de comportamiento SHALL producir «no se puede leer».
- [ ] Un acuerdo sin ningún bloque SHALL producir «no se puede leer».
- [ ] Con una ronda posterior a la última pasada que movió el comportamiento SHALL decir que
      falta; sin ninguna, que no falta.
- [ ] SHALL contar **alguna** ronda posterior, no solo la última, y su banco SHALL montar el
      caso con **dos** rondas detrás de la pasada. Con una sola no se distingue de mirar la
      última, que es el fallo original del predicado.
- [ ] SHALL existir un banco invocado desde `kit.conf`, y sus casos SHALL cubrir las cuatro
      puertas que la prosa no cerró — el cuantificador incluido, que es la primera y la que
      quedó sin caso hasta que la primera ronda de juez la echó en falta.
- [ ] `commands/kit-acepta.md` y `docs/FLUJO.md` SHALL apuntar al script en vez de explicar el
      procedimiento.
- [ ] El script NO SHALL bloquear nada ni añadirse a `hooks/hooks.json`.
- [ ] `/kit-verifica` SHALL salir en verde y `autocomprueba.sh` limpio.
