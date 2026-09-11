# El kit no depende del idioma de la máquina

## Why

**`/kit-verifica` falla en un Terminal recién abierto.** No en un caso raro: `LANG=en_US.UTF-8`
es el valor por defecto de Terminal.app.

```
$ LANG=en_US.UTF-8 bash scripts/verifica.sh
❌ rodaja y lo entregado
❌ la autocomprobación
❌ pasada pendiente
❌ banco de muta
❌ 4 paso(s) en rojo — sin firma útil.
```

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

- **Las llaves, en las catorce.** `«$A»` → `«${A}»`. Es la corrección mínima y no toca ninguna
  otra cosa: no cambia el orden de nada, no fija `LC_ALL`, no mueve semántica.
- **Un detector**, porque la clase ya falló más de dos veces y no hay forma más barata de verla:
  un paso de verificación que busca `$VAR` pegado a un carácter no-ASCII en los scripts del kit.
  Una línea de `grep`; el coste es despreciable.
- **Su banco**, con los seis caracteres medidos y con el caso que importa: que el detector no
  confunda `${A}»` —correcto— con `$A»`.
- **`docs/PIEZAS.md`** documenta el límite: esto cubre los scripts del kit, no el código del
  proyecto que lo usa.

## Por qué llaves y no `LC_ALL=C`

Fijar el locale al principio de cada script también lo arreglaría, y el kit ya lo hace en dos
sitios —`lib-kit.sh` para ordenar, `pasada-pendiente.sh` para su `awk`—. Pero ahí se fija para
una operación concreta y con la razón escrita. Ponerlo global cambiaría el orden de todo lo que
ordena y la interpretación de todo lo que compara, en scripts que hoy funcionan; sería un cambio
mucho más ancho que el fallo. Las llaves son la corrección del fallo, no de su alrededor.

## FUERA de alcance

- **`LC_ALL` global en los scripts.** Ver arriba: más ancho que el fallo.
- **El código del proyecto que usa el kit.** El detector mira `scripts/`, que es lo que el kit
  controla. Declararlo, no prometerlo.
- **Las demás clases pendientes** —reglas repetidas en N sitios, y la mutación incremental—.
  Están anotadas y no son esto.
- **Cambiar los mensajes para que no lleven guillemets.** El problema no es el guillemet: son las
  llaves que faltan. Quitar los caracteres de los mensajes taparía el fallo y dejaría la trampa
  puesta para el siguiente que escriba uno.

## Criterios de aceptación

- [ ] `LANG=en_US.UTF-8 bash scripts/verifica.sh` SHALL salir en verde y con firma.
- [ ] Los nueve bancos SHALL pasar con `LANG=en_US.UTF-8` y con el locale vacío, dando lo mismo.
- [ ] SHALL existir un detector que falle ante un `$VAR` pegado a un carácter no-ASCII en
      `scripts/`, y SHALL correrse desde `kit.conf`.
- [ ] El detector NO SHALL marcar `${VAR}` seguido del mismo carácter, que es la forma correcta.
- [ ] Su banco SHALL montar como casos los seis caracteres medidos, y SHALL matar al mutante que
      quita la comprobación.
- [ ] `docs/PIEZAS.md` SHALL declarar el límite: los scripts del kit, no el proyecto.
- [ ] `/kit-verifica` en verde y `autocomprueba.sh` limpio, en los dos locales.
