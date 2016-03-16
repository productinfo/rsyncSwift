//
//  RsyncClient.swift
//  rsyncSwift
//
//  Created by Viktor Braun on 19/09/15.
//  Copyright (c) 2015 AW-SYSTEMS. All rights reserved.
//

import UIKit

public protocol RsyncClientDelegate {
     func statusMessage(msg: String)
     func statusFile(filePath: String!, isDir: Bool, size: Int64, time: Int64, symLink: String!)
     func statistics(total: Int64, physical: Int64, logical: Int64, skipped: Int64);
     func syncCompleted(result: RsyncResult)
}

public class RsyncResult: NSObject{
    public var updated : [String] = []
    public var deleted : [String] = []
    public var total : Int64? // total bytes to sync
    public var physical : Int64? // transfereed bytes
    public var logical : Int64? // synced bytes 
    public var skipped : Int64? // skipped bytes
    
}

public class RsyncClient: NSObject, RsyncDelegateProtocol {

    public var server : String?
    public var port : UInt?
    public var user : String?
    public var pass : String?
    public var module : String?
    public var debug : Bool?
    public var delegate: RsyncClientDelegate?
    
    private var _timer : NSTimer?;
    private var _rsync : rsyncWrapper?;
    
    func initSync(){
        if(_rsync != nil){
            NSException(name: "InvalidCall", reason: "sync is already running", userInfo: nil).raise();
        }
        if(server == nil){
            NSException(name: "ArgumentNotDefined", reason: "Argument server is not defined", userInfo: nil).raise();
        }
        if(port == nil){
            NSException(name: "ArgumentNotDefined", reason: "Argument port is not defined", userInfo: nil).raise();
        }
        if(user == nil){
            NSException(name: "ArgumentNotDefined", reason: "Argument user is not defined", userInfo: nil).raise();
        }
        if(pass == nil){
            NSException(name: "ArgumentNotDefined", reason: "Argument pass is not defined", userInfo: nil).raise();
        }
        if(module == nil){
            NSException(name: "ArgumentNotDefined", reason: "Argument module is not defined", userInfo: nil).raise();
        }
        
        _rsync = rsyncWrapper();
        
        _rsync!.server = server
        _rsync!.port = port!
        _rsync!.username = user
        _rsync!.password = pass
        _rsync!.module = module
        if(debug == nil || debug == false){
            _rsync!.debugModeOn = false
        }
        else{
            _rsync!.debugModeOn = true
        }

        _rsync!.delegate = self
        
        _timer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: "timerUpdate", userInfo: nil, repeats: true)
    }
    
    func createResult() -> RsyncResult{
        let result = RsyncResult();
        result.updated = self._rsync!.updatedFiles as AnyObject as! [String]
        result.deleted = self._rsync!.deletedFiles as AnyObject as! [String]
        result.total = self._rsync!.getTotalBytes()
        result.physical = self._rsync!.getPhysicalBytes()
        result.logical = self._rsync!.getLogicalBytes()
        result.skipped = self._rsync!.getSkippedBytes()
        
        return result
    }

    public func timerUpdate(){
        let total = _rsync?.getTotalBytes();
        let skipped = _rsync?.getSkippedBytes()
        let logical = _rsync?.getLogicalBytes()
        let physical = _rsync?.getPhysicalBytes()
        self.delegate?.statistics(total!, physical: physical!, logical: logical!, skipped: skipped!)
    }
    

    public func download(localDir: String, remoteDir: String){
        initSync()

        dispatch_async(dispatch_get_global_queue(Int(QOS_CLASS_USER_INITIATED.rawValue), 0)) {
            self._rsync!.downloadToLocalDir(localDir, fromRemoteDir: remoteDir)
            dispatch_async(dispatch_get_main_queue()) {
                let result = self.createResult()
                
                self._timer!.invalidate()
                self._rsync = nil;
                self.delegate?.syncCompleted(result)
                
            }
        }
    }
    
    public func upload(localDir: String, remoteDir: String){
        initSync()
        
        dispatch_async(dispatch_get_global_queue(Int(QOS_CLASS_USER_INITIATED.rawValue), 0)) {
            self._rsync!.uploadFromLocalDir(localDir, toRemoteDir: remoteDir)
            dispatch_async(dispatch_get_main_queue()) {
                let result = self.createResult()
                
                self._timer?.invalidate()
                self._rsync = nil;
                self.delegate?.syncCompleted(result)
            }
        }
    }
    
    public func statusMessage(msg: String){
        delegate?.statusMessage(msg)
    }

    
    public func statusFile(filePath: String!, withIsDir: Bool, withSize size: Int64, withTime time: Int64, withSymLink symLink: String!) {
        delegate?.statusFile(filePath, isDir: withIsDir, size: size, time: time, symLink: symLink)
    }
    
}

