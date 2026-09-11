---
description: Verifica el proyecto (build, tests y lógica repetida) y firma el resultado contra el árbol que verificó.
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
- Stagea y verifica en comandos SEPARADOS del commit. Se firma el árbol **y** el índice, así
  que encadenar `git add && git commit` cambia el índice entre la firma y el commit, y la
  puerta lo rechazará con razón.
