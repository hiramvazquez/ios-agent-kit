## MODIFIED Requirements

### Requirement: El contexto inyectado dice de qué repositorio habla

El hook que inyecta el acuerdo en cada turno SHALL atribuir lo que afirma al repositorio
del que lo ha leído, y SHALL producirlo entero sea cual sea el estado de las tareas.

1. El digest SHALL nombrar ese repositorio, incluso cuando no haya nada que contar sobre él.
2. Un repositorio sin `openspec/` SHALL producir un digest que lo diga, y que NO ordene
   abrir una propuesta.
3. Con un cambio activo y **cero** tareas pendientes, el digest SHALL incluir la línea de
   recuento de tareas y el bloque «FUERA de alcance», y el hook NO SHALL escribir nada en
   la salida de error.
4. El bloque «FUERA de alcance» SHALL reconocerse **sea cual sea la caja de su cabecera**:
   `## Fuera de alcance` y `## FUERA de alcance` SHALL dar el mismo resultado.
5. Un cambio activo **sin `tasks.md`** NO SHALL producir la línea de recuento de tareas, y SHALL
   seguir produciendo el resto del digest.
6. Las reglas innegociables SHALL incluir **qué hacer con un hallazgo de revisión**: buscar la
   causa antes de reaccionar y preferir restar, porque un hallazgo no justifica por sí solo un
   fichero nuevo. SHALL caber en una línea.

**Límite declarado.** Que la regla esté delante no obliga a nadie a seguirla: el digest pone el
texto, no impone la conducta.

#### Scenario: Un cambio con todas las tareas cerradas

- **WHEN** el hook corre en un repositorio cuyo cambio activo no tiene tareas pendientes
- **THEN** el digest dice cuántas tareas hay hechas
- **AND** incluye el bloque «FUERA de alcance»
- **AND** el hook no escribe nada en la salida de error

#### Scenario: La cabecera del fuera de alcance en mayúsculas

- **WHEN** el `proposal.md` del cambio activo escribe `## FUERA de alcance`
- **THEN** el digest incluye ese bloque, igual que con la cabecera en minúsculas

#### Scenario: Un cambio activo sin lista de tareas

- **WHEN** el cambio activo no tiene `tasks.md`
- **THEN** el digest no lleva la línea de recuento de tareas
- **AND** sigue llevando el bloque «FUERA de alcance»

#### Scenario: Qué hacer con un hallazgo, delante en cada turno

- **WHEN** el hook corre en cualquier repositorio
- **THEN** las reglas innegociables incluyen qué hacer con un hallazgo de revisión
- **AND** ocupa una línea

#### Scenario: Un repositorio que no usa OpenSpec

- **WHEN** el hook corre en un repositorio sin `openspec/`
- **THEN** el digest nombra ese repositorio
- **AND** dice que no usa OpenSpec
- **AND** no ordena abrir una propuesta

#### Scenario: Un repositorio con OpenSpec y sin cambio activo

- **WHEN** el hook corre en un repositorio con `openspec/` y ningún cambio activo
- **THEN** el digest dice que no hay cambio activo y que hay que proponer antes de tocar código
- **AND** lo atribuye a ese repositorio

### Requirement: El hook no escribe en directorios compartidos

El hook que inyecta el acuerdo NO SHALL crear ficheros fuera de su caché declarada.

1. NO SHALL escribir en un directorio compartido por todos los usuarios de la máquina con un
   nombre derivable del identificador de proceso.

Este hook corre en cada turno de cualquier repositorio por el que pase una sesión: un temporal
de nombre adivinable en un directorio escribible por cualquiera es un riesgo innecesario para
componer tres líneas de texto.

#### Scenario: El hook compone el digest con tareas pendientes

- **WHEN** el hook corre en un repositorio con un cambio activo y tareas sin cerrar
- **THEN** el digest lleva las tareas pendientes
- **AND** no queda ningún fichero nuevo en el directorio temporal del sistema
