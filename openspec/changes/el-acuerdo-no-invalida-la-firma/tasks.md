## 1. Los casos, en rojo antes que el código

- [ ] 1.1 En `scripts/verifica-salidas.sh`, una sección nueva sobre un repositorio temporal con `kit.conf`, un `openspec/changes/x/tasks.md` y un `openspec/specs/y/spec.md` commiteados, y firma verde: editar el `tasks.md` deja `--comprueba` en 0; stagearlo también; `git commit` de eso pasa por el hook; `git mv` del cambio a `archive/` más una edición en `openspec/specs/` pasa `--comprueba`; tras eso, una edición fuera de `openspec/` lo pone en 1; una edición en `openspec-notas/` lo pone en 1. Verificación: los casos que esperan 0 salen en rojo con la huella de hoy, y se anota cuántos

## 2. La huella

- [ ] 2.1 `huella_diff` en `scripts/lib-kit.sh` con `-- ':(top)' ':(top,exclude)openspec'` en las tres llamadas a `git diff`, y su comentario con la exclusión, su razón y su límite. Verificación: `verifica-salidas.sh` en verde, y el resto de bancos con los mismos recuentos
- [ ] 2.2 Comprobar que el hook generado lleva la exclusión (`grep ':(top,exclude)openspec' .agent-kit/pre-commit` tras verificar en un temporal) y que con `openspec/` limpio la huella nueva y la vieja coinciden. Verificación: anotar los dos números

## 3. Decirlo donde se lee

- [ ] 3.1 `docs/PIEZAS.md` (sección de `verifica.sh`), `commands/kit-verifica.md` y la cabecera de `scripts/verifica.sh`: la norma de stagear, verificar y commitear aparte vale para lo que está fuera de `openspec/`, y el límite va en PIEZAS. Verificación: `grep -n 'openspec/' docs/PIEZAS.md commands/kit-verifica.md scripts/verifica.sh`

## 4. Cierre

- [ ] 4.1 Los criterios de aceptación del `proposal.md`, con su resultado anotado aquí
- [ ] 4.2 Una ronda de `/kit-revisa`, con la ruta del cambio; decide el owner
- [ ] 4.3 `/kit-verifica` en verde antes de archivar, y archivar y commitear sin volver a verificar: es la prueba en vivo de este cambio
