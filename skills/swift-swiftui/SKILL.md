---
name: swift-swiftui
description: Reglas de Swift y SwiftUI para código escrito por agentes, adaptadas de SwiftAgents (Paul Hudson) con las que exigen iOS 26 marcadas aparte. Úsala al escribir o revisar cualquier fichero .swift de UI o de lógica de vista.
---

# Swift y SwiftUI — reglas de código

Adaptado de [SwiftAgents](https://github.com/twostraws/SwiftAgents) (Paul Hudson).
**Ojo:** el original apunta a **iOS 26+**. El objetivo de despliegue (deployment target) lo
declara CADA proyecto —no esta skill—, así que las reglas de aquí que exigen una versión de
iOS más nueva que ESE objetivo están marcadas aparte, al final, para revisarlas contra el
tuyo antes de aplicarlas.

Medido el 2026-09-05 sobre los 88 ficheros Swift del proyecto donde se probó esta skill:
**cero infracciones**. Esto no es una lista de deuda, es una barandilla para el código que
se escriba a partir de ahora.

## Swift

- `@Observable` marcado `@MainActor` (salvo aislamiento por defecto del módulo).
- Nada de `ObservableObject`, `@Published`, `@StateObject`, `@ObservedObject`,
  `@EnvironmentObject`.
- `async/await` antes que closures, siempre que exista la variante.
- Nada de GCD (`DispatchQueue.main.async`).
- Foundation moderna: `URL.documentsDirectory`, `appending(path:)`.
- `FormatStyle`, nunca subclases de `Formatter`.
- Filtrado de texto del usuario con `localizedStandardContains()`.
- Sin force unwrap ni `try!` salvo que sea irrecuperable.

## SwiftUI

- `foregroundStyle()`, no `foregroundColor()`.
- `clipShape(.rect(cornerRadius:))`, no `cornerRadius()`.
- `NavigationStack` + `navigationDestination(for:)`.
- `Task.sleep(for:)`, no `sleep(nanoseconds:)`.
- `onChange()` en su variante de dos parámetros.
- `Button` antes que `onTapGesture()` (salvo que necesites posición o número de toques).
- Nada de `UIScreen.main.bounds`, `AnyView`, ni `GeometryReader` si hay alternativa.
- Subvistas en `struct View` propios, no en propiedades computadas.
- Dynamic Type: no fijes tamaños de fuente.
- `.scrollIndicators(.hidden)` para ocultar indicadores.
- Lógica de vista en el view model, para que se pueda testear.
- Sin colores de UIKit en SwiftUI.

## Marcadas aparte: exigen más iOS del que tu proyecto quizá declare

Aplícalas solo si el `deployment target` de TU proyecto ya las cubre; si tu proyecto
despliega en una versión anterior a la que cada una pide, quedan fuera:

- `Tab` API en vez de `tabItem()` — requiere iOS 18.
- "usa las ScrollView APIs más nuevas" — `ScrollPosition` es iOS 18.
- "target iOS 26.0 o superior" — es el objetivo del propio SwiftAgents, no un hecho de tu
  proyecto: usa el `deployment target` que tu proyecto declare, sea cual sea.

## Por encima de esta skill: las reglas de tu proyecto

Esta skill viaja instalada en el plugin, así que no sabe nada de tu repositorio. Lo que
sigue es la precedencia, que sí vale en cualquiera:

- **Donde SwiftAgents y las reglas de tu proyecto discrepen, ganan las de tu proyecto.**
  Búscalas donde tu repositorio las tenga —un `AGENTS.md`, un `CLAUDE.md`, la configuración
  de tu linter de arquitectura— y léelas antes que esto.
- **El linter que tenga tu proyecto, en verde antes de commitear.** Cuál es, y si lo hay,
  lo dice tu repositorio.

Y una regla del original que no depende de ningún proyecto: si un modelo de SwiftData va a
CloudKit, aplican las tres de SwiftAgents — nada de `@Attribute(.unique)`, propiedades con
valor por defecto u opcionales, y relaciones opcionales.
