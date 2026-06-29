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
      theme: _buildAppTheme(Brightness.light),
      darkTheme: _buildAppTheme(Brightness.dark),
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

ThemeData _buildAppTheme(Brightness brightness) {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: Colors.indigo,
    brightness: brightness,
  );
  return ThemeData(
    colorScheme: colorScheme,
    useMaterial3: true,
    visualDensity: VisualDensity.standard,
    scaffoldBackgroundColor: colorScheme.surfaceContainerLowest,
    cardTheme: CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colorScheme.surfaceContainerLowest,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: colorScheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
      ),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: colorScheme.surface,
      indicatorColor: colorScheme.primaryContainer,
      selectedIconTheme: IconThemeData(color: colorScheme.onPrimaryContainer),
      selectedLabelTextStyle: TextStyle(
        color: colorScheme.onSurface,
        fontWeight: FontWeight.w700,
      ),
      unselectedLabelTextStyle: TextStyle(color: colorScheme.onSurfaceVariant),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    ),
  );
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

  static const _icons = [
    Icons.calculate_outlined,
    Icons.call_split_outlined,
    Icons.sync_alt_outlined,
    Icons.lan_outlined,
    Icons.menu_book_outlined,
  ];

  static const _selectedIcons = [
    Icons.calculate,
    Icons.call_split,
    Icons.sync_alt,
    Icons.lan,
    Icons.menu_book,
  ];

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

  List<String> get _destinationDescriptions {
    if (_isEnglish) {
      return const [
        'Address, masks, ranges, and binary view',
        'Split or merge prefixes with clear subnet tables',
        'IPv4-mapped, NAT64/RFC 6052, and 6to4',
        'Check same-link, routing, dual-stack, and translation',
        'Normative RFC basis for every calculation',
      ];
    }
    return const [
      'Direcciones, máscaras, rangos y vista binaria',
      'Divide o agrega prefijos con tablas claras',
      'IPv4-mapped, NAT64/RFC 6052 y 6to4',
      'Evalúa enlace, ruteo, dual-stack y traducción',
      'Base normativa RFC de cada cálculo',
    ];
  }

  List<NavigationRailDestination> get _destinations {
    final labels = _destinationLabels;
    return List.generate(
      labels.length,
      (i) => NavigationRailDestination(
        icon: Icon(_icons[i]),
        selectedIcon: Icon(_selectedIcons[i]),
        label: Text(labels[i]),
      ),
    );
  }

  List<NavigationDestination> get _bottomDestinations {
    final labels = _destinationLabels;
    return List.generate(
      labels.length,
      (i) => NavigationDestination(
        icon: Icon(_icons[i]),
        selectedIcon: Icon(_selectedIcons[i]),
        label: labels[i],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final labels = _destinationLabels;
    final descriptions = _destinationDescriptions;
    final languageScope = AppLocalization(
      language: widget.language,
      child: _screens[index],
    );

    return Scaffold(
      body: AppLocalization(
        language: widget.language,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 760;
            final content = Column(
              children: [
                _TopPreferencesBar(
                  title: labels[index],
                  subtitle: descriptions[index],
                  icon: _selectedIcons[index],
                  language: widget.language,
                  themeMode: widget.themeMode,
                  onLanguageChanged: widget.onLanguageChanged,
                  onThemeModeChanged: widget.onThemeModeChanged,
                ),
                Expanded(
                  child: Container(
                    color: Theme.of(context).colorScheme.surfaceContainerLowest,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: KeyedSubtree(
                        key: ValueKey(index),
                        child: languageScope,
                      ),
                    ),
                  ),
                ),
              ],
            );

            if (compact) {
              return Column(
                children: [
                  Expanded(child: content),
                  NavigationBar(
                    selectedIndex: index,
                    onDestinationSelected: (i) => setState(() => index = i),
                    destinations: _bottomDestinations,
                  ),
                ],
              );
            }

            return Row(
              children: [
                _AppNavigationRail(
                  selectedIndex: index,
                  extended: constraints.maxWidth >= 1180,
                  destinations: _destinations,
                  onDestinationSelected: (i) => setState(() => index = i),
                ),
                VerticalDivider(
                  width: 1,
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
                Expanded(child: content),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _AppNavigationRail extends StatelessWidget {
  final int selectedIndex;
  final bool extended;
  final List<NavigationRailDestination> destinations;
  final ValueChanged<int> onDestinationSelected;

  const _AppNavigationRail({
    required this.selectedIndex,
    required this.extended,
    required this.destinations,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return NavigationRail(
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      extended: extended,
      minExtendedWidth: 220,
      labelType: extended
          ? NavigationRailLabelType.none
          : NavigationRailLabelType.all,
      leading: Padding(
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 24),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 44,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Image(image: AssetImage('assets/icon/logo.png')),
            ),
            if (extended) ...[
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  context.t('Herramienta IPv4 ↔ IPv6'),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ],
        ),
      ),
      destinations: destinations,
    );
  }
}

class _TopPreferencesBar extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final AppLanguage language;
  final ThemeMode themeMode;
  final ValueChanged<AppLanguage> onLanguageChanged;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  const _TopPreferencesBar({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.language,
    required this.themeMode,
    required this.onLanguageChanged,
    required this.onThemeModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = themeMode == ThemeMode.dark;
    return Material(
      color: colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Wrap(
          spacing: 12,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 380,
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: colorScheme.onPrimaryContainer),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          subtitle,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 132),
              child: SegmentedButton<AppLanguage>(
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
            ),
            Tooltip(
              message: context.t('Tema de color'),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 230),
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
            ),
          ],
        ),
      ),
    );
  }
}
