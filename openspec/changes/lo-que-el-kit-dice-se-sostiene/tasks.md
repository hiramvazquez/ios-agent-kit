## 1. Las citas resuelven donde corre el comando

- [ ] 1.1 Las cinco citas pasan a `${CLAUDE_PLUGIN_ROOT}/…`: `commands/kit-revisa.md:25`
      (`docs/FLUJO.md`) y `:41` (`agents/aceptacion.md`), `commands/kit-acepta.md:25` y `:63`
      (`docs/FLUJO.md`), `commands/kit-verifica.md:21` (`docs/PIEZAS.md`). Verificación:
      `grep -rnoE '(^|[^}/[:alnum:]_])(docs|agents|commands|scripts|plantillas|skills|hooks)/[[:alnum:]_./-]+\.(md|sh|py|json|ejemplo)' commands agents skills`
      sale vacío —hoy devuelve esas cinco—, y `bash scripts/autocomprueba.sh` sigue en verde:
      su punto 5 comprueba que cada ruta escrita así existe.
- [ ] 1.2 Que la ruta llega expandida al modelo. Cargar el plugin desde el árbol de trabajo
      (`claude --plugin-dir . -p` con `/ios-agent-kit:kit-revisa`, pidiéndole solo que repita
      la ruta de `FLUJO.md` que ha recibido, sin lanzar nada) y comprobar que es una ruta
      absoluta a un fichero que existe. Verificación: la ruta, anotada aquí. Si en prosa no se
      expande, las cinco citas pasan a una línea dentro de un bloque de código —donde consta
      que sí— y se repite la 1.1.

## 2. El presupuesto se pide donde se lanza la ronda

- [ ] 2.1 `commands/kit-revisa.md`: antes de la instrucción de lanzar al revisor, una frase que
      mande decir cuántas rondas se presupuestan, remitiendo a la tabla «rondas a presupuestar»
      de `FLUJO.md` por la ruta de la 1.1. La frase de la sección «Qué hacer con lo que
      devuelva» pasa a contar las rondas contra ese presupuesto. No se copia la tabla.
      Verificación: `grep -n 'que declaraste' commands/kit-revisa.md` vacío, y la mención del
      presupuesto queda por encima de la sección «Qué hacer con lo que devuelva».

## 3. El detector dice lo que cuenta

- [ ] 3.1 `scripts/busca-duplicados.py`: con `--tocados` y sin hallazgos, «✅ sin lógica
      repetida que toque este cambio (N ficheros Swift mirados).»; sin `--tocados`, la frase
      de hoy. Verificación: las dos salidas, anotadas, sobre los repos del banco.
- [ ] 3.2 `scripts/verifica-duplicados.sh`: el caso «con --tocados, un grupo que este cambio
      no toca no se reporta: se cuenta» exige además la forma nueva y que no salga «ficheros
      Swift que toque». Ningún caso nuevo. Verificación: el banco en verde, y ese caso en rojo
      contra el `busca-duplicados.py` de `HEAD`.

## 4. Cierre

- [ ] 4.1 `git diff --stat`: tres comandos, `busca-duplicados.py`, `verifica-duplicados.sh` y
      este cambio. Nada de `openspec/specs/`, `docs/` ni `hooks/`.
- [ ] 4.2 Una ronda de `/kit-revisa`, con la ruta del cambio, y decide el owner.
- [ ] 4.3 `/kit-verifica` en verde.
