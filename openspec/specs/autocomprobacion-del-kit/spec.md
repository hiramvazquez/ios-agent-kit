# autocomprobacion-del-kit Specification

## Purpose

Comprobar, antes de publicar, lo que solo se ve al instalar: que los manifiestos del plugin
carguen, y que las piezas que un comando, un agente o una skill manden ejecutar existan **y se
citen por la raíz del plugin**. Cubre las clases de fallo que ya rompieron una instalación, que
es la regla de la casa para que un detector nazca.

Lo que **no** pretende: cubrir todos los fallos posibles de carga, ni sustituir a instalar el
plugin de verdad.

## Requirements

### Requirement: Toda invocación de un fichero del kit pasa por la raíz del plugin

La autocomprobación SHALL fallar cuando un comando, un agente o una skill mande ejecutar un
fichero del kit por una ruta que no se resuelva desde la raíz del plugin.

1. SHALL cazar tanto la ruta inexistente como la ruta que **omite** la raíz del plugin.
2. SHALL salir en rojo contra el repositorio tal como está antes de este cambio.

#### Scenario: Un agente cita un script por una ruta relativa al proyecto

- **WHEN** un fichero de `agents/` manda ejecutar `Scripts/verifica.sh`
- **THEN** la autocomprobación falla
- **AND** nombra el fichero y la ruta

### Requirement: La autocomprobación se puede apuntar a un árbol, y por eso se puede probar

`autocomprueba.sh` SHALL poder comprobar un árbol de kit distinto del suyo.

1. Con una raíz como argumento, SHALL comprobar ESA raíz.
2. Sin argumento, SHALL comprobar la suya.

Sirve para probarla a mano contra un árbol roto sin tocar el del kit, y es lo que da sentido a su
«no pude mirar»: una raíz que no existe.

**Límite declarado.** Sin banco, nada comprueba que siga cazando lo que dice cazar: se ve cuando
falla al publicar.

#### Scenario: Un árbol de kit con un manifiesto roto

- **WHEN** se apunta la autocomprobación a un árbol cuyo `hooks.json` pone los eventos fuera del
  objeto `hooks`
- **THEN** falla, y nombra el fichero

#### Scenario: Un árbol de kit sano

- **WHEN** se apunta a un árbol correcto
- **THEN** sale limpio

#### Scenario: Sin argumento

- **WHEN** se invoca sin argumentos, como hace `kit.conf`
- **THEN** comprueba su propia raíz

### Requirement: «No pude mirar» y «hay problemas» salen con códigos distintos

`autocomprueba.sh` SHALL distinguir en su código de salida el caso en que no ha podido
comprobar nada del caso en que ha comprobado y hay problemas.

1. No poder resolver o alcanzar la raíz que se le pide SHALL salir con un código propio para
   «no pude mirar».
2. Que haya problemas SHALL salir con un código distinto de ese, **sea cual sea el número de
   problemas**.
3. El número de problemas SHALL seguir siendo legible en la salida del script.

Su único invocador es `kit.conf`, que solo mira cero contra no-cero: el contrato es el que se lee
al depurar a mano.

#### Scenario: Un árbol de kit con varios defectos

- **WHEN** la autocomprobación corre sobre un árbol con más de un problema
- **THEN** el código de salida no es el de «no pude mirar»
- **AND** la salida dice cuántos problemas hay

#### Scenario: Una raíz que no existe

- **WHEN** se apunta la autocomprobación a un directorio que no existe
- **THEN** sale con el código de «no pude mirar»
