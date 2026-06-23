class RfcReference {
  final String rfc;
  final String topic;
  final String why;
  const RfcReference(this.rfc, this.topic, this.why);
}

const List<RfcReference> rfcReferenceTable = [
  RfcReference('RFC 791', 'IPv4', 'Base histórica de la dirección IPv4 y clases A/B/C.'),
  RfcReference('RFC 4632', 'CIDR', 'Prefijos, notación classless, longest match, agregación de rutas.'),
  RfcReference('RFC 1918', 'IPv4 privado', 'Rangos 10/8, 172.16/12, 192.168/16 y por qué filtrarlos.'),
  RfcReference('RFC 3021', '/31 en IPv4', 'Permite usar ambas direcciones de un /31 en enlaces punto a punto.'),
  RfcReference('RFC 5737', 'Documentación IPv4', '192.0.2.0/24, 198.51.100.0/24, 203.0.113.0/24 para ejemplos.'),
  RfcReference('RFC 4291', 'Arquitectura IPv6', 'Tipos de dirección, texto, prefijos, IPv4-mapped, sin broadcast.'),
  RfcReference('RFC 5952', 'Texto canónico IPv6', 'Minúsculas, "::" óptimo, sin ceros a la izquierda.'),
  RfcReference('RFC 4193', 'ULA', 'fc00::/7, equivalente funcional a "privado" en IPv6.'),
  RfcReference('RFC 3849', 'Documentación IPv6', '2001:db8::/32 reservado para ejemplos.'),
  RfcReference('RFC 7421', 'Frontera de 64 bits', 'Por qué /64 es la unidad operativa estándar de un enlace.'),
  RfcReference('RFC 6177', 'Asignación de sitio', 'Ya no recomienda /48 único; depende de uso y crecimiento.'),
  RfcReference('RFC 4861', 'Neighbor Discovery', 'Resolución de vecinos y descubrimiento de routers en IPv6.'),
  RfcReference('RFC 4862', 'SLAAC', 'Autoconfiguración sin estado y Duplicate Address Detection.'),
  RfcReference('RFC 8415', 'DHCPv6', 'Direcciones, parámetros y delegación de prefijos.'),
  RfcReference('RFC 8200', 'Especificación IPv6', 'MTU mínimo de enlace de 1280 octetos.'),
  RfcReference('RFC 8201', 'PMTUD en IPv6', 'Depende de ICMPv6 Packet Too Big; no filtrar indiscriminadamente.'),
  RfcReference('RFC 6052', 'IPv4 embebida en IPv6', 'Algoritmo de incrustación/extracción, PL∈{32,40,48,56,64,96}.'),
  RfcReference('RFC 7915', 'SIIT', 'Traducción stateless de cabeceras IPv4/IPv6.'),
  RfcReference('RFC 6146', 'NAT64', 'Traducción stateful para clientes IPv6-only hacia IPv4.'),
  RfcReference('RFC 6147', 'DNS64', 'Síntesis de registros AAAA a partir de registros A.'),
  RfcReference('RFC 8215', 'Prefijo local NAT64', '64:ff9b:1::/48 para uso interno, sin restricción del WKP.'),
  RfcReference('RFC 3056', '6to4', 'Túnel automático legado vía prefijo 2002::/16.'),
  RfcReference('RFC 7526', '6to4 anycast', 'Desaconseja el despliegue anycast de 6to4.'),
  RfcReference('RFC 6333', 'DS-Lite', 'IPv4 sobre acceso IPv6 mediante túnel hacia un AFTR + NAT44.'),
  RfcReference('RFC 7597', 'MAP-E', 'Mapeo de direcciones y puertos con encapsulación.'),
  RfcReference('RFC 7599', 'MAP-T', 'Mapeo de direcciones y puertos con traducción (menor overhead).'),
];
