## MODIFIED Requirements

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
