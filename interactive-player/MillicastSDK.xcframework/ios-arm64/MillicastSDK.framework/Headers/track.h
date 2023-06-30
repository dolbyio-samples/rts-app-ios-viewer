/**
  * @file track.h
  * @author David Baldassin
  * @copyright Copyright 2021 CoSMoSoftware.
  * @date 02/2021
  */

#import <UIKit/UIKit.h>
#import <MillicastSDK/renderer.h>
#import <MillicastSDK/exports.h>

// Forward declarations ///////////////////////////////////////////////////////
@class MCVideoRenderer;
@class MCAudioRenderer;

// Track //////////////////////////////////////////////////////////////////////

/**
 * @brief The Track class represent a media sources.
 */

MILLICAST_API @interface MCTrack : NSObject

/**
 * @brief Get the track's id.
 * @return The track's id.
 */

 - (NSString *) getId;

/**
 * @brief Get the track's kind.
 * @return The track's kind. Either audio or video.
 */

- (NSString *) kind;

/**
 * @brief Tell whether the track is enabled or not.
 * @return true if the track is enabled, false otherwise.
 */

- (BOOL) isEnabled;

/**
 * @brief enable or disable the track.
 * A disabled track will produce silence (if audio) or black frames (if video).
 * Can be disabled and re-enabled.
 * @param e true to enable, false to disable.
 */

- (void) enable: (BOOL)e;

@end


// VideoTrack /////////////////////////////////////////////////////////////////

/**
 * @brief The VideoTrack class
 */

MILLICAST_API @interface MCVideoTrack : MCTrack

/**
 * @brief Add a VideoRenderer to render this video track.
 * Several renderers can be added to the track.
 * Each one will be called when a new frame is available.
 * @param renderer The video renderer.
 */

- (void) addRenderer: (id<MCVideoRenderer>) renderer;

/**
 * @brief Remove a renderer from the renderer list.
 * @param renderer The renderer to remove.
 */

- (void) removeRenderer: (id<MCVideoRenderer>) renderer;

@end


// AudioTrack /////////////////////////////////////////////////////////////////

/**
 * @brief The AudioTrack class
 */

MILLICAST_API @interface MCAudioTrack : MCTrack

/**
 * @brief Add an audio renderer to render this track.
 * Several renderers can be added to the track.
 * Each one will be called when a new frame is available.
 * @param renderer The audio renderer.
 */

- (void) addRenderer:(id<MCAudioRenderer>) renderer;

/**
 * @brief Remove a renderer from the renderer list.
 * @param renderer The renderer to remove.
 */

- (void) removeRenderer:(id<MCAudioRenderer>) renderer;

/**
 * @brief Set the volume of this track
 * @param volume The volume to set between 0 and 1
 * @warning Only affects remtoe track
 */

- (void) setVolume:(double) volume;

@end
