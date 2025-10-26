// lib/src/screens/main_screen.dart
import 'package:flutter/material.dart';

// Importa las pantallas principales
import '../features/video_management/presentation/screens/gallery_screen.dart';
import '../features/instructor/presentation/screens/instructor_screen.dart';
// Importa futuras pantallas aquí (Perfil, Ajustes)
// import '../features/profile/screens/profile_screen.dart'; // Ejemplo
import '../features/settings/screens/settings_screen.dart'; // Necesitamos SettingsScreen ahora

// Widget Placeholder Simple para secciones no implementadas
class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
       appBar: AppBar(
         title: Text(title),
         automaticallyImplyLeading: false,
         centerTitle: true,
       ),
       body: Center(
        child: Text(
          '$title - Próximamente...',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}


// --- Pantalla Principal con Navegación ---
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0; // Índice inicial: Galería
  final PageController _pageController = PageController(); // Controlador para PageView

  // Lista de las pantallas/widgets principales
  // Quitamos el placeholder central de "Añadir"
  static final List<Widget> _widgetOptions = <Widget>[
    const GalleryScreen(),    // Índice 0
    const InstructorScreen(), // Índice 1
    const PlaceholderScreen(title: 'Perfil'), // Índice 2 (Pronto)
    const SettingsScreen(), // Índice 3 - Añadimos la pantalla de Ajustes real
  ];

  // Callback cuando se toca un ítem de la barra inferior
  void _onItemTapped(int index) {
     // Anima el PageView para ir a la página correspondiente
     _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
     );
     // No necesitamos setState aquí porque onPageChanged lo hará
  }

  // Callback cuando el PageView cambia de página (por deslizamiento)
  void _onPageChanged(int index) {
     setState(() {
       _selectedIndex = index;
     });
  }

  @override
  void dispose() {
    _pageController.dispose(); // Libera el controlador
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // El AppBar se define en cada pantalla individual ahora

      // PageView para permitir el deslizamiento entre pantallas
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged, // Actualiza el índice al deslizar
        children: _widgetOptions, // Las pantallas
        // physics: const NeverScrollableScrollPhysics(), // Descomenta si quieres deshabilitar el swipe
      ),

      // Barra de Navegación Inferior (sin el botón central)
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.video_library_outlined),
            activeIcon: Icon(Icons.video_library),
            label: 'Galería',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.lightbulb_outline),
            activeIcon: Icon(Icons.lightbulb),
            label: 'Instructor',
          ),
          // Quitamos el ítem central de "Añadir"
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Ajustes',
          ),
        ],
        currentIndex: _selectedIndex, // Marca el ítem activo
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey[600],
        onTap: _onItemTapped, // Llama a esta función al tocar un ítem
        type: BottomNavigationBarType.fixed, // Mantiene todos visibles
        showUnselectedLabels: true,
        selectedFontSize: 12,
        unselectedFontSize: 12,
      ),
    );
  }
}