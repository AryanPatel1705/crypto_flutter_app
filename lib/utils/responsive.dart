import 'package:flutter/widgets.dart';

class Responsive {
  final BuildContext context;
  late double _screenWidth;
  late double _screenHeight;
  late double _blockWidth;
  late double _blockHeight;

  Responsive(this.context) {
    final size = MediaQuery.of(context).size;
    _screenWidth = size.width;
    _screenHeight = size.height;
    _blockWidth = _screenWidth / 100;
    _blockHeight = _screenHeight / 100;
  }

  double widthPercent(double percent) {
    return _blockWidth * percent;
  }

  double heightPercent(double percent) {
    return _blockHeight * percent;
  }

  double scaleFont(double fontSize) {
    // Scale font size based on screen width, with a minimum scale factor
    double scaleFactor = _screenWidth / 375; // base width for scaling
    return fontSize * scaleFactor;
  }
}
