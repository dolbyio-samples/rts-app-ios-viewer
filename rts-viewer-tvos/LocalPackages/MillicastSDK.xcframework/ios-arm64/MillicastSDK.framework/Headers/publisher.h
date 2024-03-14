/**
  * @file publisher.h
  * @author David Baldassin
  * @copyright Copyright 2021 CoSMoSoftware.
  * @date 07/2021
  */

#import <MillicastSDK/client.h>
#import <MillicastSDK/exports.h>

// Forward declarations ///////////////////////////////////////////////////////
NS_ASSUME_NONNULL_BEGIN

@class MCVideoTrack;
@class MCAudioTrack;
@class MCTrack;

// Publisher //////////////////////////////////////////////////////////////////

/**
 * @brief The Listener protocol for the Publisher class.
 * It adds the publishing event on top of the Client listener
 * You must implement this protocol and set a listener with setListener
 * to be able to receive events from the publisher.
 */

MILLICAST_API @protocol MCPublisherDelegate <MCDelegate>
/**
 * @brief Called when the first viewer is viewing the stream
 */
- (void) onActive;

/**
 * @brief Called when the last viewer stops viewing the stream
 */
- (void) onInactive;

/**
 * @brief Called when the stream is currently publishing.
 */
- (void) onPublishing;

/**
 * @brief Called after a frame has been encoded if you need to add data
 * to this frame before the frame is being passed to the RTP packetizer
 * @param data Empty array to be filled with user data. Must be filled with NSNumber with unsignedChar value
 * @param ssrc Synchronization source of the frame
 * @param timestamp Timestamp of the frame
 */
@optional
- (void) onTransformableFrame:(NSMutableArray<NSNumber*>*)data withSsrc:(int) ssrc withTimestamp:(int) timestamp;

@end

/**
 * @brief The Credentials interface represents the credentials needed to be able to
 * connect and publish to a Millicast stream.
 * @sa https://dash.millicast.com/docs.html
 */

MILLICAST_API @interface MCPublisherCredentials : NSObject

/** @brief The name of the stream we want to publish */
@property (nonatomic, strong) NSString* streamName;
/** @brief The publishing token as described in the Millicast API */
@property (nonatomic, strong) NSString* token;
/** @brief The publish API URL as described in the Millicast API */
@property (nonatomic, strong) NSString* apiUrl;

@end

/**
 * @brief The Publisher interface. Its purpose is to publish media to a Millicast stream.
 */

MILLICAST_API @interface MCPublisher : NSObject<MCClient>

/**
 * @brief Publish a stream to Millicast.
 * You must be connected first in order to publish a stream.
 * When publishing, the SDK sets the AVAudioSession to the playAndRecord
 * category, with voiceChat mode and allowBluetooth option. If desired, the App
 * can configure the AVAudioSession with its own settings. For an example,
 * please see how the Millicast iOS Sample App configures the AVAudioSession at:
 * https://github.com/millicast/Millicast-ObjC-SDK-iOS-Sample-App-in-Swift
 * @param completionHandler handler invoked when the result is ready.
 */

- (void) publishWithCompletionHandler:(nonnull void (^)(NSError * _Nullable)) completionHandler;

/**
 * @brief Publish a stream to Millicast.
 * You must be connected first in order to publish a stream.
 * When publishing, the SDK sets the AVAudioSession to the playAndRecord
 * category, with voiceChat mode and allowBluetooth option. If desired, the App
 * can configure the AVAudioSession with its own settings. For an example,
 * please see how the Millicast iOS Sample App configures the AVAudioSession at:
 * https://github.com/millicast/Millicast-ObjC-SDK-iOS-Sample-App-in-Swift
 * @param options options to pass to publishing. Only Publishing relevant
 * @param completionHandler handler invoked when the result is ready.
 */

- (void) publishWithOptions:(nonnull MCClientOptions *) options
          completionHandler:(nonnull void (^)(NSError * _Nullable)) completionHandler;

/**
 * @brief Stop sending media to Millicast.
 * The SDK will automatically disconnect after unpublish.
 * @param completionHandler handler invoked when the result is ready.
 */

- (void)unpublishWithCompletionHandler:(nonnull void (^)(NSError * _Nullable)) completionHandler;

/**
 * @brief Tell if the publisher is publishing
 * @param completionHandler completionHandler invoked when the query result is ready.
*/
- (void) isPublishingWithCompletionHandler:(nonnull void (^)(BOOL publishing)) completionHandler;

/**
 * @brief Set the publisher credentials.
 * @param credentials The credentials
 * @param completionHandler handler invoked when the result is ready.
*/

- (void) setCredentials:(nonnull MCPublisherCredentials*) credentials
      completionHandler:(nonnull void (^)(NSError * _Nullable)) completionHandler;
/**
 * @brief Get the current publisher credentials.
 * @param completionHandler handler invoked when the result is ready.
*/

- (void) getCredentialsWithCompletionHandler: (nonnull void (^)(MCPublisherCredentials * _Nonnull)) completionHandler;

/**
 * @brief Add a video track that will be used to publish media.
 * @param videoTrack video track to add.
 * @param completionHandler handler invoked when the result is ready.
*/

- (void) addTrackWithVideoTrack:(nonnull MCVideoTrack*) videoTrack
              completionHandler:(nonnull void (^)(void)) completionHandler;

/**
 * @brief Add an audio track that will be used to publish media.
 * @param audioTrack audio track to add.
 * @param completionHandler handler invoked when the result is ready.
*/

- (void) addTrackWithAudioTrack:(nonnull MCAudioTrack*) audioTrack
              completionHandler:(nonnull void (^)(void)) completionHandler;

/**
 * @brief Clear all track added to the publisher.
 * @param completionHandler handler invoked when the result is ready.
*/

- (void) clearTracksWithCompletionHandler:(nonnull void (^)(void)) completionHandler;

/**
 * @brief Initialize a publisher object.
 * @param delegate publisher delegate to receive events related
 * to publishing.
 * @return A publisher object.
*/
- (instancetype) initWithDelegate: (nonnull id<MCPublisherDelegate>) delegate;

/**
 * @brief Start recording. This asks the millicast service to start recording.
 * @param completionHandler handler invoked when result is ready.
 * @remarks Call this after publishing
*/
-(void) recordWithCompletionHandler:(nonnull void (^)(NSError * _Nullable)) completionHandler;


/**
 * @brief Stop recording. This asks the millicast service to stop recording. 
 * @param completionHandler handler invoked when result is ready.
 * @remarks Call this after publishing
*/
-(void) unrecordWithCompletionHandler:(nonnull void (^)(NSError * _Nullable)) completionHandler;

@end

NS_ASSUME_NONNULL_END
