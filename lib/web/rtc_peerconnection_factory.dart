import 'dart:async';
// ignore: uri_does_not_exist
import 'dart:html' as HTML;
import 'rtc_peerconnection.dart';

Future<RTCPeerConnection> createPeerConnection(Map<String, dynamic> configuration, Map<String, dynamic> constraints) async {
  final constr = constraints.isNotEmpty ? constraints : {
    "mandatory": {},
    "optional": [
      {"DtlsSrtpKeyAgreement": true},
    ],
  };
  final jsRtcPc = HTML.RtcPeerConnection(configuration, constraints);
  return RTCPeerConnection(jsRtcPc);
}
