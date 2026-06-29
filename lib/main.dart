import 'package:flutter/material.dart';
import 'app_localization.dart';
import 'screens/calculator_screen.dart';
import 'screens/mask_transition_screen.dart';
import 'screens/ipv4_to_ipv6_screen.dart';
import 'screens/connectivity_screen.dart';
import 'screens/reference_screen.dart';

void main() {
  runApp(const IpToolkitApp());
}

class IpToolkitApp extends StatefulWidget {
  const IpToolkitApp({super.key});

  @override
  State<IpToolkitApp> createState() => _IpToolkitAppState();
}

class _IpToolkitAppState extends State<IpToolkitApp> {
  ThemeMode _themeMode = ThemeMode.light;
  AppLanguage _language = AppLanguage.es;

  void _setThemeMode(ThemeMode mode) {
    setState(() => _themeMode = mode);
  }

  void _setLanguage(AppLanguage language) {
    setState(() => _language = language);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IPv4 ↔ IPv6 Toolkit',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: _themeMode,
      home: HomeShell(
        language: _language,
        themeMode: _themeMode,
        onLanguageChanged: _setLanguage,
        onThemeModeChanged: _setThemeMode,
      ),
    );
  }
}

class HomeShell extends StatefulWidget {
  final AppLanguage language;
  final ThemeMode themeMode;
  final ValueChanged<AppLanguage> onLanguageChanged;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  const HomeShell({
    super.key,
    required this.language,
    required this.themeMode,
    required this.onLanguageChanged,
    required this.onThemeModeChanged,
  });

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int index = 0;

  static const _screens = [
    CalculatorScreen(),
    MaskTransitionScreen(),
    Ipv4ToIpv6Screen(),
    ConnectivityScreen(),
    ReferenceScreen(),
  ];

  bool get _isEnglish => widget.language == AppLanguage.en;

  List<String> get _destinationLabels {
    if (_isEnglish) {
      return const [
        'Calculator',
        'Subnetting',
        'v4↔v6 transition',
        'Connectivity',
        'RFC reference',
      ];
    }
    return const [
      'Calculadora',
      'Subnetting',
      'Transición v4↔v6',
      'Conectividad',
      'Referencia RFC',
    ];
  }

  List<NavigationRailDestination> get _destinations {
    final labels = _destinationLabels;
    return [
      NavigationRailDestination(
        icon: const Icon(Icons.calculate_outlined),
        selectedIcon: const Icon(Icons.calculate),
        label: Text(labels[0]),
      ),
      NavigationRailDestination(
        icon: const Icon(Icons.call_split_outlined),
        selectedIcon: const Icon(Icons.call_split),
        label: Text(labels[1]),
      ),
      NavigationRailDestination(
        icon: const Icon(Icons.sync_alt_outlined),
        selectedIcon: const Icon(Icons.sync_alt),
        label: Text(labels[2]),
      ),
      NavigationRailDestination(
        icon: const Icon(Icons.lan_outlined),
        selectedIcon: const Icon(Icons.lan),
        label: Text(labels[3]),
      ),
      NavigationRailDestination(
        icon: const Icon(Icons.menu_book_outlined),
        selectedIcon: const Icon(Icons.menu_book),
        label: Text(labels[4]),
      ),
    ];
  }

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
              child: Image(
                image: AssetImage('assets/icon/logo.png'),
                width: 40,
                height: 40,
              ),
            ),
            destinations: _destinations,
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: Column(
              children: [
                AppLocalization(
                  language: widget.language,
                  child: _TopPreferencesBar(
                    language: widget.language,
                    themeMode: widget.themeMode,
                    onLanguageChanged: widget.onLanguageChanged,
                    onThemeModeChanged: widget.onThemeModeChanged,
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: AppLocalization(
                    language: widget.language,
                    child: _screens[index],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TopPreferencesBar extends StatelessWidget {
  final AppLanguage language;
  final ThemeMode themeMode;
  final ValueChanged<AppLanguage> onLanguageChanged;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  const _TopPreferencesBar({
    required this.language,
    required this.themeMode,
    required this.onLanguageChanged,
    required this.onThemeModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = themeMode == ThemeMode.dark;
    return Material(
      color: theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Text(
                context.t('Herramienta IPv4 ↔ IPv6'),
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 12),
            SegmentedButton<AppLanguage>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: AppLanguage.es, label: Text('ES')),
                ButtonSegment(value: AppLanguage.en, label: Text('EN')),
              ],
              selected: {language},
              onSelectionChanged: (selection) {
                onLanguageChanged(selection.first);
              },
            ),
            const SizedBox(width: 12),
            Tooltip(
              message: context.t('Tema de color'),
              child: SegmentedButton<ThemeMode>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(
                    value: ThemeMode.light,
                    icon: const Icon(Icons.light_mode_outlined, size: 18),
                    label: Text(context.t('Claro')),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    icon: const Icon(Icons.dark_mode_outlined, size: 18),
                    label: Text(context.t('Oscuro')),
                  ),
                ],
                selected: {isDark ? ThemeMode.dark : ThemeMode.light},
                onSelectionChanged: (selection) {
                  onThemeModeChanged(selection.first);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
