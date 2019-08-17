#import <Foundation/Foundation.h>
#import "FlutterRTCFrameCapturer.h"
#import "WebRTC/RTCVideoFrame.h"
#import "WebRTC/RTCVideoFrameBuffer.h"
#import "WebRTC/RTCCVPixelBuffer.h"

@implementation FlutterRTCFrameCapturer {
    __strong RTCVideoTrack* _videoTrack;
    NSString* _filePath;
    bool _frameSaved;
    int _rotation;
}

- (instancetype) initWithVideoTrack:(RTCVideoTrack *)track filePath:(NSString *)path rotationDegrees:(NSNumber *)rotation {
    self = [self init];
    _frameSaved = false;
    _videoTrack = track;
    _filePath = path;
    _rotation = rotation.intValue % 360;
    [track addRenderer:self];
    return self;
}

- (void)renderFrame:(nullable RTCVideoFrame *)frame {
    if (_frameSaved || frame == nil) {
        return;
    }
    NSLog(@"🔋🔋🔋");
    id <RTCVideoFrameBuffer> buffer = frame.buffer;
    CVPixelBufferRef pixelBufferRef = ((RTCCVPixelBuffer *) buffer).pixelBuffer;
    CIImage *ciImage = [CIImage imageWithCVPixelBuffer:pixelBufferRef];
    CIContext *tempContext = [CIContext contextWithOptions:nil];
    CGImageRef cgImage = [tempContext
                          createCGImage:ciImage
                          fromRect:CGRectMake(0, 0, frame.width, frame.height)];
    UIImageOrientation orientation;
    switch (frame.rotation) {
        case RTCVideoRotation_90:
            orientation = UIImageOrientationRight;
            break;
        case RTCVideoRotation_180:
            orientation = UIImageOrientationDown;
            break;
        case RTCVideoRotation_270:
            orientation = UIImageOrientationLeft;
        default:
            orientation = UIImageOrientationUp;
            break;
    }
    switch (_rotation) {
        case 0: break;
        case 90:
            switch (orientation) {
                case UIImageOrientationUp: orientation = UIImageOrientationRight; break;
                case UIImageOrientationRight: orientation = UIImageOrientationDown; break;
                case UIImageOrientationDown: orientation = UIImageOrientationLeft; break;
                case UIImageOrientationLeft: orientation = UIImageOrientationUp; break;
                default: break;
            }
            break;
        case 180:
            switch (orientation) {
                case UIImageOrientationUp: orientation = UIImageOrientationDown; break;
                case UIImageOrientationRight: orientation = UIImageOrientationLeft; break;
                case UIImageOrientationDown: orientation = UIImageOrientationUp; break;
                case UIImageOrientationLeft: orientation = UIImageOrientationRight; break;
                default: break;
            }
            break;
        case 270:
            switch (orientation) {
                case UIImageOrientationUp: orientation = UIImageOrientationLeft; break;
                case UIImageOrientationRight: orientation = UIImageOrientationUp; break;
                case UIImageOrientationDown: orientation = UIImageOrientationRight; break;
                case UIImageOrientationLeft: orientation = UIImageOrientationDown; break;
                default: break;
            }
            break;
        default:
            break;
    }
    UIImage *uiImage = [UIImage imageWithCGImage:cgImage scale:1 orientation:orientation];
    CGImageRelease(cgImage);
    NSData *jpgData = UIImageJPEGRepresentation(uiImage, 0.9f);
    if ([jpgData writeToFile:_filePath atomically:NO]) {
        NSLog(@"File writed successfully to %@", _filePath);
    } else {
        NSLog(@"Failed to write to file");
    }
    _frameSaved = true;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self->_videoTrack removeRenderer:self];
        self->_videoTrack = nil;
        NSLog(@"🔴🔴🔴");
    });
}

- (void)setSize:(CGSize)size {
}

@end
