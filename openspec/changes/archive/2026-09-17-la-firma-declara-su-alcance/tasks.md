## 1. La detección, en un solo sitio

- [x] 1.1 Añadir a `scripts/lib-kit.sh` una función que devuelva en **una línea** el toolchain:
      versión del compilador del PATH, Xcode seleccionado, y la marca de divergencia si el
      compilador del PATH y el de `xcrun` no son el mismo. Si alguna herramienta no está, la
      línea lo dice («no identificado») y la función sale con 0.
      Verificación: invocada a mano en esta máquina imprime la versión de Swift y `Xcode 27.0`;
      invocada con un PATH sin `swift` ni `xcodebuild` imprime «no identificado» y sale con 0.
      Las dos salidas quedan anotadas aquí.
      **Hecho**: `toolchain()` en `scripts/lib-kit.sh`, con `version_swift()` al lado porque el
      compilador se interroga dos veces —el del PATH y el de `xcrun`— y comparar las dos es el
      aviso de divergencia. En esta máquina imprime `Swift 6.4 · Xcode 27.0`. Con un PATH que no
      tiene nada que interrogar: `no identificado`, `exit=0`.
      *El primer intento de esa segunda prueba no probaba nada*: con `PATH=/usr/bin:/bin` seguía
      imprimiendo `Swift 6.4 · Xcode 27.0`, porque `/usr/bin/swift` y `/usr/bin/xcodebuild` son
      los shims de Xcode. Hubo que apuntar el PATH a un directorio vacío de verdad.
- [x] 1.2 Medir lo que cuesta la función, en caliente y tres veces, y anotarlo aquí. Si pasa de
      1 s, se para y se replantea D4 por escrito en vez de aceptar el coste.
      **Hecho**: 0,33 s · 0,31 s · 0,30 s (tres corridas en caliente, `/usr/bin/time -p`).
      Por debajo del segundo que esta tarea fijaba como tope, sobre verificaciones que en este
      repo tardan ~15 s y en AppStarter ~90 s.

## 2. La firma

- [x] 2.1 `scripts/verifica.sh` llama a esa función una vez y escribe `toolchain: …` en la
      cabecera del marker, debajo de `rama:`. Verificación: tras `/kit-verifica` en este repo,
      `grep '^toolchain: ' .agent-kit/verificacion.txt` da una línea con la versión de Swift.
      **Hecho**: la cabecera del marker de este repo dice
      `toolchain: Swift 6.4 · Xcode 27.0`, debajo de `rama:`. Una sola llamada, guardada en una
      variable, con el porqué escrito al lado: el digest y `/kit-estado` leen esa línea en vez
      de volver a detectar.
- [x] 2.2 `verifica.sh` lee la variable `LIMITES` del `kit.conf` del proyecto y escribe
      `limites: declarados` o `limites: sin declarar` en la cabecera; cuando hay texto, lo
      imprime en el cuerpo del informe bajo un rótulo, y cuando no, el informe dice que el
      proyecto no los declara. Verificación: con `LIMITES` puesto y sin él, las dos cabeceras y
      los dos informes, anotados.
      **Hecho**. Sin `LIMITES`: cabecera `limites: sin declarar` y el informe dice
      `ℹ️  este proyecto no declara los límites de su firma (LIMITES en kit.conf)`. Con
      `LIMITES`: cabecera `limites: declarados` y el informe abre
      `LO QUE ESTA FIRMA NO CUBRE, según este proyecto:` con el texto del proyecto indentado.
      La prosa va al cuerpo y no a la cabecera por D2: la cabecera se lee con `grep` línea a
      línea.
- [x] 2.3 La línea con la que se anuncia el verde deja de ser «verificación en verde, firmada
      contra el árbol verificado» y nombra el toolchain. Lo mismo la respuesta de `--comprueba`.
      Verificación: las dos líneas nuevas, copiadas aquí.
      **Hecho**, las dos líneas, copiadas tal cual:
      `✅ verde · toolchain: Swift 6.4 · Xcode 27.0 · firmado contra el árbol verificado — no dice nada de otros toolchains.`
      `✅ firma válida para este árbol · toolchain: Swift 6.4 · Xcode 27.0`
      Y la de rojo también lo nombra: `❌ 1 paso(s) en rojo · toolchain: Swift 6.4 · Xcode 27.0
      — sin firma útil`, que es cuando más importa saber con qué falló.
      *Corregido tras el juicio*: era `verde con $TOOLCHAIN`, y con `no identificado` se leía
      «verde con no identificado». Con la etiqueta funciona en los dos casos sin condicionales.

## 3. Las otras dos superficies

- [x] 3.1 `scripts/inyecta-contexto.sh`: la línea de verificación del digest nombra el toolchain
      **leyéndolo del marker**, sin detectar nada. Forma corta, una línea.
      Verificación: el digest de un árbol firmado y el de un árbol sin firmar, los dos copiados
      aquí; y `grep -c "swift --version\|xcodebuild" scripts/inyecta-contexto.sh` da 0.
      **Hecho**: `· Verificación: firmada contra el árbol actual (toolchain: Swift 6.4 · Xcode 27.0).`
      El toolchain sale del marker con un `sed`; si la firma es de otro árbol la línea queda como
      estaba, porque ahí lo que importa es que no vale. `grep -c "swift --version\|xcodebuild"`
      sobre el hook da **0**: no interroga a nada.
- [x] 3.2 `scripts/estado.sh`: `/kit-estado` enseña el toolchain de la última firma en su línea
      de verificación. Verificación: la salida, anotada.
      **Hecho**, y con el caso que más se agradece — la firma ya no valía porque había tocado
      los scripts, y aun así dijo con qué se verificó la última vez:
      ```
      ▶ Verificación
        ❌ la firma es de OTRO diff — vuelve a verificar
        última: 2026-09-17T23:53:31Z · verde · rama main
        toolchain: Swift 6.4 · Xcode 27.0 · límites del proyecto: sin declarar
      ```

## 4. Los bancos

- [x] 4.1 `scripts/verifica-salidas.sh` gana casos para: la cabecera lleva `toolchain:` y
      `limites:` tras una verificación verde; con `LIMITES` declarado el informe trae su texto;
      un marker **viejo** sin las líneas nuevas sigue siendo válido para `--comprueba` (el
      riesgo declarado en `design.md`). Verificación: el banco pasa, y falla si se le quita la
      línea `toolchain:` al marker que construye.
      **Hecho**: nueve casos nuevos en `verifica-salidas.sh` —la cabecera con `toolchain:` y
      `limites:`, el informe con y sin `LIMITES`, las dos líneas de cierre, y el marker viejo—.
      **Y muerde**: amputando la línea `echo "toolchain: $TOOLCHAIN"` del marker, el banco da
      `❌ 2 de 24 caso(s) fallan`; restaurada, `✅ verifica.sh cumple los 24 casos`.
      El caso del marker viejo es el que más vale: si `--comprueba` rechazara una firma sin los
      campos nuevos, actualizar el kit invalidaría la firma de todos los proyectos a la vez.
- [x] 4.2 `scripts/verifica-contexto.sh` gana el caso del digest con firma: nombra el toolchain
      del marker. Verificación: el banco pasa, y falla si el digest vuelve a la línea de antes.
      **Hecho**: tres casos en `verifica-contexto.sh`, que **no tenía ni uno** sobre la línea de
      verificación del digest —y es la línea que más se lee, porque llega en cada turno—. Se
      firma de verdad en el fixture en vez de fabricar el marker a mano, porque la huella tiene
      que cuadrar con el árbol. 33 casos en verde.
      Dos errores míos por el camino, los dos cazados por el propio kit: usé `igual`, que solo
      existe en el otro banco, y dejé un `caso $?` detrás de un `[ ]` que `shellcheck` señaló
      (SC2319). El segundo puso el paso `shellcheck · scripts` en rojo y por eso no hubo firma:
      la puerta funcionando.
- [x] 4.3 Sonda de la divergencia: con un `swift` falso en el PATH que diga otra versión, la
      firma y el informe lo dicen y la verificación **no** se bloquea. Verificación: la salida
      de la sonda, anotada, y el árbol restaurado después.
      **Hecho**, y como caso de banco en vez de sonda de una vez: cuesta lo mismo y no se
      pierde. Con un `swift` falso en el PATH que anuncia `Apple Swift version 9.9.9`, la salida
      trae `OJO: el swift del PATH (9.9.9) NO es el de Xcode (6.4)` y cierra con
      `✅ verde con Swift 9.9.9 · Xcode 27.0 · OJO…`: lo dice y **no** bloquea, que es lo que
      pide el requisito. 26 casos en verde.

## 5. Lo que describe la firma

- [x] 5.1 `plantillas/kit.conf.ejemplo` documenta `LIMITES`: qué es, que es opcional, y que son
      dos o tres líneas. Verificación: la plantilla lo nombra y el ejemplo se puede copiar tal
      cual.
      **Hecho**: `plantillas/kit.conf.ejemplo` documenta `LIMITES` —opcional, dos o tres
      líneas, y que viaja en la firma— con un ejemplo que se puede copiar tal cual, y con el
      caso real que hizo falta esto escrito al lado: una firma en verde con el CI en rojo doce
      corridas porque el CI compilaba con otro Xcode.
- [x] 5.2 El `kit.conf` de este repo declara sus propios `LIMITES` —empezando por el de
      shellcheck, que hoy vive en un comentario—. Verificación: `/kit-verifica` de este repo
      imprime esos límites en el informe.
      **Hecho, moviendo y no duplicando**: el bloque «LO QUE NO SE VERIFICA AQUÍ» que vivía en
      un comentario al final de `verificaciones()` **se ha ido de ahí** y ahora es el valor de
      `LIMITES`. Con eso el informe de este repo imprime sus tres límites, y `/kit-estado` dice
      `límites del proyecto: declarados`. Se le añadió el de `shellcheck --severity=warning`,
      que era un límite de cobertura real escrito en otro comentario.
- [x] 5.3 `commands/kit-verifica.md`, `commands/kit-estado.md`, `docs/` y `README.md`: lo que
      describe la firma pasa a describir su alcance. Verificación:
      `grep -rn "firmada contra el árbol verificado" commands docs README.md` sale vacío.
      **Hecho**: la descripción de `/kit-verifica`, la fila de `docs/PIEZAS.md` y la tabla del
      `README.md` —que gana la fila de «"Verificado" leído como "esto pasa", cuando solo pasó
      aquí»—. `grep -rn "firmada contra el árbol verificado" commands docs README.md` sale
      vacío.

## 6. Cierre

- [x] 6.1 `/kit-verifica` de este repo en verde, con los bancos nuevos dentro.
      Verificación: el informe, anotado.
      **Hecho**: los once pasos en verde, con los bancos dentro —28 casos en `verifica.sh` y 33
      en el hook— y el informe imprimiendo los cuatro límites que este repo declara.
- [x] 6.2 `/kit-revisa` sobre el diff: ¿esto rompe algo? Presta atención a los lectores del
      marker que no se hayan tocado (la puerta) y a un marker viejo.
      **Hecho — GREEN**. La puerta solo consume el código de salida de `--comprueba`, así que
      las líneas nuevas no la tocan; probado en fixture con marker nuevo, rojo y viejo, y
      también al revés —un `--comprueba` viejo sobre un marker nuevo—, porque `diff:` y
      `resultado:` no se movieron. Probó el ataque que yo no había pensado: `LIMITES="resultado:
      verde"` en un proyecto con un paso en rojo, para suplantar la cabecera. No entra, porque
      el `sed 's/^/    /'` indenta todo el texto del proyecto y nada llega a la columna 0.
      Y **seis mutantes** sobre copias enteras de `scripts/` para comprobar que ningún caso
      nuevo pasa por casualidad: los seis ponen rojo el banco.
      De sus seis hallazgos opcionales se aplicaron los seis: el patrón de `version_swift` ya no
      exige «Apple» —un banner de Linux se saltaba en silencio y la línea atribuía la corrida al
      Swift de `xcrun`, que es mentir en vez de callar—; `/kit-estado` ya no repite el toolchain
      cuando `--comprueba` lo trae; el caso de la divergencia ahora asierta sobre el marker y no
      solo sobre stdout; la plantilla deja de aconsejar «decláralo en un comentario», que es
      justo lo que este cambio sustituye; `README.md`, `docs/PIEZAS.md` §`verifica.sh` y
      `docs/FLUJO.md` §4 describen ya el alcance; y el límite del detector de duplicados de este
      repo entró en `LIMITES`.
- [x] 6.3 `/kit-acepta`: el cambio toca más de cinco ficheros y su contrato lo consume otro
      repositorio, así que el juez entra.
      **Hecho — ACEPTADO** en la ronda 1. Probó las cinco cláusulas y los seis escenarios
      ejecutando, no leyendo, sobre el árbol y cinco repositorios sintéticos. Los dos que le
      pedí vigilar: no queda ninguna superficie diciendo «verificado» a secas —enumeró los
      lectores del marker con `grep` en vez de creerse el «cuatro» del proposal—, y el caso sin
      toolchain identificable corre entero y firma, probado con un PATH de 965 binarios sin
      `swift`, `xcrun` ni `xcodebuild`. Remidió el coste (0,31-0,32 s) y los recuentos.
      Sus tres observaciones, aplicadas: la tarea 5.3 prometía más de lo hecho y ahora sus
      ficheros están tocados de verdad; el desglose del coste del proposal atribuía 0,004 s a un
      `xcode-select -p` que la función nunca llama, corregido con su marca; y la cláusula 2 decía
      «no son el mismo» cuando la implementación compara **versiones**, así que la cláusula pasa
      a decir eso y declara lo que no distingue.
- [ ] 6.4 Publicar la versión: `MINOR`, porque el formato de la firma gana campos y el contrato
      del `kit.conf` gana una variable, sin romper nada anterior. Verificación: la versión del
      plugin, el tag y el `/kit-estado` de un proyecto que ya la tenga instalada.
