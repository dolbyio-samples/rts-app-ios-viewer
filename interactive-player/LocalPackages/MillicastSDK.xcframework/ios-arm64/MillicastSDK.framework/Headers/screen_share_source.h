#import <ReplayKit/ReplayKit.h>
#import <MillicastSDK/exports.h>
#import <MillicastSDK/source.h>
#import <MillicastSDK/track.h>

/// Uses Replaykit to capture the screen of the application.
MILLICAST_API @interface MCAppShareSource: NSObject
@property(nonatomic, readonly) NSString * _Nonnull name;


/// Initializes the source with a recorder.
/// - Parameters:
///   - recorder: A ReplayKit recorder.
-(nonnull instancetype) initWithRecorder:(RPScreenRecorder  * _Nonnull) recorder;

/// Initializes the source with a name to identify the source.
/// - Parameters:
///   - recorder: A ReplayKit recorder.
///   - name: The source name
-(nonnull instancetype) initWithName: (NSString  * _Nonnull ) name recorder: (RPScreenRecorder * _Nonnull) recorder;

/// Start capturing the application screen.
/// - Parameters:
///   - completionHandler: handler that is invoked when the result is ready.
///   The capture process produces an audio track and a video track if successful. See
///   ``MCPublisher/addTrackWithAudioTrack:completionHandler:`` and
///   ``MCPublisher/addTrackWithVideoTrack:completionHandler:`` to attach
///   those tracks to a publisher.
-(void) startCaptureWithCompletionHandler: (nonnull void (^)(MCAudioTrack * _Nullable audioTrack, MCVideoTrack * _Nullable videoTrack, NSError * _Nullable))completionHandler;


/// Stops capturing the application screen.
/// - Parameters:
///   - completionHandler: handler that is invoked when the result is ready.
-(void) stopCaptureWithCompletionHandler: (nonnull void (^)(NSError * _Nullable))completionHandler;
@end
