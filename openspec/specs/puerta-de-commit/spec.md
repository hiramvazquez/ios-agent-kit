# puerta-de-commit Specification

## Purpose

Impedir que se commitee un árbol que nadie ha verificado. Sin esta puerta, «los tests pasan»
es una afirmación del modelo sobre un árbol que pudo cambiar después de correrlos: error de
proceso, no mala fe, y el más caro porque no deja rastro.

Es un hook `pre-commit` de git del repositorio del proyecto, que instala la verificación al
firmar. Lo que NO pretende: frenar a quien decide saltársela. `--no-verify` y un git que no
lea los hooks del repositorio siguen abiertos, y eso no se puede cerrar desde dentro de la
misma máquina.

## Requirements

### Requirement: La puerta es un hook de git del repositorio

La puerta de commit SHALL ser un hook `pre-commit` de git instalado en el repositorio del
proyecto, y SHALL decidir con la misma regla que la comprobación de firma: la firma tiene que
ser del árbol y del índice que se van a commitear, y de una verificación que salió verde.

1. Un `git commit` sin firma válida SHALL fallar antes de crear el commit, con un mensaje que
   diga qué hacer.
2. La decisión NO SHALL depender del directorio desde el que se invoca git, de la forma en que
   se escribe el comando ni de la herramienta que lo lanza: un `git -C`, un `cd` previo, un
   `bash -c` y una terminal ajena a Claude Code SHALL dar el mismo resultado.
3. Stagear en el propio commit —`-a` o un pathspec— después de firmar SHALL bloquear, porque
   cambia el índice firmado.
4. En un repositorio sin ningún commit todavía, SHALL comprobar la huella del índice, que es
   la única referencia que existe.
5. Sin `kit.conf` en la raíz del repositorio, el hook SHALL dejar pasar: ese repositorio ya no
   usa el kit, y un hook que sobrevive a desinstalarlo no puede convertirse en un muro.
6. Lo que la puerta no frena SHALL estar declarado en el propio hook y en la referencia de
   piezas: `--no-verify`, un git que no lea los hooks del repositorio, y los commits que git
   crea sin pasar por `pre-commit` (merge, revert, cherry-pick, rebase).

#### Scenario: Commit sin firma

- **WHEN** se intenta `git commit` en un repositorio con el kit y sin firma válida para su árbol
- **THEN** el commit no se crea
- **AND** el mensaje dice que hay que stagear, verificar y commitear en comandos separados

#### Scenario: Commit con firma válida

- **WHEN** el índice y el árbol son los que firmó una verificación verde
- **THEN** el commit pasa

#### Scenario: El commit stagea por su cuenta

- **WHEN** hay firma verde y se commitea con `-a` o con un pathspec tras modificar el árbol
- **THEN** el commit no se crea

#### Scenario: Desde otro directorio o con otra forma de invocación

- **WHEN** el commit se lanza con `git -C <repo>`, tras un `cd` a una ruta con `~`, dentro de
  un `bash -c`, o desde una terminal que no es la de Claude Code
- **THEN** el veredicto es el mismo que desde la raíz del repositorio

#### Scenario: El repositorio deja de usar el kit

- **WHEN** el repositorio tiene el hook instalado y ya no tiene `kit.conf`
- **THEN** el commit pasa

#### Scenario: El primer commit del repositorio

- **WHEN** el repositorio no tiene `HEAD` y hay firma verde de su índice
- **THEN** el commit pasa

### Requirement: La verificación instala la puerta

`verifica.sh` SHALL instalar o refrescar el hook `pre-commit` del repositorio cada vez que
firma, sin pisar un hook que no sea suyo.

1. Si no hay `pre-commit`, o el que hay lleva la marca del kit, SHALL escribirlo con la huella
   copiada de la única definición del kit, y hacerlo ejecutable.
2. Si hay un `pre-commit` sin la marca del kit, o `core.hooksPath` está configurado, NO SHALL
   modificar nada, y el informe SHALL decir qué fichero es y qué línea añadir.
3. SHALL instalarlo también cuando la verificación sale en rojo: la puerta tiene que existir
   para bloquear ese árbol.
4. La primera vez que lo instala en un repositorio, el informe SHALL decirlo; si no puede
   escribirlo, el informe SHALL decir que el repositorio queda sin puerta, y NO SHALL decir
   que la instaló.

#### Scenario: Primera verificación en un repositorio

- **WHEN** `verifica.sh` firma en un repositorio sin `pre-commit`
- **THEN** existe `.git/hooks/pre-commit`, ejecutable y con la marca del kit
- **AND** el informe dice que lo ha instalado

#### Scenario: Un hook ajeno

- **WHEN** el repositorio ya tiene un `pre-commit` sin la marca del kit
- **THEN** ese fichero queda byte a byte igual
- **AND** el informe nombra el fichero y la línea que hay que añadirle

#### Scenario: No se puede escribir el hook

- **WHEN** el directorio de hooks no admite escritura
- **THEN** el informe dice que el repositorio queda sin puerta
- **AND** no dice que la haya instalado

#### Scenario: Verificación en rojo

- **WHEN** algún paso de `kit.conf` falla
- **THEN** el hook se instala o refresca igual
- **AND** un `git commit` posterior se bloquea
