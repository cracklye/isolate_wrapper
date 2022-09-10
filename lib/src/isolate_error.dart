


import 'package:isolate_wrapper/src/isolate_message.dart';

class IsolateError extends IsolateMessage {
  final String message;
  final Object? exception;
  IsolateError(this.message, [this.exception]);
}

