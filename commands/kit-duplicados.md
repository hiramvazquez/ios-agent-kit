---
description: Busca lógica repetida — el mismo cuerpo de función escrito en dos sitios.
allowed-tools: Bash
---

```bash
bash -c 'source kit.conf 2>/dev/null; python3 "${CLAUDE_PLUGIN_ROOT}/scripts/busca-duplicados.py" ${FUENTES:-App Sources Packages}'
```

Lo que encuentre no es automáticamente un error: dos cuerpos idénticos pueden ser
coincidencia legítima. Lo que sí es seguro es que **nadie los había mirado juntos**. Para
cada grupo, decide: extraer a un sitio común, o dejarlo con una razón.

Úsalo **antes** de escribir una función nueva, no solo al final. El caso que motivó esto
fueron tres `extension Date` en tres view models distintos, cada una escrita en una semana
distinta, todas correctas por separado.
