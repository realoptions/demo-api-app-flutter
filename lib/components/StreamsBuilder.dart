import 'package:flutter/material.dart';

Widget helperStreamBuild(
    BuildContext context,
    List<Stream> streams,
    List<dynamic> initialDatum,
    List<AsyncSnapshot> snapshots,
    int index,
    int maxLength,
    Function build) {
  return StreamBuilder(
      stream: streams[index],
      initialData: initialDatum[index],
      builder: (buildContext, snapshot) {
        snapshots.add(snapshot);
        return index < maxLength
            ? helperStreamBuild(buildContext, streams, initialDatum, snapshots,
                index + 1, maxLength, build)
            : build(buildContext, snapshots.toList());
      });
}

class StreamsBuilder extends StatelessWidget {
  StreamsBuilder(
      {Key key,
      @required this.streams,
      @required this.builder,
      @required this.initialData});
  final Function builder;
  final List<Stream> streams;
  final List<dynamic> initialData;
  @override
  Widget build(BuildContext context) {
    return helperStreamBuild(context, streams, initialData, <AsyncSnapshot>[],
        0, streams.length - 1, builder);
  }
}
