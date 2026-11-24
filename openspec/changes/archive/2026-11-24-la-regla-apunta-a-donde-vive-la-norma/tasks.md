## 1. El texto

- [x] 1.1 `openspec/config.yaml`, primera regla: donde dice «`hooks/hooks.json` lo dice en su
      `_nota`: …», un puntero a `docs/PIEZAS.md` (sección `inyecta-contexto.sh`) sin repetir la
      norma, conservando la frase de que la puerta de commit es un hook de git y no de Claude
      Code. Verificación: `grep -c _nota openspec/config.yaml` da 0 y la regla enlaza a PIEZAS.
      **Hecho (2026-09-30).** El YAML carga, y `docs/PIEZAS.md:137-139` tiene la norma a la
      que apunta.
- [x] 1.2 *Retirada al implementar, el 2026-09-30.* Era una frase en el paso 2 de
      `commands/kit-init.md`: si hay app de Xcode, `kit.conf` lleva su paso o el comando no ha
      terminado. Se retiró porque su motivo era falso; la prueba y la evidencia están en 2.1 y
      en el proposal, «Lo que este cambio iba a llevar y no lleva». Verificación:
      `git diff HEAD -- commands/kit-init.md` está vacío.

## 2. La prueba real

- [x] 2.1 Corrida real de `/kit-init`, no interactiva, con el texto de este árbol, y mirar si el
      `kit.conf` que sale lleva el paso de la app.
      **Hecho (2026-09-30), y lo que enseñó tumbó la 1.2.** Tres corridas, todas como
      subagente con el texto del comando y las mismas herramientas —el OAuth del `claude` de
      terminal estaba caducado—, todas comprobadas en disco:
      1. Clon de AppStarter sin `kit.conf` ni `openspec/`, texto nuevo: paso de la app y verde.
         El revisor (3.1) la tumbó: el clon conservaba la historia, el agente leyó
         `HEAD~1:kit.conf` y lo copió. No discriminaba.
      2. Control: proyecto mínimo de cero (`scratchpad/lista-base`: app SwiftUI con xcodegen,
         `ListaTests`, paquete `Core` con test; sin historia útil, sin CI, sin `AGENTS.md`),
         **texto de `HEAD`**: paso «Lista · build + tests» con `xcodebuild … -scheme Lista`, y
         firma verde a la primera.
      3. No hizo falta la corrida con el texto nuevo: el transcript del 2026-09-20 enseña que
         las dos veces en ListaPrueba el texto viejo también metió la app (`paso "app · build +
         AppTests"`, escrituras de 01:41 y 03:59). Tres de tres: no hay fallo que arreglar.
      Hallazgo ajeno a este cambio, apuntado: en esta máquina `iPhone 17 Pro` solo existe en
      el runtime iOS 26.5, y Xcode 27 resuelve `name=` contra el 27.0, así que `name=iPhone 17
      Pro` falla con «Unable to find a device». Es la nota «por id» del runbook, ahora con
      causa. La plantilla usa `iPhone 17`, que está en los dos runtimes.

## 3. Cierre

- [x] 3.1 `/kit-revisa`, una ronda; decide el owner. Verificación: el veredicto y la decisión,
      anotados aquí.
      **Ronda 1 (2026-09-30): AMBER**, presupuesto de una. Un hallazgo: la prueba de la 2.1 no
      distinguía el texto nuevo del viejo (el clon con historia). Se rehízo la prueba y el
      control con el texto viejo pasó: la 1.2 se retiró y el cambio se renombró. Tres
      opcionales del revisor sin tocar: una app sin target de tests no podría cumplir la frase
      literal (ya no hay frase); `find -maxdepth 1` no ve un `.xcodeproj` en subdirectorio (ya
      pasaba, fuera del encargo); y «son los dos» en la regla nueva es redacción.
      **Decisión del owner (2026-11-24):** se cierra así, con la única pieza que queda.
- [x] 3.2 `scripts/verifica.sh` en verde, archivar el cambio y commitear a `main` en un solo
      commit, sin subir la versión. Verificación: `git log -1` lo enseña y `openspec list` no
      tiene cambios activos.
      **Hecho (2026-11-24).** El cambio esperó casi dos meses la decisión y `main` avanzó de
      la 2.3.0 a la 2.4.1 entretanto, así que se volvió a comprobar contra el árbol de hoy
      antes de archivar: `openspec/config.yaml` de `HEAD` seguía citando la `_nota`,
      `hooks/hooks.json` sigue sin esa clave y con sus dos hooks, y la norma sigue en
      `docs/PIEZAS.md`, en la sección de `inyecta-contexto.sh` (hoy en las líneas 145-147; el
      «137-139» de la 1.1 es del 2026-09-30). Verificación verde con Swift 6.4 · Xcode 27.0.
