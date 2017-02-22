//
//  ImportWizard.m
//  GPK-Man
//
//  Created by Vladislav Skachkov on 29/12/2016.
//  Copyright © 2016 Vladislav Skachkov. All rights reserved.
//

#import "ImportWizard.h"
#import "UPackage.h"

@interface ImportWizard ()
@property (weak) UPackage                               *package;
@property (assign) BOOL                                 returnCode;

@property (weak) IBOutlet NSComboBox                    *importBox;
@end

@implementation ImportWizard

+ (instancetype)wizardForPackage:(UPackage *)package
{
  ImportWizard *wizard = [[ImportWizard alloc] initWithWindowNibName:@"NewImport"];
  wizard.package = package;
  return wizard;
}

- (BOOL)runForWindow:(NSWindow *)host
{
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
  [NSApp beginSheet:self.window modalForWindow:host modalDelegate:nil didEndSelector:nil contextInfo:nil];
  [NSApp runModalForWindow:self.window];
  [self.window close];
#pragma GCC diagnostic pop
  return self.returnCode;
}

- (void)awakeFromNib
{
  [self populateBox];
}

- (void)populateBox
{
  [self.importBox removeAllItems];
  [self.importBox addItemsWithObjectValues:self.package.allExports];
}

- (IBAction)cancel:(id)sender
{
  self.returnCode = NO;
  [NSApp endSheet:self.window];
  [NSApp stopModal];
}

- (IBAction)ok:(id)sender
{
  self.returnCode = YES;
  [NSApp endSheet:self.window];
  [NSApp stopModal];
}

- (NSArray *)resultObjects
{
  return nil;
}

@end
