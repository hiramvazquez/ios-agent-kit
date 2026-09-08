# Instalación

Todo lo de aquí está ejecutado y verificado, incluidos los errores. Si algo no te sale, mira
[Cuando algo falla](#cuando-algo-falla) antes de tocar nada.

## 1. Node y el CLI de OpenSpec — una vez por máquina

El kit se apoya en [OpenSpec](https://github.com/Fission-AI/OpenSpec), que es un CLI de npm.

```bash
brew install node                              # si no lo tienes
npm install -g @fission-ai/openspec@latest
openspec --version                             # 1.12.0 o superior
```

Sin esto el kit funciona a medias: los scripts y los agentes van, pero no tienes
`/opsx:propose`, ni validación de specs, ni archivado automático — que es la mitad del valor.

## 2. El plugin — una vez por máquina

**La forma normal es dentro de una sesión de Claude Code**, escribiendo:

```
/plugin marketplace add hiramvazquez/ios-agent-kit
/plugin install ios-agent-kit
```

Y reiniciar la sesión: los plugins se cargan al arrancar.

**La terminal hace lo mismo** y es la forma con la que está verificado este kit (un agente
no puede teclear comandos de barra — los escribe el humano). Sirve además para guiones y
para CI:

```bash
claude plugin marketplace add hiramvazquez/ios-agent-kit
claude plugin install ios-agent-kit@hiram-kits -y
claude plugin list          # debe decir: Status ✔ enabled
```

Elige una; no hay diferencia en el resultado.

Comprueba qué quedó instalado:

```bash
claude plugin details ios-agent-kit
```

Ese comando inventaría las piezas —skills, agentes y hooks— y dice cuántos tokens quedan
siempre activos por sesión. Los números salen de ahí y **no se escriben aquí**: un inventario
copiado a un documento caduca en el momento de escribirse, y este llegó a quedarse corto sin
que nadie se enterara. La tabla de coste, con su fecha, está en
[PIEZAS.md](PIEZAS.md#coste).

Lo que sí conviene saber sin correr nada: lo caro se paga al invocarlo, no por estar
instalado, y los hooks no cuestan contexto porque corren fuera del modelo.

## 3. Tu proyecto — una vez por proyecto

Con Claude Code abierto en la raíz del proyecto:

```
/kit-init
```

Mira el repo antes de escribir nada —qué paquetes hay, qué comandos de build y test— y deja:

| qué | dónde | qué es |
|---|---|---|
| `openspec/` | raíz | tus specs y tus cambios. **Tuyo**, no del kit |
| `kit.conf` | raíz | qué verifica este proyecto y dónde vive el código |
| `openspec/config.yaml` | dentro de `openspec/` | las reglas: criterios de aceptación obligatorios, etc. |
| `.agent-kit/` en `.gitignore` | raíz | la firma de verificación es estado local |

Termina con `/kit-verifica`. **Si no sale verde a la primera, el `kit.conf` está mal** — y
ese es el momento de arreglarlo, no la primera vez que alguien intente commitear.

### Si prefieres hacerlo a mano

```bash
openspec init --tools claude --language es
cp "$(claude plugin details ios-agent-kit | grep -o '/.*ios-agent-kit')/plantillas/kit.conf.ejemplo" kit.conf
printf '\n.agent-kit/\n' >> .gitignore
$EDITOR kit.conf          # pon los comandos reales de tu proyecto
```

## Cuando algo falla

**`Status: ✘ failed to load`** — `claude plugin list` te dice el motivo exacto. Los dos que
me encontré montando esto: `plugin.json` declarando rutas que ya son las de por defecto, y
`hooks.json` con los eventos fuera del objeto `hooks`. Los dos están corregidos; si te sale
con una versión tuya modificada, el mensaje del CLI nombra la clave concreta.

**`kit.conf` no encontrado** — `verifica.sh` sale con **3**, no con 1. Es deliberado: "no
pude mirar" no es lo mismo que "está mal". Créalo con `/kit-init`.

**`Unknown command: /opsx:apply`** (o `/opsx:propose`, o `/opsx:archive`), mientras los
`/kit-*` sí funcionan — **la sesión está abierta en el directorio equivocado**. Ábrela en la
raíz del repositorio, no un nivel por encima.

Los dos juegos de comandos vienen de sitios distintos y por eso fallan por separado, que es
lo que despista:

| comandos | de dónde vienen | dónde funcionan |
|---|---|---|
| `/kit-verifica`, `/kit-acepta`… | del **plugin**, instalado para tu usuario | desde cualquier directorio |
| `/opsx:propose`, `/opsx:apply`… | de `.claude/commands/` **del proyecto**, que instala `openspec init` | solo si la sesión tiene ese repo como raíz |

Con la sesión un nivel por encima te queda medio flujo funcionando y la otra mitad
respondiendo «Unknown command», que no dice nada de la causa. Los ficheros están donde tienen
que estar; simplemente nadie los ha cargado.

**La puerta bloquea un commit que crees válido** — la firma es de OTRO diff. Pasa siempre
por lo mismo: encadenar `git add && git commit`. Stagea, verifica y commitea en **tres
comandos separados**; entre la firma y el commit el diff no puede cambiar.

**`openspec list --specs` dice `requirements 0`** — tu spec es prosa que el parser no
reconoce. Necesita `### Requirement:` con "SHALL" y `#### Scenario:` con WHEN/THEN. Está
explicado en [PRIMER-CAMBIO.md](PRIMER-CAMBIO.md).

**No aparecen los comandos `/kit-*`** — reinicia la sesión de Claude Code. Los plugins se
cargan al arrancar.

**`Agent type 'reviewer' not found`** — lo mismo, y el síntoma engaña porque no es que el
agente no aparezca: es que **falla al invocarlo**. Los sub-agentes del plugin tampoco
existen en una sesión que ya estaba abierta cuando se instaló. Reinicia.

## Actualizar

Cuando el kit cambie:

```bash
claude plugin marketplace update hiram-kits       # trae el repo nuevo
claude plugin update ios-agent-kit@hiram-kits     # instala la versión nueva
```

**`claude plugin install` NO actualiza** — si ya está instalado responde "ya instalado" y
se queda con la versión vieja, sin avisar de que hay otra. El comando es `update`.
Reinicia la sesión para que cargue.

Los proyectos que usan el kit no tocan nada, salvo que cambie el contrato de `kit.conf`.

## Desinstalar

```bash
claude plugin uninstall ios-agent-kit@hiram-kits
claude plugin marketplace remove hiram-kits
```

En tu proyecto quedan `openspec/` y `kit.conf`. El primero es documentación tuya que sigue
teniendo sentido sin el kit; el segundo es un fichero corto que puedes borrar.
