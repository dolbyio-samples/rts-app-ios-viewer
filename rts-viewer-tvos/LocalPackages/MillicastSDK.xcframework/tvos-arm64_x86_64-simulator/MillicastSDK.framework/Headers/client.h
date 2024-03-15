/**
 * @file client.h
 * @author David Baldassin
 * @copyright Copyright 2021 CoSMoSoftware.
 * @date 07/2021
 */

#import <Foundation/Foundation.h>
#import <MillicastSDK/exports.h>

// Forward declaration
@class MCStatsReport;

/**
 * @brief The DegradationPreferences enum
 * @brief Based on the spec in https://w3c.github.io/webrtc-pc/#idl-def-rtcdegradationpreference.
 */
typedef NS_ENUM(NSInteger, MCDegradationPreferences)
{
  DISABLED,            /**< Don't take any actions based on over-utilization signals. */
  MAINTAIN_RESOLUTION, /**< On over-use, request lower frame rate, possibly causing frame drops. */
  MAINTAIN_FRAMERATE,  /**< On over-use, request lower resolution, possibly causing down-scaling. */
  BALANCED,            /**< Try to strike a "pleasing" balance between frame rate or resolution. */
  DEFAULT              /**< No degradation preference, let the SDK decide how to handle over-utilization. */
};

/**
 * @brief Settings for the minimum, maximum and start bitrates of the streams.
 */

MILLICAST_API @interface MCBitrateSettings : NSObject
@property(nonatomic) BOOL      disableBWE;
@property(nonatomic) NSInteger maxBitrateKbps;   /** The minimum bitrate in kilobits per second */
@property(nonatomic) NSInteger minBitrateKbps;   /** The maximum bitrate in kilobits per second */
@property(nonatomic) NSInteger startBitrateKbps; /** The start bitrate in kilobits per second */
@end

/**
 * @brief The Client Delegate protocol which contains methods that will be called
 * on specific events from a Client object.
 */

@protocol MCDelegate <NSObject>

/**
 * @brief onConnected is called when the WebSocket connection to Millicast is opened
 */
- (void)onConnected;

/**
 * @brief onDisconnected is called when the WebSocket connection to Millicast is
 * closed. If this was an unintended disconnect, a reconnect attempt will happen
 * automatically by default. To turn off the automatic reconnect, set {@ref
 * Option#autoReconnect} to false.
 */
- (void)onDisconnected;

/**
 * @brief onConnectionError is called when the attempt to connect to Millicast failed.
 * @param status The HTTP status code.
 * @param reason The reason the connection attempt failed.
 */
- (void)onConnectionError:(int)status withReason:(nonnull NSString *)reason;

/**
 * @brief Called when an error message in received from Millicast in response of a websocket command
 * @param message The recevied error message
 */
- (void)onSignalingError:(nonnull NSString *)message;

/**
 * @brief onStatsReport is called when a new rtc stats report has been collected.
 * @remarks You must enable the stats to be able to receive a report.
 * @see enableStats
 */
- (void)onStatsReport:(nonnull MCStatsReport *)report;

/**
 * @brief Called when a new viewer join the stream or when a viewer quit the stream
 * @param count The current number of viewers.
 */
- (void)onViewerCount:(int)count;

@end

// Scalability mode ///////////////////////////////////////////////////////////

/**
 * @brief MCScalabilityMode refers to Scalable Video Coding
 * @remark only for publishing
 * @remark please refer to https://www.w3.org/TR/webrtc-svc/#scalabilitymodes* to understand where these values are from
 */
typedef NS_ENUM(NSInteger, MCScalabilityMode)
{
  NONE,
  L1T2,
  L1T2h,
  L1T3,
  L1T3h,
  L2T1,
  L2T1h,
  L2T1_KEY,
  L2T2,
  L2T3,
  L2T2h,
  L2T2_KEY,
  L2T2_KEY_SHIFT,
  L2T3h,
  L3T1,
  L3T2,
  L3T3,
  L3T3_KEY,
  S2T1,
  S2T2,
  S2T3,
  S3T1,
  S3T2,
  S3T3,
  S2T1h,
  S2T2h,
  S2T3h,
  S3T1h,
  S3T2h,
  S3T3h
};

/**
 * @brief MCConnectionOptions provides options while connecting
 */
MILLICAST_API @interface MCConnectionOptions: NSObject

/** @brief Attempt to reconnect by default in case of connection error/network dropout. Enabled by default */
@property(nonatomic, assign) BOOL autoReconnect;

@end

MILLICAST_API @interface MCClientOptions : NSObject

/* multisource options */

/**
 * @brief The id/name of the sourceyou want to publish
 * @remark only for publishing
 */
@property(nonatomic, retain, nullable) NSString *sourceId;
/**
 * @brief the receiving source you want to pin
 * @remark only for subscribing
 */
@property(nonatomic, retain, nullable) NSString *pinnedSourceId;
/**
 * @brief the sources you don't want to receive
 * @remark only for subscribing
 */
@property(nonatomic, retain, nullable) NSArray *excludedSourceId;
/** @brief enable discontinuous transmission on the publishing side, so audio data is only sent when a user’s voice is detected. */
@property(nonatomic, assign) BOOL dtx;
/**
 * @brief the number of multiplxed audio tracks you want to receive
 * @remark only for subscribing
 */
@property(nonatomic, assign) int multiplexedAudioTrack;

/* Codecs options (for the publisher only) */
/**
 * @brief The video codec to use
 * @remark only for publishing
 */
@property(nonatomic, retain, nullable) NSString *videoCodec;
/**
 * @brief The audio codec to use
 * @remark only for publishing
 */
@property(nonatomic, retain, nullable) NSString *audioCodec;

/* General connection options */
/** @brief Which strategy the use in order to limit the bandwidth usage */
@property(nonatomic, assign) MCDegradationPreferences degradationPreferences;

/**
 * @brief Determines the minimum, maximum and start bitrates
 * @remark only for publishing
 */
@property(nonatomic, retain, nullable) MCBitrateSettings *bitrateSettings;

/**
 * @brief Enable / disable stereo
 * @remark only for publishing
 */
@property(nonatomic, assign) BOOL stereo;

/** @brief Enable the rate at which you want to receive stats report */
@property(nonatomic, assign) int statsDelayMs;

/**
 * @brief The minimum video jitter buffer delay in milliseconds. Defaults to 0
 * @remark only for subscribing
 */
@property(nonatomic, assign) int videoJitterMinimumDelayMs;

/**
 * @brief Force the playout delay to be 0. This asks the media server to remove any delay when processing frames
 * @remark only for subscribing
 */
@property(nonatomic, assign) BOOL forcePlayoutDelay;

/**
 * @brief Disable receiving audio completely. This should help reduce A/V sync related delays for video only streams
 * @remark only for publishing
 */
@property(nonatomic, assign) BOOL disableAudio;

/** @brief Scalable Video Coding selection.
 * @remark Refer to https://www.w3.org/TR/webrtc-svc/#scalabilitymodes* to learn which modes are supported by which codecs.
 * @remark only for publishing
 */
@property(nonatomic, assign) MCScalabilityMode svcMode;

/**
 * @brief Enable simulcast
 * @remark This is only applicable to VP8 and H264
 * @remark only for publishing.
 * @remark Disabled by default
 */
@property(nonatomic, assign) BOOL simulcast;

/** @brief Enable logging RTC Event Log into a file. Provide the full path */
@property(nonatomic, retain, nullable) NSString *rtcEventLogOutputPath;


/**
 * @brief Enable recording immediately after publishing
 * @remark Only for publishing
 * @remark Make sure the recording feature is enabled for the publisher token
 * @remark Disabled by default
 *
 */
@property(nonatomic,assign) BOOL recordStream;

/* @brief Priority of published stream */
@property(nonatomic, assign, nullable) NSNumber *priority;

@end

/**
 * @brief The Client base class.
 * @brief This is the base class to handle a connection with the Millicast platform.
 */

MILLICAST_API @protocol MCClient

/**
 * @brief Connect and open a websocket connection with the Millicast platform.
 * @param completionHandler handler invoked when the result is ready
 * @remarks You must set valid credentials before using this method.
 */
- (void)connectWithCompletionHandler:(nonnull void (^)(NSError * _Nullable)) completionHandler;

/**
 * @brief Connect and open a websocket connection with the Millicast platform.
 * @param options connection options. 
 * @param completionHandler handler invoked when the result is ready
 * @remarks You must set valid credentials before using this method.
 */
- (void)connectWithOptions:(nonnull MCConnectionOptions *) options
         completionHandler:(nonnull void (^)(NSError * _Nullable)) completionHandler;

/**
 * @brief Connect to the media server directly using the websocket url and the
 * JWT.
 * @param wsUrl The websocket url returned by the director api
 * @param jwt The JSON Web Token returned by the director api
 * @param completionHandler handler invoked when the result is ready.
 */
- (void)connectWithWebsocketUrl:(nonnull NSString *)websocketUrl jwt:(nonnull NSString *)jwt
              completionHandler:(nonnull void (^)(NSError * _Nullable)) completionHandler;

/**
 * @brief Connect to the media server directly using the websocket url and the
 * JWT.
 * @param connectionOptions connection options.
 * @param websocketUrl The websocket url returned by the director api
 * @param jwt The JSON Web Token returned by the director api
 * @param completionHandler handler invoked when the result is ready.
 */
- (void)connectWithWebsocketUrl:(nonnull NSString *)websocketUrl jwt:(nonnull NSString *)jwt
              connectionOptions:(nonnull MCConnectionOptions *) connectionOptions
              completionHandler:(nonnull void (^)(NSError * _Nullable)) completionHandler;

/**
 * @brief Query whether the client is connected.
 * @param completionHandler handler invoked when the result is ready.
 */
- (void)isConnectedWithCompletionHandler:(nonnull void (^)(BOOL connected)) completionHandler;

/**
 * @brief Disconnect from Millicast.
 * The websocket connection to Millicast will no longer be active
 * after disconnect is complete.
 * @remark If the client is currently publishing/subscribing, the SDK will first stop
 * the publishing/subscribing before disconnecting.
 * @param completionHandler handler invoked when the result is ready.
 */
- (void)disconnectWithCompletionHandler:(nonnull void (^)(NSError * _Nullable)) completionHandler;

/**
 * @brief Enable the rtc stats collecting.
 * The stats are collected once the client is either publishing or subscribed.
 * @param enable true to enable the stats, false to disable the stats.
 * @param completionHandler handler invoked when the result is ready.
 */
- (void)enableStats:(BOOL)enable 
  completionHandler:(nonnull void (^)(void)) completionHandler;

/**
 * @brief Add frame transformer so you can add metadata to video  frames. Disabled by default.
 * @param enable true to enable the frame transformer, false to disable it
 * @param completionHandler handler invoked when the result is ready.
 */
- (void)enableFrameTransformer:(BOOL)enable
             completionHandler:(nonnull void (^)(void)) completionHandler;

/**
 * @brief Get the transceiver mid associated to a track.
 * @remark The underlying peer connection must be alive, i.e. we are either
 * publishing or subscribing.
 * @param trackId The id of the track we want to retrieve the mid
 * @param completionHandler handler invoked when the result is ready.
 */
- (void) getMid:(nonnull NSString*) trackId
         completionHandler:(nonnull void (^)(NSString * _Nullable, NSError * _Nullable)) completionHandler;
@end

/**
 * @brief Clean and free the memory of dynamic objects.
 * @remarks Call this after all sdk objects have been destroyed. You would likely call this function just before the app exit.
 */
MILLICAST_API @interface MCCleanup : NSObject

+ (void)cleanup;

@end
