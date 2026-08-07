import 'package:flutter/material.dart';

/// Sits under news art, so a slow or broken image still reads as a card rather
/// than a blank rectangle.
const newsFallbackGradient = <Color>[Color(0xFF1E3A8A), Color(0xFF172554)];

/// The photo of a news entry, filling whatever box it is given. A missing or
/// dead URL just falls through to [newsFallbackGradient].
class NewsImage extends StatelessWidget {
  final String? url;

  const NewsImage({super.key, this.url});

  @override
  Widget build(BuildContext context) {
    final hasUrl = url != null && url!.isNotEmpty;

    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: newsFallbackGradient,
            ),
          ),
        ),
        if (hasUrl)
          Image.network(
            url!,
            fit: BoxFit.cover,
            loadingBuilder: (_, child, progress) => progress == null
                ? child
                : const Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white70),
                      ),
                    ),
                  ),
            errorBuilder: (_, _, _) => const SizedBox.shrink(),
          ),
      ],
    );
  }
}
