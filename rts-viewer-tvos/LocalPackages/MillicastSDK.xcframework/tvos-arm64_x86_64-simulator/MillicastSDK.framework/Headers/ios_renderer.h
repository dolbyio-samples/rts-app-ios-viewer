#import <UIKit/UIView.h>
#import <MillicastSDK/renderer.h>

@protocol MCIosVideoRendererDelegate <NSObject>

- (void) didChangeVideoSize:(CGSize) size;

@end

/**
 * @brief The purpose of this interface is to render video frames in a UI view. (iOS and tvOS)
 */

MILLICAST_API @interface MCIosVideoRenderer : NSObject <MCVideoRenderer>

@property (nonatomic, weak) id<MCIosVideoRendererDelegate> delegate;

- (instancetype) initWithOpenGLRenderer: (BOOL) enable; /**< Initializes the renderer to use OpenGL. By default, Metal is used. */
- (instancetype) initWithColorRangeExpansion: (BOOL) enable; /**< Initialize with the option of expanding limited color range to full range upon rendering. */
- (instancetype) initWithOpenGLRenderer: (BOOL) enable colorRangeExpansion:(BOOL) enableCRE; /**< Initializes the renderer to use OpenGL. By default, Metal is used. Can optionally enable color range expansion to expand limited color range received to full range before rendering.*/
- (UIView*) getView; /**< Get the view in which are rendered video frame so you can add it in your UI.*/
- (float) getWidth; /**< Get the width of the WebRTC video frame.*/
- (float) getHeight; /**< Get the height of the WebRTC video frame.*/
@end
