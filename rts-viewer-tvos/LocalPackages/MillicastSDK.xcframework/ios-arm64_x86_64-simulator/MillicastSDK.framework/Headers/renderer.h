/**
  * @file renderer.h
  * @author David Baldassin
  * @copyright Copyright 2021 CoSMoSoftware.
  * @date 07/2021
  */
#import <AVFoundation/AVFoundation.h>

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
