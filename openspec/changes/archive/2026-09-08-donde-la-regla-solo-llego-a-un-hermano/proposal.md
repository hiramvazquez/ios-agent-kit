# Donde la regla solo llegó a un hermano

## Why

Una auditoría del 2026-09-08 leyó los scripts, los acuerdos y los documentos del kit con la
verificación en verde delante —los diez pasos de `kit.conf`, todos ✅— y encontró once
defectos. Ninguno es una regla que faltara: **todos son reglas que este repo ya escribió,
aplicadas en un fichero y no en su hermano.**

- `verifica.sh` sale con `1` en rojo y reserva el `3` para «no pude mirar», y lo tiene
  documentado y con banco. `autocomprueba.sh` —la puerta de publicación— sale con el número
  de fallos, así que **un** problema es indistinguible de «no existe la raíz».
- `autocomprueba.sh` documenta que `cd ""` devuelve 0 en bash y se protege. `rodaja.sh` y
  `doc-paquetes.sh` usan `cd "$(git rev-parse …)" || { echo "no es un repo git"; exit 1; }`,
  que por eso mismo **nunca dispara**.
- El hook aprendió a no escribir dentro del repositorio observado. `rodaja.sh`, tres líneas
  después de su guarda muerta, hace `mkdir -p .agent-kit` en el directorio donde estés.
- `rodaja.sh` escribe `|| true` después de un `grep -c`, que es lo correcto. El hook escribe
  `|| echo 0` dos ficheros más allá, y por eso pierde parte del digest.

### Lo que el verde no cubría

Los seis defectos de código viven en dos sitios, y los dos son la misma clase de punto ciego:

1. **La rama que ningún fixture monta.** El banco del hook monta un cambio activo con
   *exactamente una* tarea pendiente. Con cero —el estado normal cuando el cambio está
   terminado y se va a llamar al juez— el digest se rompe, y nadie lo había visto.
2. **El script que ningún banco mira.** `doc-paquetes.sh` es el único script de producción
   sin banco, y es el único con una rama muerta: su `find` de `.build/checkouts` lleva un
   `-depth 1` que lo hace insatisfacible.

Y un tercero que es peor, porque el banco **sí** lo mira y pasa por una razón que no se
sostiene en producción: el banco del hook fija `HOME="$TMP/home"`, así que la mitad de la
búsqueda de dependencias —`DerivedData`— está vacía en las pruebas. Su caso «cada repo recibe
SUS dependencias» pasa por el fixture, no por el código.

**La lección, que vale más que los once arreglos: un verde prueba los fixtures, no el
código.** Es la misma forma del hallazgo que ya está escrito en `busca-duplicados.py` —un
recuento agregado no dice si lo que se fue era lo que sobraba— aplicada a la cobertura.

### El defecto que más cuesta

El digest pierde el bloque **`FUERA de alcance`** exactamente cuando el cambio está
terminado. En bash 3.2 —el de macOS, el que resuelve `#!/usr/bin/env bash`— un error de
expansión aritmética aborta el compound entero, no solo su línea; y `PEND` vale `"0\n0"`
siempre que no queden tareas pendientes. Reproducido:

```
· Cambio activo: mi-cambio
· Estos paquetes traen sus PROPIAS reglas...     ← saltó al final; faltan tres líneas
```

Se pierde una de las tres reglas innegociables que este hook existe para inyectar, en
silencio, en el turno en que se invoca al juez y se commitea. Es el modo de fallo que el hook
existe para impedir, cometido por el hook.

### La dependencia que no es de este repositorio

El acuerdo inyectado en la sesión donde se hizo esta auditoría decía:

> `Estos paquetes traen sus PROPIAS reglas y no están en el repo: AppFoundation CoreNetworking`

Este repositorio tiene **cero** ficheros `.swift`. Esos dos salen del `DerivedData` de
`AppStarter` y `DemoMulti`, porque el `find` recorre todo `~/Library/Developer/Xcode/
DerivedData` sin filtrar por proyecto. Un repositorio vacío recién creado en `/tmp` recibe la
misma frase.

Es literalmente lo que `contexto-inyectado` declara inaceptable: *«un caché compartido
serviría las dependencias de un proyecto a otro — un fallo peor que el que se arregla, porque
el dato equivocado parecería correcto»*. Se arregló el **almacenamiento** —hay un fichero de
caché por repositorio, y se comprobó— pero no la **consulta**, así que los cuatro cachés de
esta máquina contienen la misma respuesta de toda la máquina.

## What Changes

Once arreglos. Los agrupo por lo que cambian, no por fichero.

### Comportamiento (con delta de spec)

- **El hook sobrevive al cambio terminado**: con cero tareas pendientes el digest sigue
  entero, sin perder `tareas:`, ni la lista, ni el `FUERA de alcance`, y sin escribir a
  stderr.
- **Las dependencias son las de ESTE repositorio**: la búsqueda se acota al repositorio
  observado en vez de a la máquina entera.
- **El hook de compactación dice su propio nombre**: `hookEventName` pasa a corresponder al
  evento que lo invoca. Hoy emite `UserPromptSubmit` también cuando lo llama
  `SessionStart(compact)`, y la documentación de Claude Code exige el nombre del evento.
- **`/kit-doc` vuelve a ver las dependencias locales de SwiftPM**: se quita el `-depth 1` que
  hace insatisfacible la rama de `.build/checkouts`.
- **Toda pieza que exige un repositorio git lo dice cuando no lo hay**, y ninguna deja nada
  escrito fuera de uno.
- **`autocomprueba.sh` distingue «no pude mirar» de «está mal»**, igual que `verifica.sh`.

### El acuerdo, renegociado por escrito

- **El detector de duplicados tiene DOS suelos, no uno.** `busca-duplicados.py` ignora los
  cuerpos por debajo de 3 líneas **y** los de menos de 60 caracteres normalizados. El segundo
  no está en la spec, y por él un ayudante real de tres líneas copiado en dos ficheros **no
  se reporta** —contra lo que la cláusula 3 promete y su escenario afirma—. `docs/PIEZAS.md`
  sí lo documenta, así que la discrepancia es spec ↔ código.

  **Se renegocia el acuerdo, no se cambia el comportamiento**, y esa decisión se justifica
  abajo. La spec pasa a hablar de dos suelos y el script gana la declaración que la spec ya
  exigía del primero.

### Prosa que afirma cosas falsas (sin delta: no cambia comportamiento)

- `docs/PIEZAS.md` describe la puerta **anterior** a su arreglo —«si el comando *contiene*
  `git commit`»—, que es justo lo que `puerta-de-commit` cl.3 prohíbe.
- `docs/PIEZAS.md` dice que el hook «inyecta **tres** cosas y ninguna más» cuando son cuatro:
  falta la atribución del repositorio, que es el titular de dos cambios ya archivados.
- `skills/swift-swiftui/SKILL.md` habla de «**esta** app», «**este** repo» y «**este**
  proyecto» para describir un proyecto que no es el que la lee. La skill viaja a los
  proyectos de los usuarios; ahí esas frases son afirmaciones falsas sobre el proyecto del
  lector, y aquí, sobre un repositorio con cero ficheros Swift.

### La decisión de diseño que este cambio toma

**Que el suelo de 60 se declare en vez de quitarse.** Las dos salidas eran legítimas —la
regla de la casa dice «se corrige el código o se renegocia el acuerdo POR ESCRITO»— y se
eligió la segunda por tres razones:

1. **El suelo lleva ahí desde el principio y no es un descuido**: filtra la coincidencia
   trivial, que es ruido, no duplicación.
2. **`docs/PIEZAS.md` ya lo documenta**, con su número. O sea que el kit lo conocía y lo
   contaba a quien lo instala; lo que faltaba era el acuerdo, no el conocimiento.
3. **Quitarlo cambia el comportamiento del detector en proyectos reales sin medición
   previa**, y la cláusula 4 de esa misma spec prohíbe mover el suelo con un recuento
   agregado. Moverlo hoy sería romper su propia regla para cumplir su propia cláusula.

Lo que **no** se acepta de la situación actual es que el suelo viva sin declarar: la spec
exige que todo suelo esté «escrito en el propio script, con su razón y su medición», y el de
60 no tiene ni comentario. Eso se arregla aquí.

## Fuera de alcance

- **Mover el suelo de 3, o el de 60.** Este cambio los declara; medirlos para moverlos es
  otra cosa y la cláusula 4 dice cómo hacerlo (por identidad, no por recuento). No se toca
  ni un número.
- **Escribir un detector de duplicados para bash.** `kit.conf` ya declara por qué no, con el
  pipeline de tres líneas que lo sustituye. Esta auditoría no cambia ese cálculo.
- **Un banco para `lib-kit.sh` o `lib-banco.sh`.** Son librerías sin lógica propia que los
  bancos de sus consumidores ya ejercitan.
- **Reescribir `docs/FLUJO.md`, `docs/PRIMER-CAMBIO.md`, `docs/INSTALACION.md` o el
  `README.md`.** La auditoría no encontró en ellos ninguna afirmación falsa. Solo se tocan si
  algún arreglo de aquí les cambia lo que describen.
- **Los prompts de `aceptacion.md` y `reviewer.md`.** No tienen defectos en esta auditoría.
- **Reconocer más envoltorios en `analiza-invocacion.py`** (`env`, `time`, `nohup`, `xargs`).
  Se probaron y caen al directorio heredado, pero la cabecera del script **ya lo declara** —
  «cualquier envoltorio que no sea un shell de la lista»—, así que es un límite declarado, no
  un defecto. Estrecharlo es otro cambio.
- **La deuda de que un `bien` de `autocomprueba.sh` mire el contador acumulado** se arregla
  aquí por ser de una línea, pero no gana delta: es cosmética y no cambia ningún contrato.

## Límite declarado

**El hook de `SessionStart(compact)` no se puede verificar desde dentro de este repositorio.**
Que `hookEventName` deba corresponder al evento es lo que documenta Claude Code, y el arreglo
se hace contra esa documentación; que el resultado se aplique de verdad solo se ve
compactando una sesión real con el plugin instalado. El banco puede fijar la forma del JSON
—que el nombre emitido sea el del evento invocante— y no puede fijar el efecto. Se declara
porque es el único arreglo de este cambio cuya prueba vive fuera.

**Y una segunda vez la misma clase de límite:** el arreglo de las dependencias se puede
probar montando un `DerivedData` falso bajo un `HOME` temporal, que es lo que hará el banco.
Que el filtro acierte contra el `DerivedData` real de una máquina con varios proyectos Xcode
se comprueba corriéndolo ahí, y ese caso queda como medición fechada, no como prueba.

## Criterios de aceptación

- [ ] Con **cero** tareas pendientes, el digest SHALL incluir la línea `tareas:` y el bloque
      `FUERA de alcance`, y NO SHALL escribir nada en stderr.
- [ ] El banco del hook SHALL montar un cambio activo sin tareas pendientes, y ese caso SHALL
      salir en rojo contra `scripts/inyecta-contexto.sh` tal como está antes de este cambio.
- [ ] En un repositorio sin ficheros Swift ni dependencias resueltas, el digest NO SHALL
      nombrar ninguna dependencia, aunque la máquina tenga `DerivedData` de otros proyectos.
- [ ] El JSON que emite el hook SHALL declarar el evento que lo ha invocado, y el banco SHALL
      comprobar los dos nombres.
- [ ] `doc-paquetes.sh` SHALL listar un paquete resuelto en `.build/checkouts` del propio
      repositorio, con su `AGENTS.md`, sin `DerivedData` por medio.
- [ ] SHALL existir un banco de `doc-paquetes.sh`, invocado desde `kit.conf`.
- [ ] `rodaja.sh` y `doc-paquetes.sh`, invocados fuera de un repositorio git, SHALL decirlo y
      salir distinto de 0, y NO SHALL dejar ningún fichero ni directorio nuevo.
- [ ] `autocomprueba.sh` SHALL salir con un código propio para «no pude mirar», distinto del
      que usa cuando ha mirado y hay problemas, **sea cual sea el número de problemas**.
- [ ] El número de problemas SHALL seguir siendo legible en su salida.
- [ ] `busca-duplicados.py` SHALL declarar sus DOS suelos en el propio script, cada uno con
      su razón, y la spec `deteccion-de-duplicados` SHALL hablar de los dos.
- [ ] Ningún suelo SHALL cambiar de valor en este cambio.
- [ ] `docs/PIEZAS.md` NO SHALL decir que la puerta reconoce un commit por subcadena, ni que
      el hook inyecta tres cosas.
- [ ] `skills/swift-swiftui/SKILL.md` NO SHALL afirmar nada sobre «esta app» / «este repo» /
      «este proyecto» que no sea cierto en el proyecto que la lee.
- [ ] `/kit-verifica` SHALL salir en verde, con todos los bancos —los que había y los nuevos.
- [ ] `bash scripts/autocomprueba.sh` SHALL salir limpio.
