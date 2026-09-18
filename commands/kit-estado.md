---
description: Cómo estamos — lo que queda sin guardar, los cambios activos, la firma, los duplicados y la versión del kit. Al instante, sin compilar.
allowed-tools: Bash
---

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/estado.sh"
```

Enseña la salida tal cual. No compila, no toca la red ni escribe en tu árbol, y tarda menos de un
segundo: úsalo cuando alguien pregunte en qué punto está, en vez de juntarlo a mano.

Reglas al leerla:

- **No es una puerta.** Sale con 0 aunque algo esté en rojo. Cada línea en rojo se arregla con su
  comando: la firma con `/kit-verifica`, los duplicados con `/kit-duplicados`.
- **«Sin empujar» y «sin traer» son respecto al último `fetch`.** Si importa, haz `git fetch`
  primero.
- **La línea de la firma dice su alcance**: con qué toolchain se verificó y si el proyecto
  declara límites. Sale incluso cuando la firma ya no vale, que es cuando se pregunta.
- **Si aconseja abrir una conversación nueva, es literal.** Una conversación reanudada puede seguir
  cargando la versión del kit con la que empezó, por mucho que ya haya otra instalada.
- **Lo que sí toca, dicho:** carga el `kit.conf` del proyecto para saber dónde buscar duplicados
  —en un repositorio clonado de fuera, eso es ejecutar código que no has leído—, y al comprobar la
  firma git puede refrescar la caché de su índice (`.git/index`). Por parte del kit, tu árbol y lo
  stageado no cambian.
