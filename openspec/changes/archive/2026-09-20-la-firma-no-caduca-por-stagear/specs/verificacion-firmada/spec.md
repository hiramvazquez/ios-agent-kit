## MODIFIED Requirements

### Requirement: La firma cubre el árbol que se verificó

`verifica.sh` SHALL firmar una **foto del árbol de trabajo**, que es lo que se compila y lo
que se prueba. La foto SHALL hacerla git —un índice temporal, `add -A` y `write-tree`— y NOT
SHALL construirse leyendo rutas: git cita los nombres que no puede imprimir a pelo, y no toda
entrada de un árbol es un fichero normal. La foto SHALL cubrir, con la misma regla, los
ficheros sin trackear que git no ignora, los enlaces simbólicos aunque su destino no exista,
los submódulos por el commit al que apuntan, los permisos y lo borrado. Que el índice lleve ese mismo árbol y no otra cosa
NOT SHALL ir dentro de la huella: SHALL comprobarse aparte, cuando se juzga la firma.

1. La huella SHALL ser el sha256 de esa foto, y NOT SHALL depender del estado del índice: el
   mismo árbol SHALL dar la misma huella esté lo que esté stageado.
1bis. Tomar la foto NOT SHALL escribir en el repositorio del proyecto —ni objetos, ni estado:
   lo que necesite SHALL vivir fuera— y NOT SHALL depender del directorio desde el que se
   llame.
1ter. Si el árbol no se puede fotografiar, SHALL fallar cerrada, y para eso hacen falta tres
   cosas a la vez: lo que imprima NOT SHALL ser una constante, quien firma NOT SHALL escribir
   firma —SHALL salir con el código de «no pude mirar»—, y todo el que juzgue una firma SHALL
   mirar el código de salida antes de comparar nada. Con solo la primera, un fallo que
   persiste se firma y después cuadra consigo mismo.
2. En un repositorio sin ningún commit todavía, las rutas SHALL salir del índice, que es la
   única referencia que existe ahí.
3. La huella SHALL tener **una sola definición** en el kit. `verifica.sh` y el hook que inyecta
   el contexto SHALL usar esa.
4. Un cambio del árbol posterior a la firma, fuera de `openspec/`, SHALL invalidarla: editar,
   borrar y también CREAR un fichero que git no ignore.
5. Un cambio posterior a la firma dentro de `openspec/` —marcar una tarea, anotar una ronda,
   archivar un cambio— NO SHALL invalidarla, esté en el árbol o en el índice.
6. La exclusión SHALL ser exactamente la ruta `openspec` de la raíz del repositorio: otro
   directorio cuyo nombre empiece igual —`openspec-notas/`— y uno anidado —`src/openspec/`—
   SHALL seguir dentro de la huella. *Corregido al implementar, el 2026-09-20:* antes decía «el
   directorio `openspec/`», y un FICHERO llamado `openspec` en la raíz sí se firmaba. Ahora
   queda fuera. Nadie tiene un fichero así con código dentro, y distinguirlo costaría un caso
   borde para nadie; decidido con el revisor.
7. `.agent-kit/` SHALL quedar fuera de la huella, lo ignore el proyecto o no: es donde vive
   la firma, y dentro de la foto escribirla invalidaría la firma recién escrita. Lo que el
   proyecto ignore en su `.gitignore` SHALL quedar fuera también: si no, compilar invalidaría
   la firma.
8. Stagear contenido que ya estaba en el árbol verificado NO SHALL invalidar la firma, sea un
   fichero ya trackeado o uno nuevo. Acercar el índice al árbol solo puede hacer que el commit
   lleve **más** de lo verificado, nunca algo distinto.
9. Quien juzgue una firma SHALL rechazarla, aunque la huella cuadre, si alguna ruta stageada
   tiene en el índice un contenido distinto del árbol. Esa lista de rutas SHALL tener **una
   sola definición** en el kit, la SHALL usar todo el que juzgue una firma, y SHALL llevar los
   mismos pathspecs que la huella, `openspec/` excluido incluido.

Los dos lados tienen su fallo, y mirar uno solo deja el otro abierto: sin la huella del árbol,
editar después de firmar pasa desapercibido; sin la comprobación del índice, stagear contenido
y devolver el fichero a su contenido de `HEAD` deja el árbol igual que al firmar mientras
`git commit` a secas se lleva el índice.

La 3 y la 9 no son orden: las copias tienen que dar el mismo resultado o el digest dirá «la
firma es de OTRO diff» en cada turno de un árbol recién firmado.

La 5 existe porque el flujo de OpenSpec escribe en `openspec/` justo después de verificar, y
cada escritura obligaba a verificar otra vez un árbol cuyo código no había cambiado. La 8 y la
9 existen por lo mismo medido en el índice: el informe pide stagear lo que falta, y hacerle
caso obligaba a repetir la verificación de un árbol que no había cambiado.

**Límites declarados.** Sigue siendo posible commitear **menos** de lo verificado —stagear una
parte y commitear solo esa—. Eso lo avisa el informe como árbol sucio, y no bloquea: quien
tiene trabajo en curso aparte decide. Una ruta con un salto de línea en el nombre no está
soportada. Lo que vive en `openspec/` no queda firmado: si un proyecto verifica algo de ahí en
su `kit.conf`, un cambio posterior en ese directorio no lo invalida. Y la huella sigue siendo
del diff contra `HEAD`: la firma deja de valer cuando un commit se lleva el código firmado, y
después un commit que solo toque `openspec/` necesita otra verificación.

#### Scenario: El índice lleva algo que el árbol ya no

- **WHEN** hay firma verde, se stagea contenido distinto y el fichero vuelve a su contenido de
  `HEAD`
- **THEN** la firma deja de valer y la puerta bloquea el commit

#### Scenario: Se firma con el índice ya divergente

- **WHEN** una ruta tiene en el índice un contenido distinto del árbol y se verifica en verde
- **THEN** el informe lo dice, con las rutas
- **AND** esa firma no vale para commitear mientras el índice siga divergiendo

#### Scenario: Se stagea lo que ya se había verificado

- **WHEN** hay firma verde con cambios sin stagear y después se stagean, sin tocar el árbol
- **THEN** la firma sigue valiendo y la puerta deja pasar el commit

#### Scenario: Commit con -a después de editar el árbol

- **WHEN** hay firma verde y después se modifica un fichero trackeado sin stagearlo
- **THEN** la puerta bloquea `git commit -am`

#### Scenario: Commit con -a sin editar nada después de firmar

- **WHEN** hay firma verde de un árbol con cambios sin stagear y no se toca nada después
- **THEN** `git commit -am` pasa, porque se lleva exactamente el árbol que se verificó

#### Scenario: Un fichero nuevo, creado antes de firmar y stageado después

- **WHEN** existe un fichero sin trackear al verificar y se stagea después, sin tocarlo
- **THEN** la firma sigue valiendo

#### Scenario: Un fichero nuevo stageado después de firmar

- **WHEN** se crea un fichero que git no ignora después de firmar y se stagea
- **THEN** la firma deja de valer

#### Scenario: Un fichero nuevo creado después de firmar y sin stagear

- **WHEN** se crea un fichero que git no ignora después de firmar y no se stagea
- **THEN** la firma deja de valer

#### Scenario: Una ruta que git escribe entrecomillada

- **WHEN** un fichero cuyo nombre git cita —acentos, comillas, tabuladores— se cambia después
  de una firma que ya lo incluía cambiado
- **THEN** la firma deja de valer

#### Scenario: Un enlace simbólico roto

- **WHEN** un enlace simbólico cuyo destino no existe se repunta a otro destino después de
  firmar
- **THEN** la firma deja de valer

#### Scenario: Un submódulo sube de commit

- **WHEN** un submódulo se sube a otro commit después de una firma que ya lo incluía subido
- **THEN** la firma deja de valer

#### Scenario: Se borra un fichero después de firmar

- **WHEN** se borra del árbol un fichero trackeado después de firmar
- **THEN** la firma deja de valer

#### Scenario: Aparece un fichero que git ignora

- **WHEN** después de firmar aparece un fichero que el `.gitignore` del proyecto excluye
- **THEN** la firma sigue valiendo

#### Scenario: El árbol no se puede fotografiar

- **WHEN** un fichero del árbol no se puede leer, o un filtro declarado en `.gitattributes` no
  está instalado, y se verifica
- **THEN** no se escribe ninguna firma y la verificación sale con «no pude mirar»
- **AND** mientras la causa siga ahí, ninguna firma anterior vale y la puerta bloquea

#### Scenario: Se pregunta por la firma en un repositorio sin el kit

- **WHEN** se comprueba la firma en un repositorio que nunca ha verificado
- **THEN** responde que no hay nada verificado
- **AND** no crea ningún directorio de estado en ese repositorio

#### Scenario: Se escribe la propia firma

- **WHEN** la verificación escribe su marcador en `.agent-kit/`
- **THEN** la firma que acaba de escribir vale para ese árbol

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
