//
//  Document.h
//  Basler
//
//  Created by John Maunsell on 1/27/18.
//  Copyright © 2018 John Maunsell. All rights reserved.
//

#import <Cocoa/Cocoa.h>
//#import "BaslerCamera.h"
#import "CameraClass.h"

@interface Document:NSDocument {

    CameraClass *camera;
//    BaslerCamera *camera;
}
@end

