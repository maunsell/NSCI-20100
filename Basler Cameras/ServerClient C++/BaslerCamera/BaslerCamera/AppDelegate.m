//
//  AppDelegate.m
//  BaslerCamera
//
//  Created by John Maunsell on 2/4/18.
//  Copyright © 2018 John Maunsell. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {

    socket = [[BaslerSocket alloc] init];
    if (![socket openSocket]) {
        NSLog(@"Failed to open socket");
        exit(0);
    }
    gui = [[BaslerGUI alloc] initWithWindowNibName:@"BaslerGUI"];
    gui.socket = socket;
    [gui window];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
        [socket doCommand:@"exit"];
}

@end
