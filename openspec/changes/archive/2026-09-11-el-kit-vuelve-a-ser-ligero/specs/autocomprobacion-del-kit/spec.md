# Autocomprobación del kit — delta

## MODIFIED Requirements

### Requirement: La autocomprobación se puede apuntar a un árbol, y por eso se puede probar

`autocomprueba.sh` SHALL poder comprobar un árbol de kit distinto del suyo.

1. Con una raíz como argumento, SHALL comprobar ESA raíz.
2. Sin argumento, SHALL comprobar la suya.

Sirve para probarla a mano contra un árbol roto sin tocar el del kit, y es lo que da sentido a su
«no pude mirar»: una raíz que no existe.

Tuvo un banco que le pasaba árboles rotos y uno sano. Se retiró el 2026-09-11 porque solo había
cazado fallos del propio `autocomprueba.sh`. Lo que la autocomprobación caza —manifiestos rotos,
invocaciones que no pasan por la raíz del plugin, frontmatter— sí llegó a romper al instalar, y por
eso ella se queda.

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

## REMOVED Requirements

### Requirement: Ningún documento afirma cuántas piezas trae el kit

**Reason**: El lint solo mira los documentos del propio kit —README, `docs/`, agentes, comandos y
skills— y no corre en los proyectos que lo instalan. Cazó dos veces un recuento caducado en esos
documentos, que se caza igual leyendo. La regla que sirve a los proyectos —que un acuerdo no cuente
cosas a mano— la aplica el juez, en «Los números del acuerdo» de `agents/aceptacion.md`, y se queda.

**Migration**: Nada que migrar en los proyectos. En el kit, un recuento escrito a mano en un
documento se corrige cuando alguien lo lee, como cualquier otra frase desfasada.

### Requirement: El lint de censos declara qué NO mira

**Reason**: Declaraba el alcance de un lint que se retira con «Ningún documento afirma cuántas
piezas trae el kit».

**Migration**: Ninguna.
