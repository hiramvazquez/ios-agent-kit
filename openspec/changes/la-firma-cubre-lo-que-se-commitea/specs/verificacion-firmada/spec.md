# Verificación firmada — delta

## ADDED Requirements

### Requirement: La firma cubre el árbol que se verificó

`verifica.sh` SHALL firmar la huella del **árbol de trabajo y del índice**, que entre los dos
son lo que cualquier forma de commit puede llevarse.

1. La huella SHALL cubrir el árbol contra `HEAD` **y** el contenido del índice, de forma que lo
   que está en uno no se pueda confundir con lo que está en el otro.
2. En un repositorio sin ningún commit todavía, SHALL cubrir el índice, que es la única
   referencia que existe ahí.
3. La huella SHALL tener **una sola definición** en el kit. `verifica.sh` y el hook que inyecta
   el contexto SHALL usar esa.
4. Un cambio posterior a la firma SHALL invalidarla, esté en el árbol, en el índice, o en los
   dos.

Los dos lados tienen su fallo, y firmar uno solo deja el otro abierto. Con la huella del
índice, firmar con nada stageado y commitear después con `-a` o con un pathspec mete código que
nadie ha verificado: el índice sigue vacío y la huella no se mueve. Con la huella del árbol,
stagear contenido distinto y devolver el fichero a su contenido de `HEAD` deja la huella igual
mientras `git commit` a secas se lleva el índice: entra contenido que nunca se compiló. El
primero se reprodujo el 2026-09-11 con `-am`, `-a -m` y un pathspec; el segundo lo reprodujo el
revisor ese mismo día, sobre la primera versión de este arreglo.

La 3 no es orden: las dos copias tienen que dar el mismo número o el digest dirá «la firma es de
OTRO diff» en cada turno de un árbol recién firmado.

**Consecuencia asumida.** Stagear después de firmar cambia el índice y por tanto la huella, así
que stagear, verificar y commitear van en comandos separados. Es el precio de cubrir los dos
lados, y es el lado correcto en el que equivocarse.

**Límite declarado.** Sigue siendo posible commitear **menos** de lo verificado —stagear una
parte y commitear solo esa—. Eso lo avisa el informe como árbol sucio, y no bloquea: quien tiene
trabajo en curso aparte decide.

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
