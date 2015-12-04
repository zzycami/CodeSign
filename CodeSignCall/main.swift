//
//  main.swift
//  CodeSignCall
//
//  Created by yrtd on 15/11/5.
//  Copyright © 2015年 kuaiyong. All rights reserved.
//

import Foundation

let SignAppend = "-signed.ipa"

func readCertificateFile(certificateFile:String)->String? {
    guard let certificateData = NSData(contentsOfFile: certificateFile) else {
        return nil
    }
    let options = NSMutableDictionary()
    options.setValue("", forKey: kSecImportExportPassphrase as String)
    var items:CFArray?
    let ret = SecPKCS12Import(certificateData, options, &items)
    print(ret)
    let first = CFArrayGetValueAtIndex(items!, 0)
    let content = unsafeBitCast(first, CFDictionaryRef.self)
    let labelRef = CFDictionaryGetCountOfKey(content, kSecImportItemLabel as String)
    let label = unsafeBitCast(labelRef, CFString.self)
    let chain = CFDictionaryGetCountOfKey(content, kSecImportItemCertChain as String)
    let identity = CFDictionaryGetCountOfKey(content, kSecImportItemIdentity as String)
    let keyid = CFDictionaryGetCountOfKey(content, kSecImportItemKeyID as String)
    let trust = CFDictionaryGetCountOfKey(content, kSecImportItemTrust as String)
    print(label)
    print(chain)
    print(identity)
    print(keyid)
    print(trust)
    return nil
}

//将C语言int型转换为Swift中的Int
let cout = Int(Process.argc)
if cout < 1 {
    exit(0)
}

print("Please install p12 file before start resigning the application!!")

var RootDirectory = String.fromCString(Process.unsafeArgv[0])!//"/Users/yrtd/Desktop/codesign/"
let fileManager = NSFileManager.defaultManager()
if !fileManager.isDirectoryItemAtPath(RootDirectory) {
    RootDirectory = RootDirectory.stringByDeletingLastPathComponent!
}


let directoryManager = DirectoryManager(pathOfFiles: RootDirectory)
//print("\(directoryManager)")

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
var packageName:String?
for name in directoryManager.packages {
    if !name.containsString(SignAppend) {
        packageName = name
        break
    }
}
guard let packageFile = packageName else {
    print("ipa file not exists!")
    exit(0)
}
SSZipArchive.unzipFileAtPath(packageFile, toDestination: directoryManager.destinationPath, overwrite: false, password: "", progressHandler: { (entry, zipInfo, entryNumber, total) -> Void in
    let percent = Float(entryNumber)/Float(total)
    print("unzip percent:\(percent)")
}) { (path, succeeded, error) -> Void in
    if error != nil {
        print(error.localizedDescription)
        exit(0)
    }
    print("unzip to \(path) finished")
}

// Rewrite the info.plist file
guard let updateBundleId = directoryManager.resignBundleId else {
    print("can't read the resign bundle id")
    exit(0)
}
print("start to resign the new bundle id:\(updateBundleId)")
if !directoryManager.replaceApplicationBundleId(updateBundleId) {
    print("resign the new bundle id failed")
    exit(0)
}
print("resign the new bundle id success")


//Copy mobileprovision & plist file
print("start to copy plist files and mobileprovision file")
if let destinationPackagePath = directoryManager.destinationPackagePath {
    let fileManager = NSFileManager.defaultManager()
    for plistFile in directoryManager.configPlists {
        if let file = plistFile.lastPathComponent() {
            let toPath = destinationPackagePath.stringByAppendingPathComponent(file)
            do {
                try fileManager.removeItemAtPath(toPath)
            }catch {
            }
            do {
                try fileManager.copyItemAtPath(plistFile, toPath: toPath)
                print("copy plist file:\(plistFile) to \(toPath) success")
            }catch let error as NSError {
                print("copy plist file:\(plistFile) to \(toPath) failed, reason:\(error.localizedDescription)")
            }
        }
    }
    if let provisions = directoryManager.provisions {
        if let file = provisions.lastPathComponent() {
            let toPath = destinationPackagePath.stringByAppendingPathComponent(file)
            do {
                try fileManager.removeItemAtPath(toPath)
            }catch {
            }
            do {
                try fileManager.copyItemAtPath(provisions, toPath: toPath)
                print("copy mobileprovision file:\(provisions) to \(toPath) success")
            }catch let error as NSError {
                print("copy mobileprovision file:\(provisions) to \(toPath) failed, reason:\(error.localizedDescription)")
            }
        }
    }
}

// sign
print("start sign")
if let destinationPackagePath = directoryManager.destinationPackagePath, entitlementPath = directoryManager.entitlements.first {
    let signString = "codesign -f -s '\(organizationName)' --entitlements \(entitlementPath) \(destinationPackagePath)"
    print(signString)
    system(signString)
}

// zip the ipa package
print("start zip the ipa package")
let parentPath = packageFile.stringByDeletingLastPathComponent!
let filename = packageFile.lastPathComponent()!.stringByDeletingPathExtension()
let resignPackageFile = filename! + SignAppend//parentPath.stringByAppendingPathComponent(filename! + SignAppend)
system("pwd")

system("mv \(parentPath)/Payload  ./Payload")
system("rm -rf \(parentPath)/iTunesArtwork")
system("rm -rf \(parentPath)/META-INF")
system("rm -rf \(parentPath)/iTunesMetadata.plist")
let zipString = "zip -r \(resignPackageFile) ./Payload"
print(zipString)
system(zipString)

// clear the temp file
print("start to clear temp files")
system("rm -rf ./Payload")

system("open .")
