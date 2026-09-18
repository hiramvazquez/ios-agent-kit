# contexto-inyectado Specification

## Purpose

Poner el acuerdo delante del modelo en cada turno, corto y atribuido: contra la deriva no sirve
obligar a leer una skill, porque el modelo cree que se acuerda y no relee; lo que sirve es que el
texto esté delante otra vez, siempre. Atribuido, porque el hook lee el repositorio del directorio
que hereda la sesión, que no tiene por qué ser aquel en el que se trabaja, y un digest que
describe otro repositorio empuja en la dirección contraria a la que fue puesto.

Lo que **no** pretende: adivinar dónde trabaja el modelo —no hay señal disponible, y adivinarla
sería peor que callarse— ni escribir nada dentro del repositorio que observa, porque corre en
toda sesión del usuario, también en repositorios que nunca pidieron el kit.

## Requirements

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

### Requirement: El hook no escribe en repositorios que no usan el kit

El hook SHALL evitar crear ficheros o directorios dentro de un repositorio que no dé
señales de usar el kit, y las dependencias que anuncia SHALL acotarse al prefijo del
repositorio observado.

1. Tras correr sobre un repositorio sin `kit.conf` ni `openspec/`, el estado de git SHALL
   quedar igual que antes.
2. El caché que hoy vive en `.agent-kit/` SHALL vivir fuera del repositorio observado.
3. Dos repositorios distintos SHALL tener cachés distintos.
4. El caché SHALL seguir evitando el recorrido de `DerivedData` en turnos consecutivos.
5. La búsqueda de dependencias SHALL acotarse por el prefijo `<carpeta del repositorio>-*`
   sobre `DerivedData`. Un repositorio sin dependencias resueltas NO SHALL recibir las de un
   proyecto cuyo nombre no case con ese prefijo.
6. **El acotado es por prefijo y no por identidad**, con la consecuencia que eso tiene: un
   repositorio `spm` SÍ recibe las de `spm-pro`. Ese límite SHALL estar declarado donde vive
   la resolución.

#### Scenario: Un repositorio sin dependencias en una máquina con otros proyectos

- **WHEN** el hook corre en un repositorio sin dependencias resueltas, en una máquina cuyo
  `DerivedData` tiene paquetes de proyectos cuyo nombre no empieza por el suyo
- **THEN** el digest no nombra ninguna dependencia

#### Scenario: Un proyecto vecino cuyo nombre empieza por el del repositorio

- **WHEN** el hook corre en un repositorio `spm` y la máquina tiene `DerivedData` de `spm-pro`
- **THEN** el digest todavía nombra las de `spm-pro`
- **AND** ese límite está declarado donde vive la resolución

#### Scenario: Un repositorio ajeno al kit

- **WHEN** una sesión pasa por un repositorio sin `kit.conf` ni `openspec/`
- **THEN** el hook inyecta su contexto
- **AND** no deja ningún fichero ni directorio nuevo en ese repositorio

#### Scenario: Dos proyectos con dependencias distintas

- **WHEN** el hook corre en un repositorio y después en otro con dependencias distintas, y
  ninguno de los dos nombres es prefijo del otro
- **THEN** cada uno recibe las suyas
- **AND** ninguno recibe las del otro

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

### Requirement: El hook declara el evento que lo ha invocado

El hook SHALL emitir en `hookSpecificOutput.hookEventName` el nombre del evento que lo
invoca.

1. Invocado por `UserPromptSubmit`, SHALL emitir `UserPromptSubmit`.
2. Invocado por `SessionStart`, SHALL emitir `SessionStart`.
3. Sin señal del evento invocante, SHALL emitir `UserPromptSubmit`, que es el caso mayoritario
   y el comportamiento de hoy.

El mismo script está registrado en los dos eventos, y la documentación de Claude Code exige que
ese campo sea el nombre del evento. La rama de `SessionStart(compact)` existe para reinyectar el
acuerdo **tras compactar**, que es cuando se pierde.

**Límite declarado:** que el efecto se aplique de verdad solo se ve compactando una sesión
real con el plugin instalado. Lo que se puede fijar aquí es la forma del JSON; el efecto vive
fuera de este repositorio.

#### Scenario: El hook invocado desde SessionStart

- **WHEN** el hook corre como hook de `SessionStart`
- **THEN** el JSON que emite declara `SessionStart` como `hookEventName`

#### Scenario: El hook invocado desde UserPromptSubmit

- **WHEN** el hook corre como hook de `UserPromptSubmit`
- **THEN** el JSON que emite declara `UserPromptSubmit`, igual que antes de este cambio
