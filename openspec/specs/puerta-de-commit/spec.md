# puerta-de-commit Specification

## Purpose

Impedir que se commitee un árbol que nadie ha verificado. Sin esta puerta, «los tests pasan»
es una afirmación del modelo sobre un árbol que pudo cambiar después de correrlos: error de
proceso, no mala fe, y el más caro porque no deja rastro.

Vigila **el repositorio al que va el commit**, no el directorio desde el que corre la sesión
— el plugin se instala para el usuario, así que ambos se separan a menudo. Y solo vigila los
repositorios que usan el kit: donde no hay `kit.conf` no hay firma que se pueda producir, y
exigir una sería dejar el commit sin salida.

Lo que NO pretende, dicho porque un límite que no se declara se convierte en una promesa
falsa: frena el olvido, no a quien decide saltárselo. `--no-verify`, otra terminal y las
invocaciones construidas en tiempo de ejecución siguen abiertas, y eso no se puede cerrar
desde dentro de la misma máquina.

## Requirements

### Requirement: La puerta juzga el repo al que va el commit

El hook `PreToolUse` que vigila los commits SHALL decidir sobre el repositorio **al que va
el commit interceptado**, no sobre el directorio de trabajo que hereda de la sesión.

1. Cuando el comando indica el repositorio de destino —`-C <ruta>`, `--git-dir <ruta>`, o
   un `cd <ruta>` que precede al commit en la misma línea—, la puerta SHALL comprobar la
   firma de verificación **de ese** repositorio.
2. Cuando el comando no indica ninguno, la puerta SHALL comprobar la del repositorio del
   directorio heredado, que es el caso normal.
3. La puerta SHALL reconocer un commit por su invocación, no por la presencia de una
   subcadena en el texto del comando.
4. Cada salida que deje pasar el comando sin comprobar nada SHALL declarar por escrito, en
   el propio script, si falla abierto o cerrado y por qué.
5. Lo que la puerta exige es una firma válida **para el árbol** del repositorio de destino, no
   para su índice: la forma de stagear —`-a`, un pathspec, o el índice— NO SHALL cambiar el
   veredicto.

La 1 y la 3 no son la misma: un comando dirigido con `-C` falla hoy por las DOS razones a
la vez —no se reconoce como commit, y aunque se reconociera se miraría el repo equivocado—,
y arreglar solo una lo deja roto.

La 3 tiene una segunda cara que no es teórica: mientras el reconocimiento sea por
subcadena, cualquier comando que mencione las palabras queda bloqueado aunque no invoque
git. Escribir documentación sobre la puerta es el caso que lo destapó.

La 5 no cambia lo que hace la puerta —delega en `verifica.sh --comprueba`— sino lo que esta
norma promete. Decía «firma válida para su diff staged», y con esa lectura `git commit -am`
sobre un índice vacío cumplía la letra mientras metía código sin verificar. Qué se firma lo fija
`verificacion-firmada`.

#### Scenario: Commit dirigido a otro repo sin firma

- **WHEN** el comando dirige un commit con `-C` a un repositorio sin firma válida para su
  árbol
- **THEN** la puerta lo bloquea
- **AND** el motivo nombra el repositorio que ha comprobado

#### Scenario: Commit dirigido a otro repo con firma válida

- **WHEN** el comando dirige un commit con `-C` a un repositorio cuya firma es válida para
  su árbol
- **THEN** la puerta lo deja pasar

#### Scenario: Commit a secas en el repo de la sesión

- **WHEN** el comando es un commit sin indicar repositorio y el directorio heredado tiene
  firma válida
- **THEN** la puerta lo deja pasar
- **AND** si no la tiene, la bloquea — igual que antes de este cambio

#### Scenario: Un commit que stagea y commitea a la vez

- **WHEN** hay firma válida y después se modifica el árbol sin stagear
- **THEN** la puerta bloquea el commit aunque stagee él mismo con `-a` o con un pathspec

#### Scenario: Un comando que solo menciona las palabras

- **WHEN** el comando escribe, imprime o busca el texto «git commit» sin invocar git
- **THEN** la puerta no lo bloquea

### Requirement: La puerta solo vigila los repositorios que usan el kit

El plugin se instala para el usuario, no para un proyecto, así que sus hooks corren en toda
sesión. La puerta SHALL exigir firma únicamente donde esa firma se pueda producir.

1. La señal de que un repositorio usa el kit SHALL ser `kit.conf` en su raíz.
2. En un repositorio sin esa señal, la puerta NO SHALL exigir firma ni bloquear el commit.
3. En un repositorio con esa señal, la puerta SHALL comportarse como siempre: pasa con
   firma válida, bloquea sin ella.

La 2 no afloja nada: hoy, en un repositorio sin `kit.conf`, la puerta bloquea el commit
—porque no hay firma— y `verifica.sh` no puede crearla —porque aborta por falta de
`kit.conf`—. El commit queda bloqueado sin salida desde dentro del kit, y lo que se pierde
no es rigor, es la capacidad de commitear en repositorios que nunca pidieron el kit.

`openspec/` no vale como señal: un repositorio puede usar OpenSpec sin usar este kit, y la
firma que la puerta vigila no depende de OpenSpec.

#### Scenario: Un repositorio que no usa el kit

- **WHEN** se commitea en un repositorio sin `kit.conf`
- **THEN** la puerta deja pasar el commit
- **AND** no exige ninguna verificación

#### Scenario: Un repositorio del kit sin firma

- **WHEN** se commitea en un repositorio con `kit.conf` y sin firma válida para su diff
- **THEN** la puerta lo bloquea, igual que antes de este cambio

#### Scenario: Un límite que se estrecha

- **WHEN** una forma de invocación deja de colarse por la puerta
- **THEN** la cabecera del script deja de declararla como límite
- **AND** toda forma que siga colándose queda declarada en su lugar
