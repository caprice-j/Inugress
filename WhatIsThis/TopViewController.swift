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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        initializeColor()
        
        clearAllNSDefaultsData()


        let config = RLMRealmConfiguration.defaultConfiguration()
        
        config.schemaVersion = 6;
        
        let migrationBlock: RLMMigrationBlock = { migration, oldSchemaVersion in
            if oldSchemaVersion < 1 {
                migration.enumerateObjects(DogRecord.className(), block: {
//                    oldObject, newObject in newObject!["isDog"] = true
                    dummy in 1
                })
            }
        }
        
        RLMRealmConfiguration.setDefaultConfiguration(config)
        
        let realm = RLMRealm.defaultRealm()
        
        print( realm.path )
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
