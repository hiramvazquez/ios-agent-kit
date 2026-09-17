> ## RESULTADO: no se entregó. Archivado como hallazgo, no como mejora.
>
> Cuatro intentos, cuatro veredictos —AMBER, DEVUELTO, DEVUELTO, DEVUELTO—, y se revirtió al
> estado original en `4641faf`. **La puerta sigue sin frenar `cd ~/… && git commit` ni
> `git add` + `git commit` en líneas distintas.** Lo que sí queda: el agujero medido y
> reproducible, 19 casos de prueba escritos (grupo 8 de `tasks.md`), y la razón por la que
> cada arreglo fabricaba el siguiente fallo (grupo 9).
>
> Este cambio se archiva **sin promover su delta al spec vivo**: describe una puerta que no
> existe, y el punto 7 de ese mismo requisito prohíbe nombrar lo que no se cubre.
>
> Lo que queda por decidir está en el grupo 9 de `tasks.md`, y no lo resuelve otra ronda de
> parches.

## Why

La puerta de commit no frena nada cuando la ruta se escribe como la escribe cualquiera.
Medido el 2026-09-16 alimentando el hook con la entrada que le da Claude Code:

| forma del comando | ¿bloquea? |
|---|---|
| `cd /Users/hiram/… && git commit` | sí |
| `cd ~/… && git commit` | **no** |
| `cd $HOME/… && git commit` | **no** |
| `cd <ruta>` en una línea, `git commit` en la siguiente | **no** |

Y no son iguales de graves, que es la diferencia que importa. El spec vivo dice que la
puerta comprueba el repositorio indicado por «un `cd <ruta>` que precede al commit **en la
misma línea**»:

- **Lo de `~` y `$HOME` incumple lo prometido.** El comando indica el destino en la misma
  línea y la puerta no lo comprueba.
- **Lo del salto de línea es un límite declarado**, no un incumplimiento. Lo que está mal
  ahí es otra cosa: el código aparenta cubrirlo y no lo cubre.

Dos causas distintas:

1. **La ruta no se expande.** `cd_pendiente` se pasa tal cual a `git -C`, así que con `~` o
   `$HOME` git no resuelve nada, el hook no obtiene repositorio de destino y **falla
   abierto** — su comportamiento correcto cuando no puede afirmar que hay un commit, pero
   aquí sí lo había.
2. **El salto de línea no separa comandos.** `SEPARADORES` lo incluye, pero `shlex` con
   `whitespace_split=True` **nunca emite `"\n"`**: lo consume como espacio. Comprobado
   tokenizando `cd /tmp\ngit commit -m x` → `['cd','/tmp','git','commit','-m','x']`, un solo
   segmento. Y como al ver un `cd` el analizador hace `continue`, el `git commit` de la línea
   siguiente no se examina nunca. Esa entrada de `SEPARADORES` es código muerto que aparenta
   cubrir un caso que el spec declara fuera. Se cubre —es la forma más natural de escribir un
   script de varias líneas— y así el código y la norma dicen lo mismo.

Esto no es teórico y conviene decirlo entero: **todos los commits que la sesión del
2026-09-16 hizo en otro repositorio usaron `cd ~/… && git commit`, y la puerta no intervino
en ninguno.** Todos fueron sobre verificación verde de verdad —se corrió `verifica.sh`, se leyó
su resultado, y cuando salió rojo se dijo y se rehizo—, pero eso lo sostuvo la disciplina de
quien commiteaba, no el mecanismo. La promesa del kit es justamente no depender de eso.

## What Changes

- **La pista de directorio se expande antes de resolverla**: `~`, `~usuario` y variables de
  entorno. Si tras expandir sigue sin resolver un repositorio, el fallo abierto se mantiene:
  es correcto cuando de verdad no se sabe a dónde va el commit.
- **El salto de línea separa comandos de verdad**, de modo que `cd X` en una línea y
  `git commit` en la siguiente se juzguen como lo que son.
- **Cada caso nuevo entra con su prueba en `verifica-puerta.sh`**, que es donde ya viven las
  cuatro formas que este hook cerró en su día. Sin prueba no está arreglado: la prueba es lo
  que impide que vuelva.

## Capabilities

### Modified Capabilities
- `puerta-de-commit`: el requisito de que la puerta juzgue el repo de destino se cumple hoy
  solo si la ruta viene absoluta y en la misma línea. Se añade qué formas de ruta y de
  encadenado tiene que reconocer.

## Fuera de alcance

- **Ampliar lo que la puerta cubre más allá de eso.** Sus límites declarados —`--no-verify`,
  otra terminal, una invocación construida en tiempo de ejecución— siguen igual y siguen
  escritos en la cabecera del hook. Esto no amplía el alcance: cierra un agujero dentro del
  alcance que ya prometía.
- **Cambiar el fallo abierto por fallo cerrado.** Es una decisión de diseño con su razón
  escrita, y no es lo que está roto.

## Criterios de aceptación

- [ ] `verifica-puerta.sh` cubre, y en verde: `cd ~/…`, `cd $HOME/…`, `cd` con salto de
      línea, y `git add` + `git commit` en líneas distintas con y sin `cd`; cada una
      bloqueando cuando no hay firma. (`~usuario` funciona pero no se fija con una prueba:
      `expanduser` lo resuelve por la base de datos de usuarios, no por `$HOME`, y probarlo
      exigiría escribir en el home real. Dicho en el spec.)
- [ ] Las pruebas nuevas fallan si se revierte el arreglo. Se demuestra revirtiendo.
- [ ] Los casos que ya cubría siguen cubiertos: la suite entera en verde.
- [ ] Si `SEPARADORES` mantiene `"\n"`, es porque el analizador ya lo recibe; si no, esa
      entrada se retira en vez de dejar código que aparenta cubrir algo.
- [ ] `/kit-verifica` en verde.

## Impact

- `scripts/analiza-invocacion.py` — la expansión de la pista y el separado por saltos.
- `scripts/verifica-puerta.sh` — las pruebas de los casos nuevos.
- `scripts/puerta-commit.sh` — su cabecera declara lo que cubre; si cambia, cambia ahí.
- `openspec/specs/puerta-de-commit/spec.md` — vía delta.
- Sin efecto sobre quien ya usa el kit, salvo que la puerta empieza a frenar commits que
  antes dejaba pasar. Eso es el arreglo, no un efecto secundario.
