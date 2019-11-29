import 'package:flutter/material.dart';

Widget helperStreamBuild(
    BuildContext context,
    List<Stream> streams,
    List<dynamic> initialDatum,
    List<AsyncSnapshot> snapshots,
    int index,
    Function build) {
  return StreamBuilder(
      stream: streams[index],
      initialData: initialDatum[index],
      builder: (buildContext, snapshot) {
        snapshots.add(snapshot);
        return index > 1
            ? helperStreamBuild(buildContext, streams, initialDatum, snapshots,
                index - 1, build)
            : build(buildContext, snapshots.reversed.toList());
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
        streams.length, builder);
  }
}
