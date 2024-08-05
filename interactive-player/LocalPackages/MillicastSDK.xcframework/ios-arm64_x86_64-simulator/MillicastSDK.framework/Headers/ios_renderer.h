#import <UIKit/UIView.h>
#import <MillicastSDK/renderer.h>

/// Protocol that allows subscribing to callbacks that inform about rendering video frame size changes.
@protocol MCIosVideoRendererDelegate <NSObject>

/// Called when the size of the rendered video changes, providing the new size as a CGSize parameter.
/// - Parameters:
///   - size: The new video frame size.
- (void) didChangeVideoSize:(CGSize) size;

@end

/// Classs that renders video frames in a ``UIView``.
MILLICAST_API @interface MCIosVideoRenderer : NSObject <MCVideoRenderer>


/// Delegate that can be used to receive information about video frame properties.
@property (nonatomic, weak) id<MCIosVideoRendererDelegate> delegate;

/// Initialize the renderer with OpenGL support. By default, Metal is used.
/// - Parameters:
///   - enable: True to enable OpenGL. Disabled by default.
- (instancetype) initWithOpenGLRenderer: (BOOL) enable;

/// Initializes with the option of expanding limited color range to the full range upon rendering.
/// - Parameters:
///   - enable: True to enable color range expansion. Disabled by default.
- (instancetype) initWithColorRangeExpansion: (BOOL) enable;

/// Initializes the renderer to use OpenGL and or color range expansion support. See ``MCIosVideoRenderer/initWithColorRangeExpansion:`` and ``MCIosVideoRenderer/initWithOpenGLRenderer:`` for more information.
/// - Parameters:
///   - enable: Enable OpenGL support.
///   - enableCRE: Enable Color Range Expansion.
- (instancetype) initWithOpenGLRenderer: (BOOL) enable colorRangeExpansion:(BOOL) enableCRE;

/// Get the ``UIView`` that you can add it in your UI that allows rendering video frames.
/// - Returns a ``UIView`` ready for rendering.
- (UIView*) getView;

/// Get the width of the WebRTC video frame.
/// - Returns: Width of the WebRTC video frame.
- (float) getWidth;

/// Get the height of the WebRTC video frame.
/// - Returns Height of the WebRTC video frame.
- (float) getHeight;
@end
