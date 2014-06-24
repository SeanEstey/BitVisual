//  BVMenu.h
//  BitVisual
//
//  Created by Sean Estey on 2/8/2014.
//  Copyright (c) 2014 Sean Estey. All rights reserved.
//

#import <UIKit/UIKit.h>

@class BVMenu;

@protocol BVMenuDelegate
- (void) niDropDownDelegateMethod: (BVMenu*) sender path:(NSIndexPath *)indexPath;
@end

@interface BVMenu : UIView <UITableViewDelegate, UITableViewDataSource>
{
    NSString *animationDirection;
    UIImageView *imgView;
    bool edits_sender_title_on_select;
    float width;
    float height;
}

@property (strong, nonatomic) IBOutlet UILabel* menuCaption;
@property (nonatomic, retain) id <BVMenuDelegate> delegate;
@property (nonatomic, retain) NSString *animationDirection;

-(void)hideDropDown:(UIButton *)button;
-(id)showDropDown:(UIButton*)button hasWidth:(float)w hasHeight:(float)h hasItems:(NSArray*)items direction:(NSString*)dir editsSenderOnSelect:(bool)val caption:(NSString*)c;

@end