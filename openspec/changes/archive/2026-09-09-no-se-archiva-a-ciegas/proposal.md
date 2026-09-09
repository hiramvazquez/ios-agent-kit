# No se archiva a ciegas

## Why

La 1.9.3 cerró que no se marque una rodaja sobre código que nadie ha visto. **El mismo agujero
sigue abierto un paso más adelante**, y lo destapó el juez de aquel cambio al desmentir una
frase mía: yo había escrito «el único punto del bucle donde todavía cabía» y él demostró que no.

El tramo es: el juez devuelve, arreglas lo que señaló, y archivas. **Ese arreglo no lo ha visto
ningún revisor.** El paso 7 de `docs/FLUJO.md` no menciona la revisión ni una vez —comprobado—
y `commands/kit-acepta.md` tampoco dice qué hacer con el código que se escribe para responder a
un DEVUELTO.

Y no es hipotético: **en los acuerdos archivados de esta semana que registran ambos tipos de
bloque, todas las pasadas de revisor preceden a todas las rondas de juez.** O sea que ningún
arreglo posterior a una ronda volvió a pasar por el revisor antes de archivar. Reproducible:

```bash
for d in openspec/changes/archive/*/; do
    printf '%-52s juez:%s revisor:%s\n' "$(basename $d)" \
      "$(grep -c '^## Del juez' $d/tasks.md)" \
      "$(grep -cE '^## (Del revisor|De la revisión)' $d/tasks.md)"
done
```

Cuántos de ellos tuvieron arreglos que movieran comportamiento **no se puede leer**: solo los
posteriores a la 1.9.2 llevan esa etiqueta. Decirlo de los demás sería apoyarme en mi memoria,
en el cambio cuya tesis es que la memoria no vale.

### Lo que sí está cubierto, para no inflar el agujero

El arreglo no va del todo a ciegas: al cambiar el árbol, la firma de `/kit-verifica` deja de
valer y la puerta de commit obliga a re-verificar antes de commitear, así que **build y tests
lo acaban viendo** — aunque no necesariamente antes de archivar. Lo que no lo ve es la
pregunta del revisor —«¿esto rompe algo?»— que es justamente la que caza lo que los tests no.

En `AppStarter`, el 2026-09-09, esa diferencia tuvo precio: la segunda pasada de revisor
—provocada por la regla que la 1.9.3 acabó escribiendo— encontró un defecto en una spec que
los tests no podían ver y que al archivarse se habría fundido en la canónica. La misma clase
de defecto puede entrar por este otro tramo y hoy nada la mira.

## What Changes

- **`/kit-acepta` gana la condición simétrica a la de `/kit-revisa`**: si arreglar lo que el
  juez señaló movió el comportamiento, ese código no lo ha visto ningún revisor — se pasa
  antes de archivar.
- **`docs/FLUJO.md`, paso 7**, dice lo mismo donde describe el archivado, que hoy no menciona
  la revisión.
- **`commands/kit-revisa.md`** gana la otra mitad del contrato de orden: escribir el bloque al
  final. Sin ella, «posterior» no se puede leer.

### La decisión de diseño

**El disparador es el mismo eje, y la respuesta ya está escrita.** Desde la 1.9.2 cada ronda
de juez se anota con qué pasó con el comportamiento, así que la comprobación antes de archivar
no es un ejercicio de memoria: **se lee el acuerdo.** Si alguna ronda posterior a la última
pasada de revisor dice «sí», falta una — y si no hay ninguna pasada anotada, que hoy es el caso
mayoritario, todas las rondas cuentan como posteriores.

Es la composición de las tres piezas de esta semana: el registro (1.9.2) produce el dato, el
tope (1.9.0) lo consume para pararse, y estas dos reglas —la 1.9.3 y esta— lo consumen para
saber qué falta por mirar. Ninguna inventa un criterio nuevo.

## Fuera de alcance

- **Poner una puerta al archivado.** Se podría —`/opsx:archive` corre por Bash, que es donde el
  kit ya intercepta `git commit`—, pero `hooks/hooks.json` declara que un cuarto hook tiene que
  traer escrito el fallo que lo motiva, y este no lo trae todavía: el fallo está observado y
  nadie ha medido que la instrucción no baste. Ver el límite.
- **Los prompts de `agents/`.** La condición es de quien orquesta, que es quien arregla y quien
  archiva. El juez ya tiene escrito que no archiva él.
- **Un tope para el revisor**, igual que en la 1.9.3.
- **El paso 8 (commit).** Ya lo cubre la puerta, que exige firma válida para el diff staged.
- **Volver a exigir que el juez re-juzgue.** Su tope decide cuántas rondas suyas hay; esto solo
  añade quién mira el código entre la última y el archivado.

## Límite declarado

**Nada lo comprueba, y aquí menos que en su hermana.** La 1.9.3 al menos se apoya en un gesto
del kit —`rodaja.sh --revisada`, que alguien tiene que escribir—; aquí no hay ninguno, así que
la regla vive enteramente en dos prompts y quien no los siga archiva igual sin que salte nada.
Que no haya puerta es decisión y no impedimento: cabría, y `hooks/hooks.json` dice qué haría
falta para justificarla.

**Y hereda el límite de su hermana:** si el arreglo posterior a la pasada de revisor vuelve a
mover comportamiento, hace falta otra, y así. Lo que acota eso es el presupuesto de rondas de
`docs/FLUJO.md`; al agotarse decide el owner. No se inventa aquí un segundo mecanismo.

## Criterios de aceptación

- [ ] `commands/kit-acepta.md` SHALL decir que no se archiva cuando arreglar lo que el juez
      señaló movió el comportamiento sin que un revisor lo haya visto, y qué hacer entonces.
- [ ] SHALL remitir al eje ya definido —la tabla del tope— en vez de reenunciarlo.
- [ ] SHALL decir que la respuesta está en el registro de las rondas, no en la memoria, y SHALL
      mirar si **alguna** ronda posterior a la última pasada movió el comportamiento, no solo la
      última.
- [ ] El requisito SHALL declarar lo que NO cubre: el código que el autor cambia por iniciativa
      propia, que no dispara ninguna de las dos reglas hermanas.
- [ ] `docs/FLUJO.md`, en su paso 7, SHALL describir esa condición junto al `/opsx:archive`
      que ya menciona.
- [ ] Los dos SHALL declarar que nada lo comprueba, y la razón SHALL ser cierta: que el kit ha
      decidido no poner un cuarto hook, no que el archivado sea imposible de interceptar.
- [ ] `agents/aceptacion.md` y `agents/reviewer.md` NO SHALL cambiar.
- [ ] `/kit-verifica` SHALL salir en verde y `autocomprueba.sh` limpio.
