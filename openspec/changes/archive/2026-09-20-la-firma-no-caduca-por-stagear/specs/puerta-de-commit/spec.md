## MODIFIED Requirements

### Requirement: La puerta es un hook de git del repositorio

La puerta de commit SHALL ser un hook `pre-commit` de git instalado en el repositorio del
proyecto, y SHALL decidir con la misma regla que la comprobación de firma: la firma tiene que
ser del árbol que se va a commitear —fuera de `openspec/`, que la huella no cubre—, de una
verificación que salió verde, y el índice no puede llevar contenido distinto de ese árbol.

1. Un `git commit` sin firma válida SHALL fallar antes de crear el commit, con un mensaje que
   diga qué hacer.
2. La decisión NO SHALL depender del directorio desde el que se invoca git, de la forma en que
   se escribe el comando ni de la herramienta que lo lanza: un `git -C`, un `cd` previo, un
   `bash -c` y una terminal ajena a Claude Code SHALL dar el mismo resultado.
3. Stagear en el propio commit —`-a` o un pathspec— SHALL bloquear si el árbol cambió después
   de firmar, y NO SHALL bloquear si lo que se stagea es el árbol que se verificó. Lo que se
   stagee de `openspec/` NO SHALL bloquear.
4. Si alguna ruta stageada tiene en el índice un contenido distinto del árbol, SHALL bloquear
   aunque la huella cuadre, y el mensaje SHALL nombrar esas rutas.
5. En un repositorio sin ningún commit todavía, SHALL comprobar la huella del índice, que es
   la única referencia que existe.
6. Sin `kit.conf` en la raíz del repositorio, el hook SHALL dejar pasar: ese repositorio ya no
   usa el kit, y un hook que sobrevive a desinstalarlo no puede convertirse en un muro.
7. Lo que la puerta no frena SHALL estar declarado en el propio hook y en la referencia de
   piezas: `--no-verify`, un git que no lea los hooks del repositorio, y los commits que git
   crea sin pasar por `pre-commit` (merge, revert, cherry-pick, rebase).

#### Scenario: Commit sin firma

- **WHEN** se intenta `git commit` en un repositorio con el kit y sin firma válida para su árbol
- **THEN** el commit no se crea
- **AND** el mensaje dice que hay que verificar antes de commitear

#### Scenario: Commit con firma válida

- **WHEN** el árbol es el que firmó una verificación verde y el índice no lleva nada distinto
- **THEN** el commit pasa

#### Scenario: El commit stagea por su cuenta

- **WHEN** hay firma verde y se commitea con `-a` o con un pathspec tras modificar el árbol
  fuera de `openspec/`
- **THEN** el commit no se crea

#### Scenario: El índice lleva contenido que no se verificó

- **WHEN** hay firma verde del árbol y una ruta stageada tiene en el índice otro contenido
- **THEN** el commit no se crea
- **AND** el mensaje nombra esa ruta

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
