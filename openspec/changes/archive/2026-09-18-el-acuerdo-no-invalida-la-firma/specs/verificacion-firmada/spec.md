## MODIFIED Requirements

### Requirement: La firma cubre el árbol que se verificó

`verifica.sh` SHALL firmar la huella del **árbol de trabajo y del índice**, que entre los dos
son lo que cualquier forma de commit puede llevarse, **salvo `openspec/`**, que es el acuerdo y
no lo que se compila.

1. La huella SHALL cubrir el árbol contra `HEAD` **y** el contenido del índice, de forma que lo
   que está en uno no se pueda confundir con lo que está en el otro.
2. En un repositorio sin ningún commit todavía, SHALL cubrir el índice, que es la única
   referencia que existe ahí.
3. La huella SHALL tener **una sola definición** en el kit. `verifica.sh` y el hook que inyecta
   el contexto SHALL usar esa.
4. Un cambio posterior a la firma fuera de `openspec/` SHALL invalidarla, esté en el árbol, en
   el índice, o en los dos.
5. Un cambio posterior a la firma dentro de `openspec/` —marcar una tarea, anotar una ronda,
   archivar un cambio— NO SHALL invalidarla, esté en el árbol o en el índice.
6. La exclusión SHALL ser exactamente el directorio `openspec/` de la raíz del repositorio: otro
   directorio cuyo nombre empiece igual SHALL seguir dentro de la huella.
7. Con `openspec/` sin cambios, la huella SHALL ser la misma que antes de excluirlo, para que las
   firmas ya escritas sigan valiendo.

Los dos lados tienen su fallo, y firmar uno solo deja el otro abierto: con la huella del índice
sola, firmar con nada stageado y commitear después con `-a` o con un pathspec mete código que
nadie ha verificado; con la del árbol sola, stagear contenido distinto y devolver el fichero a
su contenido de `HEAD` deja la huella igual mientras `git commit` a secas se lleva el índice.

La 3 no es orden: las dos copias tienen que dar el mismo número o el digest dirá «la firma es de
OTRO diff» en cada turno de un árbol recién firmado.

**Consecuencia asumida.** Stagear después de firmar cambia el índice y por tanto la huella, así
que stagear, verificar y commitear van en comandos separados. Es el precio de cubrir los dos
lados, y es el lado correcto en el que equivocarse.

La 5 existe porque el flujo de OpenSpec escribe en `openspec/` justo después de verificar, y
cada escritura obligaba a verificar otra vez un árbol cuyo código no había cambiado.

**Límites declarados.** Sigue siendo posible commitear **menos** de lo verificado —stagear una
parte y commitear solo esa—. Eso lo avisa el informe como árbol sucio, y no bloquea: quien tiene
trabajo en curso aparte decide. Lo que vive en `openspec/` no queda firmado: si un proyecto
verifica algo de ahí en su `kit.conf`, un cambio posterior en ese directorio no lo invalida. Y
la huella sigue siendo del diff contra `HEAD`: la firma deja de valer cuando un commit se
lleva el código firmado, y después un commit que solo toque `openspec/` necesita otra
verificación.

#### Scenario: El índice lleva algo que el árbol ya no

- **WHEN** hay firma verde, se stagea contenido distinto y el fichero vuelve a su contenido de
  `HEAD`
- **THEN** la firma deja de valer y la puerta bloquea el commit

#### Scenario: Commit con -a después de editar el árbol

- **WHEN** hay firma verde y después se modifica un fichero trackeado sin stagearlo
- **THEN** la puerta bloquea `git commit -am`

#### Scenario: Un fichero nuevo stageado después de firmar

- **WHEN** se añade un fichero nuevo al índice después de firmar
- **THEN** la firma deja de valer

#### Scenario: Un repositorio sin commits

- **WHEN** se verifica y se commitea por primera vez en un repositorio sin `HEAD`
- **THEN** la verificación firma y la puerta deja pasar el commit

#### Scenario: Se marca una tarea después de firmar

- **WHEN** hay firma verde y se edita un `tasks.md` de `openspec/changes/`, se stagee o no
- **THEN** la firma sigue valiendo

#### Scenario: Se archiva el cambio después de firmar

- **WHEN** hay firma verde y el cambio se mueve a `openspec/changes/archive/` y su delta se funde
  en `openspec/specs/`
- **THEN** la firma sigue valiendo

#### Scenario: El acuerdo y el código cambian después de firmar

- **WHEN** hay firma verde y se edita algo en `openspec/` y algo fuera de él
- **THEN** la firma deja de valer

#### Scenario: Un directorio que solo se llama parecido

- **WHEN** hay firma verde y se edita un fichero de `openspec-notas/`
- **THEN** la firma deja de valer
