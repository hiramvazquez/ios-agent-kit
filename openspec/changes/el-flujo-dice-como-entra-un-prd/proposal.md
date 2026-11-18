# El flujo dice cómo entra un PRD

## Why

`docs/FLUJO.md` cuenta el flujo partiendo de un ticket de una línea. Cuando lo que hay es un
PRD —un documento escrito con calma antes de empezar— no dice dónde va, cómo se le pasa al
`propose` ni qué relación tiene con el acuerdo, y la duda natural es si hay que pegarlo entero
o si sustituye a la propuesta.

## What Changes

- `docs/FLUJO.md` gana una sección sobre cómo se trabaja a partir de un PRD, y el paso 0 la
  señala.

## Fuera de alcance

- Cualquier plantilla de PRD, comando o comprobación nueva: el kit no lee el PRD, lo lee el
  agente al proponer.
- El resto de la documentación.

## Criterios de aceptación

- [x] La sección SHALL decir dónde se guarda el PRD, cómo se le pasa al `propose` y que el
      kit vigila la propuesta y no el PRD.
- [x] SHALL decir cuándo un PRD son varios cambios y cuándo no hace falta PRD.
- [x] `scripts/verifica.sh` SHALL seguir en verde.
