# El kit se aplica a sí mismo

## Why

Una auditoría del repositorio completa —los 11 scripts, los 2 agentes, los 6 comandos, el
README y los 4 documentos— encontró doce defectos. Once de ellos son **la misma cosa**: el
kit incumple, en su propio repositorio, una regla que impone a los proyectos que lo usan.
Esa es la razón de que vayan juntos y no en doce cambios sueltos.

| la regla, escrita en el kit | dónde el kit la incumple |
|---|---|
| «Sin evidencia no es cumplido» (`agents/aceptacion.md`) | el juez lee un diff que está **vacío** cuando se le invoca |
| «Los scripts viven en el plugin, se invocan por `${CLAUDE_PLUGIN_ROOT}`» | `agents/aceptacion.md` invoca `Scripts/verifica.sh`, que no existe |
| «Un aviso que siempre dice lo mismo deja de ser un aviso» (`busca-duplicados.py`) | el detector cuenta el mismo fichero dos veces al seguir un symlink: 21 de 28 grupos falsos en `spm-pro` |
| «Antes de escribir una función, busca si ya existe» (digest inyectado en cada turno) | la resolución del cambio activo está copiada en tres sitios, con el mismo defecto en las tres |
| «Los números caducan en el momento de escribirse» (`agents/aceptacion.md`) | `README.md` dice «5 skills» donde hoy hay 7 |
| «Un límite que no se declara es una promesa falsa» (`puerta-commit.sh`) | dos límites reales sin declarar, y uno declarado sin medir |

El doceavo no encaja en ese patrón y va igual porque es del mismo tamaño: un fichero
temporal de nombre predecible en `/tmp`, escrito por un hook que corre en cada turno de
cualquier repositorio.

### Los tres que rompen algo, con su prueba

**1. El juez de aceptación dictamina sobre un diff vacío.** `agents/aceptacion.md` le manda
leer «lo que REALMENTE se entregó» con `git diff main...HEAD`. Pero por `docs/FLUJO.md` el
juicio es el paso 6 y el commit el paso 8: **cuando se invoca al juez, el trabajo todavía no
está commiteado**, así que ese comando devuelve vacío en cualquier rama, y doblemente cuando
se trabaja en `main`, que es lo que hace este repositorio. Medido aquí: 0 líneas.

Lo grave no es que se quede sin diff: es que **no se entera**. El juez tiene `Read`, `Grep` y
`Glob`, así que juzga leyendo ficheros sueltos y emite su veredicto igual. Es un fallo
silencioso dentro de la pieza que existe para que no haya verdes sin mirar. Los dos cambios
ya archivados se aceptaron así — no significa que sus veredictos fueran falsos, sí que no
eran comprobables.

Y es una ceguera **ya resuelta en este repositorio**: `rodaja.sh` la arregló para el revisor
—los ficheros nuevos sin trackear que reportaban 26 líneas de 700— y nadie la trasladó.

**2. El detector de duplicados sigue los symlinks.** `rglob("*.swift")` los sigue, así que
el mismo fichero real leído por dos rutas produce cuerpos idénticos «en ficheros distintos».
Medido en `spm-pro`: cuatro symlinks generan **21 grupos fantasma de los 28** que reporta.

No es un repositorio raro: un build tool plugin de SwiftPM no puede depender de un target de
librería, así que enlazar las fuentes es el apaño estándar. El informe de ese proyecto es hoy
ilegible en `/kit-duplicados`, que es justo el «papel pintado» contra el que se escribió
`--tocados`.

**3. `verifica.sh` no distingue «está mal» de «no pude mirar».** `docs/PIEZAS.md` documenta
`3` como *no pude mirar*, distinto de `N` pasos en rojo. Pero el script sale con
`exit "$FALLOS"`. Comprobado en un repositorio temporal:

```
exit con 3 pasos en rojo: 3
exit sin kit.conf:        3
```

Hoy no lo consume nadie —la puerta usa `--comprueba`—, pero es una promesa escrita que el
código no cumple, y quien la meta en CI confundirá *roto* con *no mirado*: exactamente la
distinción que el propio comentario del script presume de cuidar.

### Lo que la auditoría midió y NO propone arreglar

Se dice aquí porque una medición que no se escribe se pierde, y porque contradice lo que el
propio repositorio da por supuesto.

`kit.conf` declara hoy que la duplicación en bash «no la está buscando nadie», con un tono
que sugiere un agujero grande. **Se buscó**: bloques y líneas repetidas entre los 11 scripts,
1.400 líneas. Resultado: **un solo duplicado real** —la resolución del cambio activo, que
este cambio extrae— y el idioma compartido de los dos bancos, que es deliberado. Un detector
de duplicados para bash encontraría lo que un análisis de veinte líneas ya encontró, y
costaría un script, su banco y su mantenimiento para siempre. **No se escribe.** Lo que se
hace es lo que el kit exige para los censos: sustituir la afirmación por una medición
fechada, con el comando que la produjo.

## What Changes

- El juez de aceptación lee lo entregado del árbol de trabajo, no de un diff commiteado, y
  invoca los scripts del kit por su raíz de plugin.
- `busca-duplicados.py` deja de contar dos veces el mismo fichero real. Su suelo de ruido se
  intentó subir y **se dejó donde estaba**: la historia y el motivo, en el delta.
- `verifica.sh` separa el código de salida de «no pude mirar» del de «hay pasos en rojo».
- La resolución del cambio activo pasa a existir **una vez**, es determinista, y dice cuándo
  hay más de un cambio abierto.
- `autocomprueba.sh` gana el criterio que le faltaba para cazar rutas como `Scripts/…`, y una
  comprobación de censos a mano.
- `inyecta-contexto.sh` deja de escribir en `/tmp`.
- El README, `docs/PIEZAS.md` y `kit.conf` dicen la verdad sobre las piezas, el mecanismo de
  la huella y los límites, con las mediciones fechadas.

### La decisión de diseño que este cambio toma

**Qué es «lo entregado» para el juez.** Hay tres candidatos y ninguno es obvio:
`git diff main...HEAD` (lo commiteado en la rama), `git diff HEAD` (lo staged y sin stagear)
y la suma de todo lo que ha cambiado desde que empezó el cambio, ficheros nuevos incluidos.

Se elige **el tercero, y por la pieza que ya lo resuelve**: `rodaja.sh` sabe reunir el diff
con los ficheros sin trackear, sabe excluir `.claude/` y sabe no volcar ficheros enormes. El
juez necesita lo mismo que el revisor, pero **acumulado desde el principio del cambio** en
vez de desde la última marca. Que sea el mismo código no es elegancia: es que la ceguera de
los ficheros nuevos ya costó una revisión, y duplicarla para el juez la volvería a costar.

**Qué código de salida lleva cada cosa en `verifica.sh`.** Se conserva `3` con su
significado documentado —«no pude mirar»— y el rojo pasa a ser `1`, sin importar cuántos
pasos fallaran. El número de pasos en rojo **sigue existiendo donde de verdad se lee**: en el
informe y en la línea `resultado:` de la firma. Se prefiere así porque el significado de `3`
está escrito en la documentación pública del kit y el de `N` no lo consume nadie hoy;
romper el que nadie usa cuesta cero, romper el otro cuesta una promesa.

**Por qué el detector de duplicados no aprende a distinguir «copia deliberada».** Un symlink
no es una copia deliberada: es **el mismo fichero**. La solución no es una lista de
excepciones —que envejece y hay que mantener— sino resolver la ruta real y no contar dos
veces lo que es uno. Sigue sin haber ningún mecanismo para marcar «este duplicado es
intencionado», y eso sigue decidiéndolo quien mira el cambio.

### Si esto se parte, se parte aquí

Un juez estricto puede decir «esto son dos cambios», y tendría un argumento: los tres
primeros defectos rompen algo y los demás desactualizan documentación. **La línea de corte,
si hace falta, es entre la fase 2 y la fase 3 de `tasks.md`.** Va en un solo cambio porque
la tesis —el kit no se aplica a sí mismo— es lo que da sentido a los doce juntos, y porque
partirlo obliga a escribir dos veces el mismo «Why».

## Fuera de alcance

- **Reescribir el prompt del juez o del revisor.** Este cambio corrige las líneas de entrada
  que no funcionan; las preguntas que hacen esos dos agentes son buenas y no se tocan.
- **Recortar la longitud de los agentes** (98 y 141 líneas que se cargan enteras en cada
  invocación). Es una decisión de coste con su propio argumento en contra —esa prosa es la
  que hace que las reglas se cumplan— y merece su propio cambio si algún día se toma.
- **Un detector de lógica repetida para bash.** Medido y desestimado; la medición se escribe,
  el detector no.
- **Detección semántica de duplicados.** Dos funciones que hacen lo mismo escritas distinto
  siguen sin parecerse para el detector, y este cambio no lo cambia.
- **Bancos de pruebas para los comandos y los agentes.** La ampliación de `autocomprueba.sh`
  cubre lo mecánico —que las rutas citadas existan y vayan por la raíz del plugin—. Probar
  que un prompt produce el veredicto correcto es otro problema y no se aborda aquí.
- **Cerrar `--no-verify` u otras vías deliberadas.** Sigue declarado como límite y sigue
  abierto.

## Criterios de aceptación

- [ ] El juez de aceptación SHALL recibir un conjunto de cambios NO vacío cuando el trabajo
      está sin commitear, incluidos los ficheros nuevos sin trackear. Fijado por una prueba
      que sale roja contra la entrada actual del agente.
- [ ] Ningún fichero de `commands/`, `agents/` o `skills/` SHALL citar un fichero del kit por
      una ruta que no pase por `${CLAUDE_PLUGIN_ROOT}`. Comprobado por `autocomprueba.sh`,
      que SHALL salir en rojo contra el repositorio tal como está hoy.
- [ ] `busca-duplicados.py` SHALL contar una sola vez un fichero alcanzable por dos rutas.
      Fijado por un caso de banco con un symlink, rojo contra el detector actual.
- [ ] El informe de `/kit-duplicados` sobre `spm-pro` SHALL reducirse a los grupos que no son
      artefacto de symlink, y el número resultante SHALL contarse con el comando, no
      escribirse a mano en ningún sitio.
- [ ] El suelo de ruido del detector SHALL quedarse donde está: un cuerpo repetido de dos
      líneas no se reporta, uno de tres sí y uno de cuatro también. Fijado por tres casos de
      banco. Y toda medición que proponga moverlo SHALL nombrar QUÉ grupos cambian de lado.
      **Renegociado dos veces.** Primero decía «no reportar los dobles de test», que un
      script no puede saber. Luego decía que el suelo SUBIRÍA a cuatro, y así se implementó
      — hasta que el juez de aceptación midió por identidad en vez de por recuento y encontró
      que ese suelo borraba dos duplicados reales de `spm-pro` (`pascalCase()` y
      `displayPath()`) para quitarse un doble de test. Se revirtió el código y esta línea se
      quedó pidiendo lo contrario durante una ronda: el acuerdo contradiciéndose a sí mismo,
      que es el fallo que este cambio existe para no cometer.
- [ ] `verifica.sh` SHALL salir con códigos distintos ante «no hay `kit.conf`» y ante
      «N pasos en rojo», sea cual sea N. Fijado por un banco propio —el que le faltaba— que
      cubra además que la firma solo vale para su diff y solo tras un verde.
- [ ] El número de pasos en rojo SHALL seguir siendo legible en el informe y en la firma
      tras el cambio del código de salida.
- [ ] La resolución del cambio activo SHALL existir en un solo sitio del código, y las tres
      llamadas de hoy SHALL usarla.
- [ ] Con dos cambios activos, esa resolución SHALL producir el mismo resultado en dos
      invocaciones consecutivas, y SHALL decir que hay más de uno. Hoy depende del orden del
      sistema de ficheros. Fijado por prueba.
- [ ] `inyecta-contexto.sh` NO SHALL crear ficheros en un directorio compartido con un
      nombre derivable del PID. Comprobado por una prueba del banco de contexto.
- [ ] El digest inyectado SHALL ser byte a byte el mismo que hoy en un repositorio con un
      cambio activo, salvo lo que exija la cláusula de los cambios múltiples. Es el caso que
      no puede romperse.
- [ ] Ningún documento del kit SHALL afirmar cuántas piezas trae sin que ese número esté
      contado por un comando en el momento de leerlo. `autocomprueba.sh` SHALL fallar si
      reaparece un censo a mano.
- [ ] `docs/PIEZAS.md` SHALL describir el mecanismo real de la huella: sustituir un literal
      por una constante SÍ cambia la huella, y lo que sobrevive es el grupo, porque las dos
      copias cambian igual. Demostrado con las dos huellas.
- [ ] `kit.conf` SHALL sustituir su límite declarado sobre la duplicación en bash por la
      medición, con el comando que la produce y su fecha.
- [ ] La documentación SHALL declarar dos límites que hoy no están escritos: que `kit.conf`
      se ejecuta como código al verificar, y cuánto cuesta el recorrido de `DerivedData` del
      hook de contexto, medido.
- [ ] Cada prueba nueva que fija uno de estos fallos SHALL salir ROJA contra el código sin
      arreglar; las de no-regresión SHALL salir verdes contra ambas versiones.
- [ ] Ningún límite hoy declarado SHALL desaparecer sin sustituto escrito.
