import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:math';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:demo_api_app_flutter/models/response.dart' as response_model;
charts.Color convertColor(Color color){
  return charts.Color(
    r: color.red, g: color.green, b: color.blue, a: color.alpha
  );
}
const int NUM_TICKS=5;
charts.StaticNumericTickProviderSpec getAxis(
  num firstPoint, num lastPoint
){
  List<charts.TickSpec<num>> domain=[];
  double dx=(lastPoint-firstPoint)/(NUM_TICKS-1);
  for(int i=0; i<NUM_TICKS; ++i){
    domain.add(charts.TickSpec<num>(firstPoint+dx*i));
  }
  return charts.StaticNumericTickProviderSpec(domain);
}
charts.StaticNumericTickProviderSpec getDomain(response_model.ModelResults modelResults){
  var results=modelResults.results;
  var firstDomain=results.first.atPoint;
  var lastDomain=results.last.atPoint;
  return getAxis(firstDomain, lastDomain);
}
charts.StaticNumericTickProviderSpec getIVRange(response_model.ModelResults modelResults){
  var resultsIter=modelResults.results.map((val)=>val.iv);
  var minIV=resultsIter.reduce(min)*0.85;
  var maxIV=resultsIter.reduce(max)*1.15;
  return getAxis(minIV, maxIV);
}

charts.StaticNumericTickProviderSpec getDensityRange(response_model.ModelResults modelResults){
  var results=modelResults.results;
  var minVal=0.0;
  var maxIV=results.map((val)=>val.value).reduce(max)*1.15;
  return getAxis(minVal, maxIV);
}