import 'dart:async';

import 'package:animal/core/theme/app_colors.dart';
import 'package:animal/shared/widgets/app_cached_image.dart';
import 'package:flutter/material.dart';

class FullScreenImageViewer extends StatelessWidget {
  const FullScreenImageViewer({
    required this.imageUrl,
    super.key,
    this.heroTag,
  });

  final String imageUrl;
  final String? heroTag;

  static void show(
    BuildContext context, {
    required String imageUrl,
    String? heroTag,
  }) {
    unawaited(
      Navigator.of(context).push(
        PageRouteBuilder<void>(
          opaque: false,
          barrierDismissible: true,
          barrierColor: AppColors.barrier,
          pageBuilder: (_, _, _) => FullScreenImageViewer(
            imageUrl: imageUrl,
            heroTag: heroTag,
          ),
          transitionsBuilder: (_, animation, _, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          InteractiveViewer(
            minScale: 0.5,
            maxScale: 4,
            child: Center(
              child: heroTag != null
                  ? Hero(
                      tag: heroTag!,
                      child: AppCachedImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.contain,
                        fallbackIcon: Icons.broken_image,
                        fallbackColor: AppColors.iconSubtle,
                        fallbackSize: 48,
                        loadingWidget: const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.iconLight,
                          ),
                        ),
                      ),
                    )
                  : AppCachedImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.contain,
                      fallbackIcon: Icons.broken_image,
                      fallbackColor: AppColors.iconSubtle,
                      fallbackSize: 48,
                      loadingWidget: const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.iconLight,
                        ),
                      ),
                    ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 16,
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.overlayDark,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.close, color: AppColors.iconLight),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
