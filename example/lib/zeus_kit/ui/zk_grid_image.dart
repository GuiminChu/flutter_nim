import 'package:flutter/material.dart';
import 'zk_network_image.dart';

typedef ZKImagesGridViewTaper = Function(int index);

class ZKImagesGridView extends StatelessWidget {
  final String title;
  final TextStyle titleStyle;
  final List<String> imageUrls;
  final int crossAxisCount;
  final EdgeInsets margin;

  final ZKImagesGridViewTaper taper;

  ZKImagesGridView({
    Key key,
    this.title,
    this.titleStyle = const TextStyle(
      color: const Color(0xFF666666),
      fontSize: 14.0,
    ),
    this.imageUrls,
    this.crossAxisCount = 3,
    this.margin: EdgeInsets.zero,
    this.taper,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      margin: margin,
      child: Column(
        children: <Widget>[
          Offstage(
            offstage: title == null,
            child: Container(
              height: 40.0,
              alignment: Alignment.centerLeft,
              child: Text(
                title ?? "",
                style: titleStyle,
              ),
            ),
          ),
          Offstage(
            offstage: (imageUrls?.length ?? 0) == 0,
            child: GridView.builder(
              primary: false,
              shrinkWrap: true,
              itemCount: imageUrls?.length ?? 0,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: 10.0,
                crossAxisSpacing: 10.0,
              ),
              itemBuilder: (context, index) {
                return _buildImageCell(index, imageUrls[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageCell(int index, String imageUrl) {
    return GestureDetector(
      onTap: () {
        if (taper != null) {
          taper(index);
        }
      },
      child: ZKNetworkImage(
        imageUrl: imageUrl,
        width: double.infinity,
        height: double.infinity,
        borderRadius: BorderRadius.circular(5.0),
      ),
    );
  }
}
