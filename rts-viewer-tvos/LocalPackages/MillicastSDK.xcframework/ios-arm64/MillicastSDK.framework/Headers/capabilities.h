/**
  * @file capabilities.h
  * @author David Baldassin
  * @copyright Copyright 2021 CoSMoSoftware.
  * @date 07/2021
  */

#import <MillicastSDK/exports.h>

/**
  * @brief The VideoType enum represent the pixel format used for video frames.
*/

#ifdef __cplusplus
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
};
#else
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
} MCVideoType;
#endif

/**
 * @brief The VideoCapabilities struct
 */

MILLICAST_API @interface MCVideoCapabilities : NSObject

@property int width; /**< The width of the captured video frame */
@property int height; /**< The height of the captured video frame */
@property int fps; /**< The frame rate at which the capture device shall capture */
@property MCVideoType format; /**< The pixel format to use for the capture */

- (NSString *)formatAsString; /**< Get the pixel format as a std::string */

@end
