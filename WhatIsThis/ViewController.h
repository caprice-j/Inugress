//
//  ViewController.h
//  WhatIsThis
//
//  Created by Haoxiang Li on 1/23/16.
//  Copyright © 2016 Haoxiang Li. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "c_predict_api.h"
#import <vector>

#define kDefaultWidth 224
#define kDefaultHeight 224
#define kDefaultChannels 3
#define kDefaultImageSize (kDefaultWidth*kDefaultHeight*kDefaultChannels)

@interface ViewController : UIViewController {
    
    PredictorHandle predictor;
    
    NSString *model_symbol;
    NSData *model_params;
    NSMutableArray *model_synset;
    float model_mean[kDefaultImageSize];
    UIImage *meanImage;
}

@property (weak, nonatomic) IBOutlet UILabel *borderLabel;


@property (weak, nonatomic) IBOutlet UILabel *labelDescription;
@property (weak, nonatomic) IBOutlet UIImageView *imageViewPhoto;
@property (weak, nonatomic) IBOutlet UIImageView *baloonImageView;
@property (weak, nonatomic) IBOutlet UILabel *baloonLabel;
@property (weak, nonatomic) IBOutlet UILabel *baloonLabel2;


@property (weak, nonatomic) IBOutlet UILabel *dogProbabilityLabel;
@property (weak, nonatomic) IBOutlet UILabel *allDescriptionLabel;
@property (weak, nonatomic) IBOutlet UILabel *allProbabilityLabel;

@property (weak, nonatomic) IBOutlet UILabel *allPercentLabel;
@property (weak, nonatomic) IBOutlet UILabel *dogPercentLabel;

@property (weak, nonatomic) IBOutlet UIButton *goBackToTopButton;
@property (weak, nonatomic) IBOutlet UIButton *takePhotoButton;
@property (weak, nonatomic) IBOutlet UIButton *selectPhotoButton;
@property (weak, nonatomic) IBOutlet UIButton *saveResultButton;


- (IBAction)goBackToTop:(id)sender;

@end

