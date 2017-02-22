//
//  TextureView.h
//  GPK-Man
//
//  Created by Vladislav Skachkov on 09/09/16.
//  Copyright © 2016 Vladislav Skachkov. All rights reserved.
//

#import <Quartz/Quartz.h>

@interface TextureView : NSView
@property (assign, nonatomic) CGImageRef image;
- (void)centerLayer;
@end

IB_DESIGNABLE
@interface CenteredClipView : NSClipView
@property IBInspectable BOOL centersDocumentView;
@end
