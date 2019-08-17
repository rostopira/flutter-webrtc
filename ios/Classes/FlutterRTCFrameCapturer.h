#import <Foundation/Foundation.h>
#import <WebRTC/RTCVideoRenderer.h>
#import <WebRTC/RTCVideoTrack.h>

#ifndef FlutterRTCFrameCapturer_h
#define FlutterRTCFrameCapturer_h

@interface FlutterRTCFrameCapturer : NSObject<RTCVideoRenderer>

- (instancetype) initWithVideoTrack:(RTCVideoTrack *)track
                           filePath:(NSString *)path
                    rotationDegrees:(NSNumber *)rotation;

@end

#endif /* FlutterRTCFrameCapturer_h */
