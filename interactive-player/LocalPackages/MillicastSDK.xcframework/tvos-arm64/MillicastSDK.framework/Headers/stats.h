#import <Foundation/Foundation.h>
#import <MillicastSDK/exports.h>

#ifdef __cplusplus
/// Different types of statistics.
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

/// Different types of codec statistics.
enum  MCCodecStatsType {
    ENCODE,
    DECODE
};
#else
/// Different types of statistics.
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

/// Different types of codec statistics.
typedef enum  MCCodecStatsType {
    ENCODE,
    DECODE
} MCCodecStatsType;
#endif

/// A container of various different stats. To make sense of such statistics, please refer to the [WebRTC standard](https://w3c.github.io/webrtc-stats/#introduction)
MILLICAST_API @interface MCStats : NSObject

/// The timestamp in milliseconds since Unix epoch (Jan 1, 1970 00:00:00 UTC) at which the statistical data was recorded.
@property long long         timestamp;

/// The unique identifier.
@property (nonatomic, strong) NSString *  sid; // stats id, id is a reserved keywork in objc

/// The type of statistics.
@property MCStatsType type;

@end

/// Gathers audio/video codec statistics.
MILLICAST_API @interface MCCodecsStats : MCStats

/// The type of statistics.
/// - Returns: the type of statistics.
+ (MCStatsType) get_type;

/// The unique identifier for the codec payload type. See [payloadType](https://w3c.github.io/webrtc-stats/#dom-rtccodecstats-payloadtype)
@property unsigned long payload_type;

/// See [transportId](https://w3c.github.io/webrtc-stats/#dom-rtccodecstats-transportid)
@property (nonatomic, strong)  NSString * transport_id;

/// The Multipurpose Internet Mail Extensions (MIME) type associated with the codec. See [mimeType](https://w3c.github.io/webrtc-stats/#dom-rtccodecstats-mimetype)
@property (nonatomic, strong)  NSString * mime_type;

/// Whether these stastics are for the encoder or the decoder.
@property MCCodecStatsType codec_type;

/// The clock rate of the codec, indicating the frequency at which samples are generated or processed. See [clockRate](https://w3c.github.io/webrtc-stats/#dom-rtccodecstats-clockrate)
@property unsigned long    clock_rate;

/// When present, indicates the number of channels (mono=1, stereo=2). See [channels](https://w3c.github.io/webrtc-stats/#dom-rtccodecstats-channels)
@property unsigned long    channels;

/// The Session Description Protocol (SDP) line associated with the codec. See [sdpFmtpLine](https://w3c.github.io/webrtc-stats/#dom-rtccodecstats-sdpfmtpline)
@property (nonatomic, strong)  NSString * sdp_fmtp_line;
@end

/// Statistics for an RTP stream.
MILLICAST_API @interface MCRtpStreamStats :  MCStats

/// The synchronization source identifier for the stream. See [ssrc](https://w3c.github.io/webrtc-stats/#dom-rtcrtpstreamstats-ssrc)
@property  unsigned long ssrc;

/// The type of media carried by the stream, either audio or video. See [kind](https://w3c.github.io/webrtc-stats/#dom-rtcrtpstreamstats-kind)
@property (nonatomic, strong)  NSString * kind;

/// The transport layer associated with the stream. See [transportId](https://w3c.github.io/webrtc-stats/#dom-rtcrtpstreamstats-transportid)
@property (nonatomic, strong)  NSString * transport_id;

/// The identifier of the codec used for encoding media carried by the stream. See [codecId](https://w3c.github.io/webrtc-stats/#dom-rtcrtpstreamstats-codecid)
@property (nonatomic, strong)  NSString * codec_id;
@end

/// Statistical information about an incoming RTP (Real-time Transport Protocol) stream.
MILLICAST_API @interface MCReceivedRtpStreamStats : MCRtpStreamStats

/// The type of statistics.
+ (MCStatsType) get_type;

/// The number of RTP packets received since the start of streaming. See [packetsReceived](https://w3c.github.io/webrtc-stats/#dom-rtcreceivedrtpstreamstats-packetsreceived)
@property unsigned long long packets_received;

/// The variation in packet arrival times, indicating network congestion and latency issues. See [jitter](https://w3c.github.io/webrtc-stats/#dom-rtcreceivedrtpstreamstats-jitter)
@property double             jitter;

/// The number of RTP packets lost during transmission or due to network issues. See [packetsLost](https://w3c.github.io/webrtc-stats/#dom-rtcreceivedrtpstreamstats-packetslost)
@property long long          packets_lost;

/// The number of frames dropped during playback or processing. See [framesDropped](https://w3c.github.io/webrtc-stats/#dom-rtcinboundrtpstreamstats-framesdropped)
@property unsigned long long frames_dropped;

@end

/// Statistics for an inbound RTP stream.
MILLICAST_API @interface MCInboundRtpStreamStats : MCReceivedRtpStreamStats

/// Returns the type of statistics.
+ (MCStatsType) get_type;

/// The identifier of the remote endpoint from which the stream originates. See [remoteId](https://w3c.github.io/webrtc-stats/#dom-rtcinboundrtpstreamstats-remoteid)
@property (nonatomic, strong) NSString * remote_id;

/// The identifier associated with the track receiving the stream. See [trackIdentifier](https://w3c.github.io/webrtc-stats/#dom-rtcinboundrtpstreamstats-trackidentifier)
@property (nonatomic, strong) NSString * track_identifier;

/// The identifier of the media stream. See [mid](https://w3c.github.io/webrtc-stats/#dom-rtcinboundrtpstreamstats-mid)
@property (nonatomic, strong) NSString * mid;

/// The number of bytes received. See [bytesReceived](https://w3c.github.io/webrtc-stats/#dom-rtcinboundrtpstreamstats-bytesreceived)
@property unsigned long bytes_received;

/// The number of header bytes received. See  [headerBytesReceived](https://w3c.github.io/webrtc-stats/#dom-rtcinboundrtpstreamstats-headerbytesreceived)
@property unsigned long header_bytes_received;

/// The timestamp of the last received packet. See [lastPacketReceivedTimestamp](https://w3c.github.io/webrtc-stats/#dom-rtcinboundrtpstreamstats-lastpacketreceivedtimestamp)
@property double        last_packet_received_timestamp;

/// The current delay in the jitter buffer. See [jitterBufferDelay](https://w3c.github.io/webrtc-stats/#dom-rtcinboundrtpstreamstats-jitterbufferdelay)
@property double        jitter_buffer_delay;

/// The target delay set for the jitter buffer. See [jitterBufferTargetDelay](https://w3c.github.io/webrtc-stats/#dom-rtcinboundrtpstreamstats-jitterbuffertargetdelay)
@property double        jitter_buffer_target_delay;

/// The minimum delay configured for the jitter buffer. See [jitterBufferMinimumDelay](https://w3c.github.io/webrtc-stats/#ref-for-dom-rtcinboundrtpstreamstats-jitterbufferminimumdelay-1)
@property double        jitter_buffer_minimum_delay;

/// The number of packets emitted from the jitter buffer. See [jitterBufferEmittedCount](https://w3c.github.io/webrtc-stats/#dom-rtcinboundrtpstreamstats-jitterbufferemittedcount)
@property unsigned long jitter_buffer_emitted_count;

/// The estimated playout timestamp. See [estimatedPlayoutTimestamp](https://w3c.github.io/webrtc-stats/#dom-rtcinboundrtpstreamstats-estimatedplayouttimestamp)
@property double        estimated_playout_timestamp;

/// The number of Forward Error Correction (FEC) packets received during audio transmission. See [fecPacketsReceived](https://w3c.github.io/webrtc-stats/#dom-rtcinboundrtpstreamstats-fecpacketsreceived)
@property unsigned long fec_packets_received;

/// The number of discarded Forward Error Correction (FEC) packets received during audio transmission. See [fecPacketsDiscarded](https://w3c.github.io/webrtc-stats/#dom-rtcinboundrtpstreamstats-fecpacketsdiscarded)
@property unsigned long fec_packets_discarded;

/// The total number of audio samples received. See [totalSamplesReceived](https://w3c.github.io/webrtc-stats/#dom-rtcinboundrtpstreamstats-totalsamplesreceived)
@property unsigned long total_samples_received;

/// The number of concealed audio samples. See [concealedSamples](https://w3c.github.io/webrtc-stats/#dom-rtcinboundrtpstreamstats-concealedsamples)
@property unsigned long concealed_samples;

/// The number of silent concealed audio samples. See [silentConcealedSamples](https://w3c.github.io/webrtc-stats/#dom-rtcinboundrtpstreamstats-silentconcealedsamples)
@property unsigned long silent_concealed_samples;

/// The number of concealment events. See [concealmentEvents](https://w3c.github.io/webrtc-stats/#dom-rtcinboundrtpstreamstats-concealmentevents)
@property unsigned long concealment_events;

/// The number of inserted audio samples for deceleration. See [insertedSamplesForDeceleration](https://w3c.github.io/webrtc-stats/#dom-rtcinboundrtpstreamstats-insertedsamplesfordeceleration)
@property unsigned long inserted_samples_for_deceleration;

/// The number of removed audio samples for acceleration. See [removedSamplesForAcceleration](https://w3c.github.io/webrtc-stats/#dom-rtcinboundrtpstreamstats-removedsamplesforacceleration)
@property unsigned long removed_samples_for_acceleration;

/// The audio level of the stream. See [audioLevel](https://w3c.github.io/webrtc-stats/#dom-rtcinboundrtpstreamstats-audiolevel)
@property double        audio_level;

/// The total energy of the audio stream. See [totalAudioEnergy](https://w3c.github.io/webrtc-stats/#dom-rtcinboundrtpstreamstats-totalaudioenergy)
@property double        total_audio_energy;

/// The total duration of audio samples received. See [totalSamplesDuration](https://w3c.github.io/webrtc-stats/#dom-rtcinboundrtpstreamstats-totalaudioenergy)
@property double        total_samples_duration;

/// The number of video frames received. See [framesReceived](https://w3c.github.io/webrtc-stats/#dom-rtcinboundrtpstreamstats-framesreceived)
@property unsigned long frames_received;

/// The width of video frames. See [frameWidth](https://w3c.github.io/webrtc-stats/#dom-rtcinboundrtpstreamstats-framewidth)
@property unsigned long frame_width;

/// The height of video frames. See [frameHeight](https://w3c.github.io/webrtc-stats/#dom-rtcinboundrtpstreamstats-frameheight)
@property unsigned long frame_height;

/// The frame rate. See [framesPerSecond](https://w3c.github.io/webrtc-stats/#dom-rtcinboundrtpstreamstats-framespersecond)
@property double        frames_per_second;

/// The number of decoded video frames. See [framesDecoded](https://w3c.github.io/webrtc-stats/#dom-rtcinboundrtpstreamstats-framesdecoded)
@property unsigned long frames_decoded;

/// The number of decoded key frames. See [keyFramesDecoded](https://w3c.github.io/webrtc-stats/#dom-rtcinboundrtpstreamstats-keyframesdecoded)
@property unsigned long key_frames_decoded;

/// The total time spent on decoding. See [totalDecodeTime](https://w3c.github.io/webrtc-stats/#dom-rtcinboundrtpstreamstats-totaldecodetime)
@property double total_decode_time;

/// The total video processing delay. See [totalProcessingDelay](https://w3c.github.io/webrtc-stats/#dom-rtcinboundrtpstreamstats-totalprocessingdelay)
@property double total_processing_delay;

/// The total time spent on video frame assembly. See [totalAssemblyTime](https://w3c.github.io/webrtc-stats/#dom-rtcinboundrtpstreamstats-totalassemblytime)
@property double total_assembly_time;

/// The number of video frames assembled from multiple packets. See [framesAssembledFromMultiplePackets](https://w3c.github.io/webrtc-stats/#dom-rtcinboundrtpstreamstats-framesassembledfrommultiplepackets)
@property unsigned long frames_assembled_from_multiple_packets;

/// The total inter-frame delay during video transmission. See [totalInterFrameDelay](https://w3c.github.io/webrtc-stats/#dom-rtcinboundrtpstreamstats-totalinterframedelay)
@property double total_inter_frame_delay;

/// The total squared inter-frame delay during video transmission. See [totalSquaredInterFrameDelay](https://w3c.github.io/webrtc-stats/#dom-rtcinboundrtpstreamstats-totalsquaredinterframedelay)
@property double total_squared_inter_frame_delay;

/// The implementation details of the decoder. See [decoderImplementation](https://w3c.github.io/webrtc-stats/#dom-rtcinboundrtpstreamstats-decoderimplementation)
@property (nonatomic, strong) NSString * decoder_implementation;

/// The number of Full Intra Request (FIR) packets. See [firCount](https://w3c.github.io/webrtc-stats/#dom-rtcinboundrtpstreamstats-fircount)
@property unsigned long fir_count;

/// The number of Picture Loss Indication (PLI) packets. See [pliCount](https://w3c.github.io/webrtc-stats/#dom-rtcinboundrtpstreamstats-plicount)
@property unsigned long pli_count;

/// The number of Negative Acknowledgment (NACK) packets. See [nackCount](https://w3c.github.io/webrtc-stats/#dom-rtcinboundrtpstreamstats-nackcount)
@property unsigned long nack_count;

/// The minimum playout delay during video transmission.
@property double min_playout_delay;

@end

/// Statistics related to an outgoing RTP stream.
MILLICAST_API @interface MCSentRtpStreamStats : MCRtpStreamStats

/// Returns the type of statistics.
+ (MCStatsType) get_type;

/// The number of RTP packets successfully sent over the network. See [packetsSent](https://w3c.github.io/webrtc-stats/#dom-rtcsentrtpstreamstats-packetssent)
@property unsigned long      packets_sent;

/// The number of bytes sent in RTP packets over the network. See [bytesSent](https://w3c.github.io/webrtc-stats/#dom-rtcsentrtpstreamstats-bytessent)
@property unsigned long long bytes_sent;
@end

/// Statistics about the outbound RTP streams
MILLICAST_API @interface MCOutboundRtpStreamStats : MCSentRtpStreamStats

/// Returns the type of statistics.
+ (MCStatsType) get_type;

/// The identifier of the sender of the RTP stream.
@property (nonatomic, strong) NSString * sender_id;

/// The identifier of the remote user receiving the stream. See [remoteId](https://w3c.github.io/webrtc-stats/#dom-rtcoutboundrtpstreamstats-remoteid)
@property (nonatomic, strong) NSString *   remote_id;

/// The number of retransmitted packets. See [retransmittedPacketsSent](https://w3c.github.io/webrtc-stats/#dom-rtcoutboundrtpstreamstats-retransmittedpacketssent)
@property unsigned long long retransmitted_packets_sent;

/// The number of bytes sent for headers. See [headerBytesSent](https://w3c.github.io/webrtc-stats/#dom-rtcoutboundrtpstreamstats-headerbytessent)
@property unsigned long long header_bytes_sent;

/// The amount of retransmitted data. See [retransmittedBytesSent](https://w3c.github.io/webrtc-stats/#dom-rtcoutboundrtpstreamstats-retransmittedbytessent)
@property unsigned long long retransmitted_bytes_sent;

/// The target bitrate. See [targetBitrate](https://w3c.github.io/webrtc-stats/#dom-rtcoutboundrtpstreamstats-targetbitrate)
@property double        target_bitrate;

/// The cumulative delay during sending packets. See [totalPacketSendDelay](https://w3c.github.io/webrtc-stats/#dom-rtcoutboundrtpstreamstats-totalpacketsenddelay)
@property double        total_packet_send_delay;

/// The number of encoded video frames. See [framesEncoded](https://w3c.github.io/webrtc-stats/#dom-rtcoutboundrtpstreamstats-framesencoded)
@property unsigned long frames_encoded;

/// The number of encoded key frames. See [keyFramesEncoded](https://w3c.github.io/webrtc-stats/#dom-rtcoutboundrtpstreamstats-keyframesencoded)
@property unsigned long key_frames_encoded;

/// The number of bytes encoded to meet video target bitrate. See [totalEncodedBytesTarget](https://w3c.github.io/webrtc-stats/#dom-rtcoutboundrtpstreamstats-totalencodedbytestarget)
@property unsigned long long total_encoded_bytes_target;

/// The width of video frames. See [frameWidth](https://w3c.github.io/webrtc-stats/#dom-rtcoutboundrtpstreamstats-framewidth)
@property unsigned long frame_width;

/// The height of video frames. See [frameHeight](https://w3c.github.io/webrtc-stats/#dom-rtcoutboundrtpstreamstats-frameheight)
@property unsigned long frame_height;

/// The frame rate of the video stream. See [framesPerSecond](https://w3c.github.io/webrtc-stats/#dom-rtcoutboundrtpstreamstats-framespersecond)
@property double        frames_per_second;

/// The number of video frames successfully sent. See [framesSent](https://w3c.github.io/webrtc-stats/#dom-rtcoutboundrtpstreamstats-framessent)
@property unsigned long frames_sent;

/// The number of huge video frames successfully sent. See [hugeFramesSent](https://w3c.github.io/webrtc-stats/#dom-rtcoutboundrtpstreamstats-hugeframessent)
@property unsigned long huge_frames_sent;

/// The reason for any quality limitations in the video stream. See [qualityLimitationReason](https://w3c.github.io/webrtc-stats/#dom-rtcoutboundrtpstreamstats-qualitylimitationreason)
@property (nonatomic, strong) NSString *   quality_limitation_reason;

/// The duration of quality limitations experienced. See [qualityLimitationDurations](https://w3c.github.io/webrtc-stats/#dom-rtcoutboundrtpstreamstats-qualitylimitationdurations)
@property (nonatomic, strong) NSString *   quality_limitation_durations;

/// The number of resolution changes due to quality limitations. See [qualityLimitationResolutionChanges](https://w3c.github.io/webrtc-stats/#dom-rtcoutboundrtpstreamstats-qualitylimitationresolutionchanges)
@property unsigned long quality_limitation_resolution_changes;

/// Information about the encoder used for stream encoding. See [encoderImplementation](https://w3c.github.io/webrtc-stats/#dom-rtcoutboundrtpstreamstats-encoderimplementation)
@property (nonatomic, strong) NSString *   encoder_implementation;

/// The number of Full Intra Request (FIR) messages sent. See [firCount](https://w3c.github.io/webrtc-stats/#dom-rtcoutboundrtpstreamstats-fircount)
@property unsigned long fir_count;

/// The number of Picture Loss Indication (PLI) messages sent. See [pliCount](https://w3c.github.io/webrtc-stats/#dom-rtcoutboundrtpstreamstats-plicount)
@property unsigned long pli_count;

/// The number of Negative Acknowledgment (NACK) messages sent. See [nackCount](https://w3c.github.io/webrtc-stats/#dom-rtcoutboundrtpstreamstats-nackcount)
@property unsigned long nack_count;

/// The sum of Quantization Parameters (QP) used during encoding. See [qpSum](https://w3c.github.io/webrtc-stats/#dom-rtcoutboundrtpstreamstats-qpsum)
@property unsigned long long qp_sum;


@end

/// Statistics related to an outgoing remote RTP stream.
MILLICAST_API @interface MCRemoteOutboundRtpStreamStats : MCSentRtpStreamStats

/// Returns the type of statistics.
+ (MCStatsType) get_type;

/// The identifier of the media source associated with the outbound RTP stream.
@property (nonatomic, strong) NSString * media_source_id;

/// The remote endpoint or destination of the outbound RTP stream.
@property (nonatomic, strong) NSString * remote_id;

/// The local identifier associated with the outbound RTP stream. See [localId](https://w3c.github.io/webrtc-stats/#dom-rtcremoteoutboundrtpstreamstats-localid)
@property (nonatomic, strong) NSString * local_id;

/// The timestamp of the remote endpoint related to the stream. See [remoteTimestamp](https://w3c.github.io/webrtc-stats/#dom-rtcremoteoutboundrtpstreamstats-remotetimestamp)
@property long long remote_timestamp;

/// The number of reports sent for monitoring the outbound stream. See [reportsSent](https://w3c.github.io/webrtc-stats/#dom-rtcremoteoutboundrtpstreamstats-reportssent)
@property unsigned long long reports_sent;

/// The number of round-trip time measurements taken. See [roundTripTimeMeasurements](https://w3c.github.io/webrtc-stats/#dom-rtcremoteoutboundrtpstreamstats-roundtriptimemeasurements)
@property unsigned long long round_trip_time_measurements;

/// The round-trip time for packets sent between the local and remote endpoints. See [roundTripTime](https://w3c.github.io/webrtc-stats/#dom-rtcremoteoutboundrtpstreamstats-roundtriptime)
@property double round_trip_time;

/// The sum of round-trip times for packets sent between endpoints. See [totalRoundTripTime](https://w3c.github.io/webrtc-stats/#dom-rtcremoteoutboundrtpstreamstats-totalroundtriptime)
@property double total_round_trip_time;

@end

/// Statistics about an incoming remote RTP stream.
MILLICAST_API @interface MCRemoteInboundRtpStreamStats : MCReceivedRtpStreamStats

/// Returns the type of statistics.
+ (MCStatsType) get_type;

/// The local identifier associated with the remote inbound RTP stream. See [localId](https://w3c.github.io/webrtc-stats/#dom-rtcremoteinboundrtpstreamstats-localid)
@property (nonatomic, strong) NSString * local_id;

/// The round-trip time for packets sent between the local and remote endpoints. See [roundTripTime](https://w3c.github.io/webrtc-stats/#dom-rtcremoteinboundrtpstreamstats-roundtriptime)
@property double round_trip_time;

/// The sum of round-trip times for packets sent between endpoints. See [totalRoundTripTime](https://w3c.github.io/webrtc-stats/#dom-rtcremoteinboundrtpstreamstats-totalroundtriptime)
@property double total_round_trip_time;

/// The number of round-trip time measurements. See [roundTripTimeMeasurements](https://w3c.github.io/webrtc-stats/#dom-rtcremoteinboundrtpstreamstats-roundtriptimemeasurements)
@property long long round_trip_time_measurements;

/// The fraction of RTP packets lost during transmission or due to network issues. See [fractionLost](https://w3c.github.io/webrtc-stats/#dom-rtcremoteinboundrtpstreamstats-fractionlost)
@property double fraction_lost; // fraction packet loss
@end

/// The MCMediaSourceStats class gathers statistics details.
MILLICAST_API @interface MCMediaSourceStats : MCStats

/// Returns the type of statistics.
+ (MCStatsType) get_type;

/// The identifier of the track. see [trackIdentifier](https://w3c.github.io/webrtc-stats/#dom-rtcmediasourcestats-trackidentifier)
@property (nonatomic, strong) NSString * track_identifier;

///  The track type. See [kind](https://w3c.github.io/webrtc-stats/#dom-rtcmediasourcestats-kind)
@property (nonatomic, strong) NSString * kind;
@end

/// Statistics representing a video track that is attached to one or more senders.
MILLICAST_API @interface MCVideoSourceStats : MCMediaSourceStats

/// Returns the type of statistics.
+ (MCStatsType) get_type;

/// The width of the video source. See [width](https://w3c.github.io/webrtc-stats/#dom-rtcvideosourcestats-width)
@property unsigned long width;

/// The height of the video source. See [height](https://w3c.github.io/webrtc-stats/#dom-rtcvideosourcestats-height)
@property unsigned long height;

/// The number of frames. See [frames](https://w3c.github.io/webrtc-stats/#dom-rtcvideosourcestats-frames)
@property unsigned long frames;

/// The frame rate of the video source. See [framesPerSecond](https://w3c.github.io/webrtc-stats/#dom-rtcvideosourcestats-framespersecond)
@property double        frames_per_second;
@end

/// Stastistics representing an audio track that is attached to one or more senders.
MILLICAST_API @interface MCAudioSourceStats : MCMediaSourceStats

/// Returns the type of statistics.
+ (MCStatsType) get_type;

/// The current audio level. See [audioLevel](https://w3c.github.io/webrtc-stats/#dom-rtcaudiosourcestats-audiolevel)
@property double audio_level;

/// The cumulative energy of the audio signal over a period. See [totalAudioEnergy](https://w3c.github.io/webrtc-stats/#dom-rtcaudiosourcestats-totalaudioenergy)
@property double total_audio_energy;

/// The total duration of audio samples processed. See [totalSamplesDuration](https://w3c.github.io/webrtc-stats/#dom-rtcaudiosourcestats-totalsamplesduration)
@property double total_samples_duration;

/// The amount of echo signal lost in transmission or processing. See [echoReturnLoss](https://w3c.github.io/webrtc-stats/#dom-rtcaudiosourcestats-echoreturnloss)
@property double echo_return_loss;

/// The improvement in echo cancellation performance. See [echoReturnLossEnhancement](https://w3c.github.io/webrtc-stats/#dom-rtcaudiosourcestats-echoreturnlossenhancement)
@property double echo_return_loss_enhancement;
@end

/// Interface is a container for various different statistics.
MILLICAST_API @interface MCStatsReport : NSObject

/// Adds a MCStats object to the stats report, effectively storing statistical data for analysis and reporting purposes.
/// - Parameters:
///   - obj: A stats object.
- (void) addStats:(MCStats*) obj; //__attribute((ns_consumed)) obj;

/// Retrieves a specific MCStats object from the report based on its unique identifier.
/// - Parameters:
///   - statsId: A unique identifier. See ``MCStats/sid``
/// - Returns: a stats object of a specifc kind.
- (MCStats*) get:(NSString*)statsId;

/// Retrieves an array of MCStats objects from the report that match a specified MCStatsType.
/// - Parameters:
///   - type: The desired type of statistics. See ``MCStatsType``
/// - Returns: An array containing the stats of the specified type.
- (NSArray<MCStats*>*) getStatsOfType:(MCStatsType)type;

/// The number of MCStats objects stored in the stats report.
/// - Returns: The number of stats objects in the report.
- (int) size;

@end
