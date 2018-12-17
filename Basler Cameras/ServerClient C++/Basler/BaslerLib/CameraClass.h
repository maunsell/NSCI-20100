//
//  CameraClass.h
//  Basler
//
//  Created by John Maunsell on 1/27/18.
//  Copyright © 2018 John Maunsell. All rights reserved.
//

#ifndef CameraClass_h
#define CameraClass_h

 class CameraClass {
 private:
 public:
    CameraClass(void) noexcept;
    ~CameraClass(void) noexcept;
    long grabFrame(void);
 };
#endif /* CameraClass_h */
