//
//  Extensions.swift
//  lab
//
//  Created by 周泽勇 on 15/7/4.
//  Copyright (c) 2015年 studyinhand. All rights reserved.
//


import Foundation


public extension CGRect {
    var x:CGFloat {
        get {
            return origin.x;
        }
        set {
            origin.x = newValue;
        }
    }
    
    var y:CGFloat {
        get {
            return origin.y;
        }
        set {
            origin.y = newValue;
        }
    }
}


public extension NSString {
    class public func isEmpty(string: NSString?)->Bool {
        if string == nil {
            return true;
        }
        
        if !string!.isKindOfClass(NSString.classForCoder()) {
            if string!.isKindOfClass(NSNull.classForCoder()) {
                return true;
            }else {
                return false;
            }
        }
        
        if string!.trim().length == 0 {
            return true;
        }
        return false;
    }
    
    public func trim()->NSString {
        return self.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
    }
    
}

let PathSeparate = "/"
public extension String {
    subscript (r: Range<Int>) -> String {
        get {
            let subStart = self.startIndex.advancedBy(r.startIndex, limit: self.endIndex)
            let subEnd = subStart.advancedBy(r.endIndex - r.startIndex, limit: self.endIndex)
            return self.substringWithRange(Range(start: subStart, end: subEnd))
        }
    }
    
    subscript (index: Int) -> Character {
        get {
            let subIndex = self.startIndex.advancedBy(index, limit: self.endIndex)
            return self[subIndex];
        }
    }
    
    func substring(from: Int) -> String {
        let end = self.characters.count
        return self[from..<end]
    }
    
    func substring(from: Int, length: Int) -> String {
        let end = from + length
        return self[from..<end]
    }
    
    
    public var stringByDeletingLastPathComponent:String? {
        var pathComponents = self.componentsSeparatedByString(PathSeparate)
        if pathComponents.count <= 0 {
            return nil
        }
        pathComponents.removeLast()
        var resultString = pathComponents.first!
        var index = 0
        for component in pathComponents {
            if index == 0 {
                index++
                continue
            }
            if component == "" {
                continue
            }
            resultString = resultString.stringByAppendingPathComponent(component)
            index++
        }
        return resultString
    }
    
    public var pathExtension:String? {
        let segment = self.componentsSeparatedByString(".")
        return segment.last
    }
    
    public func stringByAppendingPathComponent(pathComponent:String)->String {
        return self + "/" + pathComponent
    }
    
    public func stringByAppendingPathExtension(ext:String)->String {
        return self + "." + ext
    }
    
    public func stringByDeletingPathExtension()->String? {
        let pathComponents = self.componentsSeparatedByString(".")
        if let ext = pathComponents.last {
            return self.stringByReplacingOccurrencesOfString("."+ext, withString: "")
        }
        return nil
    }
    
    public func lastPathComponent()->String? {
        let pathComponents = self.componentsSeparatedByString("/")
        return pathComponents.last
    }
    
    public func replaceUnicode()throws->String {
        let tempStr1 = self.stringByReplacingOccurrencesOfString("\\u", withString: "\\U")
        let tempStr2 = tempStr1.stringByReplacingOccurrencesOfString("\"", withString: "\\\"")
        let tempStr3 = "\"\(tempStr2)\""
        if let data = tempStr3.dataUsingEncoding(NSUTF8StringEncoding) {
            let result = try NSPropertyListSerialization.propertyListWithData(data, options: .Immutable, format: nil)
            return result.stringByReplacingOccurrencesOfString("\\r\\n", withString: "\n")
        }
        return self
    }
}

extension NSURL {
    public func parseQuery()->[String:String] {
        var queryDict = [String:String]()
        if let query = self.query {
            let keyValuePairs = query.componentsSeparatedByString("&")
            for keyValuePair in keyValuePairs {
                var element = keyValuePair.componentsSeparatedByString("=")
                if element.count != 2 {
                    continue
                }
                let key = element[0]
                let value = element[1]
                if key.isEmpty {
                    continue
                }
                queryDict[key] = value
            }
        }
        return queryDict
    }
}

extension NSFileManager {
    func attributeOfItemAtPath(path:String, key:String)->AnyObject? {
        do {
            let values = try self.attributesOfItemAtPath(path)
            if let value = values[key] {
                return value
            }
        }catch let error as NSError {
            print(error.localizedDescription)
        }
        return nil
    }
    
    func isDirectoryItemAtPath(path:String)->Bool {
        if let fileType =  attributeOfItemAtPath(path, key: NSFileType) as? String {
            if fileType == NSFileTypeDirectory {
                return true
            }
        }

        return false
    }
    
    func isFileItemAtPath(path:String)->Bool {
        if let fileType =  attributeOfItemAtPath(path, key: NSFileType) as? String {
            if fileType == NSFileTypeRegular {
                return true
            }
        }
        return false
    }
    
    func listItemsInDirectoryAtPath(path:String, deep:Bool, error:NSErrorPointer)->[String] {
        do {
            let subPaths = deep ? try self.subpathsOfDirectoryAtPath(path) : try self.contentsOfDirectoryAtPath(path)
            var absolutePaths:[String] = []
            let relativeSubPaths = subPaths
            for subPath in relativeSubPaths {
                let absolutePath = NSURL(string: path)!.URLByAppendingPathComponent(subPath).absoluteString
                absolutePaths.append(absolutePath)
            }
            return absolutePaths
        }catch let error as NSError {
            print(error.localizedDescription)
        }
        return []
    }
    
    func listItemsInDirectoryAtPath(path:String, deep:Bool)->[String]  {
        return listItemsInDirectoryAtPath(path, deep: deep, error: nil)
    }
}


public extension NSDictionary {
    public func jsonString()->String? {
        var err: NSError! = NSError(domain: "Migrator", code: 0, userInfo: nil)
        do {
            let jsonData = try NSJSONSerialization.dataWithJSONObject(self, options: NSJSONWritingOptions())
            let jsonStr = NSString(data: jsonData, encoding: NSUTF8StringEncoding) as? String
            if let value = jsonStr {
                return value
            }
            throw err
        } catch let error as NSError {
            err = error
            print(err.localizedDescription)
        }
        return nil
    }
}

public extension NSArray {
    public func jsonString()->String? {
        var err: NSError! = NSError(domain: "Migrator", code: 0, userInfo: nil)
        do {
            let jsonData = try NSJSONSerialization.dataWithJSONObject(self, options: NSJSONWritingOptions())
            let jsonStr = NSString(data: jsonData, encoding: NSUTF8StringEncoding) as? String
            if let value = jsonStr {
                return value
            }
        } catch let error as NSError {
            err = error
            print(err.localizedDescription)
        }
        return nil
    }
}

public extension String {
    public func jsonValue()->AnyObject? {
        if let jsonData = self.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false) {
            var jsonObject: AnyObject?
            do {
                jsonObject = try NSJSONSerialization.JSONObjectWithData(jsonData, options: NSJSONReadingOptions.AllowFragments)
            } catch let error as NSError {
                print(error.localizedDescription)
                jsonObject = nil
            }
            if let value = jsonObject {
                return value
            }
        }
        return nil
    }
}


