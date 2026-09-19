## MODIFIED Requirements

### Requirement: La puerta es un hook de git del repositorio

La puerta de commit SHALL ser un hook `pre-commit` de git instalado en el repositorio del
proyecto, y SHALL decidir con la misma regla que la comprobación de firma: la firma tiene que
ser del árbol y del índice que se van a commitear —fuera de `openspec/`, que la huella no
cubre—, y de una verificación que salió verde.

1. Un `git commit` sin firma válida SHALL fallar antes de crear el commit, con un mensaje que
   diga qué hacer.
2. La decisión NO SHALL depender del directorio desde el que se invoca git, de la forma en que
   se escribe el comando ni de la herramienta que lo lanza: un `git -C`, un `cd` previo, un
   `bash -c` y una terminal ajena a Claude Code SHALL dar el mismo resultado.
3. Stagear en el propio commit —`-a` o un pathspec— algo de fuera de `openspec/` después de
   firmar SHALL bloquear, porque cambia el índice firmado. Lo que se stagee de `openspec/` NO
   SHALL bloquear.
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
  fuera de `openspec/`
- **THEN** el commit no se crea

#### Scenario: El commit lleva el acuerdo actualizado

- **WHEN** hay firma verde y, después, solo se ha cambiado y stageado algo dentro de `openspec/`
- **THEN** el commit pasa con esa firma, sin volver a verificar

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
