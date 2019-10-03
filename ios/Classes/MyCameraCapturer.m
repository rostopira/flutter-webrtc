/*
 *  Copyright 2017 The WebRTC project authors. All Rights Reserved.
 *
 *  Use of this source code is governed by a BSD-style license
 *  that can be found in the LICENSE file in the root of the source
 *  tree. An additional intellectual property rights grant can be found
 *  in the file PATENTS.  All contributing project authors may
 *  be found in the AUTHORS file in the root of the source tree.
 */
#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <WebRTC/RTCCameraVideoCapturer.h>
#import <WebRTC/RTCVideoFrameBuffer.h>
#import <WebRTC/RTCCVPixelBuffer.h>
#import <WebRTC/UIDevice+RTCDevice.h>
#import "MyCameraCapturer.h"

const int64_t kNanosecondsPerSecond = 1000000000;
@interface MyCameraCapturer ()<AVCaptureVideoDataOutputSampleBufferDelegate>
@property(nonatomic, readonly) dispatch_queue_t frameQueue;
@property(nonatomic, strong) AVCaptureDevice *currentDevice;
@property(nonatomic, assign) BOOL hasRetriedOnFatalError;
@property(nonatomic, assign) BOOL isRunning;
// Will the session be running once all asynchronous operations have been completed?
@property(nonatomic, assign) BOOL willBeRunning;
@end
@implementation MyCameraCapturer {
    AVCaptureVideoDataOutput *_videoDataOutput;
    AVCaptureSession *_captureSession;
    FourCharCode _preferredOutputPixelFormat;
    FourCharCode _outputPixelFormat;
    RTCVideoRotation _rotation;
    dispatch_queue_t _captureDispatchQueue;
    UIDeviceOrientation _orientation;
    NSObject<AVCaptureVideoDataOutputSampleBufferDelegate> *_interceptor;
}
@synthesize frameQueue = _frameQueue;
@synthesize captureSession = _captureSession;
@synthesize currentDevice = _currentDevice;
@synthesize hasRetriedOnFatalError = _hasRetriedOnFatalError;
@synthesize isRunning = _isRunning;
@synthesize willBeRunning = _willBeRunning;
@synthesize interceptor = _interceptor;
- (instancetype)init {
    return [self initWithDelegate:nil captureSession:[[AVCaptureSession alloc] init]];
}
- (instancetype)initWithDelegate:(__weak id<RTCVideoCapturerDelegate>)delegate {
    return [self initWithDelegate:delegate captureSession:[[AVCaptureSession alloc] init]];
}
// This initializer is used for testing.
- (instancetype)initWithDelegate:(__weak id<RTCVideoCapturerDelegate>)delegate
                  captureSession:(AVCaptureSession *)captureSession {
    if (self = [super initWithDelegate:delegate]) {
        _captureDispatchQueue = dispatch_queue_create("capture_session_queue", NULL);
        // Create the capture session and all relevant inputs and outputs. We need
        // to do this in init because the application may want the capture session
        // before we start the capturer for e.g. AVCapturePreviewLayer. All objects
        // created here are retained until dealloc and never recreated.
        if (![self setupCaptureSession:captureSession]) {
            return nil;
        }
        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
        _orientation = UIDeviceOrientationPortrait;
        _rotation = RTCVideoRotation_90;
        [center addObserver:self
                   selector:@selector(deviceOrientationDidChange:)
                       name:UIDeviceOrientationDidChangeNotification
                     object:nil];
        [center addObserver:self
                   selector:@selector(handleCaptureSessionInterruption:)
                       name:AVCaptureSessionWasInterruptedNotification
                     object:_captureSession];
        [center addObserver:self
                   selector:@selector(handleCaptureSessionInterruptionEnded:)
                       name:AVCaptureSessionInterruptionEndedNotification
                     object:_captureSession];
        [center addObserver:self
                   selector:@selector(handleApplicationDidBecomeActive:)
                       name:UIApplicationDidBecomeActiveNotification
                     object:[UIApplication sharedApplication]];
        [center addObserver:self
                   selector:@selector(handleCaptureSessionRuntimeError:)
                       name:AVCaptureSessionRuntimeErrorNotification
                     object:_captureSession];
        [center addObserver:self
                   selector:@selector(handleCaptureSessionDidStartRunning:)
                       name:AVCaptureSessionDidStartRunningNotification
                     object:_captureSession];
        [center addObserver:self
                   selector:@selector(handleCaptureSessionDidStopRunning:)
                       name:AVCaptureSessionDidStopRunningNotification
                     object:_captureSession];
    }
    return self;
}
- (void)dealloc {
    NSAssert(
            !_willBeRunning,
            @"Session was still running in RTCCameraVideoCapturer dealloc. Forgot to call stopCapture?");
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
+ (NSArray<AVCaptureDevice *> *)captureDevices {
    AVCaptureDeviceDiscoverySession *session = [AVCaptureDeviceDiscoverySession
      discoverySessionWithDeviceTypes:@[ AVCaptureDeviceTypeBuiltInWideAngleCamera ]
                            mediaType:AVMediaTypeVideo
                             position:AVCaptureDevicePositionUnspecified];
  return session.devices;
}
+ (NSArray<AVCaptureDeviceFormat *> *)supportedFormatsForDevice:(AVCaptureDevice *)device {
    // Support opening the device in any format. We make sure it's converted to a format we
    // can handle, if needed, in the method `-setupVideoDataOutput`.
    return device.formats;
}
- (FourCharCode)preferredOutputPixelFormat {
    return _preferredOutputPixelFormat;
}
- (void)startCaptureWithDevice:(AVCaptureDevice *)device
                        format:(AVCaptureDeviceFormat *)format
                           fps:(NSInteger)fps {
    [self startCaptureWithDevice:device format:format fps:fps completionHandler:nil];
}
- (void)stopCapture {
    [self stopCaptureWithCompletionHandler:nil];
}
- (void)startCaptureWithDevice:(AVCaptureDevice *)device
                        format:(AVCaptureDeviceFormat *)format
                           fps:(NSInteger)fps
             completionHandler:(nullable void (^)(NSError *))completionHandler {
    _willBeRunning = YES;
    dispatch_async(_captureDispatchQueue, ^{
                              NSLog(@"startCaptureWithDevice %@ @ %ld fps", format, (long)fps);
                              [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
                              self.currentDevice = device;
                              NSError *error = nil;
                                if (![self.currentDevice lockForConfiguration:&error]) {
                                  NSLog(@"Failed to lock device %@. Error: %@",
                                              self.currentDevice,
                                              error.userInfo);
                                  if (completionHandler) {
                                    completionHandler(error);
                                  }
                                  self.willBeRunning = NO;
                                  return;
                                }
                              [self reconfigureCaptureSessionInput];
                              [self updateOrientation];
                              [self updateDeviceCaptureFormat:format fps:fps];
                              [self updateVideoDataOutputPixelFormat:format];
                              [self.captureSession startRunning];
                              [self.currentDevice unlockForConfiguration];
                              self.isRunning = YES;
                              if (completionHandler) {
                                  completionHandler(nil);
                              }
                          });
}
- (void)stopCaptureWithCompletionHandler:(nullable void (^)(void))completionHandler {
    _willBeRunning = NO;
    dispatch_async(_captureDispatchQueue, ^{
          NSLog(@"Stop");
          self.currentDevice = nil;
          for (AVCaptureDeviceInput *oldInput in [self.captureSession.inputs copy]) {
              [self.captureSession removeInput:oldInput];
          }
          [self.captureSession stopRunning];
          [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
          self.isRunning = NO;
          if (completionHandler) {
              completionHandler();
          }
    });
}
#pragma mark iOS notifications
- (void)deviceOrientationDidChange:(NSNotification *)notification {
    dispatch_async(_captureDispatchQueue, ^{
        [self updateOrientation];
    });
}
#pragma mark AVCaptureVideoDataOutputSampleBufferDelegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection {
    if (self.interceptor) {
        [self.interceptor captureOutput:captureOutput didOutputSampleBuffer:sampleBuffer fromConnection:connection];
    }
    NSParameterAssert(captureOutput == _videoDataOutput);
    if (CMSampleBufferGetNumSamples(sampleBuffer) != 1 || !CMSampleBufferIsValid(sampleBuffer) ||
            !CMSampleBufferDataIsReady(sampleBuffer)) {
        return;
    }
    CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    if (pixelBuffer == nil) {
        return;
    }
    // Default to portrait orientation on iPhone.
    BOOL usingFrontCamera = NO;
    // Check the image's EXIF for the camera the image came from as the image could have been
    // delayed as we set alwaysDiscardsLateVideoFrames to NO.
//    AVCaptureDevicePosition cameraPosition =
//            [AVCaptureSession devicePositionForSampleBuffer:sampleBuffer];
//    if (cameraPosition != AVCaptureDevicePositionUnspecified) {
//        usingFrontCamera = AVCaptureDevicePositionFront == cameraPosition;
//    } else {
//        AVCaptureDeviceInput *deviceInput =
//                (AVCaptureDeviceInput *)((AVCaptureInputPort *)connection.inputPorts.firstObject).input;
//        usingFrontCamera = AVCaptureDevicePositionFront == deviceInput.device.position;
//    }
    switch (_orientation) {
        case UIDeviceOrientationPortrait:
            _rotation = RTCVideoRotation_90;
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            _rotation = RTCVideoRotation_270;
            break;
        case UIDeviceOrientationLandscapeLeft:
            _rotation = usingFrontCamera ? RTCVideoRotation_180 : RTCVideoRotation_0;
            break;
        case UIDeviceOrientationLandscapeRight:
            _rotation = usingFrontCamera ? RTCVideoRotation_0 : RTCVideoRotation_180;
            break;
        case UIDeviceOrientationFaceUp:
        case UIDeviceOrientationFaceDown:
        case UIDeviceOrientationUnknown:
            // Ignore.
            break;
    }
    RTCCVPixelBuffer *rtcPixelBuffer = [[RTCCVPixelBuffer alloc] initWithPixelBuffer:pixelBuffer];
    int64_t timeStampNs = CMTimeGetSeconds(CMSampleBufferGetPresentationTimeStamp(sampleBuffer)) *
            kNanosecondsPerSecond;
    RTCVideoFrame *videoFrame = [[RTCVideoFrame alloc] initWithBuffer:rtcPixelBuffer
                                                             rotation:_rotation
                                                          timeStampNs:timeStampNs];
    [self.delegate capturer:self didCaptureVideoFrame:videoFrame];
}
- (void)captureOutput:(AVCaptureOutput *)captureOutput
  didDropSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection {
    CFStringRef droppedReason =
            CMGetAttachment(sampleBuffer, kCMSampleBufferAttachmentKey_DroppedFrameReason, nil);
}
#pragma mark - AVCaptureSession notifications
- (void)handleCaptureSessionInterruption:(NSNotification *)notification {
    NSString *reasonString = nil;
    NSNumber *reason = notification.userInfo[AVCaptureSessionInterruptionReasonKey];
    if (reason) {
        switch (reason.intValue) {
            case AVCaptureSessionInterruptionReasonVideoDeviceNotAvailableInBackground:
                reasonString = @"VideoDeviceNotAvailableInBackground";
                break;
            case AVCaptureSessionInterruptionReasonAudioDeviceInUseByAnotherClient:
                reasonString = @"AudioDeviceInUseByAnotherClient";
                break;
            case AVCaptureSessionInterruptionReasonVideoDeviceInUseByAnotherClient:
                reasonString = @"VideoDeviceInUseByAnotherClient";
                break;
            case AVCaptureSessionInterruptionReasonVideoDeviceNotAvailableWithMultipleForegroundApps:
                reasonString = @"VideoDeviceNotAvailableWithMultipleForegroundApps";
                break;
        }
    }
}
- (void)handleCaptureSessionInterruptionEnded:(NSNotification *)notification {
    NSLog(@"Capture session interruption ended.");
}
- (void)handleCaptureSessionRuntimeError:(NSNotification *)notification {
    NSError *error = [notification.userInfo objectForKey:AVCaptureSessionErrorKey];
    NSLog(@"Capture session runtime error: %@", error);
    dispatch_async(_captureDispatchQueue, ^{
        if (error.code == AVErrorMediaServicesWereReset) {
            [self handleNonFatalError];
        } else {
            [self handleFatalError];
        }
    });
}
- (void)handleCaptureSessionDidStartRunning:(NSNotification *)notification {
    NSLog(@"Capture session started.");
    dispatch_async(_captureDispatchQueue, ^{
        // If we successfully restarted after an unknown error,
        // allow future retries on fatal errors.
        self.hasRetriedOnFatalError = NO;
    });
}
- (void)handleCaptureSessionDidStopRunning:(NSNotification *)notification {
    NSLog(@"Capture session stopped.");
}
- (void)handleFatalError {
    dispatch_async(_captureDispatchQueue, ^{
          if (!self.hasRetriedOnFatalError) {
              NSLog(@"Attempting to recover from fatal capture error.");
              [self handleNonFatalError];
              self.hasRetriedOnFatalError = YES;
          } else {
              NSLog(@"Previous fatal error recovery failed.");
          }
      });
}
- (void)handleNonFatalError {
    dispatch_async(_captureDispatchQueue, ^{
                                     NSLog(@"Restarting capture session after error.");
                                     if (self.isRunning) {
                                         [self.captureSession startRunning];
                                     }
                                 });
}
#pragma mark - UIApplication notifications
- (void)handleApplicationDidBecomeActive:(NSNotification *)notification {
    dispatch_async(_captureDispatchQueue, ^{
        if (self.isRunning && !self.captureSession.isRunning) {
            NSLog(@"Restarting capture session on active.");
            [self.captureSession startRunning];
        }
    });
}
#pragma mark - Private
- (dispatch_queue_t)frameQueue {
    if (!_frameQueue) {
        _frameQueue =
                dispatch_queue_create("org.webrtc.cameravideocapturer.video", DISPATCH_QUEUE_SERIAL);
        dispatch_set_target_queue(_frameQueue,
                dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0));
    }
    return _frameQueue;
}
- (BOOL)setupCaptureSession:(AVCaptureSession *)captureSession {
    NSAssert(_captureSession == nil, @"Setup capture session called twice.");
    _captureSession = captureSession;
    _captureSession.sessionPreset = AVCaptureSessionPresetInputPriority;
  _captureSession.usesApplicationAudioSession = NO;
    [self setupVideoDataOutput];
    // Add the output.
    if (![_captureSession canAddOutput:_videoDataOutput]) {
        NSLog(@"Video data output unsupported.");
        return NO;
    }
    [_captureSession addOutput:_videoDataOutput];
    return YES;
}
- (void)setupVideoDataOutput {
    NSAssert(_videoDataOutput == nil, @"Setup video data output called twice.");
    AVCaptureVideoDataOutput *videoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
    // `videoDataOutput.availableVideoCVPixelFormatTypes` returns the pixel formats supported by the
    // device with the most efficient output format first. Find the first format that we support.
    NSSet<NSNumber *> *supportedPixelFormats = [RTCCVPixelBuffer supportedPixelFormats];
    NSMutableOrderedSet *availablePixelFormats =
            [NSMutableOrderedSet orderedSetWithArray:videoDataOutput.availableVideoCVPixelFormatTypes];
    [availablePixelFormats intersectSet:supportedPixelFormats];
    NSNumber *pixelFormat = availablePixelFormats.firstObject;
    NSAssert(pixelFormat, @"Output device has no supported formats.");
    _preferredOutputPixelFormat = [pixelFormat unsignedIntValue];
    _outputPixelFormat = _preferredOutputPixelFormat;
    videoDataOutput.videoSettings = @{(NSString *)kCVPixelBufferPixelFormatTypeKey : pixelFormat};
    videoDataOutput.alwaysDiscardsLateVideoFrames = NO;
    [videoDataOutput setSampleBufferDelegate:self queue:self.frameQueue];
    _videoDataOutput = videoDataOutput;
}
- (void)updateVideoDataOutputPixelFormat:(AVCaptureDeviceFormat *)format {
    FourCharCode mediaSubType = CMFormatDescriptionGetMediaSubType(format.formatDescription);
    if (![[RTCCVPixelBuffer supportedPixelFormats] containsObject:@(mediaSubType)]) {
        mediaSubType = _preferredOutputPixelFormat;
    }
    if (mediaSubType != _outputPixelFormat) {
        _outputPixelFormat = mediaSubType;
        _videoDataOutput.videoSettings =
                @{ (NSString *)kCVPixelBufferPixelFormatTypeKey : @(mediaSubType) };
    }
}
#pragma mark - Private, called inside capture queue
- (void)updateDeviceCaptureFormat:(AVCaptureDeviceFormat *)format fps:(NSInteger)fps {
    @try {
        _currentDevice.activeFormat = format;
        _currentDevice.activeVideoMinFrameDuration = CMTimeMake(1, fps);
    } @catch (NSException *exception) {
        NSLog(@"Failed to set active format!\n User info:%@", exception.userInfo);
        return;
    }
}
- (void)reconfigureCaptureSessionInput {
    NSError *error = nil;
    AVCaptureDeviceInput *input =
            [AVCaptureDeviceInput deviceInputWithDevice:_currentDevice error:&error];
    if (!input) {
        NSLog(@"Failed to create front camera input: %@", error.localizedDescription);
        return;
    }
    [_captureSession beginConfiguration];
    for (AVCaptureDeviceInput *oldInput in [_captureSession.inputs copy]) {
        [_captureSession removeInput:oldInput];
    }
    if ([_captureSession canAddInput:input]) {
        [_captureSession addInput:input];
    } else {
        NSLog(@"Cannot add camera as an input to the session.");
    }
    [_captureSession commitConfiguration];
}
- (void)updateOrientation {
    _orientation = [UIDevice currentDevice].orientation;
}
@end
