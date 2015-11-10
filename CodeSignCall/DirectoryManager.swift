//
//  DirectoryManager.swift
//  CodeSign
//
//  Created by yrtd on 15/11/9.
//  Copyright © 2015年 kuaiyong. All rights reserved.
//

import Cocoa

public enum Extensions:String {
    case Certificate = "p12"
    case Plist = "plist"
    case Provision = "mobileprovision"
    case Entitlements = "entitlements"
    case Cer = "cer"
    case Package = "ipa"
}

public class DirectoryManager: NSObject {
    public var certificateFile:String?
    public var configPlists:[String] = []
    public var cers:[String] = []
    public var packages:[String] = []
    public var entitlements:[String] = []
    public var provisions:String?
    
    public var resignBundleId:String? {
        if let entitlementPath = entitlements.first {
            if let content = NSDictionary(contentsOfFile: entitlementPath) {
                if let applicationIdentifier = content.objectForKey("application-identifier") as? String {
                    if let range = applicationIdentifier.rangeOfString(".") {
                        let identifier = applicationIdentifier.substringFromIndex(range.endIndex)
                        return identifier
                    }
                }
            }
        }
        return nil
    }
    
    public var destinationPath:String {
        return self.rootPath.stringByAppendingPathComponent("")
    }
    
    private var _destinationPackagePath:String?
    
    public var destinationPackagePath:String? {
        if _destinationPackagePath == nil {
            let fileManager = NSFileManager.defaultManager()
            let temp = self.destinationPath.stringByAppendingPathComponent("Payload")
            let fileArray = try! fileManager.contentsOfDirectoryAtPath(temp)
            var tempName:String?
            for name in fileArray {
                if name.containsString("app") {
                    tempName = name
                    break
                }
            }
            if let applicationName = tempName {
                _destinationPackagePath = temp.stringByAppendingPathComponent(applicationName)
            }
        }
        return _destinationPackagePath
    }
    
    public var applicationInfoPlist:String? {
        return self.destinationPackagePath?.stringByAppendingPathComponent("Info.plist")
    }
    
    private var rootPath:String
    
    public init(pathOfFiles:String) {
        rootPath = pathOfFiles
        super.init()
        loadFiles()
    }
    
    public func replaceApplicationBundleId(bundleId:String)->Bool {
        if let infoPlistPath = self.applicationInfoPlist {
            if let content = NSMutableDictionary(contentsOfFile: infoPlistPath) {
                content.setValue(bundleId, forKey: "CFBundleIdentifier")
            
                return content.writeToFile(infoPlistPath, atomically: false)
            }
        }
        return false
    }
    
    public func loadFiles() {
        let fileManager = NSFileManager.defaultManager()
        let fileArray = try! fileManager.contentsOfDirectoryAtPath(rootPath)
        for file in fileArray {
            if let ext = file.pathExtension {
                let absoluteFile = rootPath.stringByAppendingPathComponent(file)
                print(absoluteFile)
                if let fileType = Extensions(rawValue: ext) {
                    switch fileType {
                    case .Certificate:
                        certificateFile = absoluteFile
                        break
                    case .Cer:
                        cers.append(absoluteFile)
                        break
                    case .Entitlements:
                        entitlements.append(absoluteFile)
                        break
                    case .Package:
                        packages.append(absoluteFile)
                        break
                    case .Plist:
                        configPlists.append(absoluteFile)
                        break
                    case .Provision:
                        provisions = absoluteFile
                        break
                    }
                }
            }
        }
        
    }
    
    public override var description:String {
        return "DirectoryManager{certificateFile=\(certificateFile),\n configPlists=\(configPlists),\n cers=\(cers)\n, packages=\(packages)\n, entitlements=\(entitlements)\n, provisions=\(provisions)\n}"
    }
    
}
