import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Loads an advertisement poster with a loading placeholder and an
/// icon fallback when the URL is missing or the image fails to load.
class PosterImage extends StatelessWidget {
  const PosterImage({
    super.key,
    this.url,
    this.width,
    this.height,
    this.borderRadius = BorderRadius.zero,
  });

  final String? url;
  final double? width;
  final double? height;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    final trimmed = url?.trim() ?? '';
    final fallback = _FallbackIcon(width: width, height: height);
    if (trimmed.isEmpty) {
      return ClipRRect(borderRadius: borderRadius, child: fallback);
    }
    return ClipRRect(
      borderRadius: borderRadius,
      child: CachedNetworkImage(
        imageUrl: trimmed,
        width: width,
        height: height,
        fit: BoxFit.cover,
        placeholder: (context, url) => fallback,
        errorWidget: (context, url, error) => fallback,
      ),
    );
  }
}

class _FallbackIcon extends StatelessWidget {
  const _FallbackIcon({this.width, this.height});

  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: width,
      height: height,
      color: scheme.surfaceContainerHighest,
      child: Icon(
        Icons.image_outlined,
        color: scheme.onSurfaceVariant,
        size: 28,
      ),
    );
  }
}
