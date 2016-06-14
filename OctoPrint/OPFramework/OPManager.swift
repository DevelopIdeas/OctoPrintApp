//
//  OctoPrint.swift
//  OctoPrint
//
//  Created by Michael Teeuw on 22-07-15.
//  Copyright © 2015 Michael Teeuw. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

/*
 * Structs & enums
 */

struct OPToolTemperature {
    var actual:Float
    var target:Float
    var offset:Float
}

struct OPStateFlags {
    var operational:Bool
    var paused:Bool
    var printing:Bool
    var sdReady:Bool
    var error:Bool
    var ready:Bool
    var closedOrError:Bool
}

struct OPTemperaturePreset {
    let name:String
    let extruderTemperature:Int
    let bedTemperature:Int
}

enum OPToolType {
    case Bed
    case Tool
}

enum OPNotification:String {
    case DidUpdateVersion = "com.xonaymedia.OctoPrintApp.OctoPrintDidUpdateVersion"
    case DidUpdatePrinter = "com.xonaymedia.OctoPrintApp.OctoPrintDidUpdatePrinter"
    case DidUpdateJob = "com.xonaymedia.OctoPrintApp.OctoPrintDidUpdateJob"
    case DidUpdateComponent = "com.xonaymedia.OctoPrintApp.OctoPrintDidUpdateComponent"
    case DidUpdateSettings = "com.xonaymedia.OctoPrintApp.OctoPrintDidUpdateSettings"
    
    case DidSetPrinterTool = "com.xonaymedia.OctoPrintApp.OctoPrintDidDidSetPrinterTool"
    case DidSetPrinterBed = "com.xonaymedia.OctoPrintApp.OctoPrintDidDidSetPrinterBed"
}

class OPManager {
    static let sharedInstance = OPManager()
    static let notificationCenter = NSNotificationCenter.defaultCenter()
    
    // update info
    var updateTimeStamp:NSDate?
  
    // version
    var apiVersion:String = "Unknown"
    var serverVersion:String = "Unknown"
    
    // printer
    var printerStateText:String = "Unknown"
    var printerStateFlags:OPStateFlags = OPStateFlags(operational: false, paused: false, printing: false, sdReady: false, error: false, ready: false, closedOrError: false)

    let printHead = OPPrintHead(identifier: "PrintHead")
    let bed:OPBed = OPBed(identifier: "bed")
    let tools = OPToolArray()

    // job
    var filename = ""
    var estimatedPrintTime: String = "" // seconds
    var completed: String = "" // percentage
    var printTimeLeft: String = "" // seconds
    var printTimeElapsed: String = "" // seconds
    var averagePrintTime: String = "" // seconds
    var printLength: String = "" // mm
    var printPosition: String = "" // mm

    // settings
    var temperaturePresets:[OPTemperaturePreset] = []
    var webcamStreamURL: NSURL?
    
    private enum tasks {
        static var updateVersion = OPAPITask(endPoint: "version")
        static var updatePrinter = OPAPITask(endPoint: "printer")
        static var updateJob = OPAPITask(endPoint: "job")
        static var updateSettings = OPAPITask(endPoint: "settings")
    }
    
    func updateVersion(autoUpdate interval: NSTimeInterval? = nil) {
        tasks.updateVersion.onSuccess({ (json)->() in
            if let json = json {
                self.updateTimeStamp = tasks.updateVersion.lastSuccessfulRun
                if let version = json["api"].string {
                    self.apiVersion = version
                }
                
                if let version = json["server"].string {
                    self.serverVersion = version
                }

                OPManager.notificationCenter.postNotificationKey(.DidUpdateVersion, object: self)
                
            }
        }).autoRepeat(interval).fire()
    }
    
    func updatePrinter(autoUpdate interval: NSTimeInterval? = nil) {
        tasks.updatePrinter.onSuccess({ (json)->() in
            
            if let json = json {
                self.updateTimeStamp = tasks.updatePrinter.lastSuccessfulRun
                
                self.printerStateText = json["state"]["text"].string ?? "Unknown"
                
                self.printerStateFlags = OPStateFlags(
                    operational: json["state"]["flags"]["operational"].bool ?? false,
                    paused: json["state"]["flags"]["paused"].bool ?? false,
                    printing: json["state"]["flags"]["printing"].bool ?? false,
                    sdReady: json["state"]["flags"]["sdReady"].bool ?? false,
                    error: json["state"]["flags"]["error"].bool ?? false,
                    ready: json["state"]["flags"]["ready"].bool ?? false,
                    closedOrError: json["state"]["flags"]["closedOrError"].bool ?? false)

                for (key, subJson) in json["temperature"] {
                    
                    let heatedComponent:OPHeatedComponent
                    
                    if key == "bed" {
                        heatedComponent = self.bed
                    } else {
                        heatedComponent = self.tools[key]
                    }
                    
                    heatedComponent.actualTemperature = subJson["actual"].float ?? 0
                    heatedComponent.targetTemperature = subJson["target"].float ?? 0
                    heatedComponent.temperatureOffset = subJson["offset"].float ?? 0
                    
                }
                
                OPManager.notificationCenter.postNotificationKey(.DidUpdatePrinter, object: self)
                
            }
            
        }).autoRepeat(interval).fire()
    }
    
    func updateJob(autoUpdate interval: NSTimeInterval? = nil) {
        tasks.updateJob.onSuccess({ (json)->() in
            if let json = json {
                //print(json)
                self.filename = json["job"]["file"]["name"].stringValue
                self.estimatedPrintTime = self.secondsToHoursMinutesSeconds(json["job"]["estimatedPrintTime"].intValue)
                self.completed = String(format: "%.1f%%", json["progress"]["completion"].floatValue)
                self.printTimeElapsed = self.secondsToHoursMinutesSeconds(json["progress"]["printTime"].intValue)
                self.printTimeLeft = self.secondsToHoursMinutesSeconds(json["progress"]["printTimeLeft"].intValue)
                self.averagePrintTime = self.secondsToHoursMinutesSeconds(json["job"]["averagePrintTime"].intValue)
                /*if (json["job"]["filament"]["tool0"]["length"].floatValue > 0) {
                    self.printLength = String(format: "%.2fmb", json["job"]["filament"]["tool0"]["length"].floatValue/1024.0/1024.0)
                    print(self.printLength)
                } else {
                    self.printLength = "0.00mb"
                }
                if (json["progress"]["filepos"].floatValue > 0) {
                    self.printPosition = String(format: "%.2fmb", json["progress"]["filepos"].floatValue/1024.0/1024.0)
                    print(self.printPosition)
                } else {
                    self.printPosition = "0.00mb"
                }*/
                
                /*{
                    "job" : {
                        "lastPrintTime" : null,
                        "filament" : {
                            "tool0" : {
                                "volume" : 0,
                                "length" : 14942.71760000009
                            }
                        },
                        "averagePrintTime" : null,
                        "estimatedPrintTime" : 14180.56084478403,
                        "file" : {
                            "size" : 11136634,
                            "name" : "iPhone_6_Desk_Stand_low.gcode",
                            "origin" : "local",
                            "date" : 1465846288
                        }
                    },
                    "progress" : {
                        "filepos" : 3413520,
                        "printTimeLeft" : 8114,
                        "completion" : 30.65127218870621,
                        "printTime" : 6302
                    },
                    "state" : "Printing"
                }*/

                OPManager.notificationCenter.postNotificationKey(.DidUpdateJob, object: self)
                
            }
        }).autoRepeat(interval).fire()
    }
    
    func updateSettings(autoUpdate interval: NSTimeInterval? = nil) {
        tasks.updateSettings.onSuccess({ (json)->() in
            
            if let json = json {
                self.updateTimeStamp = tasks.updatePrinter.lastSuccessfulRun
                
                self.temperaturePresets = []
                
                for (_, preset) in json["temperature"]["profiles"] {
                    
                    let preset = OPTemperaturePreset(name: preset["name"].stringValue, extruderTemperature: preset["extruder"].intValue, bedTemperature: preset["bed"].intValue)
                    self.temperaturePresets.append(preset)
                    
                    OPManager.notificationCenter.postNotificationKey(OPNotification.DidUpdateSettings, object: self)
                }
                
                let host = NSUserDefaults.standardUserDefaults().stringForKey("OctoPrintHost")!
                let streamPath = json["webcam"]["streamUrl"].stringValue
                self.webcamStreamURL = NSURL(string: "http://\(host)\(streamPath)") 
            }
            
        }).autoRepeat(interval).fire()
    }

    func secondsToHoursMinutesSeconds (seconds : Int) -> String {
        //return (seconds / 3600, (seconds % 3600) / 60, (seconds % 3600) % 60)
        return String(format: "%02dh %02dm", seconds / 3600, (seconds % 3600) / 60)
    }

}




/*
 * Extensions
 */


// Alamofire.Manager extension to create managers with default headers.

extension Alamofire.Manager {
    convenience init(withHeaders headers: [String:String]) {
        var defaultHeaders = Alamofire.Manager.sharedInstance.session.configuration.HTTPAdditionalHeaders ?? [:]
        
        for (key, value) in headers {
            defaultHeaders[key] = value
        }
        
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        configuration.HTTPAdditionalHeaders = defaultHeaders
        
        self.init(configuration: configuration)
    }
}


//  NSNotificationCenter extension to handle OctoPrintNotifications.

extension NSNotificationCenter {
    
    func addObserver(observer: AnyObject, selector aSelector: Selector, key aKey: OPNotification) {
        self.addObserver(observer, selector: aSelector, name: aKey.rawValue, object: nil)
    }
    
    func addObserver(observer: AnyObject, selector aSelector: Selector, key aKey: OPNotification, object anObject: AnyObject?) {
        self.addObserver(observer, selector: aSelector, name: aKey.rawValue, object: anObject)
    }
    
    func removeObserver(observer: AnyObject, key aKey: OPNotification, object anObject: AnyObject?) {
        self.removeObserver(observer, name: aKey.rawValue, object: anObject)
    }
    
    func postNotificationKey(key: OPNotification, object anObject: AnyObject?) {
        self.postNotificationName(key.rawValue, object: anObject)
    }
    
    func postNotificationKey(key: OPNotification, object anObject: AnyObject?, userInfo aUserInfo: [NSObject : AnyObject]?) {
        self.postNotificationName(key.rawValue, object: anObject, userInfo: aUserInfo)
    }
    
    func addObserverForKey(key: OPNotification, object obj: AnyObject?, queue: NSOperationQueue?, usingBlock block: (NSNotification!) -> Void) -> NSObjectProtocol {
        return self.addObserverForName(key.rawValue, object: obj, queue: queue, usingBlock: block)
    }
    
}

