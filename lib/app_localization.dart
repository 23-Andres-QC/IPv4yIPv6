import 'package:flutter/widgets.dart';

enum AppLanguage { es, en }

class AppLocalization extends InheritedWidget {
  final AppLanguage language;

  const AppLocalization({
    super.key,
    required this.language,
    required super.child,
  });

  static AppLanguage languageOf(BuildContext context) {
    return context
            .dependOnInheritedWidgetOfExactType<AppLocalization>()
            ?.language ??
        AppLanguage.es;
  }

  static String translate(BuildContext context, String spanish) {
    if (languageOf(context) == AppLanguage.es) {
      return spanish;
    }
    return _en[spanish] ?? spanish;
  }

  @override
  bool updateShouldNotify(AppLocalization oldWidget) {
    return language != oldWidget.language;
  }
}

extension AppText on BuildContext {
  String t(String spanish) => AppLocalization.translate(this, spanish);

  bool get isEnglish => AppLocalization.languageOf(this) == AppLanguage.en;
}

const Map<String, String> _en = {
  'Herramienta IPv4 ↔ IPv6': 'IPv4 ↔ IPv6 Toolkit',
  'Tema de color': 'Theme',
  'Claro': 'Light',
  'Oscuro': 'Dark',
  'Calculadora': 'Calculator',
  'Transición v4↔v6': 'v4↔v6 transition',
  'Conectividad': 'Connectivity',
  'Referencia RFC': 'RFC reference',
  'Calculadora de direcciones': 'Address calculator',
  'Ingresa una dirección IP y un prefijo para analizar la subred completa.':
      'Enter an IP address and prefix to analyze the complete subnet.',
  'Versión del protocolo': 'Protocol version',
  'Dirección y prefijo de red': 'Address and network prefix',
  'Dirección IP': 'IP address',
  'Grupos hexadecimales separados por dos puntos':
      'Hexadecimal groups separated by colons',
  'Cuatro números del 0 al 255, separados por puntos':
      'Four numbers from 0 to 255, separated by dots',
  'Prefijo': 'Prefix',
  'Bits de red': 'Network bits',
  'Calcular': 'Calculate',
  'Copiado': 'Copied',
  'Dirección inválida': 'Invalid address',
  'Dirección inválida. Usa el formato correcto: 192.168.0.1':
      'Invalid address. Use the correct format: 192.168.0.1',
  'Dirección IPv6 inválida. Usa el formato: 2001:db8::1':
      'Invalid IPv6 address. Use the format: 2001:db8::1',
  'El prefijo debe ser un número entre 0 y 128. Ej: 64':
      'The prefix must be a number between 0 and 128. Example: 64',
  'El prefijo debe ser un número entre 0 y 32. Ej: 24':
      'The prefix must be a number between 0 and 32. Example: 24',
  'El prefijo debe ser un número entre 0 y 128.':
      'The prefix must be a number between 0 and 128.',
  'El prefijo debe ser un número entre 0 y 32.':
      'The prefix must be a number between 0 and 32.',
  'Detalles de la subred': 'Subnet details',
  'Ver tipo de red': 'View network type',
  'Red': 'Network',
  'Identificador del bloque de red': 'Network block identifier',
  'Primer host': 'First host',
  'Primera IP asignable a un dispositivo': 'First IP assignable to a device',
  'Último host': 'Last host',
  'Última IP asignable a un dispositivo': 'Last IP assignable to a device',
  'Broadcast': 'Broadcast',
  'Envío simultáneo a todos los dispositivos':
      'Simultaneous delivery to all devices',
  'Máscara de subred': 'Subnet mask',
  'Distingue la parte de red de la de host':
      'Separates the network portion from the host portion',
  'Wildcard': 'Wildcard',
  'Inverso de la máscara, usado en ACLs y firewalls':
      'Inverse mask, used in ACLs and firewalls',
  'Dirección': 'Address',
  'Máscara': 'Mask',
  'Inverso máscara': 'Inverse mask',
  'Difusión': 'Broadcast',
  'Formas de la dirección': 'Address forms',
  'Canónica': 'Canonical',
  'Forma comprimida según RFC 5952': 'Compressed form according to RFC 5952',
  'Forma completa': 'Full form',
  'Los 128 bits sin comprimir': 'The 128 bits without compression',
  'Forma mixta': 'Mixed form',
  'IPv6 con IPv4 embebida': 'IPv6 with embedded IPv4',
  'Inicio del prefijo': 'Prefix start',
  'Fin del prefijo': 'Prefix end',
  'Primera dirección del bloque': 'First address in the block',
  'Última dirección del bloque': 'Last address in the block',
  'Direcciones totales': 'Total addresses',
  'Hosts utilizables': 'Usable hosts',
  'Representación binaria': 'Binary representation',
  'Bits de red (prefijo)': 'Network bits (prefix)',
  'Bits de host': 'Host bits',
  'Bits de máscara': 'Mask bits',
  'Rango de subred': 'Subnet range',
  'Copiar valor': 'Copy value',
  'Separador CIDR: divide la dirección del prefijo de red':
      'CIDR separator: divides the address from the network prefix',
  'Ver cada bit de la dirección — para estudiantes y profesionales':
      'View each address bit - for students and professionals',
  'Red Pública': 'Public network',
  'Red Privada': 'Private network',
  'No especificada': 'Unspecified',
  'No especificada (0.0.0.0)': 'Unspecified (0.0.0.0)',
  'Privada': 'Private',
  'Privada (RFC 1918)': 'Private (RFC 1918)',
  'Link-local / APIPA': 'Link-local / APIPA',
  'Link-local / APIPA (169.254.0.0/16, RFC 3927)':
      'Link-local / APIPA (169.254.0.0/16, RFC 3927)',
  'Compartida CGN': 'Shared CGN',
  'Compartida CGN (100.64.0.0/10, RFC 6598)':
      'Shared CGN (100.64.0.0/10, RFC 6598)',
  'Documentación': 'Documentation',
  'Documentación (RFC 5737) — no usar en producción':
      'Documentation (RFC 5737) - do not use in production',
  'Benchmarking (198.18.0.0/15, RFC 2544)':
      'Benchmarking (198.18.0.0/15, RFC 2544)',
  'Multicast (clase D, 224.0.0.0/4)': 'Multicast (class D, 224.0.0.0/4)',
  'Broadcast limitado': 'Limited broadcast',
  'Broadcast limitado (255.255.255.255)': 'Limited broadcast (255.255.255.255)',
  'Reservada': 'Reserved',
  'Reservada (clase E, 240.0.0.0/4)': 'Reserved (class E, 240.0.0.0/4)',
  'Unicast global': 'Global unicast',
  'Unicast global (potencialmente ruteable en Internet)':
      'Global unicast (potentially routable on the Internet)',
  'Link-local': 'Link-local',
  'Unique Local Address / ULA': 'Unique Local Address / ULA',
  'IPv4-mapped': 'IPv4-mapped',
  'NAT64 WKP': 'NAT64 WKP',
  'Prefijo local NAT64': 'Local NAT64 prefix',
  'Esta dirección es accesible desde Internet.':
      'This address is reachable from the Internet.',
  'Esta dirección pertenece a una red local. No es accesible desde Internet.':
      'This address belongs to a local network. It is not reachable from the Internet.',
  'Esta dirección IPv6 es accesible desde Internet.':
      'This IPv6 address is reachable from the Internet.',
  'Esta dirección IPv6 pertenece a una red local (ULA). No es accesible desde Internet.':
      'This IPv6 address belongs to a local network (ULA). It is not reachable from the Internet.',
  'RFC 3021: en prefijos /31, ambas IPs son utilizables como host (enlace punto a punto).':
      'RFC 3021: in /31 prefixes, both IPs are usable as hosts (point-to-point link).',
  'Host route /32: representa un único dispositivo específico, sin subred.':
      'Host route /32: represents a single specific device, without a subnet.',
  'IPv6 no usa broadcast. La difusión grupal se realiza con multicast (RFC 4291) y Neighbor Discovery (RFC 4861).':
      'IPv6 does not use broadcast. Group delivery is done with multicast (RFC 4291) and Neighbor Discovery (RFC 4861).',
  'Uso en redes locales (hogares, oficinas). No enrutable en Internet.':
      'Used in local networks (homes, offices). Not routable on the Internet.',
  'Dirección pública. Puede ser alcanzada desde cualquier punto de Internet.':
      'Public address. It can be reached from anywhere on the Internet.',
  'Dirección de prueba interna. El tráfico nunca abandona el dispositivo.':
      'Internal test address. Traffic never leaves the device.',
  'Envío simultáneo a múltiples receptores suscritos a un grupo.':
      'Simultaneous delivery to multiple receivers subscribed to a group.',
  'Asignada automáticamente (APIPA) cuando no hay servidor DHCP disponible.':
      'Automatically assigned (APIPA) when no DHCP server is available.',
  'Reservada solo para ejemplos y documentación técnica. No usar en producción.':
      'Reserved only for examples and technical documentation. Do not use in production.',
  'Usada por proveedores de Internet en redes CGN/LSN (Carrier-Grade NAT).':
      'Used by Internet providers in CGN/LSN networks (Carrier-Grade NAT).',
  'Reservada para pruebas de rendimiento de red (RFC 2544).':
      'Reserved for network benchmarking tests (RFC 2544).',
  'Envía a todos los dispositivos de la red local sin conocer la subred.':
      'Sends to all devices on the local network without knowing the subnet.',
  'Reservada para uso experimental futuro. No debe asignarse.':
      'Reserved for future experimental use. It must not be assigned.',
  'Equivalente IPv6 de las IPs privadas. Solo válida dentro de una organización.':
      'IPv6 equivalent of private IPs. Only valid within an organization.',
  'Dirección pública IPv6. Enrutable en Internet.':
      'Public IPv6 address. Routable on the Internet.',
  'Solo válida en el mismo segmento de red. No se puede rutear.':
      'Only valid on the same network segment. It cannot be routed.',
  'Envío grupal. No existe broadcast en IPv6.':
      'Group delivery. Broadcast does not exist in IPv6.',
  'Dirección interna del dispositivo. Equivale a 127.0.0.1 en IPv4.':
      'Internal device address. Equivalent to 127.0.0.1 in IPv4.',
  'Reservada para ejemplos y documentación técnica.':
      'Reserved for examples and technical documentation.',
  'Representación IPv6 de una dirección IPv4. Solo uso interno.':
      'IPv6 representation of an IPv4 address. Internal use only.',
  'Entendido': 'Got it',
  'Subnetting': 'Subnetting',
  'Calcula red, broadcast, hosts y transicion /p -> /q.':
      'Calculate network, broadcast, hosts, and /p -> /q transition.',
  'Calcula red, broadcast, hosts, transicion /p -> /q y VLSM.':
      'Calculate network, broadcast, hosts, /p -> /q transition, and VLSM.',
  'Transición de máscara': 'Mask transition',
  'VLSM por hosts': 'VLSM by hosts',
  'Address (host o red)': 'Address (host or network)',
  'Netmask (ej. 24)': 'Netmask (for example 24)',
  'move to:': 'move to:',
  'Nueva mascara': 'New mask',
  'Red base IPv4': 'IPv4 base network',
  'Red base IPv6': 'IPv6 base network',
  'Prefijo base': 'Base prefix',
  'Base': 'Base',
  'Cantidad de subredes': 'Subnet count',
  'Crear campos': 'Create fields',
  'Hosts requeridos por subred': 'Required hosts per subnet',
  'Direcciones requeridas por subred': 'Required addresses per subnet',
  'Hosts': 'Hosts',
  'Calcular VLSM': 'Calculate VLSM',
  'Ayuda': 'Help',
  'Ayuda de subnetting': 'Subnetting help',
  'Elige IPv4 o IPv6.': 'Choose IPv4 or IPv6.',
  'La mascara original': 'The original mask',
  'La mascara destino': 'The target mask',
  'La cantidad de subredes': 'The subnet count',
  'El prefijo base': 'The base prefix',
  'debe ser un número entero': 'must be an integer',
  'La cantidad de subredes debe estar entre 1 y 32.':
      'The subnet count must be between 1 and 32.',
  'Address acepta una IP de host o una direccion de red.':
      'Address accepts a host IP or a network address.',
  'Netmask es el prefijo actual, por ejemplo /24.':
      'Netmask is the current prefix, for example /24.',
  'Deja move to vacio para ver solo la red base.':
      'Leave move to empty to show only the base network.',
  'move to mayor divide en subredes; menor crea una superred.':
      'A larger move to splits into subnets; a smaller one creates a supernet.',
  'Ingresa la red base IPv4 y su prefijo.':
      'Enter the IPv4 base network and its prefix.',
  'Indica cuantas subredes necesitas y crea los campos.':
      'Enter how many subnets you need and create the fields.',
  'Escribe los hosts requeridos para cada subred.':
      'Enter the required hosts for each subnet.',
  'VLSM ordena de mayor a menor para evitar solapamientos.':
      'VLSM sorts from largest to smallest to avoid overlaps.',
  'Cada bloque se redondea a la siguiente potencia de dos.':
      'Each block is rounded up to the next power of two.',
  'Copiar base': 'Copy base',
  'Copiar todo': 'Copy all',
  'Copiar subredes': 'Copy subnets',
  'Copiar subred': 'Copy subnet',
  'Copiar plan VLSM': 'Copy VLSM plan',
  'Copiar': 'Copy',
  'copiado': 'copied',
  'Subred': 'Subnet',
  'Subredes': 'Subnets',
  'Mostrando': 'Showing',
  'de': 'of',
  'subredes creadas': 'created subnets',
  'Total de subredes creadas': 'Total created subnets',
  'Se muestra solo la primera subred para no saturar la pantalla.':
      'Only the first subnet is shown to avoid overloading the screen.',
  'Red base VLSM': 'VLSM base network',
  'Plan VLSM': 'VLSM plan',
  'Direcciones libres': 'Free addresses',
  'Direcciones pedidas': 'Requested addresses',
  'Direcciones asignadas': 'Assigned addresses',
  'Libres': 'Free',
  'Hosts pedidos': 'Requested hosts',
  'Hosts útiles': 'Usable hosts',
  'Hosts por red': 'Hosts per network',
  'Solicitud': 'Request',
  'Red base': 'Base network',
  'Rango': 'Range',
  'IPv6 no usa broadcast': 'IPv6 does not use broadcast',
  'Red=IP AND mascara; Broadcast=Red OR wildcard':
      'Network=IP AND mask; Broadcast=Network OR wildcard',
  'Sin cambio': 'No change',
  'y': 'and',
  'describen la misma red': 'describe the same network',
  'Dividir': 'Split',
  'Agregar': 'Aggregate',
  'Subredes creadas': 'Created subnets',
  'Mostrando solo la primera': 'Showing only the first',
  'Direcciones/subred': 'Addresses/subnet',
  'Salto': 'Step',
  'Hosts/subred': 'Hosts/subnet',
  'Agrupa': 'Groups',
  'redes': 'networks',
  'Superred': 'Supernet',
  'hosts pedidos': 'requested hosts',
  'direcciones pedidas': 'requested addresses',
  'Bloque': 'Block',
  'direcciones': 'addresses',
  'IPv6 no usa broadcast; para LANs normalmente se recomienda /64.':
      'IPv6 does not use broadcast; for LANs, /64 is usually recommended.',
  'Inicio': 'Start',
  'Fin': 'End',
  'End': 'End',
  'Direcciones': 'Addresses',
  'Clase': 'Class',
  'Transición IPv4 ↔ IPv6': 'IPv4 ↔ IPv6 transition',
  'IPv4-mapped (RFC 4291), incrustación RFC 6052 (NAT64/SIIT) y 6to4 (RFC 3056).':
      'IPv4-mapped (RFC 4291), RFC 6052 embedding (NAT64/SIIT), and 6to4 (RFC 3056).',
  'IPv4 → IPv6': 'IPv4 → IPv6',
  'IPv6 → IPv4': 'IPv6 → IPv4',
  'Transformar': 'Transform',
  'Revisa los datos de transición': 'Check the transition data',
  'Método': 'Method',
  'IPv4-mapped detectado': 'IPv4-mapped detected',
  'RFC 6052 / NAT64 WKP /96 detectado': 'RFC 6052 / NAT64 WKP /96 detected',
  'RFC 6052 / prefijo local 64:ff9b:1::/48 detectado':
      'RFC 6052 / local prefix 64:ff9b:1::/48 detected',
  '6to4 detectado': '6to4 detected',
  'Dirección IPv4 no válida': 'Invalid IPv4 address',
  'Dirección IPv6 no válida': 'Invalid IPv6 address',
  'La dirección IPv6 no contiene IPv4.':
      'The IPv6 address does not contain IPv4.',
  'Advertencia: la dirección parece 6to4, pero no se pudo extraer una IPv4.':
      'Warning: the address looks like 6to4, but an IPv4 address could not be extracted.',
  'Advertencia RFC 6052 §3.1: el Well-Known Prefix 64:ff9b::/96 NO debe usarse con direcciones IPv4 no globales (ej. RFC 1918). Esos paquetes deberían descartarse. Si necesitas representar una IPv4 privada, usa el prefijo local 64:ff9b:1::/48 (RFC 8215) o un Network-Specific Prefix propio.':
      'Warning RFC 6052 Section 3.1: the Well-Known Prefix 64:ff9b::/96 must NOT be used with non-global IPv4 addresses (for example RFC 1918). Those packets should be discarded. If you need to represent a private IPv4 address, use the local prefix 64:ff9b:1::/48 (RFC 8215) or your own Network-Specific Prefix.',
  'Advertencias': 'Warnings',
  'Dirección IPv4': 'IPv4 address',
  'Dirección IPv6': 'IPv6 address',
  'Se mostrarán IPv4-mapped, RFC 6052/NAT64 WKP y 6to4.':
      'IPv4-mapped, RFC 6052/NAT64 WKP, and 6to4 will be shown.',
  'Detecta automáticamente IPv4-mapped, NAT64 WKP/local y 6to4.':
      'Automatically detects IPv4-mapped, NAT64 WKP/local, and 6to4.',
  'Conectividad entre dispositivos': 'Connectivity between devices',
  'Misma red': 'Same network',
  'Ambos en la misma subred — sin router':
      'Both in the same subnet - no router',
  'Redes distintas': 'Different networks',
  'Necesitan un router en el medio': 'They need a router in between',
  'Sin camino': 'No path',
  'IPv4 vs IPv6 sin ninguna solución': 'IPv4 vs IPv6 with no solution',
  'Con traductor': 'With translator',
  'IPv4 vs IPv6 usando NAT64': 'IPv4 vs IPv6 using NAT64',
  'Dual-stack': 'Dual-stack',
  'Ambos hablan IPv4 e IPv6': 'Both speak IPv4 and IPv6',
  'Ingresa dos direcciones IP y te diremos cómo pueden comunicarse entre sí.':
      'Enter two IP addresses and we will tell you how they can communicate.',
  'Ocultar ejemplos': 'Hide examples',
  'Ver ejemplos de prueba': 'Show test examples',
  'Selecciona un caso para cargarlo automáticamente:':
      'Select a case to load it automatically:',
  'Conectividad entre dos extremos': 'Connectivity between two endpoints',
  'Distingue mismo enlace, ruteo entre subredes, dual-stack declarado y traducción/túnel declarado.':
      'Distinguishes same-link communication, subnet routing, declared dual-stack, and declared translation/tunnel.',
  'Dispositivo origen': 'Source device',
  'El que inicia la comunicación': 'The one starting communication',
  'Dispositivo destino': 'Destination device',
  'El que recibe la comunicación': 'The one receiving communication',
  'Evaluar conectividad': 'Evaluate connectivity',
  'Revisa los datos de conectividad': 'Check the connectivity data',
  'Extremo A': 'Endpoint A',
  'Extremo B': 'Endpoint B',
  'El prefijo no puede estar vacío.': 'The prefix cannot be empty.',
  'El prefijo debe ser un número entero.': 'The prefix must be an integer.',
  'Ingresa un número válido.': 'Enter a valid number.',
  'El prefijo debe estar entre 0 y': 'The prefix must be between 0 and',
  'broadcast limitado; no representa un host unicast.':
      'limited broadcast; it does not represent a unicast host.',
  'IPv4 reservada; no debe asumirse ruteable.':
      'reserved IPv4 address; it should not be assumed routable.',
  '0.0.0.0 es no especificada; no representa un destino de comunicación normal.':
      '0.0.0.0 is unspecified; it does not represent a normal communication destination.',
  'dirección loopback; solo es válida dentro del propio equipo.':
      'loopback address; it is only valid inside the same device.',
  'IPv4 privada; puede rutearse internamente, pero no directamente en Internet.':
      'private IPv4 address; it can be routed internally, but not directly on the Internet.',
  'IPv4 link-local/APIPA; solo aplica al enlace local.':
      'IPv4 link-local/APIPA; it only applies to the local link.',
  'IPv4 de documentación; útil para ejemplos, no para conectividad real.':
      'documentation IPv4 address; useful for examples, not real connectivity.',
  'IPv4 multicast; no representa un host unicast normal.':
      'IPv4 multicast; it does not represent a normal unicast host.',
  ':: es no especificada; no representa un destino de comunicación normal.':
      ':: is unspecified; it does not represent a normal communication destination.',
  'IPv6 link-local; requiere mismo enlace y normalmente zona/interfaz.':
      'IPv6 link-local; it requires the same link and usually a zone/interface.',
  'ULA; puede rutearse internamente, pero no directamente en Internet.':
      'ULA; it can be routed internally, but not directly on the Internet.',
  'IPv6 multicast; no representa un host unicast normal.':
      'IPv6 multicast; it does not represent a normal unicast host.',
  'IPv6 de documentación; útil para ejemplos, no para conectividad real.':
      'documentation IPv6 address; useful for examples, not real connectivity.',
  'Resultado del análisis': 'Analysis result',
  'Comunicación directa': 'Direct communication',
  'Necesita router': 'Needs router',
  'Necesita traductor': 'Needs translator',
  'Sin camino posible': 'No possible path',
  'Ocultar detalles técnicos': 'Hide technical details',
  'Ver detalles técnicos': 'Show technical details',
  'Prefijo (tamaño de red)': 'Prefix (network size)',
  'Aumentar': 'Increase',
  'Reducir': 'Decrease',
  'Prefijo máximo': 'Maximum prefix',
  'Prefijo mínimo': 'Minimum prefix',
  'Capacidades': 'Capabilities',
  '¿Cuándo marcar?': 'When to check?',
  'IPv4 + IPv6 simultáneo': 'IPv4 + IPv6 simultaneously',
  'Dual-stack declarado': 'Declared dual-stack',
  'Traducción/túnel declarado': 'Declared translation/tunnel',
  '¿Cuándo marcar cada opción?': 'When should each option be checked?',
  'Márcalo si el dispositivo tiene configuradas AMBAS versiones de IP al mismo tiempo.':
      'Check it if the device has BOTH IP versions configured at the same time.',
  'Una PC o laptop moderna con IPv4 e IPv6 activos':
      'A modern PC or laptop with IPv4 and IPv6 enabled',
  'Un servidor o router reciente con doble configuración':
      'A recent server or router with dual configuration',
  'No lo marques si el dispositivo solo usa IPv4 o solo IPv6.':
      'Do not check it if the device only uses IPv4 or only IPv6.',
  'Con traductor (NAT64 / SIIT / DS-Lite / MAP)':
      'With translator (NAT64 / SIIT / DS-Lite / MAP)',
  'Márcalo si en tu red hay un equipo especial que convierte tráfico de IPv4 a IPv6 o viceversa.':
      'Check it if your network has a special device that converts IPv4 traffic to IPv6 or vice versa.',
  'Una red empresarial o universitaria con gateway NAT64':
      'A business or university network with a NAT64 gateway',
  'Un proveedor de internet con DS-Lite': 'An internet provider with DS-Lite',
  'No lo marques si es una red doméstica normal. Es poco común.':
      'Do not check it for a normal home network. It is uncommon.',
  'Márcalo cuando sea:': 'Check it when it is:',
  'Mismo enlace IPv4': 'Same IPv4 link',
  'Mismo enlace IPv6': 'Same IPv6 link',
  'Requiere ruteo IPv4': 'Requires IPv4 routing',
  'Requiere ruteo IPv6': 'Requires IPv6 routing',
  'Posible por dual-stack declarado': 'Possible through declared dual-stack',
  'Posible mediante traducción/túnel declarado':
      'Possible through declared translation/tunnel',
  'Sin camino directo declarado': 'No declared direct path',
  'Los dos dispositivos están en la misma red. Se comunican directamente sin necesitar ningún router ni intermediario.':
      'Both devices are on the same network. They communicate directly without needing a router or intermediary.',
  'Los dispositivos están en redes diferentes pero usan el mismo tipo de IP. Necesitan un router que lleve los datos de una red a la otra.':
      'The devices are on different networks but use the same IP family. They need a router to carry traffic from one network to the other.',
  'Uno usa IPv4 y el otro IPv6, pero ambos soportan los dos tipos a la vez. Pueden comunicarse usando la versión que tengan en común.':
      'One uses IPv4 and the other IPv6, but both support both types at the same time. They can communicate using the family they have in common.',
  'Uno usa IPv4 y el otro IPv6. Pueden comunicarse, pero necesitan un dispositivo que traduzca entre los dos tipos de IP.':
      'One uses IPv4 and the other IPv6. They can communicate, but they need a device that translates between the two IP families.',
  'No hay forma de que se comuniquen. Uno usa IPv4 y el otro IPv6, y no hay ningún traductor ni dispositivo que soporte los dos tipos al mismo tiempo.':
      'They cannot communicate directly. One uses IPv4 and the other IPv6, and there is no translator or device supporting both families at the same time.',
  'Ambos extremos declaran pila dual. La conectividad debería usar una familia común disponible, idealmente IPv6, pero esta pantalla no verifica direcciones ni rutas adicionales de esa segunda pila.':
      'Both endpoints declare dual-stack. Connectivity should use an available common family, ideally IPv6, but this screen does not verify extra addresses or routes for that second stack.',
  'Alguno de los extremos declara un mecanismo de traducción o túnel. La conectividad puede existir si ese mecanismo está correctamente desplegado y tiene rutas de ida y vuelta.':
      'One of the endpoints declares a translation or tunneling mechanism. Connectivity can exist if that mechanism is correctly deployed and has return routes.',
  'Si el caso es NAT64 con Well-Known Prefix 64:ff9b::/96, verifica que la IPv4 involucrada sea global (RFC 6052 §3.1).':
      'If the case is NAT64 with Well-Known Prefix 64:ff9b::/96, verify that the involved IPv4 address is global (RFC 6052 Section 3.1).',
  'Las direcciones son de familias distintas (IPv4 vs IPv6) y ninguno de los extremos declara dual-stack ni un mecanismo de traducción/túnel disponible.':
      'The addresses are from different families (IPv4 vs IPv6), and neither endpoint declares dual-stack or an available translation/tunnel mechanism.',
  'Opciones: habilitar dual-stack o desplegar un mecanismo de traducción/túnel adecuado al escenario.':
      'Options: enable dual-stack or deploy a translation/tunnel mechanism suitable for the scenario.',
  'Ambas direcciones pertenecen a la misma red indicada. ARP puede resolver la dirección de capa 2 sin salto de router, asumiendo que comparten el mismo dominio de enlace.':
      'Both addresses belong to the indicated network. ARP can resolve the layer-2 address without a router hop, assuming they share the same link domain.',
  'Las direcciones están en redes distintas. Se requiere un router con ruta hacia cada prefijo y de vuelta. Esta pantalla no verifica la tabla de rutas real.':
      'The addresses are on different networks. A router with a route to each prefix and back is required. This screen does not verify the real routing table.',
  'Ambas direcciones comparten el prefijo de enlace. Neighbor Discovery (RFC 4861) puede resolver la dirección de capa 2 sin pasar por un router, asumiendo que comparten el mismo enlace.':
      'Both addresses share the link prefix. Neighbor Discovery (RFC 4861) can resolve the layer-2 address without going through a router, assuming they share the same link.',
  'Las direcciones están en prefijos de enlace distintos. Se requiere un router con ruta hacia cada prefijo.':
      'The addresses are on different link prefixes. A router with a route to each prefix is required.',
  'Referencia normativa': 'Standards reference',
  'RFC que sustentan los cálculos y reglas de validación de este sistema.':
      'RFCs that support this system calculations and validation rules.',
  'Tema': 'Topic',
  'Por qué importa': 'Why it matters',
  'Base histórica de la dirección IPv4 y clases A/B/C.':
      'Historical basis for IPv4 addressing and A/B/C classes.',
  'Prefijos, notación classless, longest match, agregación de rutas.':
      'Prefixes, classless notation, longest match, and route aggregation.',
  'IPv4 privado': 'Private IPv4',
  'Rangos 10/8, 172.16/12, 192.168/16 y por qué filtrarlos.':
      '10/8, 172.16/12, and 192.168/16 ranges, and why they should be filtered.',
  '/31 en IPv4': '/31 in IPv4',
  'Permite usar ambas direcciones de un /31 en enlaces punto a punto.':
      'Allows both addresses in a /31 to be used on point-to-point links.',
  'Documentación IPv4': 'IPv4 documentation',
  '192.0.2.0/24, 198.51.100.0/24, 203.0.113.0/24 para ejemplos.':
      '192.0.2.0/24, 198.51.100.0/24, and 203.0.113.0/24 for examples.',
  'Arquitectura IPv6': 'IPv6 architecture',
  'Tipos de dirección, texto, prefijos, IPv4-mapped, sin broadcast.':
      'Address types, text, prefixes, IPv4-mapped addresses, and no broadcast.',
  'Texto canónico IPv6': 'Canonical IPv6 text',
  'Minúsculas, "::" óptimo, sin ceros a la izquierda.':
      'Lowercase, optimal "::", and no leading zeroes.',
  'fc00::/7, equivalente funcional a "privado" en IPv6.':
      'fc00::/7, functional equivalent to "private" in IPv6.',
  'Documentación IPv6': 'IPv6 documentation',
  '2001:db8::/32 reservado para ejemplos.':
      '2001:db8::/32 reserved for examples.',
  'Frontera de 64 bits': '64-bit boundary',
  'Por qué /64 es la unidad operativa estándar de un enlace.':
      'Why /64 is the standard operational unit for a link.',
  'Asignación de sitio': 'Site assignment',
  'Ya no recomienda /48 único; depende de uso y crecimiento.':
      'No longer recommends a single /48; it depends on usage and growth.',
  'Resolución de vecinos y descubrimiento de routers en IPv6.':
      'Neighbor resolution and router discovery in IPv6.',
  'Autoconfiguración sin estado y Duplicate Address Detection.':
      'Stateless autoconfiguration and Duplicate Address Detection.',
  'Direcciones, parámetros y delegación de prefijos.':
      'Addresses, parameters, and prefix delegation.',
  'Especificación IPv6': 'IPv6 specification',
  'MTU mínimo de enlace de 1280 octetos.': 'Minimum link MTU of 1280 octets.',
  'PMTUD en IPv6': 'PMTUD in IPv6',
  'Depende de ICMPv6 Packet Too Big; no filtrar indiscriminadamente.':
      'Depends on ICMPv6 Packet Too Big; do not filter it indiscriminately.',
  'IPv4 embebida en IPv6': 'IPv4 embedded in IPv6',
  'Algoritmo de incrustación/extracción, PL∈{32,40,48,56,64,96}.':
      'Embedding/extraction algorithm, PL in {32,40,48,56,64,96}.',
  'Traducción stateless de cabeceras IPv4/IPv6.':
      'Stateless translation of IPv4/IPv6 headers.',
  'Traducción stateful para clientes IPv6-only hacia IPv4.':
      'Stateful translation for IPv6-only clients toward IPv4.',
  'Síntesis de registros AAAA a partir de registros A.':
      'Synthesis of AAAA records from A records.',
  '64:ff9b:1::/48 para uso interno, sin restricción del WKP.':
      '64:ff9b:1::/48 for internal use, without WKP restrictions.',
  'Túnel automático legado vía prefijo 2002::/16.':
      'Legacy automatic tunnel through prefix 2002::/16.',
  '6to4 anycast': '6to4 anycast',
  'Desaconseja el despliegue anycast de 6to4.':
      'Discourages 6to4 anycast deployment.',
  'IPv4 sobre acceso IPv6 mediante túnel hacia un AFTR + NAT44.':
      'IPv4 over IPv6 access through a tunnel to an AFTR + NAT44.',
  'Mapeo de direcciones y puertos con encapsulación.':
      'Address and port mapping with encapsulation.',
  'Mapeo de direcciones y puertos con traducción (menor overhead).':
      'Address and port mapping with translation (lower overhead).',
};
