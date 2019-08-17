import 'dart:async';
// ignore: uri_does_not_exist
import 'dart:html' as HTML;

class RTCDataChannelInit {
  bool ordered = true;
  int maxRetransmitTime = -1;
  int maxRetransmits = -1;
  String protocol = 'sctp'; //sctp | quic
  String binaryType = 'text'; // "binary" || text
  bool negotiated = false;
  int id = 0;
  Map<String, dynamic> toMap() {
    return {
      'ordered': ordered,
      if (maxRetransmitTime > 0)
        'maxRetransmitTime': maxRetransmitTime,
      if (maxRetransmits > 0)
        'maxRetransmits': maxRetransmits,
      'protocol': protocol,
      'negotiated': negotiated,
      if (id > 0)
        'id': id
    };
  }
}

enum RTCDataChannelState {
  RTCDataChannelConnecting,
  RTCDataChannelOpen,
  RTCDataChannelClosing,
  RTCDataChannelClosed,
}

typedef void RTCDataChannelStateCallback(RTCDataChannelState state);
typedef void RTCDataChannelOnMessageCallback(String data);

class RTCDataChannel {
  final HTML.RtcDataChannel _jsDc;
  RTCDataChannelStateCallback onDataChannelState;
  RTCDataChannelOnMessageCallback onMessage;
  int get dataChannelId => _jsDc.id;

  RTCDataChannel(this._jsDc) {
    _jsDc.onClose.listen((_) {
      if (onDataChannelState != null) {
        onDataChannelState(RTCDataChannelState.RTCDataChannelClosed);
      }
    });
    _jsDc.onOpen.listen((_) {
      if (onDataChannelState != null) {
        onDataChannelState(RTCDataChannelState.RTCDataChannelOpen);
      }
    });
    _jsDc.onMessage.listen((event) {
      if (onMessage != null) {
        onMessage(event.data);
      }
    });
  }

  Future<void> send(String type, dynamic data) {
    _jsDc.send(data);
    return Future.value();
  }

  Future<void> close() {
    _jsDc.close();
    return Future.value();
  }

}
