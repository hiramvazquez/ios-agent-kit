# Tu primer cambio, de principio a fin

Un recorrido real. Los ejemplos no son inventados: salen de un cambio que se hizo con este
kit en una app iOS de verdad, y el veredicto de aceptación que aparece al final fue el que
salió.

## El bucle

```
/opsx:propose "lo que quieras construir"    →  se acuerda. CERO código.
/opsx:apply                                 →  se implementa
/kit-verifica                               →  build, tests y duplicados, firmado
   reviewer                                 →  ¿esto rompe algo?
/kit-acepta                                 →  ¿es lo acordado?
/opsx:archive                               →  el delta se funde en la spec viva
```

---

## 1. Proponer — y aquí no se escribe código

```
/opsx:propose "subir AppFoundation y CoreNetworking a la última, y adoptar la cancelación
del trabajo en vuelo al desmontar una pantalla"
```

Crea `openspec/changes/<nombre>/` con tres o cuatro ficheros. El `proposal.md` lleva, por
regla del `config.yaml`, dos secciones que no son opcionales:

```markdown
## Fuera de alcance

- Cambiar los rangos de los manifiestos (`from:` ya es correcto).

## Criterios de aceptación

- [ ] Los tres `Package.resolved` en AppFoundation 1.3.1 y CoreNetworking 1.2.2.
- [ ] `UploadsFeature` pasa `cancelsInFlightWorkOnRemoval: false`, con la razón en el código.
- [ ] `/kit-verifica` en verde.
```

**Un criterio tiene que poder comprobarse mirando el resultado.** «La carga es más fluida»
no es un criterio: el juez de aceptación lo devuelve como ACUERDO-ROTO y hay que
reescribirlo. Y nombra ficheros: «las pantallas que lanzan trabajo largo» no dice cuáles, y
por tanto no se puede verificar que estén todas.

### El delta de spec, en el formato del CLI

Esto es lo que más cuesta la primera vez. No es prosa libre: si no lleva esta forma,
`openspec list --specs` dice `requirements 0` y ni `validate` ni `archive` sirven de nada.

```markdown
## ADDED Requirements

### Requirement: Cancelación del trabajo en vuelo al desmontar una pantalla

Una pantalla montada con `ScreenContainer` SHALL cancelar su trabajo asíncrono en vuelo
cuando la vista sea eliminada de la jerarquía, y SHALL NOT cancelarlo cuando la vista quede
únicamente cubierta por otra empujada encima.

#### Scenario: La pantalla se elimina de la jerarquía

- **WHEN** el usuario hace pop de una pantalla que tiene una carga en curso
- **THEN** el trabajo en vuelo se cancela
- **AND** no se entrega ningún resultado a una vista que ya no existe
```

Encabezados y `SHALL` **en inglés**; el cuerpo, en tu idioma. Un bloque `## MODIFIED
Requirements` lleva el requisito **entero**, con todos los escenarios que sobreviven:
`validate` y `archive` rechazan uno que se deje alguno por el camino.

Comprueba con `openspec validate --all` antes de seguir.

---

## 2. Implementar

```
/opsx:apply
```

Se ejecutan las tareas marcando `[x]`. Dos reglas que el hook te recuerda en cada turno:

- **Antes de escribir una función nueva**, `/kit-duplicados`. Es barato y evita lo que a
  este kit le dio origen: el mismo cuerpo escrito tres veces en tres semanas distintas.
- **Si descubres que el acuerdo estaba mal**, se corrige el acuerdo **por escrito**. Lo
  prohibido es seguir porque «es obvio que hace falta».

---

## 3. Verificar

```
/kit-verifica
```

Corre lo que diga tu `kit.conf` y firma el resultado contra el `sha256` del diff staged.
El informe de lógica repetida sale aparte: **avisa, no bloquea** — un duplicado puede ser
deliberado, y quien lo decide eres tú con el cambio delante.

Stagea, verifica y commitea en **comandos separados**. Encadenar `git add && git commit`
cambia el diff entre la firma y el commit, y la puerta lo rechaza con razón.

---

## 4. Revisar y aceptar — son dos preguntas distintas

El **reviewer** pregunta *¿esto rompe algo?* Corrección, seguridad, requisitos explícitos.
Con contexto fresco y solo el diff delante.

El **juez de aceptación** (`/kit-acepta`) pregunta *¿es lo acordado?* Criterio por criterio,
con evidencia (`fichero:línea`), y uno de tres veredictos:

| veredicto | qué significa |
|---|---|
| **ACEPTADO** | todos los criterios cumplidos, con evidencia |
| **DEVUELTO** | falta algo. Dice qué, y para |
| **ACUERDO-ROTO** | hay criterios que no se pueden comprobar, o el diff hace cosas que no responden a ningún criterio. El problema está en el acuerdo |

### Por qué hacen falta los dos

Este es el veredicto real que devolvió el juez la primera vez que se usó:

> El cambio **compila, pasa 144 tests y hace lo que hacía falta**. Y aun así rompió su
> propio acuerdo en dos sitios:
>
> 1. **Hizo lo que su «Fuera de alcance» prohibía.** Subir el `from:` de los tres
>    manifiestos no estaba autorizado. Y no fue capricho: era necesario —el resolutor de
>    Xcode se quedaba en la versión vieja—, pero eso es justamente el momento de volver al
>    acuerdo y renegociarlo por escrito.
> 2. **Un criterio escrito de forma incomprobable.** «Las pantallas que lanzan trabajo
>    largo» no dice cuáles.
>
> Ninguno de los dos fallos lo habría visto nada de lo que ya había: el compilador no opina
> de alcance, los 144 tests pasan, el linter de arquitectura está verde, y un reviewer
> mirando el diff habría dicho GREEN — porque el diff, en sí, es correcto.

El cambio no se revirtió: **se corrigió el acuerdo**, que era lo que estaba mal, y por
escrito. Esa es la dirección legítima. La prohibida es la contraria — retocar el acuerdo en
silencio para que encaje con lo entregado.

---

## 5. Archivar

```
/opsx:archive
```

Funde el delta en `openspec/specs/<dominio>/spec.md` y mueve la carpeta a
`openspec/changes/archive/<fecha>-<nombre>/`. **No se archiva con DEVUELTO ni con
ACUERDO-ROTO.**

Con `ACUERDO-ROTO` se corrige el acuerdo primero, por escrito, y se vuelve a pasar.

---

## Un cambio que no toca código

Pasa más de lo que parece y es correcto. Ejemplo real: decidir si un login en vuelo debe
sobrevivir a su pantalla. La decisión fue **mantener el comportamiento actual**, así que no
hubo diff de código — solo un escenario nuevo en la spec con la razón al lado.

Antes, ese login se cancelaba **por accidente**, porque nadie miró el default de la
dependencia. Después se cancela **por decisión**. El comportamiento es idéntico; lo que
cambia es que deja de ser una casualidad. Eso es exactamente lo que un cambio de solo-spec
debe producir, y es la clase de cosa que sin un sitio donde vivir se pierde en una nota al
pie que nadie relee.
