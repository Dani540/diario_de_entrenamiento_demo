// lib/src/features/instructor/screens/instructor_screen.dart
import 'package:flutter/material.dart';
// Quitamos import de Hive y VideoEntry, ahora la lógica está en el servicio
// import 'package:hive_flutter/hive_flutter.dart';
// import '../../video_data/models/video_entry.dart';
import '../instructor_service.dart'; // Importa el servicio del instructor
import 'dart:io'; // Necesario para Platform
// Quitamos SharedPreferences si ya no se lee directamente aquí
// import 'package:shared_preferences/shared_preferences.dart';

// Define las claves de SharedPreferences aquí o en un archivo central
// const String keepArchivedTagsPrefKey = 'keep_archived_tags'; // Se usa en el service

class InstructorScreen extends StatefulWidget {
  const InstructorScreen({super.key});

  @override
  State<InstructorScreen> createState() => _InstructorScreenState();
}

class _InstructorScreenState extends State<InstructorScreen> {
  final RuleBasedInstructor _instructor = RuleBasedInstructor();
  List<String> _suggestions = []; // Lista para guardar las sugerencias
  bool _isLoadingSuggestions = true; // Estado para mostrar carga inicial/refresco

  @override
  void initState() {
    super.initState();
    _generateSuggestions(); // Llama a la función async al iniciar
  }

  // Ahora es async y maneja el estado de carga correctamente
  Future<void> _generateSuggestions() async {
    // Si ya está cargando, no hacer nada (evita múltiples llamadas)
    // Usamos '!_isLoadingSuggestions' para iniciar la carga si NO está cargando
    if (!_isLoadingSuggestions && mounted) {
       setState(() { _isLoadingSuggestions = true; }); // Muestra loader solo si no estaba cargando
    } else if (!mounted) {
       return; // Si no está montado, salir
    }
    // Si ya estaba cargando (initState), _isLoadingSuggestions ya es true

    try {
      // Llama al servicio del instructor y ESPERA (await) el resultado
      // El servicio ahora es async porque lee SharedPreferences
      final List<String> newSuggestions = await _instructor.getSuggestions(count: 5);

      // Verifica si el widget sigue montado antes de actualizar el estado
      if (mounted) {
        setState(() {
          _suggestions = newSuggestions; // Asigna el resultado esperado (List<String>)
          _isLoadingSuggestions = false; // Oculta loader
        });
      }
    } catch (e) {
      // Manejo de errores
      if (mounted) {
        setState(() { _isLoadingSuggestions = false; }); // Oculta loader en caso de error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al obtener sugerencias: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Instructor'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
         automaticallyImplyLeading: false, // Oculta botón 'atrás' (está en PageView)
         centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Título o Introducción
            Text(
              'Basado en tus videos y configuración, aquí tienes algunas ideas:',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // --- Lista de Sugerencias o Indicador de Carga ---
            Expanded(
              child: _isLoadingSuggestions
                  ? const Center(child: CircularProgressIndicator()) // Muestra loader
                  : _suggestions.isEmpty
                      ? Center( // Mensaje si no hay sugerencias
                          child: Text(
                             'No hay sugerencias por ahora.\n¡Añade videos y tags!',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey[600]),
                          ),
                        )
                      : RefreshIndicator( // Permite refrescar deslizando hacia abajo
                          onRefresh: _generateSuggestions, // Llama a la función async al refrescar
                          child: ListView.builder(
                            // Añade physics para asegurar scroll incluso con pocos items en RefreshIndicator
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount: _suggestions.length,
                            itemBuilder: (context, index) {
                              final suggestion = _suggestions[index];
                              // Determina icono basado en si es combo
                              bool isCombo = suggestion.contains('->');
                              IconData iconData = isCombo ? Icons.link_rounded : Icons.directions_run_rounded;

                              // Cada sugerencia en una Card
                              return Card(
                                elevation: 2,
                                margin: const EdgeInsets.symmetric(vertical: 6.0),
                                color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                child: ListTile(
                                  leading: Icon(iconData, color: Theme.of(context).colorScheme.primary),
                                  title: Text(suggestion),
                                  // onTap: () { /* Acción futura? Ej: Marcar como objetivo */ },
                                ),
                              );
                            },
                          ),
                        ),
            ),
            // ------------------------------------------------

            const SizedBox(height: 16),

            // Botón para refrescar sugerencias
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Nuevas Sugerencias'),
              // Deshabilita el botón si ya está cargando sugerencias
              onPressed: _isLoadingSuggestions ? null : _generateSuggestions,
              style: ElevatedButton.styleFrom(
                 padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            const SizedBox(height: 16), // Espacio al final
          ],
        ),
      ),
    );
  }
}