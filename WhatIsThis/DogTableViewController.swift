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

class DogTableViewController: UITableViewController {

    var wordArray: [AnyObject] = []
    let saveData = NSUserDefaults.standardUserDefaults()
    
    let savedKey: String = "KEY_S"
    
    override func viewDidLoad() {
        super.viewDidLoad()

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
    }
    
    // specify the number of sections
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    // specify the number of cells
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return wordArray.count
    }
    
    // specify how to display cell contents
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("dogCell", forIndexPath: indexPath) as! DogTableViewCell
        
        let nowIndexPathDictionary : (AnyObject) = wordArray[indexPath.row]
        
        // after using Inugress-Bridging-Header.h, I have to tell the compiler the type of nowIndexPathDictionary.
        cell.labelA.text = (nowIndexPathDictionary as! NSDictionary)[ "objname" ] as? String
//        cell.labelA.text = "testtest"
        
        return cell
    }
    

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
