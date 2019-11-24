import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:charts_flutter/flutter.dart' as charts;
charts.Color convertColor(Color color){
  return charts.Color(
    r: color.red, g: color.green, b: color.blue, a: color.alpha
  );
}