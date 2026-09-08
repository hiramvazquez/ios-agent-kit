# cambio-activo Specification

## Purpose

Que todas las piezas del kit hablen del **mismo** cambio. La pregunta «¿cuál es el cambio
activo?» la hacen el hook que inyecta el acuerdo en cada turno y la marca de revisión, y si
cada una la responde por su cuenta pueden responderse distinto sin que nada lo diga.

Lo que **no** pretende: elegir bien cuando hay varios. Cuál es «el» activo entre dos sigue
siendo arbitrario; lo que se exige es que sea arbitrario y **estable**, y que quien pregunte
pueda decir que hay más de uno en vez de callárselo.

## Requirements

### Requirement: Cuál es el cambio activo se resuelve en un solo sitio

La resolución de cuál es el cambio OpenSpec activo SHALL existir una sola vez en el código, y
todas las piezas que la necesitan SHALL usarla.

1. El resultado SHALL ser el mismo en dos invocaciones consecutivas sobre el mismo
   repositorio.
2. Con más de un cambio activo, la resolución SHALL decirlo en vez de elegir uno en silencio.
3. Con ningún cambio activo, SHALL seguir comportándose como hoy.

Hoy la misma expresión está copiada en tres sitios y las tres eligen con `head -1` sobre un
`find`, que es el orden del sistema de ficheros: no determinista. Con dos cambios abiertos, el
digest puede hablar de uno mientras la marca de revisión copia las tareas del otro, sin que
nada lo diga.

Es además el único duplicado real que la auditoría del 2026-09-08 encontró en los 11 scripts,
y el que ya se cobró un defecto: la regla que el propio kit inyecta en cada turno —«antes de
escribir una función, busca si ya existe»— se escribió mientras esto se copiaba por tercera
vez.

#### Scenario: Dos cambios activos a la vez

- **WHEN** una pieza del kit pregunta cuál es el cambio activo y hay dos
- **THEN** recibe siempre el mismo
- **AND** se le dice que hay más de uno

#### Scenario: Un solo cambio activo

- **WHEN** hay exactamente un cambio activo
- **THEN** el resultado es ese, igual que antes de este cambio
