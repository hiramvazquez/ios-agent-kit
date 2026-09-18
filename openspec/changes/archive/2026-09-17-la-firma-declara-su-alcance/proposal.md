## Why

La firma dice «verificado» y lo único que puede decir es «verificado con el toolchain de esta
máquina». Quien lee el verde —persona o agente— entiende lo primero, y con eso commitea y se va.

Medido, tres veces, en dos repositorios:

- **AppStarter tuvo `/kit-verifica` en verde con su CI en rojo doce corridas seguidas.** El
  último rojo (runs `35268191849` y `35284398983`, 2026-09-17) era una conformidad aislada que
  Swift 6.4 acepta y Swift 6.2.4 —el del CI, Xcode 26.3.0— rechaza. **Ninguna firma local puede
  verlo**: el toolchain del CI no compila en esta máquina.
- **En spm-pro pasó igual el 15 y el 16 de septiembre**: un `public import` sin uso y varios
  ficheros que usaban Foundation sin importarlo. Verdes en 6.4, error en 6.2.4.
- **Y el propio toolchain se puede equivocar en silencio**: el 15, el `swift` del PATH era el de
  swiftly (6.3.3) mientras Xcode traía 6.4, y el build moría en `build-tool plugin failures` sin
  compilar una sola línea. El diagnóstico no nombra el toolchain, así que se diagnosticó como un
  problema del código.

Hoy el marker guarda `verificado:`, `diff:`, `rama:` y `resultado:`. Nada dice con qué se corrió.
Y los proyectos que se han dado cuenta lo escriben a mano en un comentario de su `kit.conf`
—spm-pro tiene un bloque «LÍMITES DE ESTA FIRMA»—, pero un comentario no viaja a la firma: no lo
lee quien mira el verde, ni el digest, ni el informe.

Esto no arregla que local y CI comprueben cosas distintas. Arregla que la firma lo diga, que es
lo que evita confundir «pasó aquí» con «pasa».

## What Changes

- **El marker gana `toolchain:`**, con lo que el kit puede detectar por sí solo: la versión del
  `swift` del PATH, el Xcode seleccionado, y **si el `swift` del PATH y el de `xcrun` divergen**
  —la trampa del 15—.
- **El marker gana `limites:` cuando el proyecto los declara.** `kit.conf` puede definir una
  variable `LIMITES` con texto libre: qué NO cubre su firma. Opcional y no bloqueante; si no
  está, el informe dice que el proyecto no los declara.
- **Las cuatro superficies donde el kit afirma la verificación dejan de decir «verificado» a
  secas** y nombran el alcance: la línea final del informe, `--comprueba`, el digest que el kit
  inyecta en cada turno, y `/kit-estado`.
- **El `kit.conf` del propio kit declara sus `LIMITES`** —ya tiene uno escrito en un comentario,
  el de shellcheck—, para que la plantilla tenga un ejemplo vivo y no inventado.

Sin cambios en el contrato de salida (`0` verde · `1` rojo · `3` no pude mirar) y sin tocar la
puerta de commit.

## Capabilities

### New Capabilities

Ninguna.

### Modified Capabilities

- `verificacion-firmada`: gana un requisito nuevo — la firma declara el toolchain con el que
  corrió y los límites que el proyecto declare, y lo dice en las cuatro superficies donde el kit
  afirma la verificación. Los cuatro requisitos que ya tiene no cambian.

## Impact

| Fichero | Qué cambia |
|---|---|
| `scripts/verifica.sh` | detecta el toolchain, lee `LIMITES`, escribe las dos líneas en el marker y nombra el alcance al cerrar |
| `scripts/inyecta-contexto.sh` | la línea de verificación del digest nombra el toolchain de la firma |
| `scripts/estado.sh` | `/kit-estado` enseña el toolchain de la última firma |
| `scripts/verifica-salidas.sh` | banco: las dos líneas nuevas, y el aviso de divergencia |
| `scripts/verifica-contexto.sh` | banco: el digest con y sin firma |
| `plantillas/kit.conf.ejemplo` | documenta `LIMITES` como parte del contrato del proyecto |
| `commands/kit-verifica.md`, `docs/`, `README.md` | lo que describe la firma pasa a describir su alcance |
| `kit.conf` (del kit) | declara sus propios `LIMITES` |

Coste medido de la detección: **0,3 s** (`swift --version` 0,17 s · `xcrun swift --version`
0,13 s · `xcodebuild -version` 0,11 s), sobre verificaciones que hoy tardan entre 15 s y 90 s.

> *Corregido el 2026-09-17, tras el juicio.* Este desglose atribuía 0,004 s a `xcode-select -p`,
> que se midió al explorar y que la función **no llega a llamar**: el Xcode sale de
> `xcodebuild -version`. El total no cambia — el juez lo remidió en 0,31-0,32 s.

**Fuera de alcance**, y es deliberado:

- **Comparar automáticamente el toolchain local con el del CI.** Exigiría que el proyecto
  declarara una versión en `kit.conf`, y una cifra escrita ahí caduca sin que nadie la vuelva a
  medir. Lo que sí entra es que el proyecto declare sus límites en prosa.
- **Bloquear cuando el `swift` del PATH no es el de Xcode.** Se avisa; bloquear rompería a quien
  usa un toolchain de swift.org a propósito.
- **El agujero de la puerta de commit** (archivado en `la-puerta-ve-la-ruta-real`) y **el coste
  de volver a firmar tras anotar una tarea**. Los dos son decisiones aparte, con datos de hoy
  suficientes para proponerlas por separado.
