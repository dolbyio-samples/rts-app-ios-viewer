/**
  * @file mc_logging.h
  * @author David Baldassin
  * @copyright Copyright 2021 CoSMoSoftware.
  * @date 07/2021
  */

/**
* @brief The LogLevel enum specify the severity of a log message.
*/

#import <UIKit/UIKit.h>
#import <MillicastSDK/exports.h>

#ifdef __cplusplus
enum MCLogLevel {
  MC_FATAL, /**< When a fatal error occured and the programm will exit */
  MC_ERROR, /**< When an error occured */
  MC_WARNING, /**< Warn the user about something, but does not prevent a normal utilisation */
  MC_LOG, /**< General info about what happen and which steps are performed */
  MC_DEBUG /**< Debug message */
};
#else
typedef enum {
  MC_FATAL, /**< When a fatal error occured and the programm will exit */
  MC_ERROR, /**< When an error occured */
  MC_WARNING, /**< Warn the user about something, but does not prevent a normal utilisation */
  MC_LOG, /**< General info about what happen and which steps are performed */
  MC_DEBUG /**< Debug message */
} MCLogLevel;
#endif

/**
 * @brief The delegate to receive log message from the sdk
 */

@protocol MCLoggerDelegate <NSObject>

/**
 * @brief Implement this function to receive log message
 * @param message The message
 * @param level The severity level. See MCLogLevel
 */
- (void)onLogWithMessage:(NSString*)message Level:(MCLogLevel)level;

@end

/**
 * @brief The logger object. Add your own delegate to receive log messages from the sdk
 */

MILLICAST_API @interface MCLogger : NSObject

+ (void) setDelegate:(id<MCLoggerDelegate>) delegate;

@end
