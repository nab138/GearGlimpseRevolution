#import <UIKit/UIKit.h>

@interface VispDetector : NSObject

- (void)detectAprilTag:(UIImage * _Nonnull)image 
                    px:(float)px 
                    py:(float)py 
                 tagId:(int)requiredTagId 
            completion:(void (^ _Nonnull)(UIImage * _Nullable, float x, float y, float z))completion;

@end

