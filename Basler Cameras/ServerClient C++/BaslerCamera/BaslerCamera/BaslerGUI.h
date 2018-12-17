//
//  BaslerGUI.h
//  BaslerCamera
//
//  Created by John Maunsell on 2/4/18.
//  Copyright © 2018 John Maunsell. All rights reserved.
//

#ifndef _BaslerGUI_h
#define _BaslerGUI_h

#import <Cocoa/Cocoa.h>
#import "BaslerSocket.h"
#import "BaslerImageView.h"

@interface BaslerGUI : NSWindowController {

    IBOutlet BaslerImageView *imageView;
    IBOutlet NSButton *grabButton;
}

@property (NS_NONATOMIC_IOSONLY) BaslerSocket *socket;

- (IBAction)grabImage:(id)sender;

@end

#endif  // BaslerGUI_h
