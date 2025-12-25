import 'package:flutter/material.dart';

class MyText extends StatelessWidget {
  final String text;
  final Color color;
  const MyText({
    super.key,
    required this.text,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(fontFamily: 'Boogaloo', fontSize: 12, color: color),
    );
  }
}
