//
//  CameraOverlayView.h
//  ARIS
//
//  Created by Jacob Hanshaw on 3/28/13.
//
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

@interface CameraOverlayView : UIView {
    
    __weak IBOutlet UIButton *libraryButon;
}

@property (weak, nonatomic) IBOutlet UIButton *libraryButton;

@end
