#import <ReplayKit/ReplayKit.h>
#import <MillicastSDK/exports.h>
#import <MillicastSDK/source.h>
#import <MillicastSDK/track.h>

/**
 * @brief a Millicast App Screen Capture Source. It internally uses ReplayKit to capture the screen 
 * of the application. 
 * */
MILLICAST_API @interface MCAppShareSource: NSObject
@property(nonatomic, readonly) NSString * _Nonnull name;
-(nonnull instancetype) initWithRecorder:(RPScreenRecorder  * _Nonnull) recorder;
-(nonnull instancetype) initWithName: (NSString  * _Nonnull ) name recorder: (RPScreenRecorder * _Nonnull) recorder;
-(void) startCaptureWithCompletionHandler: (nonnull void (^)(MCAudioTrack * _Nullable audioTrack, MCVideoTrack * _Nullable videoTrack, NSError * _Nullable))completionHandler;
-(void) stopCaptureWithCompletionHandler: (nonnull void (^)(NSError * _Nullable))completionHandler;
@end
