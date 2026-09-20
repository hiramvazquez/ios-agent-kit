# La firma no caduca por stagear lo que ya se verificó

## Why

Montando `ListaPrueba` desde cero el 2026-09-20 —un proyecto nuevo, para probar el flujo
entero— pasó esto: la verificación salió verde y su propio informe avisó de que había
ficheros trackeados sin stagear. Al hacerle caso con `git add -A`, la firma pasó a ser «de
OTRO diff» y hubo que verificar otra vez, entera. Lo stageado era exactamente el árbol que
se acababa de probar: el commit iba a llevar **más** de lo verificado, nunca menos.

Hoy eso está declarado como precio asumido: la huella cubre el árbol **y** el índice, y
`PIEZAS.md` lo llama «la norma que hay que saberse». El precio se paga porque cada lado
tapa un agujero: con la huella solo del índice, `git commit -am` mete código sin verificar;
con la del árbol sola, stagear contenido y devolver el fichero a `HEAD` deja la huella igual
mientras `git commit` se lleva el índice.

Medido el 2026-09-20 con los diez casos de `scripts/verifica-salidas.sh` reproducidos a mano
(el script de la medición está en la tarea 1.1), hay un tercer diseño que tapa los dos
agujeros sin cobrar el precio: **la huella cubre el árbol, y la puerta comprueba aparte que
el índice no diverja de él**. O sea, que ninguna ruta stageada tenga en el índice un
contenido distinto del que se verificó.

Y de paso cierra un agujero que hoy sigue abierto: si se **firma** con el índice ya
divergente, la huella de hoy firma ese par y la puerta lo deja pasar. Medido: el commit se
llevaba `veneno` y lo verificado era `uno`. Con el diseño nuevo, bloquea.

## What Changes

- `scripts/lib-kit.sh`: `huella_diff` deja de ser el sha de unos diffs y pasa a ser el de una
  **foto del árbol que hace el propio git**: `git add -A` sobre un índice propio y
  `write-tree`. Fuera, `openspec/` y `.agent-kit/`. El índice y los objetos viven en
  `~/.cache/ios-agent-kit/foto/`, fuera del repositorio, y sobreviven entre llamadas para no
  rehashear el árbol entero cada vez. Si no puede fotografiar, devuelve 1 y un valor
  irrepetible.
- `scripts/verifica.sh`: al firmar, si la foto falla, **no escribe firma** y sale con 3. Su
  `--comprueba`, el hook y el digest miran el código de salida de la foto antes que nada.

  *Corregido dos veces al implementar, el 2026-09-20.* Primero decía «el sha256 del árbol
  contra `HEAD`», el diff: no cubre los ficheros NUEVOS, que es justo lo que escribe
  `/kit-init`, y la prueba de verdad (tarea 6.4) lo tumbó. Después se hacía leyendo rutas y
  hasheándolas una a una, y eso lo tumbó el revisor con reproducción: git cita los nombres
  —comillas y tabuladores incluidos, y eso no se apaga—, un enlace roto no pasa el `[ -e ]` y
  un submódulo no se puede hashear así; en los tres casos el contenido no entraba en la foto y
  el segundo cambio era invisible. La conclusión, que es la que manda: **no parsear rutas**,
  que la foto la haga git. De paso cierra un agujero que el diff tenía: crear código después
  de verificar no invalidaba nada.
- `scripts/lib-kit.sh`: función nueva `indice_divergente`, que lista las rutas stageadas cuyo
  contenido no es el del árbol. Es lo que sustituye al diff del índice dentro de la huella.
- `scripts/verifica.sh`: `--comprueba` y el hook `pre-commit` que genera exigen las dos cosas
  —huella igual y ningún divergente— y el mensaje de bloqueo dice cuál de las dos falló.
- `scripts/verifica.sh`: al firmar, si el índice ya diverge, el informe lo dice, como ya dice
  «árbol sucio». Firmar no se impide: lo que no puede es pasar callando.
- `scripts/verifica-salidas.sh`: casos nuevos para la fricción y para el agujero, que son
  fallos vistos en un proyecto real.
- `docs/PIEZAS.md`, `docs/FLUJO.md`, `docs/INSTALACION.md`: donde hoy dicen que stagear
  invalida la firma y que hacen falta tres comandos separados, pasan a decir lo que el código
  hará: stagear lo ya verificado no invalida nada, y lo que bloquea es que el índice lleve
  algo distinto del árbol.

## Fuera de alcance

- ~~**Los ficheros sin trackear.**~~ *Sacado de «fuera de alcance» al implementar, el
  2026-09-20:* decía que seguirían fuera de la huella. Con la foto del árbol entran, porque
  son parte de lo que se compila, y era imposible dejarlos fuera sin dejar la fricción dentro:
  es el mismo hecho. Lo que git IGNORA sigue fuera, y eso no cambia.
- **Commitear menos de lo verificado**, a nivel de fichero entero: sigue permitido y sigue
  avisándose como árbol sucio. *Matiz añadido tras la ronda del revisor:* a nivel de HUNK ya
  no. Un fichero stageado a medias —`git add -p`— tiene en el índice algo que no es el árbol,
  así que la puerta lo bloquea hasta que se stagee el fichero entero o se deshaga. Es lo que
  este cambio decide a propósito: ese contenido intermedio no lo compiló nadie.
- **`openspec/`.** Sigue fuera de la huella, con la misma regla y el mismo borde.
- **Los límites de la puerta:** `--no-verify`, merges, rebases y cherry-picks siguen fuera.
- **La caída al índice sin `HEAD`.** Se queda como está.

## Criterios de aceptación

- [ ] `huella_diff` es el sha256 de una foto del árbol —el hash del contenido de cada ruta
      que difiere de `HEAD` y de cada fichero sin trackear que git no ignore—, sin `openspec/`
      ni `.agent-kit/`, y no depende del índice. *Corregido al implementar, el 2026-09-20:*
      aquí decía «el sha256 de un solo diff»; el diff no cubre los ficheros nuevos.
- [ ] Existe `indice_divergente`, con una sola definición, y la usan `verifica.sh`, su
      `--comprueba`, el hook que genera y el digest de cada turno.
- [ ] Si el árbol no se puede fotografiar —un fichero sin permiso de lectura— no se escribe
      ninguna firma, `verifica.sh` sale con 3, y `--comprueba` y la puerta rechazan. El valor
      de fallo NO es una constante.
- [ ] La huella no depende del directorio desde el que se llame.
- [ ] Con firma verde, stagear contenido que ya estaba en el árbol verificado NO invalida la
      firma: `--comprueba` sigue dando 0 y el commit pasa.
- [ ] Con firma verde, `git commit -am` sin haber editado nada después de firmar pasa.
- [ ] Si una ruta stageada tiene en el índice contenido distinto del árbol, `--comprueba` da
      1 y la puerta bloquea, aunque la huella cuadre.
- [ ] Con firma verde, stagear un fichero NUEVO que ya existía al verificar —lo que hace
      `/kit-init`— NO invalida la firma.
- [ ] Siguen bloqueando: editar el árbol tras firmar, `git commit -am` tras editarlo, borrar
      un fichero tras firmar, y CREAR un fichero después de firmar. *Corregido al implementar,
      el 2026-09-20:* aquí decía «stagear un fichero nuevo tras firmar», que mezclaba dos
      cosas. Lo que invalida es crearlo, no stagearlo; y crearlo antes no invalidaba nada, que
      era un agujero.
- [ ] Sigue sin invalidar: marcar una tarea o archivar un cambio en `openspec/`.
- [ ] Un fichero que git ignora no invalida la firma, y `.agent-kit/` queda fuera de la foto
      lo ignore el proyecto o no.
- [ ] `verifica-salidas.sh` pasa entero, con los casos nuevos incluidos.
- [ ] Ningún documento del kit sigue diciendo que stagear invalida la firma.
