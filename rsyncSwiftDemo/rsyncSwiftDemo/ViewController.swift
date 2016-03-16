//
//  ViewController.swift
//  rsyncSwiftDemo
//
//  Created by Viktor Braun on 21/09/15.
//  Copyright (c) 2015 Viktor Braun - dev-things.net. All rights reserved.
//

import UIKit
import rsyncSwift

class ViewController: UIViewController, RsyncClientDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        
        let rsync = RsyncClient()

        rsync.port = 873 // rsync port
        rsync.server = "192.168.0.102" // ip / name of the server
        rsync.module = "NetBackup" // name of the share
        
        rsync.debug = false //acrosync debug mode
        
        rsync.user = "admin" // user name
        rsync.pass = "secrete" // password
        
        let remote = "/car_video_captures/dira" // remote directory
        let local = "books/dira" // local directory
        
        rsync.delegate = self
        //rsync.download(local, remoteDir: remote)
        rsync.upload(local, remoteDir: remote)
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func syncCompleted(result: RsyncResult) {
        print("deleted: \(result.deleted)");
        print("updated: \(result.updated)");
        print("statistics: total: \(result.total) | physical: \(result.physical) | logical: \(result.logical) | skipped: \(result.skipped) | ")
    }
    
    func statistics(total: Int64, physical: Int64, logical: Int64, skipped: Int64) {
        print("")
        print("statistics: total: \(total) | physical: \(physical) | logical: \(logical) | skipped: \(skipped) | ")
    }
    
    func statusMessage(msg: String){
        print("\nstatusMessage -- msg: \(msg) \n")
    }
    func statusFile(filePath: String!, isDir: Bool, size: Int64, time: Int64, symLink: String!){
        print("\nstatusFile -- filePath: \(filePath) | isDir: \(isDir) | size: \(size) | time: \(time) | symLink: \(symLink)")
    }


}

