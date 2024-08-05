#import <MillicastSDK/mc_logging.h>
#import <MillicastSDK/source.h>
#import <MillicastSDK/exports.h>

/// Class  used  for managing media sources.
MILLICAST_API @interface MCMedia : NSObject

/// Query all available video sources.
///  - Returns: An array of all available ``MCVideoSource``
+(NSArray<MCVideoSource*>*)getVideoSources;

/// Query all available audio sources.
///  - Returns: An array of all available ``MCAudioSource``
+(NSArray<MCAudioSource*>*)getAudioSources;

/// Query available audio playback devices and plugins.
/// - Returns: An array of all available ``MCAudioPlayback`` devices.
+(NSArray<MCAudioPlayback*>*)getPlaybackDevices;

/// Query a list of the supported video codecs.
/// - Returns: An array of all available video codecs on the platforms.
+ (NSArray<NSString*>*) getSupportedVideoCodecs;

/// Query a list of all the supported audio codecs
/// - Returns: An array of all available audio codecs.
+ (NSArray<NSString*>*) getSupportedAudioCodecs;

/// Checks whether NDI support is enabled in the SDK.
/// - Returns: Whether NDI is available (true) or not (false).
+(bool)isNdiAvailable;

@end
