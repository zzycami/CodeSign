//
//  ViewController.swift
//  CodeSign
//
//  Created by yrtd on 15/11/5.
//  Copyright © 2015年 kuaiyong. All rights reserved.
//

import Cocoa
import SSZipArchive

class ViewController: NSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let RootDirectory = "/Users/yrtd/Desktop/codesign/"
        let directoryManager = DirectoryManager(pathOfFiles: RootDirectory)
        print("\(directoryManager)")
        
        // Fetch the organization name
        guard let certificateFile = directoryManager.certificateFile else {
            print("certificate file not exist!")
            exit(0)
        }
        
        let certificate = Certificate(contentOfFile: certificateFile, password: "")
        let array = certificate.label.componentsSeparatedByString(":")
        if array.count != 2 {
            print("Fetch product name failed")
            exit(0)
        }
        
        let organizationName = array.last!.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        print("The organization name is:\(organizationName)")
        
        
        // unzip the ipa file
        guard let packageFile = directoryManager.packages.first else {
            print("ipa file not exists!")
            exit(0)
        }
        
        SSZipArchive.unzipFileAtPath(packageFile, toDestination: RootDirectory, overwrite: true, password: "", progressHandler: { (entry, zipInfo, entryNumber, total) -> Void in
            let percent = entryNumber/total
            print("unzip percent:\(percent)")
            }) { (path, succeeded, error) -> Void in
                if error != nil {
                    print(error.localizedDescription)
                    exit(0)
                }
                print("unzip \(packageFile) finished")
        }
    }

    override var representedObject: AnyObject? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}

