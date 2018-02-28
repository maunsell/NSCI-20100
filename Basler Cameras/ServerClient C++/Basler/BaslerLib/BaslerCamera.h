//
//  BaslerCamera.h
//  Basler
//
//  Created by John Maunsell on 1/27/18.
//  Copyright © 2018 John Maunsell. All rights reserved.
//

#ifndef BaslerCamera_h
#define BaslerCamera_h

#ifdef __cplusplus
extern "C" {
#endif

void initialize(void);
long grabFrame(void);
void terminate(void);

#ifdef __cplusplus
}
#endif

// Classs BaslerCamera {
// private:
// public:
//    BaslerCamera(void) noexcept;
//    ~BaslerCamera(void) noexcept;


#endif /* BaslerCamera_h */
