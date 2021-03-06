//
//  MBHUDHelper.m
//  iplaza
//
//  Created by Rush.D.Xzj on 4/27/13.
//  Copyright (c) 2013 Wanda Inc. All rights reserved.
//

#import "MBHUDHelper.h"
#import "MBProgressHUD.h"

@implementation MBHUDHelper

+ (void)showWarningWithText:(NSString *)text
{
    [MBHUDHelper showWarningWithText:text delegate:nil];
}

+ (void)showWarningWithText:(NSString *)text delegate:(id<MBProgressHUDDelegate>)delegate
{
    [MBHUDHelper showWarningWithText:text animationType:MBProgressHUDAnimationZoom mode:MBProgressHUDModeText customView:nil delegate:nil];
}

+ (void)showWarningWithText:(NSString *)text animationType:(MBProgressHUDAnimation)animationType customView:(UIView*)customView
{
    [MBHUDHelper showWarningWithText:text animationType:animationType mode:MBProgressHUDModeCustomView customView:customView  delegate:nil];
}

+ (void)showWarningWithText:(NSString *)text animationType:(MBProgressHUDAnimation)animationType mode:(MBProgressHUDMode)model customView:(UIView*)customView delegate:(id<MBProgressHUDDelegate>)delegate
{
    UIWindow *window = [[UIApplication sharedApplication].windows objectAtIndex:0];
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:window animated:YES];
    hud.animationType = animationType;
    hud.delegate = delegate;
    hud.labelText = text;
    hud.customView = customView;
    hud.mode = model;
    hud.removeFromSuperViewOnHide = YES;
    hud.dimBackground = NO;
    [hud hide:YES afterDelay:1.0];
}

@end
