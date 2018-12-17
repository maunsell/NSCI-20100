//
//  BaslerGUI.m
//  BaslerCamera
//
//  Created by John Maunsell on 2/4/18.
//  Copyright © 2018 John Maunsell. All rights reserved.
//

#import "BaslerGUI.h"

@interface BaslerGUI ()

@end

@implementation BaslerGUI

- (IBAction)grabImage:(id)sender
{
    NSLog(@"grabImage");
    [self.socket doCommand:@"grab"];
    [imageView setNeedsDisplay:YES];
}

- (void)windowDidLoad {
    [super windowDidLoad];
}

@end
