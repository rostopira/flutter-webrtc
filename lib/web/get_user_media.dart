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
    final jsStream = await nav.getUserMedia(audio: true, video: true);
    print("Got jsStream ${jsStream}");
    return MediaStream(jsStream);
  }

  static Future<MediaStream> getDisplayMedia(Map<String, dynamic> mediaConstraints) async {
    final mediaDevices = HTML.window.navigator.mediaDevices;
    final jsMediaDevices = JS.JsObject.fromBrowserObject(mediaDevices);
    JS.JsObject getDisplayMediaPromise;
    if (jsMediaDevices.hasProperty(getDisplayMedia)) {
      final JS.JsObject arg = JS.JsObject.jsify({"video":true});
      getDisplayMediaPromise = jsMediaDevices.callMethod('getDisplayMedia',[arg]);
    } else {
      final JS.JsObject arg = JS.JsObject.jsify({"video":{"mediaSource":'screen'}});
      getDisplayMediaPromise = jsMediaDevices.callMethod('getUserMedia',[arg]);
    }
    final HTML.MediaStream jsStream = await promiseToFuture(getDisplayMediaPromise);
    return MediaStream(jsStream);
  }

  static Future<List<dynamic>> getSources() =>
    HTML.window.navigator.mediaDevices.enumerateDevices();

}
