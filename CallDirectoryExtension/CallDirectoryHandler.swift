//
//  CallDirectoryHandler.swift
//  CallDirectoryExtension
//
//  Created by seemelk on 2017/4/12.
//  Copyright © 2017年 罕见. All rights reserved.
//

import Foundation
import CallKit

class CallDirectoryHandler: CXCallDirectoryProvider {

    let phoneNumberDict: [NSNumber:String]? = {
        let defaults = UserDefaults(suiteName: appGroupKey)
        return defaults?.object(forKey: namePhoneDictKey) as? [NSNumber:String]
    }()
    
    
    override func beginRequest(with context: CXCallDirectoryExtensionContext) {
        context.delegate = self

//        do {
//            try addBlockingPhoneNumbers(to: context)
//        } catch {
//            NSLog("Unable to add blocking phone numbers")
//            let error = NSError(domain: "CallDirectoryHandler", code: 1, userInfo: nil)
//            context.cancelRequest(withError: error)
//            return
//        }

        do {
            try addIdentificationPhoneNumbers(to: context)
        } catch {
            NSLog("Unable to add identification phone numbers")
            let error = NSError(domain: "CallDirectoryHandler", code: 2, userInfo: nil)
            context.cancelRequest(withError: error)
            return
        }

        context.completeRequest()
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
//        let phoneNumbers: [CXCallDirectoryPhoneNumber] = [ 18775555555, 18885555555 ]
//        let labels = [ "Telemarketer", "Local business" ]
//
//        for (phoneNumber, label) in zip(phoneNumbers, labels) {
//            context.addIdentificationEntry(withNextSequentialPhoneNumber: phoneNumber, label: label)
//        }
        
        if let phoneNumberDict = phoneNumberDict {
            let keys = phoneNumberDict.keys
            let shortedKeys = keys.sorted(by: { (n1: NSNumber, n2: NSNumber) -> Bool in
                return n1.compare(n2) == ComparisonResult.orderedAscending
            })
            for phone in shortedKeys {
                context.addIdentificationEntry(withNextSequentialPhoneNumber: CXCallDirectoryPhoneNumber(phone), label: phoneNumberDict[phone]!)
            }
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
