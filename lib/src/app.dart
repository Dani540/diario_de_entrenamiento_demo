import 'package:flutter/material.dart';
import 'features/gallery/screens/gallery_screen.dart'; // Importa la pantalla de galería

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Diario de Entrenamiento',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const GalleryScreen(), // La pantalla inicial es la galería
      debugShowCheckedModeBanner: false, // Opcional: quita el banner de debug
    );
  }
}
