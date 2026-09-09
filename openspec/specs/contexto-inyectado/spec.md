# contexto-inyectado Specification

## Purpose

Poner el acuerdo delante del modelo en cada turno, corto y atribuido. Contra la deriva no
sirve obligar a leer una skill: el modelo cree que se acuerda y no relee. Lo que sirve es que
el texto esté delante otra vez, siempre.

«Atribuido» es la mitad que costó aprender. El hook lee el repositorio del directorio que
hereda la sesión, que no tiene por qué ser aquel en el que se trabaja, y un digest que
describe otro repositorio empuja exactamente en la dirección contraria a la que fue puesto.
Nombrarlo NO elimina ese desfase —no hay señal disponible de dónde trabaja el modelo, y
adivinarla sería peor que callarse—, pero convierte «sin cambio activo», falso sobre el
trabajo en curso, en «en este repositorio, sin cambio activo», que es cierto.

Y no escribe nada dentro del repositorio que observa: corre en toda sesión del usuario,
también en repositorios que nunca pidieron el kit.

## Requirements

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

Las cláusulas 5 y 6 sustituyen a una 5 que prometía un absoluto —«NO SHALL recibir las de
otro proyecto de la misma máquina»— que el acotado por prefijo rompe. Reproducido el
2026-09-08: un repositorio `spm`, sin dependencias propias, recibía `PaqueteDelVecino` desde
`spm-pro-555444`.

**Por qué se corrige aquí y no en otro cambio.** Este es el que hizo que las dos piezas
compartan la MISMA función y el que decidió declarar sus límites como canon. Archivarlo
dejando la norma del hermano diciendo lo contrario sobre la misma función es, literalmente, el
defecto que este cambio persigue — «la regla que llegó a un fichero y no a su hermano»— cometido
en la capa del acuerdo.

Se corrigieron una por una todas las instancias que se fueron encontrando, y aun así esta se
escapó dos rondas seguidas —y con ella el escenario de aquí abajo, dentro del arreglo—, porque
el criterio que las buscaba estaba escrito en términos **léxicos** («que ningún documento diga que falla hacia
el lado seguro») mientras lo que protege es **semántico**: que ningún documento prometa una
garantía de acotado que el código no da. Este no dice esa frase; dice algo más fuerte y más
falso. Es el hueco léxico-semántico que el prompt del juez de aceptación ya tiene escrito como
la trampa más fina de los censos, aplicada a una promesa en vez de a un número.

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
2. El digest producido SHALL ser el mismo que antes de este cambio, salvo lo que exija la
   cláusula de los cambios activos múltiples.

Este hook corre en cada turno de cualquier repositorio por el que pase una sesión, así que un
temporal de nombre adivinable en un directorio escribible por cualquiera es un riesgo
innecesario para lo que hace: componer tres líneas de texto. Es además la extensión natural
de la regla que este mismo hook ya cumple —no escribir dentro del repositorio observado— al
único sitio donde todavía escribe.

#### Scenario: El hook compone el digest con tareas pendientes

- **WHEN** el hook corre en un repositorio con un cambio activo y tareas sin cerrar
- **THEN** el digest sale igual que antes
- **AND** no queda ningún fichero nuevo en el directorio temporal del sistema

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
