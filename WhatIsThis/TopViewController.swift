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

        let realm = RLMRealm.defaultRealm()
        
         print( "realm path is : " + realm.path )
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
