// lib/src/features/instructor/screens/instructor_screen.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

// Importaciones locales
import '../../video_data/models/video_entry.dart';
import '../instructor_service.dart'; // Importa el servicio

class InstructorScreen extends StatefulWidget {
  const InstructorScreen({super.key});

  @override
  State<InstructorScreen> createState() => _InstructorScreenState();
}

class _InstructorScreenState extends State<InstructorScreen> {
  final RuleBasedInstructor _instructor = RuleBasedInstructor();
  List<String> _suggestions = []; // Lista para guardar las sugerencias

  @override
  void initState() {
    super.initState();
    // Generamos las sugerencias cuando la pantalla se carga por primera vez
    _generateSuggestions();
  }

  void _generateSuggestions() {
    final videoBox = Hive.box<VideoEntry>('videoEntriesBox');
    final videoEntries = videoBox.values.toList();
    final Set<String> allUserTags = {};
    for (var entry in videoEntries) {
      allUserTags.addAll(entry.tags);
    }
    setState(() { // Actualizamos el estado con las nuevas sugerencias
      _suggestions = _instructor.getSuggestions(allUserTags.toList(), count: 5); // Pedimos 5 sugerencias
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Instructor'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch, // Estira los hijos horizontalmente
          children: [
            // Título o Introducción
            Text(
              'Basado en tus videos, aquí tienes algunas ideas para practicar:',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Lista de Sugerencias
            Expanded( // Ocupa el espacio restante
              child: _suggestions.isEmpty
                  ? const Center(child: Text('No hay sugerencias por ahora. ¡Sigue añadiendo videos!'))
                  : ListView.builder(
                      itemCount: _suggestions.length,
                      itemBuilder: (context, index) {
                        final suggestion = _suggestions[index];
                        // Determinar si es un combo o movimiento simple por el "->"
                        bool isCombo = suggestion.contains('->');
                        IconData iconData = isCombo ? Icons.link : Icons.directions_run; // Iconos diferentes

                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.symmetric(vertical: 6.0),
                           color: Theme.of(context).colorScheme.surfaceVariant,
                          child: ListTile(
                            leading: Icon(iconData, color: Theme.of(context).colorScheme.primary),
                            title: Text(suggestion),
                            // Podrías añadir un botón aquí para "Marcar como intentado" o "Ver tutorial" en el futuro
                            // trailing: IconButton(
                            //   icon: Icon(Icons.check_circle_outline),
                            //   onPressed: () { /* Marcar completado? */ },
                            // ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 16),

            // Botón para refrescar sugerencias
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Generar Nuevas Sugerencias'),
              onPressed: _generateSuggestions, // Llama a la función para recalcular
              style: ElevatedButton.styleFrom(
                 padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
             const SizedBox(height: 16),
            // Podrías añadir un botón aquí para "Empezar a Grabar"
            // ElevatedButton.icon(
            //   icon: const Icon(Icons.videocam_outlined),
            //   label: const Text('Empezar a Grabar'),
            //   onPressed: () { /* Navegar a pantalla de grabación? */ },
            //   style: ElevatedButton.styleFrom(
            //      backgroundColor: Theme.of(context).colorScheme.secondary,
            //      foregroundColor: Theme.of(context).colorScheme.onSecondary,
            //      padding: const EdgeInsets.symmetric(vertical: 12),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}