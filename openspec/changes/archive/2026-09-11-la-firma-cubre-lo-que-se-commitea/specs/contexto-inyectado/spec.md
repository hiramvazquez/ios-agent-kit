# Contexto inyectado — delta

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
5. El bloque «FUERA de alcance» SHALL reconocerse **sea cual sea la caja de su cabecera**:
   `## Fuera de alcance` y `## FUERA de alcance` SHALL dar el mismo resultado.
6. Un cambio activo **sin `tasks.md`** NO SHALL producir la línea de recuento de tareas, y SHALL
   seguir produciendo el resto del digest.

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

La 5 y la 6 salen de la auditoría del 2026-09-11. Las dos hacen lo mismo por dos puertas: el
digest afirma algo falso y nadie se entera. Con la cabecera en mayúsculas —3 de las 16
propuestas de este repositorio, incluida la activa— el «fuera de alcance» desaparecía sin decir
nada, que es la clase de fallo silencioso que la cláusula 4 ya cerró por el otro lado. Y sin
`tasks.md` —lo que `docs/FLUJO.md` recomienda para un cambio pequeño— el digest decía
`tareas: 0/0 hechas`, que se lee como «no queda nada por hacer» cuando lo cierto es que ese
cambio no lleva lista.

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

#### Scenario: Un repositorio que no usa OpenSpec

- **WHEN** el hook corre en un repositorio sin `openspec/`
- **THEN** el digest nombra ese repositorio
- **AND** dice que no usa OpenSpec
- **AND** no ordena abrir una propuesta

#### Scenario: Un repositorio con OpenSpec y sin cambio activo

- **WHEN** el hook corre en un repositorio con `openspec/` y ningún cambio activo
- **THEN** el digest dice lo mismo que decía antes de este cambio
- **AND** lo atribuye a ese repositorio
