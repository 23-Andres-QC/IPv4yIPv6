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
  'Dirección inválida': 'Invalid address',
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
  'Direcciones totales': 'Total addresses',
  'Hosts utilizables': 'Usable hosts',
  'Representación binaria': 'Binary representation',
  'Bits de red (prefijo)': 'Network bits (prefix)',
  'Bits de host': 'Host bits',
  'Bits de máscara': 'Mask bits',
  'Rango de subred': 'Subnet range',
  'Copiar valor': 'Copy value',
  'Ver cada bit de la dirección — para estudiantes y profesionales':
      'View each address bit - for students and professionals',
  'Red Pública': 'Public network',
  'Red Privada': 'Private network',
  'Esta dirección es accesible desde Internet.':
      'This address is reachable from the Internet.',
  'Esta dirección pertenece a una red local. No es accesible desde Internet.':
      'This address belongs to a local network. It is not reachable from the Internet.',
  'Esta dirección IPv6 es accesible desde Internet.':
      'This IPv6 address is reachable from the Internet.',
  'Esta dirección IPv6 pertenece a una red local (ULA). No es accesible desde Internet.':
      'This IPv6 address belongs to a local network (ULA). It is not reachable from the Internet.',
  'Entendido': 'Got it',
  'Subnetting': 'Subnetting',
  'Calcula red, broadcast, hosts y transicion /p -> /q.':
      'Calculate network, broadcast, hosts, and /p -> /q transition.',
  'Address (host o red)': 'Address (host or network)',
  'Netmask (ej. 24)': 'Netmask (for example 24)',
  'move to:': 'move to:',
  'Nueva mascara': 'New mask',
  'Ayuda': 'Help',
  'Ayuda de subnetting': 'Subnetting help',
  'Elige IPv4 o IPv6.': 'Choose IPv4 or IPv6.',
  'Address acepta una IP de host o una direccion de red.':
      'Address accepts a host IP or a network address.',
  'Netmask es el prefijo actual, por ejemplo /24.':
      'Netmask is the current prefix, for example /24.',
  'Deja move to vacio para ver solo la red base.':
      'Leave move to empty to show only the base network.',
  'move to mayor divide en subredes; menor crea una superred.':
      'A larger move to splits into subnets; a smaller one creates a supernet.',
  'Copiar base': 'Copy base',
  'Copiar todo': 'Copy all',
  'Copiar subredes': 'Copy subnets',
  'Copiar': 'Copy',
  'copiado': 'copied',
  'Subred': 'Subnet',
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
  'Referencia normativa': 'Standards reference',
  'RFC que sustentan los cálculos y reglas de validación de este sistema.':
      'RFCs that support this system calculations and validation rules.',
  'Tema': 'Topic',
  'Por qué importa': 'Why it matters',
};
