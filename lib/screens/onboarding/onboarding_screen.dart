import 'package:flutter/material.dart';
import 'package:nekoflow/data/boxes/user_box.dart';
import 'package:nekoflow/routes/app_router.dart';
import 'package:nekoflow/screens/onboarding/loading_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final TextEditingController _nameController = TextEditingController();
  int _currentPage = 0;
  String name = '';
  late UserBox _userBox;
  bool _isLoading = true;

  final List<Map<String, dynamic>> onboardingData = [
    {
      "title": "Bienvenido a MangaVerse",
      "description": "Disfruta del mejor contenido anime en un solo lugar",
      "image": "assets/images/onboarding/home_screen.png",
      "features": [
        "Gran catálogo de anime",
        "Contenido en HD",
        "Actualizaciones semanales"
      ],
    },
    {
      "title": "Calendario de Emisión",
      "description": "Mantente al día con los últimos estrenos",
      "image": "assets/images/onboarding/calendar_screen.png",
      "features": [
        "Calendario de emisión",
        "Notificaciones personalizadas",
        "Próximos estrenos"
      ],
    },
    {
      "title": "Gestiona tus Favoritos",
      "description": "Organiza y sigue tus series preferidas",
      "image": "assets/images/onboarding/favorites_screen.png",
      "features": [
        "Lista de favoritos",
        "Marcadores personalizados",
        "Recomendaciones inteligentes"
      ],
    },
    {
      "title": "Historial y Progreso",
      "description": "Retoma tus series desde donde las dejaste",
      "image": "assets/images/onboarding/history_screen.png",
      "features": [
        "Seguimiento de episodios",
        "Historial detallado",
        "Estadísticas de visualización"
      ],
    },
  ];

  @override
  void initState() {
    super.initState();
    _initializeBoxAndCheckStatus();
  }

  Future<void> _initializeBoxAndCheckStatus() async {
    try {
      _userBox = UserBox();
      await _userBox.init();

      final user = _userBox.getUser();

      if (user.name != null && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => AppRouter(name: user.name ?? ''),
          ),
        );
      } else {
        setState(() {
          _isLoading = false;
          if (user.name != null) {
            name = user.name!;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        _showError('Error al inicializar. Por favor, reinicia la app.');
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _completeOnboarding() async {
    if (name.trim().isEmpty) return;

    setState(() => _isLoading = true);

    try {
      await _userBox.updateUser(name: name.trim());
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => AppRouter(name: name.trim()),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        _showError('Error al guardar. Intenta de nuevo.');
      }
    }
  }

  void _nextPage() {
    if (_currentPage < onboardingData.length) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const LoadingScreen();
    }

    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              onPageChanged: (index) => setState(() => _currentPage = index),
              itemCount: onboardingData.length + 1,
              itemBuilder: (context, index) {
                if (index < onboardingData.length) {
                  return _buildOnboardingPage(index, theme);
                }
                return _buildProfilePage(theme);
              },
            ),
            _buildSkipButton(theme),
          ],
        ),
      ),
      bottomNavigationBar: _buildNavigationBar(theme),
    );
  }

  Widget _buildSkipButton(ThemeData theme) {
    if (_currentPage >= onboardingData.length - 1) return const SizedBox.shrink();

    return Positioned(
      top: 16,
      right: 16,
      child: TextButton(
        onPressed: () {
          _pageController.animateToPage(
            onboardingData.length,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
        style: TextButton.styleFrom(
          foregroundColor: theme.colorScheme.primary,
        ),
        child: const Text("Saltar"),
      ),
    );
  }

  Widget _buildOnboardingPage(int index, ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
              onboardingData[index]['image'],
              height: MediaQuery.of(context).size.height * 0.5,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            onboardingData[index]['title'],
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            onboardingData[index]['description'],
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.textTheme.bodyLarge?.color?.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          _buildFeaturesList(onboardingData[index]['features'], theme),
        ],
      ),
    );
  }

  Widget _buildFeaturesList(List<String> features, ThemeData theme) {
    return Column(
      children: features.map((feature) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Icon(
                Icons.check_circle_outline,
                color: theme.colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  feature,
                  style: theme.textTheme.bodyLarge,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildProfilePage(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_outline,
            size: 64,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 32),
          Text(
            "¿Cómo te llamas?",
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Personaliza tu experiencia",
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.textTheme.bodyLarge?.color?.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _nameController,
            onChanged: (value) => setState(() => name = value),
            style: theme.textTheme.bodyLarge,
            decoration: InputDecoration(
              hintText: 'Tu nombre',
              prefixIcon: const Icon(Icons.person_outline),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationBar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: theme.dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              onboardingData.length + 1,
                  (index) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                height: 8,
                width: _currentPage == index ? 24 : 8,
                decoration: BoxDecoration(
                  color: _currentPage == index
                      ? theme.colorScheme.primary
                      : theme.colorScheme.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: (name.trim().isNotEmpty ||
                _currentPage < onboardingData.length)
                ? _nextPage
                : null,
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              _currentPage < onboardingData.length ? "Continuar" : "Comenzar",
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }
}