# raiz-de-trabajo Specification

## Purpose
Que una pieza que necesita un repositorio git lo compruebe de verdad, lo diga cuando no lo
haya, y no deje nada escrito donde nadie le pidió nada.

Existe por un detalle de bash que hace mentir a la guarda evidente: `cd ""` **devuelve 0**, así
que `cd "$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "no es un repo git"; exit 1; }`
se lee como una comprobación y no lo es. La casa ya tenía la forma correcta escrita en dos
sitios cuando dos hermanos suyos seguían con la rota, y uno de ellos creaba un directorio fuera
de todo repositorio cada vez que se le invocaba mal.

Lo que **no** pretende: obligar a los hooks. Un hook que imprime donde no toca rompe el JSON
que la herramienta espera de él, o convierte un fallo suyo en una sesión inutilizable — así que
la cláusula de hablar les exime, con su razón escrita, y las de no ensuciar y comprobar bien
les siguen aplicando. Esa excepción no estaba en la primera versión, y sin ella esta norma
habría convertido en infractores a dos piezas que hacen lo correcto.

## Requirements

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
4. Los **hooks** quedan fuera de la cláusula 1, y esto es una decisión, no un olvido: un hook
   que imprima donde no toca rompe el JSON que la herramienta espera de él, o convierte un
   fallo suyo en una sesión inutilizable. `inyecta-contexto.sh` sale en silencio con 0 por
   esa razón, y `puerta-commit.sh` lleva escrito en su propio comentario que ahí falla ABIERTO
   a propósito. Las cláusulas 2 y
   3 sí les aplican: la 3 es el defecto de bash que este requisito existe para cerrar, y
   ninguno de los dos la incumple.

La cláusula 4 la trajo el juez de aceptación del 2026-09-08, y con un argumento que vale más
que el arreglo: la primera versión de este requisito decía «TODO script del kit», lo que
convertía en infractores a esos dos hooks cuyo silencio exigen otras dos specs. Al archivarse
esto queda como norma permanente, y la próxima auditoría de esta casa —cuyo método declarado
es buscar la regla que llegó a un fichero y no a su hermano— habría encontrado exactamente
esos dos hermanos y los habría «arreglado», rompiendo dos contratos. El modo de fallo que este
cambio existe para cerrar, plantado en el acuerdo que lo cierra.

La 3 es el defecto, y es de bash: `cd ""` **devuelve 0**, así que el idiom
`cd "$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "no es un repo git"; exit 1; }`
tiene la guarda muerta. Lo usan `rodaja.sh` y `doc-paquetes.sh`.

`rodaja.sh` es el que muerde: dos líneas después hace `mkdir -p .agent-kit`, así que **crea un
directorio en el sitio donde estés**, no en un repositorio, y luego vuelca el `usage` de
`git diff` en vez del mensaje que tiene escrito. Comprobado el 2026-09-08 en un directorio
pelado. Es la misma regla que el hook de contexto ya cumple —no escribir donde nadie pidió el
kit— sin llegar a su hermano.

Y la casa ya sabía esto: `autocomprueba.sh` lleva escrito en un comentario que «`cd ""`
devuelve 0 en bash» y se protege con un `[ -n "$RAIZ" ]`. `verifica.sh` usa la forma correcta,
`RAIZ="$(…)" || { … }`, que sí propaga el código de git. La regla estaba escrita y aplicada;
lo que no había ocurrido es que llegara a todos los que la necesitan.

Aquí iba un «dos ficheros la aplican y dos no» que era falso —eran tres los que ya la
aplicaban— y que además se contradecía con la cláusula 4, que dos párrafos más arriba cuenta a
uno de ellos como cumplidor. Lo cazó el juez de aceptación contando. No se sustituye por el
número correcto: un censo dentro de una norma que se archiva envejece solo, y esta norma se
sostiene sin él.

#### Scenario: `rodaja.sh` fuera de un repositorio

- **WHEN** se invoca `rodaja.sh` en un directorio que no está en ningún repositorio git
- **THEN** dice que no es un repositorio git
- **AND** sale con un código distinto de 0
- **AND** no crea ningún fichero ni directorio ahí

#### Scenario: `doc-paquetes.sh` fuera de un repositorio

- **WHEN** se invoca `doc-paquetes.sh` en un directorio que no está en ningún repositorio git
- **THEN** dice que no es un repositorio git
- **AND** sale con un código distinto de 0
