import 'dart:async';
// ignore: uri_does_not_exist
import 'dart:html' as HTML;
// ignore: uri_does_not_exist
import 'dart:js' as JS;
import 'package:flutter/material.dart';
import 'media_stream.dart';
import 'dart:ui' as ui;

enum RTCVideoViewObjectFit {
  RTCVideoViewObjectFitContain,
  RTCVideoViewObjectFitCover,
}

typedef void VideoRotationChangeCallback(int textureId, int rotation);
typedef void VideoSizeChangeCallback(
    int textureId, double width, double height);

/// STUB
/// https://github.com/flutter/flutter/pull/37819
class RTCVideoRenderer {

  double _width = 0.0, _height = 0.0;
  bool _mirror = false;
  MediaStream _srcObject;
  RTCVideoViewObjectFit _objectFit =
      RTCVideoViewObjectFit.RTCVideoViewObjectFitContain;
  VideoSizeChangeCallback onVideoSizeChanged;
  VideoRotationChangeCallback onVideoRotationChanged;
  dynamic onFirstFrameRendered;
  var isFirstFrameRendered = false;

  dynamic onStateChanged;

  HtmlElementView htmlElementView;
  HTML.VideoElement _htmlVideoElement;

  static var _isViewFactoryRegistered = false;
  static final _videoViews = Map<int, HTML.VideoElement>();
  static Function(HTML.VideoElement) _nextCallback;

  initialize() async {
    if (!_isViewFactoryRegistered) {
      // ignore: implementation_imports
      ui.platformViewRegistry.registerViewFactory('webrtc_video', (int viewId) {
        final x = HTML.VideoElement();
        x.autoplay = true;
        x.muted = true;
        if (_srcObject != null)
          x.srcObject = _srcObject.jsStream;
        _videoViews[viewId] = x;
        if (_nextCallback != null)
          _nextCallback(x);
        return x;
      });
      _isViewFactoryRegistered = true;
    }
    _nextCallback = (v) => _htmlVideoElement = v;
    htmlElementView = HtmlElementView(viewType: 'webrtc_video');
  }

  int get rotation => 0;

  double get width => _width ?? 1080;

  double get height => _height ?? 1920;

  int get textureId => 0;

  double get aspectRatio =>
    (_width == 0 || _height == 0) ? (9/16) : _width / _height;

  bool get mirror => _mirror;

  set mirror(bool mirror) {
    _mirror = mirror;
    if (this.onStateChanged != null) {
      this.onStateChanged();
    }
  }

  RTCVideoViewObjectFit get objectFit => _objectFit;

  set objectFit(RTCVideoViewObjectFit objectFit) {
    _objectFit = objectFit;
    if (this.onStateChanged != null) {
      this.onStateChanged();
    }
  }

  set srcObject(MediaStream stream) {
    _srcObject = stream;
//    _videoViews[_htmlViewId]?.srcObject = stream.jsStream;
    findHtmlView()?.srcObject = stream.jsStream;
  }

  void findAndApply(Size size) {
    final htmlView = findHtmlView();
    if (_srcObject != null && htmlView != null) {
      htmlView.srcObject = _srcObject.jsStream;
      htmlView.width = size.width.toInt();
      htmlView.height = size.height.toInt();
      htmlView.onLoadedMetadata.listen((_) {
        if (htmlView.videoWidth != 0 && htmlView.videoHeight != 0 && (_width != htmlView.videoWidth || _height != htmlView.videoHeight)) {
          _width = htmlView.videoWidth.toDouble();
          _height = htmlView.videoHeight.toDouble();
          if (onVideoSizeChanged != null)
            onVideoSizeChanged(0, _width, _height);
        }
        if (!isFirstFrameRendered && onFirstFrameRendered != null) {
          onFirstFrameRendered();
          isFirstFrameRendered = true;
        }
      });
      if (htmlView.videoWidth != 0 && htmlView.videoHeight != 0 && (_width != htmlView.videoWidth || _height != htmlView.videoHeight)) {
        _width = htmlView.videoWidth.toDouble();
        _height = htmlView.videoHeight.toDouble();
        if (onVideoSizeChanged != null)
          onVideoSizeChanged(0, _width, _height);
      }
      htmlView.play();
    }
  }

  HTML.VideoElement findHtmlView() {
    if (_htmlVideoElement != null)
      return _htmlVideoElement;
    print("_htmlVideoElement is null");
    final fltPv = HTML.document.getElementsByTagName('flt-platform-view');
    if (fltPv.isEmpty)
      return null;
    return (fltPv.first as HTML.Element).shadowRoot.lastChild;
  }

  Future<Null> dispose() async {
    //TODO?
  }

}

class RTCVideoView extends StatefulWidget {
  final RTCVideoRenderer _renderer;
  RTCVideoView(this._renderer);
  @override
  _RTCVideoViewState createState() => new _RTCVideoViewState(_renderer);
}

class _RTCVideoViewState extends State<RTCVideoView> {
  final RTCVideoRenderer _renderer;
  double _aspectRatio;
  RTCVideoViewObjectFit _objectFit;
  bool _mirror;
  _RTCVideoViewState(this._renderer);

  @override
  void initState() {
    super.initState();
    _setCallbacks();
    _aspectRatio = _renderer.aspectRatio;
    _mirror = _renderer.mirror;
    _objectFit = _renderer.objectFit;
  }

  @override
  void deactivate() {
    super.deactivate();
    _renderer.onStateChanged = null;
  }

  void _setCallbacks() {
    _renderer.onStateChanged = () {
      setState(() {
        _aspectRatio = _renderer.aspectRatio;
        _mirror = _renderer.mirror;
        _objectFit = _renderer.objectFit;
      });
    };
  }

  Widget _buildVideoView(BoxConstraints constraints) {
    _renderer.findAndApply(constraints.biggest);
    return Container(
      width: constraints.maxWidth,
      height: constraints.maxHeight,
      child: new SizedBox(
        width: constraints.maxHeight * _aspectRatio,
        height: constraints.maxHeight,
        child: _renderer.htmlElementView
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    bool renderVideo = _renderer._srcObject != null;
    return new LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return new Center(
          child: renderVideo ? _buildVideoView(constraints) : new Container()
        );
      }
    );
  }

}
