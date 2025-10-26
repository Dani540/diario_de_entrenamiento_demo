// lib/src/features/gallery/widgets/add_video_grid_item.dart
import 'package:flutter/material.dart';

class AddVideoGridItem extends StatelessWidget {
  final VoidCallback onTap; // Callback para cuando se toca

  const AddVideoGridItem({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap, // Llama al callback recibido
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.0),
        child: Container(
          decoration: BoxDecoration(
            // Color ligeramente diferente o borde punteado para distinguirlo
            color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
              width: 1.5,
              // Podrías usar DottedBorder si añades el paquete `dotted_border`
              // style: BorderStyle.dashed,
            ),
            borderRadius: BorderRadius.circular(8.0)
          ),
          child: Center(
            child: Icon(
              Icons.add_circle_outline_rounded,
              size: 50,
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
        ),
      ),
    );
  }
}