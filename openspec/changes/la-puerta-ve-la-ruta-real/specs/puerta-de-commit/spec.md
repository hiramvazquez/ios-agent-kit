## MODIFIED Requirements

### Requirement: La puerta juzga el repo al que va el commit

El hook `PreToolUse` que vigila los commits SHALL decidir sobre el repositorio **al que va
el commit interceptado**, no sobre el directorio de trabajo que hereda de la sesión.

1. Cuando el comando indica el repositorio de destino —`-C <ruta>`, `--git-dir <ruta>`, o un
   `cd <ruta>` que precede al commit en la misma cadena de comandos—, la puerta SHALL
   comprobar la firma de verificación **de ese** repositorio. Entre el `cd` y el commit
   SHALL poder haber otros comandos de git (`git add`, `git status`), separados por `&&`,
   por `;` o por salto de línea.
2. La ruta indicada SHALL resolverse como la resolvería el shell que va a ejecutarla: `~`,
   `~usuario` y variables de entorno se expanden antes de buscar el repositorio. Una ruta que
   el shell resolvería y la puerta no, es un commit que pasa sin comprobar.
3. Cuando el comando no indica ninguno, la puerta SHALL comprobar la del repositorio del
   directorio heredado, que es el caso normal.
4. La puerta SHALL reconocer un commit por su invocación, no por la presencia de una
   subcadena en el texto del comando.
5. Cada salida que deje pasar el comando sin comprobar nada SHALL declarar por escrito, en el
   propio script, si falla abierto o cerrado y por qué.
6. Lo que la puerta exige es una firma válida **para el árbol** del repositorio de destino, no
   para su índice: la forma de stagear —`-a`, un pathspec, o el índice— NO SHALL cambiar el
   veredicto.
7. Ninguna constante del analizador SHALL enumerar un caso que el analizador no recibe. Una
   lista que nombra algo sin cubrirlo hace creer que está cubierto, y eso es peor que no
   nombrarlo: fue exactamente lo que pasó con el salto de línea.

La 1 y la 4 no son la misma: un comando dirigido con `-C` falla hoy por las DOS razones a la
vez —no se reconoce como commit, y aunque se reconociera se miraría el repo equivocado—, y
arreglar solo una lo deja roto.

La 4 tiene una segunda cara que no es teórica: mientras el reconocimiento sea por subcadena,
cualquier comando que mencione las palabras queda bloqueado aunque no invoque git. Escribir
documentación sobre la puerta es el caso que lo destapó.

La 2 y la 7 salen de una medición del 2026-09-16: `cd ~/… && git commit` no se bloqueaba,
porque la pista se pasaba sin expandir a `git -C` y el hook caía en su salida de fallo
abierto. Y el salto de línea tampoco, porque `shlex` con `whitespace_split` nunca emite
`"\n"` aunque la constante lo enumerase. Lo primero incumplía esta norma; lo segundo era un
límite declarado que el código aparentaba cubrir.

La 6 no cambia lo que hace la puerta —delega en `verifica.sh --comprueba`— sino lo que esta
norma promete. Decía «firma válida para su diff staged», y con esa lectura `git commit -am`
sobre un índice vacío cumplía la letra mientras metía código sin verificar. Qué se firma lo
fija `verificacion-firmada`.

#### Scenario: Commit dirigido a otro repo sin firma

- **WHEN** el comando dirige un commit con `-C` a un repositorio sin firma válida para su
  árbol
- **THEN** la puerta lo bloquea
- **AND** el motivo nombra el repositorio que ha comprobado

#### Scenario: Commit dirigido a otro repo con firma válida

- **WHEN** el comando dirige un commit con `-C` a un repositorio cuya firma es válida para su
  árbol
- **THEN** la puerta lo deja pasar

#### Scenario: La ruta se escribe con `~` o con una variable

- **WHEN** el comando hace `cd ~/ruta/al/repo` —o `cd $HOME/ruta/al/repo`— y después
  commitea, y ese repositorio no tiene firma válida
- **THEN** la puerta lo bloquea igual que si la ruta viniera absoluta

`~usuario` se expande por el mismo camino y funciona, pero NO está fijado por el banco: se
resuelve por la base de datos de usuarios y no por `$HOME`, así que probarlo exigiría escribir
en el home real del usuario que ejecuta las pruebas. Queda dicho aquí en vez de dejar creer
que hay una prueba que no existe.

#### Scenario: El `cd` y el commit van en líneas distintas

- **WHEN** el comando hace `cd <ruta>` en una línea y commitea en la siguiente, y ese
  repositorio no tiene firma válida
- **THEN** la puerta lo bloquea

#### Scenario: Stagear y commitear en líneas distintas

- **WHEN** el comando hace `git add` en una línea y `git commit` en la siguiente, con o sin
  un `cd` por delante, y el repositorio de destino no tiene firma válida
- **THEN** la puerta lo bloquea

Es la forma más común de escribir un commit en un script de varias líneas, y hasta el
2026-09-16 no se comprobaba ni el repositorio de la sesión: el escaneo se detenía en el
`add`.

#### Scenario: Un comando que no es de git entre el `cd` y el commit

- **WHEN** entre el `cd` y el commit hay un comando cualquiera —un `echo`, un script— en una
  línea intermedia
- **THEN** la puerta cae al directorio heredado, como declara su límite
- **AND** ese límite está escrito en la cabecera del hook

La razón de no cubrirlo: `shlex` no emite el salto de línea, así que dentro de un segmento no
se sabe dónde acaba un comando y empieza el siguiente. Se reconocen los inicios de comando
conocidos —git y los shells—, y un nombre arbitrario no se puede distinguir de un argumento.
Partir la entrada por líneas sí lo resolvería, pero convertiría el cuerpo de un heredoc que
contenga `git commit` en un commit falso, que es un caso que este banco ya fija.

#### Scenario: Commit a secas en el repo de la sesión

- **WHEN** el comando es un commit sin indicar repositorio y el directorio heredado tiene
  firma válida
- **THEN** la puerta lo deja pasar
- **AND** si no la tiene, la bloquea

#### Scenario: Un commit que stagea y commitea a la vez

- **WHEN** hay firma válida y después se modifica el árbol sin stagear
- **THEN** la puerta bloquea el commit aunque stagee él mismo con `-a` o con un pathspec

#### Scenario: Un comando que solo menciona las palabras

- **WHEN** el comando escribe, imprime o busca el texto «git commit» sin invocar git
- **THEN** la puerta no lo bloquea

#### Scenario: Una ruta que el shell tampoco resolvería

- **WHEN** la pista de directorio se construye en tiempo de ejecución y no se puede resolver
  sin ejecutar el comando
- **THEN** la puerta falla abierto, como ya declara
- **AND** ese límite sigue escrito en la cabecera del hook
