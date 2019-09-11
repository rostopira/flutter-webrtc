import 'dart:async';
import 'dart:math';

import 'media_stream_track.dart';
import 'media_stream.dart';
import 'utils.dart';

class MediaRecorder {
  static final _random = Random();
  final _recorderId = _random.nextInt(0x7FFFFFFF);
  String filePath;

  Future<void> start(String path, {
    MediaStreamTrack videoTrack,
    MediaStreamTrack audioTrack,
    RecorderAudioChannel audioChannel,
    int rotation,
    //TODO: add codec/quality options
  }) async {
    if (path == null)
      throw ArgumentError.notNull("path");
    if (audioChannel == null && videoTrack == null)
      throw Exception("Neither audio nor video track were provided");
    filePath = path;
    await WebRTC.methodChannel().invokeMethod('startRecordToFile', {
      'path' : path,
      'audioChannel' : audioChannel?.index,
      'videoTrackId' : videoTrack?.id,
      'audioTrackId' : audioTrack?.id,
      'recorderId' : _recorderId,
      'rotation': (rotation ?? 0) * 90,
    });
  }

  void startWeb(MediaStream stream, {
    Function(dynamic blob, bool isLastOne) onDataChunk,
    String mimeType = 'video/webm'
  }) {
    throw "WTF?";
  }

  Future<dynamic> stop() async =>
    await WebRTC.methodChannel().invokeMethod('stopRecordToFile', {
      'recorderId' : _recorderId
    });

}

enum RecorderAudioChannel { INPUT, OUTPUT }