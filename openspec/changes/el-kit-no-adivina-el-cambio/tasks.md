## 1. La lib no designa uno entre varios

- [ ] 1.1 `scripts/lib-kit.sh`: `cambio_activo` rellena `ACTIVO` solo si `ACTIVOS_N` es 1, y su
      comentario dice lo que hace hoy (fuera «cuál es el activo cuando hay varios es
      arbitrario, pero estable»). Verificación: en un repo de banco con dos cambios,
      `cambio_activo` deja `ACTIVO` vacío, `ACTIVOS_N=2` y `ACTIVOS` con los dos en orden.
- [ ] 1.2 `scripts/verifica-contexto.sh`: el caso «elige el primero por orden estable» pasa a
      exigir que con varios no se elige ninguno y que la lista sale en orden `LC_ALL=C` —los
      directorios del banco ya se crean en orden inverso—. Verificación: el caso pasa con el
      hook nuevo y falla contra una copia del de `HEAD` (`HOOK_BAJO_PRUEBA=<ruta>`, con la
      copia dentro de `scripts/` y su `lib-kit.sh` de `HEAD` al lado).

## 2. El hook nombra y no afirma

- [ ] 2.1 `scripts/inyecta-contexto.sh`: con `ACTIVOS_N` mayor que 1, el bloque de design §2
      —cuántos, la frase, hasta cinco nombres con su recuento y «… y N más»—, sin tareas
      pendientes ni «FUERA de alcance». Con 1, la rama de hoy sin tocar. La cabecera del
      script («Inyecta cinco cosas») dice lo nuevo en su punto 2. Verificación: `git diff`
      del fichero no toca la rama de un solo cambio.
- [ ] 2.2 Casos de banco en `scripts/verifica-contexto.sh`, sobre el repo `dos_cambios` que ya
      existe: nombra los cambios con su recuento; no contiene «Cambio activo:», «FUERA de
      alcance» ni ninguna línea `- [ ]`; con más de cinco, dice cuántos quedan. Y uno que fije
      que con un solo cambio el digest es el de antes. Verificación: `bash
      scripts/verifica-contexto.sh` en verde.

## 3. La rodaja recibe el cambio y se ciñe a él

- [ ] 3.1 `scripts/rodaja.sh`: la ruta vale en los tres modos (design §3). El bloque que valida
      la de `--entregado` sube para servir a todos; sin ruta y con varios activos, nombra,
      pide la ruta y sale con 1 antes de imprimir tareas o diff y antes de escribir la marca.
      Verificación: `grep -n 'primero por orden' scripts/rodaja.sh` vacío.
- [ ] 3.2 El principio del cambio se calcula una vez para rodaja y `--entregado`, y la marca
      solo se usa si el suelo es su ancestro (design §4). Verificación: los dos casos de
      banco de la 3.4 sobre marcas.
- [ ] 3.3 En modo rodaja, `openspec/changes/` fuera del `git diff` (pathspec) y del bucle de
      ficheros nuevos; `--entregado` intacto (design §5). La cabecera de `rodaja.sh` declara el
      uso con ruta y el límite nuevo: lo commiteado antes del cambio no es de esta rodaja.
- [ ] 3.4 Casos de banco en `scripts/verifica-rodaja.sh`: (a) dos activos sin ruta → sale
      distinto de 0, nombra los dos, sin tareas ni diff, y `--revisada` no escribe la marca;
      (b) dos activos con ruta → las tareas son las de ese cambio; (c) marca anterior al
      principio del cambio → lo commiteado antes no sale; (d) marca posterior → empieza en la
      marca; (e) la rodaja no contiene rutas de `openspec/changes/`, trackeadas ni nuevas, y
      `--entregado` sí. El caso existente que espera el aviso «cambios activos» en
      `--entregado` sin ruta se ajusta a la parada. Verificación: `bash
      scripts/verifica-rodaja.sh` en verde.

## 4. Quien invoca pasa la ruta

- [ ] 4.1 `commands/kit-revisa.md`: el revisor corre `rodaja.sh <ruta>` y el marcado es
      `rodaja.sh --revisada <ruta>`; desaparece el párrafo «Y dile qué hacer si la rodaja
      avisa de varios cambios activos». `agents/reviewer.md`: la entrada usa la ruta y lee
      `openspec/changes/<nombre>/proposal.md`, no `openspec/changes/*/proposal.md`.
      Verificación: `grep -rn 'primero por orden' scripts commands agents docs` vacío, y
      `bash scripts/autocomprueba.sh` en verde.
- [ ] 4.2 `docs/PIEZAS.md`, sección `rodaja.sh`: el uso con ruta, el suelo y que no vuelca
      `openspec/changes/`, con el límite declarado. Sin historia: lo que hace hoy.
      Verificación: la sección no crece más de lo que dice.
- [ ] 4.3 `openspec/specs/cambio-activo/spec.md`, solo su «Purpose»: hoy dice que elegir entre
      varios es «arbitrario» y que lo exigido es que sea «estable». Pasa a decir que no se
      elige: no hay señal de cuál es el de la sesión, la lista es estable y ninguna pieza actúa
      sobre uno por orden. El requisito lo funde el archivado; el propósito no viaja en el
      delta. Verificación: `openspec validate --specs --strict` en verde.

## 5. La medición y el cierre

- [ ] 5.1 Reproducir la prueba real en un clon desechable de AppStarter (fuera de los dos
      repos): `git checkout -q fafee38`, `git checkout 0461d2a -- . && git reset -q`, y la
      marca puesta a mano en `41ed19c` (`.agent-kit/.ultima-revision`). Verificación:
      `rodaja.sh openspec/changes/los-snapshots-fijan-su-locale` dice 12 líneas de cambio y no
      vuelca nada bajo `openspec/changes/`; con el `rodaja.sh` de `HEAD`, sin ruta, dice
      «primero por orden» y más de 1700. Las dos cifras, anotadas aquí.
- [ ] 5.2 Una ronda de `/kit-revisa` —ya con la ruta—, y decide el owner. El juez no se invoca
      en este repo.
- [ ] 5.3 `/kit-verifica` en verde.
