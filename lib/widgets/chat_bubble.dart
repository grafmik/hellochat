import 'package:flutter/material.dart';
import '../models.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAvatar(),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.username,
                  style: TextStyle(
                    color: message.color,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                Text(
                  message.text,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    if (message.avatarBytes != null) {
      return CircleAvatar(radius: 16, backgroundImage: MemoryImage(message.avatarBytes!));
    }
    if (message.avatarIndex != null) {
      return GridAvatar(index: message.avatarIndex!);
    }
    return CircleAvatar(
      radius: 16,
      backgroundColor: message.color.withValues(alpha: 0.25),
      child: Text(
        message.username[0].toUpperCase(),
        style: TextStyle(
          color: message.color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// Affiche une cellule de la grille avatar_grid.png (16×16 cellules de 128px)
class GridAvatar extends StatelessWidget {
  final int index; // 0–255
  static const double size = 32;

  const GridAvatar({super.key, required this.index});

  @override
  Widget build(BuildContext context) {
    final row = index ~/ 16;
    final col = index % 16;
    final totalSize = size * 16;

    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: OverflowBox(
          maxWidth: totalSize,
          maxHeight: totalSize,
          alignment: Alignment.topLeft,
          child: Transform.translate(
            offset: Offset(-col * size, -row * size),
            child: Image.asset(
              'assets/avatar_grid.png',
              width: totalSize,
              height: totalSize,
              filterQuality: FilterQuality.medium,
            ),
          ),
        ),
      ),
    );
  }
}
