import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:material_ui/material_ui.dart';

/// The pixel width to decode an image that is drawn [logicalWidth] wide, for
/// the screen the widget is on: 168 for 84 on a 2x screen, 252 on a 3x one.
int decodeWidthFor(BuildContext context, double logicalWidth) =>
    (logicalWidth * MediaQuery.devicePixelRatioOf(context)).round();

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
    this.memCacheWidth,
    this.memCacheHeight,
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
  final int? memCacheWidth;
  final int? memCacheHeight;

  @visibleForTesting
  static ImageProvider Function(String url)? debugImageProvider;

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

    final debugProvider = debugImageProvider;
    Widget image = debugProvider != null
        ? Image(
            image: debugProvider(imageUrl),
            width: width,
            height: height,
            fit: fit,
            errorBuilder: (context, error, stackTrace) => fallback,
          )
        : CachedNetworkImage(
            imageUrl: imageUrl,
            width: width,
            height: height,
            fit: fit,
            memCacheWidth: memCacheWidth,
            memCacheHeight: memCacheHeight,
            placeholder: (context, url) => loadingWidget ?? fallback,
            errorWidget: (context, url, error) => fallback,
          );

    if (borderRadius != null) {
      image = ClipRRect(borderRadius: borderRadius!, child: image);
    }

    return image;
  }
}
