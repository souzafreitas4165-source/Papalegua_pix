import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class CachedImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;
  final Color? color;
  final BlendMode? colorBlendMode;
  final BoxShape shape;

  const CachedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
    this.color,
    this.colorBlendMode,
    this.shape = BoxShape.rectangle,
  });

  @override
  Widget build(BuildContext context) {
    final image = CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      color: color,
      colorBlendMode: colorBlendMode,
      placeholder: (context, url) =>
          placeholder ??
          const Center(child: CircularProgressIndicator()),
      errorWidget: (context, url, error) =>
          errorWidget ?? const Icon(Icons.error),
      fadeInDuration: const Duration(milliseconds: 200),
      fadeOutDuration: const Duration(milliseconds: 100),
      memCacheWidth: width?.toInt(),
      memCacheHeight: height?.toInt(),
    );

    if (borderRadius != null || shape != BoxShape.rectangle) {
      return ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.zero,
        clipBehavior: Clip.antiAlias,
        child: image,
      );
    }

    return image;
  }

  // Construtor para imagens circulares
  factory CachedImage.circle({
    Key? key,
    required String imageUrl,
    required double size,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
    Widget? errorWidget,
    Color? color,
    BlendMode? colorBlendMode,
  }) {
    return CachedImage(
      key: key,
      imageUrl: imageUrl,
      width: size,
      height: size,
      fit: fit,
      placeholder: placeholder,
      errorWidget: errorWidget,
      color: color,
      colorBlendMode: colorBlendMode,
      shape: BoxShape.circle,
    );
  }

  // Construtor para imagens com cantos arredondados
  factory CachedImage.rounded({
    Key? key,
    required String imageUrl,
    double? width,
    double? height,
    double radius = 8.0,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
    Widget? errorWidget,
    Color? color,
    BlendMode? colorBlendMode,
  }) {
    return CachedImage(
      key: key,
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      placeholder: placeholder,
      errorWidget: errorWidget,
      color: color,
      colorBlendMode: colorBlendMode,
      borderRadius: BorderRadius.circular(radius),
    );
  }
}
