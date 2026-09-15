## Context

La motivación está en `proposal.md` — Why. Lo que condiciona el cómo, medido el 2026-09-14:

- `scripts/lib-kit.sh` es donde viven las piezas que comparten los scripts, y cada función lleva
  escrito por qué: la usan dos piezas, y copiarla ya se cobró un fallo. `/kit-estado` necesita tres
  cosas que hoy no están ahí: el recuento de tareas (dentro de `inyecta-contexto.sh`), la lista
  completa de cambios activos (`cambio_activo` solo deja el primero y cuántos hay) y la lectura de
  versiones (dentro de `verifica.sh`).
- `verifica.sh --comprueba` ya es el veredicto de la puerta de commit y tarda ~70 ms en AppStarter.
  Pero hace `mkdir -p .agent-kit` antes de mirar qué modo le piden.
- `busca-duplicados.py` sobre las fuentes de AppStarter tarda ~220 ms.
- El digest del hook lo fija `verifica-contexto.sh`, con los casos de cero tareas pendientes y de
  cambio sin `tasks.md`. `verifica-salidas.sh` fija los modos de `verifica.sh`, pero no el aviso de
  desfase: ningún banco ni spec lo cubre.
- La spec `raiz-de-trabajo` obliga a un script que invoca una persona a comprobar que la raíz se
  resolvió, no el `cd`.

## Goals / Non-Goals

**Goals:**

- Contestar en menos de 1 s en un proyecto real, sin escribir nada.
- Ninguna decisión nueva: cada línea de la salida la decide una pieza que ya existe o una función
  compartida.

**Non-Goals:**

- Salida para máquinas. La lee una persona o el modelo, y un formato estable sería un contrato más.
- Detectar de dónde se cargó el kit (instalado frente a directorio de desarrollo).

## Decisions

### 1. Un script, `scripts/estado.sh`, y un comando que solo lo invoca

Lo eligió el owner el 2026-09-14. Así le alcanzan los pasos de `kit.conf` que ya existen —`bash -n`,
`shellcheck` y las variables pegadas a un carácter no ASCII— sin escribir uno nuevo.

- *Modo `--estado` de `verifica.sh`:* descartado. El script de la firma haría dos trabajos.
- *Bash dentro del `.md` del comando:* descartado. Quedaría fuera de las tres comprobaciones que
  cazaron los fallos de bash 3.2 de este kit.

### 2. La firma se delega en `verifica.sh --comprueba`, y sus modos de lectura dejan de escribir

`estado.sh` imprime la línea de `--comprueba` tal cual, y añade `verificado:` y `resultado:` leídos
de la cabecera de `verificacion.txt`. En `verifica.sh`, el `mkdir -p` pasa a después del `case` de
modos: `--informe` y `--comprueba` ya manejan que el fichero no exista y no necesitan el directorio.

- *`huella_diff` y un `grep` dentro de `estado.sh`, como hace el hook:* descartado. Sería la
  tercera forma de decir si la firma vale, y la del hook ya no coincide con la de la puerta (ver
  Risks).

### 3. Cambios activos y tareas, a `lib-kit.sh`

- `cambio_activo` deja además `ACTIVOS`: las rutas de todos los cambios activos, una por línea, en
  el mismo orden estable que ya usa. Una cadena y no un array, porque expandir un array vacío bajo
  `set -u` aborta en bash 3.2, y la lib ya lo tiene escrito para `DD_PROPIO`.
- Función nueva `recuento_tareas <cambio>`: deja `TAREAS_HECHAS` y `TAREAS_TOTAL`, o las deja vacías
  si el cambio no tiene `tasks.md`. Se llama sin subshell, como `cambio_activo`. Se lleva con ella la
  nota del `grep -c … || true` que hoy está en el hook, que es la razón de que no se pueda reescribir
  de memoria.
- El hook pasa a usarla, con la salida igual. Lo comprueba su banco, y el criterio de aceptación lo
  compara byte a byte.

### 4. Versiones: `version_kit` en `lib-kit.sh`, con el consejo incluido

`version_kit <raíz-del-kit-que-corre>` deja `VER_CORRE`, `VER_INSTALADA`, `VER_CLON`, el directorio
del clon y `CONSEJO_VERSION`, que queda vacío cuando no hay nada que aconsejar.

- **La que corre:** el `.claude-plugin/plugin.json` de la raíz del kit desde la que se invocó el
  script, como hoy.
- **El clon:** el primer `~/.claude/plugins/marketplaces/*/` cuyo `plugin.json` tenga el mismo
  nombre, como hoy.
- **La instalada:** `~/.claude/plugins/installed_plugins.json`, entrada `<nombre>@<marketplace>`. Si
  hay varias entradas (ámbitos distintos), la de ámbito `user`, y si no, la primera. Se lee con
  `python3`, que el hook ya exige.
- El consejo sigue la tabla de la spec `estado-del-kit`, con los comandos escritos como
  `<nombre>@<marketplace>`, igual que en la doc.
- `verifica.sh` llama a `version_kit` y conserva lo único que es suyo: la consulta diaria al remoto
  del marketplace. Si el remoto va por delante del clon, sustituye el consejo por el de actualizar
  marketplace, plugin y conversación.
- *Leer la instalada con `claude plugin list`:* descartado. Arranca el CLI, tarda, y su salida está
  pensada para personas.

### 5. Duplicados: el detector entero, y solo su resumen

`estado.sh` carga `kit.conf` en un subshell para sacar `FUENTES` —con el mismo valor por defecto que
`verifica.sh`— y corre `busca-duplicados.py` **sin** `--tocados`, así que cuenta todos los grupos.
De la salida se queda con las líneas de resumen, las que empiezan por ✅, ❌ o ⚠️, y remite a
`/kit-duplicados` para la lista.

### 6. Git: una sola llamada, sin `fetch`

`git status --porcelain=v1 --branch` da rama, upstream, adelantados, atrasados y ficheros en una
pasada.

### 7. Raíz y código de salida

La raíz se resuelve como en `verifica.sh`: `RAIZ="$(git rev-parse --show-toplevel 2>/dev/null)" ||
{ …; exit 1; }`. Sale con 0 cuando ha podido mirar, y con 1 fuera de un repositorio git, como sus
hermanos.

## Risks / Trade-offs

- **[El resumen de duplicados depende del texto del detector]** → Si `busca-duplicados.py` cambia
  sus emojis, `/kit-estado` pierde esa línea sin avisar. Se acepta: un modo `--cuenta` sería un
  contrato más. Va declarado en la cabecera de `estado.sh`.
- **[`installed_plugins.json` es un fichero interno de Claude Code]** → Su forma puede cambiar. Si
  no se puede leer, `version_kit` compara la que corre con el clon, que es la cláusula 4 de la spec
  y lo que hacía el aviso hasta hoy.
- **[Cargar `kit.conf` ejecuta código del proyecto]** → El mismo límite que `/kit-duplicados` y
  `verifica.sh`, declarado en la spec.
- **[Sin banco]** → La salida de `estado.sh` no la comprueba nada salvo leerla. Lo que se mueve a la
  lib sí queda vigilado por los bancos del hook y de `verifica.sh`; `version_kit` no, igual que hoy
  no lo está su código. El criterio con `HOME` temporal lo mide una vez, a mano.
- **[Hallazgo de la planificación, fuera de este cambio]** → El digest dice «firmada contra el árbol
  actual» mirando solo la huella, así que tras una verificación en rojo sobre este árbol también dice
  «firmada». La puerta no se deja engañar, porque mira el resultado. Está en el «FUERA de alcance».
- **[Que corra una versión distinta de la instalada no siempre es una conversación reanudada]** →
  Cargando el kit desde un directorio de desarrollo también difieren, y el consejo no aplicaría. No
  se detecta: quien lo carga así sabe de dónde.

## Migration Plan

Nada que migrar. Un `verificacion.txt` ya escrito conserva el aviso viejo hasta la siguiente
verificación. Revertir es revertir el commit.
