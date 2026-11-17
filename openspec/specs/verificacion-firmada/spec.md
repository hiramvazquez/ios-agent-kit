# verificacion-firmada Specification

## Purpose

Que «verificado» signifique algo que se puede comprobar: la verificación se firma contra el
`sha256` del árbol que se verificó, dice con qué toolchain corrió y qué no cubre, y la firma vale
para ese árbol y solo si el resultado fue verde. Y que se distinga **«no pude mirar»** de **«está
mal»**: confundirlos hace que un gate roto parezca un proyecto roto, y al revés.

Lo que **no** pretende: que el verde valga para otro toolchain que el que corrió; lo que hace es
que el verde diga de qué habla.

## Requirements

### Requirement: «No pude mirar» y «está mal» salen con códigos distintos

`verifica.sh` SHALL distinguir en su código de salida el caso en que no ha podido verificar
del caso en que ha verificado y hay pasos en rojo.

1. Faltar `kit.conf`, o que no defina `verificaciones()`, SHALL seguir saliendo con el código
   documentado para «no pude mirar».
2. Que haya pasos en rojo SHALL salir con un código distinto de ese, **sea cual sea el número
   de pasos fallidos**.
3. El número de pasos en rojo SHALL seguir siendo legible en el informe y en la línea
   `resultado:` de la firma.

La 3 existe porque el recuento no se pierde: vive donde de verdad se lee.

#### Scenario: Tres pasos en rojo

- **WHEN** la verificación corre con tres pasos que fallan
- **THEN** el código de salida no es el de «no pude mirar»
- **AND** el informe dice cuántos pasos fallaron

#### Scenario: Un repositorio sin kit.conf

- **WHEN** la verificación corre donde no hay `kit.conf`
- **THEN** sale con el código de «no pude mirar»

### Requirement: El veredicto del kit no depende del idioma de la máquina

Los scripts del kit SHALL dar el mismo resultado con `LANG` vacío y con un locale UTF-8, que es
el que trae por defecto el terminal de macOS.

1. Ningún script del kit SHALL escribir `$VAR` pegado a un carácter no-ASCII. SHALL escribirse
   `${VAR}`, porque `bash` 3.2 con `LC_CTYPE` UTF-8 mete los bytes de ese carácter dentro del
   nombre de la variable.
2. `kit.conf` SHALL tener un paso que lo compruebe, que salga en rojo si encuentra alguno y diga
   en qué fichero y en qué línea.
3. El paso NO SHALL marcar la forma correcta `${VAR}` seguida del mismo carácter.
4. El paso SHALL mirar el byte y no una lista de caracteres: cuenta cualquier carácter no-ASCII,
   no solo los seis con los que se midió el fallo.

La 1 es el fallo real y no una precaución: con `set -u` —que usan todos los scripts del kit— no
degrada, **aborta**, y `/kit-verifica` sale sin firma, así que la puerta de commit bloquea el
commit. El kit queda inservible para quien abra un terminal con su configuración por defecto.

La 2 existe porque no hay forma más barata de verla: `bash -n` sale con 0,
`shellcheck --severity=warning` sale con 0, y los bancos pasan en verde porque el agente corre
con el locale vacío.

La 3 existe porque un paso que marcara las dos formas sería inútil: el mensaje correcto lleva el
mismo carácter, y la diferencia son exactamente las llaves.

**Límite declarado.** Esto cubre los scripts del kit —`scripts/*.sh`, `scripts/*.py`, `kit.conf` y
su plantilla—, que es lo que el kit controla. El código del proyecto que lo usa queda fuera: ahí el
kit no manda, y prometerlo sería prometer de más. Tampoco ve un script fuera de `scripts/` o en una
subcarpeta suya, una variable partida con `\` al final de la línea, ni avisa si no puede abrir un
fichero.

#### Scenario: Un script con la forma rota

- **WHEN** un script del kit escribe `$VAR` pegado a un carácter no-ASCII
- **THEN** el paso sale en rojo y dice en qué fichero y en qué línea

#### Scenario: La forma correcta

- **WHEN** un script escribe `${VAR}` seguido del mismo carácter
- **THEN** el paso no lo marca

#### Scenario: El mismo veredicto en los dos idiomas

- **WHEN** se corre la verificación con `LANG` vacío y con `LANG=en_US.UTF-8`
- **THEN** las dos salen en verde y con firma

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

### Requirement: La firma declara con qué se verificó, y qué no cubre

Una firma verde SHALL decir con qué toolchain corrió. Sin eso, «verificado» se lee como «esto
pasa», cuando lo único que afirma es «esto pasó aquí»: un diagnóstico que produce una versión
de Swift y otra no, ninguna firma local lo ve.

1. La firma SHALL registrar el toolchain con el que se ejecutaron los pasos: la versión del
   compilador que hay en el PATH y, si el proyecto se construye con Xcode, la versión de Xcode
   seleccionada. Si no se puede identificar, SHALL decir que no se pudo, y no callarlo.
2. Cuando el compilador del PATH y el que expone el Xcode seleccionado anuncian **versiones
   distintas**, la firma SHALL decirlo. Dos toolchains distintos que anuncien la misma versión
   no se distinguen, y eso queda fuera a propósito. No SHALL bloquear: hay proyectos que usan
   un toolchain de swift.org a propósito.
3. Un proyecto SHALL poder declarar en su `kit.conf`, en prosa, **qué no cubre su firma**. Lo
   declarado SHALL viajar en la firma y aparecer en el informe. Cuando el proyecto no declara
   nada, el informe SHALL decir que no lo declara, en vez de dejar creer que no hay límites.
4. Toda superficie donde el kit afirme la verificación SHALL nombrar ese alcance: el informe, la
   comprobación de firma válida, el contexto que el kit inyecta en cada turno y el estado del
   kit. Un solo sitio que siga diciendo «verificado» a secas basta para deshacer el resto.
5. El coste de identificar el toolchain SHALL ser despreciable frente a la verificación: décimas
   de segundo sobre verificaciones que tardan de segundos a minutos.

**Lo que este requisito NO promete.** No hace que la firma cubra otro toolchain, y no compara la
versión local con la del CI: eso exigiría que cada proyecto escribiera una versión en su
`kit.conf`, y una cifra escrita ahí caduca sin que nadie la vuelva a medir. Lo que hace es que el
verde diga de qué habla, para que quien lo lea sepa qué le falta comprobar.

#### Scenario: Se verifica un proyecto y la verificación sale verde

- **WHEN** `/kit-verifica` termina en verde
- **THEN** la firma dice con qué compilador y con qué Xcode se corrió
- **AND** la línea con la que se anuncia el verde nombra ese alcance

#### Scenario: El compilador del PATH no es el del Xcode seleccionado

- **WHEN** el `swift` del PATH y el que expone `xcrun` son de versiones distintas
- **THEN** la firma y el informe lo dicen
- **AND** la verificación no se bloquea por ello

#### Scenario: El proyecto declara los límites de su firma

- **WHEN** el `kit.conf` del proyecto declara qué no cubre su verificación
- **THEN** lo declarado aparece en el informe y viaja en la firma

#### Scenario: El proyecto no declara ningún límite

- **WHEN** el `kit.conf` del proyecto no declara límites
- **THEN** el informe dice que el proyecto no los declara

#### Scenario: Se pregunta por la firma sin volver a verificar

- **WHEN** se consulta si hay firma válida, o el estado del kit, o llega el contexto de un turno
- **THEN** lo que se responde nombra el toolchain de esa firma

#### Scenario: El toolchain no se puede identificar

- **WHEN** en la máquina no hay ningún compilador que el kit pueda interrogar
- **THEN** la firma dice que el toolchain no se pudo identificar
- **AND** la verificación sigue su curso y firma igual

### Requirement: La firma se juzga por su cabecera

Quien juzgue una firma —`--comprueba`, el hook de commit y el digest— SHALL leer la huella y
el resultado solo de la cabecera del fichero, que acaba en la primera línea en blanco. Lo que
va debajo es el informe, y copia salida de los pasos: NOT SHALL poder cambiar el veredicto.

#### Scenario: Un paso que falla imprime la línea del veredicto

- **WHEN** un paso sale en rojo y su salida contiene la línea `resultado: verde`
- **THEN** la firma no es válida para nadie que la juzgue
- **AND** el commit queda bloqueado

### Requirement: Lo que se firma es lo que vieron los pasos

`verifica.sh` SHALL fotografiar el árbol antes de correr los pasos y otra vez al terminar. Si
las dos fotos difieren, la verificación SHALL salir en rojo y el informe SHALL nombrar las
rutas que cambiaron.

#### Scenario: El árbol cambia mientras se verifica

- **WHEN** un fichero del árbol cambia entre el primer paso y la firma
- **THEN** la verificación sale en rojo
- **AND** el informe nombra ese fichero

#### Scenario: El árbol no cambia

- **WHEN** nada cambia mientras corren los pasos
- **THEN** la verificación se firma como antes
