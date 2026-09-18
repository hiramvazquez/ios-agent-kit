## Context

Ver `proposal.md` — Why. Lo que condiciona el cómo:

- Los bancos (`scripts/verifica-*.sh`) no leen comentarios: cualquier edición que solo toque
  líneas `#` o docstrings deja los 116 casos igual. Es la red de este cambio.
- Las directivas `# shellcheck disable=…` y `# shellcheck source=…` son comentarios que
  **sí** cambian el resultado de `shellcheck`. No son narrativa y se quedan.
- OpenSpec funde los deltas en las specs vivas al archivar. La prosa que no es requisito
  —`## Purpose`, párrafos entre requisitos— no pasa por delta: se edita en la spec viva.
- El digest de cada turno lo compone `inyecta-contexto.sh` a partir de texto literal del
  script; no toca comentarios, así que sale igual.

## Goals / Non-Goals

**Goals:**
- Que cada fichero diga lo que hace hoy, y que la razón quepa en dos o tres líneas.
- Que cada norma tenga un dueño: un fichero, una sección.
- Que el abanico de un cambio de comportamiento baje de 7–18 ficheros a los tres o cuatro
  que de verdad cambian.

**Non-Goals:**
- Reescribir los prompts de los agentes. Cambiar lo que un prompt manda es «prosa como
  producto», y es lo que este cambio viene a dejar de hacer por sistema.
- Perder las mediciones que sostienen un número vigente (el suelo del detector). Van con
  fecha porque una medición sin fecha vale menos; es la única fecha que queda en las specs.

## Decisions

### D1. Qué comentario se queda y cuál se va

Se queda: **qué hace** la pieza, **por qué existe** (una frase) y el **límite declarado** (qué
no cubre). Se va: cuándo se descubrió, quién lo cazó, qué ponía antes, cuántas rondas costó,
cifras de medición que no fijan un valor del código. Regla mecánica: si la frase tiene fecha o
la palabra «antes», va al log. Los mensajes de commit de este repositorio ya cuentan la
historia; `openspec/changes/archive/` la conserva íntegra.

*Alternativa descartada:* mover la narrativa a un `docs/HISTORIA.md`. Es un fichero nuevo que
nadie leería y que habría que mantener: la misma clase de crecimiento que se corta.

### D2. Dónde vive cada norma

| norma | vive en | los demás |
|---|---|---|
| stagea, verifica y commitea en comandos separados | `docs/PIEZAS.md` › `verifica.sh` | `verifica.sh` y `puerta-commit.sh` la dicen en su mensaje, que es donde se lee al chocar con ella |
| cuándo se invoca el juez | `commands/kit-acepta.md` | FLUJO, PIEZAS y `kit-revisa.md` enlazan |
| límite del acotado por prefijo | `lib-kit.sh` › `derivados_propios` y `docs/PIEZAS.md` | nadie más lo explica |
| qué no frena la puerta | cabecera de `puerta-commit.sh` | (lo reescribe `la-puerta-es-de-git`) |
| presupuesto de rondas | `docs/FLUJO.md` | `kit-revisa.md` y `kit-acepta.md` enlazan |

### D3. Qué documentación queda

`README.md`: qué resuelve, instalación en diez líneas, el bucle diario, `kit.conf`, qué trae el
plugin, la regla contra el crecimiento en un párrafo, enlaces. Sin ensayos.
`docs/FLUJO.md`: el flujo paso a paso con un caso; absorbe de PRIMER-CAMBIO el formato del
delta, el veredicto real de ACUERDO-ROTO y el cambio de solo-spec.
`docs/PIEZAS.md`: referencia por pieza, con sus límites; coste sin cifras que no se puedan
rehacer.
`docs/INSTALACION.md`: instalar, actualizar, desinstalar, y «cuando algo falla». No vuelve a
explicar el flujo.

*Alternativa descartada:* fundir INSTALACION en README. La sección «cuando algo falla» es
larga y de consulta, no de lectura; en el README estorba.

### D4. Las specs pierden narrativa en la viva, y requisitos por delta

`## Purpose` queda en dos o tres frases. Los párrafos que explican un requisito se recortan a
lo que hace falta para entenderlo hoy. Solo las cláusulas que cambian van por delta
(`## MODIFIED Requirements`), que es lo que `openspec archive` funde. `puerta-de-commit` no se
toca: la reescribe `la-puerta-es-de-git`; el requisito de versión de `estado-del-kit` y el de
kit desfasado de `verificacion-firmada` tampoco: son de `la-version-no-se-vigila`.

### D5. Orden de trabajo, para que la red esté siempre tensa

1. Guardar referencia: salida del digest y resumen de cada banco.
2. Scripts y `kit.conf`, un fichero por rodaja; tras cada uno, `bash -n`, `shellcheck` y su
   banco. Al terminar, el digest byte a byte contra la referencia.
3. Specs vivas, luego los deltas ya escritos se validan con `openspec validate`.
4. Docs, comandos, agentes, plantillas, y las comprobaciones de «una norma, un sitio».
5. `openspec/config.yaml`.

### D6. Reglas de proceso, en `config.yaml` y no en un documento

Van en el `context` de `openspec/config.yaml` porque es lo que se inyecta a cada propuesta y
sobrevive a `openspec update`. Tres, en imperativo: el juez no se invoca sobre este repositorio;
el revisor da una ronda y decide el owner; un caso de banco nace por un fallo que llegó a un
proyecto real.

## Risks / Trade-offs

- [Cortar una razón que sí hacía falta] → cada función conserva su «por qué» en una frase; si
  al recortar no cabe en una, es que la razón es un límite declarado y se queda como tal.
- [Un banco que dependa de un texto de comentario] → ninguno lo hace hoy; se comprueba
  corriendo los seis tras cada fichero.
- [Que el README corto pierda el argumento de venta] → el «qué resuelve» y el caso del
  ACUERDO-ROTO se quedan; lo que se va es la repetición.
- [Que alguien vuelva a escribir historia en un comentario] → la regla D1 va en el `context`
  de `config.yaml`, que es lo que lee quien propone.
