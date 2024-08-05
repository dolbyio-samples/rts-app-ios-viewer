#import <AVFoundation/AVFoundation.h>

#import <MillicastSDK/capabilities.h>
#import <MillicastSDK/exports.h>
#import <MillicastSDK/frames.h>

/// This protocol can be used to implement objects that receive video frames in your
/// applications. Used in ``MCVideoTrack/addRenderer:`` to start receiving
/// video frames from that video track.
@protocol MCVideoRenderer <NSObject>


/// This handler is called when a new video frame becomes available, either captured or received.
/// - Parameters:
///   - frame: A raw video frame.
- (void) didReceiveFrame:(id<MCVideoFrame>)frame;

@end

// Audio //////////////////////////////////////////////////////////////////////

/// This protocol can be implemented to receive audio frames from audio tracks. However,
/// The recommended method to render audio is to use ``MCAudioPlaback`` instead.
/// See ``MCAudioTrack/addRenderer:`` to attach an audio renderer.
@protocol MCAudioRenderer <NSObject>

/// This handler is called when a new audio frame is available.
/// - Parameters:
///   - frame: A raw audio frame.
- (void) didReceiveFrame:(MCAudioFrame*) frame;

@end

/// The  class is responsible for rendering video as an NDI source. To render audio with NDI, use
/// ``MCAudioPlayback`` with the NDI output instead.
MILLICAST_API @interface MCNdiRenderer : NSObject <MCVideoRenderer>

/// Sets the name of the NDI source.
/// - Parameters:
///   - name: The name that will be displayed to other NDI applications
/// when they search for NDI sources.
- (void) setName: (NSString*) name;

/// Creates an NDI renderer.
/// - Returns: An NDI renderer.
+ (MCNdiRenderer*) create;

@end
