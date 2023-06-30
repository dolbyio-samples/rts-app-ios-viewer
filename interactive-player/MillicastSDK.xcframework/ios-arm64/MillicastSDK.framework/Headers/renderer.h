/**
  * @file renderer.h
  * @author David Baldassin
  * @copyright Copyright 2021 CoSMoSoftware.
  * @date 07/2021
  */

#import <MillicastSDK/capabilities.h>
#import <MillicastSDK/exports.h>
#import <MillicastSDK/frames.h>

// Video //////////////////////////////////////////////////////////////////////

/**
 * @brief The VideoRenderer protocol
 * Inherits this class to receive video frames and render them in your application.
 */

@protocol MCVideoRenderer <NSObject>

/**
 * @brief didReceiveVIdeoFrame is called when a new video frame is available
 * ( either captured or received from a peer )
 * @param frame The video frame
 */

- (void) didReceiveFrame:(id<MCVideoFrame>)frame;

@end

// Audio //////////////////////////////////////////////////////////////////////

/**
 * @brief The AudioRenderer protocol
 * inherits this if you want to render audio in a specific way in your application.
 * @remarks The recommended method to render audio is to use AudioPlayback
 * @see AudioPlayback
 */

@protocol MCAudioRenderer <NSObject>

/**
 * @brief didReceiveFrame is called when a new audio frame is available.
 * @param frame The audio frame.
 */

- (void) didReceiveFrame:(MCAudioFrame*) frame;

@end

// ndi ////////////////////////////////////////////////////////////////////////

/**
 * @brief The NdiRenderer interface is used to render video as an ndi source.
 * @remark For now, this class does not render audio,
 * use AudioPlayback with Ndi output instead.
 */

MILLICAST_API @interface MCNdiRenderer : NSObject <MCVideoRenderer>

/**
 * @brief Set the name of the ndi source.
 * This is the name that will be displayed to other ndi application when they
 * search for ndi sources.
 * @param name The name of the source.
 */

- (void) setName: (NSString*) name;


/**
 * @brief Create an Ndi renderer.
 * @return An Ndi renderer object.
 */

+ (MCNdiRenderer*) create;

@end

@protocol MCIosVideoRendererDelegate <NSObject>

- (void) didChangeVideoSize:(CGSize) size;

@end

/**
 * @brief The purpose of this interface is to render video frames in a UI view. (iOS and tvOS)
 */

MILLICAST_API @interface MCIosVideoRenderer : NSObject <MCVideoRenderer>

@property (nonatomic, assign) id<MCIosVideoRendererDelegate> delegate;

- (instancetype) initWithColorRangeExpansion: (BOOL) enable; /**< Initialize with the option of expanding limited color range to full range upon rendering.*/
- (UIView*) getView; /**< Get the view in which are rendered video frame so you can add it in your UI.*/
- (float) getWidth; /**< Get the width of the WebRTC video frame.*/
- (float) getHeight; /**< Get the height of the WebRTC video frame.*/
@end
