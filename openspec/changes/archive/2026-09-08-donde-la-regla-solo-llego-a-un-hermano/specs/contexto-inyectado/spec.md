# contexto-inyectado — delta

## MODIFIED Requirements

### Requirement: El contexto inyectado dice de qué repositorio habla

El hook que inyecta el acuerdo en cada turno SHALL atribuir lo que afirma al repositorio
del que lo ha leído, y SHALL producirlo entero sea cual sea el estado de las tareas.

1. El digest SHALL nombrar ese repositorio, incluso cuando no haya nada que contar sobre él.
2. Un repositorio sin `openspec/` SHALL producir un digest que lo diga, y que NO ordene
   abrir una propuesta.
3. Un repositorio con `openspec/` SHALL producir el mismo digest que producía antes de
   este cambio, **salvo las líneas de atribución que exige la cláusula 1**.
4. Con un cambio activo y **cero** tareas pendientes, el digest SHALL incluir la línea de
   recuento de tareas y el bloque «FUERA de alcance», y el hook NO SHALL escribir nada en
   la salida de error.

La 4 es nueva y no es un detalle de formato. `grep -c` imprime `0` **y** sale con 1, así que
el idiom `$(grep -c … || echo 0)` deja `"0\n0"`; en bash 3.2 —el de macOS, el que resuelve
`#!/usr/bin/env bash`— un error de expansión aritmética aborta **el compound entero**, no solo
su línea. El resultado es que el digest pierde en silencio el recuento, la lista de
pendientes y el «fuera de alcance», que es una de las tres reglas innegociables que este hook
existe para inyectar.

Y lo pierde exactamente cuando el cambio está terminado, que es el turno en que se llama al
juez y se commitea: el momento en que esa regla más manda. El banco no lo veía porque su
fixture monta siempre **una** tarea pendiente. El mismo `grep -c` está escrito bien —con
`|| true`, que no imprime nada— en `rodaja.sh`, dos ficheros más allá.

#### Scenario: Un cambio con todas las tareas cerradas

- **WHEN** el hook corre en un repositorio cuyo cambio activo no tiene tareas pendientes
- **THEN** el digest dice cuántas tareas hay hechas
- **AND** incluye el bloque «FUERA de alcance»
- **AND** el hook no escribe nada en la salida de error

#### Scenario: Un repositorio que no usa OpenSpec

- **WHEN** el hook corre en un repositorio sin `openspec/`
- **THEN** el digest nombra ese repositorio
- **AND** dice que no usa OpenSpec
- **AND** no ordena abrir una propuesta

#### Scenario: Un repositorio con OpenSpec y sin cambio activo

- **WHEN** el hook corre en un repositorio con `openspec/` y ningún cambio activo
- **THEN** el digest dice lo mismo que decía antes de este cambio
- **AND** lo atribuye a ese repositorio

### Requirement: El hook no escribe en repositorios que no usan el kit

El hook SHALL evitar crear ficheros o directorios dentro de un repositorio que no dé
señales de usar el kit, y las dependencias que anuncia SHALL ser las de ese repositorio.

1. Tras correr sobre un repositorio sin `kit.conf` ni `openspec/`, el estado de git SHALL
   quedar igual que antes.
2. El caché que hoy vive en `.agent-kit/` SHALL vivir fuera del repositorio observado.
3. Dos repositorios distintos SHALL tener cachés distintos.
4. El caché SHALL seguir evitando el recorrido de `DerivedData` en turnos consecutivos.
5. La búsqueda de dependencias SHALL acotarse al repositorio observado. Un repositorio sin
   dependencias resueltas NO SHALL recibir las de otro proyecto de la misma máquina.

La 5 es la mitad que faltaba de la 3, y sin ella la 3 no sirve de nada. Se arregló el
**almacenamiento** —un fichero de caché por repositorio, comprobado por el banco— y no la
**consulta**: el `find` recorre todo `~/Library/Developer/Xcode/DerivedData` sin filtrar, así
que los cachés son distintos y su contenido es idéntico. Medido el 2026-09-08: el digest del
propio `ios-agent-kit` —que tiene **cero** ficheros `.swift`— anunciaba `AppFoundation` y
`CoreNetworking`, que son de `AppStarter` y `DemoMulti`; un repositorio vacío recién creado
recibía la misma frase.

Es exactamente el fallo que la 3 declara peor que el que arreglaba, «porque el dato
equivocado parecería correcto», reintroducido por la puerta de al lado. El banco no lo veía
porque fija `HOME` a un temporal vacío: su caso de aislamiento pasaba por el fixture, no por
el código.

#### Scenario: Un repositorio sin dependencias en una máquina con otros proyectos

- **WHEN** el hook corre en un repositorio sin dependencias resueltas, en una máquina cuyo
  `DerivedData` tiene paquetes de otros proyectos
- **THEN** el digest no nombra ninguna dependencia

#### Scenario: Un repositorio ajeno al kit

- **WHEN** una sesión pasa por un repositorio sin `kit.conf` ni `openspec/`
- **THEN** el hook inyecta su contexto
- **AND** no deja ningún fichero ni directorio nuevo en ese repositorio

#### Scenario: Dos proyectos con dependencias distintas

- **WHEN** el hook corre en un repositorio y después en otro con dependencias distintas
- **THEN** cada uno recibe las suyas
- **AND** ninguno recibe las del otro

## ADDED Requirements

### Requirement: El hook declara el evento que lo ha invocado

El hook SHALL emitir en `hookSpecificOutput.hookEventName` el nombre del evento que lo
invoca.

1. Invocado por `UserPromptSubmit`, SHALL emitir `UserPromptSubmit`.
2. Invocado por `SessionStart`, SHALL emitir `SessionStart`.
3. Sin señal del evento invocante, SHALL emitir `UserPromptSubmit`, que es el caso mayoritario
   y el comportamiento de hoy.

El mismo script está registrado en los dos eventos y emite `UserPromptSubmit` siempre. La
documentación de Claude Code exige que ese campo sea el nombre del evento, así que la rama de
`SessionStart(compact)` está anunciando un contrato que no es el suyo — y esa rama existe para
reinyectar el acuerdo **tras compactar**, que es cuando se pierde, y es una de las cinco
promesas de cabecera del `README`.

**Límite declarado:** que el efecto se aplique de verdad solo se ve compactando una sesión
real con el plugin instalado. Lo que se puede fijar aquí es la forma del JSON; el efecto vive
fuera de este repositorio.

#### Scenario: El hook invocado desde SessionStart

- **WHEN** el hook corre como hook de `SessionStart`
- **THEN** el JSON que emite declara `SessionStart` como `hookEventName`

#### Scenario: El hook invocado desde UserPromptSubmit

- **WHEN** el hook corre como hook de `UserPromptSubmit`
- **THEN** el JSON que emite declara `UserPromptSubmit`, igual que antes de este cambio
