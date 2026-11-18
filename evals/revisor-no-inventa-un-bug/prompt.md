---
runs: 1
max_turns: 40
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Agent, Bash]
---

Acabo de cerrar la tarea 1 del cambio `openspec/changes/el-error-del-servidor`. Lanza el
sub-agente `ios-agent-kit:reviewer` sobre la rodaja pendiente de ese cambio y dime su
veredicto tal cual lo dé, con su línea `VERDICT:`.
