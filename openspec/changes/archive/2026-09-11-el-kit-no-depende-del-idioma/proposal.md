# El kit no depende del idioma de la máquina

## Why

**`/kit-verifica` falla en un Terminal recién abierto.** No en un caso raro: `LANG=en_US.UTF-8`
es el valor por defecto de Terminal.app.

```
$ LANG=en_US.UTF-8 bash scripts/verifica.sh      # sobre la 1.9.5
❌ rodaja y lo entregado
❌ la autocomprobación
❌ pasada pendiente
❌ 3 paso(s) en rojo — sin firma útil.
```

*(Reproducido sobre el árbol publicado de la 1.9.5, que es lo que la gente tenía instalado. En el
árbol de trabajo donde se descubrió salían cuatro, porque llevaba encima un paso de otro cambio
sin publicar; el número que importa es el de lo publicado.)*

Sin firma, la puerta de commit bloquea el commit. El kit queda inservible para quien no tenga el
locale vacío — que es la configuración del agente, no la del humano.

**La causa es de una línea, y de las que no se ven leyendo.** `bash` 3.2 —el que trae macOS— con
`LC_CTYPE` UTF-8 se traga los bytes del carácter multibyte que venga pegado a `$VAR`, y lo mete
dentro del nombre de la variable:

```
$ LANG=en_US.UTF-8 bash -c 'set -u; A=ok; echo "«$A»"'
bash: A»: unbound variable
```

No es solo el guillemet: probado con `»`, `—`, `·`, `…`, `á` y `€`, los seis rompen. Con `set -u`
—que es lo que usan todos los scripts del kit— el fallo no degrada, **aborta**.

**Nada de lo que ya hay lo caza**, y eso es la otra mitad de la regla de la casa: `bash -n` sale
con 0, `shellcheck --severity=warning` sale con 0, y los bancos pasan en verde porque el agente
corre con el locale vacío. Es un fallo invisible a todo el instrumental existente y visible para
el usuario a la primera.

**Y la clase ya reincidió**: catorce apariciones repartidas en seis scripts, escritas a lo largo
de varias semanas y de varios cambios. **Diez ya están publicadas** en la 1.9.5, así que esto no
es deuda nueva: es un fallo que está fuera, en el kit que la gente instala.

## What Changes

- **Las llaves, en las diez del kit.** `«$A»` → `«${A}»`. Es la corrección mínima y no toca
  ninguna otra cosa: no cambia el orden de nada, no fija `LC_ALL`, no mueve semántica. *(Decía
  «en las catorce»: las otras cuatro estaban en `muta.sh`, que salió del árbol con su cambio el
  2026-09-11.)*
- **Un paso de verificación**, porque la clase ya falló más de dos veces y no hay forma más
  barata de verla: una línea de `perl` en `kit.conf` que busca `$VAR` pegado a un carácter
  no-ASCII en los scripts del kit, dice fichero y línea, y pone el paso en rojo. Lo que no ve va
  escrito junto a él.

> **Renegociado el 2026-09-11, después de cuatro rondas de juez.** Aquí decía que habría un
> detector —que acabó en Python—, con su banco, y que `docs/PIEZAS.md` documentaría el límite. La
> auditoría del kit de ese día encontró 711 líneas de detector, banco y mutantes para una
> expresión regular, sin haber corrido nunca en un proyecto real, y una línea de `perl` que en la
> 1.9.5 señala las mismas 9 líneas. Se renegocia **la forma y se estrecha el alcance**: sigue
> habiendo un paso que falla ante la forma rota y no marca la correcta, pero se pierden el banco,
> el «no pude mirar», la variable partida con `\` al final de línea y los scripts fuera de
> `scripts/` o en sus subcarpetas, que el detector en Python veía porque barría desde la raíz. Lo decidió el owner el
> 2026-09-11; el detalle está en el bloque «Renegociado» de `tasks.md`.

## Por qué llaves y no `LC_ALL=C`

Fijar el locale al principio de cada script también lo arreglaría, y el kit ya lo hace en dos
sitios —`lib-kit.sh` para ordenar, `pasada-pendiente.sh` para su `awk`—. Pero ahí se fija para
una operación concreta y con la razón escrita. Ponerlo global cambiaría el orden de todo lo que
ordena y la interpretación de todo lo que compara, en scripts que hoy funcionan; sería un cambio
mucho más ancho que el fallo. Las llaves son la corrección del fallo, no de su alrededor.

## FUERA de alcance

- **`LC_ALL` global en los scripts.** Ver arriba: más ancho que el fallo.
- **El código del proyecto que usa el kit.** El paso mira los scripts **del kit** —`scripts/*.sh`,
  `scripts/*.py`, `kit.conf` y la plantilla—, que es lo que el kit controla. El proyecto que lo usa
  queda fuera: declararlo, no prometerlo.
- **Las demás clases pendientes** —reglas repetidas en N sitios, y la mutación incremental—. No
  son esto. *(Decía «están anotadas»: lo estaban en el cambio de los mutantes, que salió del árbol
  el 2026-09-11.)*
- **Cambiar los mensajes para que no lleven guillemets.** El problema no es el guillemet: son las
  llaves que faltan. Quitar los caracteres de los mensajes taparía el fallo y dejaría la trampa
  puesta para el siguiente que escriba uno.

## Criterios de aceptación

- [ ] `LANG=en_US.UTF-8 bash scripts/verifica.sh` SHALL salir en verde y con firma.
- [ ] **Todos** los bancos SHALL pasar con `LANG=en_US.UTF-8` y con el locale vacío, dando lo
      mismo. Cuántos hay se cuenta con `ls scripts/verifica-*.sh`; no se escribe aquí, que es
      como un número se queda corto en cuanto nace una pieza.
- [ ] `kit.conf` SHALL tener un paso que falle ante un `$VAR` pegado a un carácter no-ASCII en
      `scripts/*.sh`, `scripts/*.py`, `kit.conf` y su plantilla, y que diga fichero y línea.
- [ ] El paso NO SHALL marcar `${VAR}` seguido del mismo carácter, que es la forma correcta.
- [ ] El paso SHALL comprobarse con los seis caracteres medidos, en los dos locales —rojo con la
      forma rota, verde con la correcta—, con el comando del bloque «Renegociado» de `tasks.md`.
- [ ] Lo que el paso no ve SHALL estar escrito junto a él y en la spec.
- [ ] `/kit-verifica` en verde y `autocomprueba.sh` limpio, en los dos locales.

> **Renegociado el 2026-09-11**, con la nota de «What Changes». Los criterios tercero a sexto
> decían: que existiera un detector barriendo desde la raíz del kit y corrido desde `kit.conf`;
> que el detector no marcara la forma correcta; que su banco montara los seis caracteres y matara
> al mutante que quita la comprobación; y que `docs/PIEZAS.md` declarara el límite.
