import 'package:flutter/material.dart';

class RoundedImage extends StatelessWidget {
  final String url;
  final double radius;
  const RoundedImage({super.key, required this.url, this.radius=70.5});

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: SizedBox.fromSize(
        size: Size.fromRadius(radius), // Image radius
        child: Image.network(url, fit: BoxFit.cover),
      ),
    );
  }
}
