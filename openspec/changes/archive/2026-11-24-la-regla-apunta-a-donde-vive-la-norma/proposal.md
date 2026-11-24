# La regla apunta a donde vive la norma

## Why

`openspec/config.yaml` —las reglas de este repo, que OpenSpec inyecta en cada artefacto— dice
en su primera regla que `hooks/hooks.json` fija la norma de los hooks «en su `_nota`». Esa clave
se quitó en la 2.2.2 (2026-09-19) porque Claude Code avisaba de ella en cada sesión, y la norma
vive desde entonces en `docs/PIEZAS.md`, en la sección de `inyecta-contexto.sh`. La regla es
correcta; el puntero está muerto. Encontrado en el barrido del 2026-09-30, y es de la clase que
el `kit.conf` de este repo declara que ningún automatismo comprueba: markdown.

## What Changes

- **`openspec/config.yaml`, primera regla:** apunta a `docs/PIEZAS.md` en vez de a la `_nota`,
  y deja de repetir la norma: una norma, un sitio.
- Nada más.

## Lo que este cambio iba a llevar y no lleva

Se abrió como `kit-init-no-deja-la-app-fuera`, con una segunda pieza: una frase en el paso 2 de
`commands/kit-init.md` obligando a que `kit.conf` lleve el target de la app cuando hay app de
Xcode, porque «las dos veces que se montó ListaPrueba el `kit.conf` salió solo con los paquetes
y hubo que meter la app a mano». **Eso era falso.** El transcript de la sesión del 2026-09-20
enseña que las dos veces (01:41 y 03:59) `/kit-init` escribió el `kit.conf` con el paso
`app · build + AppTests`, y los dos commits de montaje lo dicen. La nota del runbook de la que
salió la afirmación era un consejo de revisión, no un fallo observado.

La prueba real de este cambio lo confirmó por su lado: en un proyecto mínimo montado de cero
—app SwiftUI con xcodegen, target de tests unitarios y un paquete local, sin historia, sin CI,
sin `AGENTS.md`— la corrida de control con el texto de `HEAD` también metió la app y firmó en
verde. Con el texto de hoy son tres de tres. Sin fallo real no hay frase: la regla del repo es
que un cambio de prosa nace de un fallo que llegó a un proyecto real, y aquí no lo hubo. La
frase se retiró y el cambio se renombró para que el archivo no mienta.

## Capabilities

### New Capabilities

Ninguna.

### Modified Capabilities

Ninguna. El cambio lleva `skip_specs: true`, como los otros cambios de prosa del repo:
`config.yaml` no es una capacidad, es la configuración de OpenSpec.

## Impact

- Un fichero de configuración. Ningún script, ningún caso de banco, y la versión no sube: va a
  `main` y se publica con la siguiente versión que lo merezca.
