## ADDED Requirements

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
