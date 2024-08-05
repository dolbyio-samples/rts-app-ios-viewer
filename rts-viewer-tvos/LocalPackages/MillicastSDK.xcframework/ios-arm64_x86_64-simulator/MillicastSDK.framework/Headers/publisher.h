#import <MillicastSDK/client.h>
#import <MillicastSDK/exports.h>

// Forward declarations ///////////////////////////////////////////////////////
NS_ASSUME_NONNULL_BEGIN

@class MCVideoTrack;
@class MCAudioTrack;
@class MCTrack;

// Publisher //////////////////////////////////////////////////////////////////

/// This delegate  acts as a listener for the Publisher class.
/// It adds the publishing event on top of the Client listener.
/// You must implement this protocol and set a listener
/// to receive events from the publisher.
MILLICAST_API @protocol MCPublisherDelegate <MCDelegate>

/// Called when the first viewer is viewing the stream.
- (void) onActive;

/// Called when the last viewer stops viewing the stream.
- (void) onInactive;

/// Called when the stream is currently publishing.
- (void) onPublishing;


@optional
/// Called after a frame has been encoded if you need to add data
/// to this frame before the frame is passed to the RTP packetizer.
/// - Parameters:
///   - data: The user data containing NSNumber with the unsignedChar value.
///   - ssrc: The synchronization source of the frame.
///   - timestamp: The timestamp of the frame.
- (void) onTransformableFrame:(NSMutableArray<NSNumber*>*)data withSsrc:(int) ssrc withTimestamp:(int) timestamp;

@end


/// The Credentials interface represents the credentials required for
/// connecting the publisher to the streaming platform and publishing a stream.
/// Refer to the [streaming dashboard](https://dash.millicast.com/docs.html) for this information.
MILLICAST_API @interface MCPublisherCredentials : NSObject

/// The name of the stream to publish.
@property (nonatomic, strong) NSString* streamName;

/// The publishing token.
@property (nonatomic, strong) NSString* token;

/// The publish API URL.
@property (nonatomic, strong) NSString* apiUrl;

@end

/// The Publisher interface is responsible for publishing media to a Millicast stream.
MILLICAST_API @interface MCPublisher : NSObject<MCClient>

/// Initiates the process of publishing streams to the streaming platform.
/// Prior to calling this method, you must use the ``MCClient/connectWithCompletionHandler:``or ``MCClient/connectWithWebsocketUrl:jwt:completionHandler:`` method to connect the publisher to the platform.
/// When publishing, the SDK sets the AVAudioSession to the playAndRecord
/// category, with voiceChat mode and allowBluetooth option. If desired, the application
/// can configure the AVAudioSession with its own settings.
/// - Parameters:
///   - completionHandler: Invoked when the result is ready.
- (void) publishWithCompletionHandler:(nonnull void (^)(NSError * _Nullable)) completionHandler;


/// Publish a stream with configuration options.
/// - Parameters:
///   - options: Options to configure the publishing session. For example, audio/video codec selection.
///   - completionHandler: Invoked when the result is ready.
- (void) publishWithOptions:(nonnull MCClientOptions *) options
          completionHandler:(nonnull void (^)(NSError * _Nullable)) completionHandler;

/// Stops the process of publishing streams to the streaming platform.
/// After calling this method, the SDK automatically terminates the connection 
/// between the publisher and the streaming platform.
/// - Parameters:
///   - completionHandler: Invoked when the result is ready.
- (void)unpublishWithCompletionHandler:(nonnull void (^)(NSError * _Nullable)) completionHandler;

/// Checks whether the publisher is currently in a publishing state
/// and returns a boolean indicating the publishing status.
/// - Parameters:
///   - completionHandler: Invoked when the result is ready.
- (void) isPublishingWithCompletionHandler:(nonnull void (^)(BOOL publishing)) completionHandler;

/// Sets the publisher credentials, providing authentication information
/// required for connecting to the streaming platform.
/// - Parameters:
///   - credentials: The publishing credentials.
///   - completionHandler: Invoked when the result is ready.
- (void) setCredentials:(nonnull MCPublisherCredentials*) credentials
      completionHandler:(nonnull void (^)(NSError * _Nullable)) completionHandler;

/// Returns the current publisher credentials.
/// - Parameters:
///   - completionHandler: Invoked when the result is ready.
- (void) getCredentialsWithCompletionHandler: (nonnull void (^)(MCPublisherCredentials * _Nonnull)) completionHandler;

/// Adds a video track to the publisher. See ``MCVideoSource/startCapture`` as an example
/// for capturing a video device track.
/// - Parameters:
///   - videoTrack: The video track to add.
///   - completionHandler: Invoked when the result is ready.
- (void) addTrackWithVideoTrack:(nonnull MCVideoTrack*) videoTrack
              completionHandler:(nonnull void (^)(void)) completionHandler;

/// Adds an audio track to the publisher. See ``MCAudioSource/startCapture`` as an example
/// for capturing an audio device track.
/// - Parameters:
///   - videoTrack: The video track to add.
///   - completionHandler: Invoked when the result is ready.
- (void) addTrackWithAudioTrack:(nonnull MCAudioTrack*) audioTrack
              completionHandler:(nonnull void (^)(void)) completionHandler;

/// Clears all tracks added to the publisher.
/// - Parameters:
///   - completionHandler: Invoked when the result is ready.
- (void) clearTracksWithCompletionHandler:(nonnull void (^)(void)) completionHandler;

/// Initializes a publisher.
/// - Parameters:
///   - delegate: The publisher delegate to receive events related to publishing
- (instancetype) initWithDelegate: (nonnull id<MCPublisherDelegate>) delegate;


/// Starts recording a stream.
/// See the [Recording Docs](https://docs.dolby.io/streaming-apis/docs/recordings) for more information.
/// - Parameters:
///   - completionHandler: completionHandler Invoked when result is ready.
-(void) recordWithCompletionHandler:(nonnull void (^)(NSError * _Nullable)) completionHandler;


/// Stops recording a stream.
/// See the [Recording Docs](https://docs.dolby.io/streaming-apis/docs/recordings)
/// for more information on how to access the recordings.
/// - Parameters:
///   - completionHandler: completionHandler Invoked when result is ready.
-(void) unrecordWithCompletionHandler:(nonnull void (^)(NSError * _Nullable)) completionHandler;

@end

NS_ASSUME_NONNULL_END
