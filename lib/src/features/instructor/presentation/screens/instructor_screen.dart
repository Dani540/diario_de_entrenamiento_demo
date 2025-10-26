// lib/src/features/instructor/screens/instructor_screen.dart
import 'package:diario_de_entrenamiento_demo/src/core/di/injection_container.dart';
import 'package:flutter/material.dart';

import '../../../video_management/data/repositories/video_repository_impl.dart';
import '../../instructor_service.dart';

class InstructorScreen extends StatefulWidget {
  const InstructorScreen({super.key});

  @override
  State<InstructorScreen> createState() => _InstructorScreenState();
}

class _InstructorScreenState extends State<InstructorScreen> {
  late final VideoRepositoryImpl _videoRepository;
  late final RuleBasedInstructor _instructor;
  List<String> _suggestions = [];
  bool _isLoadingSuggestions = true;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    _videoRepository = sl<VideoRepositoryImpl>();
    _instructor = RuleBasedInstructor(_videoRepository);
    await _generateSuggestions();
  }

  Future<void> _generateSuggestions() async {
    if (!mounted) return;

    setState(() { _isLoadingSuggestions = true; });

    try {
      final List<String> newSuggestions = await _instructor.getSuggestions(count: 5);

      if (mounted) {
        setState(() {
          _suggestions = newSuggestions;
          _isLoadingSuggestions = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() { _isLoadingSuggestions = false; });
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
        automaticallyImplyLeading: false,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Basado en tus videos y configuración, aquí tienes algunas ideas:',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _isLoadingSuggestions
                  ? const Center(child: CircularProgressIndicator())
                  : _suggestions.isEmpty
                      ? Center(
                          child: Text(
                            'No hay sugerencias por ahora.\n¡Añade videos y tags!',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _generateSuggestions,
                          child: ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount: _suggestions.length,
                            itemBuilder: (context, index) {
                              final suggestion = _suggestions[index];
                              bool isCombo = suggestion.contains('->');
                              IconData iconData = isCombo 
                                  ? Icons.link_rounded 
                                  : Icons.directions_run_rounded;

                              return Card(
                                elevation: 2,
                                margin: const EdgeInsets.symmetric(vertical: 6.0),
                                color: Theme.of(context)
                                    .colorScheme
                                    .surfaceVariant
                                    .withOpacity(0.8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: ListTile(
                                  leading: Icon(
                                    iconData,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                  title: Text(suggestion),
                                ),
                              );
                            },
                          ),
                        ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Nuevas Sugerencias'),
              onPressed: _isLoadingSuggestions ? null : _generateSuggestions,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}