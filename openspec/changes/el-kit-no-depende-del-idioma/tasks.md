# Tareas

- [x] 1. **Reproducir primero, arreglar después.** Un caso que falle hoy: correr un banco con
      `LANG=en_US.UTF-8` y ver el `unbound variable`. Sin eso, lo que sigue es fe.

- [x] 2. **Las llaves, en las catorce apariciones.** Se listan con
      `grep -rnP '\$[A-Za-z_][A-Za-z0-9_]*[^\x00-\x7F]' scripts/`. No se toca nada más: ni
      `LC_ALL`, ni los mensajes, ni el orden de nada.

- [x] 3. **El detector**, como paso de `kit.conf`. Una línea de `grep`, y el comentario de por
      qué existe: su clase falló más de dos veces y `bash -n` y `shellcheck` salen con 0.

- [x] 4. **Su banco**, con los seis caracteres medidos —`»`, `—`, `·`, `…`, `á`, `€`— y con el
      caso que de verdad distingue: `${A}»` NO se marca y `$A»` SÍ. Un detector que marcara los
      dos sería inútil, porque el mensaje correcto lleva el mismo carácter.

- [x] 5. **Su lista de mutantes**, en `scripts/mutantes/`. Al menos el que quita la comprobación
      entera, y el que la deja marcar también la forma correcta.

- [x] 6. **`docs/PIEZAS.md`**: la pieza y su límite —los scripts del kit, no el proyecto—.

- [x] 7. **Cierre:** los nueve bancos en verde **en los dos locales**, `/kit-verifica` firmada en
      los dos, `autocomprueba.sh` limpio. Auditarme antes de invocar a nadie, con el barrido de
      siempre, y con el que esta sesión ha añadido por las malas: **para cada caso que escriba,
      el mutante que debe matarlo, comprobado ejecutándolo**.

## Lo que salió al implementarlo, y no del informe

- [x] 8. **El arreglo repitió el fallo que venía a arreglar.** La primera versión del detector
      usaba `grep -rnoP` y **no encontraba nada nunca**: el `grep` de macOS es BSD y no tiene
      `-P`. Salía con «invalid option», el `|| true` se lo comía, y contestaba «✅ ninguna» sobre
      ficheros que sí las tenían. No se vio porque **el `grep` del agente es otro, uno que sí
      soporta `-P`** — la misma forma exacta del bug: algo que funciona en un entorno y revienta
      en el otro. Reescrito en Python, que ya es dependencia del kit y lee BYTES, sin depender de
      ningún locale.

- [x] 9. **Y el banco lo tapaba.** Comparaba contra «pegado a un carácter no-ASCII», que está en
      el mensaje de éxito **y** en el de fallo: doce casos en verde con el detector muerto. Lo
      destapó **el único caso que miraba el código de salida**, no el mensaje. Todas las
      aserciones van ahora contra el código, y el par que mira texto compara trozos que no son
      subcadena de su contraria.

- [x] 10. **El detector se denunciaba a sí mismo**, porque su cabecera enseña el fallo. Añadida
      la marca `pegada-de-ejemplo`, **por línea y no por fichero** —marcar un ejemplo no puede
      cegar el resto del script—, con dos casos y dos mutantes. Y acotado a `.sh` y `.py`:
      escaneaba los `.pyc`, que nadie escribe a mano.

- [x] 11. **El arreglo rompió la deducción de `muta.sh`.** Su `banco_de` buscaba `$DIR/` y los
      ficheros que ya llevan llaves escriben `${DIR}/`. Cazado al ejecutar; acepta las dos.
      (Vive en el cambio de los mutantes, que es su dueño.)

- [x] 12. **Y uno que solo existía en el árbol de publicación.** El banco nuevo usaba `igual()`
      de `lib-banco.sh`, donde lo mueve el cambio de los mutantes — que no se publica aquí. Al
      reconstruir la 1.9.6 desde HEAD, 18 de 21 casos en rojo. Definido localmente, como los
      otros cuatro bancos; la consolidación se queda en su cambio. **Solo se vio por verificar el
      árbol que se publica en vez de dar por bueno el de desarrollo.**

**Cierre, medido:** `/kit-verifica` firmada y los nueve bancos en verde **con `LANG` vacío y con
`LANG=en_US.UTF-8`**, que era el criterio de aceptación de verdad. `autocomprueba.sh` limpio.
