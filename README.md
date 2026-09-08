# iOS Agent Kit

Trabajo con agentes sobre proyectos iOS, sin que el andamiaje se coma el proyecto.

Se apoya en [OpenSpec](https://github.com/Fission-AI/OpenSpec) para acordar qué se va a
construir **antes** de construirlo, y le añade lo que OpenSpec no trae y que en la práctica
hace falta: está en la tabla de aquí abajo, que es la que manda.

**En tu app acaban dos cosas:** la carpeta `openspec/` (que es tuya: son tus specs) y un
`kit.conf` corto. Nada más. Los agentes, los comandos, los hooks y los
scripts viven en el plugin, no en tu repo.

---

## Qué resuelve

| problema | pieza |
|---|---|
| El agente hace algo distinto de lo que se pidió, y nadie se entera hasta que un humano lo mira | **juez de aceptación** — compara lo entregado contra lo acordado, criterio por criterio, con evidencia |
| El agente escribe código correcto que rompe algo | **reviewer** — contexto fresco, una sola pregunta: ¿esto rompe algo? |
| Empieza bien y acaba repitiendo lógica que ya existía | **detector de duplicados** — el mismo cuerpo de función en dos ficheros |
| "Los tests pasan" dicho sobre un árbol que ya cambió | **verificación firmada** contra el `sha256` del diff staged |
| Se olvida de las reglas a mitad de sesión, o tras compactar | **inyección del acuerdo** en cada turno y tras cada compactación |

Y lo que **no** hace, dicho por delante: no impide que un modelo alucine, no obliga a nadie
a leer una skill, y no defiende contra alguien decidido a saltárselo (`--no-verify`, otra
terminal). Frena el **error de proceso**, que es el fallo real y el más caro.

---

## Puesta en marcha

### Una vez por máquina

```bash
npm install -g @fission-ai/openspec@latest     # necesita Node
```

**Dentro de una sesión de Claude Code** — es la forma normal, y la única que necesitas:

```
/plugin marketplace add hiramvazquez/ios-agent-kit
/plugin install ios-agent-kit
```

Reinicia la sesión después: los plugins se cargan al arrancar.

<details>
<summary>La misma operación desde la terminal (equivalente, útil para guiones y CI)</summary>

```bash
claude plugin marketplace add hiramvazquez/ios-agent-kit
claude plugin install ios-agent-kit@hiram-kits -y
claude plugin details ios-agent-kit      # el inventario de piezas, contado por el CLI
claude plugin list                       # Status ✔ enabled
```

Es la forma con la que está verificada la instalación de este kit, porque un agente no
puede teclear comandos de barra: los escribe el humano.
</details>

**Todo el trabajo del día a día es con comandos de barra dentro de Claude Code**
(`/opsx:propose`, `/kit-verifica`, `/kit-acepta`…). La terminal solo hace falta para
instalar, actualizar y diagnosticar.

Coste: lo que quede siempre activo por sesión te lo dice ese mismo `plugin details`; la
medición fechada está en [PIEZAS.md](docs/PIEZAS.md#coste) y aquí no se copia, que es como
se acabó teniendo el mismo número en tres sitios y uno de ellos viejo. Lo estructural sí se
puede decir sin número: los agentes y comandos solo cuestan cuando se invocan, y los hooks
corren fuera del contexto del modelo, así que no cuestan nada.

### Una vez por proyecto

```
/kit-init
```

Mira el repo —qué paquetes hay, qué comandos de build y test— y deja montado:

- `openspec/` con `openspec init`, en español,
- `kit.conf` con **los comandos reales de tu proyecto**,
- `openspec/config.yaml` con las reglas (criterios de aceptación obligatorios, etc.),
- `.agent-kit/` en el `.gitignore`.

Termina corriendo `/kit-verifica`. Si no sale verde a la primera, el `kit.conf` está mal y
se arregla ahí mismo.

---

## El día a día

```
/opsx:propose "lo que quieras construir"   →  proposal + delta de spec + tareas. CERO código.
/opsx:apply                                →  se implementa, marcando tareas
/kit-revisa                                →  ¿esto rompe algo? UNA TAREA, no el cambio entero
/kit-verifica                              →  build, tests y duplicados, firmado
/kit-acepta                                →  ¿es lo acordado? criterio por criterio
/opsx:archive                              →  el delta se funde en la spec viva
```

Los dos últimos pasos antes de archivar son distintos **a propósito**: un cambio puede
estar impecable —arquitectura, tests, lint— y no ser lo que se pidió. El reviewer no lo ve
porque no es su pregunta.

### El caso que lo justifica

El juez de aceptación se estrenó contra un cambio que compilaba, pasaba 144 tests y tenía
el linter de arquitectura en verde. Lo devolvió **ACUERDO-ROTO**: había hecho exactamente
lo que su propio "Fuera de alcance" prohibía. Era necesario hacerlo — y ese es justo el
momento de renegociar el acuerdo por escrito, no de seguir porque es obvio. No lo veía
nada de lo que ya había.

---

## Qué acaba dentro de tu proyecto

```
tu-app/
├── openspec/          ← tuyo: specs, cambios activos y archivados
│   ├── specs/<dominio>/spec.md
│   ├── changes/<cambio>/{proposal,tasks}.md + specs/
│   └── config.yaml    ← las reglas del proyecto
├── kit.conf           ← qué verifica este proyecto y dónde vive el código
└── .agent-kit/        ← firma de verificación (gitignored)
```

Y nada más. Si algún día desinstalas el plugin, lo que queda es documentación tuya que
sigue teniendo sentido sin él.

### `kit.conf`

```bash
FUENTES="App Packages"

verificaciones() {
    paso "Platform · build"  bash -c 'cd Packages/Platform && swift build'
    paso "Platform · tests"  bash -c 'cd Packages/Platform && swift test'
}
```

Cada `paso` lleva un nombre legible y un comando. Si alguno sale distinto de 0, no hay
firma y la puerta de commit no deja pasar.

---

## Qué trae el plugin

| | |
|---|---|
| `agents/aceptacion.md` | juez de aceptación |
| `agents/reviewer.md` | revisor de corrección |
| `skills/swift-swiftui/` | reglas de Swift/SwiftUI, adaptadas de [SwiftAgents](https://github.com/twostraws/SwiftAgents) de Paul Hudson, con las que exigen iOS 26 marcadas aparte |
| `commands/` | `/kit-init`, `/kit-verifica`, `/kit-duplicados`, `/kit-doc`, `/kit-revisa`, `/kit-acepta` |
| `hooks/hooks.json` | los tres hooks |
| `scripts/` | lo que ejecutan los hooks y los comandos, dos libs compartidas, y los bancos de pruebas `verifica-*.sh`. No hay uno por pieza: los tiene la puerta, el hook de contexto, el detector de duplicados, la rodaja y la propia verificación — `autocomprueba.sh` sigue sin banco, y su punto ciego dejó pasar una invocación muerta durante las diez versiones publicadas. `ls scripts/` los lista; escribirlos aquí era un inventario a mano y ya se había quedado corto |

### Para mejorar el kit

```bash
bash scripts/autocomprueba.sh          # ANTES de publicar. Comprueba lo que el CLI rechaza
# sube la versión en .claude-plugin/plugin.json, commit y push
claude plugin marketplace update hiram-kits
claude plugin update ios-agent-kit@hiram-kits    # `install` NO actualiza: dice "ya instalado"
claude plugin list                                # Status ✔ enabled, con la versión nueva
```

Los proyectos que lo usan no tocan nada, salvo que cambie el contrato de `kit.conf`.

### Los tres hooks

| evento | qué hace |
|---|---|
| `UserPromptSubmit` | inyecta el acuerdo vigente y las tareas pendientes, en cada turno |
| `SessionStart(compact)` | lo reinyecta tras compactar, que es cuando se pierde |
| `PreToolUse` | **bloquea** un commit sin firma de verificación válida |

El digest que se inyecta empieza diciendo **de qué repositorio habla**, y no es un adorno:
el plugin se instala para el usuario, no para un proyecto, así que el hook lee el
repositorio del directorio que hereda la sesión — que no tiene por qué ser aquel en el que
estás trabajando. Nombrarlo no elimina ese desfase (no hay ninguna señal de dónde trabaja
el modelo, y adivinarla sería peor que callarse), pero convierte «sin cambio activo» —falso
sobre el trabajo en curso— en «en este repositorio, sin cambio activo», que es cierto. Un
repositorio sin `openspec/` recibe además eso mismo dicho, en vez de la orden de abrir una
propuesta que allí nadie puede seguir. Y el hook no escribe nada dentro del repositorio que
observa: su caché vive en `~/.cache/ios-agent-kit`, con la ruta del repositorio en la clave.

`PreToolUse` es el único evento de Claude Code capaz de bloquear. Por eso es el único
hook que bloquea aquí: no por diseño elegante, por lo que la herramienta permite.

La puerta juzga **el repositorio al que va el commit**, no el directorio desde el que corre
la sesión: analiza la invocación y sigue la pista de un `-C`, un `--git-dir` o un `cd`
encadenado por delante. Y se desentiende de los repositorios sin `kit.conf` — ahí no hay
flujo que proteger, y exigir una firma que `verifica.sh` tampoco puede crear allí dejaría el
commit sin salida.

Sigue la pista también cuando el `cd` va agrupado —`(cd X && …)`, `{ cd X && …; }`— o
envuelto en un `bash -c '…'`. Esa lista no es de adorno: la primera versión decía «un `cd`
encadenado por delante» a secas y era **falsa**, porque el primer token del segmento era `(`
y el `cd` no se registraba. Lo encontró un juez de aceptación con el banco en verde.

Lo que **no** frena, dicho porque un límite que no se declara se convierte en una promesa
falsa: `--no-verify`, un commit desde otra terminal, y una invocación construida en tiempo
de ejecución (`$CMD`, un alias, un `eval`), que cae al directorio heredado. Frena el olvido,
y el olvido tiene formas comunes. Los casos que sí cubre están fijados en
`scripts/verifica-puerta.sh`, que imprime cuántos son — aquí no se escribe el número, que
es como se acabó diciendo «diez» donde el banco decía once.

---

## La regla que impide que esto crezca

La tentación, cuando algo se escapa, es hacer **la lista de todo lo que hay que vigilar** y
escribir un detector por línea. Esa lista es infinita. Un workflow anterior de esta casa
llegó a 36.740 líneas en nueve semanas por ese camino, y sus propias métricas decían que
sus detectores mecánicos hacían 1.279 corridas con **cero hallazgos**, mientras el revisor
—que solo tiene una pregunta abierta— encontraba cosas reales.

Así que cada cosa que se escapa se clasifica antes de reaccionar:

| ¿quién podía haberlo visto? | dónde va |
|---|---|
| El compilador, SwiftLint, el linter de arquitectura | ya está cubierto — **no añadas nada** |
| Es mecánico y ningún linter lo ve | detector propio, **solo si ya falló dos veces** |
| Solo se ve leyendo con criterio | **se mejora la pregunta** del revisor o del juez, no se escribe código |

Y el orden importa: **primero se mejora la pregunta, después se escribe el detector.**
Cambiar una línea de un prompt cuesta una línea; un detector cuesta un script, su test y su
mantenimiento para siempre.

Hoy hay **un solo** detector propio, el de duplicados, y está porque esa clase ya mordió
tres veces: tres `extension Date` en tres view models distintos, cada una correcta por
separado.

---

## Documentación

| | |
|---|---|
| [**El flujo completo**](docs/FLUJO.md) | de una tarea de Jira a un commit, paso a paso. **Empieza por aquí** |
| [Instalación](docs/INSTALACION.md) | paso a paso, con los errores reales y cómo salir de ellos |
| [Tu primer cambio](docs/PRIMER-CAMBIO.md) | el bucle completo sobre un caso de verdad, con el formato de las specs |
| [Las piezas](docs/PIEZAS.md) | qué hace cada una, cuándo se dispara, y **qué no hace** |

## Requisitos

- Claude Code
- Node (para el CLI de OpenSpec)
- Un proyecto iOS con git

## Licencia

MIT
