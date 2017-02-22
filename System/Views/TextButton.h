//
//  TextButton.h
//  GPK-Man
//
//  Created by Vladislav Skachkov on 13/08/16.
//  Copyright © 2016 Vladislav Skachkov. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface TextButton : NSButton
@end

IB_DESIGNABLE
@interface TextFieldWithGoButtonCell : NSTextFieldCell
@property (assign) IBInspectable CGFloat margin;
@end

@interface AlternatableTableCellView : NSTableCellView
@end

@interface CancelableTextField : NSTextField

@end

@interface TextFieldWithGoButton : NSTextField
@property (nonatomic, assign) SEL          goAction;
@property (nonatomic, assign) id           goTarget;
@end
