// lib/src/screens/main_screen.dart
import 'package:flutter/material.dart';

// Importa las pantallas que se mostrarán en la barra de navegación
import '../features/gallery/screens/gallery_screen.dart';
import '../features/instructor/screens/instructor_screen.dart';
// Importa otras pantallas si las tienes (ej. perfil, ajustes)

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0; // Índice de la pestaña seleccionada (inicia en Galería)

  // Lista de las pantallas/widgets principales que se mostrarán
  static const List<Widget> _widgetOptions = <Widget>[
    GalleryScreen(),    // Índice 0
    InstructorScreen(), // Índice 1
    PlaceholderScreen(title: 'Añadir (+)'), // Índice 2 (Placeholder)
    PlaceholderScreen(title: 'Perfil (Pronto)'), // Índice 3 (Placeholder)
    PlaceholderScreen(title: 'Ajustes (Pronto)'), // Índice 4 (Placeholder)
  ];

  void _onItemTapped(int index) {
    // El índice 2 (central) podría tener una acción especial
    if (index == 2) {
       // Por ahora no hace nada, podría abrir cámara, añadir video, etc.
       // _showAddOptions(context); // Ejemplo: mostrar opciones para añadir
    } else {
       setState(() {
         _selectedIndex = index;
       });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // El AppBar se definirá dentro de cada pantalla (_widgetOptions[selectedIndex])
      // appBar: AppBar(title: Text('App Name')), // Quitamos AppBar global

      // Muestra la pantalla seleccionada
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),

      // --- Barra de Navegación Inferior ---
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.video_library_outlined),
            activeIcon: Icon(Icons.video_library), // Icono cuando está activa
            label: 'Galería',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.lightbulb_outline),
             activeIcon: Icon(Icons.lightbulb),
            label: 'Instructor',
          ),
           BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline, size: 35), // Icono central más grande
            label: 'Añadir', // Label puede ser opcional aquí
          ),
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
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).colorScheme.primary, // Color del ítem activo
        unselectedItemColor: Colors.grey[600], // Color de ítems inactivos
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed, // Mantiene todos los ítems visibles
        showUnselectedLabels: true, // Muestra labels de ítems inactivos
        selectedFontSize: 12, // Tamaño de fuente del label activo
        unselectedFontSize: 12, // Tamaño de fuente del label inactivo
        // backgroundColor: Theme.of(context).colorScheme.surfaceVariant, // Color de fondo (opcional)
      ),
    );
  }
}


// --- Widget Placeholder Simple ---
// Para las secciones aún no implementadas
class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    // Puedes quitar el AppBar si prefieres que la pantalla principal no tenga
    return Scaffold(
       appBar: AppBar(
         title: Text(title),
         automaticallyImplyLeading: false, // Oculta botón de volver
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