#import <Foundation/Foundation.h>
#import <MillicastSDK/exports.h>

// Forward declaration
@class MCStatsReport;


/// The DegradationPreferences enum. Based on [the WebRTC standard](https://w3c.github.io/webrtc-pc/#idl-def-rtcdegradationpreference.)
typedef NS_ENUM(NSInteger, MCDegradationPreferences)
{
  /// Does not take any actions based on over-utilization signals.
  DISABLED,

  /// On over-use, requests lower frame rate, possibly causing frame drops.
  MAINTAIN_RESOLUTION,

  /// On over-use, requests lower resolution, possibly causing down-scaling.
  MAINTAIN_FRAMERATE,

  /// Tries to strike a pleasing balance between frame rate or resolution.
  BALANCED,

  /// No degradation preference, lets the SDK decide how to handle over-utilization.
  DEFAULT
};

/// The BitrateSettings class allows customizing bitrate settings for publishing streams.
MILLICAST_API @interface MCBitrateSettings : NSObject

/// Disable built-in bandwidth estimation algorithm that forces sending the maximum bitrate without any congestion control.
@property(nonatomic) BOOL      disableBWE;

/// The maximum bitrate, in kilobits per second.
@property(nonatomic) NSInteger maxBitrateKbps;

/// The minimum bitrate, in kilobits per second.
@property(nonatomic) NSInteger minBitrateKbps;

/// The start bitrate, in kilobits per second.
@property(nonatomic) NSInteger startBitrateKbps;
@end

/// The `MCDelegate` protocol contains common methods that will be called on specific events from a Client object. It is mainly
/// subclassed by ``MCSubscriberDelegate`` and ``MCPublisherDelegate``, which are the main ones to implement.
@protocol MCDelegate <NSObject>

/// Called when the WebSocket connection to Millicast opens.
- (void)onConnected __attribute__((deprecated));

/// Called when the WebSocket connection to Millicast closes. In the case of an unintended disconnect, a reconnect attempt will happen
/// automatically by default. To turn off the automatic reconnect, set ``MCConnectionOptions/autoReconnect`` to false.
- (void)onDisconnected __attribute__((deprecated));

/// Called when an attempt to connect to Millicast fails.
///
/// - Parameters:
///   - status: The HTTP status code. -1 if an error did not have an HTTP related code.
///   - reason: The reason the connection attempt failed.
- (void)onConnectionError:(int)status withReason:(nonnull NSString *)reason;

/// Called when an error message from Millicast in the response of a websocket command is received.
/// - Parameters:
///   - message: The received error message.
- (void)onSignalingError:(nonnull NSString *)message;


/// Called when a new RTC statistics report has been collected. You must enable statistics via ``MCClient/enableStats:completionHandler:``
/// to start receiving this handler.
///  - Parameters:
///     - report: A Stats report object. Contains various different stats. Use ``MCStatsReport/getStatsOfType:`` to extract statistics of different types like ``MCCodecsStats`` for example.
///
- (void)onStatsReport:(nonnull MCStatsReport *)report;

/// Called whenever a new viewer joins or leaves the stream.
/// - Parameters:
///   - count: The current number of viewers connected to the stream.
- (void)onViewerCount:(int)count;

@end

/// MCScalabilityMode refers to Scalable Video Coding. This is only available for publishing. Please refer to [the WebRTC standard](https://www.w3.org/TR/webrtc-svc/#scalabilitymodes*) to understand where these values come from
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

/// The MCConnectionOptions class gathers connection options.
MILLICAST_API @interface MCConnectionOptions: NSObject

/// Attempts to reconnect by default in case of connection error or network dropout. Enabled by default
@property(nonatomic, assign) BOOL autoReconnect;

@end

/// The MCClientOptions class gathers options for the client.
MILLICAST_API @interface MCClientOptions : NSObject

/// The ID of the source to publish. This option is related to the multisource feature of the millicast service. For more information refer to [The Multisource Broadcasting Guide](https://docs.dolby.io/streaming-apis/docs/multi-source-broadcasting). This is a publisher only option.
@property(nonatomic, retain, nullable) NSString *sourceId;

/// The receiving source to pin. Refer to [ The Multiview Guide](https://docs.dolby.io/streaming-apis/docs/multiview) to learn more about this. This is a subscriber only option.
@property(nonatomic, retain, nullable) NSString *pinnedSourceId;

/// Excluded sources that you do not wish to receive. Refer to [ The Multiview Guide](https://docs.dolby.io/streaming-apis/docs/multiview) to learn more about this. This is a subscriber only option.
@property(nonatomic, retain, nullable) NSArray *excludedSourceId;

/// Enables discontinuous transmission on the publishing side, so audio data is only sent when a user’s voice is detected.
@property(nonatomic, assign) BOOL dtx;

/// The number of multiplxed audio tracks to receive. This is only available for the subscriber
@property(nonatomic, assign) int multiplexedAudioTrack;


/// The video codec to use for publishing. This is only available for the publisher.
@property(nonatomic, retain, nullable) NSString *videoCodec;

/// The audio codec to use for publishing. This is only available for the publisher.
@property(nonatomic, retain, nullable) NSString *audioCodec;


/// The strategy the use in order to limit the bandwidth usage. Refer to [the WebRTC standard](https://www.w3.org/TR/mst-content-hint/#degradation-preference-when-encoding)
@property(nonatomic, assign) MCDegradationPreferences degradationPreferences;

/// Adjust the bitrate settings. This is only available for publishing.
@property(nonatomic, retain, nullable) MCBitrateSettings *bitrateSettings;

/// A boolean indicating whether the SDK should enable stereo audio. True enables stereo, false disables it. This is only available for publishing.
@property(nonatomic, assign) BOOL stereo;

/// The rate at which you want to receive reports with statistics in milliseconds. Defaults to 1 second.
@property(nonatomic, assign) int statsDelayMs;

/// The minimum video jitter buffer delay, in milliseconds. The default value is 0. For more information, refer to [this document](https://webrtc.googlesource.com/src/+/refs/heads/main/docs/native-code/rtp-hdrext/playout-delay) to understand more about what this field does. This is only for subscribing.
@property(nonatomic, assign) int videoJitterMinimumDelayMs;

/// Removes any playout delay on the media server sender side, minimizing the playout delay as much as possible. This is only available for subscribing.
@property(nonatomic, assign) BOOL forcePlayoutDelay;

/// Determines whether audio playback should be completely disabled. Disabling unnecessary audio helps reduce audio-to-video synchronization delays. This is only available on the subscriber.
@property(nonatomic, assign) BOOL disableAudio;

/// Enables Scalable Video Coding selection. Refer to the [WebRTC standard](https://www.w3.org/TR/webrtc-svc/#scalabilitymodes*) to learn which modes are supported by which codecs. This is only available when publishing.
@property(nonatomic, assign) MCScalabilityMode svcMode;


/// Determines whether Simulcast should be enabled (true) or not (false). This is only available for VP8 and H264 codecs, and is `false` by default. This is only available for publishing. Enabling this will send out 3 simulcast streams (low, medium and high).
@property(nonatomic, assign) BOOL simulcast;

/// Enables logging RTC event log into a custom file path.
@property(nonatomic, retain, nullable) NSString *rtcEventLogOutputPath;


/// Indicates whether the SDK should enable stream recording immediately after publishing. Make sure the recording feature is enabled for the publisher token. Recordings can then be viewed on the dashboard.
@property(nonatomic,assign) BOOL recordStream;

/// The priority of redundant streams that indicates the order in which backup streams should be broadcasted in the case of any problems with the primary stream. Refer to the [Redundant Ingest Guide](https://docs.dolby.io/streaming-apis/docs/redundant-ingest#4-set-priorities) to understand more.
@property(nonatomic, assign, nullable) NSNumber *priority;

@end

/// The Client base that contains common methods between ``MCPublisher`` and ``MCSubscriber``.
MILLICAST_API @protocol MCClient

/// Connects and opens a websocket connection with the Millicast platform.  You must set valid credentials before using this method.
/// - Parameters:
///   - completionHandler: Handler invoked when the result is ready.
- (void)connectWithCompletionHandler:(nonnull void (^)(NSError * _Nullable)) completionHandler;


/// Connects and opens a websocket connection with the Millicast platform. You must set valid credentials before using this method.
/// - Parameters:
///   - options: Connection options.
///   - completionHandler: Handler invoked when the result is ready.
- (void)connectWithOptions:(nonnull MCConnectionOptions *) options
         completionHandler:(nonnull void (^)(NSError * _Nullable)) completionHandler;

/// Connects to the media server directly using the websocket URL and the JSON Web Token.
/// - Parameters:
///   - websocketUrl: The websocket URL returned by the Director API.
///   - jwt: The JSON Web Token returned by the Director API.
///   - completionHandler: Handler invoked when the result is ready.
- (void)connectWithWebsocketUrl:(nonnull NSString *)websocketUrl jwt:(nonnull NSString *)jwt
              completionHandler:(nonnull void (^)(NSError * _Nullable)) completionHandler;

/// Connects to the media server directly using the websocket URL and the JSON Web Token.
/// - Parameters:
///   - connectionOptions: Connection options. Can be used for example to disable ``MCConnectionOptions/autoReconnect``.
///   - websocketUrl: The websocket URL returned by the Director API.
///   - jwt: The JSON Web Token returned by the Director API.
///   - completionHandler: Handler invoked when the result is ready.
- (void)connectWithWebsocketUrl:(nonnull NSString *)websocketUrl jwt:(nonnull NSString *)jwt
              connectionOptions:(nonnull MCConnectionOptions *) connectionOptions
              completionHandler:(nonnull void (^)(NSError * _Nullable)) completionHandler;

/// Checks whether the client is connected to the media server.
///  - Parameters:
///    - completionHandler: Handler invoked when the result is ready.
- (void)isConnectedWithCompletionHandler:(nonnull void (^)(BOOL connected)) completionHandler;


/// Disconnects from the Millicast platform.  
/// Any ongoing process of publishing or subscribing content
/// is automatically stopped before termination.
/// The websocket connection to Millicast will no longer be active
/// after disconnect is complete.
/// - Parameters:
///   - completionHandler: Handler invoked when the result is ready.
- (void)disconnectWithCompletionHandler:(nonnull void (^)(NSError * _Nullable)) completionHandler;

/// Enables or disables the collection and reporting of real-time
/// statistics associated with streaming sessions.
/// The statistics are collected once the client is either publishing or subscribed.
/// - Parameters:
///   - enable:  A boolean that determines whether the RTC reporting should be enabled (true) or disabled (false).
///   - completionHandler: Handler invoked when the result is ready.
///
- (void)enableStats:(BOOL)enable
  completionHandler:(nonnull void (^)(void)) completionHandler;

/// Enables or disables the frame transformation functionality that lets you
/// add metadata to video frames. The functionality is disabled by default.
/// - Parameters:
///   - enable: A boolean that indicates the requested action. True enables the frame transformation, false disables it.
///   - completionHandler: Handler invoked when the result is ready.
- (void)enableFrameTransformer:(BOOL)enable
             completionHandler:(nonnull void (^)(void)) completionHandler;

/// Get the transceiver mid associated to a track.
/// The underlying peer connection must be alive, 
/// i.e. we are either publishing or subscribing.
/// - Parameters:
///   - trackId: The id of the track we want to retrieve the mid.
///   - completionHandler: handler invoked when the result is ready.
- (void) getMid:(nonnull NSString*) trackId
         completionHandler:(nonnull void (^)(NSString * _Nullable, NSError * _Nullable)) completionHandler;
@end


/// The Cleanup class is responsible for cleaning the memory of dynamic objects.
MILLICAST_API @interface MCCleanup : NSObject

/// Cleans and frees the memory of dynamic objects. Call this method after all SDK objects have been destroyed. You would likely call this function just before the application exit.
+ (void)cleanup;

@end
