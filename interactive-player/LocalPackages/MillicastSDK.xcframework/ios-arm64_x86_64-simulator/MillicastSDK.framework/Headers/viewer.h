#import <MillicastSDK/client.h>
#import <MillicastSDK/exports.h>

NS_ASSUME_NONNULL_BEGIN

// Forward declarations ///////////////////////////////////////////////////////
@class MCVideoTrack;
@class MCAudioTrack;

// Viewer /////////////////////////////////////////////////////////////////////

/// Simulcast/SVC layer resolution information. Received as part in ``MCLayerData``
/// in ``MCSubscriber/layers()`` event.
@interface MCLayerResolution : NSObject
/// The height of the layer.
@property int height;
/// The width of the layer.
@property int width;
@end

/// The layer data is used to select a simulcast/svc layer.
/// by sending a command to the server using the select or project method.
MILLICAST_API @interface MCLayerData : NSObject

/// The encoding id of the simulcast/SVC layer
@property (nonatomic, strong, nonnull) NSString* encodingId;

/// The bitrate of the SVC layer.
@property int bitrate;

/// The spatial layer id of a SVC layer.
@property(nonatomic, assign, nullable) NSNumber *spatialLayerId;

/// The temporal layer id of the SVC layer
@property(nonatomic, assign, nullable) NSNumber *temporalLayerId;

/// The maximum temporal layer to be used. Set by app.
@property(nonatomic, assign, nullable) NSNumber *maxTemporalLayerId;

/// The maximum spatial layer to be used. Set by app.
@property(nonatomic, assign, nullable) NSNumber *maxSpatialLayerId;

/// The resolution of frames in the layer.
@property(nonatomic, assign, nullable) MCLayerResolution* layerResolution;
@end

/// The projection data is used to project a video/audio track into a specific transceiver.
/// We send a command to the media server using the project method to choose which track to
/// project
MILLICAST_API @interface  MCProjectionData : NSObject

/// The id of the track on the server side
@property (nonatomic, strong, nonnull) NSString* trackId;

/// Kind of the track. Either "video" or "audio"
@property (nonatomic, strong, nonnull) NSString* media;

/// The transceiver mid associated to the track
@property (nonatomic, strong, nonnull) NSString* mid;

/// Optionally choose a simulcast layer.
@property (nonatomic, strong, nullable) MCLayerData*  layer;

@end

/// Delegate protocol that can be implemented to receive subscriber specific
/// events. Initialize the viewer with a delegate via ``MCSubscriber/initWithDelegate:``
@protocol MCSubscriberDelegate <MCDelegate>

///  Called when the subscriber starts receiving media.
- (void) onSubscribed;


/// Called when a remote video track has been added.
/// - Parameters:
///   - track: The remote video track.
- (void) onVideoTrack:(nonnull MCVideoTrack*) track withMid:(nonnull NSString*) mid;

/// Called when a remote audio track has been added.
/// - Parameters:
///   - track: The remote audio track.
///   - mid: The associated transceiver mid. Can be nil if there is none.
- (void) onAudioTrack:(nonnull MCAudioTrack*) track withMid:(nonnull NSString*) mid;

/// Called when a new source has been publishing within the new stream
/// - Parameters:
///   - streamId: The stream id.
///   - tracks: All the track ids within the stream
///   - sourceId: The source id if the publisher has set one.
- (void) onActive: (nonnull NSString*) streamId tracks: (nonnull NSArray<NSString*> *)tracks sourceId:(nonnull NSString*) sourceId;


/// Called when a source has been unpublished within the stream
/// - Parameters:
///   - streamId: The stream id. Generally in the form of `AccountID/StreamName`.
///   - sourceId: The source id set by the publisher if any.
- (void) onInactive: (nonnull NSString*) streamId sourceId:(nonnull NSString*) sourceId;

/// Callback is not currently used, but is reserved for future usage.
- (void) onStopped;

/// Called when a source id is being multiplexed into the audio track based on the voice activity level.
/// - Parameters:
///   - mid: The media ID which represents the current WebRTC transceiver associated with the source's audio track.
///   - sourceId: The publisher's source ID.
- (void) onVad: (nonnull NSString*) mid sourceId:(nonnull NSString*) sourceId;

/// Called when simulcast/svc layers are available
/// - Parameters:
///   - mid: The mid associated to the track.
///   - activeLayers: Active simulcast/SVC layers
///   - inactiveLayers: inactive simulcast/SVC layers
- (void) onLayers: (nonnull NSString*) mid activeLayers:(nonnull NSArray<MCLayerData*>*) activeLayers inactiveLayers:(nonnull NSArray<NSString*>*) inactiveLayers;

@optional
/// Called when a frame is received and not yet decoded.
/// Provide extracted metadata embedded in a frame if any.
/// Any data provided by ``MCPublisherDelegate/onTransformableFrame:withSsrc:withTimestamp:``
/// can be accessed here.
/// - Parameters:
///   - data: Array of metadata coming from the publisher.
///   - length: Length of the metadata array
///   - ssrc: Synchronization source of the frame
///   - timestamp: Timestamp of the frame
- (void) onFrameMetadata:(nonnull const unsigned char*)data withLength:(int)length withSsrc:(int) ssrc withTimestamp:(int) timestamp;

@end

/// The Credentials interface represent the credentials required for
/// connecting and subscribing to a Millicast stream. See the [Streaming Dashboard](https://dash.millicast.com/docs.html)
MILLICAST_API @interface MCSubscriberCredentials : NSObject

/// The name of the stream you want to subscribe to.
@property (nonatomic, strong, nonnull) NSString* streamName;

/// The subscribing token.
@property (nonatomic, strong, nonnull) NSString* token;

/// Your Millicast account ID.
@property (nonatomic, strong, nonnull) NSString* accountId;

/// The subscribe API URL.
@property (nonatomic, strong, nonnull) NSString* apiUrl;

@end

/// The Subscriber class manages the subscription to audio and video tracks from the Millicast platform.
MILLICAST_API @interface MCSubscriber : NSObject <MCClient>

@property(nonatomic, weak) id<MCSubscriberDelegate> delegate;

/// Initialize a subscriber.
/// - Parameters:
///   - delegate The subscriber delegate to receive events related
///   to subscribing.
/// - Returns: A subscriber object.
- (instancetype)initWithDelegate: (id<MCSubscriberDelegate>) delegate;

/// Initiates the subscription process from the Millicast platform.
/// Prior to calling this method, you must use the ``MCClient/connectWithCompletionHandler:`` or similar to
/// connect the subscriber to the platform.
/// Successful subscription results in calling the onSubscribed method of the Listener.
/// - Parameters:
///   - completionHandler: Handler invoked when the result is ready.
- (void)subscribeWithCompletionHandler:(nonnull void (^)(NSError * _Nullable)) completionHandler;

/// Subscribes to a stream with options.
/// - Parameters:
///   - opts: Options to be applied for subscribing. Only valid subscriber
///   options in MCClientOptions will be used; others will be ignored.
///   - completionHandler: Handler invoked when the result is ready.
- (void)subscribeWithOptions: (MCClientOptions *) opts completionHandler:(nonnull void (^)(NSError * _Nullable)) completionHandler;

/// Checks whether the subscriber is currently subscribing to any media.
/// - Parameters:
///   - completionHandler: Handler invoked when the result is ready.
- (void) isSubscribedWithCompletionHandler:(nonnull void (^)(BOOL subscribed)) completionHandler;

/// Stops the subscription process indicating to the streaming server that the subscriber
/// is no longer interested in receiving audio and video content.
/// After calling this method, the SDK automatically terminates the connection between
/// the subscriber and the streaming platform.
/// - Parameters:
///   - completionHandler: Handler invoked when the result is ready.
- (void)unsubscribeWithCompletionHandler:(nonnull void (^)(NSError * _Nullable)) completionHandler;

/// Specify the source you want to receive.
/// With the project method you can select and switch sources from the Millicast server
/// and then forward the selected media to the subscriber, for each audio and video track.
/// - Parameters:
///   - sourceId: The source id you want to receive
///   - projectionData: The configuration of the track you want to receive.
///   - completionHandler: Handler invoked when the result is ready.
- (void) project:(NSString*) sourceId withData:(NSArray<MCProjectionData*>*) projectionData completionHandler:(nonnull void (^)(NSError * _Nullable)) completionHandler;

/// Specify the media you want to stop receving.
/// - Parameters:
///   - mids: The list of mids to unproject.
///   - completionHandler: Handler invoked when the result is ready.
- (void) unproject:(NSArray<NSString*>*) mids completionHandler:(nonnull void (^)(NSError * _Nullable)) completionHandler;

/// Select a specific simulcast/SVC layer for a video track.
/// - Parameters:
///   - layer: The data to select which layer and which track. Send an empty optional to reset to automatic layer selection by the server.
///   - completionHandler: Handler invoked when the result is ready.
- (void) select:(MCLayerData* _Nullable)layer completionHandler:(nonnull void (^)(NSError * _Nullable)) completionHandler;

/// Dynamically add on new track to the subscriber so you can project another source into it.
/// It will locally renegociate the SDP.
/// - Parameters:
///   - kind: The kind of the track. "video" or "audio"
///   - completionHandler: handler invoked when the result is ready.
- (void) addRemoteTrack: (NSString*) kind completionHandler:(nonnull void (^)(NSError * _Nullable)) completionHandler;

/// Get the transceiver mid associated to a track.
/// - Parameters:
///   - trackId: The id of the track we want to retrieve the mid
///   - completionHandler: handler invoked when the result is ready.
- (void) getMid:(NSString*) trackId completionHandler:(nonnull void (^)(NSString *, NSError * _Nullable)) completionHandler;

/// Sets the credentials, providing authentication information required for connecting to the streaming platform.
/// - Parameters:
///   - credentials: The credentials.
///   - completionHandler: Handler invoked when the result is ready.
- (void) setCredentials: (nonnull MCSubscriberCredentials*) credentials completionHandler:(nonnull void (^)(NSError * _Nullable)) completionHandler;

/// Get the current viewer's credentials.
/// - Parameters:
///   - completionHandler Handler invoked when the result is ready.
- (void) getCredentialsWithCompletionHandler:(nonnull void (^)(MCSubscriberCredentials * _Nonnull)) completionHandler;

@end

NS_ASSUME_NONNULL_END
