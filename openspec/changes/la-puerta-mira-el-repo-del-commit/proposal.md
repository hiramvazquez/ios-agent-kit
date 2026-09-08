# La puerta mira el repo del commit, no el directorio de la sesión

## Why

`puerta-commit.sh` decide sobre **el repo del cwd heredado**, no sobre el repo al que va el
commit, y reconoce un commit por subcadena:

```bash
cd "$(git rev-parse --show-toplevel 2>/dev/null)" || exit 0
case "$CMD" in *"git commit"*) ;; *) exit 0 ;; esac
```

Eso la rompe de tres formas. Las tres se observaron el 2026-09-07 en una sesión real, con el
cwd en `spm-pro` y el trabajo en `AppStarter`.

**1. Deja pasar lo que debía frenar.** `git -C <ruta> commit` no contiene la subcadena, así
que el `case` no casa y el hook sale por `exit 0` sin comprobar nada. No es una forma
esotérica: es la forma natural de commitear en otro repo. Dos commits entraron así ese día.
Que además estuvieran verificados fue suerte, no diseño — la puerta ni se enteró.

**2. Frena lo que debía dejar pasar.** Con el cwd en otro repo, `cd $(git rev-parse
--show-toplevel)` entra en el repo equivocado, no encuentra firma —está en el otro— y
bloquea con «No hay verificación firmada para este diff». El mensaje describe un problema
que no existe, y la reacción natural, volver a verificar, no arregla nada.

**3. Frena texto que no es un comando.** El `case` casa contra la cadena entera, así que
cualquier comando que MENCIONE esas dos palabras queda bloqueado: escribir documentación
sobre la puerta, un `grep`, un `echo`. Se descubrió intentando escribir este mismo fichero
con un heredoc: la puerta bloqueó la propuesta que la arregla.

**4. Se impone a repositorios que no usan el kit, y ahí no tiene salida.** El plugin se
instala con `scope: user` y sin `projectPath`, así que sus hooks corren en TODAS las
sesiones, en cualquier repositorio. En uno que no usa el kit, la puerta exige una firma que
no existe y bloquea el commit; pero `verifica.sh` no puede producirla, porque aborta antes
con «falta kit.conf en la raíz del proyecto» (línea 47). **El commit queda bloqueado sin
salida desde dentro del kit.** `spm-pro` es el caso real: no tiene `kit.conf` ni
`openspec/`, no participa del flujo, y aun así cualquier commit desde una sesión de Claude
Code allí está bloqueado.

El 2 es molesto y el 3 es cómico. El **1** y el **4** son los que importan, por razones
opuestas: el 1 deja pasar lo que debía frenar; el 4 frena lo que nunca debió mirar. Y la
cabecera del script declara sus límites con precisión —`--no-verify`, otra terminal, «un git
invocado de otra forma»— sin mencionar ninguno de los dos.

## What Changes

- `puerta-commit.sh` deriva el repo **del comando interceptado** cuando el comando lo dice
  (`git -C <ruta>`, `--git-dir`, o un `cd <ruta>` que preceda al commit en la misma línea), y
  solo cae al cwd cuando el comando no dice nada.
- Reconocer «esto es un commit» deja de ser una subcadena: pasa a mirar la invocación real,
  de modo que `git -C … commit` entre y una mención en texto no.
- La puerta SHALL desentenderse de los repositorios que no usan el kit: sin `kit.conf`, no
  hay flujo que proteger y no hay firma que se pueda producir, así que no se exige ninguna.
- Los `exit 0` que hoy dejan pasar en silencio se revisan uno a uno. Cada uno queda con
  escrito al lado si falla abierto o cerrado, y por qué.
- La cabecera del script y la parte del README que describe la puerta se reescriben con los
  límites que queden de verdad. Un límite que se estrecha se reescribe; no se borra.

### La decisión de diseño que este cambio toma

Un hook `PreToolUse` no sabe dónde va a ejecutarse el comando: ve el texto y hereda un cwd
que puede no tener relación. Tres salidas.

**Ignorar el cwd y exigir que el comando diga siempre el repo** — descartada: rompe el caso
normal, que es un commit a secas en el repo de la sesión, y es la inmensa mayoría.

**Ejecutar el comando en seco para averiguar el repo** — descartada: un hook no puede
ejecutar lo que está juzgando.

**Leer el repo del comando cuando el comando lo diga, y caer al cwd cuando no** — la que se
toma. Cubre las dos formas reales sin tocar el caso normal.

Su coste, dicho para que sea decisión y no descuido: el análisis es sintáctico y no cubre
toda forma imaginable de invocar git; una invocación suficientemente retorcida seguirá
cayendo al cwd. Es aceptable **si queda escrito** en la cabecera: la puerta frena el olvido,
y el olvido tiene formas comunes, no retorcidas.

### La señal de que un repositorio usa el kit

`kit.conf` en la raíz, y no otra cosa. Es el fichero que `/kit-init` escribe, el que
`verifica.sh` exige para poder firmar, y el kit ya lo trata como su única dependencia del
proyecto. Sin él no hay verificación posible, luego no hay nada que la puerta pueda exigir.

`openspec/` NO sirve como señal: un repositorio puede usar OpenSpec sin usar este kit —de
hecho el kit se apoya en OpenSpec precisamente porque son cosas separadas—, y la firma que
la puerta vigila no depende de OpenSpec para nada.

Lo que este criterio NO hace, para que no se lea de más: un repositorio CON `kit.conf` y sin
firma sigue bloqueado. Eso no es el bug, eso es la puerta.

## Fuera de alcance

- **`inyecta-contexto.sh`, que tiene el mismo defecto** (líneas 13, 44 y 55). Con el cwd en
  otro repo inyecta el acuerdo del repo equivocado: durante toda la sesión del 2026-09-07
  afirmó «Sin cambio OpenSpec activo» mientras el repo donde se trabajaba tenía uno activo.
  Es el mismo bug y merece su propio cambio: ahí no hay comando del que inferir nada, así
  que la decisión de diseño es otra y no debe colarse de rebote en esta.
- `verifica.sh`, `rodaja.sh` y `doc-paquetes.sh`, que resuelven la raíz igual. Los invoca
  una persona o un comando y admiten un `cd` delante; no corren solos.
- Cerrar `--no-verify` u otras vías deliberadas. La cabecera ya declara que no pretende
  frenar a quien decide saltárselas, y eso sigue igual.

## Criterios de aceptación

- [ ] Un commit dirigido con `-C` a otro repo SIN firma válida SHALL ser bloqueado. Hoy
      pasa. Fijado por una prueba que falla contra el script actual.
- [ ] Un commit dirigido con `-C` a otro repo CON firma válida para su diff staged SHALL
      pasar.
- [ ] Un `cd`/`pushd <otro-repo>` seguido de commit SHALL comportarse igual que los dos
      anteriores, **también agrupado** —`(cd X && …)`, `{ cd X && …; }`— y **envuelto** en
      un `bash -c '…'`. Añadido en la renegociación del 2026-09-08: la redacción anterior
      decía «`cd <otro-repo> && …`» y se cumplía solo en su forma desnuda, mientras la
      cabecera del script afirmaba cubrir «un `cd` encadenado por delante» a secas.
- [ ] Un commit a secas en el repo de la sesión SHALL comportarse exactamente como hoy:
      verde si hay firma, bloqueo si no. Es el caso que no puede romperse.
- [ ] Un comando que solo MENCIONA las palabras sin invocar git —un `echo`, un `grep`, un
      heredoc— SHALL pasar sin bloqueo.
- [ ] Un commit en un repositorio SIN `kit.conf` SHALL pasar sin exigir firma. Hoy queda
      bloqueado sin salida: la puerta pide una firma que `verifica.sh` no puede producir
      allí. Fijado por prueba que falla contra el script actual.
- [ ] Un commit en un repositorio CON `kit.conf` y sin firma válida SHALL seguir
      bloqueado. Es el caso que este cambio no puede aflojar.
- [ ] Un comando que no es un commit SHALL salir por `exit 0` **sin costar más que la
      versión anterior del hook**, medido sobre 30 iteraciones del mismo comando.
      Renegociado el 2026-09-08: decía «sin coste medible», que no tiene umbral ni método y
      por tanto no se puede cumplir — todo coste es medible. El juez lo midió y encontró
      +12,6 ms (+34 %), porque el arreglo pasó de un `git` + un `python3` a dos `python3`.
      El umbral nuevo es comparativo y falsificable, y obliga a lo que había que hacer:
      dejarlo en UNA sola invocación de intérprete.
- [ ] Cada salida que deje pasar el comando sin comprobar la firma SHALL llevar escrito, en
      el propio código, si falla abierto o cerrado y por qué. Renegociado el 2026-09-08:
      decía «cada `exit 0` del script», que es un criterio léxico y dejaba fuera el
      `sys.exit(0)` del analizador en python; el requisito 4 del delta de spec ya lo decía
      en forma semántica y es la que manda.
- [ ] La cabecera del script y la doc del README SHALL describir los límites reales tras el
      cambio; ningún límite hoy declarado SHALL desaparecer sin sustituto escrito.
- [ ] Cada prueba que fija uno de los fallos SHALL salir ROJA contra el script sin
      arreglar, y las de no-regresión SHALL salir verdes contra ambas versiones. Verificado
      una a una. Renegociado el 2026-09-08: decía «ninguna prueba nueva SHALL pasar contra
      el script sin arreglar», y eso **contradecía** al criterio del caso que no puede
      romperse — sus pruebas también son nuevas, y tienen que pasar contra las dos
      versiones. No había código capaz de satisfacer los dos a la vez. La distinción que
      siempre se quiso está en el propio banco, que marca 🔴 los casos que fijan un fallo y
      ✅ los demás.
- [ ] El motivo del bloqueo SHALL nombrar el repositorio comprobado, y una prueba SHALL
      fijarlo. Añadido el 2026-09-08: el delta de spec ya lo exigía y ninguna prueba lo
      miraba — el banco solo casaba contra `permissionDecision: deny`.
- [ ] El recuento de casos del banco NO SHALL escribirse a mano en ningún sitio. Añadido el
      2026-09-08: el commit anterior dejó «once casos» en `kit.conf` y en el propio banco, y
      «diez casos» en el README, contradiciéndose a sí mismo el mismo día. Un censo a mano
      envejece en cuanto alguien añade un caso.
