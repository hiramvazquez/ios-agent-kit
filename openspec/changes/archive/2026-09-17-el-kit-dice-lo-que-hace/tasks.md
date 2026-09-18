## 1. Referencia

- [x] 1.1 Guardar en el scratchpad la salida de `bash scripts/inyecta-contexto.sh </dev/null` sobre este repositorio y la última línea de cada `bash scripts/verifica-*.sh`; verificar que los seis bancos están en verde antes de tocar nada

## 2. Scripts y kit.conf: solo comentarios

- [x] 2.1 `scripts/lib-kit.sh`: cada función con qué hace, por qué existe y su límite, sin fechas; verificar con `bash -n`, `shellcheck --severity=warning` y que `grep -c 2026-09- scripts/lib-kit.sh` da 0
- [x] 2.2 `scripts/inyecta-contexto.sh`, `scripts/verifica.sh`, `scripts/rodaja.sh`, `scripts/estado.sh`, `scripts/doc-paquetes.sh`, `scripts/autocomprueba.sh`, `scripts/puerta-commit.sh` (solo lo que no sea la cabecera de límites), `scripts/analiza-invocacion.py`, `scripts/busca-duplicados.py`: mismo criterio; verificar `bash -n`, `python3 -m py_compile`, `shellcheck`, y los seis bancos en verde
- [x] 2.3 Los seis bancos y `scripts/lib-banco.sh`: comentario histórico fuera, los casos intactos; verificar que cada banco imprime el mismo recuento de casos que en 1.1
- [x] 2.4 `kit.conf`, `plantillas/kit.conf.ejemplo`, `plantillas/openspec-config.yaml.ejemplo`: comentarios sin historia; verificar `bash scripts/verifica.sh` en verde y `grep -c 2026-09-` a 0 en los tres
- [x] 2.5 Comparar el digest con la referencia de 1.1: `diff` vacío. Verificar que ningún script tiene más comentario que código con el bucle del criterio de aceptación

## 3. Specs vivas

- [x] 3.1 `autocomprobacion-del-kit`, `cambio-activo`, `raiz-de-trabajo`, `juicio-de-aceptacion`: `## Purpose` en dos o tres frases y los párrafos entre requisitos recortados a lo que explica el requisito hoy; requisitos y escenarios intactos; verificar `openspec validate --all` y que no queda `2026-09-`
- [x] 3.2 `contexto-inyectado`, `coste-del-juicio`, `deteccion-de-duplicados`, `doc-de-paquetes`: misma poda de prosa en la viva; las cláusulas que cambian ya están en el delta de este cambio; verificar `openspec validate el-kit-dice-lo-que-hace`
- [x] 3.3 `estado-del-kit` y `verificacion-firmada`: poda de prosa en todo salvo el requisito de versión y el de kit desfasado, que son de `la-version-no-se-vigila`; verificar que esos dos requisitos quedan byte a byte iguales (`git diff` sobre sus bloques)

## 4. Documentación, comandos y plantillas

- [x] 4.1 `docs/FLUJO.md`: absorbe de `docs/PRIMER-CAMBIO.md` el formato del delta de spec, el veredicto real de ACUERDO-ROTO y «un cambio que no toca código»; fuera las frases con fecha; el presupuesto de rondas se queda; verificar `grep -c 'ADDED Requirements\|ACUERDO-ROTO\|no toca código' docs/FLUJO.md` ≥ 3
- [x] 4.2 Borrar `docs/PRIMER-CAMBIO.md` y quitar sus enlaces de README, INSTALACION y FLUJO; verificar `grep -rn PRIMER-CAMBIO . --include=*.md --include=*.yaml --include=*.conf` vacío
- [x] 4.3 `docs/PIEZAS.md`: referencia por pieza sin «aquí ponía»; sección de coste sin cifras de tokens por ronda, con el orden de magnitud y el comando `claude plugin details`; la norma de los tres comandos separados vive aquí; verificar que no queda `2026-09-` ni `k tokens`
- [x] 4.4 `docs/INSTALACION.md`: instalar, actualizar, desinstalar y «cuando algo falla», sin volver a explicar el flujo ni la historia del `cp`; verificar que no queda `2026-09-`
- [x] 4.5 `README.md` reescrito corto según D3; verificar que `cat README.md docs/*.md | wc -l` < 800
- [x] 4.6 `commands/kit-revisa.md`, `commands/kit-acepta.md`, `commands/kit-verifica.md`, `commands/kit-estado.md`: cuándo se invoca el juez solo en `kit-acepta.md` y los demás enlazan; fuera las frases con fecha; verificar los dos `grep -rl` de los criterios de aceptación
- [x] 4.7 `agents/aceptacion.md`, `agents/reviewer.md`: solo se quitan frases con fecha o con referencia a versiones anteriores; verificar con `git diff --stat` que el cambio es de pocas líneas y `bash scripts/autocomprueba.sh` en verde

## 5. Reglas de proceso

- [x] 5.1 `openspec/config.yaml`: en `context`, las tres reglas del repositorio (juez, una ronda, bancos) y la regla D1 sobre comentarios; verificar `grep -c 'juez\|una ronda\|proyecto real' openspec/config.yaml` ≥ 3

## 6. Cierre

- [x] 6.1 Correr todos los criterios de aceptación del `proposal.md` y anotar aquí el resultado de cada uno. Resultado: todos en verde; docs en 799 líneas; digest idéntico entre el script original y el nuevo sobre el mismo estado; las fechas que quedan en `verificacion-firmada` las retira el delta al archivar
- [x] 6.2 `/kit-revisa` sobre el cambio entero, una ronda; decide el owner. Ronda 1 del revisor: AMBER · comportamiento: no. Cuatro hallazgos de prosa, los cuatro corregidos: PIEZAS prometía los límites en `--comprueba` y en el digest (solo sale el toolchain); FLUJO contaba cuatro hooks; el criterio de fechas no explicaba las del requisito de la firma; y se había borrado del prompt del juez una frase sin fecha, fuera de alcance: restaurada
- [x] 6.3 `/kit-verifica` en verde
