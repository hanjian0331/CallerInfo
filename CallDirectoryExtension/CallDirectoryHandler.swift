//
//  CallDirectoryHandler.swift
//  CallDirectoryExtension
//
//  Created by seemelk on 2017/4/12.
//  Copyright © 2017年 罕见. All rights reserved.
//

import Foundation
import CallKit
import FMDB

class CallDirectoryHandler: CXCallDirectoryProvider {
    
    override func beginRequest(with context: CXCallDirectoryExtensionContext) {
        context.delegate = self

        var containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupKey)
        containerURL?.appendPathComponent("caller_210.db")
        let patch = (containerURL?.relativeString)!.replacingOccurrences(of: "file://", with: "")
        
        
        guard let database = FMDatabase(path: patch) else {
            print("unable to create database")
            context.completeRequest()
            return
        }
        guard database.open() else {
            print("Unable to open database")
            context.completeRequest()
            return
        }
        var count = 0
        do {
            let rs = try database.executeQuery("select c from updateStatus", values: nil)
            while rs.next() {
                count = Int(rs.longLongInt(forColumn: "c"))
                break;
            }
        } catch {
            print("failed: \(error.localizedDescription)")
        }
        
        var phoneNameDict = [CXCallDirectoryPhoneNumber:String]()
        let onceCount = 50000
        do {
            let excuteString: String
            if count + onceCount > 140000 {
                excuteString = "select number,name from caller limit \(count),-1"
            }else{
                excuteString = "select number,name from caller limit \(count),\(onceCount)"
            }
            
            let rs = try database.executeQuery(excuteString, values: nil)
            
            while rs.next() {
                if let name = rs.string(forColumn: "name") {
                    if var phone = rs.string(forColumn: "number") {
                        phone = phone.replacingOccurrences(of: "+0086", with: "")
                        phone = phone.replacingOccurrences(of: "+", with: "")
                        phone = "86" + phone
                        let length = phone.characters.count
                        if length > 5 && length < 14 {
                            phoneNameDict[CXCallDirectoryPhoneNumber(phone)!] = name
                        }
                    }
                }
            }
        } catch {
            print("failed: \(error.localizedDescription)")
        }
        database.close()
        
        let keys = phoneNameDict.keys.sorted()
   
        for phoneNumber in keys {
            context.addIdentificationEntry(withNextSequentialPhoneNumber: phoneNumber, label: phoneNameDict[phoneNumber]!)
        }

        context.completeRequest()
        
        guard database.open() else {
            print("Unable to open database")
            context.completeRequest()
            return
        }
        do {
            try database.executeUpdate("update updateStatus set c = ?", values: ["\(count+onceCount)"])
        } catch {
            print("failed: \(error.localizedDescription)")
        }
        database.close()

    }

    private func addBlockingPhoneNumbers(to context: CXCallDirectoryExtensionContext) throws {
        // Retrieve phone numbers to block from data store. For optimal performance and memory usage when there are many phone numbers,
        // consider only loading a subset of numbers at a given time and using autorelease pool(s) to release objects allocated during each batch of numbers which are loaded.
        //
        // Numbers must be provided in numerically ascending order.
        let phoneNumbers: [CXCallDirectoryPhoneNumber] = [ 14085555555, 18005555555 ]

        for phoneNumber in phoneNumbers {
            context.addBlockingEntry(withNextSequentialPhoneNumber: phoneNumber)
        }
    }

    private func addIdentificationPhoneNumbers(to context: CXCallDirectoryExtensionContext) throws {
        // Retrieve phone numbers to identify and their identification labels from data store. For optimal performance and memory usage when there are many phone numbers,
        // consider only loading a subset of numbers at a given time and using autorelease pool(s) to release objects allocated during each batch of numbers which are loaded.
        //
        // Numbers must be provided in numerically ascending order.
        let phoneNumbers: [CXCallDirectoryPhoneNumber] = [ 18775555555, 8618885555555 ]
        let labels = [ "Telemarketer", "Local business" ]

        for (phoneNumber, label) in zip(phoneNumbers, labels) {
            context.addIdentificationEntry(withNextSequentialPhoneNumber: phoneNumber, label: label)
        }

    }

}

extension CallDirectoryHandler: CXCallDirectoryExtensionContextDelegate {

    func requestFailed(for extensionContext: CXCallDirectoryExtensionContext, withError error: Error) {
        // An error occurred while adding blocking or identification entries, check the NSError for details.
        // For Call Directory error codes, see the CXErrorCodeCallDirectoryManagerError enum in <CallKit/CXError.h>.
        //
        // This may be used to store the error details in a location accessible by the extension's containing app, so that the
        // app may be notified about errors which occured while loading data even if the request to load data was initiated by
        // the user in Settings instead of via the app itself.
    }

}
