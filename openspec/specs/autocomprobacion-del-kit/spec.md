# autocomprobacion-del-kit Specification

## Purpose

Comprobar, antes de publicar, lo que solo se ve al instalar. Los manifiestos del plugin
fallaron dos veces el mismo día sin que se viera leyéndolos: se vio cuando `claude plugin
list` dijo «failed to load».

Con el tiempo cubre también lo que el kit se exige a sí mismo y nadie más comprueba: que las
piezas que un comando o un agente manden ejecutar existan **y se citen por la raíz del
plugin**, y que ningún documento cuente a mano cuántas piezas trae el kit.

Lo que **no** pretende: cubrir todos los fallos posibles de carga, ni sustituir a instalar el
plugin de verdad. Cubre las clases que ya fallaron, que es la regla de la casa para que un
detector nazca.

## Requirements

### Requirement: Toda invocación de un fichero del kit pasa por la raíz del plugin

La autocomprobación SHALL fallar cuando un comando, un agente o una skill mande ejecutar un
fichero del kit por una ruta que no se resuelva desde la raíz del plugin.

1. SHALL cazar tanto la ruta inexistente como la ruta que **omite** la raíz del plugin.
2. SHALL salir en rojo contra el repositorio tal como está antes de este cambio.

La comprobación que hay hoy solo mira rutas que ya empiezan por la raíz del plugin: verifica
que lo citado exista, pero no ve lo que se cita mal. Por eso el kit lleva publicando en verde
un prompt con dos invocaciones muertas.

#### Scenario: Un agente cita un script por una ruta relativa al proyecto

- **WHEN** un fichero de `agents/` manda ejecutar `Scripts/verifica.sh`
- **THEN** la autocomprobación falla
- **AND** nombra el fichero y la ruta

### Requirement: Ningún documento afirma cuántas piezas trae el kit

La autocomprobación SHALL fallar cuando un documento del kit escriba a mano un recuento de
sus propias piezas.

1. Un recuento SHALL sustituirse por el comando que lo produce, o SHALL ir fechado como
   medición.

Esta clase ya falló dos veces: «once casos» escrito en dos sitios y «diez» en un tercero el
mismo día, y hoy un «5 skills» en el README donde hay siete piezas. Es la misma regla que el
juez de aceptación impone a cualquier criterio que cuente cosas — un censo caduca en el
momento de escribirse.

#### Scenario: El README dice cuántas skills trae el plugin

- **WHEN** un documento del kit contiene un recuento de piezas escrito a mano
- **THEN** la autocomprobación falla
