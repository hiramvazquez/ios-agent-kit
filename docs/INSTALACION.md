# Instalación

Instalar, actualizar, desinstalar, y qué hacer cuando algo falla. El flujo de trabajo está en
[FLUJO.md](FLUJO.md); qué hace cada pieza, en [PIEZAS.md](PIEZAS.md).

## 1. Node y el CLI de OpenSpec — una vez por máquina

```bash
brew install node                              # si no lo tienes
npm install -g @fission-ai/openspec@latest
openspec --version                             # 1.12.0 o superior
```

Sin esto no tienes `/opsx:propose`, ni validación de specs, ni archivado.

## 2. El plugin — una vez por máquina

Dentro de una sesión de Claude Code:

```
/plugin marketplace add hiramvazquez/ios-agent-kit
/plugin install ios-agent-kit
```

Y reinicia la sesión: los plugins se cargan al arrancar. Desde la terminal es lo mismo, y
sirve para guiones y CI:

```bash
claude plugin marketplace add hiramvazquez/ios-agent-kit
claude plugin install ios-agent-kit@hiram-kits -y
claude plugin list          # debe decir: Status ✔ enabled
```

## 3. Tu proyecto — una vez por proyecto

Con Claude Code abierto en la raíz del proyecto:

```
/kit-init
```

Mira el repo antes de escribir nada y deja:

| qué | dónde | qué es |
|---|---|---|
| `openspec/` | raíz | tus specs y tus cambios. **Tuyo**, no del kit |
| `kit.conf` | raíz | qué verifica este proyecto y dónde vive el código |
| `openspec/config.yaml` | dentro de `openspec/` | las reglas: criterios de aceptación obligatorios, etc. |
| `.agent-kit/` en `.gitignore` | raíz | la firma de verificación es estado local |

Termina con `/kit-verifica`. Si no sale verde a la primera, el `kit.conf` está mal, y ese es el
momento de arreglarlo.

### Si prefieres hacerlo a mano

Las plantillas viven en el clon del marketplace, no en tu proyecto. `hiram-kits` es el nombre
con el que lo añadiste; si usaste otro, cámbialo aquí.

```bash
KIT=~/.claude/plugins/marketplaces/hiram-kits

openspec init --tools claude --language es
cp "$KIT/plantillas/kit.conf.ejemplo" kit.conf
cp "$KIT/plantillas/openspec-config.yaml.ejemplo" openspec/config.yaml
printf '\n.agent-kit/\n' >> .gitignore

$EDITOR kit.conf               # pon los comandos reales de tu proyecto
$EDITOR openspec/config.yaml   # rellena el `context` con módulos, capas y reglas
```

Son dos plantillas, no una: el segundo `cp` pisa el `config.yaml` que acaba de generar
`openspec init`, y eso es lo que se quiere.

## Cuando algo falla

**`Status: ✘ failed to load`** — `claude plugin list` te dice el motivo exacto. Los dos
clásicos: `plugin.json` declarando rutas que ya son las de por defecto, y `hooks.json` con los
eventos fuera del objeto `hooks`. `bash scripts/autocomprueba.sh` los caza antes de publicar.

**`kit.conf` no encontrado** — `verifica.sh` sale con **3**, no con 1: «no pude mirar» no es
lo mismo que «está mal». Créalo con `/kit-init`.

**`Unknown command: /opsx:apply`** (o `/opsx:propose`, o `/opsx:archive`), mientras los
`/kit-*` sí funcionan — **la sesión está abierta en el directorio equivocado**. Ábrela en la
raíz del repositorio, no un nivel por encima. Los dos juegos de comandos vienen de sitios
distintos y por eso fallan por separado:

| comandos | de dónde vienen | dónde funcionan |
|---|---|---|
| `/kit-verifica`, `/kit-acepta`… | del **plugin**, instalado para tu usuario | desde cualquier directorio |
| `/opsx:propose`, `/opsx:apply`… | de `.claude/commands/` **del proyecto**, que instala `openspec init` | solo si la sesión tiene ese repo como raíz |

**La puerta bloquea un commit que crees válido** — la firma es de otro árbol. Casi siempre es
por encadenar `git add && git commit`: se firma el árbol **y** el índice, así que stagear
después de firmar cambia lo firmado. Stagea, verifica y commitea por separado (la razón, en
[PIEZAS.md](PIEZAS.md#verificash--la-firma)).

**`openspec list --specs` dice `requirements 0`** — tu spec es prosa que el parser no
reconoce. Necesita `### Requirement:` con SHALL y `#### Scenario:` con WHEN/THEN. El formato
está en [FLUJO.md](FLUJO.md#el-delta-de-spec-en-el-formato-del-cli).

**No aparecen los comandos `/kit-*`** — reinicia la sesión de Claude Code. Los plugins se
cargan al arrancar.

**`Agent type 'reviewer' not found`** — lo mismo, y el síntoma engaña porque el agente no es
que no aparezca: es que falla al invocarlo. Los sub-agentes del plugin tampoco existen en una
sesión que ya estaba abierta cuando se instaló. Reinicia.

## Actualizar

Cuando el kit cambie:

```bash
claude plugin marketplace update hiram-kits       # trae el repo nuevo
claude plugin update ios-agent-kit@hiram-kits     # instala la versión nueva
```

`claude plugin install` **no** actualiza: si ya está instalado responde «ya instalado» y se
queda con la versión vieja. El comando es `update`.

Después, abre una conversación nueva: una reanudada puede seguir cargando la versión con la
que empezó. `/kit-estado` avisa si la conversación va desfasada y dice qué hacer.

Los proyectos que usan el kit corren `/kit-verifica` una vez tras actualizar: es lo que
refresca la puerta de commit del repositorio.

## Desinstalar

```bash
claude plugin uninstall ios-agent-kit@hiram-kits
claude plugin marketplace remove hiram-kits
```

En tu proyecto quedan `openspec/` y `kit.conf`, y fuera de git `.agent-kit/` y el hook
`.git/hooks/pre-commit`. El primero es documentación tuya que sigue teniendo sentido sin el
kit. Borra `kit.conf` y el hook se abre solo; para no dejar rastro, borra también
`.agent-kit/` y `.git/hooks/pre-commit`.
