#import "VispDetector.h"
#include <Foundation/NSObjCRuntime.h>
#import "ImageConversion.h"
#import "ImageDisplayWithContext.h"

vpDetectorAprilTag detector(vpDetectorAprilTag::TAG_36h11, vpDetectorAprilTag::HOMOGRAPHY_VIRTUAL_VS);

@implementation VispDetector

- (UIImage *)detectAprilTag:(UIImage *)image px:(float)px py:(float)py {

    // make vpImage for the detection.
    vpImage<unsigned char> I = [ImageConversion vpImageGrayFromUIImage:image];

    float u0 = I.getWidth() / 2;
    float v0 = I.getHeight() / 2;

    // in case, intrinsic parameter is not worked.
    if(px == 0.0 && py == 0.0){
        px = 1515.0;
        py = 1515.0;
    }

    // AprilTag detections setting
    float quadDecimate = 3.0;
    int nThreads = 1;
    double tagSize = 0.043; // meter
    detector.setAprilTagQuadDecimate(quadDecimate);
    detector.setAprilTagNbThreads(nThreads);

    // Detection.
    vpCameraParameters cam;
    cam.initPersProjWithoutDistortion(px, py, u0, v0);
    std::vector<vpHomogeneousMatrix> cMo_vec;
    detector.detect(I, tagSize, cam, cMo_vec);

    // Start drawing with a transparent context
    UIGraphicsBeginImageContextWithOptions(image.size, NO, image.scale);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // Flip the context vertically to match the coordinate system
    CGContextTranslateCTM(context, 0, image.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);

    // draw frames by each tag.
    int tagNums = (int) detector.getNbObjects();
    for (int i = 0; i < tagNums; i++) {

        // parameters
        std::vector<vpImagePoint> polygon = detector.getPolygon(i);
        vpImagePoint cog = detector.getCog(i);
        vpTranslationVector trans = cMo_vec[i].getTranslationVector();
        UIColor *mainColor = [UIColor blueColor];
        int tagLineWidth = 10;

        // tag Id from message: "36h11 id: 1" -> 1
        NSString *message = [NSString stringWithCString:detector.getMessage(i).c_str() encoding:[NSString defaultCStringEncoding]];
        NSArray *phases = [message componentsSeparatedByString:@" "];
        int detectedTagId = [phases[2] intValue];

        // draw tag id
        NSString *tagIdStr = [NSString stringWithFormat:@"%d", detectedTagId];
        
        // Save the context before rotating
        CGContextSaveGState(context);
        
        // Draw the tag ID
        CGContextTranslateCTM(context, polygon[0].get_u(), polygon[0].get_v() - 50);
        CGContextRotateCTM(context, -M_PI_2); // Rotate -90 degrees (adjust if necessary)
        [ImageDisplay displayText:tagIdStr :0 :0 :600 :100 :mainColor :[UIColor clearColor]];
        
        // Restore the context to previous state
        CGContextRestoreGState(context);

        // draw tag frame
        [ImageDisplay displayLineWithContext:context :polygon :mainColor :tagLineWidth];

        // draw xyz coordinate.
        [ImageDisplay displayFrameWithContext:context :cMo_vec[i] :cam :tagSize :6];

        // draw distance from camera.
        NSString *meter = [NSString stringWithFormat:@"(%.2f,%.2f,%.2f)", trans[0], trans[1], trans[2]];
        CGContextSaveGState(context);
        CGContextTranslateCTM(context, cog.get_u(), cog.get_v() + 50);
        CGContextRotateCTM(context, -M_PI_2); // Rotate -90 degrees (adjust if necessary)
        [ImageDisplay displayText:meter :0 :0 :600 :100 :[UIColor whiteColor] :[UIColor blueColor]];
        CGContextRestoreGState(context);
    }

    UIImage *overlayImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return overlayImage;
}

@end
