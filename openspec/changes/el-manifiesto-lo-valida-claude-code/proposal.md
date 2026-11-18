# El manifiesto lo valida Claude Code

## Why

`autocomprueba.sh` comprueba a mano cosas que hoy comprueba `claude plugin validate`, que es
quien decide de verdad si un plugin carga. Se midió el 2026-11-17 con copias rotas del kit,
una por defecto:

| defecto | `claude plugin validate --strict` | `autocomprueba.sh` |
|---|---|---|
| JSON roto en `plugin.json`, `marketplace.json` o `hooks.json` | falla | falla |
| eventos de `hooks.json` fuera del objeto `hooks` | falla | falla |
| un agente sin frontmatter | falla | falla |
| un evento de hook que no existe | falla | **no lo ve** |
| un hook que apunta a un script que no existe | **no lo ve** | falla |
| un comando que cita un script que no existe | **no lo ve** | falla |

Y una de las comprobaciones propias ya dice algo falso: `autocomprueba.sh` rechaza que
`plugin.json` declare `commands`, y el validador lo acepta.

Lo que el validador cubre, el kit lo mantiene dos veces y una de ellas mal. Lo que no cubre
—que los scripts que citan hooks, comandos y agentes existan y se citen por la raíz del
plugin— es lo que el kit tiene que seguir mirando.

## What Changes

- La verificación del kit corre `claude plugin validate --strict` como paso propio.
- `autocomprueba.sh` pierde las comprobaciones que ese paso ya hace: que los JSON parseen, que
  `plugin.json` no declare rutas, que `hooks.json` envuelva sus eventos, y el frontmatter.
- Se queda con las tres que nadie más hace: los scripts de los hooks, lo que citan comandos y
  agentes, y que lo citen por la raíz del plugin.

## Fuera de alcance

- Declarar `engines` en `plugin.json`. No hay ninguna versión de Claude Code en la que se sepa
  que el kit falla, así que el número sería inventado y habría que mantenerlo a mano.
- Un banco para `autocomprueba.sh`.
- `claude plugin eval`.

## Límite declarado

`--strict` convierte en fallo cualquier aviso del validador, y los avisos los decide cada
versión de Claude Code: una actualización puede poner este paso en rojo sin que el kit haya
cambiado. Es el precio de dejar que mande quien carga el plugin.

## Criterios de aceptación

- [x] `verificaciones()` de `kit.conf` SHALL correr `claude plugin validate --strict` sobre el
      kit, y SHALL fallar —no saltarse— si el CLI de `claude` no está.
- [x] `autocomprueba.sh` NOT SHALL comprobar nada de lo que la tabla dice que el validador
      caza.
- [x] `autocomprueba.sh` SHALL seguir fallando ante un hook que apunta a un script que no
      existe y ante un comando que cita un script que no existe. Comprobado con las mismas
      copias rotas.
- [x] `scripts/verifica.sh` SHALL salir en verde.
