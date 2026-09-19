# cambio-activo Specification

## Purpose

Que todas las piezas del kit hablen del **mismo** cambio: la pregunta «¿cuál es el cambio
activo?» la hacen el hook que inyecta el acuerdo en cada turno y la marca de revisión, y si cada
una la responde por su cuenta pueden responderse distinto sin que nada lo diga.

Lo que **no** pretende: elegir cuando hay varios. Nada dice cuál es el de la sesión, y una pieza
que actúa sobre uno elegido por su cuenta afirma cosas del acuerdo de otro. Lo que se exige es
que la lista sea **estable**, que quien pregunte sepa que hay más de uno, y que el cambio
concreto lo diga quien invoca.

## Requirements

### Requirement: Cuál es el cambio activo se resuelve en un solo sitio

La resolución de cuál es el cambio OpenSpec activo SHALL existir una sola vez en el código, y
todas las piezas que la necesitan SHALL usarla.

1. El resultado SHALL ser el mismo en dos invocaciones consecutivas sobre el mismo
   repositorio.
2. Con más de un cambio activo, la resolución SHALL decirlo en vez de elegir uno en silencio.
3. Con ningún cambio activo, SHALL seguir comportándose como hoy.

#### Scenario: Dos cambios activos a la vez

- **WHEN** una pieza del kit pregunta cuál es el cambio activo y hay dos
- **THEN** recibe siempre el mismo
- **AND** se le dice que hay más de uno

#### Scenario: Un solo cambio activo

- **WHEN** hay exactamente un cambio activo
- **THEN** el resultado es ese, igual que antes de este cambio
