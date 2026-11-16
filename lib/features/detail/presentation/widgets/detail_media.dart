import 'package:animal/core/theme/app_colors.dart';
import 'package:animal/core/theme/app_spacing.dart';
import 'package:animal/data/models/anime.dart';
import 'package:animal/data/models/anime_detail.dart';
import 'package:animal/shared/widgets/app_cached_image.dart';
import 'package:animal/shared/widgets/full_screen_gallery.dart';
import 'package:animal/shared/widgets/section_card.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

const _videoWidth = 208.0;
const _videoHeight = 117.0;
const _pictureWidth = 112.0;
const _pictureHeight = 160.0;

/// The promotional videos MAL lists for an anime (trailers, PVs). A tap opens
/// the video in the app that handles its link.
class VideosCard extends StatelessWidget {
  const VideosCard({required this.videos, super.key});

  final List<AnimeVideo> videos;

  /// Only web links are opened: the address comes from a third party.
  static bool _isPlayable(AnimeVideo video) {
    final scheme = Uri.tryParse(video.url)?.scheme;
    return scheme == 'https' || scheme == 'http';
  }

  static bool hasContent(List<AnimeVideo> videos) => videos.any(_isPlayable);

  @override
  Widget build(BuildContext context) {
    final items = videos.where(_isPlayable).toList(growable: false);

    return SectionCard(
      title: 'Videos',
      trailing: '${items.length}',
      child: SizedBox(
        height: _videoHeight,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: items.length,
          separatorBuilder: (context, index) =>
              const SizedBox(width: AppSpacing.md),
          itemBuilder: (context, index) => _VideoTile(video: items[index]),
        ),
      ),
    );
  }
}

class _VideoTile extends StatelessWidget {
  const _VideoTile({required this.video});

  final AnimeVideo video;

  Future<void> _open(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final uri = Uri.tryParse(video.url);
    var opened = false;
    try {
      opened =
          uri != null &&
          await launchUrl(uri, mode: LaunchMode.externalApplication);
    } on Exception catch (_) {
      opened = false;
    }
    if (opened) return;
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Could not open the video'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = video.title;
    final thumbnail = video.thumbnail;

    return Semantics(
      button: true,
      label: 'Play ${title ?? 'video'}',
      excludeSemantics: true,
      onTap: () => _open(context),
      child: SizedBox(
        width: _videoWidth,
        height: _videoHeight,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.cover),
          child: Stack(
            fit: StackFit.expand,
            children: [
              AppCachedImage(
                imageUrl: thumbnail ?? '',
                fallbackSize: 28,
                memCacheWidth: decodeWidthFor(context, _videoWidth),
              ),
              const Center(
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.overlayDarker,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.play_arrow_rounded,
                      color: AppColors.iconLight,
                    ),
                  ),
                ),
              ),
              if (title != null && title.isNotEmpty)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: ColoredBox(
                    color: AppColors.overlayDarker,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.xs,
                      ),
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppColors.iconLight,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              Positioned.fill(
                child: Material(
                  type: MaterialType.transparency,
                  child: InkWell(onTap: () => _open(context)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The extra pictures MAL lists for an anime. A tap opens them full screen,
/// starting from the one tapped.
class GalleryCard extends StatelessWidget {
  const GalleryCard({required this.pictures, super.key});

  final List<MainPicture> pictures;

  static bool _hasImage(MainPicture picture) =>
      (picture.medium ?? picture.large) != null;

  static bool hasContent(List<MainPicture> pictures) => pictures.any(_hasImage);

  @override
  Widget build(BuildContext context) {
    final items = pictures.where(_hasImage).toList(growable: false);
    final full = [for (final p in items) (p.large ?? p.medium)!];

    return SectionCard(
      title: 'Gallery',
      trailing: '${items.length}',
      child: SizedBox(
        height: _pictureHeight,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: items.length,
          separatorBuilder: (context, index) =>
              const SizedBox(width: AppSpacing.md),
          itemBuilder: (context, index) => Semantics(
            button: true,
            label: 'Open picture ${index + 1} of ${items.length}',
            excludeSemantics: true,
            onTap: () => FullScreenGalleryViewer.show(
              context,
              imageUrls: full,
              initialIndex: index,
            ),
            child: SizedBox(
              width: _pictureWidth,
              height: _pictureHeight,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    AppCachedImage(
                      imageUrl: (items[index].medium ?? items[index].large)!,
                      fallbackSize: 24,
                      memCacheWidth: decodeWidthFor(context, _pictureWidth),
                    ),
                    Positioned.fill(
                      child: Material(
                        type: MaterialType.transparency,
                        child: InkWell(
                          onTap: () => FullScreenGalleryViewer.show(
                            context,
                            imageUrls: full,
                            initialIndex: index,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
