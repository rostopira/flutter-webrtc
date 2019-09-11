import 'package:flutter/services.dart';
import 'utils.dart';

class MediaStreamTrack {
  MethodChannel _channel = WebRTC.methodChannel();
  String _trackId;
  String _label;
  String _kind;
  bool _enabled;

  MediaStreamTrack(this._trackId, this._label, this._kind, this._enabled);

  set enabled(bool enabled) {
    _channel.invokeMethod('mediaStreamTrackSetEnable',
        <String, dynamic>{'trackId': _trackId, 'enabled': enabled});
    _enabled = enabled;
  }

  bool get enabled => _enabled;
  String get label => _label;
  String get kind => _kind;
  String get id => _trackId;

  Future<bool> switchCamera() =>
    _channel.invokeMethod(
      'mediaStreamTrackSwitchCamera',
      <String, dynamic>{'trackId': _trackId},
    );

  Future<void> adaptRes(int width, int height) =>
    _channel.invokeMethod(
      'mediaStreamTrackAdaptRes',
      <String, dynamic>{
        'trackId': _trackId,
        'width': width,
        'height': height,
      },
    );

  void setVolume(double volume) async {
    await _channel.invokeMethod(
      'setVolume',
      <String, dynamic>{'trackId': _trackId, 'volume': volume},
    );
  }

  captureFrame([String filePath, int rotation]) =>
    _channel.invokeMethod(
      'captureFrame',
      <String, dynamic>{
        'trackId':_trackId,
        'path': filePath,
        'rotation': (rotation ?? 0) * 90,
      },
    );

  torch(bool enabled) =>
    _channel.invokeMethod(
      'torch',
      {'trackId': _trackId, 'enabled': enabled}
    );

  Future<void> dispose() async {
    await _channel.invokeMethod(
      'trackDispose',
      <String, dynamic>{'trackId': _trackId},
    );
  }
}
