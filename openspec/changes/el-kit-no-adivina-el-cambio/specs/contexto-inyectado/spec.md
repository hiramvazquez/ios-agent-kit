## ADDED Requirements

### Requirement: Con varios cambios activos, el digest no afirma el acuerdo de ninguno

Con más de un cambio OpenSpec activo, el hook no tiene forma de saber cuál es el de la sesión.
El digest SHALL nombrarlos todos y NO SHALL presentar como acuerdo vigente el contenido de
ninguno.

1. El digest SHALL decir cuántos cambios activos hay y SHALL nombrar cada uno con su recuento
   de tareas, en orden estable.
2. El digest NO SHALL incluir tareas pendientes ni el bloque «FUERA de alcance» de ninguno de
   ellos, y SHALL decir que el acuerdo de la sesión es el del cambio en el que se trabaja.
3. La lista SHALL seguir siendo corta: a partir de cierto número de cambios, SHALL nombrar los
   primeros y decir cuántos quedan sin nombrar.
4. Con exactamente un cambio activo, el digest NO SHALL cambiar.

**Límite declarado.** Con varios cambios abiertos el digest deja de recordar en cada turno qué
queda por hacer y qué está fuera de alcance. Es el precio de no afirmar lo de otro: quien
trabaja con varios abiertos lee el acuerdo de su cambio en su carpeta.

#### Scenario: Dos cambios activos

- **WHEN** el hook corre en un repositorio con dos cambios activos
- **THEN** el digest nombra los dos, con las tareas hechas y totales de cada uno
- **AND** no contiene tareas pendientes ni «FUERA de alcance» de ninguno
- **AND** dice que el acuerdo de la sesión es el del cambio en el que se trabaja

#### Scenario: El «FUERA de alcance» de un cambio nombra la tarea de otro

- **WHEN** hay dos cambios activos y el «Fuera de alcance» de uno menciona justo lo que el otro
  arregla
- **THEN** el digest no pone ese texto delante de quien trabaja en el otro

#### Scenario: Un solo cambio activo

- **WHEN** el hook corre en un repositorio con un solo cambio activo
- **THEN** el digest lleva su recuento, sus tareas pendientes y su «FUERA de alcance», como hoy
