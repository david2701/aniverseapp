import 'package:flutter/material.dart';
import 'package:nekoflow/data/boxes/settings_box.dart';
import 'package:nekoflow/data/theme/theme_manager.dart';

class ThemeScreen extends StatefulWidget {
  final String title;
  const ThemeScreen({super.key, required this.title});

  @override
  State<ThemeScreen> createState() => _ThemeScreenState();
}

class _ThemeScreenState extends State<ThemeScreen> {
  ThemeType _selectedTheme = ThemeType.dark;
  late SettingsBox _settingsBox;

  // Agregamos tabs para categorizar los temas
  final List<String> _themeTabs = ['Dark', 'Light'];
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeBox();
    _loadInitialTheme();
  }

  Future<void> _initializeBox() async {
    _settingsBox = SettingsBox();
    await _settingsBox.init();
  }

  void _loadInitialTheme() {
    final themeName = _settingsBox.getTheme();
    setState(() {
      _selectedTheme = ThemeManager.getThemeType(themeName!) ?? ThemeType.dark;
      // Inicializar el tab correcto basado en el tema
      _selectedTabIndex = _isDarkTheme(_selectedTheme) ? 0 : 1;
    });
  }

  bool _isDarkTheme(ThemeType theme) {
    return theme != ThemeType.sakuraBlossom &&
        theme != ThemeType.solarFlare &&
        theme != ThemeType.serenityLight;
  }

  List<ThemeType> _getThemesForTab(int tabIndex) {
    return ThemeType.values.where((theme) =>
    tabIndex == 0 ? _isDarkTheme(theme) : !_isDarkTheme(theme)
    ).toList();
  }

  Future<void> _updateTheme(ThemeType theme) async {
    setState(() {
      _selectedTheme = theme;
    });
    await _settingsBox.updateTheme(_selectedTheme.name);
  }

  Widget _buildThemeCard(ThemeType themeType) {
    final theme = ThemeManager.getTheme(themeType);
    final isSelected = themeType == _selectedTheme;
    final textColor = _getTextColor(theme.colorScheme.surface);

    return GestureDetector(
      onTap: () => _updateTheme(themeType),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildGradientStrip(theme),
            const SizedBox(height: 8),
            _buildColorStrip(theme.colorScheme.secondary),
            const SizedBox(height: 8),
            _buildColorStrip(theme.colorScheme.tertiary),
            const SizedBox(height: 12),
            Text(
              _formatThemeName(themeType.name),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: textColor,
              ),
              textAlign: TextAlign.center,
            ),
            if (isSelected) ...[
              const SizedBox(height: 4),
              Icon(
                Icons.check_circle,
                color: theme.colorScheme.primary,
                size: 20,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGradientStrip(ThemeData theme) {
    return Container(
      height: 8,
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.secondary,
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildColorStrip(Color color) {
    return Container(
      height: 8,
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  String _formatThemeName(String name) {
    return name
        .replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(1)}')
        .capitalize();
  }

  Color _getTextColor(Color backgroundColor) {
    return ThemeData.estimateBrightnessForColor(backgroundColor) ==
        Brightness.light
        ? Colors.black
        : Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    final themeData = ThemeManager.getTheme(_selectedTheme);

    return Theme(
      data: themeData,
      child: Scaffold(
        extendBody: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.navigate_before,
              size: 35,
            ),
          ),
          title: Hero(
            tag: ValueKey(widget.title),
            child: Text(
              "Theme",
              style: themeData.textTheme.headlineLarge?.copyWith(
                fontSize: 35,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          forceMaterialTransparency: true,
        ),
        body: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: themeData.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: _themeTabs.asMap().entries.map((entry) {
                  final isSelected = _selectedTabIndex == entry.key;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedTabIndex = entry.key),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? themeData.colorScheme.primary.withOpacity(0.1)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          entry.value,
                          style: themeData.textTheme.titleMedium?.copyWith(
                            color: isSelected
                                ? themeData.colorScheme.primary
                                : themeData.colorScheme.onSurface,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                itemCount: _getThemesForTab(_selectedTabIndex).length,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemBuilder: (context, index) {
                  return _buildThemeCard(_getThemesForTab(_selectedTabIndex)[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension StringCasingExtension on String {
  String capitalize() =>
      isNotEmpty ? '${this[0].toUpperCase()}${substring(1).toLowerCase()}' : '';
}