//
//  DelegateHandler.h
//  rsyncSwift
//
//  Created by Viktor Braun on 19/09/15.
//  Copyright (c) 2015 AW-SYSTEMS. All rights reserved.
//

#ifndef __rsyncSwift__DelegateHandler__
#define __rsyncSwift__DelegateHandler__

#include <stdio.h>
#include <vector>
#include <set>

class DelegateHandler {
private:
    
public:
    
    void(*statusMessage)(const char* msg, void *context);
    
    void(*statusFile)(const char * path, bool isDir, int64_t size, int64_t time,
         const char * symlink, void *context);
    
    void *context;
    
    DelegateHandler();
    ~DelegateHandler();
    
    void in1(const char*) const;
    void in5(const char * /*path*/, bool /*isDir*/, int64_t /*size*/, int64_t /*time*/,
                           const char * /*symlink*/) const;
    
};

#endif /* defined(__rsyncSwift__DelegateHandler__) */
