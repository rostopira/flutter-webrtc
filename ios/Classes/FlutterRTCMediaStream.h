#import <Foundation/Foundation.h>
#import "MyCameraCapturer.h"
#import "FlutterWebRTCPlugin.h"

@interface FlutterWebRTCPlugin (RTCMediaStream)

+(MyCameraCapturer *)getCameraCapturer;

-(void)getUserMedia:(NSDictionary *)constraints
             result:(FlutterResult)result;

-(void)getDisplayMedia:(NSDictionary *)constraints
             result:(FlutterResult)result;

-(void)getSources:(FlutterResult)result;

-(void)mediaStreamTrackSwitchCamera:(RTCMediaStreamTrack *)track
                             result:(FlutterResult) result;

-(void)mediaStreamTrackAdaptRes:(RTCMediaStreamTrack *)track height:(NSNumber *)height width:(NSNumber *)width result:(FlutterResult)result;
@end


