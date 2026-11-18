# Los flujos de OpenSpec son skills

## Why

OpenSpec 2.0.0 retira los comandos `/opsx:*`: cada flujo queda solo como skill, y
`/opsx:propose` pasa a ser `/openspec-propose`. El kit nombra los comandos viejos en el
README, en los tres documentos, en `/kit-init` y en el digest que se inyecta en cada turno,
así que al actualizar OpenSpec mandaría teclear comandos que ya no existen.

No hace falta esperar a actualizar: las skills `openspec-propose`, `openspec-apply-change` y
`openspec-archive-change` ya las instala la versión que hay hoy, y la 2.1.0 las conserva con
el mismo nombre. Comprobado creando un proyecto con la 2.1.0 en un directorio temporal: el
digest, `/kit-estado` y la rodaja leen sus cambios sin tocar nada.

## What Changes

- Donde el kit decía `/opsx:propose`, `/opsx:apply` y `/opsx:archive`, dice
  `/openspec-propose`, `/openspec-apply-change` y `/openspec-archive-change`.
- `docs/INSTALACION.md` explica el «Unknown command» con las dos causas que tiene ahora: la
  sesión abierta por encima del repositorio, o las skills de OpenSpec sin instalar.

## Fuera de alcance

- Actualizar el CLI de OpenSpec de esta máquina y correr `openspec update` en los proyectos:
  lo decide el owner, proyecto a proyecto.
- Elegir por el usuario entre skills en el proyecto o globales: `/kit-init` sigue llamando a
  `openspec init` como hasta ahora, y eso lo resuelve cada versión de OpenSpec.
- Usar `openspec status --all` o la verificación de OpenSpec en lugar de piezas del kit.
- Los acuerdos archivados, que son historia y nombran lo que había.

## Criterios de aceptación

- [x] Ningún fichero publicado del kit —README, `docs/`, `commands/`, `agents/`, `scripts/`,
      `plantillas/`— SHALL mandar teclear un comando `/opsx:`. Se comprueba con `git grep`.
      Enmendado al implementar: decía «nombrar», y queda una mención a propósito en
      `docs/INSTALACION.md`, la que le dice a quien teclea el comando viejo que ya no existe.
- [x] El digest de un repositorio con `openspec/` y sin cambio activo SHALL mandar
      `/openspec-propose`. Fijado por el caso de banco que ya existía, con el nombre nuevo.
- [x] `scripts/verifica.sh` SHALL seguir en verde.
