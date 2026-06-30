# Logica matematica IPv4 e IPv6

Este documento explica, por bloques, la logica matematica que usa la app para
IPv4, IPv6, subnetting, conversiones, mecanismos de transicion y conectividad.
La implementacion principal vive en `lib/core/ipv4.dart`,
`lib/core/ipv6.dart`, `lib/core/subnetting.dart`, `lib/core/transition.dart` y
`lib/core/connectivity.dart`.

## Bloque 1: modelo numerico base

### IPv4

IPv4 se modela como un entero sin signo de 32 bits.

Una direccion como:

```text
192.168.0.1
```

se separa en 4 octetos:

```text
192, 168, 0, 1
```

Cada octeto debe cumplir:

```text
0 <= octeto <= 255
```

El valor entero se arma desplazando 8 bits por octeto:

```text
valor = (((192 << 8) | 168) << 8 | 0) << 8 | 1
```

Formula general:

```text
valor = (o1 << 24) | (o2 << 16) | (o3 << 8) | o4
```

Para volver a texto se invierte el proceso:

```text
o1 = (valor >> 24) & 0xff
o2 = (valor >> 16) & 0xff
o3 = (valor >> 8)  & 0xff
o4 = valor & 0xff
```

### IPv6

IPv6 se modela como un entero de 128 bits (`BigInt`).

Una direccion IPv6 tiene 8 grupos de 16 bits:

```text
2001:0db8:0000:0000:0000:0000:0000:0001
```

Cada grupo hexadecimal debe cumplir:

```text
0x0000 <= grupo <= 0xffff
```

El valor entero se arma desplazando 16 bits por grupo:

```text
valor = (((g1 << 16) | g2) << 16 | g3) ... | g8
```

La app permite:

- Una sola compresion `::`.
- Sufijo IPv4 embebido, por ejemplo `::ffff:192.0.2.33`.
- Identificador de zona despues de `%`, que se elimina antes de parsear.

Si existe un sufijo IPv4, se convierte en dos grupos de 16 bits:

```text
192.0.2.33 = 0xc0000221
grupo_alto = 0xc000
grupo_bajo = 0x0221
```

## Bloque 2: normalizacion de texto IPv6

Para la forma canonica IPv6 se usa la idea de RFC 5952:

- Se escriben los grupos en minuscula.
- Se quitan ceros a la izquierda.
- Se comprime con `::` la secuencia mas larga de grupos `0000`.
- Solo se comprime si la secuencia tiene longitud 2 o mayor.

Ejemplo:

```text
2001:0db8:0000:0000:0000:0000:0000:0001
```

queda:

```text
2001:db8::1
```

## Bloque 3: prefijos CIDR y mascaras

Un prefijo `/p` indica cuantos bits son de red.

### IPv4

IPv4 tiene 32 bits. Para un prefijo `/p`:

```text
bits_red = p
bits_host = 32 - p
```

La mascara se calcula asi:

```text
si p = 0:
  mascara = 0
si p > 0:
  mascara = 0xffffffff << (32 - p)
```

La app conserva solo 32 bits:

```text
mascara = mascara & 0xffffffff
```

La wildcard es el complemento de la mascara:

```text
wildcard = ~mascara
```

La red se calcula con AND binario:

```text
red = direccion & mascara
```

El broadcast se calcula con OR:

```text
broadcast = red | wildcard
```

El total de direcciones es:

```text
total = 2^(32 - p)
```

Hosts utilizables:

```text
si p <= 30:
  hosts = 2^(32 - p) - 2
si p = 31:
  hosts = 2
si p = 32:
  hosts = 1
```

Reglas especiales:

- `/31`: enlace punto a punto; ambas direcciones son utilizables.
- `/32`: ruta de host; representa un unico dispositivo.

### IPv6

IPv6 tiene 128 bits. Para un prefijo `/p`:

```text
bits_red = p
bits_host = 128 - p
```

La mascara se calcula con:

```text
full = 2^128 - 1
hostBits = 128 - p
mascara = (full >> hostBits) << hostBits
```

La red inicial:

```text
inicio = direccion & mascara
```

La direccion final:

```text
fin = inicio | complemento(mascara)
```

El total de direcciones:

```text
total = 2^(128 - p)
```

IPv6 no usa broadcast. En lugar de ARP/broadcast, usa Neighbor Discovery y
multicast.

## Bloque 4: subnetting por cambio de mascara

La pantalla de subnetting permite pasar de una mascara original `/p` a una
mascara destino `/q`.

### Caso 1: misma mascara

Si:

```text
q = p
```

se mantiene una sola red.

### Caso 2: dividir en subredes

Si:

```text
q > p
```

se toman bits de host y se convierten en bits de red.

Cantidad de subredes:

```text
cantidad = 2^(q - p)
```

Tamano de cada bloque IPv4:

```text
bloque = 2^(32 - q)
```

Tamano de cada bloque IPv6:

```text
bloque = 2^(128 - q)
```

La red `i` se calcula asi:

```text
red_i = red_base + i * bloque
```

Ejemplo IPv4:

```text
192.168.0.0/24 -> /26
cantidad = 2^(26 - 24) = 4
bloque = 2^(32 - 26) = 64
```

Subredes:

```text
192.168.0.0/26
192.168.0.64/26
192.168.0.128/26
192.168.0.192/26
```

### Caso 3: agregacion hacia superred

Si:

```text
q < p
```

la app calcula una superred:

```text
superred = direccion & mascara(q)
```

Ejemplo:

```text
192.168.0.65/26 -> /24
superred = 192.168.0.0/24
```

## Bloque 5: subnetting por cantidad deseada

Cuando el usuario pide una cantidad de subredes, la app redondea a la siguiente
potencia de 2 porque los bloques CIDR deben alinearse por bits.

Para `n` subredes deseadas:

```text
extraBits = menor b tal que 2^b >= n
nuevoPrefijo = prefijoBase + extraBits
subredesEntregadas = 2^extraBits
```

Ejemplo:

```text
red base = /24
subredes deseadas = 3
extraBits = 2 porque 2^2 = 4
nuevoPrefijo = /26
subredes entregadas = 4
```

## Bloque 6: subnetting por hosts utilizables

Para IPv4, si se pide una cantidad de hosts por subred, la app busca el prefijo
mas especifico que todavia soporte esos hosts.

Para hosts normales:

```text
2^(32 - p) - 2 >= hosts
```

Casos especiales:

```text
hosts = 1 -> /32
hosts = 2 -> /31
```

Ejemplo:

```text
hosts requeridos = 50
se necesita total >= 52
2^5 = 32  no alcanza
2^6 = 64  alcanza
bits_host = 6
prefijo = 32 - 6 = /26
hosts utiles = 64 - 2 = 62
```

## Bloque 7: VLSM

VLSM asigna subredes de tamanos distintos dentro de una red base.

La app hace:

1. Ordena los requerimientos de hosts de mayor a menor.
2. Calcula el prefijo minimo para cada requerimiento.
3. Alinea el cursor al tamano del bloque.
4. Asigna el bloque si cabe dentro de la red base.
5. Mueve el cursor al siguiente bloque disponible.

Alineacion:

```text
alineado = ceil(cursor / bloque) * bloque
```

Ejemplo:

```text
base = 10.0.0.0/24
hosts = [100, 50, 10]
```

Resultado:

```text
100 hosts -> 10.0.0.0/25
50 hosts  -> 10.0.0.128/26
10 hosts  -> 10.0.0.192/28
```

## Bloque 8: agregacion de prefijos

La app puede unir dos prefijos contiguos si:

- Tienen la misma longitud.
- Son adyacentes.
- El primer prefijo esta alineado para formar el padre.

Condicion simplificada para IPv4:

```text
b.red = a.red + 2^(32 - longitud)
a.red % 2^(32 - (longitud - 1)) = 0
```

Si se cumple:

```text
a/longitud + b/longitud -> a/(longitud - 1)
```

Ejemplo:

```text
192.168.0.0/25 + 192.168.0.128/25 = 192.168.0.0/24
```

## Bloque 9: clasificacion IPv4

La clasificacion se hace comparando la direccion con rangos CIDR mediante:

```text
(direccion & mascara) == (base & mascara)
```

Rangos principales:

```text
0.0.0.0/32          -> no especificada
255.255.255.255/32  -> broadcast limitado
127.0.0.0/8         -> loopback
10.0.0.0/8          -> privada
172.16.0.0/12       -> privada
192.168.0.0/16      -> privada
169.254.0.0/16      -> link-local/APIPA
100.64.0.0/10       -> CGNAT compartida
192.0.2.0/24        -> documentacion
198.51.100.0/24     -> documentacion
203.0.113.0/24      -> documentacion
198.18.0.0/15       -> benchmarking
224.0.0.0/4         -> multicast
240.0.0.0/4         -> reservada
resto               -> unicast global
```

## Bloque 10: clasificacion IPv6

Tambien se usa:

```text
(direccion & mascara) == (base & mascara)
```

Rangos principales:

```text
::/128              -> no especificada
::1/128             -> loopback
ff00::/8            -> multicast
fe80::/10           -> link-local
fc00::/7            -> ULA
::ffff:0:0/96       -> IPv4-mapped
64:ff9b::/96        -> NAT64 Well-Known Prefix
64:ff9b:1::/48      -> prefijo local NAT64
2001:db8::/32       -> documentacion
2002::/16           -> 6to4
2001::/32           -> Teredo
resto               -> unicast global
```

## Bloque 11: conversion IPv4-mapped

IPv4-mapped representa una IPv4 dentro de IPv6 con el prefijo:

```text
::ffff:0:0/96
```

Formato:

```text
::ffff:a.b.c.d
```

Matematicamente:

```text
ipv6 = 0x00000000000000000000ffff00000000 | ipv4
```

Ejemplo:

```text
192.0.2.33 = 0xc0000221
IPv4-mapped = ::ffff:192.0.2.33
```

Para extraer la IPv4:

```text
ipv4 = ipv6 & 0xffffffff
```

Uso esperado:

- Representacion interna de APIs dual-stack.
- No es un mecanismo de ruteo publico.

## Bloque 12: RFC 6052 / NAT64 / SIIT

RFC 6052 define como incrustar una IPv4 dentro de una IPv6 usando un prefijo
IPv6.

Longitudes permitidas por la app:

```text
PL in {32, 40, 48, 56, 64, 96}
```

Primero se limpian bits fuera del prefijo:

```text
prefixBits = prefixAddress & mask(PL)
```

### Caso PL = 96

La IPv4 ocupa los ultimos 32 bits:

```text
resultado = prefixBits | ipv4
```

Ejemplo:

```text
64:ff9b::/96 + 192.0.2.33
= 64:ff9b::c000:221
= 64:ff9b::192.0.2.33
```

Extraccion:

```text
ipv4 = ipv6 & 0xffffffff
```

### Casos PL distintos de 96

La app divide los 32 bits IPv4 en parte alta y parte baja:

```text
highBits = 64 - PL
lowBits = 32 - highBits
```

Parte alta:

```text
highPart = (ipv4 >> lowBits) & ((1 << highBits) - 1)
```

Parte baja:

```text
lowPart = ipv4 & ((1 << lowBits) - 1)
```

Insercion:

```text
resultado = prefixBits
resultado |= highPart << 64
resultado |= lowPart << (88 - PL)
```

Extraccion inversa:

```text
highPart = (ipv6 >> 64) & ((1 << highBits) - 1)
lowPart  = (ipv6 >> (88 - PL)) & ((1 << lowBits) - 1)
ipv4 = (highPart << lowBits) | lowPart
```

Regla de seguridad:

- Si se usa `64:ff9b::/96`, la IPv4 deberia ser global.
- Para IPv4 privada se recomienda un prefijo local como `64:ff9b:1::/48` o un
  Network-Specific Prefix propio.

## Bloque 13: 6to4

6to4 usa el prefijo:

```text
2002::/16
```

La IPv4 se coloca despues de `2002`, formando un `/48`.

Formula:

```text
resultado = (0x2002 << 112) | (ipv4 << 80)
```

Ejemplo:

```text
IPv4 = 192.0.2.1 = c000:0201
6to4 = 2002:c000:0201::/48
```

Extraccion:

```text
ipv4 = (ipv6 >> 80) & 0xffffffff
```

Advertencia:

- 6to4 es legado.
- Requiere IPv4 publica unica.
- El despliegue anycast de 6to4 esta desaconsejado para escenarios nuevos.

## Bloque 14: logica de conectividad

La app no promete conectividad real absoluta; evalua condiciones logicas segun
direcciones, prefijos y capacidades declaradas.

### Ambos extremos IPv4

Se calcula:

```text
mismaRed = a.length == b.length && a.network == b.network
```

Si `mismaRed`:

```text
resultado = comunicacion directa IPv4
```

Si no:

```text
resultado = requiere ruteo IPv4
```

### Ambos extremos IPv6

Se calcula:

```text
mismaRed = a.length == b.length && a.networkStart == b.networkStart
```

Si `mismaRed`:

```text
resultado = comunicacion directa IPv6
```

Si no:

```text
resultado = requiere ruteo IPv6
```

### Familias distintas

Si uno usa IPv4 y otro IPv6:

```text
si ambos declaran dual-stack:
  posible por familia comun
si alguno declara traductor/tunel:
  posible mediante traduccion/tunel
si no:
  sin camino directo declarado
```

La app tambien muestra advertencias para direcciones especiales: privadas,
documentacion, loopback, multicast, link-local, ULA, reservadas, etc.

## Bloque 15: tema claro/oscuro e idioma

El tema vive en `main.dart`:

```text
theme = _buildAppTheme(Brightness.light)
darkTheme = _buildAppTheme(Brightness.dark)
themeMode = ThemeMode.light o ThemeMode.dark
```

El usuario cambia el modo con el control Claro/Oscuro. La UI usa
`ColorScheme` para que colores, superficies, textos y bordes cambien con el
tema.

El idioma usa `AppLocalization`, un `InheritedWidget` con:

```text
AppLanguage.es
AppLanguage.en
```

La app escribe las cadenas base en espanol y, si el idioma activo es ingles,
busca la traduccion en el mapa `_en`.

Si una cadena no esta en el mapa:

```text
se muestra la cadena original
```

## Bloque 16: validaciones automatizadas

Las pruebas cubren:

- Parseo y clasificacion IPv4.
- Parseo, normalizacion y clasificacion IPv6.
- Subnetting IPv4 e IPv6.
- Semantica especial `/31` y `/32`.
- Redondeo a potencias de 2.
- VLSM y agregacion.
- RFC 6052.
- Transicion IPv4 a IPv6 y extraccion IPv6 a IPv4.
- Conectividad entre extremos.
- Limpieza de resultados al editar.
- Cambio de idioma ES/EN.
- Cambio de tema claro/oscuro.

Comandos usados para validar:

```text
flutter analyze
flutter test
flutter build web
```

## Bloque 17: limites del modelo

La app calcula con reglas matematicas y de protocolo, pero no inspecciona la red
real.

No verifica:

- Tabla de rutas real.
- ARP real.
- Neighbor Discovery real.
- Firewalls.
- NAT desplegado.
- DNS64 real.
- Politicas de proveedor.
- ACLs.

Por eso los resultados de conectividad deben leerse como requisitos logicos:

```text
misma red -> podria comunicarse directamente si comparten enlace real
red distinta -> requiere router
IPv4 vs IPv6 -> requiere dual-stack o traduccion/tunel
```

## Bloque 18: resumen rapido de formulas

```text
IPv4 valor = (o1 << 24) | (o2 << 16) | (o3 << 8) | o4
IPv4 mascara(/p) = 0xffffffff << (32 - p)
IPv4 red = direccion & mascara
IPv4 wildcard = ~mascara
IPv4 broadcast = red | wildcard
IPv4 total = 2^(32 - p)
IPv4 hosts = 2^(32 - p) - 2, salvo /31 y /32

IPv6 valor = (((g1 << 16) | g2) ... | g8)
IPv6 mascara(/p) = ((2^128 - 1) >> (128 - p)) << (128 - p)
IPv6 inicio = direccion & mascara
IPv6 fin = inicio | ~mascara
IPv6 total = 2^(128 - p)

Subredes = 2^(nuevoPrefijo - prefijoOriginal)
Tamano bloque IPv4 = 2^(32 - nuevoPrefijo)
Tamano bloque IPv6 = 2^(128 - nuevoPrefijo)
red_i = red_base + i * tamanoBloque

IPv4-mapped = ::ffff:0:0/96 | ipv4
RFC6052 /96 = prefixBits | ipv4
6to4 = (0x2002 << 112) | (ipv4 << 80)
```
