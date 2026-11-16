import 'dart:async';

import 'package:animal/core/theme/app_colors.dart';
import 'package:animal/core/theme/app_spacing.dart';
import 'package:animal/shared/widgets/app_cached_image.dart';
import 'package:animal/shared/widgets/scrim_icon_button.dart';
import 'package:material_ui/material_ui.dart';

/// Pictures shown one at a time on the barrier: swipe to move between them,
/// pinch to zoom. Swiping is off while a picture is zoomed so that dragging
/// pans the picture instead of turning the page.
class FullScreenGalleryViewer extends StatefulWidget {
  const FullScreenGalleryViewer({
    required this.imageUrls,
    super.key,
    this.initialIndex = 0,
  });

  final List<String> imageUrls;
  final int initialIndex;

  static void show(
    BuildContext context, {
    required List<String> imageUrls,
    int initialIndex = 0,
  }) {
    unawaited(
      Navigator.of(context).push(
        PageRouteBuilder<void>(
          opaque: false,
          barrierDismissible: true,
          barrierColor: AppColors.barrier,
          pageBuilder: (_, _, _) => FullScreenGalleryViewer(
            imageUrls: imageUrls,
            initialIndex: initialIndex,
          ),
          transitionsBuilder: (_, animation, _, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),
    );
  }

  @override
  State<FullScreenGalleryViewer> createState() =>
      _FullScreenGalleryViewerState();
}

class _FullScreenGalleryViewerState extends State<FullScreenGalleryViewer> {
  late final PageController _pages = PageController(
    initialPage: widget.initialIndex,
  );
  late int _index = widget.initialIndex;
  bool _zoomed = false;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _onZoomChanged({required bool zoomed}) {
    if (zoomed != _zoomed) setState(() => _zoomed = zoomed);
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.imageUrls.length;
    final top = MediaQuery.paddingOf(context).top + AppSpacing.sm;

    return Scaffold(
      backgroundColor: AppColors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            controller: _pages,
            physics: _zoomed ? const NeverScrollableScrollPhysics() : null,
            itemCount: total,
            onPageChanged: (index) => setState(() {
              _index = index;
              _zoomed = false;
            }),
            itemBuilder: (context, index) => _GalleryPage(
              imageUrl: widget.imageUrls[index],
              onZoomChanged: _onZoomChanged,
            ),
          ),
          Positioned(
            top: top,
            left: AppSpacing.lg,
            child: Container(
              height: 48,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.overlayDarker,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text(
                '${_index + 1} / $total',
                semanticsLabel: 'Picture ${_index + 1} of $total',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.iconLight,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          Positioned(
            top: top,
            right: AppSpacing.lg,
            child: ScrimIconButton(
              icon: Icons.close_rounded,
              tooltip: 'Close',
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _GalleryPage extends StatefulWidget {
  const _GalleryPage({required this.imageUrl, required this.onZoomChanged});

  final String imageUrl;
  final void Function({required bool zoomed}) onZoomChanged;

  @override
  State<_GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<_GalleryPage> {
  final TransformationController _transform = TransformationController();

  @override
  void initState() {
    super.initState();
    _transform.addListener(_onTransform);
  }

  @override
  void dispose() {
    _transform
      ..removeListener(_onTransform)
      ..dispose();
    super.dispose();
  }

  void _onTransform() {
    widget.onZoomChanged(zoomed: _transform.value.getMaxScaleOnAxis() > 1.01);
  }

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      transformationController: _transform,
      maxScale: 4,
      child: Center(
        child: AppCachedImage(
          imageUrl: widget.imageUrl,
          fit: BoxFit.contain,
          fallbackIcon: Icons.broken_image,
          fallbackColor: AppColors.iconSubtle,
          fallbackSize: 48,
          loadingWidget: const Center(
            child: CircularProgressIndicator(color: AppColors.iconLight),
          ),
        ),
      ),
    );
  }
}
