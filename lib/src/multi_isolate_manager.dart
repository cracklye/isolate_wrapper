import 'dart:async';
import 'dart:isolate';

import 'package:flutter/widgets.dart';
import 'package:isolate_wrapper/isolate_wrapper.dart';

class MultiIsolateManager {
  List<IsolateWrapper> isolates = [];
  Map<String, IsolateInfo> infos = {};

  StreamController<List<IsolateInfo>> controller =
      StreamController<List<IsolateInfo>>();

  Stream<List<IsolateInfo>> getUpdateStream() {
    return controller.stream;
  }

  Future<String> run<T>(Function(SendPort) processFunction,
      {Function(IsolateProgress)? handleProgress,
      String? description,
      Function(T)? handleResult,
      Function(IsolateError)? handleError,
      Function()? handleComplete,
      Map<String, Object> parameters = const {}}) async {
    // isolates.add(isolate);
    String id = UniqueKey().toString();

    IsolateWrapper isolate = IsolateWrapper(
      processFunction,
      description: description,
      customId: id,
      handleError: (err) {
        _doHandleError(id, err);
        if (handleError != null) {
          handleError(err);
        }
      },
      handleProgress: (progress) {
        _doHandleProgress(id, progress);
        if (handleProgress != null) {
          handleProgress(progress);
        }
      },
      handleResult: (progress) {
        _doHandleResult<T>(id, progress);
        if (handleResult != null) {
          handleResult(progress);
        }
      },
      handleComplete: () {
        _doHandleComplete<T>(id);
        if (handleComplete != null) {
          handleComplete();
        }
      },
    );
    isolates.add(isolate);

    isolate.run(parameters);

    return id;
  }

  Future<T> runForResult<T>(Function(SendPort) processFunction,
      {String? description,
      Function(IsolateProgress)? handleProgress,
      Map<String, Object> parameters = const {}}) async {
    String id = UniqueKey().toString();

    IsolateWrapper isolate = IsolateWrapper(
      customId: id,
      processFunction,
      description: description,
      handleProgress: (progress) {
        _doHandleProgress(id, progress);
        if (handleProgress != null) {
          handleProgress(progress);
        }
      },
    );

    return await isolate.runForResult(parameters: parameters);
  }

  void _doHandleError(String isolateId, IsolateError error) {
    print("error: $isolateId - $error");
    IsolateInfo? info = _getIsolateInfo(isolateId);
    if (info == null) return;

    _replaceInfo(
        isolateId,
        info.copyWith(
            log: "Exception Returned ${error.message}", isError: true));
  }

  void _doHandleProgress(String isolateId, IsolateProgress progress) {
    print("progress: $isolateId - ${progress.message}");
    IsolateInfo? info = _getIsolateInfo(isolateId);
    if (info == null) return;

    _replaceInfo(
        isolateId,
        info.copyWith(
            progressMessage: progress.message, progress: progress.progress));
  }

  void _doHandleResult<T>(String isolateId, T result) {
    print("result: $isolateId - $result");
    IsolateInfo? info = _getIsolateInfo(isolateId);
    if (info == null) return;
    _replaceInfo(isolateId, info.copyWith(log: "Result Returned $result"));
  }

  void _doHandleComplete<T>(String isolateId) {
    print("complete: $isolateId");
    IsolateInfo? info = _getIsolateInfo(isolateId);
    if (info == null) return;

    _replaceInfo(isolateId, info.copyWith(isComplete: true));
  }

  void _replaceInfo(String id, IsolateInfo info) {
    infos.update(id, (value) => info, ifAbsent: () => info);
    _refreshStream();
  }

  IsolateWrapper? _getIsolateWrapper(String id) {
    try {
      IsolateWrapper i = isolates.firstWhere((element) => element.id == id);
      return i;
    } catch (e) {}
    return null;
  }

  IsolateInfo? _getIsolateInfo(String id) {
    if (infos.containsKey(id)) {
      return infos[id]!;
    }
    //Otherwise....
    try {
      IsolateWrapper? i = _getIsolateWrapper(id);
      if (i == null) return null;

      var info = IsolateInfo(id, description: i.description);
      infos.putIfAbsent(id, () => info);
      return info;
    } catch (e) {}
    return null;
  }

  void remove(String id) {
    _refreshStream();
  }

  Future<void> stop(String id) async {
    var i = _getIsolateWrapper(id);
    if (i == null) return;
    await i.stop();
  }

  void _refreshStream() {
    controller.add(infos.values.toList());
  }
}

class IsolateInfo {
  final String id;
  final int progress;
  final String progressMessage;
  final String? description;
  final bool isComplete;
  final String log;
  final int errorCount;

  IsolateInfo(this.id,
      {this.description = "",
      this.progressMessage = "",
      this.progress = 0,
      this.isComplete = false,
      this.log = "",
      this.errorCount = 0});

  IsolateInfo copyWith(
      {String? description,
      String? progressMessage,
      int? progress,
      bool? isComplete,
      String? log,
      bool isError = false}) {
    return IsolateInfo(id,
        description: description ?? this.description,
        progressMessage: progressMessage ?? this.progressMessage,
        progress: progress ?? this.progress,
        isComplete: isComplete ?? this.isComplete,
        log: (log != null) ? ("${this.log}\n$log") : this.log,
        errorCount: (isError ? (errorCount + 1) : errorCount));
  }

  String get label {
    if (description != null) {
      return '$description ($id)';
    } else {
      return id;
    }
  }

  @override
  String toString() {
    return "<IsolateInfo: \n     id=$id \n     description=$description \n     progress=$progress \n     progressMessage=$progressMessage \n     isComplete=$isComplete\n     errorCount=$errorCount \n     >";
  }
}
