# El revisor se prueba con un bug sembrado

## Why

`kit.conf` declara como límite que los `agents/` y `commands/` son markdown y nadie comprueba
que hagan lo que dicen. Es el hueco por el que entraron los fallos más caros del kit: un juez
que leía un diff vacío, un prompt que citaba un script que no existía. Los bancos prueban los
scripts; a los agentes no los prueba nada.

Claude Code trae ahora `claude plugin eval`: corre el plugin en una sesión aislada contra un
caso —un prompt y unas comprobaciones sobre lo que pasó— y dice si pasa.

## What Changes

- Nace `evals/` con dos casos para el revisor, sobre el mismo repositorio de juguete:
  - con un bug sembrado —el indicador de carga no se apaga en el camino de error—, el revisor
    tiene que dar RED;
  - con el mismo cambio bien hecho, no puede dar RED.
- `docs/PIEZAS.md` dice cómo se corre y qué cuesta, y el límite de `kit.conf` deja de decir
  que a los agentes no los prueba nada.

## Fuera de alcance

- Meter el eval en `verificaciones()`: gasta llamadas al modelo y no da siempre lo mismo, así
  que no puede ser condición para commitear. Se corre a mano antes de publicar un cambio en
  los prompts.
- Evals para el juez de aceptación, los comandos y la skill.
- El brazo sin plugin: sin el plugin no existe el revisor, así que no hay nada que comparar.

## Límite declarado

Un eval verde dice que el revisor cazó ESTE bug en las corridas que se hicieron; no que cace
los demás. Y lo que se prueba incluye el modelo, que cambia sin que el kit cambie.

Añadido al implementar: en el sandbox del eval `git` no arranca en macOS, así que `rodaja.sh`
falla y el revisor reconstruye el diff a mano. Los dos casos prueban su juicio sobre un cambio,
no la rodaja. Se vio leyendo las trazas de la segunda corrida.

## Criterios de aceptación

- [x] `claude plugin eval` SHALL correr los dos casos y los dos SHALL pasar, con el revisor
      del kit lanzado en ambos.
- [x] El caso del bug SHALL fallar si el revisor no da RED, y el de control SHALL fallar si
      lo da. Comprobado mirando los veredictos de la corrida, no solo la nota.
- [x] Los resultados de las corridas NOT SHALL entrar en git.
- [x] `scripts/verifica.sh` SHALL seguir en verde con `evals/` dentro del repositorio.
