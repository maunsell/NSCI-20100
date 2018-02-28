//
//  BaslerImageView.m
//  BaslerCamera
//
//  Created by John Maunsell on 2/4/18.
//  Copyright © 2018 John Maunsell. All rights reserved.
//

#import "BaslerImageView.h"

@implementation BaslerImageView

- (void)awakeFromNib {
    [self removeConstraint:self.widthCon];
//    self.heightCon = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeHeight
//                    relatedBy:NSLayoutRelationEqual toItem:self.window
//                    attribute:NSLayoutAttributeHeight multiplier:1.0 constant:-25];
//    [self addConstraint:self.widthCon];
    self.widthCon = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeWidth
                    relatedBy:NSLayoutRelationEqual toItem:self
                    attribute:NSLayoutAttributeHeight multiplier:1.26562 constant:0];
    [self addConstraint:self.widthCon];
}

//(instancetype)constraintWithItem:(id)view1
//attribute:(NSLayoutAttribute)attr1
//relatedBy:(NSLayoutRelation)relation
//toItem:(id)view2
//attribute:(NSLayoutAttribute)attr2
//multiplier:(CGFloat)multiplier
//constant:(CGFloat)c;

- (void)drawRect:(NSRect)dirtyRect {
    
//    CGImageRef myImage;
//    CGDataProviderRef imageRef;
    NSImage *theImage;
//    NSError *error;
//    NSURL *homeDirURL, *theURL;
    NSURL *theURL;
//    NSFileManager *fm = [[NSFileManager alloc] init];
//    CGContextRef cgcontext = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];

    [super drawRect:dirtyRect];

//    NSArray *dirArray = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:@"/Users/maunsell/Desktop" error:&error];
    theURL = [NSURL fileURLWithPath:@"Desktop/GrabbedImage.png" relativeToURL:[[NSFileManager defaultManager] homeDirectoryForCurrentUser]];
//    homeDirURL = [[NSFileManager defaultManager] homeDirectoryForCurrentUser];
//    NSArray *dirArray = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:@"~/Desktop" error:&error];
//    NSLog(@"%@", dirArray);

    theImage = [[NSImage alloc] initWithContentsOfURL:theURL];
    [theImage drawInRect:dirtyRect];
//    imageRef = CGDataProviderCreateWithFilename("JHRM/Users/maunsell/Desktop/GrabbedImage.png");
//    if (imageRef == NULL) {
//        NSLog(@"Failed to create image data provider");
//        return;
//    }
//    myImage = CGImageCreateWithPNGDataProvider(imageRef, NULL, NO, kCGRenderingIntentDefault);

    //    myImage = CGImageCreate(size_t width, size_t height, size_t bitsPerComponent, size_t bitsPerPixel,
    //            size_t bytesPerRow, CGColorSpaceRef space, CGBitmapInfo bitmapInfo,
    //            CGDataProviderRef provider, NULL, NO, kCGRenderingIntentDefault);
    //    theImage = [[NSImage alloc] initByReferencingFile:@"/Users/maunsell/Desktop/GrabbedImage.png"];
//    if ([self lockFocusIfCanDraw]) {
//        printf("DrawIntoView lockFocusIfCanDraw returned True, gonna try draw At point. \n");
//        //        [theImage drawAtPoint:NSMakePoint(0, 0) fromRect:NSZeroRect operation:NSCompositingOperationSourceOver fraction:1];
//        CGContextDrawImage(cgcontext, [self bounds], myImage);
//        [[NSGraphicsContext currentContext] flushGraphics];
//        [self unlockFocus];
//    }
//    else {
//        printf("DrawIntoView lockFocusIfCanDraw returned FALSE!!!!!. \n");
//    }
//    CGDataProviderRelease(imageRef);
}

@end
