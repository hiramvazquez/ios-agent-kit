## Context

Ver `proposal.md` — Why. Lo que condiciona el cómo:

- `cambio_activo` (`scripts/lib-kit.sh`) deja `ACTIVO`, `ACTIVOS` y `ACTIVOS_N`. Con varios,
  `ACTIVO` es el primero por `LC_ALL=C sort`. Lo consumen `inyecta-contexto.sh` y `rodaja.sh`;
  `estado.sh` solo usa la lista y el recuento.
- `rodaja.sh --entregado <ruta>` ya acepta la ruta, la valida (existe, tiene `proposal.md`) y
  calcula el principio del cambio: el commit anterior al que introdujo su `proposal.md`, o
  `HEAD` si la propuesta aún no está commiteada.
- La marca es un objeto de `git stash create` —un commit cuyo primer padre es el `HEAD` de
  cuando se marcó— o, si no había nada que guardar, el propio `HEAD`.
- El hook no recibe nada que diga en qué cambio trabaja la sesión, y corre en cada turno: lo
  que haga tiene que ser barato y corto.

## Goals / Non-Goals

**Goals:**

- Que ninguna pieza actúe sobre un cambio elegido por orden.
- Que la rodaja mida el cambio que se revisa, con lo que ya sabe calcular el script.

**Non-Goals:**

- Un estado nuevo, por sesión o por repositorio, que recuerde «el cambio de la sesión».
- Tocar lo que ve el juez.

## Decisions

### 1. `ACTIVO` se vacía en la lib cuando hay varios, no en cada consumidor

La resolución vive en un solo sitio, y ahí se quita el defecto: `cambio_activo` rellena
`ACTIVO` solo si `ACTIVOS_N` es 1. Arreglarlo en los consumidores dejaría la variable
cargada para el siguiente que la lea sin mirar el recuento. El orden estable se conserva,
porque la lista sigue saliendo y se enseña.

### 2. El hook, con varios: nombres y una frase

```
· Cambios activos: 2 — el acuerdo de esta sesión es el del cambio en el que trabajas; léelo en su carpeta.
    - el-ci-fija-el-xcode-con-el-que-prueba (1/11)
    - los-snapshots-fijan-su-locale (0/9)
```

Hasta cinco nombres, y «… y N más» detrás: el digest se paga en cada turno. Un cambio sin
`tasks.md` sale sin paréntesis, igual que hoy no lleva línea de recuento.

Alternativa descartada por el owner (2026-09-18): inferir el cambio de la sesión de qué
carpeta de `openspec/changes/` tiene ficheros sin commitear. Acierta desde la primera tarea
marcada y falla antes, y es una heurística nueva con su banco.

### 3. `rodaja.sh`: la ruta vale en todos los modos, y sin ella no se elige

`rodaja.sh [<ruta>]`, `rodaja.sh --revisada [<ruta>]`, `rodaja.sh --entregado [<ruta>]`. El
bloque que hoy valida la ruta de `--entregado` sube para servir a los tres. Sin ruta: el
único activo; ninguno activo, como hoy; varios, nombra, pide la ruta y sale con 1, antes de
imprimir nada y antes de mover la marca.

Parar y no avisar: el aviso ya existía y no bastó. `/kit-revisa` y `agents/aceptacion.md`
siempre conocen la ruta, así que el único que se encuentra la parada es quien lo lanza a mano.

`--reinicia` no necesita cambio: borra la marca.

### 4. Un solo «principio del cambio», y la marca se compara contra él

Lo que hoy calcula `--entregado` se usa también para la rodaja. Llamémoslo SUELO.

```
DESDE = MARCA   si SUELO es ancestro de MARCA   (git merge-base --is-ancestor SUELO MARCA)
DESDE = SUELO   si no
```

Comprobado el 2026-09-18 sobre los objetos reales de AppStarter: con SUELO `ec117fa`, la
marca de la prueba (`576c959`, stash sobre `fafee38`) da «es ancestro» y se usa; la marca
vieja (`41ed19c`) da «no» y se usa el suelo. Una marca que ya no tiene relación con la rama
—tras un rebase— también da «no», que es el lado seguro.

**Sin suelo, la marca se respeta.** Con la propuesta aún sin commitear el principio no se
conoce. La primera versión tomaba `HEAD` de suelo, y la ronda de revisión reprodujo lo que
eso rompe: un commit del propio cambio hecho tras la marca quedaba por debajo de ese suelo
móvil, la marca se descartaba, el commit no salía, y el `--revisada` siguiente lo enterraba.
La regla de arriba solo se aplica con `SUELO` conocido. Lo que se pierde a cambio: en ese
flujo una marca vieja sigue inflando la parte de código de la rodaja (161 líneas en lo
medido, no 12); la planificación sigue fuera por la decisión 5.

El suelo es el commit **anterior** al de la propuesta, no el de la propuesta: si propuesta y
código entran en el mismo commit —lo habitual en AppStarter— el de la propuesta ya lleva
código. Que así entren también los ficheros de planificación lo resuelve la decisión 5.

### 5. `openspec/changes/` fuera de la rodaja, con un pathspec

`git diff "$DESDE" -- . ':!openspec/changes'`, y el bucle de ficheros nuevos se salta las
rutas bajo `openspec/changes/`, como ya se salta `.claude/`. Solo en modo rodaja.

Se excluye `openspec/changes/` y no `openspec/` entero: `openspec/specs/` es el contrato
vigente y un cambio ahí sí merece ojos. En la medición eran 43 líneas de 1742.

Lo que el revisor deja de ver: que alguien reescriba el acuerdo para que encaje. Eso es lo
que pregunta el juez, no el revisor («¿esto rompe algo?»), y las tareas cerradas siguen
saliendo en su lista.

## Risks / Trade-offs

- **[Código commiteado sin revisar antes de que el cambio empezara deja de entrar en ninguna
  rodaja]** → es el comportamiento buscado y va como límite declarado en la spec y en la
  cabecera de `rodaja.sh`. La alternativa medida es que todo entre en todas: 1742 líneas para
  revisar 12.
- **[Con varios cambios abiertos, el digest pierde tareas y «fuera de alcance»]** → límite
  declarado. El caso común es un cambio activo, y ese no cambia.
- **[Un script o un hábito que llame a `rodaja.sh` sin ruta con varios abiertos se para]** →
  sale con un mensaje que nombra los cambios y enseña la orden con ruta.
- **[Los bancos exigen hoy lo contrario]** → el caso «elige el primero por orden estable» de
  `verifica-contexto.sh` se reescribe en el mismo commit que la lib; si no, el kit no firma.
