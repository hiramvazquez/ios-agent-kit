---
description: Verifica el proyecto (build, tests y lógica repetida) y firma el resultado contra el árbol que verificó, diciendo con qué toolchain y qué no cubre.
allowed-tools: Bash
---

Ejecuta la verificación del proyecto y firma el resultado:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/verifica.sh"
```

Reglas al leer la salida:

- Si algún paso sale en rojo, **no commitees**: arréglalo y vuelve a verificar. La firma
  solo vale para el árbol exacto que había cuando se generó.
- Si sale el aviso de **lógica repetida**, míralo antes de seguir. No bloquea, pero si el
  duplicado lo ha añadido este cambio, es tuyo y toca resolverlo ahora — es mucho más caro
  después.
- Se firma el árbol **y** el índice: stagear después de firmar invalida la firma. Stagea
  antes de verificar, y commitea después, sin encadenar el `add` con el commit. La razón está
  en `docs/PIEZAS.md`, en la sección de `verifica.sh`.
