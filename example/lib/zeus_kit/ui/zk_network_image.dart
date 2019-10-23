import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ZKNetworkImage extends StatelessWidget {
  final String imageUrl;
  final double width;
  final double height;
  final BoxFit fit;
  final BorderRadius borderRadius;
  final String placeholderImagePath;
  final String errorImagePath;

  ZKNetworkImage({
    @required this.imageUrl,
    this.width,
    this.height,
    this.fit: BoxFit.cover,
    this.borderRadius,
    this.placeholderImagePath: "",
    this.errorImagePath: "",
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return ClipRRect(
        borderRadius: borderRadius,
        child: placeholderImagePath.isEmpty
            ? Container(
                width: width,
                height: height,
              )
            : Image.asset(
                placeholderImagePath,
                width: width,
                height: height,
                fit: BoxFit.cover,
              ),
      );
    }

    return Container(
      child: ClipRRect(
        borderRadius: borderRadius,
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          width: width,
          height: height,
          fit: fit,
          placeholder: (context, url) {
            if (placeholderImagePath.isEmpty) {
              return Container(
                width: width,
                height: height,
                color: const Color(0xFFE8E8E8),
                alignment: Alignment.center,
                child: CupertinoActivityIndicator(),
              );
            } else {
              return Image.asset(
                placeholderImagePath,
                width: width,
                height: height,
                fit: BoxFit.cover,
              );
            }
          },
          errorWidget: (context, url, error) {
            if (errorImagePath.isEmpty) {
              return Icon(Icons.error);
            } else {
              return Image.asset(
                errorImagePath,
                width: width,
                height: height,
                fit: BoxFit.cover,
              );
            }
          },
        ),
      ),
    );
  }
}

class ZKCircleAvatar extends StatelessWidget {
  final String avatarUrl;
  final double size;
  final String defaultAvatar;

  ZKCircleAvatar({
    Key key,
    @required this.avatarUrl,
    @required this.size,
    @required this.defaultAvatar,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (avatarUrl == null || avatarUrl.isEmpty) {
      return ClipOval(
        child: Image.asset(
          defaultAvatar,
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      );
    }

    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: avatarUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (context, url) {
          return CupertinoActivityIndicator();
        },
        errorWidget: (context, url, error) {
          return Image.asset(
            defaultAvatar,
            width: size,
            height: size,
            fit: BoxFit.cover,
          );
        },
      ),
    );
  }
}
