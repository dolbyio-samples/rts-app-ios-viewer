/**
 * @file media.h
 * @author David Baldassin
 * @copyright Copyright 2021 CoSMoSoftware.
 * @date 07/2021
 */

#import <MillicastSDK/mc_logging.h>
#import <MillicastSDK/source.h>
#import <MillicastSDK/exports.h>

/**
 * @brief The Media class is used to manage media sources.
 */

MILLICAST_API @interface MCMedia : NSObject

/**
 * @brief getVideoSources get all the available video source (device, desktop, ...)
 * @see MCVideoSource
 * @return An array of all found video source
*/

+(NSArray<MCVideoSource*>*)getVideoSources;

/**
* @brief getAudioSources get all the available audio source (device, ndi, ...)
* @see MCAudioSource
* @return An array of all found audio source
*/

+(NSArray<MCAudioSource*>*)getAudioSources;

/**
 * @brief getPlaybackDevices, get all the available audio playback (device, ndi, ...)
 * @see MCAudioPlayback
 * @return An array of all found audio playback devices
*/

+(NSArray<MCAudioPlayback*>*)getPlaybackDevices;

/**
 * @brief getSupportedVideoCodecs returns the list of the supported video codecs.
 * @return The list of the supported video codecs.
 */

+ (NSArray<NSString*>*) getSupportedVideoCodecs;

/**
 * @brief getSupportedAudioCodecs returns the list of the supported audio codecs.
 * @return The list of the supported audio codecs.
 */

+ (NSArray<NSString*>*) getSupportedAudioCodecs;

/**
 * @brief isNdiAvailable, check if ndi support is enabled in the sdk
 * @return true if ndi is available false otherwise.
*/

+(bool)isNdiAvailable;


@end
