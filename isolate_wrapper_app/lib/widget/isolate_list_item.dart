import 'package:flutter/material.dart';
import 'package:isolate_wrapper/isolate_wrapper.dart';

class IsolateListItem extends StatelessWidget {
  final IsolateInfo item;

  IsolateListItem(this.item);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(item.label),
      subtitle: getSubTitle(context),

    );
  }


  Widget getSubTitle(BuildContext context){

    if(item.isComplete){
      return Text("complete");
    } else {
      return LinearProgressIndicator(value: item.progress.toDouble()/100);

    }

  }
}
