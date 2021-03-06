import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:math';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:realoptions/models/response.dart';

charts.Color convertColor(Color color) {
  return charts.Color(
      r: color.red, g: color.green, b: color.blue, a: color.alpha);
}

const int NUM_TICKS = 5;
const double PADDING_PERCENTAGE = 0.15;
List<charts.TickSpec<num>> getAxis(num firstPoint, num lastPoint) {
  List<charts.TickSpec<num>> domain = [];
  double dx = (lastPoint - firstPoint) / (NUM_TICKS - 1);
  for (int i = 0; i < NUM_TICKS; ++i) {
    domain.add(charts.TickSpec<num>(firstPoint + dx * i));
  }
  return domain;
}

charts.StaticNumericTickProviderSpec getDomain(List<ModelResult> modelResults) {
  var firstDomain = modelResults.first.atPoint;
  var lastDomain = modelResults.last.atPoint;
  return charts.StaticNumericTickProviderSpec(getAxis(firstDomain, lastDomain));
}

charts.StaticNumericTickProviderSpec getIVRange(
    List<ModelResult> modelResults) {
  var resultsIter = modelResults.map((val) => val.iv);
  var minIV = resultsIter.reduce(min) * (1.0 - PADDING_PERCENTAGE);
  var maxIV = resultsIter.reduce(max) * (1.0 + PADDING_PERCENTAGE);
  return charts.StaticNumericTickProviderSpec(getAxis(minIV, maxIV));
}

charts.StaticNumericTickProviderSpec getDensityRange(
    List<ModelResult> modelResults) {
  var results = modelResults;
  var minVal = 0.0;
  var maxIV =
      results.map((val) => val.value).reduce(max) * (1.0 + PADDING_PERCENTAGE);
  return charts.StaticNumericTickProviderSpec(getAxis(minVal, maxIV));
}
