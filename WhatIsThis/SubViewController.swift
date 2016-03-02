//
//  SubViewController.swift
//  Inugress
//
//  Created by PCUser on 3/2/16.
//  Copyright © 2016 Haoxiang Li. All rights reserved.
//

import UIKit

class SubViewController: UIViewController {

    @IBOutlet var selectedImgView: UIImageView!
    @IBOutlet var selectedNameLabel: UILabel!
    @IBOutlet var selectedProbabilityLabel: UILabel!
    @IBOutlet var backButton: UIButton!
    @IBOutlet var inceptionIndexLabel: UILabel!
    @IBOutlet var noCountLabel: UILabel!
    
    // DogTableViewController.swift の prepareForSeque 関数で代入される
    var selectedImg: UIImage!
    var selectedRecognizedString: String!
    var selectedProbabilityString: String!
    var selectedInceptionIndexString: String!
    var selectedNoCountString: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        

        // Do any additional setup after loading the view.
        
        self.view.backgroundColor = MyColor.backColor()
        
        backButton.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Normal)
        backButton.backgroundColor = MyColor.textColor()

        
        selectedNameLabel.numberOfLines = 0
        
        selectedImgView.image = selectedImg
        selectedNameLabel.text = selectedRecognizedString
        selectedProbabilityLabel.text = selectedProbabilityString
        
        inceptionIndexLabel.text = selectedInceptionIndexString
        noCountLabel.text = selectedNoCountString
        
//        // UIImageView を画像に合うように縮小させる。これがないと枠が画像に沿わない
//        selectedImgView.frame = CGRectMake(0,100, selectedImg.size.width, selectedImg.size.height)
//
//        selectedImgView.layer.borderWidth = 3.0
//        selectedImgView.layer.cornerRadius = 10.0
//        selectedImgView.layer.masksToBounds = true
//        selectedImgView.layer.borderColor = MyColor.textColor().CGColor

        
        // 画像のアスペクト比を維持して収まるように
         selectedImgView.contentMode = UIViewContentMode.ScaleAspectFit
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func goBackToTable () {
        dismissViewControllerAnimated(true, completion: nil)
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
