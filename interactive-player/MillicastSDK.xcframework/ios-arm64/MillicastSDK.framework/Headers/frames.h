#ifndef MILLICAST_FRAMES_H
#define MILLICAST_FRAMES_H

#import <MillicastSDK/capabilities.h>

/**
 * @brief The VideoFrame interface used to described a VideoFrame
 */

MILLICAST_API @protocol MCVideoFrame<NSObject>

/**
 * @brief Get the width of the video frame
 * @return The width
 */

- (int) width;

/**
 * @brief Get the height of the video frame
 * @return The height
 */

- (int) height;

- (MCVideoType) frameType;

/**
 * @brief Get the buffer size for the specified video type.
 */

- (uint32_t) sizeRgb;
- (uint32_t) sizeI420;
- (uint32_t) sizeI444;

/**
 * @brief Get the video frame buffer as the video type specified in parameter.
 * @param buffer The buffer to be filled on  the user side
 * @return The video frame buffer.
 */
- (void) getRgbBuffer:(uint8_t*) buffer;
- (void) getI420Buffer:(uint8_t*) buffer;
- (void) getI444Buffer:(uint8_t*) buffer;

@end


/**
 * @brief The AudioFrame interface used to described audio data.
 */

MILLICAST_API @interface MCAudioFrame : NSObject

@property const void* data; /**< The audio data */
@property int bitsPerSample; /**< The number of bits per sample, usually 16 bits */
@property int sampleRate; /**< The sample rate of the audio data, usually 48kHz */
@property size_t channelNumber; /**< The number of channels used */
@property size_t frameNumber; /**< The number of samples in the data array */

@end


#endif /* FRAMES_H */
