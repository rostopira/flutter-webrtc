import 'dart:async';
// ignore: uri_does_not_exist
import 'dart:js' as JS;
// ignore: uri_does_not_exist
import 'dart:html' as HTML;

import 'media_stream.dart';
import 'media_stream_track.dart';

class MediaRecorder {
  String filePath;
  HTML.MediaRecorder _recorder;
  List<HTML.Blob> _chunks;
  Completer<dynamic> _completer;

  /// For Android use audioChannel param
  /// For iOS use audioTrack
  Future<void> start(String path, {
    MediaStreamTrack videoTrack,
    MediaStreamTrack audioTrack,
    RecorderAudioChannel audioChannel,
    int rotation,
  }) {
    throw "Use startWeb on Flutter Web!";
  }

  /// Only for Flutter Web
  void startWeb(MediaStream stream, {
    Function(dynamic blob, bool isLastOne) onDataChunk,
    String mimeType = '"video/x-matroska'
  }) {
    _recorder = HTML.MediaRecorder(stream.jsStream);//, {'mimeType':mimeType, 'ignoreMutedMedia': false});
    if (onDataChunk == null) {
      _chunks = List();
      _completer = Completer();
      JS.context['rec'] = JS.JsObject.fromBrowserObject(_recorder);
      _recorder.onError.listen((x) {
        print(x);
      });
      _recorder.addEventListener('dataavailable', (HTML.Event event) {
        print("datavailable ${event.runtimeType}");
        final HTML.Blob blob = JS.JsObject.fromBrowserObject(event)['data'];
        print("BLOB SIZE: ${blob.size}");
        if (blob.size > 0) {
          _chunks.add(blob);
        }
        if (_recorder.state == 'inactive') {
          final blob = HTML.Blob(_chunks, mimeType);
          _completer?.complete(HTML.Url.createObjectUrlFromBlob(blob));
          _completer = null;
        }
      });
      _recorder.onError.listen((error) {
        _completer?.completeError(error);
        _completer = null;
      });
    } else {
      _recorder.addEventListener('dataavailable', (HTML.Event event) {
        final HTML.Blob blob = JS.JsObject.fromBrowserObject(event)['data'];
        onDataChunk(blob, _recorder.state == 'inactive');
      });
    }
    _recorder.start(2048);
  }

  Future<dynamic> stop() {
    _recorder?.stop();
    return _completer?.future ?? Future.value();
  }

}

enum RecorderAudioChannel { INPUT, OUTPUT }