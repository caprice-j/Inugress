//
//  DogTableViewController.swift
//  Inugress
//
//  Created by PCUser on 2/15/16.
//  Copyright © 2016 Haoxiang Li. All rights reserved.
//

import UIKit


// Execution Order
//1) 起動したとき
//
//起動時（ ViewController が表示される）は以下の順
//
// ViewController viewDidLoad
// ViewController viewWillAppear
// ViewController viewDidAppear

//2) Nextボタンをタップして遷移したとき
// ViewController から NextViewController に遷移したとき
//
// NextViewController viewDidLoad
// ViewController viewWillDisappear
// NextViewController viewWillAppear
// ViewController viewDidDisappear
// NextViewController viewDidAppear

//3) 戻ったとき
//
//　ナビゲーションバーの戻るで戻るとき。このときは ViewController のviewDidLoad はもうすでに呼ばれているため、呼ばれない
//
// NextViewController viewWillDisappear
// ViewController viewWillAppear
// NextViewController viewDidDisappear
// ViewController viewDidAppear

//class DogObject : RLMObject {
//    
//}

// ViewController.mm で保存した DogRecord 型に対応するものを作成
//class DogRecord : RLMObject {
//    dynamic var recognizedNameString = ""
//    dynamic var pictureNSData: NSData? = nil
//}



class DogTableViewController: UITableViewController {

    var wordArray: [AnyObject] = []
    let saveData = NSUserDefaults.standardUserDefaults()
    var dogObjects: RLMResults? = nil
    let savedKey: String = "KEY_S"
    
    
    func cropThumbnailImage(image :UIImage, w:Int, h:Int) ->UIImage
    {
        // リサイズする
        let origRef    = image.CGImage;
        let origWidth  = Int(CGImageGetWidth(origRef))
        let origHeight = Int(CGImageGetHeight(origRef))
        var resizeWidth:Int = 0, resizeHeight:Int = 0
        
        if (origWidth < origHeight) {
            resizeWidth = w
            resizeHeight = origHeight * resizeWidth / origWidth
        } else {
            resizeHeight = h
            resizeWidth = origWidth * resizeHeight / origHeight
        }
        
        let resizeSize = CGSizeMake(CGFloat(resizeWidth), CGFloat(resizeHeight))
        UIGraphicsBeginImageContext(resizeSize)
        
        image.drawInRect(CGRectMake(0, 0, CGFloat(resizeWidth), CGFloat(resizeHeight)))
        
        let resizeImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        // 切り抜き処理
        
        let cropRect  = CGRectMake(
            CGFloat((resizeWidth - w) / 2),
            CGFloat((resizeHeight - h) / 2),
            CGFloat(w), CGFloat(h))
        let cropRef   = CGImageCreateWithImageInRect(resizeImage.CGImage, cropRect)
        let cropImage = UIImage(CGImage: cropRef!)
        
        return cropImage
    }
    
    @IBOutlet var barBackButton : UIBarButtonItem!;
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 色を変える
        navigationController?.navigationBar.barTintColor = MyColor.backColor() // 上方、ナビ部分の背景色
        navigationController?.navigationBar.tintColor = MyColor.textColor()    // 上方、ナビ部分の文字色 ("Back to Title", "Edit")
        barBackButton.setTitleTextAttributes([ NSFontAttributeName: UIFont(name: "Helvetica-Bold", size: 13)!], forState: UIControlState.Normal)

        // 編集ボタンを左上に配置
        navigationItem.rightBarButtonItem = editButtonItem()
        navigationItem.rightBarButtonItem?.setTitleTextAttributes([ NSFontAttributeName: UIFont(name: "Helvetica-Bold", size: 13)!], forState: UIControlState.Normal)
        
        // 以下の一行はviewWillAppear() だとエラる おそらく tableView.registerNib() の前に呼ぶ必要がある
        dogObjects = DogRecord.allObjects()
        
        // self.view.frame.width
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        // dogCell is written in the dattribute inspector in DogTableViewCell.xlib
        tableView.registerNib( UINib(nibName: "DogTableViewCell", bundle:nil), forCellReuseIdentifier: "dogCell")
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if saveData.arrayForKey(savedKey) != nil {
            wordArray = saveData.arrayForKey(savedKey)!
            print("record exists")
        }else{
            print("no record")
        }
        tableView.reloadData()
        
//        let realm = try! Realm()
//        DogRecord.allObjects()
        let realm = RLMRealm.defaultRealm()
        
        if dogObjects!.count > 0 {
            
            // 以下の for 文を使うためには、 RLMSupport.swift を github からDLする必要があった
            // する前は 'RLMResults' does not have a member named 'Generator' 的なエラーが出ていた
            for dogObject in dogObjects! {
                print("user.name: \( (dogObject as! DogRecord).recognizedNameString)")
            }
        }
    }
    
    // Edit ボタンが押されたときに呼ばれる関数
    override func setEditing(editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        tableView.editing = editing
    }
    
    // 削除可能なセルの indexPath を指定する
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true // 全てのセルを削除可能にする
    }
    
    // 削除された時の処理
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        
        let nowIndexPathDictionary : (AnyObject) = dogObjects![ UInt( indexPath.row )]
        
        // Invalid update エラーを避けるため、先にデータを更新する
        try! RLMRealm.defaultRealm().transactionWithBlock({ () -> Void in
//            // 単一レコードの削除
//            let dogObj = dogObjects(  )
//            RLMRealm.defaultRealm().deleteObject(dogObj)
//            // 複数レコードの削除
            let result = dogObjects!.objectsWithPredicate(
                NSPredicate(format: "createdAt == '\(nowIndexPathDictionary.createdAt)' " ))
            RLMRealm.defaultRealm().deleteObjects(result)
        })
        
        // それからテーブルの更新
        tableView.deleteRowsAtIndexPaths([NSIndexPath(forRow: indexPath.row, inSection: 0)],
            withRowAnimation: UITableViewRowAnimation.Fade)
    }
    
    // specify the number of sections
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    // specify the number of cells
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // return wordArray.count
        return Int( dogObjects!.count )
    }
    
    // specify how to display cell contents
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("dogCell", forIndexPath: indexPath) as! DogTableViewCell
        
        // let nowIndexPathDictionary : (AnyObject) = wordArray[indexPath.row]
        let nowIndexPathDictionary : (AnyObject) = dogObjects![ UInt( indexPath.row )]
        
        // after using Inugress-Bridging-Header.h, I have to tell the compiler the type of nowIndexPathDictionary.
        // cell.labelA.text = (nowIndexPathDictionary as! NSDictionary)[ "objname" ] as? String
        cell.labelA.text = nowIndexPathDictionary.recognizedNameString
        cell.probLabel.text = nowIndexPathDictionary.percent
//        cell.labelA.text = "testtest"
        let image = UIImage( data: nowIndexPathDictionary.pictureNSData )
        cell.dogImageView.image = cropThumbnailImage(image!, w: 174, h: 220)

        // doesn(t work well...
//        if( nowIndexPathDictionary.isDog == false ){
//            cell.contentView.backgroundColor = MyColor.accentColor()
//        }else{
//            
//        }
        
        return cell
    }
    
//    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath)
//    {
//        let nowIndexPathDictionary : (AnyObject) = dogObjects![ UInt( indexPath.row )]
//print(nowIndexPathDictionary.isDog)
//    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func goBackToTop () {
        dismissViewControllerAnimated(true, completion: nil)
    }

    // MARK: - Table view data source

    /*
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("reuseIdentifier", forIndexPath: indexPath)

        // Configure the cell...

        return cell
    }
    */

    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
