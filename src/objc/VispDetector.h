#import <UIKit/UIKit.h>
#import <visp3/core/vpTranslationVector.h>

@interface VispDetector : NSObject

- (void)detectAprilTag:(UIImage *)image px:(float)px py:(float)py tagId:(int)tagId completion:(void (^)(UIImage * _Nullable, vpTranslationVector))completion;

@end