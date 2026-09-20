## 1. La medición, antes de tocar nada

- [x] 1.1 Reproducir a mano los casos que la spec fija hoy, con las dos huellas en paralelo, y
      comprobar que el diseño nuevo los conserva, quita la fricción y cierra el caso de firmar
      con el índice divergente. Verificación: la tabla, anotada.
      **Hecho (2026-09-20)**, con `scratchpad/mide-firma.sh`, diez casos:
      conservados los seis que la spec fija —árbol limpio pasa; editar tras firmar bloquea;
      `commit -a` tras editar bloquea; fichero nuevo stageado bloquea; solo `openspec/` pasa;
      índice envenenado tras firmar bloquea—; la fricción desaparece en los dos casos que la
      producían (stagear lo ya verificado, y `commit -a` sin editar nada); y el caso 9 —se
      firma con el índice ya divergente— pasa de `PASA` a `BLOQUEA`: el commit se llevaba
      `veneno` con `uno` verificado.

## 2. La huella y la divergencia

- [x] 2.1 En `scripts/lib-kit.sh`, `huella_diff` pasa a ser el sha256 de una FOTO DEL ÁRBOL:
      el hash del contenido de cada ruta que difiere de `HEAD` y de cada fichero sin trackear
      que git no ignore, sin `openspec/` ni `.agent-kit/`. Sin `HEAD`, las rutas salen del
      índice. Verificación: la misma huella con lo stageado y sin stagear.
      **Corregida al implementar, el 2026-09-20:** esta tarea decía «el sha256 del árbol contra
      `HEAD`», o sea el diff. La tarea 6.4 lo tumbó: un fichero NUEVO no está en `git diff
      HEAD` hasta que se stagea, así que `git add -A` de lo que escribe `/kit-init` seguía
      invalidando la firma. La foto no depende del índice.
      **Hecho:** medido con `scratchpad/mide-foto.sh`, doce casos. Con la foto, stagear —un
      fichero trackeado, uno nuevo, o `git add -A` de todo— no mueve la huella; crear o borrar
      un fichero sí; y lo que git ignora, no.
- [x] 2.1-bis *Añadida al implementar, el 2026-09-20:* `.agent-kit/` queda fuera de la foto
      SIEMPRE, lo ignore el proyecto o no. Lo destapó el banco: el marcador de la firma vive
      ahí, y dentro de la foto escribirlo invalidaba la firma recién escrita —doce casos del
      banco en rojo a la vez—. Verificación: el banco vuelve a pasar entero.
      **Hecho:** los cinco pathspecs de `lib-kit.sh` excluyen `.agent-kit/`.
- [x] 2.2 En `scripts/lib-kit.sh`, función nueva `indice_divergente`: las rutas stageadas cuyo
      contenido no es el del árbol, con los mismos pathspecs que la huella. Verificación: en un
      repositorio de prueba, lista la ruta envenenada y no lista nada tras `git add` de lo ya
      verificado.
      **Hecho:** `indice_divergente` es el `comm -12` de las rutas stageadas con las que difieren entre índice y árbol, con los mismos pathspecs. Probada en los casos nuevos del banco.
- [x] 2.3 Reescribir el comentario de las dos funciones para que diga lo que hacen hoy: por qué
      la huella es de un solo lado, qué cierra la otra comprobación, y los límites que quedan.
      Verificación: el comentario no dice que stagear invalide la firma.
      **Hecho:** los dos comentarios dicen qué cubre cada pieza, por qué se separaron las dos preguntas y qué límites quedan (lo no trackeado y `openspec/`).

## 3. Quien juzga la firma

- [x] 3.1 `verifica.sh --comprueba` exige huella igual **y** ningún divergente, y dice cuál de
      las dos falló. Verificación: los dos mensajes, vistos en un repositorio de prueba.
      **Hecho:** `--comprueba` exige las tres cosas y, cuando falla por el índice, imprime las rutas y dice que se commitea el índice, no el árbol.
- [x] 3.2 El hook `pre-commit` que genera `verifica.sh` lleva copiadas las dos funciones y
      aplica la misma regla; su mensaje nombra las rutas divergentes y deja de pedir tres
      comandos separados. Verificación: el hook generado contiene `indice_divergente`.
      **Hecho:** el hook lleva las dos funciones con `declare -f` y comprueba la divergencia ANTES que la huella, para que el mensaje sea el específico. Su cabecera y su mensaje ya no piden tres comandos separados.
- [x] 3.3 Al firmar, si el índice diverge, el informe lo dice con sus rutas, como ya dice árbol
      sucio. Verificación: el aviso, visto en un repositorio de prueba.
      **Hecho:** aviso `ÍNDICE DIVERGENTE` en el informe, con sus rutas, junto al de árbol sucio. Firmar no se impide (design D4).

## 4. El banco

- [x] 4.1 Casos nuevos en `scripts/verifica-salidas.sh`, nacidos de la prueba en `ListaPrueba`:
      stagear lo ya verificado no invalida; `commit -a` sin editar pasa; firmar con el índice
      divergente no deja commitear; el mensaje nombra la ruta. Verificación: el banco pasa
      entero, con su recuento nuevo.
      **Hecho:** 18 casos nuevos en tres secciones —las dos de la fricción y el agujero del
      índice, más la de la foto del árbol: stagear un fichero nuevo, crearlo después de
      firmar, borrarlo, uno ignorado, y que escribir la firma no se invalide a sí misma—. El
      banco pasa entero: 76 casos.
- [x] 4.2 Revisar los casos que fijaban la conducta vieja y ajustarlos, sin borrar lo que
      siguen probando. Verificación: ningún caso del banco espera que stagear invalide.
      **Hecho:** dos casos ajustados. El de «stagear después de firmar bloquea» pasa a decir la razón real —el árbol cambió— y el del mensaje de la puerta comprueba el texto nuevo. Ninguno se borró.

## 5. La prosa

- [x] 5.1 `docs/PIEZAS.md`: la sección de la firma dice lo que hace hoy —huella del árbol y
      comprobación aparte del índice— y qué bloquea. Verificación: no queda «stagear después
      de firmar invalida la firma» ni «tres comandos separados».
      **Hecho:** la sección de `verifica.sh` y la de la puerta dicen la regla nueva, con el aviso de índice divergente.
- [x] 5.2 `docs/FLUJO.md` y `docs/INSTALACION.md`: lo mismo, allí donde lo repiten.
      Verificación: `grep -rn 'tres comandos\|invalida la firma' docs/ README.md` sale vacío o
      solo sobre lo que sigue siendo cierto.
      **Hecho:** INSTALACION, `/kit-verifica` y `/kit-init` ya no dicen que stagear invalide. `/kit-init` además deja de exigir stagear antes de verificar.
- [x] 5.3 Que la norma viva en un solo sitio: los demás documentos enlazan a PIEZAS en vez de
      repetirla. Verificación: la explicación completa aparece una vez.
      **Hecho:** la explicación completa vive en PIEZAS; los demás enlazan o la resumen en una línea.

## 6. Cierre

- [x] 6.1 `openspec validate la-firma-no-caduca-por-stagear --strict` en verde.
      **Hecho:** `Change 'la-firma-no-caduca-por-stagear' is valid`. La autocomprobación del kit también sale verde.
- [x] 6.2 `/kit-revisa` sobre el diff. Presupuesto: una ronda. Verificación: el veredicto.
      **Ronda 1 (2026-09-20): RED**, con reproducción, y tenía razón.
      - **RED — rutas que git cita.** `core.quotePath` viene en `true`, así que
        `git diff --name-only` y `ls-files --others` imprimen `"Dise\303\261o.swift"` para
        cualquier ruta con un byte no ASCII. El `[ -e ]` no encontraba el fichero, la ruta caía
        en la rama BORRADO y su contenido NO se hasheaba: reescribir entero un `Diseño.swift`
        después de firmar daba la misma huella y el commit entraba sin verificar. Reproducido
        aquí antes de tocar nada. Arreglado en la causa: `-c core.quotePath=false` en las cinco
        llamadas a git de `lib-kit.sh`. Seis casos nuevos de banco lo fijan.
      - **AMBER — el digest mentía.** `inyecta-contexto.sh` juzgaba la firma solo con la
        huella, así que con el índice divergente decía «firmada contra el árbol actual» mientras
        la puerta bloqueaba. Ahora hace las mismas dos preguntas, con caso de banco en
        `verifica-contexto.sh`.
      - **AMBER — `.build/` stageado.** Se me coló con un `git add -A`; además, sin ignorarlo,
        cada `swift build` caducaría la firma. Añadido a `.gitignore` y sacado del índice.
      - **Nota — stagear por hunks.** Con la comprobación del índice, un fichero a medias queda
        bloqueado hasta stagear el árbol. Es coherente con el diseño y se dice en el proposal.
      Como los arreglos cambian lo que hace el código, va segunda vuelta del mismo revisor.
      **Ronda 2: RED.** `core.quotePath=false` tapaba el caso que reportó, no la causa: git cita
      también comillas y tabuladores, un enlace roto no pasa el `[ -e ]` y un submódulo no lo
      puede hashear `git hash-object`. Y peor, **mis seis casos de banco pasaban con el código
      roto**: probaban la primera transición de la ruta, que se detecta aunque el contenido no
      entre. Arreglado dejando de parsear rutas: la foto la hace git. Casos rehechos en DOS
      pasos, y comprobado mutando a la implementación vieja (5 en rojo, antes 0).
      **Ronda 3: RED, y el peor de los tres.** `SIN-HUELLA` era una CONSTANTE: si la causa del
      fallo persistía —un fichero sin permiso de lectura, Git LFS sin instalar— se firmaba esa
      cadena y después cuadraba consigo misma; desde ahí cualquier árbol valía. Arreglado con
      las tres cosas: valor irrepetible, quien firma se niega a firmar, y todos los que juzgan
      miran el código de salida. Sus dos ámbar también: el coste (caché fuera del repositorio,
      y de paso apareció que dentro el `add -A` se añadía a sí mismo, 27 casos rojos) y la
      huella, que dependía del directorio desde el que se llamara. Ocho casos de banco nuevos.
      Va cuarta vuelta: estos arreglos vuelven a cambiar lo que hace el código.
      **Ronda 4: AMBER**, y ningún camino para commitear sin verificar. Comprobó además que el
      caché roto, de solo lectura o borrado a media foto falla cerrado; que dos repositorios en
      la misma ruta reciclada no se confunden; que el `rm --cached` no toca el índice real; y
      que un `touch -r` conservando el mtime no engaña a la foto. Tres cosas finas, arregladas:
      dos fotos simultáneas se disputaban el índice del caché —8 de 20 fallaban y el perdedor
      rechazaba un commit bueno culpando a un fichero ilegible inexistente—, así que cada foto
      trabaja sobre su copia y la devuelve con un `mv` atómico (medido: 0 de 10, y sin restos);
      el valor de fallo solo era irrepetible entre procesos, porque una subshell hereda
      `$RANDOM`, y ahora lleva un contador propio; y el presupuesto de 0,3 s por turno, que el
      banco del hook y este diseño decían al revés, queda explicado donde estaba: no es un tope
      de gasto, es que un dato ya escrito no se recalcula. Tres casos de banco nuevos. El
      fichero llamado `openspec` se queda fuera de la foto, decidido con él, y la spec lo dice.
      **Ronda 5: AMBER, y cierre.** Confirmó la concurrencia arreglada —0 de 20 fotos
      simultáneas fallan, todas con la misma huella y sin restos— y que el caché roto,
      inmutable o ilegible degrada bien. Tres apuntes de una línea, arreglados: mi caso de los
      restos miraba el `$HOME` real en vez del del banco (ni veía lo suyo ni era reproducible);
      una foto interrumpida dejaba su copia para siempre (ahora verificar tira las de más de
      una hora, nunca las recientes); y un caché corrupto dejaba la foto rota para siempre con
      un mensaje que mandaba a otro sitio (ahora se tira al fallar, se cura solo, y el mensaje
      lo nombra). Corregí además una afirmación falsa mía: el contador NO hace irrepetible el
      valor dentro del mismo proceso, porque la subshell no lo devuelve; el comentario ahora
      dice lo que hace.
      **Y un fallo que no vio ningún revisor, lo cazó el banco:** al partir la foto en varias
      funciones, el hook seguía copiando solo dos con `declare -f`, así que dentro de la puerta
      quedaban indefinidas y BLOQUEABA CUALQUIER COMMIT (11 casos en rojo). Arreglado copiando
      las cuatro, con un caso nuevo que corre el hook en un shell limpio y comprueba que no
      dice «command not found».
      **Decisión del owner (Hiram, 2026-09-20): se cierra aquí**, sin sexta ronda. Los arreglos
      de la quinta son tres líneas, cada una con su caso de banco.
- [x] 6.3 `/kit-verifica` en verde en este repositorio. Verificación: la firma, anotada.
      **Hecho (2026-09-20):** verde, con los dos bancos dentro —94 casos en `verifica-salidas`
      y 38 en `verifica-contexto`— y la autocomprobación del kit. Firma `diff: 4d3712df…`.
- [x] 6.4 **La prueba de verdad**: borrar `ListaPrueba` y rehacerla entera con el kit
      arreglado —generar, `/kit-init`, un cambio, revisar, verificar, archivar y commitear—
      sin que aparezca ninguna de las dos fricciones. Verificación: anotado qué pasó al
      stagear después de verificar, y si el descubrimiento de `/kit-init` encuentra el
      `.xcodeproj` y el `project.yml`.
      **Hecha dos veces (2026-09-20).** La primera tumbó el primer diseño de este cambio: la
      huella del diff no cubría los ficheros NUEVOS que escribe `/kit-init`, así que
      `git add -A` seguía invalidando la firma. De ahí salió la foto del árbol.
      **La segunda, con el kit ya arreglado, salió limpia:**
      - el descubrimiento de `/kit-init` encuentra el `.xcodeproj` y el `project.yml` (con
        `ls` y patrones, en zsh, la línea entera se perdía);
      - verificar sin stagear nada y hacer `git add -A` después —kit.conf, `openspec/`,
        `.claude/`, el `.gitignore`— deja la firma VÁLIDA, y el commit pasa la puerta a la
        primera. Antes costaba repetir la verificación entera;
      - tocar un fichero después de firmar la invalida, y deshacer el cambio la devuelve;
      - el cambio del proyecto se acordó, implementó, revisó (AMBER, un hallazgo real),
        verificó, archivó y commiteó: `83fe4e4`, `7bb1ad1`, `c315185`, con la app mostrando
        productos reales de DummyJSON en el simulador.