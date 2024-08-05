#import <MillicastSDK/renderer.h>

/// Delegate for  receiving raw video ``CMSampleBufferRef`` ready for rendering
MILLICAST_API @protocol MCCMSampleBufferVideoRendererDelegate

/// Implement this method and return true to accept a sample buffer. Otherwise, the frame is dropped.
- (bool) canHandleMoreFrames;

/// A delegate method that will receive CMSampleBufferRef that contain raw video ready for rendering.
/// - Parameters:
///   - buffer: A reference to a CMSampleBuffer.
- (void) didReceiveSampleBuffer:(CMSampleBufferRef) buffer;


/// A delegate method that will be called when the size of the incoming video frames has changed.
/// - Parameters:
///   - size: The new video frame size.
- (void) didChangeSize:(CGSize) size;
@end

/// This class is responsible for converting ``MCVideoFrame``  into renderable ``CMSampleBufferRef`` frames.
MILLICAST_API @interface MCCMSampleBufferVideoRenderer : NSObject<MCVideoRenderer>

/// Delegate that will receive ``CMSampleBufferRef`` frames.
@property(atomic, weak) id<MCCMSampleBufferVideoRendererDelegate> delegate;

/// The width of the last video frame received.
@property(atomic, readonly) float width;

/// The height of the last video frame received.
@property(atomic, readonly) float height;

/// Initialize the renderer with a Delegate for receiving  ``CMSampleBufferRef``
- (instancetype) initWithDelegate: (id<MCCMSampleBufferVideoRendererDelegate>) delegate;

/// Initialize the renderer.
- (instancetype) init;
@end
