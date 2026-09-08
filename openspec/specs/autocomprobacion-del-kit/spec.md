# autocomprobacion-del-kit Specification

## Purpose

Comprobar, antes de publicar, lo que solo se ve al instalar. Los manifiestos del plugin
fallaron dos veces el mismo día sin que se viera leyéndolos: se vio cuando `claude plugin
list` dijo «failed to load».

Con el tiempo cubre también lo que el kit se exige a sí mismo y nadie más comprueba: que las
piezas que un comando o un agente manden ejecutar existan **y se citen por la raíz del
plugin**, y que ningún documento cuente a mano cuántas piezas trae el kit.

Lo que **no** pretende: cubrir todos los fallos posibles de carga, ni sustituir a instalar el
plugin de verdad. Cubre las clases que ya fallaron, que es la regla de la casa para que un
detector nazca.

## Requirements

### Requirement: Toda invocación de un fichero del kit pasa por la raíz del plugin

La autocomprobación SHALL fallar cuando un comando, un agente o una skill mande ejecutar un
fichero del kit por una ruta que no se resuelva desde la raíz del plugin.

1. SHALL cazar tanto la ruta inexistente como la ruta que **omite** la raíz del plugin.
2. SHALL salir en rojo contra el repositorio tal como está antes de este cambio.

La comprobación que hay hoy solo mira rutas que ya empiezan por la raíz del plugin: verifica
que lo citado exista, pero no ve lo que se cita mal. Por eso el kit lleva publicando en verde
un prompt con dos invocaciones muertas.

#### Scenario: Un agente cita un script por una ruta relativa al proyecto

- **WHEN** un fichero de `agents/` manda ejecutar `Scripts/verifica.sh`
- **THEN** la autocomprobación falla
- **AND** nombra el fichero y la ruta

### Requirement: Ningún documento afirma cuántas piezas trae el kit

La autocomprobación SHALL fallar cuando un documento del kit escriba a mano un recuento de
sus propias piezas.

1. Un recuento SHALL sustituirse por el comando que lo produce, o SHALL ir fechado como
   medición.

Esta clase ya falló dos veces: «once casos» escrito en dos sitios y «diez» en un tercero el
mismo día, y hoy un «5 skills» en el README donde hay siete piezas. Es la misma regla que el
juez de aceptación impone a cualquier criterio que cuente cosas — un censo caduca en el
momento de escribirse.

#### Scenario: El README dice cuántas skills trae el plugin

- **WHEN** un documento del kit contiene un recuento de piezas escrito a mano
- **THEN** la autocomprobación falla

### Requirement: La autocomprobación se puede apuntar a un árbol, y por eso se puede probar

`autocomprueba.sh` SHALL poder comprobar un árbol de kit distinto del suyo.

1. Con una raíz como argumento, SHALL comprobar ESA raíz.
2. Sin argumento, SHALL comprobar la suya, igual que antes de este cambio.
3. SHALL existir un banco que le pase árboles rotos —uno por cada clase de fallo que dice
   cazar— y un árbol sano que salga limpio.

La 3 no es una consecuencia de las otras dos: es la razón por la que existen. Este script es
la puerta de publicación del kit —dice «se puede publicar»— y era la única pieza con lógica
sin nadie que la mirase. Su punto ciego dejó pasar una invocación muerta en el prompt del juez
durante las diez versiones publicadas.

El árbol sano importa tanto como los rotos: sin él, un banco cuyos casos esperan rojo pasa
igual con un detector que devuelva rojo siempre.

#### Scenario: Un árbol de kit con un manifiesto roto

- **WHEN** se apunta la autocomprobación a un árbol cuyo `hooks.json` pone los eventos fuera
  del objeto `hooks`
- **THEN** falla, y nombra el fichero

#### Scenario: Un árbol de kit sano

- **WHEN** se apunta a un árbol correcto
- **THEN** sale limpio

#### Scenario: Sin argumento

- **WHEN** se invoca sin argumentos, como hace `kit.conf`
- **THEN** comprueba su propia raíz

### Requirement: El lint de censos declara qué NO mira

El lint que caza recuentos escritos a mano SHALL declarar su alcance donde vive.

1. SHALL decir que `openspec/` queda fuera, y por qué.
2. La razón SHALL ser la decisión, no el olvido: un patrón que cuenta dígitos pegados a un
   sustantivo no distingue el alcance de un cambio —enumerar lo que toca, que es legítimo— de
   un censo usado como justificación, que es la trampa.

Un límite que solo conoce quien lo escribió vuelve a proponerse cada seis meses. Este ya se
propuso una vez, y la respuesta —que la clase ha fallado una sola vez y que el control barato
existe: un juez leyendo— tiene que estar donde alguien vaya a buscarla.

#### Scenario: Alguien se pregunta por qué un acuerdo con un censo pasa el lint

- **WHEN** lee el punto del lint de censos en el script
- **THEN** encuentra escrito que `openspec/` queda fuera y la razón

### Requirement: «No pude mirar» y «hay problemas» salen con códigos distintos

`autocomprueba.sh` SHALL distinguir en su código de salida el caso en que no ha podido
comprobar nada del caso en que ha comprobado y hay problemas.

1. No poder resolver o alcanzar la raíz que se le pide SHALL salir con un código propio para
   «no pude mirar».
2. Que haya problemas SHALL salir con un código distinto de ese, **sea cual sea el número de
   problemas**.
3. El número de problemas SHALL seguir siendo legible en la salida del script.

Hoy sale con `exit "$FALLOS"`, y además sale con `1` cuando la raíz no existe: **un** problema
encontrado es indistinguible de «no existe la raíz». Es exactamente la colisión que
`verifica.sh` arregló, documentada en `verificacion-firmada` con su razón —«confundirlos hace
que un gate roto parezca un proyecto roto, y al revés»—, sin aplicar al hermano.

Y este hermano es la **puerta de publicación**: el script que dice «se puede publicar». Que
la regla llegara al que firma y no al que publica es el patrón que este cambio entero
persigue.

No tiene consecuencia viva hoy, y conviene decirlo en vez de inflarlo: su único invocador es
`kit.conf`, que solo mira cero contra no-cero. Se arregla porque el contrato es el que se lee
al depurar a mano, y porque la casa ya decidió cuál es la forma correcta.

#### Scenario: Un árbol de kit con varios defectos

- **WHEN** la autocomprobación corre sobre un árbol con más de un problema
- **THEN** el código de salida no es el de «no pude mirar»
- **AND** la salida dice cuántos problemas hay

#### Scenario: Una raíz que no existe

- **WHEN** se apunta la autocomprobación a un directorio que no existe
- **THEN** sale con el código de «no pude mirar»
