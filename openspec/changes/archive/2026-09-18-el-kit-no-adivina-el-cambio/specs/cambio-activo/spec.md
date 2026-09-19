## MODIFIED Requirements

### Requirement: Cuál es el cambio activo se resuelve en un solo sitio

La resolución de qué cambios OpenSpec están activos SHALL existir una sola vez en el código, y
todas las piezas que la necesitan SHALL usarla.

1. El resultado SHALL ser el mismo en dos invocaciones consecutivas sobre el mismo
   repositorio: la lista de cambios activos sale siempre en el mismo orden.
2. Con más de un cambio activo, la resolución NO SHALL designar ninguno como «el» activo:
   SHALL dar la lista y cuántos son. Una pieza que necesite uno SHALL recibirlo de quien la
   invoca, y si no lo recibe SHALL decirlo en vez de actuar sobre uno elegido por orden.
3. Con exactamente un cambio activo, ese SHALL ser «el» activo.
4. Con ningún cambio activo, SHALL seguir comportándose como hoy.

#### Scenario: Dos cambios activos a la vez

- **WHEN** una pieza del kit pregunta cuál es el cambio activo y hay dos
- **THEN** no recibe ninguno como «el» activo
- **AND** recibe los dos, siempre en el mismo orden, y que son dos

#### Scenario: Un solo cambio activo

- **WHEN** hay exactamente un cambio activo
- **THEN** el resultado es ese
