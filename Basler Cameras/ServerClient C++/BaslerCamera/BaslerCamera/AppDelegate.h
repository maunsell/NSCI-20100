//
//  AppDelegate.h
//  BaslerCamera
//
//  Created by John Maunsell on 2/4/18.
//  Copyright © 2018 John Maunsell. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "BaslerGUI.h"
#import "BaslerSocket.h"

@interface AppDelegate : NSObject <NSApplicationDelegate> {

    BaslerGUI *gui;
    BaslerSocket *socket;
}

@end

