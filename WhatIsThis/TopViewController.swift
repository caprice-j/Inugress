//
//  TopViewController.swift
//  Inugress
//
//  Created by PCUser on 2/15/16.
//  Copyright © 2016 Haoxiang Li. All rights reserved.
//

import UIKit

class TopViewController: UIViewController {
    
    @IBOutlet var takePhotoButton: UIButton!
    @IBOutlet var showAlbumButton: UIButton!

    @IBOutlet var takePhotoIcon: UILabel!
    @IBOutlet var showAlbumIcon: UILabel!
    
    @IBOutlet var currentDogBreedNumberLabel: UILabel!

    @IBOutlet var dogBreedPrefixLabel: UILabel!
    @IBOutlet var dogBreedSlashLabel: UILabel!
    @IBOutlet var dogBreedMaximumLabel: UILabel!
    @IBOutlet var dogBreedSuffixLabel: UILabel!
    
    
    var dogObjects: RLMResults? = nil

    
    // NSDefaultsをすべて消したいとき
    func clearAllNSDefaultsData () {
        
        let appDomain = NSBundle.mainBundle().bundleIdentifier!
        NSUserDefaults.standardUserDefaults().removePersistentDomainForName(appDomain)
    }
    
    // viewDidLoad 内で呼ばれる
    func initializeColor() {
        
        self.view.backgroundColor = MyColor.backColor()
        takePhotoButton.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Normal)
        takePhotoButton.backgroundColor = MyColor.textColor()
        
        takePhotoIcon.textColor = UIColor.whiteColor()

        showAlbumButton.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Normal)
        showAlbumButton.backgroundColor = MyColor.textColor()
        
        showAlbumIcon.textColor = UIColor.whiteColor()
        

        
    }
    
    func migrateMyRealm() {
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        initializeColor()
        
        clearAllNSDefaultsData()

//        migrateMyRealm()
        let config = RLMRealmConfiguration.defaultConfiguration()
        
        // migration を行いたいときは、この schemaVersion を 既存の値よりも上げる必要がなぜかある
        config.schemaVersion = 9;
        
        let migrationBlock: RLMMigrationBlock = { migration, oldSchemaVersion in
            if oldSchemaVersion > 1 {
            
                var prvalue: Int = 120;
                
                // 処理を行いたいクラス名を渡すと、oldObject と newObject に値が入る
                migration.enumerateObjects(DogRecord.className(), block: { oldObject, newObject in
                    
                        // newObject!["createdAt"] = String( prvalue++ )
                        // prvalue = prvalue + 1
                    
                        // MAYBE-LATER: 表示されない ... ?
                        NSLog("\n** migration occurred ** \n");
                    
                        // NSLog(String(oldObject!["createdAt"]))
                    

                        // if( seen.containsObject(newObject!["createdAt"]!) ){
                        
//                            toDelete.addObject(newObject!)
                        //}
                        //seen.addObject(newObject!["createdAt"]!)


                    // dummy in 1
                })
  //              migration.delete(toDelete)
             }
        }
        
        
        RLMRealmConfiguration.setDefaultConfiguration(config)
        RLMRealm.migrateRealm(config)

        
        
        
        
        
        
        // Can only add, remove, or create objects in a Realm in a write transaction - call beginWriteTransaction on an RLMRealm instance first.'
        // を避けるために必要な beginWriteTransaction()
//        realm.beginWriteTransaction()
//        realm.deleteObjects(DogRecord.allObjects())

//        realm.deleteAllObjects()
   //      var error: NSError? = nil
    //    try realm.commitWriteTransaction()
//        if let path = realm.path as String? {
//            print(path)
//            try! NSFileManager().removeItemAtPath(path)
//        }
    }
    
    override func viewWillAppear(animated: Bool) {

        let realm = RLMRealm.defaultRealm()
        print( "realm path is : " + realm.path )
        
        // やりかた１
//        let result = DogRecord.objectsWhere("createdAt != 'invalidString' ")
//        currentDogBreedNumberLabel.text = String( result.count )
        
        // やりかた２
//        let schedules = DogRecord.allObjects()
//        var uniqueIDs = [String]()
//        var uniqueSchedules = [DogRecord]()
//        for schedule in schedules {
//            let schedule = schedule as! DogRecord
//            let scheduleID = String( schedule.inceptionIndex ) // stored as Int32
//            if !contains(uniqueIDs, scheduleID) {
//                uniqueSchedules.append(schedule)
//                uniqueIDs.append(scheduleID)
//            }
//        }
        
        // やりかた３
        // Query all users
        var dogIds : [Int32] = []
        for d in DogRecord.allObjects() {
            let idx = (d as! DogRecord).inceptionIndex
            if( idx != -1 ){
                if( dogIds.indexOf(idx) == nil ){
                    dogIds.append(idx)
                }
            }
        }
        
        // 0 種のときは情報が多すぎるので消す
        
        print("dogIds.count: " + String(dogIds.count))
        if( dogIds.count > 0 ){
            dogBreedPrefixLabel.text    = "現在"
            dogBreedSlashLabel.text     = "/"
            dogBreedMaximumLabel.text   = "118"
            dogBreedSuffixLabel.text    = "種"
        currentDogBreedNumberLabel.text = String( dogIds.count )
            
        }else{
              dogBreedPrefixLabel.text  = ""
              dogBreedSlashLabel.text   = ""
              dogBreedMaximumLabel.text = ""
              dogBreedSuffixLabel.text  = ""
        currentDogBreedNumberLabel.text = ""

        }
        
        
//        }else{
//            currentDogBreedNumberLabel.text = "0"
//        }

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
