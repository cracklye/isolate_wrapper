import 'package:flutter/material.dart';
import 'package:isolate_wrapper/isolate_wrapper.dart';
import 'package:isolate_wrapper_app/widget/isolate_list_item.dart';

class IsolateList extends StatelessWidget {
  final List<IsolateInfo> items;

  const IsolateList(this.items);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      // Let the ListView know how many items it needs to build.
      itemCount: items.length,
      // Provide a builder function. This is where the magic happens.
      // Convert each item into a widget based on the type of item it is.
      itemBuilder: (context, index) {
        final item = items[index];

        return IsolateListItem(item);
      },
    );
  }
}
