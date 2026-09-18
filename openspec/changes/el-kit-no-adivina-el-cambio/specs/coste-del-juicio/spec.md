## ADDED Requirements

### Requirement: La rodaja es del cambio que se revisa

Lo que paga una ronda de revisión es el tamaño de lo que se le entrega. La rodaja que
`rodaja.sh` entrega al revisor SHALL ser la del cambio que se revisa, no la del repositorio.

1. `rodaja.sh` SHALL aceptar la ruta del cambio en todos sus modos. Sin ruta SHALL usar el
   único cambio activo; con varios activos y sin ruta SHALL nombrarlos, pedir cuál, y NO SHALL
   imprimir tareas ni diff ni mover la marca.
2. Las tareas cerradas que lista SHALL ser las de ese cambio.
3. La rodaja NO SHALL empezar antes del principio de ese cambio: una marca de revisión
   anterior a él NO SHALL usarse, y una posterior SHALL usarse como hoy. «El principio del
   cambio» SHALL calcularse de una sola manera para la rodaja y para `--entregado`.
4. La rodaja NO SHALL volcar ficheros de `openspec/changes/`, trackeados o nuevos. La salida
   de `--entregado` NO SHALL cambiar por este requisito.
5. Sin ningún cambio activo y sin ruta, la rodaja SHALL seguir yendo desde la marca.

**Límite declarado.** Lo que se commiteó antes de que el cambio empezara y nadie revisó deja de
entrar en la siguiente revisión: la rodaja ya no barre el repositorio. Y un commit ajeno al
cambio hecho a mitad de él sí entra, porque nada dice de quién es cada línea.

#### Scenario: Una marca más vieja que el cambio

- **WHEN** la última revisión marcada es anterior al commit que introdujo la propuesta del
  cambio, y en medio hay commits de otros cambios
- **THEN** la rodaja no contiene esos commits
- **AND** contiene todo lo del cambio que se revisa

#### Scenario: Una marca dentro del cambio

- **WHEN** la última revisión marcada es posterior al principio del cambio
- **THEN** la rodaja empieza en la marca, y solo trae lo hecho desde entonces

#### Scenario: La propuesta va en un commit aparte, antes que el código

- **WHEN** el `proposal.md`, el diseño y las tareas del cambio se commitearon antes de
  implementarlo
- **THEN** la rodaja no vuelca esos ficheros
- **AND** las tareas cerradas siguen saliendo en su lista

#### Scenario: Dos cambios activos y nadie dice cuál

- **WHEN** se invoca `rodaja.sh` sin ruta con dos cambios activos
- **THEN** nombra los dos y pide la ruta
- **AND** no imprime tareas ni diff
