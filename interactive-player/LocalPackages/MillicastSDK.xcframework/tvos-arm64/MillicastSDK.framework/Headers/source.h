/**
  * @file source.h
  * @author David Baldassin
  * @copyright Copyright 2021 CoSMoSoftware.
  * @date 07/2021
  */

#import <CoreVideo/CoreVideo.h>
#import <CoreMedia/CoreMedia.h>

#import <MillicastSDK/mc_logging.h>
#import <MillicastSDK/capabilities.h>
#import <MillicastSDK/exports.h>
#import <MillicastSDK/frames.h>

// Forward declarations ///////////////////////////////////////////////////////
@class MCTrack;


// Source /////////////////////////////////////////////////////////////////////

#ifdef __cplusplus
/// The Source type
enum MCSourceType {
  /// Hardware sources, camera, playback devices.
  MC_DEVICE,
  /// Fullscreen capture source.
  MC_MONITOR,
  /// Application screen capture source
  MC_APP,
  /// Microphone devices source
  MC_MIC,
  /// Ndi sources (input and output).
  MC_NDI,
  /// DeckLink devices sources (input and output).
  MC_DECKLINK,
  /// Custom audio source.
  MC_CUSTOM,
};
#else
/// The Source type
typedef enum {
  /// Hardware sources, camera, playback devices.
  MC_DEVICE,
  /// Fullscreen capture source.
  MC_MONITOR,
  /// Application screen capture source
  MC_APP,
  /// Microphone devices source
  MC_MIC,
  /// Ndi sources (input and output).
  MC_NDI,
  /// DeckLink devices sources (input and output).
  MC_DECKLINK,
  /// Custom audio source.
  MC_CUSTOM,
} MCSourceType;
#endif

/// Gathers information about the source.
MILLICAST_API @interface MCSource : NSObject

/// Gets the source type.
/// - Returns: The ``MCSourceType`` source type.
- (MCSourceType) getType;

/// Gets the name of the source.
/// - Returns: The source name.
- (NSString*) getName;

/// Gets the unique identifier of the source.
/// - Returns: The unique identifier of the source.
- (NSString*) getUniqueId;

/// Gets the video source type as a NSString.
/// - Returns: the source type as a string. See ``MCSourceType``
- (NSString*) getTypeAsString;

@end

/// Responsible for building a source object.
MILLICAST_API @interface MCSourceBuilder : NSObject

/// Sets the type of media source to be created, either video or audio.
/// - Parameters:
///   - type: The type of the source you are building.
- (void) setType:(MCSourceType) type;

/// Set a name to the media source.
/// - Parameters:
///   - name: Name of the source.
- (void) setName:(NSString *) name;

/// Set a unique identifier to the source.
/// - Parameters:
///   - type: A unique ID.
- (void) setUniqueId:(NSString*) type;

@end

/// Manages the process of capturing the source by input sources, such as a microphone or a camera.
@protocol CaptureSource <NSObject>

/// Initiates and starts the capture device and creates
/// the corresponding track. You should not call start capture twice in a row.
/// - Returns: The track corresponding to this source.
- (MCTrack *) startCapture;

/// Stops a capture and releases the track and the underlying devices.
- (void) stopCapture;

/// Checks the current state of the capture process.
/// - Returns: A boolean value indicating whether the source is currently capturing (true) or not (false).
- (bool) isCapturing;

@end

/// Responsible for managing playback devices.
@protocol PlaybackSource <NSObject>

/// Initializes the playback device.
- (void) initPlayback;

/// Checks whether the playback device is currently playing media (true) or not (false).
/// - Returns: True if playing. False otherwise.
- (bool) isPlaying;

@end

// Video //////////////////////////////////////////////////////////////////////

/// Responsible for managing video sources.
MILLICAST_API @interface MCVideoSource : MCSource <CaptureSource>

/// The current set of capabilities configured for the video source.
/// - Returns: An array of video capabilities of the video device.
- (NSArray<MCVideoCapabilities*>*) getCapabilities;

/// Enable a specific video capability on the video source.
/// - Parameters:
///   - cap: The video capability.
- (void) setCapability:(MCVideoCapabilities*) cap;

/// Change the underlying video source. For example in the case of a Camera, switch
/// between front/rear camera.
/// - Parameters:
///   - ascending: The direction in which to switch the sources.
- (void) changeVideoSource: (bool) ascending;

/// Changes the current video source to a new source based on the provided device ID, for example
/// if there is an external camera connected and a device ID is known.
/// - Parameters:
///   - ascending: The direction in which to switch the sources.
///   - deviceId: The device ID.
- (void) changeVideoSource: (bool) ascending : (NSString*) deviceId;

@end

/// Responsible for building a video source object.
@interface MCVideoSourceBuilder : MCSourceBuilder

/// Sets capabilities for the video source.
- (void) setCapabilities:(NSArray<MCVideoCapabilities*>*) capabilities;

/// Builds the VideoSource class.
/// - Returns: a new video source.
- (MCVideoSource*) build;

@end

// Audio //////////////////////////////////////////////////////////////////////

/// Manages audio settings.
@protocol MCAudioControl <NSObject>

/// Adjusts the microphone or speaker volume.
/// - Parameters:
///   - v:  The volume level between 0 (mute) and 1 (full volume).
- (void) setVolume:(uint32_t) v;

/// Sets the number of channels to use.
/// - Parameters:
///   -  channel: The number of channels to use.
- (void) setNumChannel:(uint8_t) channel;

/// Mutes the microphone or the speakers.
/// - Parameters:
///   - m: A boolean indicating whether the audio source should be muted (true) or not (false).
- (void) mute:(bool) m;

/// Gets the current volume.
/// - Returns: The current volume level.
- (uint32_t) getVolume;

/// Checks whether the microphone or speaker is muted or not.
/// - Returns: A boolean indicating whether the audio source is muted (true) or not (false).
- (bool) isMuted;

@end

/// Manages the audio capture functionality.
MILLICAST_API @interface MCAudioSource : MCSource <CaptureSource, MCAudioControl>

/// Initiates the audio capture process from the current source.
/// - Returns: An audio track. See ``MCPublisher/addTrackWithAudioTrack:completionHandler:`` to see
/// how you can use this class.
- (MCTrack*) startCapture;

/// Stops the audio capture process.
- (void) stopCapture;

/// Checks whether the AudioSource instance is currently actively capturing audio.
/// - Returns: True if the audio source is capturing. False otherwise.
- (bool) isCapturing;

@end

/// Responsible for building AudioSource.
@interface MCAudioSourceBuilder : MCSourceBuilder

/// Builds the AudioSource class.
/// - Returns: A new audio source.
- (MCAudioSource*) build;

@end

/// Provides functionalities for managing audio playback.
/// This class inherits the Source class, however this is not
/// a capture source.
MILLICAST_API @interface MCAudioPlayback : MCSource <PlaybackSource, MCAudioControl>

/// Initializes the playback device.
- (void) initPlayback;

/// Checks whether the playback device is playing.
/// - Returns: True if the device is playing, false otherwise.
- (bool) isPlaying;

@end

/// Responsible for building AudioPlayback.
MILLICAST_API @interface MCAudioPlaybackBuilder : MCSourceBuilder

/// Builds the AudioPlayback class.
/// - Returns a new audio playback device.
- (MCAudioPlayback*) build;
@end

/// A custom audio source that can be fed any raw audio data for publishing.
MILLICAST_API @interface MCCustomAudioSource : MCSource

/// Starts capture. Effectively creates an audio track that can be added to the publisher.
/// - Returns: An audio track. See ``MCPublisher/addTrackWithAudioTrack:completionHandler:``
/// to learn how to attach this track to a publisher.
- (MCTrack*) startCapture;


/// To be called whenever the application wishes to feed audio frames to the source.
/// - Parameters:
///   - frame: An audio frame to feed. See ``MCAudioFrame`` and ``MCCMSampleBufferFrame`` for
///   possible audio frames to feed. Currently only 48kHz and 44.1kHz are supported sample formats.
- (void) onAudioFrame: (MCAudioFrame*) frame;

/// Query whether the source is currently capturing.
/// - Returns: True if the application is capturing, false otherwise.
- (bool) isCapturing;

/// Stops the underlying audio tracks and informs the SDK to stop any pending operations related to this custom source.
- (void) stopCapture;

@end

/// Responsible for building MCCustomAudioSource.
MILLICAST_API @interface MCCustomAudioSourceBuilder : MCSourceBuilder
/// Builds the MCCustomAudioSource class.
/// - Returns: A new custom audio source.
- (MCCustomAudioSource*) build;
@end

/// A Source that allows applications to feed their own raw CVPixelBuffers for publishing.
MILLICAST_API @interface MCCoreVideoSource : MCSource

/// Starts capture. Effectively creates a video track that can be added to the publisher.
/// - Returns: A video track. See ``MCPublisher/addTrackWithVideoTrack:completionHandler:``
/// to learn how to attach this track to a publisher.
- (MCTrack*) startCapture;

/// To be called whenever the application wishes to feed a CVPixelBuffer to the source.
/// This API does not copy the CVPixelBuffer if using H.264, which is hardware accelerated on Apple platforms.
/// If using codecs other than H.264, an internal copy of the frame will occur.
/// - Parameters:
///   - pixelBuffer: ACVPixelBufferRef reference. The reference will be retained/decremented internally.
- (void) onPixelBuffer:(CVPixelBufferRef) pixelBuffer;

/// To be called whenever the application wishes to feed a CVPixelBuffer to the source along with a timestamp.
/// - Parameters:
///   - pixelBuffer: A CVPixelBufferRef. The reference will be retained/decremented internally.
///   - timestamp: The timestamp to the given frame. Will act as a capture timestamp.
- (void) onPixelBuffer:(CVPixelBufferRef) pixelBuffer withTimestamp: (CMTime) timestamp;

/// Query whether the source is currently capturing.
/// - Returns: True if the application is capturing, false otherwise.
- (bool) isCapturing;

/// Stops capturing video.
- (void) stopCapture;

@end

/// Responsible for building a CoreVideoSource.
MILLICAST_API @interface MCCoreVideoSourceBuilder : MCSourceBuilder

/// Builds the CoreVideoSource class.
/// - Returns: A new core video source.
- (MCCoreVideoSource*) build;
@end
