# Diseño

## D1. Qué cubre la huella, y qué comprueba la puerta aparte

**Decisión:** la huella es una **foto del árbol que hace el propio git**: se copia el índice a
uno temporal, se le hace `git add -A` y se le pide `write-tree`; el id de ese árbol es la
huella, salvo `openspec/` y `.agent-kit/`, que se sacan del índice temporal antes de escribir. Lo que el índice aportaba a la huella pasa a ser una
comprobación aparte de la puerta: **ninguna ruta stageada puede tener en el índice un
contenido distinto del árbol**.

*Corregido dos veces al implementar, el 2026-09-20, y las dos por medición:*

1. La primera versión era «el diff del árbol contra `HEAD`». La tumbó la prueba real: un
   fichero nuevo no aparece en ese diff hasta que se stagea, así que stagear lo que
   `/kit-init` acababa de escribir seguía moviendo la huella.
2. La segunda leía `git diff --name-only` y `ls-files --others`, hasheaba cada ruta con
   `[ -e ]` y mandaba el resto a `BORRADO`. La tumbó el revisor, en dos rondas y con
   reproducción: **git cita las rutas** —no solo las no ASCII: también comillas y
   tabuladores, y eso no se apaga—, y **no toda entrada es un fichero normal**: un enlace
   roto no pasa el `[ -e ]`, y un submódulo no lo puede hashear `git hash-object`. En los
   tres casos la foto registraba la presencia de la ruta pero nunca su contenido, así que el
   segundo cambio era invisible y el commit se llevaba código sin verificar.

La lección de las dos: **no parsear rutas**. Git ya sabe fotografiar un árbol —es lo que hace
para cada commit— y sabe de submódulos, enlaces, permisos y nombres imposibles. `write-tree`
sobre un índice temporal da esa foto sin que este kit tenga que entender ninguno de esos
casos.

Las dos cosas juntas dicen lo mismo que se quería decir con la huella doble —«lo que se va a
commitear es lo que se verificó»— pero separan dos preguntas que son distintas:

| | pregunta | cómo se responde |
|---|---|---|
| huella | ¿es este el árbol que se probó? | comparar un sha |
| divergencia | ¿lleva el índice algo que no es ese árbol? | `comm -12` de dos listas de rutas |

Mezclarlas en un solo sha obliga a que cualquier movimiento del índice —incluido acercarlo al
árbol— cambie el número, y ahí es donde aparecía la fricción.

**Por qué no seguir con la huella doble.** Porque el precio no compraba lo que parecía. Medido
el 2026-09-20, la huella doble deja pasar el caso en el que se **firma** con el índice ya
divergente: firma el par y la puerta vuelve a calcular el mismo par. El commit se llevaba
`veneno` con `uno` verificado. La comprobación de divergencia no depende de cuándo se firmó,
así que ese caso también queda cerrado.

**Por qué no solo la huella del árbol.** Sin la comprobación de divergencia queda abierto el
caso que la spec vieja ya nombraba: stagear contenido y devolver el fichero a su contenido de
`HEAD` deja el árbol igual que al firmar, y `git commit` a secas se lleva el índice.

## D2. Cómo se mide la divergencia

```
comm -12 <(git diff --cached --name-only …) <(git diff --name-only …)
```

La intersección de «rutas stageadas» con «rutas cuyo índice y árbol difieren». Si una ruta
está en las dos listas, lo stageado no es lo verificado.

**Por qué por rutas y no por contenido:** `git diff --name-only` ya compara contenido; lo que
devuelve es la respuesta, no una heurística. Y una lista de rutas es lo que hay que enseñar
cuando la puerta bloquea: el mensaje puede nombrar los ficheros.

Las dos listas llevan los mismos pathspecs que la huella, `openspec/` excluido incluido: el
acuerdo no es lo que se compila, y esa asimetría ya está decidida.

## D2-ter. Dónde vive el caché, y qué cuesta la foto

`git add` escribe los blobs que hashea, así que la foto usa su propio índice y su propio
`GIT_OBJECT_DIRECTORY`, con el del repositorio como alternativa de solo lectura. Medido en
cuatro repositorios: el número de objetos sueltos del repo no cambia.

**El caché vive fuera del repositorio**, en `~/.cache/ios-agent-kit/foto/<hash de la raíz>`,
donde el kit ya guarda el de dependencias. Dentro no puede, por dos razones medidas: `add -A`
se encontraría el propio caché y se añadiría a sí mismo mientras git escribe ahí —la foto
fallaba y 27 casos del banco se cayeron a la vez—, y preguntar por la firma crearía
`.agent-kit/` en un repositorio que nunca pidió el kit, que la spec de `/kit-estado` prohíbe.

**Y sobrevive entre llamadas a propósito.** Sin caché, cada foto rehashea el árbol entero. Con
él, `add -A` solo toca lo que cambió.

**El coste, medido el 2026-09-20 con la máquina a media carga:** 347 ms por foto en AppStarter
(357 ficheros), de los cuales 189 son arrancar git cuatro veces —`git --version` sola costaba
47 ms—. La versión anterior, que leía rutas, costaba 55 ms y era incorrecta. Es el precio de
que la foto la haga git, y se paga en el hook de cada turno y en cada commit; sigue estando
dos órdenes de magnitud por debajo de compilar. Este kit ya declaró inaceptable gastar 0,3 s
por turno en detectar el toolchain, y esto es distinto: aquel dato estaba en el marcador y no
hacía falta volver a calcularlo; esta es la pregunta misma.

## D2-bis. Qué queda fuera de la foto, y por qué

`openspec/`, porque es el acuerdo y no lo que se compila; esa decisión ya estaba tomada.

`.agent-kit/` **siempre**, lo ignore el proyecto o no: es donde vive la propia firma. Si
entrara en la foto, escribir la firma cambiaría el árbol y la invalidaría al instante. Lo
destapó el banco: con `.agent-kit/` dentro, ninguna firma valía ni para el árbol que acababa
de verificar.

Lo que el proyecto ignore en su `.gitignore` tampoco entra, y es lo que se quiere: si entrara,
compilar —`build/`, `DerivedData/`— invalidaría la firma.

## D3. Las firmas que ya existen

Dejan de valer: la huella de un árbol limpio hoy es el sha de la línea del separador, y
mañana el del vacío —la foto de un árbol sin nada que fotografiar—. Quien actualice el kit
verifica una vez más de lo normal, y ya.

**Alternativa descartada:** conservar el separador con el lado del índice siempre vacío, para
que las firmas de árbol limpio siguieran cuadrando. Se descarta porque deja en el código una
línea cuyo único motivo es la compatibilidad de un número que nadie lee a mano, y porque el
kit ya tiene la norma de decir lo que hace hoy. El coste real es una verificación.

## D3-bis. Fallar cerrada de verdad

**Decisión:** si el árbol no se puede fotografiar, `huella_diff` devuelve 1 e imprime un valor
**irrepetible**; quien firma se niega a firmar y sale con 3 («no pude mirar»); y todo el que
juzga —`--comprueba`, la puerta y el digest— mira el código de salida.

Las tres cosas, y no una, porque el revisor demostró que con una sola no basta: con un valor
de fallo CONSTANTE, `verifica.sh` lo escribía en la firma, y el siguiente `--comprueba`
recalculaba la misma cadena y cuadraba. Desde ahí la huella era un número fijo y cualquier
árbol valía. Sus dos disparadores eran corrientes: un fichero sin permiso de lectura y un
filtro de `.gitattributes` —Git LFS— sin instalar.

## D4. Firmar con el índice divergente: avisa, no impide

**Decisión:** `verifica.sh` firma igual, y el informe lo dice, como ya dice «árbol sucio».

No lo impide porque verificar no es commitear: quien tiene el índice a medias puede querer
saber si su árbol está verde. Lo que no puede es enterarse en el `git commit`, con el mensaje
de la puerta, de algo que el informe ya podía haberle dicho.
