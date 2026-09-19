# iOS Agent Kit

Trabajo con agentes sobre proyectos iOS, sin que el andamiaje se coma el proyecto.

Se apoya en [OpenSpec](https://github.com/Fission-AI/OpenSpec) para acordar qué se va a
construir **antes** de construirlo, y le añade lo que OpenSpec no trae y que en la práctica
hace falta.

**En tu app acaban dos cosas:** la carpeta `openspec/` (que es tuya: son tus specs) y un
`kit.conf` corto. Los agentes, los comandos, los hooks y los scripts viven en el plugin.

## Qué resuelve

| problema | pieza |
|---|---|
| El agente hace algo distinto de lo que se pidió, y nadie se entera hasta que un humano lo mira | **juez de aceptación** — compara lo entregado contra lo acordado, criterio por criterio, con evidencia |
| El agente escribe código correcto que rompe algo | **reviewer** — contexto fresco, una sola pregunta: ¿esto rompe algo? |
| Empieza bien y acaba repitiendo lógica que ya existía | **detector de duplicados** — el mismo cuerpo de función en dos ficheros |
| «Los tests pasan» dicho sobre un árbol que ya cambió | **verificación firmada** contra el `sha256` del árbol que se verificó, y una **puerta de commit** que la exige |
| «Verificado» leído como «esto pasa», cuando solo pasó aquí | la firma **declara su alcance**: con qué toolchain corrió y qué no cubre |
| Se olvida de las reglas a mitad de sesión, o tras compactar | **inyección del acuerdo** en cada turno y tras cada compactación |

Lo que **no** hace: no impide que un modelo alucine, no obliga a nadie a leer una skill, y no
defiende contra alguien decidido a saltárselo; qué deja abierto la puerta de commit está en
[PIEZAS.md](docs/PIEZAS.md#la-puerta-de-commit--un-hook-de-git). Frena el **error de
proceso**, que es el fallo real y el más caro.

## Puesta en marcha

Una vez por máquina, con Node instalado:

```bash
npm install -g @fission-ai/openspec@latest
```

Y dentro de una sesión de Claude Code:

```
/plugin marketplace add hiramvazquez/ios-agent-kit
/plugin install ios-agent-kit
```

Reinicia la sesión: los plugins se cargan al arrancar. La misma operación desde la terminal,
los errores conocidos y cómo actualizar están en [INSTALACION.md](docs/INSTALACION.md).

Una vez por proyecto, con la sesión abierta en la raíz del repositorio:

```
/kit-init
```

Mira el repo —qué paquetes hay, qué comandos de build y test— y deja `openspec/`, un
`kit.conf` con los comandos reales del proyecto, las reglas en `openspec/config.yaml` y
`.agent-kit/` en el `.gitignore`. Termina corriendo `/kit-verifica`: si no sale verde a la
primera, el `kit.conf` está mal y se arregla ahí mismo.

## El día a día

```
/opsx:propose "lo que quieras construir"   →  proposal + delta de spec + tareas. CERO código.
/opsx:apply                                →  se implementa, marcando tareas
/kit-verifica                              →  build, tests y duplicados, firmado
/kit-revisa                                →  ¿esto rompe algo? una tarea, no el cambio entero
/kit-acepta                                →  ¿es lo acordado? opcional; cuándo, lo dice él
/opsx:archive                              →  el delta se funde en la spec viva
```

Los dos jueces preguntan cosas distintas a propósito: un cambio puede estar impecable
—arquitectura, tests, lint— y no ser lo que se pidió. El obligatorio antes de archivar es el
revisor. El paso a paso, con un caso real, está en [FLUJO.md](docs/FLUJO.md).

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

Si algún día desinstalas el plugin, lo que queda es documentación tuya que sigue teniendo
sentido sin él. `kit.conf` es esto:

```bash
FUENTES="App Packages"
LIMITES="- El CI compila con otro Xcode: lo que solo falla ahí no lo ve esta firma."   # opcional
verificaciones() {
    paso "Platform · build"  bash -c 'cd Packages/Platform && swift build'
    paso "Platform · tests"  bash -c 'cd Packages/Platform && swift test'
}
```

Cada `paso` lleva un nombre legible y un comando; si alguno sale distinto de 0, no hay firma
y la puerta de commit —un hook `pre-commit` de git que la propia verificación instala— no deja
pasar. `LIMITES` viaja en la firma: lo lee quien mira el verde.

## Qué trae el plugin

| | |
|---|---|
| `agents/aceptacion.md` | juez de aceptación |
| `agents/reviewer.md` | revisor de corrección |
| `skills/swift-swiftui/` | reglas de Swift/SwiftUI, adaptadas de [SwiftAgents](https://github.com/twostraws/SwiftAgents) de Paul Hudson, con las que exigen iOS 26 marcadas aparte |
| `commands/` | `/kit-init`, `/kit-verifica`, `/kit-duplicados`, `/kit-doc`, `/kit-revisa`, `/kit-acepta`, `/kit-estado` |
| `hooks/hooks.json` | dos hooks: el que inyecta el acuerdo en cada turno y el que lo reinyecta tras compactar. La puerta de commit no es un hook de Claude Code: es un hook `pre-commit` de git que instala `/kit-verifica` |
| `scripts/` | lo que ejecutan los hooks y los comandos, dos libs compartidas, y los bancos de pruebas `verifica-*.sh` |

Qué hace cada pieza, cuándo se dispara y **qué no hace** está en [PIEZAS.md](docs/PIEZAS.md).

### Para mejorar el kit

```bash
bash scripts/autocomprueba.sh          # ANTES de publicar: comprueba lo que el CLI rechaza
# sube la versión en .claude-plugin/plugin.json, commit y push
```

Con auto-update activado para `hiram-kits`, Claude Code trae la versión nueva solo y
`/reload-plugins` la carga; la vía manual está en
[INSTALACION.md](docs/INSTALACION.md#actualizar). `/kit-estado` dice qué versión corre.

## La regla que impide que esto crezca

La tentación, cuando algo se escapa, es hacer la lista de todo lo que hay que vigilar y
escribir un detector por línea. Esa lista es infinita, y los detectores mecánicos acaban
corriendo miles de veces con cero hallazgos mientras el revisor —que solo tiene una pregunta
abierta— encuentra cosas reales. Así que cada cosa que se escapa se clasifica antes de
reaccionar:

| ¿quién podía haberlo visto? | dónde va |
|---|---|
| El compilador, SwiftLint, el linter de arquitectura | ya está cubierto — **no añadas nada** |
| Es mecánico y ningún linter lo ve | detector propio, **solo si ya falló dos veces** |
| Solo se ve leyendo con criterio | **se mejora la pregunta** del revisor o del juez, no se escribe código |

Primero se mejora la pregunta, después se escribe el detector: cambiar una línea de un prompt
cuesta una línea; un detector cuesta un script, su banco y su mantenimiento para siempre. Hoy
hay un solo detector propio, el de duplicados.

Y la otra deriva, más difícil de ver porque cada paso parece responsable: se recibe un
hallazgo, se arregla, y **el arreglo abre el siguiente**. Lo que la corta no es otra regla
mecánica: presupuestar las rondas antes de empezar, parar y archivar con la deuda escrita, y
preferir restar. Por eso el digest de cada turno lleva la regla en una línea: «un hallazgo se
arregla en su causa y restando: no es motivo para un fichero nuevo».

## Documentación

| | |
|---|---|
| [**El flujo completo**](docs/FLUJO.md) | de una tarea a un commit, paso a paso, con un caso real. **Empieza por aquí** |
| [Instalación](docs/INSTALACION.md) | instalar, actualizar, desinstalar, y qué hacer cuando algo falla |
| [Las piezas](docs/PIEZAS.md) | qué hace cada una, cuándo se dispara, y **qué no hace** |

## Requisitos

- Claude Code
- Node (para el CLI de OpenSpec)
- Un proyecto iOS con git

## Licencia

MIT
