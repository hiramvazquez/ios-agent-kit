# Puerta de commit — delta

## MODIFIED Requirements

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
