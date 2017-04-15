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
    
    var database: FMDatabase? 
    var containerPath: String? {
        didSet{
            database = FMDatabase(path: containerPath)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillEnterForeground), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
        
        
        let path = Bundle.main.path(forResource: "caller_210", ofType: "db")
        var containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupKey)
        containerURL?.appendPathComponent("caller_210.db")
        containerPath = (containerURL?.relativeString)!.replacingOccurrences(of: "file://", with: "")
        let exists = FileManager.default.fileExists(atPath: containerPath!)
        if !exists {
            do {
                try FileManager.default.copyItem(at: URL.init(fileURLWithPath: path!), to: containerURL!)
            } catch {
                print(error)
            }
            creatTable()
        }
        
        applicationWillEnterForeground()
    }
    

    private func creatTable(){

        if database == nil {
            return;
        }
        guard database!.open() else {
            print("Unable to open database")
            return
        }
        do {
            try database!.executeUpdate("create table if not exists updateStatus(c int)", values: nil)
            try database!.executeUpdate("insert into updateStatus (c) values (?)", values: ["0"])
        } catch {
            print("failed: \(error.localizedDescription)")
        }
        database!.close()
    }
    
    private func resetUpdateStatus(){
        
        if database == nil {
            return;
        }
        guard database!.open() else {
            print("Unable to open database")
            return
        }
        do {
            try database!.executeUpdate("update updateStatus set c = 0", values: nil)
        } catch {
            print("failed: \(error.localizedDescription)")
        }
        database!.close()
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
        
        resetUpdateStatus()
        
        reloadExtension()
        


    }

    private func reloadExtension(){
        CXCallDirectoryManager.sharedInstance.reloadExtension(withIdentifier: callExtensionIndentifier) {  [weak self] (error) in
            DispatchQueue.main.async {
                if (error == nil) {
                    if let database = self?.database{
                        guard database.open() else {
                            return
                        }
                        var count: Int?
                        if let rs = try? database.executeQuery("select c from updateStatus", values: nil) {
                            if rs.next() {
                                count = Int(rs.longLongInt(forColumn: "c"))
                            }
                        }
                        if count != nil && count! < 140000 {
                            self?.updateButton.setTitle("目前：\(count!)", for: .normal)
                            self?.reloadExtension()
                        }else{
                            self?.updateButton.isEnabled = true
                            self?.updateButton.setTitle("成功", for: .normal)
                        }
                        
                        
                    }
                }else{
                    self?.updateButton.setTitle("失败", for: .normal)
                }
            }
        }
    }
}

