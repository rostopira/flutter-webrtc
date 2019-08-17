//
//  FlutterRTCAudioSink-Interface.h
//  flutter_webrtc
//
//  Created by THIS on 4/2/19.
//

#ifndef FlutterRTCAudioSink_Interface_h
#define FlutterRTCAudioSink_Interface_h

void RTCAudioSinkCallback (void *object,
                           const void *audio_data,
                           int bits_per_sample,
                           int sample_rate,
                           size_t number_of_channels,
                           size_t number_of_frames
);

#endif /* FlutterRTCAudioSink_Interface_h */
