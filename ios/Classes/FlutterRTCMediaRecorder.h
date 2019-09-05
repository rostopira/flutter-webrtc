#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <WebRTC/RTCVideoTrack.h>
#import <WebRTC/RTCVideoRenderer.h>


@interface FlutterRTCMediaRecorder : NSObject<RTCVideoRenderer>

@property (nonatomic, strong) RTCVideoTrack *videoTrack;
@property (nonatomic, strong) NSURL *output;
@property (nonatomic, strong) AVAssetWriter *assetWriter;
@property (nonatomic, strong) AVAssetWriterInput *writerInput;

- (instancetype) initWithVideoTrack:(RTCVideoTrack *)video
                    rotationDegrees:(NSNumber *)rotation
                         audioTrack:(RTCAudioTrack *)audio
                         outputFile:(NSURL *)out;

- (void)stop;

@end
