//
//  DelegateHandler.cpp
//  rsyncSwift
//
//  Created by Viktor Braun on 19/09/15.
//  Copyright (c) 2015 AW-SYSTEMS. All rights reserved.
//

#include <stdio.h>
#include "DelegateHandler.h"


DelegateHandler::DelegateHandler(){
    statusMessage = NULL;
    statusFile = NULL;
}

DelegateHandler::~DelegateHandler(){
    statusMessage = NULL;
    statusFile = NULL;
}

void DelegateHandler::in5(const char * path, bool isDir, int64_t size, int64_t time,
                                        const char * symlink) const{
    statusFile(path, isDir, size, time, symlink, context);
}
void DelegateHandler::in1(const char* msg) const{
    statusMessage(msg, context);
}