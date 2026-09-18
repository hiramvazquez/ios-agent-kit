## MODIFIED Requirements

### Requirement: Una pieza INVOCADA POR UNA PERSONA que exige un repositorio git lo dice

Todo script del kit que una persona invoque directamente SHALL comprobar que ha podido
resolver la raíz del repositorio antes de
usarla, SHALL decirlo cuando no la haya, y NO SHALL dejar nada escrito fuera de un
repositorio.

1. Invocado fuera de un repositorio git, el script SHALL imprimir que no lo es y salir con un
   código distinto de 0.
2. NO SHALL crear ningún fichero ni directorio en el directorio desde el que se le invocó.
3. La comprobación SHALL mirar si la raíz se ha podido resolver, no el resultado de entrar en
   ella.
4. Los **hooks de Claude Code** quedan fuera de la cláusula 1, y esto es una decisión, no un
   olvido: un hook que imprima donde no toca rompe el JSON que la herramienta espera de él.
   `inyecta-contexto.sh` sale en silencio con 0 por esa razón. Las cláusulas 2 y 3 sí le
   aplican: la 3 es el defecto de bash que este requisito existe para cerrar.

La 3 es el defecto, y es de bash: `cd ""` **devuelve 0**, así que el idiom
`cd "$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "no es un repo git"; exit 1; }`
tiene la guarda muerta. La forma correcta es `RAIZ="$(…)" || { … }`, que sí propaga el código de
git.

#### Scenario: `rodaja.sh` fuera de un repositorio

- **WHEN** se invoca `rodaja.sh` en un directorio que no está en ningún repositorio git
- **THEN** dice que no es un repositorio git
- **AND** sale con un código distinto de 0
- **AND** no crea ningún fichero ni directorio ahí

#### Scenario: `doc-paquetes.sh` fuera de un repositorio

- **WHEN** se invoca `doc-paquetes.sh` en un directorio que no está en ningún repositorio git
- **THEN** dice que no es un repositorio git
- **AND** sale con un código distinto de 0
