# El contexto dice de qué repo habla, y deja en paz a los que no usan el kit

## Why

`inyecta-contexto.sh` corre en **cada turno** sobre el repositorio del cwd heredado
(líneas 13, 44 y 55), que no tiene por qué ser aquel en el que se está trabajando. Cuando no
lo es, falla de dos maneras, y las dos se observaron el 2026-09-07 con el cwd en `spm-pro` y
el trabajo en `AppStarter`.

**Afirma cosas falsas sobre el trabajo, sin decir de qué repo habla.** Durante la sesión
entera inyectó «Sin cambio OpenSpec activo. Si vas a tocar código, primero `/opsx:propose`»
mientras el repositorio real tenía un cambio activo con ocho criterios y siete tareas
hechas. También inyectó «Verificación: sin firmar todavía» mientras la firma del repositorio
real era válida. Ninguna de las dos frases dice a qué repositorio se refiere, así que ambas
se leen como afirmaciones sobre el trabajo en curso — y son ciertas sobre otro sitio.

El daño no es informativo: el digest existe **precisamente** para que el modelo no derive, y
un digest que describe otro repositorio empuja en la dirección contraria a la que fue puesto.

**Escribe en repositorios que no usan el kit.** La línea 45 hace `mkdir -p` sobre
`.agent-kit/` sin condición alguna, así que cualquier repositorio por el que pase una sesión
acaba con un directorio que nunca pidió. `spm-pro` no tiene `kit.conf` ni `openspec/` —no es
un proyecto del kit— y aun así tiene `.agent-kit/.paquetes-con-reglas`, creado por este
hook. Hubo que añadirlo a su `.gitignore` para que dejara de ensuciar `git status`.

## What Changes

- El digest SHALL empezar diciendo **de qué repositorio habla**. No arregla el desfase —el
  hook no puede saber dónde está trabajando el modelo—, pero lo hace visible en el primer
  turno en vez de a las tres horas.
- Se distingue «este repositorio no usa OpenSpec» de «lo usa y no hay cambio activo». Hoy
  las dos salen por la misma rama y producen la misma orden, que en el primer caso es un
  consejo sobre un repositorio que no va a seguirlo.
- El caché de paquetes deja de vivir dentro del repositorio observado. Pasa a un directorio
  del usuario, con el repositorio en la clave.
- El hook no crea nada dentro de un repositorio que no dé señales de usar el kit.

### La decisión de diseño que este cambio toma

Un hook `UserPromptSubmit` recibe el prompt y hereda un cwd. **No hay ninguna señal
disponible de en qué repositorio está trabajando el modelo**, a diferencia de la puerta de
commit, que al menos ve el comando. Las salidas eran tres.

**Adivinar el repositorio real** —escanear repos vecinos con cambio activo, leer el prompt
buscando rutas— descartada: un digest que se equivoca de repositorio en silencio es el
problema que se intenta arreglar; uno que ADEMÁS lo adivina mal es peor, porque suena más
seguro.

**Callarse cuando el repositorio no usa el kit** — descartada como única medida: el desfase
también ocurre entre dos repositorios que SÍ lo usan, y ahí el digest seguiría mintiendo.

**Nombrar siempre el repositorio y no escribir donde no te llaman** — la que se toma. El
digest deja de ser una afirmación flotante y pasa a estar atribuida: «esto es lo que sé de
`spm-pro`» es verdad aunque el trabajo esté en otro sitio, mientras que «sin cambio activo»
a secas es falso.

Su coste, dicho para que sea decisión y no descuido: el desfase **sigue existiendo**. Este
cambio no lo elimina, lo hace legible. Eliminarlo requeriría que Claude Code diera al hook el
repositorio de la tarea, que hoy no existe; el día que exista, esto se sustituye.

## Fuera de alcance

- **`puerta-commit.sh`**, que tiene el mismo defecto de origen. Es
  [`la-puerta-mira-el-repo-del-commit`](../la-puerta-mira-el-repo-del-commit/proposal.md), su
  propio cambio, porque allí SÍ hay un comando del que inferir el repositorio y la decisión
  de diseño es distinta.
- `verifica.sh`, `rodaja.sh` y `doc-paquetes.sh`. Los invoca alguien y admiten un `cd`
  delante; no corren solos en cada turno.
- El fichero temporal `/tmp/.ic.$$` de la línea 31 y el `git diff --cached | shasum` que se
  ejecuta en cada turno. Son deudas del script, reales, y ninguna tiene que ver con qué
  repositorio se mira. Si se arreglan de paso, se arreglan sin acuerdo.

## Criterios de aceptación

- [ ] El digest SHALL nombrar el repositorio del que habla, en todos los casos, incluido
      aquel en el que no hay nada que contar.
- [ ] En un repositorio SIN `openspec/`, el digest SHALL decir que ese repositorio no usa
      OpenSpec, y NO SHALL ordenar `/opsx:propose`. Fijado por prueba.
- [ ] En un repositorio CON `openspec/` y sin cambio activo, el digest SHALL seguir diciendo
      exactamente lo que dice hoy. Es el caso que no puede romperse.
- [ ] Tras correr el hook en un repositorio sin `kit.conf` ni `openspec/`, `git status`
      SHALL quedar como estaba: ningún fichero ni directorio nuevo. Fijado por prueba que
      falla contra el script actual.
- [ ] El caché de paquetes SHALL seguir evitando el `find` sobre `DerivedData` en turnos
      consecutivos, viviendo fuera del repositorio observado.
- [ ] Dos repositorios distintos SHALL tener cachés distintos; el de uno no SHALL servirse
      al otro. Fijado por prueba.
- [ ] Ninguna prueba nueva SHALL pasar contra el script sin arreglar. Verificado una a una.
