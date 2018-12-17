//
//  BaslerSocket.h
//  BaslerCamera
//
//  Created by John Maunsell on 2/4/18.
//  Copyright © 2018 John Maunsell. All rights reserved.
//

#ifndef _BaslerSocket_h
#define _BaslerSocket_h


#import <Foundation/Foundation.h>

@interface BaslerSocket : NSObject {

    int theSocket;
}

- (void)doCommand:(NSString *)command;
- (BOOL)openSocket;


@end

#endif // _BaslerSocket_h
