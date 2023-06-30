/**
  * @file stats.h
  * @author David Baldassin
  * @copyright Copyright 2021 CoSMoSoftware.
  * @date 07/2021
  */

#import <Foundation/Foundation.h>
#import <MillicastSDK/exports.h>

#ifdef __cplusplus
enum MCStatsType
{
  CODEC,
  OUTBOUND_RTP,
  INBOUND_RTP,
  REMOTE_INBOUND_RTP,
  REMOTE_OUTBOUND_RTP,
  MEDIA_TRACK,
  AUDIO_TRACK,
  VIDEO_TRACK,
  MEDIA_SOURCE
};

enum  MCCodecStatsType {
    ENCODE,
    DECODE
};
#else
typedef enum MCStatsType
{
  CODEC,
  OUTBOUND_RTP,
  INBOUND_RTP,
  REMOTE_INBOUND_RTP,
  REMOTE_OUTBOUND_RTP,
  MEDIA_TRACK,
  AUDIO_TRACK,
  VIDEO_TRACK,
  MEDIA_SOURCE
} MCStatsType;

typedef enum  MCCodecStatsType {
    ENCODE,
    DECODE
} MCCodecStatsType;
#endif

MILLICAST_API @interface MCStats : NSObject

/**
 * @brief The timestamp in Milliseconds since Unix Epoch (Jan 1, 1970 00:00:00 UTC).
 */
@property long long         timestamp;
@property (assign, nonatomic) NSString *  sid; // stats id, id is a reserved keywork in objc
@property MCStatsType type;

@end

MILLICAST_API @interface MCCodecsStats : MCStats
+ (MCStatsType) get_type;

@property unsigned long payload_type;
@property (assign, nonatomic)  NSString * transport_id;
@property (assign, nonatomic)  NSString * mime_type;

@property MCCodecStatsType codec_type;
@property unsigned long    clock_rate;
@property unsigned long    channels;
@property (assign, nonatomic)  NSString * sdp_fmtp_line;
@end

MILLICAST_API @interface MCRtpStreamStats :  MCStats
@property  unsigned long ssrc;
@property (assign, nonatomic)  NSString * kind;
@property (assign, nonatomic)  NSString * transport_id;
@property (assign, nonatomic)  NSString * codec_id;
@end

MILLICAST_API @interface MCReceivedRtpStreamStats : MCRtpStreamStats
+ (MCStatsType) get_type;

@property unsigned long long packets_received;
@property double             jitter;
@property long long          packets_lost;
@property unsigned long long frames_dropped;

@end

MILLICAST_API @interface MCInboundRtpStreamStats : MCReceivedRtpStreamStats
+ (MCStatsType) get_type;

@property (assign, nonatomic) NSString * remote_id;
@property (assign, nonatomic) NSString * track_identifier;
@property (assign, nonatomic) NSString * mid;
@property unsigned long bytes_received;
@property unsigned long header_bytes_received;
@property double        last_packet_received_timestamp;
@property double        jitter_buffer_delay;
@property unsigned long jitter_buffer_emitted_count;
@property double        estimated_playout_timestamp;

/**
 * @brief Only defined for audio.
 */
@property unsigned long fec_packets_received;
/**
 * @brief Only defined for audio.
 */
@property unsigned long fec_packets_discarded;
/**
 * @brief Only defined for audio.
 */
@property unsigned long total_samples_received;
/**
 * @brief Only defined for audio.
 */
@property unsigned long concealed_samples;
/**
 * @brief Only defined for audio.
 */
@property unsigned long silent_concealed_samples;
/**
 * @brief Only defined for audio.
 */
@property unsigned long concealment_events;
/**
 * @brief Only defined for audio.
 */
@property unsigned long inserted_samples_for_deceleration;
/**
 * @brief Only defined for audio.
 */
@property unsigned long removed_samples_for_acceleration;
/**
 * @brief Only defined for audio.
 */
@property double        audio_level;
/**
 * @brief Only defined for audio.
 */
@property double        total_audio_energy;
/**
 * @brief Only defined for audio.
 */
@property double        total_samples_duration;

/**
 * @brief Only defined for video.
 */
@property unsigned long frames_received;
/**
 * @brief Only defined for video.
 */
@property unsigned long frame_width;
/**
 * @brief Only defined for video.
 */
@property unsigned long frame_height;
/**
 * @brief Only defined for video.
 */
@property double        frames_per_second;
/**
 * @brief Only defined for video.
 */
@property unsigned long frames_decoded;
/**
 * @brief Only defined for video.
 */
@property unsigned long key_frames_decoded;
/**
 * @brief Only defined for video.
 */
@property unsigned long frames_dropped;
/**
 * @brief Only defined for video.
 */
@property double total_decode_time;
/**
 * @brief Only defined for video.
 */
@property double total_processing_delay;
/**
 * @brief Only defined for video.
 */
@property double total_assembly_time;
/**
 * @brief Only defined for video.
 */
@property unsigned long frames_assembled_from_multiple_packets;
/**
 * @brief Only defined for video.
 */
@property double total_inter_frame_delay;
/**
 * @brief Only defined for video.
 */
@property double total_squared_inter_frame_delay;
/**
 * @brief Only defined for video.
 */
@property (assign, nonatomic) NSString * decoder_implementation;
/**
 * @brief Only defined for video.
 */
@property unsigned long fir_count;
/**
 * @brief Only defined for video.
 */
@property unsigned long pli_count;
/**
 * @brief Only defined for video.
 */
@property unsigned long nack_count;
/**
 * @brief Only defined for video.
 */
@property double min_playout_delay;

@end

MILLICAST_API @interface MCSentRtpStreamStats : MCRtpStreamStats
+ (MCStatsType) get_type;

@property unsigned long      packets_sent;
@property unsigned long long bytes_sent;
@end

MILLICAST_API @interface MCOutboundRtpStreamStats : MCSentRtpStreamStats
+ (MCStatsType) get_type;

@property (assign, nonatomic) NSString * sender_id;
@property (assign, nonatomic) NSString *   remote_id;
@property unsigned long long retransmitted_packets_sent;
@property unsigned long long header_bytes_sent;
@property unsigned long long retransmitted_bytes_sent;
@property double        target_bitrate;
@property double        total_packet_send_delay;

/**
 * @brief Only defined for video.
 */
@property unsigned long frames_encoded;
/**
 * @brief Only defined for video.
 */
@property unsigned long key_frames_encoded;
/**
 * @brief Only defined for video.
 */
@property unsigned long long total_encoded_bytes_target;
/**
 * @brief Only defined for video.
 */
@property unsigned long frame_width;
/**
 * @brief Only defined for video.
 */
@property unsigned long frame_height;
/**
 * @brief Only defined for video.
 */
@property double        frames_per_second;
/**
 * @brief Only defined for video.
 */
@property unsigned long frames_sent;
/**
 * @brief Only defined for video.
 */
@property unsigned long huge_frames_sent;
/**
 * @brief Only defined for video.
 */
@property (assign, nonatomic) NSString *   quality_limitation_reason;
/**
 * @brief Only defined for video.
 */
@property (assign, nonatomic) NSString *   quality_limitation_durations;
/**
 * @brief Only defined for video.
 */
@property unsigned long quality_limitation_resolution_changes;
/**
 * @brief Only defined for video.
 */
@property (assign, nonatomic) NSString *   encoder_implementation;
/**
 * @brief Only defined for video.
 */
@property unsigned long fir_count;
/**
 * @brief Only defined for video.
 */
@property unsigned long pli_count;
/**
 * @brief Only defined for video.
 */
@property unsigned long nack_count;
/**
 * @brief Only defined for video.
 */
@property unsigned long long qp_sum;


@end

MILLICAST_API @interface MCRemoteOutboundRtpStreamStats : MCSentRtpStreamStats
+ (MCStatsType) get_type;
@property (assign, nonatomic) NSString * media_source_id;
@property (assign, nonatomic) NSString * remote_id;
@property (assign, nonatomic) NSString * local_id;
@property long long remote_timestamp;
@property unsigned long long reports_sent;
@property unsigned long long round_trip_time_measurements;
@property double round_trip_time;
@property double total_round_trip_time;

@end

MILLICAST_API @interface MCRemoteInboundRtpStreamStats : MCReceivedRtpStreamStats
+ (MCStatsType) get_type;
@property (assign, nonatomic) NSString * local_id;
@property double round_trip_time;
@property double total_round_trip_time;
@property long long round_trip_time_measurements;
@property double fraction_lost; // fraction packet loss
@end

MILLICAST_API @interface MCMediaStreamTrackStats : MCStats
+ (MCStatsType) get_type;

@property (assign, nonatomic) NSString * track_identifier;
@property (assign, nonatomic) NSString * kind;
@property (assign, nonatomic) NSString * media_source_id;
@end

MILLICAST_API @interface MCVideoStreamTrackStats : MCMediaStreamTrackStats
+ (MCStatsType) get_type;
@property unsigned long width;
@property unsigned long height;
@property unsigned long bit_depth;
@property unsigned long frames_sent;
@property unsigned long frames_received;
@end

MILLICAST_API @interface MCAudioStreamTrackStats : MCMediaStreamTrackStats
+ (MCStatsType) get_type;
@property double audio_level;
@property double total_audio_energy;
@property double total_samples_duration;
@end

MILLICAST_API @interface MCMediaSourceStats : MCStats
+ (MCStatsType) get_type;
@property (assign, nonatomic) NSString * track_identifier;
@property (assign, nonatomic) NSString * kind;
@end

MILLICAST_API @interface MCVideoSourceStats : MCMediaSourceStats
+ (MCStatsType) get_type;
@property unsigned long width;
@property unsigned long height;
@property unsigned long frames;
@property double        frames_per_second;
@end

MILLICAST_API @interface MCAudioSourceStats : MCMediaSourceStats
+ (MCStatsType) get_type;

@property double audio_level;
@property double total_audio_energy;
@property double total_samples_duration;
@property double echo_return_loss;
@property double echo_return_loss_enhancement;
@end

MILLICAST_API @interface MCStatsReport : NSObject

- (void) addStats:(MCStats*)obj;
- (MCStats*) get:(NSString*)statsId;

/**
 * @brief Gets all the MCStats in this MCStatsReport that is of the MCStatsType specified.
 * @param type The MCStatsType desired.
 * @return An array containing the MCStats of the MCStatsType specified.
 */

- (NSArray<MCStats*>*) getStatsOfType:(MCStatsType)type;
- (int) size;

@end
