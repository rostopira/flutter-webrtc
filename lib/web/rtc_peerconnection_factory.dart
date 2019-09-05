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
  if (constraints.isEmpty)
    print("⚠️ Warning! Constraints is empty!");
  else
    print("⚠️ $constraints");
  final jsRtcPc = HTML.RtcPeerConnection(configuration, constr);
  return RTCPeerConnection(jsRtcPc);
}
