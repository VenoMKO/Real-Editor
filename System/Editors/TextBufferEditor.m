//
//  TextBufferEditor.m
//  Real Editor
//
//  Created by Vladislav Skachkov on 20/01/2017.
//  Copyright © 2017 Vladislav Skachkov. All rights reserved.
//

#import "TextBufferEditor.h"

@interface TextBufferEditor ()
@property (weak) IBOutlet NSTextView *textView;
@end

@implementation TextBufferEditor
@dynamic object;

- (void)viewDidLoad
{
  [super viewDidLoad];
  [self.textView setString:self.object.text.string];
}

- (NSString *)exportExtension
{
  return @"txt";
}

@end
