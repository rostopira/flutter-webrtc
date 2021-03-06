import 'dart:async';
// ignore: uri_does_not_exist
import 'dart:js' as JS;
// ignore: uri_does_not_exist
import 'dart:html' as HTML;
import 'media_stream.dart';
import 'utils.dart';

class navigator {

  static Future<MediaStream> getUserMedia(Map<String, dynamic> mediaConstraints) async {
    final nav = HTML.window.navigator;
    final jsStream = await nav.getUserMedia(
        audio: mediaConstraints['audio'] ?? false,
        video: mediaConstraints['video'] ?? false
    );
    print("Got jsStream ${jsStream}");
    return MediaStream(jsStream);
  }

  static Future<MediaStream> getDisplayMedia(Map<String, dynamic> mediaConstraints) async {
    final nav = HTML.window.navigator;
    final mediaDevices = nav.mediaDevices;
    final jsMediaDevices = JS.JsObject.fromBrowserObject(mediaDevices);
    if (jsMediaDevices.hasProperty(getDisplayMedia)) {
      final JS.JsObject arg = JS.JsObject.jsify({"video":true});
      JS.JsObject getDisplayMediaPromise = jsMediaDevices.callMethod('getDisplayMedia',[arg]);
      final HTML.MediaStream jsStream = await promiseToFuture(getDisplayMediaPromise);
      return MediaStream(jsStream);
    } else {
      final HTML.MediaStream jsStream = await nav.getUserMedia(
        video: {"mediaSource":'screen'},
        audio: mediaConstraints['audio'] ?? false
      );
      return MediaStream(jsStream);
    }
  }

  static Future<List<dynamic>> getSources() async {
    final devices = await HTML.window.navigator.mediaDevices.enumerateDevices();
    final result = List<dynamic>();
    for (final device in devices) {
      result.add(<String, String>{
        'deviceId': device.deviceId,
        'groupId': device.groupId,
        'kind': device.kind,
        'label': device.label
      });
    }
    return result;
  }

}
