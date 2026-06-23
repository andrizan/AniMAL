import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Shared cached image widget with consistent placeholder/error handling.
class AppCachedImage extends StatelessWidget {
  const AppCachedImage({
    required this.imageUrl,
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.fallbackIcon = Icons.movie,
    this.fallbackColor,
    this.fallbackSize,
    this.loadingWidget,
  });

  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final IconData fallbackIcon;
  final Color? fallbackColor;
  final double? fallbackSize;
  final Widget? loadingWidget;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveFallbackSize =
        fallbackSize ??
        (width != null && height != null
            ? (width! < height! ? width! : height!) * 0.35
            : 24);
    final fallback = ColoredBox(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          fallbackIcon,
          size: effectiveFallbackSize,
          color: fallbackColor ?? theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );

    Widget image = CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) => loadingWidget ?? fallback,
      errorWidget: (context, url, error) => fallback,
    );

    if (borderRadius != null) {
      image = ClipRRect(borderRadius: borderRadius!, child: image);
    }

    return image;
  }
}
