#ifndef MILLICAST_FRAMES_H
#define MILLICAST_FRAMES_H

#import <CoreMedia/CoreMedia.h>

#import <MillicastSDK/capabilities.h>

/// This class represents a raw Video Frame. Used
/// with ``MCVideoRenderer`` for playback.
MILLICAST_API @protocol MCVideoFrame<NSObject>

/// The width of the video frame.
/// - Returns: the width of the video frame.
- (int) width;

/// The height of the video frame.
/// - Returns: The height of the video frame
- (int) height;

/// The pixel format. For example, can be an I420 or a I444 frame.
/// - Returns: ``MCVideoType`` representing the pixel format.
- (MCVideoType) frameType;

/// If the frame was an RGB frame, then this will return size of the frame in bytes.
/// - Returns: The actual size if it was an RGB frame, 0 otherwise.
- (uint32_t) sizeRgb;

/// If the frame was an I420 frame, then this will return size of the frame in bytes.
/// - Returns: The actual size if it was an I420 frame, 0 otherwise.
- (uint32_t) sizeI420;

/// If the frame was an I444 frame, then this will return size of the frame in bytes.
/// - Returns: The actual size if it was an I444 frame, 0 otherwise.
- (uint32_t) sizeI444;

/// Get the video frame buffer as an RGB frame. Performs the necessary conversion.
/// - Parameters:
///   - buffer: The pre-allocated buffer to be filled on the user side. buffer needs to fit ``MCVideoFrame/sizeRgb`` bytes.
- (void) getRgbBuffer:(uint8_t*) buffer;

/// Get the video frame buffer as an I420 frame. Performs the necessary conversion.
/// - Parameters:
///   - buffer: The pre-allocated buffer to be filled on the user side. buffer needs to fit ``MCVideoFrame/sizeI420`` bytes.
- (void) getI420Buffer:(uint8_t*) buffer;

/// Get the video frame buffer as an I444 frame. Performs the necessary conversion.
/// - Parameters:
///   - buffer: The pre-allocated buffer to be filled on the user side. buffer needs to fit ``MCVideoFrame/sizeI444`` bytes.
- (void) getI444Buffer:(uint8_t*) buffer;

@end


/// Audio frame that contains audio data. Used with ``MCCustomAudioSource/onAudioFrame:``
/// to feed custom audio frames into source used by a ``MCPublisher``.
/// ```
/// var frame: MCAudioFrame = MCAudioFrame()
/// var source: MCCustomAudioSourceBuilder().build()
/// frame.bitsPerSample = 32; // We are using Float32 as an example
/// frame.channelNumber = numChannels
/// frame.sampleRate = Int32(sampleRate)
/// frame.frameNumber = Int(sampleRate * chunkTime / 1000);
/// // Imagine audioData is a pointer to some data
/// frame.data = UnsafeRawPointer(audioData)
/// source.onAudioFrame(frame)
/// ```
MILLICAST_API @interface MCAudioFrame : NSObject

/// The audio data containing raw audio samples.
@property const void* data;

/// The number of bits per audio sample.
@property int bitsPerSample;

/// The sample rate of the audio data, which is either 48kHz or 44.1kHz.
@property int sampleRate;

/// The number of audio channels defining whether the audio is mono, stereo, or has more complex channel configurations.
@property size_t channelNumber;

/// The number of frames in the data array. The number of frames is dependent on the sample rate and chunk time.
@property size_t frameNumber;

@end

/// Class responsible for initializing a ``MCAudioFrame``  from a ``CMSampleBuffer``
MILLICAST_API @interface MCCMSampleBufferFrame: MCAudioFrame

/// Initialize with a ``CMSampleBuffer``
/// ```
/// let sampleBuffer: CMSampleBuffer = ...
/// let source = MCCustomAudioSourceBuilder().build()
/// source.onAudioFrame(MCCMSampleBufferFrame(sampleBuffer))
/// ```
- (id) initWithSampleBuffer: (CMSampleBufferRef) buffer;

@end

#endif /* FRAMES_H */
