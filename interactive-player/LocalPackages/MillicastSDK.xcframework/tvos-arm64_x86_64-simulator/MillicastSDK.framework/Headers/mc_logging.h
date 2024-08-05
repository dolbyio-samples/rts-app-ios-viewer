#import <Foundation/Foundation.h>
#import <MillicastSDK/exports.h>

#ifdef __cplusplus
/// Enum to specify the severity of a log message.
enum MCLogLevel {
  /// Logs disabled.
  MC_OFF,
  /// When an error occured.
  MC_ERROR,
  /// Warn the user about something, but does not prevent a normal utilisation.
  MC_WARNING,
  /// General info about what happens and which steps are performed.
  MC_LOG,
  /// Debug message.
  MC_DEBUG,
  /// Very verbose log message.
  MC_VERBOSE
};
#else
/// Enum to specify the severity of a log message.
typedef enum {
  /// Logs disabled.
  MC_OFF,
  /// When an error occured.
  MC_ERROR,
  /// Warn the user about something, but does not prevent a normal utilisation.
  MC_WARNING,
  /// General info about what happens and which steps are performed.
  MC_LOG,
  /// Debug message.
  MC_DEBUG,
  /// Very verbose log message.
  MC_VERBOSE
} MCLogLevel;
#endif

/// Delegate that receives events from ``MCLogger``
MILLICAST_API @protocol MCLoggerDelegate <NSObject>

/// Called whenever a log message is emitted.
/// - Parameters:
///   - message: The log message.
///   - level: The severity level. For more information, see ``MCLogLevel``.
- (void)onLogWithMessage:(NSString*)message Level:(MCLogLevel)level;

@end

/// Class that is responsible for managing SDK logs.
MILLICAST_API @interface MCLogger : NSObject

/// Set a delegate that receives log messages.
/// - Parameters:
///   - delegate: ``MCLoggerDelegate`` that receives log messages.
+ (void) setDelegate:(id<MCLoggerDelegate>) delegate;

/// Set the LogLevel for the SDK/Webrtc/Websocket modules
/// - Parameters:
///   - Sdk: `MCLogLevel` sets the log level for the SDK.
///   - Webrtc: `MCLogLevel` sets the log level for Webrtc.
///   - Websocket: `MCLogLevel` sets the log level for Websocket.
+ (void)setLogLevelWithSdk:(MCLogLevel)sdkLogLevel 
                    Webrtc:(MCLogLevel)webrtcLogLevel 
                 Websocket:(MCLogLevel)websocketLogLevel;

/// Disable websocket logs.
/// - Parameters:
///   - disable: True to disable the logs. False otherwise.
+ (void) disableWebsocketLogs:(BOOL) disable;
@end
