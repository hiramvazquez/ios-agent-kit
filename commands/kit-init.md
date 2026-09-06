---
description: Prepara este proyecto para el kit — kit.conf, OpenSpec y las reglas del proyecto.
allowed-tools: Bash, Read, Write, Edit, Glob, Grep
---

Prepara ESTE proyecto. Son cuatro pasos y ninguno se hace a ciegas: mira el repo antes de
escribir nada.

## 1. OpenSpec

```bash
command -v openspec >/dev/null || echo "FALTA: npm install -g @fission-ai/openspec@latest"
[ -d openspec ] || openspec init --tools claude --language es
```

Si falta el CLI, dilo y para. Es la dependencia del kit y no se sustituye a mano.

## 2. `kit.conf` — el único fichero que el kit necesita del proyecto

Descúbrelo, no lo supongas:

- `find . -name Package.swift -not -path "*/.build/*"` → qué paquetes hay y dónde.
- `ls *.xcodeproj *.xcworkspace project.yml 2>/dev/null` → si hay app de Xcode.
- Mira si ya existe un script de build/test del proyecto antes de inventar comandos.

Escribe `kit.conf` en la raíz con `${CLAUDE_PLUGIN_ROOT}/plantillas/kit.conf.ejemplo` como
base, con **los comandos reales de este proyecto**. Y luego **corre `/kit-verifica`**: si
no sale verde a la primera, el conf está mal y hay que arreglarlo ahora, no la primera vez
que alguien intente commitear.

## 3. Estado local fuera de git

```bash
grep -q '^\.agent-kit/' .gitignore 2>/dev/null || printf '\n# Firma de verificación del kit: estado local, ligado a un diff\n.agent-kit/\n' >> .gitignore
```

## 4. Las reglas del proyecto, en `openspec/config.yaml`

Ese fichero es el punto de extensión de OpenSpec y sobrevive a `openspec update`, así que
las reglas van ahí y no en otro documento que haya que recordar. Usa
`${CLAUDE_PLUGIN_ROOT}/plantillas/openspec-config.yaml.ejemplo` y **rellena el `context`
con lo de este proyecto**: módulos, capas, dónde vive la lógica, qué linter manda.

Si el repo ya tiene `AGENTS.md` o `CLAUDE.md`, **no los dupliques**: cítalos desde el
`context` y deja que sigan mandando ellos.

## Al terminar

Di en tres líneas qué ha quedado montado, qué comando verifica el proyecto, y cuál es el
siguiente paso real: `/opsx:propose "<lo que quieras construir>"`.
