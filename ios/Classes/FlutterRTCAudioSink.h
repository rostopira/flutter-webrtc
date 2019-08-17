#import <Foundation/Foundation.h>
#import "WebRTC/RTCAudioTrack.h"
#import "WebRTC/RTCAudioSource.h"

@interface FlutterRTCAudioSink : NSObject

@property (nonatomic, copy) void (^bufferCallback)(CMSampleBufferRef);
@property (nonatomic) CMAudioFormatDescriptionRef format;

- (instancetype) initWithAudioTrack:(RTCAudioTrack* )audio;

- (void) close;

@end
