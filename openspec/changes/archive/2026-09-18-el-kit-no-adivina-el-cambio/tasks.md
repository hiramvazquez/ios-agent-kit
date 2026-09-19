## 1. La lib no designa uno entre varios

- [x] 1.1 `scripts/lib-kit.sh`: `cambio_activo` rellena `ACTIVO` solo si `ACTIVOS_N` es 1, y su
      comentario dice lo que hace hoy (fuera «cuál es el activo cuando hay varios es
      arbitrario, pero estable»). Verificación: en un repo de banco con dos cambios,
      `cambio_activo` deja `ACTIVO` vacío, `ACTIVOS_N=2` y `ACTIVOS` con los dos en orden.
      **Hecho.** Con dos cambios: `ACTIVO=[]`, `ACTIVOS_N=2`, la lista en orden; con uno,
      `ACTIVO` es ese; con ninguno, vacío. La función devuelve 0 en los tres casos.
- [x] 1.2 `scripts/verifica-contexto.sh`: el caso «elige el primero por orden estable» pasa a
      exigir que con varios no se elige ninguno y que la lista sale en orden `LC_ALL=C` —los
      directorios del banco ya se crean en orden inverso—. Verificación: el caso pasa con el
      hook nuevo y falla contra una copia del de `HEAD` (`HOOK_BAJO_PRUEBA=<ruta>`, con la
      copia dentro de `scripts/` y su `lib-kit.sh` de `HEAD` al lado).
      **Hecho.** El caso exige ahora el orden `LC_ALL=C` entero de la lista. Contra el hook y
      la lib de `HEAD` (copiados a un directorio aparte: el hook carga la lib del suyo, no hace
      falta que sea `scripts/`) cae; con los nuevos pasa.

## 2. El hook nombra y no afirma

- [x] 2.1 `scripts/inyecta-contexto.sh`: con `ACTIVOS_N` mayor que 1, el bloque de design §2
      —cuántos, la frase, hasta cinco nombres con su recuento y «… y N más»—, sin tareas
      pendientes ni «FUERA de alcance». Con 1, la rama de hoy sin tocar. La cabecera del
      script («Inyecta cinco cosas») dice lo nuevo en su punto 2. Verificación: `git diff`
      del fichero no toca la rama de un solo cambio.
      **Hecho.** De la rama de un solo cambio el diff solo quita el aviso de «hay N cambios
      activos», que ya no se alcanza y llevaba la frase que el criterio manda borrar. El digest
      de un repo con un cambio activo —este— es byte a byte el del hook de `HEAD` (1640 bytes).
- [x] 2.2 Casos de banco en `scripts/verifica-contexto.sh`, sobre el repo `dos_cambios` que ya
      existe: nombra los cambios con su recuento; no contiene «Cambio activo:», «FUERA de
      alcance» ni ninguna línea `- [ ]`; con más de cinco, dice cuántos quedan. Y uno que fije
      que con un solo cambio el digest es el de antes. Verificación: `bash
      scripts/verifica-contexto.sh` en verde.
      **Hecho**: 36 casos en verde; contra el hook de `HEAD` caen los cinco nuevos y ninguno
      más. El fixture `dos_cambios` tiene CINCO cambios, no dos; para «más de cinco» el caso
      crea dos directorios más. La mitad de «un solo cambio» la cubrían ya tres casos de «lo
      que ya hacía»; el que nombra el cambio exige además que no salga la forma de varios, y
      caza una frontera mal puesta (`-ge 1`): comprobado con esa mutación.

## 3. La rodaja recibe el cambio y se ciñe a él

- [x] 3.1 `scripts/rodaja.sh`: la ruta vale en los tres modos (design §3). El bloque que valida
      la de `--entregado` sube para servir a todos; sin ruta y con varios activos, nombra,
      pide la ruta y sale con 1 antes de imprimir tareas o diff y antes de escribir la marca.
      Verificación: `grep -n 'primero por orden' scripts/rodaja.sh` vacío.
      **Hecho.** Un argumento que no es un flag es la ruta. La resolución y la parada van antes
      de cualquier salida y antes de `--revisada`. `grep` vacío.
- [x] 3.2 El principio del cambio se calcula una vez para rodaja y `--entregado`, y la marca
      solo se usa si el suelo es su ancestro (design §4). Verificación: los dos casos de
      banco de la 3.4 sobre marcas.
      **Hecho.** `SUELO` se calcula una vez; `--entregado` parte de él y la rodaja lo usa de
      suelo. Cuando la marca se descarta, la cabecera lo dice («la marca era anterior a él») y
      las tareas salen como primera revisión del cambio, no comparadas con una foto ajena.
- [x] 3.3 En modo rodaja, `openspec/changes/` fuera del `git diff` (pathspec) y del bucle de
      ficheros nuevos; `--entregado` intacto (design §5). La cabecera de `rodaja.sh` declara el
      uso con ruta y el límite nuevo: lo commiteado antes del cambio no es de esta rodaja.
      **Hecho**, con una función `diferencia` para los dos `git diff` y un `case` en el bucle
      de ficheros nuevos.
- [x] 3.4 Casos de banco en `scripts/verifica-rodaja.sh`: (a) dos activos sin ruta → sale
      distinto de 0, nombra los dos, sin tareas ni diff, y `--revisada` no escribe la marca;
      (b) dos activos con ruta → las tareas son las de ese cambio; (c) marca anterior al
      principio del cambio → lo commiteado antes no sale; (d) marca posterior → empieza en la
      marca; (e) la rodaja no contiene rutas de `openspec/changes/`, trackeadas ni nuevas, y
      `--entregado` sí. El caso existente que espera el aviso «cambios activos» en
      `--entregado` sin ruta se ajusta a la parada. Verificación: `bash
      scripts/verifica-rodaja.sh` en verde.
      **Hecho**: 20 casos en verde (eran 14; con el de la 5.2, 21). Contra el `rodaja.sh` y la lib de `HEAD` caen
      cinco de los seis nuevos; el sexto —marca dentro del cambio— pasa con los dos, que es lo
      que fija: «como hoy». Dos mutaciones comprobadas: invertir la comprobación de ancestro
      tumba (c) y (d); quitar el `exit 1` tumba los dos de (a). No había ningún caso que
      esperase el aviso en `--entregado` sin ruta, así que no hubo nada que ajustar ahí; sí se
      reescribió un texto de fallo que llevaba la frase retirada.

## 4. Quien invoca pasa la ruta

- [x] 4.1 `commands/kit-revisa.md`: el revisor corre `rodaja.sh <ruta>` y el marcado es
      `rodaja.sh --revisada <ruta>`; desaparece el párrafo «Y dile qué hacer si la rodaja
      avisa de varios cambios activos». `agents/reviewer.md`: la entrada usa la ruta y lee
      `openspec/changes/<nombre>/proposal.md`, no `openspec/changes/*/proposal.md`.
      Verificación: `grep -rn 'primero por orden' scripts commands agents docs` vacío, y
      `bash scripts/autocomprueba.sh` en verde.
      **Hecho.** `grep` vacío en `scripts commands agents docs`; `autocomprueba.sh`: «kit sano».
- [x] 4.2 `docs/PIEZAS.md`, sección `rodaja.sh`: el uso con ruta, el suelo y que no vuelca
      `openspec/changes/`, con el límite declarado. Sin historia: lo que hace hoy.
      Verificación: la sección no crece más de lo que dice.
      **Hecho, y una línea más de lo que decía esta tarea**: la sección del hook de
      `docs/PIEZAS.md` describía «el cambio activo con sus tareas y su fuera de alcance» sin
      matiz, y la regla del repo es que la doc cambia con el comportamiento en el mismo
      cambio. Gana un párrafo de cuatro líneas sobre varios cambios activos. `docs/FLUJO.md`
      no se toca: lo que dice sigue siendo cierto con un cambio activo, y el uso vive en
      PIEZAS.
- [x] 4.3 `openspec/specs/cambio-activo/spec.md`, solo su «Purpose»: hoy dice que elegir entre
      varios es «arbitrario» y que lo exigido es que sea «estable». Pasa a decir que no se
      elige: no hay señal de cuál es el de la sesión, la lista es estable y ninguna pieza actúa
      sobre uno por orden. El requisito lo funde el archivado; el propósito no viaja en el
      delta. Verificación: `openspec validate --specs --strict` en verde.
      **Hecho.** `openspec validate --specs --strict`: 11 de 11.

## 5. La medición y el cierre

- [x] 5.1 Reproducir la prueba real en un clon desechable de AppStarter (fuera de los dos
      repos): `git checkout -q fafee38`, `git checkout 0461d2a -- . && git reset -q`, y la
      marca puesta a mano en `41ed19c` (`.agent-kit/.ultima-revision`). Verificación:
      `rodaja.sh openspec/changes/los-snapshots-fijan-su-locale` dice 12 líneas de cambio y no
      vuelca nada bajo `openspec/changes/`; con el `rodaja.sh` de `HEAD`, sin ruta, dice
      «primero por orden» y más de 1700. Las dos cifras, anotadas aquí.
      **Hecho (2026-09-18)**, en un clon en el scratchpad, ya borrado. Con el `rodaja.sh` de
      `HEAD` y sin ruta: `⚠️  hay 2 cambios activos; se mira «el-ci-fija-el-xcode-con-el-que-prueba»,
      el primero por orden.`, la tarea 4.1 del otro cambio, y `RODAJA A REVISAR (desde la última
      revisión): 1742 líneas de cambio`. Con el nuevo y la ruta: `RODAJA A REVISAR (desde el
      principio de este cambio: la marca era anterior a él): 12 líneas de cambio`, cero rutas
      bajo `openspec/changes/`, y tres ficheros: `project.yml` y los dos PNG. Sin ruta, el
      nuevo nombra los dos cambios y para.
- [x] 5.2 Una ronda de `/kit-revisa` —ya con la ruta—, y decide el owner. El juez no se invoca
      en este repo.
      **Hecho (2026-09-18): AMBER**, una ronda, 339 líneas de rodaja —con la ruta, desde el
      principio del cambio—. Dio por bueno: bancos en verde bajo bash 3.2, `--entregado` byte a
      byte igual que en `HEAD`, el digest de un solo cambio idéntico, y los casos nuevos caen
      al romper el suelo, la exclusión o el salto de ficheros nuevos. Dos hallazgos:
      (1) **una regresión mía, reproducida**: con la propuesta sin commitear el suelo era
      `HEAD`, que se mueve; un commit del cambio posterior a la marca quedaba por debajo, la
      marca se descartaba y ese commit no salía —`2 líneas` donde el script de `HEAD` daba 4,
      con el código—, y el `--revisada` siguiente lo enterraba. **Decisión del owner**: el
      arreglo de una línea, sin segunda ronda. Sin principio conocido la marca se respeta; se
      van el recurso a `HEAD` y su mensaje. Caso de banco nuevo, que cae contra la versión
      revisada y solo él. El acuerdo se enmendó por escrito: cláusula 3 y un escenario en el
      delta de `coste-del-juicio`, `design.md` §4, `proposal.md` y `docs/PIEZAS.md`.
      (2) `agents/aceptacion.md:29` contaba que `--entregado` sin argumento «vuelve a elegir el
      primer cambio por orden»: corregido. El `grep` del criterio no lo cazó porque la frase
      era otra, y `proposal.md` decía que ese fichero no cambiaba: enmendado.
      Sin acción, anotadas: ningún banco fija que `ACTIVO` quede vacío con varios —los dos
      consumidores miran antes `ACTIVOS_N`—; la foto de tareas de la marca es una por
      checkout, así que marcar un cambio y pedir la rodaja de otro sobre-informa; y
      `rodaja.sh --revisada` sin ruta, que sigue valiendo con un solo cambio activo, es lo que
      enseñan el aviso de rodaja gorda y `docs/FLUJO.md`.
- [x] 5.3 `/kit-verifica` en verde.
      **Hecho** sobre el árbol que se commitea, con esta anotación dentro: la firma es de ese
      árbol o la puerta no deja pasar el commit. Diez pasos en verde; en la primera pasada cayó
      «variables pegadas» por un `$t»` mío en el banco de contexto, corregido a `${t}`.
