## 1. Las citas resuelven donde corre el comando

- [x] 1.1 Las cinco citas pasan a `${CLAUDE_PLUGIN_ROOT}/…`: `commands/kit-revisa.md:25`
      (`docs/FLUJO.md`) y `:41` (`agents/aceptacion.md`), `commands/kit-acepta.md:25` y `:63`
      (`docs/FLUJO.md`), `commands/kit-verifica.md:21` (`docs/PIEZAS.md`). Verificación:
      `grep -rnoE '(^|[^}/[:alnum:]_])(docs|agents|commands|scripts|plantillas|skills|hooks)/[[:alnum:]_./-]+\.(md|sh|py|json|ejemplo)' commands agents skills`
      sale vacío —hoy devuelve esas cinco—, y `bash scripts/autocomprueba.sh` sigue en verde:
      su punto 5 comprueba que cada ruta escrita así existe.
      **Hecho.** El `grep` sale vacío, y el punto 5 de `autocomprueba.sh` da por existentes
      `docs/FLUJO.md`, `docs/PIEZAS.md` y `agents/aceptacion.md`.
- [x] 1.2 Que la ruta llega expandida al modelo. Cargar el plugin desde el árbol de trabajo
      (`claude --plugin-dir . -p` con `/ios-agent-kit:kit-revisa`, pidiéndole solo que repita
      la ruta de `FLUJO.md` que ha recibido, sin lanzar nada) y comprobar que es una ruta
      absoluta a un fichero que existe. Verificación: la ruta, anotada aquí. Si en prosa no se
      expande, las cinco citas pasan a una línea dentro de un bloque de código —donde consta
      que sí— y se repite la 1.1.
      **Hecho (2026-09-18): en prosa SÍ se expande.** Con una copia del plugin renombrada
      —`kitprueba`, para no chocar con el instalado—, sin hooks, un turno y sin herramientas,
      el modelo devolvió literal `…/plugin-prueba/docs/FLUJO.md` y
      `…/plugin-prueba/agents/aceptacion.md`, rutas absolutas a ficheros que existen. El plan
      de los bloques de código no hace falta. La copia ya está borrada.

## 2. El presupuesto se pide donde se lanza la ronda

- [x] 2.1 `commands/kit-revisa.md`: antes de la instrucción de lanzar al revisor, una frase que
      mande decir cuántas rondas se presupuestan, remitiendo a la tabla «rondas a presupuestar»
      de `FLUJO.md` por la ruta de la 1.1. La frase de la sección «Qué hacer con lo que
      devuelva» pasa a contar las rondas contra ese presupuesto. No se copia la tabla.
      Verificación: `grep -n 'que declaraste' commands/kit-revisa.md` vacío, y la mención del
      presupuesto queda por encima de la sección «Qué hacer con lo que devuelva».
      **Hecho.** El párrafo del presupuesto es el primero del comando, por encima de «Lanza
      el sub-agente»; la frase de después dice «contra ese presupuesto». `grep` vacío.

## 3. El detector dice lo que cuenta

- [x] 3.1 `scripts/busca-duplicados.py`: con `--tocados` y sin hallazgos, «✅ sin lógica
      repetida que toque este cambio (N ficheros Swift mirados).»; sin `--tocados`, la frase
      de hoy. Verificación: las dos salidas, anotadas, sobre los repos del banco.
      **Hecho.** Con `--tocados`: `✅ sin lógica repetida que toque este cambio (1 ficheros
      Swift mirados).`; sin él: `✅ sin lógica repetida en 1 ficheros Swift.`, la de hoy.
- [x] 3.2 `scripts/verifica-duplicados.sh`: el caso «con --tocados, un grupo que este cambio
      no toca no se reporta: se cuenta» exige además la forma nueva y que no salga «ficheros
      Swift que toque». Ningún caso nuevo. Verificación: el banco en verde, y ese caso en rojo
      contra el `busca-duplicados.py` de `HEAD`.
      **Hecho**: 10 casos en verde; contra el detector de `HEAD` cae ese caso y solo ese.

## 4. Cierre

- [x] 4.1 `git diff --stat`: tres comandos, `busca-duplicados.py`, `verifica-duplicados.sh` y
      este cambio. Nada de `openspec/specs/`, `docs/` ni `hooks/`.
      **Hecho**: `commands/kit-acepta.md`, `kit-revisa.md`, `kit-verifica.md`,
      `scripts/busca-duplicados.py`, `scripts/verifica-duplicados.sh` y este `tasks.md`.
- [x] 4.2 Una ronda de `/kit-revisa`, con la ruta del cambio, y decide el owner.
      **Hecho (2026-09-18): GREEN**, una ronda —la presupuestada—, 32 líneas de rodaja. Sin
      hallazgos. Comprobó por su cuenta los consumidores del mensaje (`verifica.sh` por la
      subcadena; `estado.sh` llama sin `--tocados`, la rama que no cambia), que el caso de
      banco cae contra el detector de `HEAD` y solo él, que las cinco citas las captura el
      punto 5 de `autocomprueba.sh`, y que lo que afirman los tres comandos existe donde dicen.
      No reprodujo la 1.2; descansa en el experimento anotado ahí.
      De sus tres notas opcionales se atendió una, de formato y mía: una línea de 154
      caracteres en `kit-revisa.md`, reenvuelta. Sin acción: la nota de «fallo conocido» que
      se queda en el caso del banco —es la convención de todos los casos— y el «1 ficheros»,
      que ya venía en la frase de antes.
- [x] 4.3 `/kit-verifica` en verde.
      **Hecho** sobre el árbol que se commitea, con esta anotación dentro. Once pasos en
      verde, y el informe del propio kit ya dice `✅ sin lógica repetida que toque este cambio
      (0 ficheros Swift mirados).`
