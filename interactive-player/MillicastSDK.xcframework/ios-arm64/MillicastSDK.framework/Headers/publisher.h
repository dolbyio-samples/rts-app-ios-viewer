/**
  * @file publisher.h
  * @author David Baldassin
  * @copyright Copyright 2021 CoSMoSoftware.
  * @date 07/2021
  */

#import <MillicastSDK/client.h>
#import <MillicastSDK/exports.h>

// Forward declarations ///////////////////////////////////////////////////////

@class MCVideoTrack;
@class MCAudioTrack;
@class MCTrack;

// Scalability mode ///////////////////////////////////////////////////////////

#ifdef __cplusplus
enum MCScalabilityMode
{
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
#else
typedef enum
{
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
} MCScalabilityMode;
#endif

// Publisher //////////////////////////////////////////////////////////////////

/**
 * @brief The Listener protocol for the Publisher class.
 * It adds the publishing event on top of the Client listener
 * You must implement this protocol and set a listener with setListener
 * to be able to receive events from the publisher.
 */

@protocol MCPublisherListener <MCListener>

/**
 * @brief onPublishing is called when a peerconnection has been established
 * with Millicast and the media exchange has started.
 */

- (void) onPublishing;

/**
 * @brief Called when an error occuredwhile establishing the peerconnection
 * @param error The reason of the error
 * @param
 */
- (void) onPublishingError:(NSString*) error;

/**
 * @brief Called when the first viewer is viewing the stream
 */
- (void) onActive;

/**
 * @brief Called when the last viewer stops viewing the stream
 */
- (void) onInactive;

/**
 * @brief Called after a frame has been encoded if you need to add data
 * to this frame before the frame is being passed to the RTP packetizer
 * @param data Empty array to be filled with user data. Must be filled with NSNumber with unsignedChar value
 * @param ssrc Synchronization source of the frame
 * @param timestamp Timestamp of the frame
 */
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
 * @return true if now trying to, or is already publishing, false
 * otherwise.
 * @remark After trying，a successful publish results in the
 * Listener's method onPublishing being called.
 */

- (BOOL) publish;

/**
 * @brief Stop sending media to Millicast.
 * The SDK will automatically disconnect after unpublish.
 * @return false if unable to reach a disconnected state, true otherwise.
 */

- (BOOL)unpublish;

/**
 * @brief Tell if the publisher is publishing
 * @return true if the publisher is publishing, false otherwise.
*/

- (BOOL) isPublishing;

/**
 * @brief Set the publisher credentials.
 * @param credentials The credentials
 * @return true if the credentials are valid and set correctly, false otherwise.
*/

- (BOOL) setCredentials: (MCPublisherCredentials*) credentials;

/**
 * @brief Get the current publisher credentials.
 * @return The current credentials set in the publisher.
*/

- (MCPublisherCredentials*) getCredentials;

/**
 * @brief Add a track that will be used to publish media (audio or video).
 * @param track The track.
*/

- (void) addTrack:(MCTrack*) track;

/**
 * @brief clearTracks will clear all track added to the publisher.
*/

- (void) clearTracks;

/**
 * @brief Enable scalable video coding with a single ssrc
 * @param mode The scalability mode
 * @remarks call this method before publishing
*/
- (void) enableSvcWithMode:(MCScalabilityMode) mode;

/**
 * @brief Disable scalable video coding and set default publish parameter
*/
- (void) disableSvc;

/**
 * @brief enable simulcast.
 * @param enable true to enable simulcast. false to disable it.
 * @remarks Call this before publishing
*/
- (void) enableSimulcast:(BOOL) enable;

/**
 * @brief Get the transceiver mid associated to a track
 * @param trackId The id of the track we want to retrieve the mid
 * @return The transceiver mid. nil if there is no mid found
 */
- (NSString*) getMid:(NSString*) trackId;

/**
 * @brief Create a publisher object.
 * @return A publisher object.
*/

+ (MCPublisher*) create;

@end
