//
//  ViewController.swift
//  CallerInfo
//
//  Created by seemelk on 2017/4/12.
//  Copyright © 2017年 罕见. All rights reserved.
//

import UIKit
import FMDB
import CallKit

class ViewController: UIViewController {

    @IBOutlet weak var updateButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillEnterForeground), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
        
        
        let path = Bundle.main.path(forResource: "caller_210", ofType: "db")
        var containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupKey)
        containerURL?.appendPathComponent("caller_210.db")
        let s = (containerURL?.relativeString)!.replacingOccurrences(of: "file://", with: "")
        let exists = FileManager.default.fileExists(atPath: s)
        if !exists {
            do {
                try FileManager.default.copyItem(at: URL.init(fileURLWithPath: path!), to: containerURL!)
            } catch {
                print(error)
            }
        }

        
        
    }
    

    @objc private func applicationWillEnterForeground(){
        CXCallDirectoryManager.sharedInstance.getEnabledStatusForExtension(withIdentifier: callExtensionIndentifier) { [weak self] (enabledStatus, error) in
            DispatchQueue.main.async {
                switch enabledStatus {
                case .unknown:
                    self?.updateButton.isEnabled = false
                    self?.updateButton.setTitle("获取号码识别打开状态失败", for: .normal)
                    break
                case .enabled:
                    self?.updateButton.isEnabled = true
                    self?.updateButton.setTitle("更新号码", for: .normal)
                    break
                case .disabled:
                    self?.updateButton.isEnabled = false
                    self?.updateButton.setTitle("未打开号码识别！", for: .normal)
                    break
                    
                }
            }
        }
    }
    
    
    @IBAction func updatePhoneNumbers(_ sender: UIButton) {
        
        sender.isEnabled = false
        sender.setTitle("正在更新中...", for: .normal)
        
        CXCallDirectoryManager.sharedInstance.getEnabledStatusForExtension(withIdentifier: callExtensionIndentifier) { [weak self] (enabledStatus, error) in
            DispatchQueue.main.async {
                switch enabledStatus {
                case .unknown:
                    self?.updateButton.setTitle("获取号码识别打开状态失败", for: .normal)
                    break
                case .enabled:
//                    self?.fecthPhones()
                    self?.reloadPhones()
                    break
                case .disabled:
                    self?.updateButton.setTitle("未打开号码识别！", for: .normal)
                    break
                    
                }
            }
        }

    }

    
    private func fecthPhones() {
        let defaults = UserDefaults(suiteName: appGroupKey)
//        if ((defaults?.object(forKey: namePhoneDictKey)) != nil) {
//            return
//        }
        
        let path = Bundle.main.path(forResource: "caller_210", ofType: "db")
        guard let database = FMDatabase(path: path) else {
            print("unable to create database")
            return
        }
        guard database.open() else {
            print("Unable to open database")
            return
        }
        
        var phoneNameDict = [String:String]()
        do {
            let rs = try database.executeQuery("select * from caller", values: nil)
            
            var count = 0
            while rs.next() {
                count += 1

                
                if let name = rs.string(forColumn: "name") {
                    var phone = rs.string(forColumn: "number")
                    if phone == nil {
                        continue
                    }
                    
                    phone = phone?.replacingOccurrences(of: "+0086", with: "")
                    phone = phone?.replacingOccurrences(of: "+", with: "")
                    phone = "86" + phone!
                    let length = phone!.characters.count
                    if length > 4 && length < 14 {
                        if count > 9000 && count <= 18000{
                            phoneNameDict[phone!] = name
                        }
                    }
                    

                }
            }
        } catch {
            print("failed: \(error.localizedDescription)")
        }
        
        database.close()
        defaults?.set(phoneNameDict, forKey: namePhoneDictKey)
        defaults?.synchronize()
    }
    
    private func reloadPhones() {
        CXCallDirectoryManager.sharedInstance.reloadExtension(withIdentifier: callExtensionIndentifier) { [weak self] (error: Error?) in
            DispatchQueue.main.async {
                if (error == nil) {
                    self?.updateButton.setTitle("更新成功", for: .normal)
                }else{
                    print(error!)
                    
                    self?.updateButton.isEnabled = true
                    self?.updateButton.setTitle("失败,点击重试", for: .normal)
                }
            }
        }
    }
}

