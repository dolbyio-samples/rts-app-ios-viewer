#import <MillicastSDK/exports.h>


#ifdef __cplusplus
/// The VideoType enum represent the pixel format used for video frames.
enum MCVideoType {
  UNKNOWN,
  I420,
  I444,
  I210,
  IYUV,
  RGB24,
  ARGB,
  RGB565,
  YUY2,
  YV12,
  UYVY,
  MJPEG,
  BGRA,
  NV12,
  NATIVE
};
#else
/// The VideoType enum represent the pixel format used for video frames.
typedef enum {
  UNKNOWN,
  I420,
  I444,
  I210,
  IYUV,
  RGB24,
  ARGB,
  RGB565,
  YUY2,
  YV12,
  UYVY,
  MJPEG,
  BGRA,
  NV12,
  NATIVE
} MCVideoType;
#endif

/// This VideoCapabilities class represents the video capabilities of a video track.
MILLICAST_API @interface MCVideoCapabilities : NSObject

/// The width of the captured video frame.
@property int width;

/// The height of the captured video frame.
@property int height;

/// The frame rate that defines the number of frames per second that the video track should be capable of delivering or receiving.
@property int fps;

/// The pixel format to use for the capture.
@property MCVideoType format;

/// Gets the pixel format as a string
- (NSString *)formatAsString;

@end
