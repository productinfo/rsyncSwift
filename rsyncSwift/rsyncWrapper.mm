//
//  rsyncWrapper.mm
//  rsyncSwift
//
//  Created by Viktor Braun on 16/09/15.
//  Copyright (c) 2015 dev-things.net. All rights reserved.
//

#import "rsyncWrapper.h"


#include "rsync_client.h"
#include "rsync_entry.h"
#include "rsync_file.h"
#include "rsync_log.h"
#include "rsync_pathutil.h"
#include "rsync_socketutil.h"
#include "rsync_sshio.h"
#include "rsync_socketio.h"

#include "DelegateHandler.h"

#include <libssh2.h>


@implementation rsyncWrapper {
    // Private instance variables

    
    int _cancelFlag;
    NSString* _cachesPath;
    
    int64_t _statTotalBytes;
    int64_t _statPhysicalBytes;
    int64_t _statLogicalBytes;
    int64_t _statSkippedBytes;

    
}


//@synthesize username = _username;

- (void) resetPointers {
    _cancelFlag = 0;
    _statLogicalBytes = 0;
    _statPhysicalBytes = 0;
    _statLogicalBytes = 0;
    _statSkippedBytes = 0;
    
    _updatedFiles = [[NSMutableArray alloc] init];
    _deletedFiles = [[NSMutableArray alloc] init];

}

- (rsync::IO*) createIO: (NSString*) module {
    if(_debugModeOn){
        rsync::Log::setLevel(rsync::Log::Debug);
    }
    else{
        rsync::Log::setLevel(rsync::Log::Fatal);
    }

    rsync::SocketUtil::startup();
    if(_useSSH){
        int ssh = libssh2_init(0);
        if(ssh != 0){
            NSLog(@"ERROR: failed to initialize libssh2");
            rsync::SocketUtil::cleanup();
            return NULL;
        }
        
        rsync::SSHIO *sshio = new rsync::SSHIO();
        sshio->connect(_server.UTF8String, (int) _port, _username.UTF8String, _password.UTF8String, 0, 0);
        

        return sshio;
    }
    else{
        rsync::SocketIO *io = new rsync::SocketIO();
        io->connect(_server.UTF8String, (int) _port, _username.UTF8String, _password.UTF8String, module.UTF8String);
        
        return io;
    }
}

- (id) init {
    self = [super init];
    if (self != nil) {
        _updatedFiles = nil;
        _deletedFiles = nil;
        _debugModeOn = false;
        _cachesPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    }
    return self;
}

- (std::string) getAbsolutePathFor: (NSString*) path{
    NSString *localPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    
    std::string localDir = rsync::PathUtil::join([localPath UTF8String], [path UTF8String]);
    
    return localDir;
}

- (void)disconnect: (rsync::IO*) withIO {
    if(_useSSH){
        libssh2_exit();
    }
    
    if(withIO != NULL){
        delete withIO;
    }
    
    rsync::SocketUtil::cleanup();
}



void statusMessageDelegate(const char* status, void *context){
    [((__bridge rsyncWrapper*)context) statusMessageUpdate: status];
}

void statusFileDelegate(const char * path, bool isDir, int64_t size, int64_t time,
                           const char * symlink, void *context){
    [((__bridge rsyncWrapper*)context) statusFileUpdate: path isDir:isDir withSize:size withTime:time withSymLink:symlink];
}

-(void) statusMessageUpdate: (const char *) status{
    NSString *msg = [NSString stringWithUTF8String:status];
    [_delegate statusMessage:msg];
}

-(void) statusFileUpdate: (const char *) path isDir: (bool) isDir withSize: (int64_t) size withTime: (int64_t) time withSymLink: (const char*) symlink {
    NSString *argPath = [NSString stringWithUTF8String:path];
    NSString *argSymLink = @"";
    if(symlink){
        argSymLink = [NSString stringWithUTF8String:symlink];
    }

    
    [_delegate statusFile:argPath withIsDir:isDir withSize:size withTime:time withSymLink:argSymLink];
}

- (void) collectFileInfos: (rsync::Client*) client{
    _updatedFiles = [[NSMutableArray alloc] init];
    _deletedFiles = [[NSMutableArray alloc] init];
    
    const std::vector<std::string> deleted = client->getDeletedFiles();
    const std::vector<std::string> updated = client->getUpdatedFiles();

    for(int i = 0; i < updated.size(); i++){
        std::string value = updated.at(i);
        NSString* st = [NSString stringWithUTF8String:value.c_str()];
        [_updatedFiles addObject:st];
    }
    
    for(int i = 0; i < deleted.size(); i++){
        std::string value = deleted.at(i);
        NSString* st = [NSString stringWithUTF8String:value.c_str()];
        [_deletedFiles addObject:st];
    }
}

- (int64_t) getTotalBytes{
    return _statTotalBytes;
}

- (int64_t) getPhysicalBytes{
    return _statPhysicalBytes;
}

- (int64_t) getLogicalBytes{
    return _statLogicalBytes;
}

- (int64_t) getSkippedBytes{
    return _statSkippedBytes;
}


- (BOOL)downloadToLocalDir: (NSString *) localDir fromRemoteDir: (NSString *) remoteDir{

    bool success = false;
    [self resetPointers];
    
    rsync::IO *io = NULL;
    try{
        io = [self createIO:_module];
        
        if(io != NULL){
            rsync::Client client(io, "rsync", 30, &_cancelFlag);
        
            client.setSpeedLimits(512, 512);
            client.setStatsAddresses(&_statTotalBytes, &_statPhysicalBytes, &_statLogicalBytes, &_statSkippedBytes);
        
            std::string tempFile = rsync::PathUtil::join([_cachesPath UTF8String], "acrosync.part");
            
            const std::string absolutePath = [self getAbsolutePathFor:localDir];
            
            
            DelegateHandler handler;
            handler.statusMessage = statusMessageDelegate;
            handler.statusFile = statusFileDelegate;
            handler.statusFile = statusFileDelegate;
            handler.context = (__bridge void*)self;
            client.statusOut.connect(&handler, &DelegateHandler::in1);
            client.entryOut.connect(&handler, &DelegateHandler::in5);

            
            client.download(absolutePath.c_str(), [remoteDir UTF8String], tempFile.c_str());

            [self collectFileInfos: &client];
            
            success = true;
        }
    }
    catch(rsync::Exception){
        NSLog(@"ERROR: there is a rsync error during the download");
    }
    
    [self disconnect:io];
    return success;
}

- (BOOL)uploadFromLocalDir: (NSString *) localDir toRemoteDir: (NSString *) remoteDir{
    
    bool success = false;
    [self resetPointers];
    
    rsync::IO *io = NULL;
    try{
        io = [self createIO:_module];

        if(io != NULL){
            
            rsync::Client client(io, "rsync", 30, &_cancelFlag);

            client.setSpeedLimits(512, 512);
            client.setStatsAddresses(&_statTotalBytes, &_statPhysicalBytes, &_statLogicalBytes, &_statSkippedBytes);

            DelegateHandler handler;
            handler.statusMessage = statusMessageDelegate;
            handler.statusFile = statusFileDelegate;
            handler.statusFile = statusFileDelegate;
            handler.context = (__bridge void*)self;
            client.statusOut.connect(&handler, &DelegateHandler::in1);
            client.entryOut.connect(&handler, &DelegateHandler::in5);

            std::string tempFile = rsync::PathUtil::join([_cachesPath UTF8String], "acrosync.part");
            
            const std::string absolutePath = [self getAbsolutePathFor:localDir];
            
            client.upload(absolutePath.c_str(), [remoteDir UTF8String]);
            
            [self collectFileInfos:&client];
            
            success = true;
        }
    }
    catch(rsync::Exception){
        NSLog(@"ERROR: there is a rsync error during the download");
    }
    
    [self disconnect:io];
    return success;
    
}



@end