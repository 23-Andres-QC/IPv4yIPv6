# IPv4 ↔ IPv6 Toolkit (Flutter Desktop)

Aplicación de escritorio (Windows) hecha en Flutter para calcular direcciones,
subredes y transformaciones IPv4/IPv6 siguiendo los RFC normativos (4632,
4291, 5952, 6052, 3056, 3021, etc.) en vez de reglas heurísticas por octeto.

Este documento explica **la lógica y las matemáticas exactas** detrás de cada
pantalla, con la ubicación del código fuente correspondiente.

---

## 1. Representación interna de las direcciones

### IPv4 — `lib/core/ipv4.dart`

Una IPv4 se guarda como un único entero de 32 bits (`int value`), no como 4
octetos sueltos. Esto permite que máscara, red, broadcast, etc. sean simples
operaciones binarias:

- **Parseo**: se separa el texto por `.`, se valida que haya 4 partes 0-255,
  y se combinan con `(v << 8) | octeto` para formar el entero de 32 bits.
- **Octetos**: para mostrar `a.b.c.d` se extraen con desplazamientos:
  `(value >> 24) & 0xFF`, `(value >> 16) & 0xFF`, `(value >> 8) & 0xFF`,
  `value & 0xFF`.
- **Operaciones**: `&` (AND), `|` (OR) y complemento `~` se aplican
  directamente sobre el entero de 32 bits — son la base de todo el cálculo de
  máscaras.

### IPv6 — `lib/core/ipv6.dart`

Una IPv6 se guarda como un entero de **128 bits** usando `BigInt` (un `int`
de Dart no alcanza). El parseo soporta los tres formatos de RFC 4291 §2.2:

- **Forma completa**: 8 grupos de 16 bits separados por `:`.
- **Compresión `::`**: se separa el texto en `izquierda` y `derecha` por el
  único `::` permitido, se cuentan los grupos de cada lado, y los que faltan
  (`8 - izquierda.length - derecha.length`) se rellenan con grupos en `0`.
- **Forma mixta con IPv4 embebida**: si el último grupo contiene un `.`, se
  parsea como IPv4 y sus 32 bits se convierten en dos grupos hexadecimales de
  16 bits (`hi = (ipv4 >> 16) & 0xFFFF`, `lo = ipv4 & 0xFFFF`).

Cada grupo válido (1-4 dígitos hex) se acumula así para construir el entero
de 128 bits: `acc = (acc << 16) | grupo`.

### Texto canónico (RFC 5952) — `Ipv6Address.canonical`

Para que la misma dirección siempre se muestre igual (importante para
comparar e indexar), se aplica el algoritmo de RFC 5952:

1. Convertir los 8 grupos a hexadecimal en **minúsculas** y sin ceros a la
   izquierda.
2. Buscar la **corrida más larga** de grupos en `0` (de longitud ≥ 2; en caso
   de empate, la **primera** que aparece).
3. Reemplazar esa corrida por `::`. Si no hay ninguna corrida de longitud ≥ 2,
   no se usa `::` (regla explícita de RFC 5952: nunca comprimir un solo grupo
   en cero).

### Forma mixta para IPv4 embebida — `mixedFormIfApplicable`

Cuando la dirección es `IPv4-mapped` (`::ffff:0:0/96`) o usa el *Well-Known
Prefix* de NAT64 (`64:ff9b::/96`), los últimos 32 bits se vuelven a mostrar
como una IPv4 punteada (ej. `::ffff:192.0.2.33`) en lugar de hexadecimal,
comprimiendo aparte los 6 primeros grupos con el mismo algoritmo de RFC 5952.

---

## 2. Máscaras, prefijos y rangos (CIDR — RFC 4632)

### Máscara a partir de la longitud de prefijo

Para un prefijo `/p`, la máscara es un entero con `p` unos seguidos de
`(32-p)` o `(128-p)` ceros:

```
IPv4:  mask = 0xFFFFFFFF << (32 - p)        (con p = 0 ⇒ mask = 0)
IPv6:  mask = ((2^128 - 1) >> (128 - p)) << (128 - p)
```

A partir de la máscara se derivan, con operaciones bit a bit puras (nada de
tablas ni casos por clase):

| Campo | Fórmula |
|---|---|
| Wildcard | `~mask` |
| Red (network) | `dirección & mask` |
| Broadcast (solo IPv4) | `red \| wildcard` |
| Fin de prefijo (IPv6) | `inicio \| ~mask` |
| Direcciones totales | `2^(32-p)` (IPv4) o `2^(128-p)` (IPv6) |

### Hosts utilizables en IPv4 — caso general y excepciones normativas

```
si p ≤ 30:  hosts_útiles = 2^(32-p) - 2      (se restan red y broadcast)
si p == 31: hosts_útiles = 2                  (RFC 3021: enlaces punto a punto,
                                                ambas direcciones son host)
si p == 32: hosts_útiles = 1                  (host route)
```

Este caso especial existe porque, sin él, un `/31` calcularía `2-2=0` hosts,
lo que es matemáticamente correcto para LANs pero **incorrecto** para
enlaces P2P, donde RFC 3021 redefine el uso de esas 2 direcciones.

### IPv6 no tiene "broadcast"

IPv6 no resta direcciones: `totalAddresses = 2^(128-p)` son todas
"utilizables" en el sentido de identificadores de interfaz; la difusión se
resuelve con multicast (RFC 4291) y Neighbor Discovery (RFC 4861), no con una
dirección de broadcast dirigida.

---

## 3. Transición de máscara /p → /q (pantalla "Subnetting")

`lib/core/subnetting.dart` — `Ipv4Subnetting` / `Ipv6Subnetting`

Esta es la generalización de la función clásica "*Netmask for sub/supernet,
move to:*". Dado un prefijo original `/p`, hay tres formas de llegar al
resultado, pero **las tres terminan resolviendo el mismo problema
matemático**: encontrar la longitud de prefijo `/q` correcta y, si `q > p`,
generar 2^(q-p) bloques iguales.

### 3.1 Por prefijo destino directo (`transitionMask`)

- **Si `q == p`**: misma red, no hay cambio.
- **Si `q > p` (subneteo)**: se toman `(q - p)` bits adicionales del host.
  Esto multiplica por `2^(q-p)` la cantidad de subredes y divide el tamaño de
  cada una por ese mismo factor. La subred *i*-ésima (con `i` desde 0) se
  calcula como:

  ```
  bloque = 2^(32 - q)              (tamaño de cada subred, en direcciones)
  red_i  = red_original + i * bloque
  ```

  Se generan todas las `i = 0 .. 2^(q-p)-1` y se construye un
  `Ipv4Prefix`/`Ipv6Prefix` por cada una. Hay un límite de seguridad
  (`maxResults = 4096`) para no intentar renderizar millones de filas si el
  usuario pide, por ejemplo, pasar de `/8` a `/30`.

- **Si `q < p` (supernetting / agregación)**: en vez de generar varias redes,
  se recalcula la **superred** que contiene la dirección original aplicando
  la máscara más corta: `superred = dirección & mask(q)`. No se valida
  alineación porque aquí no se está agregando una lista de prefijos
  existentes (eso lo hace `aggregate`, ver 3.5) sino derivando *el* bloque
  contenedor de una sola dirección.

### 3.2 Por cantidad de subredes deseada (`byDesiredSubnetCount`)

Aquí el usuario no calcula `/q` a mano: indica cuántas subredes quiere y el
sistema deriva los bits necesarios.

Como las subredes de igual tamaño sólo pueden crearse en cantidades que sean
potencia de 2 (cada bit prestado *duplica* la cantidad de bloques, nunca la
incrementa en un número arbitrario), el algoritmo es:

```
bits_extra = el menor entero tal que 2^bits_extra ≥ cantidad_deseada
q = p + bits_extra
entregadas = 2^bits_extra
```

Esto se calcula incrementando una potencia de 2 (`capacity`) hasta igualar o
superar lo pedido, contando cuántas duplicaciones (`bits`) hicieron falta —
equivalente a `ceil(log2(cantidad_deseada))` pero hecho con enteros para
evitar errores de precisión de coma flotante.

Si `cantidad_deseada` no es ya una potencia de 2 (p. ej. se pide 6), el
resultado se redondea hacia arriba (a 8) y la UI muestra una nota explicando
cuántas se pidieron contra cuántas se entregaron realmente.

Se valida que `q` no supere 32 (IPv4) o 128 (IPv6): si pedir esa cantidad de
subredes exige más bits de los que existen en la dirección, se rechaza con
un mensaje explicando cuántos bits harían falta.

### 3.3 Por hosts requeridos por subred (`byHostsPerSubnet`, solo IPv4)

El usuario indica cuántos hosts utilizables necesita **en cada subred** y el
sistema busca el prefijo más largo (la red más pequeña) que todavía alcance:

```
necesario = hosts_pedidos + 2          (se reserva red y broadcast)
tamaño_bloque = la menor potencia de 2 ≥ necesario
q = 32 - log2(tamaño_bloque)
```

Casos especiales (coherentes con la tabla de la sección 2):
- `hosts_pedidos == 1` ⇒ `q = 32` (host route).
- `hosts_pedidos == 2` ⇒ `q = 31` (excepción RFC 3021, sin restar 2).

Una vez obtenido `q`, se divide la red base en bloques de ese tamaño igual
que en 3.1, y se informa cuántos bloques de `/q` entran en total dentro de la
red base (`2^(q - p)`). Si la red base es **más pequeña** que el bloque
necesario (`q < p`), se rechaza explícitamente: no tiene sentido pedir 1000
hosts dentro de un `/28`.

Este modo no existe para IPv6 porque no hay "hosts utilizables" en el sentido
de restar direcciones reservadas — cualquier /64 tiene 2^64 identificadores
disponibles sin excepciones.

### 3.4 VLSM — asignación por requerimientos distintos (`vlsm`)

Aunque no está expuesto todavía en la UI, el motor implementa VLSM clásico
(RFC 4632): dada una lista de requerimientos de hosts distintos entre sí, se
ordenan de mayor a menor demanda (para minimizar fragmentación — los bloques
grandes deben ubicarse primero), y a cada uno se le asigna el bloque más
pequeño que lo satisface (misma fórmula que 3.3), alineado al múltiplo de su
propio tamaño:

```
bloque = 2^(32 - q_requerimiento)
inicio_alineado = ceil(cursor / bloque) * bloque
```

El `cursor` avanza después de cada asignación (`cursor = broadcast_asignado +
1`), y si en algún punto el bloque alineado se saldría del rango de la red
base, se lanza un error indicando cuántos bits se necesitaban.

### 3.5 Agregación / supernetting de una lista (`aggregate`)

Dado un conjunto de prefijos (no necesariamente generados por este sistema),
se intenta resumirlos en bloques más grandes, de forma iterativa:

1. Ordenar por dirección de red.
2. Recorrer la lista buscando **pares adyacentes** `(a, b)` tales que:
   - tengan la **misma longitud de prefijo**,
   - `b` empiece exactamente donde termina el bloque de `a`
     (`red_b == red_a + 2^(32 - longitud)`),
   - y `a` esté **alineado** al límite de la superred resultante
     (`red_a % 2^(32 - (longitud-1)) == 0`).
3. Si se cumplen las tres condiciones, se reemplaza el par por una sola
   superred con `longitud - 1`, y se repite el proceso completo (porque la
   nueva superred puede a su vez combinarse con su vecina).

Esto es exactamente la condición de RFC 4632 para que el *longest prefix
match* siga siendo válido tras agregar: sin alineación, la superred
"inventada" incluiría direcciones que no pertenecían a ninguno de los dos
bloques originales.

---

## 4. Transición IPv4 ↔ IPv6 (`lib/core/transition.dart`)

### 4.1 IPv4-mapped (RFC 4291 §2.5.5.2)

Es la incrustación más simple: 80 bits en cero, 16 bits en `ffff`, y los 32
bits de la IPv4 al final.

```
v6 = 0x00000000_0000_FFFF_00000000  |  ipv4   (128 bits)
```

Es **solo representación** (para sockets/APIs dual-stack): no es un mecanismo
de tránsito y no debería rutearse así.

### 4.2 RFC 6052 — incrustación algorítmica con Well-Known Prefix o NSP

Este es el cálculo más delicado del sistema porque el RFC **no** coloca los
32 bits de la IPv4 de forma contigua salvo cuando el prefijo es `/96`. Para
prefijos más cortos, el RFC reserva siempre el octeto `u` (bits 64-71, debe
ser `0`) y divide la IPv4 alrededor de él:

```
highBits = 64 - PL      (bits de la IPv4 que caben ANTES del octeto u)
lowBits  = 32 - highBits (bits de la IPv4 que van DESPUÉS del octeto u)
```

| PL | bits de IPv4 antes de `u` | bits de IPv4 después de `u` |
|---|---|---|
| 32 | 32 (toda la IPv4) | 0 |
| 40 | 24 | 8 |
| 48 | 16 | 16 |
| 56 | 8 | 24 |
| 64 | 0 | 32 (toda la IPv4) |
| 96 | — (no hay octeto `u`) | toda la IPv4 al final |

Implementación (`_embedV4Bits` / `_extractV4Bits`):

```
parte_alta = los `highBits` bits más significativos de la IPv4
parte_baja = los `lowBits` bits restantes (los menos significativos)

# Posicionamiento dentro del entero de 128 bits:
resultado |= parte_alta << 64            # siempre termina justo antes del bit 64
resultado |= parte_baja << (88 - PL)     # siempre empieza justo después del bit 71
```

Que el desplazamiento de `parte_alta` sea siempre `64` (sin importar `PL`,
mientras sea < 64) no es casualidad: la parte alta de la IPv4 *siempre*
termina exactamente en el bit 63, justo antes del octeto `u`; por eso su
posición no depende de dónde empiece (que sí depende de `PL`), solo de dónde
termina. La extracción aplica la operación inversa (desplazar a la derecha y
enmascarar) y reconstruye `ipv4 = (parte_alta << lowBits) | parte_baja`.

Para `PL = 96` no hay octeto `u`: la IPv4 ocupa directamente los últimos 32
bits (`resultado = prefijo | ipv4`).

**Validación normativa (RFC 6052 §3.1)**: si el prefijo usado es el
*Well-Known Prefix* `64:ff9b::/96` y la IPv4 a embeber **no** es una
dirección global (por ejemplo, es RFC 1918), el sistema muestra una
advertencia explícita: el WKP no debe usarse con IPv4 no globales, y esos
paquetes deberían descartarse según el RFC. La alternativa correcta para
direcciones privadas es el prefijo local `64:ff9b:1::/48` (RFC 8215) o un
Network-Specific Prefix propio — el sistema lo sugiere en el mismo mensaje.

### 4.3 6to4 (RFC 3056)

El prefijo de sitio `/48` se construye colocando el literal `2002` en los
primeros 16 bits y la IPv4 completa en los siguientes 32:

```
prefijo_2002 = 0x2002                     (bits 0-15)
v6 = (0x2002 << 112) | (ipv4 << 80)       (bits 16-47 = IPv4)
```

La extracción inversa es `ipv4 = (v6 >> 80) & 0xFFFFFFFF`. El sistema marca
este método como legado y advierte que RFC 7526 desaconseja su variante
anycast para despliegues nuevos.

---

## 5. Clasificación normativa de direcciones

`Ipv4Address.classification` y `Ipv6Address.classification` no usan un único
`if` plano: comprueban, en orden, pertenencia a cada bloque reservado
calculando `(dirección & máscara_del_bloque) == red_del_bloque`, exactamente
la misma operación que define la red de un prefijo. Esto evita reglas
especiales por "forma del texto" — todo se reduce a la misma operación AND
usada en el resto del sistema:

- IPv4: loopback (`127/8`), privadas (RFC 1918: `10/8`, `172.16/12`,
  `192.168/16`), link-local/APIPA (`169.254/16`, RFC 3927), CGN compartido
  (`100.64/10`, RFC 6598), documentación (RFC 5737), benchmarking (RFC 2544),
  multicast (`224/4`), reservada (`240/4`).
- IPv6: loopback, multicast (`ff00::/8`), link-local (`fe80::/10`), ULA
  (`fc00::/7`, RFC 4193), IPv4-mapped (`::ffff:0:0/96`), NAT64 WKP
  (`64:ff9b::/96`) y prefijo local (`64:ff9b:1::/48`, RFC 8215),
  documentación (`2001:db8::/32`), 6to4 (`2002::/16`), Teredo (`2001::/32`).

---

## 6. Motor de conectividad (`lib/core/connectivity.dart`)

No asume que "si las redes son iguales hay conectividad": separa
explícitamente cuatro situaciones, en este orden de evaluación:

1. **Mismo enlace** (misma familia, mismo `network`/`networkStart` y misma
   longitud de prefijo): resuelto por ARP (IPv4) o Neighbor Discovery —
   RFC 4861 (IPv6), sin pasar por un router.
2. **Ruteo dentro de la misma familia** (misma familia, redes distintas):
   requiere un router con ruta hacia ambos prefijos. El sistema **no**
   verifica una tabla de rutas real — solo determina que se necesita ruteo
   porque las direcciones no comparten el mismo prefijo de enlace.
3. **Familias distintas**:
   - Si ambos extremos son dual-stack, se recomienda preferir la familia
     común (normalmente IPv6) en vez de traducir.
   - Si alguno declara tener traductor/túnel disponible, se indica que la
     conectividad es posible vía NAT64+DNS64 (RFC 6146/6147) o SIIT
     (RFC 7915), con la misma advertencia de RFC 6052 sobre el WKP si
     corresponde.
   - Si ninguna de las dos anteriores aplica, se reporta explícitamente
     "sin conectividad directa" y se listan las opciones (dual-stack,
     NAT64/SIIT, DS-Lite, MAP-E/MAP-T) en vez de asumir que existe un camino.

---

## 7. Estructura del proyecto

```
lib/
  core/
    ipv4.dart              Dirección y prefijo IPv4, máscaras, clasificación
    ipv6.dart               Dirección y prefijo IPv6, texto RFC 5952, clasificación
    subnetting.dart         Transición /p→/q, por cantidad, por hosts, VLSM, agregación
    transition.dart         IPv4-mapped, RFC 6052, 6to4
    connectivity.dart        Motor de decisión de conectividad
    reference_data.dart      Tabla de RFC mostrada en la pestaña "Referencia"
  screens/                   Una pantalla por motor (UI en Flutter)
  widgets/bit_view.dart      Render de bits coloreados (prefijo vs. host)
```

## Cómo compilar y ejecutar

```bash
flutter pub get
flutter run -d windows          # modo desarrollo, con hot reload
flutter build windows --release # genera build/windows/x64/runner/Release/ipv4_ipv6_toolkit.exe
```
