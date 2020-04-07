//
//  UIExtensions.h
//  GPK-Man
//
//  Created by Vladislav Skachkov on 04/11/2016.
//  Copyright © 2016 Vladislav Skachkov. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AlphaColorWell : NSColorWell
@end

@interface LockedColorWell : NSColorWell
@end

// Used for modal sheets to handle ok/cancel;
@interface USWindow : NSWindow
@property (weak) NSWindow *hostWindow;
@end

// Used for modal sheets to handle ok/cancel;
@interface USPanel : NSPanel
@property (weak) NSWindow *hostWindow;
@end
