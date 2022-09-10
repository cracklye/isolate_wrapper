import 'package:isolate_wrapper/isolate_wrapper.dart';

class IsolateBlocEvent {}

class IsolateBlocEventStart extends IsolateBlocEvent {
  int startNo;
  IsolateBlocEventStart(this.startNo);
}

class IsolateBlocEventStop extends IsolateBlocEvent {
  String isolateId;
  IsolateBlocEventStop(this.isolateId);
}
class IsolateBlocEventUpdateList extends IsolateBlocEvent {
  List<IsolateInfo> list;
  IsolateBlocEventUpdateList(this.list);
}