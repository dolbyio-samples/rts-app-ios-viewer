#import <MillicastSDK/renderer.h>

/**
 * @brief a CMSampleBuffer receiving delegate.
 */
MILLICAST_API @protocol MCCMSampleBufferVideoRendererDelegate 

/**
 * @brief return true to accept a sample buffer, otherwise, the frame will be dropped.
 */
- (bool) canHandleMoreFrames;

/*
 * @brief this delegate will receive CMSampleBufferRef once
 * attached to a CMSampleBufferVideoRenderer.
 * @param buffer a reference to a CMSampleBuffer
 */
- (void) didReceiveSampleBuffer:(CMSampleBufferRef) buffer;
/*
 * @brief this delegate will be called when the size of the incoming video
 * frames have changed.
 */
- (void) didChangeSize:(CGSize) size;
@end

/**
 * @brief CMSampleBuffer renderer.
 */
MILLICAST_API @interface MCCMSampleBufferVideoRenderer : NSObject<MCVideoRenderer>
@property(atomic, weak) id<MCCMSampleBufferVideoRendererDelegate> delegate;
@property(atomic, readonly) float width /**< The width of the rendered video frame*/;
@property(atomic, readonly) float height /**< The height of the rendered video frame*/;

/**
 * @brief initialize the renderer with a delegate.
 */
- (instancetype) initWithDelegate: (id<MCCMSampleBufferVideoRendererDelegate>) delegate;

/**
 * @brief initialize the renderer
 */
- (instancetype) init;
@end
