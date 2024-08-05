#ifndef obj_c_errors_h
#define obj_c_errors_h

#import <Foundation/Foundation.h>
#import <MillicastSDK/exports.h>

extern NSErrorDomain const MCGenericErrorDomain;
/// Generic errors returned by the SDK.
typedef NS_ERROR_ENUM(MCGenericErrorDomain, MCGenericError) {
  /// Exception was thrown and not handled.
  MCGenericErrorExceptionThrown = 1,
  /// Signaling provided invalid JSON.
  MCGenericErrorInvalidJSON,
  /// Signaling provided JSON with missing or incorrect data.
  MCGenericErrorInvalidJSONSchema,
  /// Signaling returned error for the request.
  MCGenericErrorTransactionError,
  /// No credentials are set.
  MCGenericErrorNoCredentials,
  /// Invalid options set for the request.
  MCGenericErrorInvalidOptions,
  /// Invalid state of the client.
  MCGenericErrorInvalidState,
  /// Director REST API returned an error.
  MCGenericErrorRestAPIError,
  /// Websocket not connected.
  MCGenericErrorWebsocketHasFailed,
  /// Can not create PeerConnection.
  MCGenericErrorPeerConnectionCreate,
  /// Can not create PeerConnection offer.
  MCGenericErrorPeerConnectionCreateOffer,
  /// Can not set PeerConnection local description.
  MCGenericErrorPeerConnectionLocalDesc,
  /// Can not set PeerConnection remote description.
  MCGenericErrorPeerConnectionRemoteDesc,
  /// Can not add tracks to the peer connection.
  MCGenericErrorPeerConnectionAddTracksFailed,
  /// PeerConnection was not established.
  MCGenericErrorPeerConnectionNotEstablished,
  /// Listener not set while it should be.
  MCGenericErrorNullListener,
};

extern NSErrorDomain const MCAsyncOperationCancelledErrorDomain;
/// Error category for errors triggered when the operation failed because
/// it was abandoned for various reasons.
typedef NS_ERROR_ENUM(MCAsyncOperationCancelledErrorDomain, MCAsyncOperationCancelledError) {
  /// Internal SDK logic error.
  MCAsyncOperationCancelledErrorMultipleResolve = 1,
  /// Operation was cancelled because a newer request made it
  /// obsolete.
  MCAsyncOperationCancelledErrorAborted,
  /// Operation was cancelled for unspecified reasons.
  MCAsyncOperationCancelledErrorAbandoned,
  /// Operation was cancelled because shutdown or disconnection in progress.
  MCAsyncOperationCancelledErrorActorShutdown,
  /// Operation was cancelled due to a timeout.
  MCAsyncOperationCancelledErrorTimeout,
};

extern NSErrorDomain const MCInternalSDKErrorDomain;
/// Error category for unidentified errors. Usually representing a bug.
typedef NS_ERROR_ENUM(MCInternalSDKErrorDomain, MCInternalSDKError) {
  /// Uknown error.
  MCInternalSDKErrorUnkown = 1,
};

#endif /* obj_c_errors_h */
