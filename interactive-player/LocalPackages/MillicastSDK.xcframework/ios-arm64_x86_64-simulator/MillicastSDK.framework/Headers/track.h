#import <MillicastSDK/renderer.h>
#import <MillicastSDK/exports.h>

// Forward declarations ///////////////////////////////////////////////////////
@class MCVideoRenderer;
@class MCAudioRenderer;

/// Represents a captured instance of a media source.
MILLICAST_API @interface MCTrack : NSObject

/// Get the track Id.
/// - Returns: The track ID.
- (NSString *) getId;

/// Get  the track type.
/// - Returns: The track type, either audio or video.
- (NSString *) kind;

/// Checks whether the track is enabled or not.
/// - Returns: True if the track is enabled, false otherwise.
- (BOOL) isEnabled;


/// Enables or disables the track. A disabled audio track produces silence. A disabled video track produces black frames.
/// - Parameters:
///   - e: True to enable the track, false otherwise.
- (void) enable: (BOOL)e;

@end

/// Responsible for managing video capture session from a video source.
MILLICAST_API @interface MCVideoTrack : MCTrack

/// Adds a VideoRenderer to render this video track.
/// Several renderers can be added to the track.
/// Each one will be called when a new frame becomes available.
/// - Parameters:
///   - renderer: The video renderer that will receive captured video frames.
- (void) addRenderer: (id<MCVideoRenderer>) renderer;

/// Removes a renderer from the list.
/// - Parameters:
///   - renderer: The renderer to remove.
- (void) removeRenderer: (id<MCVideoRenderer>) renderer;

@end


/// Manages and plays a single audio resource.
MILLICAST_API @interface MCAudioTrack : MCTrack

/// Adds an audio renderer to render this track.
/// Several renderers can be added to the track.
/// Each one will be called when a new frame becomes available.
/// - Parameters:
///   - renderer: The audio renderer to add.
- (void) addRenderer:(id<MCAudioRenderer>) renderer;

/// Removes a renderer from the list.
/// - Parameters:
///   - renderer: The renderer to remove.
- (void) removeRenderer:(id<MCAudioRenderer>) renderer;


/// Sets the volume of the remote audio track.
/// - Parameters:
///   - volume: The volume level between 0 (mute) and 1 (full volume).
- (void) setVolume:(double) volume;

@end
