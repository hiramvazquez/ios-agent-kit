## 1. El hook, y su banco antes que él

- [ ] 1.1 En `scripts/verifica-salidas.sh`, casos nuevos sobre un repositorio temporal con `kit.conf`: tras verificar existe el hook con la marca y es ejecutable; `git commit` con índice firmado pasa; `git commit -am` tras editar bloquea; `git commit <pathspec>` tras editar bloquea; `git -C <repo> commit` desde fuera sin firma bloquea; `cd ~/…` con `HOME` apuntado al temporal bloquea; primer commit sin `HEAD` pasa; hook ajeno queda igual y el informe lo nombra; con `core.hooksPath` no se escribe en `.git/hooks`. Verificación: todos en rojo antes de tocar `verifica.sh`
- [ ] 1.2 `verifica.sh`: función que escribe el hook según D2 y D3 en `$(git rev-parse --git-path hooks)`, llamada tanto en verde como en rojo, con la línea del informe la primera vez y el aviso con hook ajeno. Verificación: los casos de 1.1 en verde
- [ ] 1.3 Vaciar el hook generado a mano y correr el banco: los casos de bloqueo caen. Verificación: anotar cuántos caen

## 2. Restar

- [ ] 2.1 Borrar `scripts/puerta-commit.sh`, `scripts/analiza-invocacion.py` y `scripts/verifica-puerta.sh`; quitar `PreToolUse` de `hooks/hooks.json` y su `_nota` pasa a dos hooks; quitar el paso «puerta de commit» de `kit.conf`. Verificación: `bash scripts/autocomprueba.sh` en verde y `ls scripts/` sin los tres
- [ ] 2.2 `scripts/estado.sh`: la línea de si la puerta está instalada. Verificación: en este repositorio dice que sí tras verificar, y que no en un temporal sin verificar

## 3. Decirlo

- [ ] 3.1 `docs/PIEZAS.md`: la sección de la puerta describe el hook de git, qué no frena, y el caso del hook ajeno; `README.md`, `docs/FLUJO.md` (paso 8), `docs/INSTALACION.md` («la puerta bloquea…»), `commands/kit-verifica.md`, `openspec/config.yaml`: dos hooks, y ninguna mención a `PreToolUse` ni al analizador. Verificación: el `grep -rn` del criterio de aceptación vacío
- [ ] 3.2 La spec viva `puerta-de-commit`: el delta de este cambio la sustituye al archivar; comprobar con `openspec validate la-puerta-es-de-git`

## 4. Cierre

- [ ] 4.1 Correr los criterios de aceptación del `proposal.md` y anotar el resultado
- [ ] 4.2 `/kit-revisa`, una ronda; decide el owner
- [ ] 4.3 `/kit-verifica` en verde, y comprobar que en este mismo repositorio el hook quedó instalado y bloquea un commit sin firma
