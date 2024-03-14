#ifndef obj_c_errors_h
#define obj_c_errors_h

#import <Foundation/Foundation.h>

extern NSErrorDomain const MCGenericErrorDomain;
typedef NS_ERROR_ENUM(MCGenericErrorDomain, MCGenericError) {
  MCGenericErrorExceptionThrown = 1,
  MCGenericErrorInvalidJSON,
  MCGenericErrorInvalidJSONSchema,
  MCGenericErrorTransactionError,
  MCGenericErrorNoCredentials,
  MCGenericErrorInvalidOptions,
  MCGenericErrorInvalidState,
  MCGenericErrorRestAPIError,
  MCGenericErrorWebsocketHasFailed,
  MCGenericErrorPeerConnectionCreate,
  MCGenericErrorPeerConnectionCreateOffer,
  MCGenericErrorPeerConnectionLocalDesc,
  MCGenericErrorPeerConnectionRemoteDesc,
  MCGenericErrorPeerConnectionAddTracksFailed,
  MCGenericErrorPeerConnectionNotEstablished,
  MCGenericErrorNullListener,
};

extern NSErrorDomain const MCAsyncOperationCancelledErrorDomain;
typedef NS_ERROR_ENUM(MCAsyncOperationCancelledErrorDomain, MCAsyncOperationCancelledError) {
  MCAsyncOperationCancelledErrorMultipleResolve = 1,
  MCAsyncOperationCancelledErrorAborted,
  MCAsyncOperationCancelledErrorAbandoned,
  MCAsyncOperationCancelledErrorActorShutdown,
  MCAsyncOperationCancelledErrorTimeout,
};

extern NSErrorDomain const MCInternalSDKErrorDomain;
typedef NS_ERROR_ENUM(MCInternalSDKErrorDomain, MCInternalSDKError) {
  MCInternalSDKErrorUnkown = 1,
};

#endif /* obj_c_errors_h */
