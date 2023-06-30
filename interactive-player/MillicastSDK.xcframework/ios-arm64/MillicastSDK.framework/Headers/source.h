/**
  * @file source.h
  * @author David Baldassin
  * @copyright Copyright 2021 CoSMoSoftware.
  * @date 07/2021
  */

#import <MillicastSDK/mc_logging.h>
#import <MillicastSDK/capabilities.h>
#import <MillicastSDK/exports.h>
#import <MillicastSDK/frames.h>

// Forward declarations ///////////////////////////////////////////////////////
@class MCTrack;


// Source /////////////////////////////////////////////////////////////////////

/**
 * @brief The Source type
 */

#ifdef __cplusplus
enum MCSourceType {
  MC_DEVICE, /**< Hardware sources, camera, playback devices, ... */
  MC_MONITOR, /**< Fullscreen capture source */
  MC_APP, /**< Application screen capture source */
  MC_MIC, /**< Microphone devices source */
  MC_NDI, /**< Ndi sources (input and output) */
  MC_DECKLINK, /**< DeckLink devices sources (input and output) */
  MC_CUSTOM
};
#else
typedef enum {
  MC_DEVICE, /**< Hardware sources, camera, playback devices, ... */
  MC_MONITOR, /**< Fullscreen capture source */
  MC_APP, /**< Application screen capture source */
  MC_MIC, /**< Microphone devices source */
  MC_NDI, /**< Ndi sources (input and output) */
  MC_DECKLINK, /**< DeckLink devices sources (input and output) */
  MC_CUSTOM
} MCSourceType;
#endif

/**
 * @brief The Source base class.
 */

MILLICAST_API @interface MCSource : NSObject

/**
 * @brief Get the source type
 * @return the type. See MCSourceType
 */
- (MCSourceType) getType;

/**
 * @brief Get the name of the source
 * @return the name as a NSString
 */
- (NSString*) getName;

/**
 * @brief Get the unique identifier of the source.
 * @return the unique identifier of the source
 */
- (NSString*) getUniqueId;


/**
 * @brief Get the video source's type as a NSString
 */

- (NSString*) getTypeAsString;

@end

/**
 * @brief The source builder is used to build a source object.
 */

MILLICAST_API @interface MCSourceBuilder : NSObject

- (void) setType:(MCSourceType) type;
- (void) setName:(NSString *) name;
- (void) setUniqueId:(NSString*) type;

@end

@protocol CaptureSource <NSObject>

/**
 * @brief Start a capture from this source,
 * this will init and start the capture device and create
 * the corresponding track.
 * @return The track corresponding to this source.
 */

- (MCTrack *) startCapture;

/**
 * @brief Stop a capture adn release the track and the underlying devices.
 * @return The track corresponding to this source.
 */

- (void) stopCapture;

/**
 * @brief Tell is the source is currently capturing.
 * @return true is the source is capturing, false otherwise.
 */

- (bool) isCapturing;

@end

@protocol PlaybackSource <NSObject>

/**
 * @brief Init the playback device
 */

- (void) initPlayback;

/**
 * @return true if something is played on the device, false otherwise
 */
- (bool) isPlaying;

@end

// Video //////////////////////////////////////////////////////////////////////

/**
 * @brief The VideoSource class
 */

MILLICAST_API @interface MCVideoSource : MCSource <CaptureSource>

- (NSArray<MCVideoCapabilities*>*) getCapabilities;
- (void) setCapability:(MCVideoCapabilities*) cap;
- (void) changeVideoSource: (bool) ascending;
- (void) changeVideoSource: (bool) ascending : (NSString*) deviceId;

@end

@interface MCVideoSourceBuilder : MCSourceBuilder

- (void) setCapabilities:(NSArray<MCVideoCapabilities*>*) capabilities;
- (MCVideoSource*) build;

@end

// Audio //////////////////////////////////////////////////////////////////////

/**
 * @brief The AudioControl class
 */

@protocol MCAudioControl <NSObject>

/**
 * @brief Set the microphone / speaker volume.
 * @param v The volume as an integer.
 */

- (void) setVolume:(uint32_t) v;

/**
 * @brief Set the number of channels to use
 * @param n The number of channels.
 * Possible values are 1 or 2.
 */

- (void) setNumChannel:(uint8_t) channel;

/**
 * @brief Mute the microphone or the speakers.
 * @param m true if you want to mute, false if you want to unmute
 */

- (void) mute:(bool) m;

/**
 * @brief Get the current volume.
 * @return The current volume.
 */

- (uint32_t) getVolume;

/**
 * @brief Tell whether the mic / speaker is muted or not.
 * @return true if muted, false otherwise.
 */

- (bool) isMuted;

@end


/**
 * @brief The AudioSource class
 */

MILLICAST_API @interface MCAudioSource : MCSource <CaptureSource, MCAudioControl>

- (MCTrack*) startCapture;
- (void) stopCapture;
- (bool) isCapturing;

@end

@interface MCAudioSourceBuilder : MCSourceBuilder
- (MCAudioSource*) build;
@end

/**
 * @brief The AudioPlayback class
 * @remark This class inherits the Source class, however this is not
 * a capture source. That is why most of the capture interface is overrided
 * in private here.
 */

MILLICAST_API @interface MCAudioPlayback : MCSource <PlaybackSource, MCAudioControl>

/**
 * @brief Init the playback device.
 */

- (void) initPlayback;

/**
 * @brief Tell if the playback device is playing
 * @return true if it is playing, false otherwise
 */
- (bool) isPlaying;

@end

MILLICAST_API @interface MCAudioPlaybackBuilder : MCSourceBuilder
- (MCAudioPlayback*) build;
@end

MILLICAST_API @interface MCCustomSource : MCSource

/**
 * @brief Create the video track
 * @return The video track
 */
- (MCTrack*) startVideoCapture;

/**
 * @brief Create the audio track
 * @return The audio track
 */
- (MCTrack*) startAudioCapture;

/**
 * @brief Call this at the video frame rate to provide your own video frame
 * @param frame The video Frame.
 */
- (void) onVideoFrame:(id<MCVideoFrame>) frame;

/**
 * @brief Call this to provide your own audio data
 * @param frame The audio frame (chunk of audio).
 */
- (void) onAudioFrame:(MCAudioFrame*) frame;

- (bool) isCapturing;

- (void) stopCapture;

@end

MILLICAST_API @interface MCCustomSourceBuilder : MCSourceBuilder
- (MCCustomSource*) build;
@end
