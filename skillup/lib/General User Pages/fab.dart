import 'package:flutter/material.dart';

class CustomFabLocation extends FloatingActionButtonLocation {
  @override
  Offset getOffset(ScaffoldPrelayoutGeometry geometry) {
    final double fabWidth = geometry.floatingActionButtonSize.width;
    final double fabHeight = geometry.floatingActionButtonSize.height;

    final double scaffoldWidth = geometry.scaffoldSize.width;
    final double scaffoldHeight = geometry.scaffoldSize.height;

    final double x = scaffoldWidth - fabWidth - 16; // 16px from the right
    final double y = scaffoldHeight - fabHeight - 120; // 120px from the bottom

    return Offset(x, y);
  }
}
