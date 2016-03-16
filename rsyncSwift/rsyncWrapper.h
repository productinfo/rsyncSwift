//
//  rsyncWrapper.h
//  rsyncSwift
//
//  Created by Viktor Braun on 16/09/15.
//  Copyright (c) 2015 dev-things.net. All rights reserved.
//

#import <Foundation/Foundation.h>



@protocol RsyncDelegateProtocol <NSObject>
@required

- (void)statusMessage: (NSString*) statusMessage;
- (void)statusFile: (NSString*) filePath withIsDir: (bool) isDir withSize: (int64_t) size withTime: (int64_t) time withSymLink: (NSString*) symLink;

@end


@interface rsyncWrapper : NSObject {

}

@property (copy) NSString *server;
@property NSUInteger port;
@property BOOL useSSH;

@property BOOL debugModeOn;

@property (copy) NSString *username;
@property (copy) NSString *password;
@property (copy) NSString *module;

@property (nonatomic, weak) id<RsyncDelegateProtocol> delegate;

@property NSMutableArray* updatedFiles;
@property NSMutableArray* deletedFiles;


- (id) init;


- (BOOL)downloadToLocalDir: (NSString *) localDir fromRemoteDir: (NSString *) remoteDir;

- (BOOL)uploadFromLocalDir: (NSString *) localDir toRemoteDir: (NSString *) remoteDir;

- (int64_t) getTotalBytes;
- (int64_t) getPhysicalBytes;
- (int64_t) getLogicalBytes;
- (int64_t) getSkippedBytes;

@end