//
//  UIDevice+ITTAdditions.h
//  iTotemFrame
//
//  Created by jack 廉洁 on 3/15/12.
//  Copyright (c) 2012 iTotemStudio. All rights reserved.
//

#import <UIKit/UIKit.h>

#define IS_IPAD_DEVICE ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
#define IS_IOS_7 ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0)

@interface UIDevice (ITTAdditions)

+ (UIInterfaceOrientation)currentOrientation;

- (BOOL)hasRetinaDisplay;
- (BOOL)is4InchScreen;

- (NSUInteger)totalMemory;
- (NSUInteger)userMemory;

- (NSString*)macAddress;
- (NSString*)platformString;
- (NSString*)deviceIdentifier;
- (NSString*)uuid;
- (NSString*)iPAddress;
@end
