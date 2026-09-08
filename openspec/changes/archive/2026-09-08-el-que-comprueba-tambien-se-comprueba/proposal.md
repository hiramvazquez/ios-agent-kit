# El que comprueba también se comprueba

## Why

La 1.7.0 se cerró dejando tres cosas anotadas. Dos se arreglan aquí y la tercera se decide
por escrito, que también es arreglarla.

**`autocomprueba.sh` es la única pieza con lógica que no tiene banco**, y no es una pieza
cualquiera: es la puerta de publicación, la que dice «kit sano — se puede publicar». Su punto
ciego —comprobar solo las rutas que ya empiezan por `${CLAUDE_PLUGIN_ROOT}` y no ver las que
omiten la raíz— dejó pasar una invocación muerta en el prompt del juez durante **las diez
versiones publicadas**. El cambio anterior le añadió dos comprobaciones más, y siguen sin
tener quien las mire.

Y hay una razón técnica de por qué nunca lo tuvo, que hay que quitar antes de poder
escribirlo: `autocomprueba.sh:14` hace `cd` a **su propia** raíz. No se le puede apuntar a un
árbol de prueba, así que cualquier banco comprobaría el kit de verdad en vez de fixtures
rotos. Un detector que no se puede apuntar a ningún sitio es un detector que no se puede
probar.

**El flujo asume que la sesión se abre en la raíz del repositorio, y cuando no, falla en
silencio.** Los comandos `/kit-*` vienen del plugin —ámbito de usuario— y funcionan desde
cualquier directorio; los `/opsx:*` son comandos de proyecto y solo se cargan si la sesión
tiene el repo como raíz. Un nivel por encima, medio flujo funciona y la otra mitad responde
«Unknown command», que no dice nada de la causa. Pasó el 2026-09-08 en una sesión real.

## What Changes

- `autocomprueba.sh` acepta una raíz opcional y, sin argumento, sigue comportándose
  exactamente como hoy.
- Nace `scripts/verifica-autocomprueba.sh`: un banco con un árbol de kit falso por cada clase
  de fallo que el detector dice cazar, más uno sano que tiene que salir limpio.
- `docs/INSTALACION.md` explica dónde hay que abrir la sesión y qué se ve cuando no.
- El alcance del lint de censos queda declarado en el propio script: no lee `openspec/`, y es
  una decisión, no un olvido.

### La decisión de diseño que este cambio toma, y va contra lo que parecía obvio

Lo anotado en la 1.7.0 decía que el lint de censos «no lee `openspec/`, así que un recuento a
mano dentro de un acuerdo no lo caza nada». La reacción natural es extenderlo. **No se
extiende**, y conviene decir por qué antes de que alguien lo intente:

1. **Dispararía sobre prosa legítima.** El propio kit distingue dos cosas que el patrón no
   puede: enumerar lo que un cambio toca —que es alcance, se verifica hoy y muere con el
   cambio— y enumerar el resto del repositorio como justificación, que es la trampa. «Se
   tocan `ProductsLogic` y `SearchLogic`» es un buen criterio; un patrón que cuenta dígitos
   pegados a un sustantivo no sabe cuál de los dos está leyendo.
2. **La clase ha fallado una vez, no dos.** La regla de la casa pide dos antes de escribir un
   detector, y pide antes de eso preguntarse si hay una forma más barata de verlo. La hay, y
   funcionó: el censo del acuerdo lo cazó un juez leyendo, que es su trabajo.
3. **El archivo no se toca nunca.** Un acuerdo archivado es historia: sus números describen lo
   que se midió aquel día y no envejecen, envejece el repositorio.

Lo que sí hace falta es que esto esté **escrito donde vive el detector**, no solo en el prompt
del juez. Un límite que solo conoce quien lo escribió vuelve a proponerse cada seis meses.

### Cómo se hace apuntable sin cambiar lo que hace

`autocomprueba.sh` pasa a aceptar un argumento opcional con la raíz a comprobar. Sin
argumento, resuelve la suya como hoy — de modo que `kit.conf`, que lo invoca sin argumentos,
no se entera. Es el mismo patrón que ya usan los otros bancos con `HOOK_BAJO_PRUEBA`,
`ROD_BAJO_PRUEBA` y compañía, pero al revés: allí se cambia el script bajo prueba, aquí el
árbol que mira.

## Fuera de alcance

- **Extender el lint de censos a `openspec/`**, por lo de arriba. Si algún día vuelve a
  fallar, la clase habrá fallado dos veces y entonces sí.
- **Añadir comprobaciones nuevas a `autocomprueba.sh`.** Este cambio le pone un banco a las
  que ya tiene; no le añade ninguna.
- **Bancos para `doc-paquetes.sh` y `busca-duplicados.py`.** El segundo ya lo tiene; el
  primero no ha fallado nunca y no se lo ha ganado.
- **El resto del prompt del juez.** Se acaba de tocar y no se vuelve a tocar aquí.

## Criterios de aceptación

- [ ] `autocomprueba.sh` SHALL aceptar una raíz como argumento y comprobar ESE árbol.
- [ ] Sin argumento SHALL comprobar su propia raíz, y `kit.conf` SHALL seguir invocándolo
      igual que hoy, sin cambios.
- [ ] SHALL existir un banco con un árbol de kit falso por cada clase de fallo que el
      detector dice cazar, y cada caso SHALL salir rojo contra el árbol roto y verde contra
      el sano.
- [ ] El banco SHALL entrar en `verificaciones()` de `kit.conf` y el recuento de casos NO
      SHALL escribirse a mano en ningún sitio.
- [ ] Un árbol de kit correcto SHALL salir limpio, para que el banco no pase por construcción.
- [ ] `docs/INSTALACION.md` SHALL decir dónde se abre la sesión, qué comandos dependen de eso
      y qué se ve cuando está mal — el «Unknown command» literal, para que sea buscable.
- [ ] El script SHALL declarar, donde vive el lint de censos, que `openspec/` queda fuera y
      por qué.
- [ ] `/kit-verifica` SHALL seguir en verde con el banco nuevo dentro.
