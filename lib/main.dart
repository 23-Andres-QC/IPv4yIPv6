import 'package:flutter/material.dart';
import 'screens/calculator_screen.dart';
import 'screens/mask_transition_screen.dart';
import 'screens/ipv4_to_ipv6_screen.dart';
import 'screens/connectivity_screen.dart';
import 'screens/reference_screen.dart';

void main() {
  runApp(const IpToolkitApp());
}

class IpToolkitApp extends StatelessWidget {
  const IpToolkitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IPv4 ↔ IPv6 Toolkit',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const HomeShell(),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int index = 0;

  static const _destinations = [
    NavigationRailDestination(icon: Icon(Icons.calculate_outlined), selectedIcon: Icon(Icons.calculate), label: Text('Calculadora')),
    NavigationRailDestination(icon: Icon(Icons.call_split_outlined), selectedIcon: Icon(Icons.call_split), label: Text('Subnetting')),
    NavigationRailDestination(icon: Icon(Icons.sync_alt_outlined), selectedIcon: Icon(Icons.sync_alt), label: Text('Transición v4↔v6')),
    NavigationRailDestination(icon: Icon(Icons.lan_outlined), selectedIcon: Icon(Icons.lan), label: Text('Conectividad')),
    NavigationRailDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book), label: Text('Referencia RFC')),
  ];

  static const _screens = [
    CalculatorScreen(),
    MaskTransitionScreen(),
    Ipv4ToIpv6Screen(),
    ConnectivityScreen(),
    ReferenceScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: index,
            onDestinationSelected: (i) => setState(() => index = i),
            labelType: NavigationRailLabelType.all,
            leading: const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Icon(Icons.hub, size: 32),
            ),
            destinations: _destinations,
          ),
          const VerticalDivider(width: 1),
          Expanded(child: _screens[index]),
        ],
      ),
    );
  }
}
