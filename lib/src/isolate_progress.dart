import 'package:isolate_wrapper/src/isolate_message.dart';

class IsolateProgress extends IsolateMessage {
  final String message;
  final int progress;

  IsolateProgress(this.message, [this.progress = 0]);

  
}
