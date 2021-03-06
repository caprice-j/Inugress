//
//  ViewController.m
//  WhatIsThis
//
//  Created by Haoxiang Li on 1/23/16.
//  Copyright © 2016 Haoxiang Li. All rights reserved.
//

#import "ViewController.h"
#import <Realm/Realm.h> // この一行がないと Realm 型が呼び出せない

// @interface DogRecord は Swift でもこの DogRecord を使えるようにするために Inugress-Bridging-Header.h　へ移動した
#import "Inugress-Bridging-Header.h"
#import <QuartzCore/QuartzCore.h> // UIImageView の枠線などを付けるため
// この Implementation の2行がないと、 "_OBJC_CLASS_$_DogRecord", referenced from: というエラーになる
@implementation DogRecord
// 何も書かなくてよい
//+ (NSString *)primaryKey {
//    return @"createdAt";
//}
@end

@interface ViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (nonatomic, retain) UIActivityIndicatorView *indicatorView;

@end

@implementation ViewController

- (float)roundProbability:(float)rawProb {
    float prob = rawProb * 1000;

    return roundf(prob) / 10;
}

NSString * noticeNSString = @"ではなく ... ";

// 引数として渡された UIImage に写っている物体を認識し、その物体名を文字列で返す
- (NSString *)predictImage:(UIImage *)image {


    const int numForRendering = kDefaultWidth*kDefaultHeight*(kDefaultChannels+1);
    const int numForComputing = kDefaultWidth*kDefaultHeight*kDefaultChannels;

    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    uint8_t imageData[numForRendering];
    CGContextRef contextRef = CGBitmapContextCreate(imageData,
                                                    kDefaultWidth,
                                                    kDefaultHeight,
                                                    8,
                                                    kDefaultWidth*(kDefaultChannels+1),
                                                    colorSpace,
                                                    kCGImageAlphaNoneSkipLast | kCGBitmapByteOrderDefault);
    CGContextDrawImage(contextRef, CGRectMake(0, 0, kDefaultWidth, kDefaultHeight), image.CGImage);
    CGContextRelease(contextRef);
    CGColorSpaceRelease(colorSpace);

    //< Subtract the mean and copy to the input buffer
    std::vector<float> input_buffer(numForComputing);
    float *p_input_buffer[3] = {
        input_buffer.data(),
        input_buffer.data() + kDefaultWidth*kDefaultHeight,
        input_buffer.data() + kDefaultWidth*kDefaultHeight*2};
    const float *p_mean[3] = {
        model_mean,
        model_mean + kDefaultWidth*kDefaultHeight,
        model_mean + kDefaultWidth*kDefaultHeight*2};
    for (int i = 0, map_idx = 0, glb_idx = 0; i < kDefaultHeight; i++) {
        for (int j = 0; j < kDefaultWidth; j++) {
            p_input_buffer[0][map_idx] = imageData[glb_idx++] - p_mean[0][map_idx];
            p_input_buffer[1][map_idx] = imageData[glb_idx++] - p_mean[1][map_idx];
            p_input_buffer[2][map_idx] = imageData[glb_idx++] - p_mean[2][map_idx];
            glb_idx++;
            map_idx++;
        }
    }
    
    mx_uint *shape = nil;
    mx_uint shape_len = 0;
    MXPredSetInput(predictor, "data", input_buffer.data(), numForComputing);
    MXPredForward(predictor);
    MXPredGetOutputShape(predictor, 0, &shape, &shape_len);
    mx_uint tt_size = 1;
    for (mx_uint i = 0; i < shape_len; i++) {
        tt_size *= shape[i];
    }
    std::vector<float> outputs(tt_size);
    MXPredGetOutput(predictor, 0, outputs.data(), tt_size);

    
    // size_t max_idx = std::distance(outputs.begin(), outputs.begin()); すると 最初の "Tinca" が返る
    // std::distance(outputs.begin(), outputs.begin()+151) は "チワワ" (最初の犬カテゴリ)
    // std::distance(outputs.begin(), outputs.begin()+268) は "メキシカン・ヘアレス・ドッグ" (最後の犬カテゴリ)

    
    // 1 ~ 1000 の全カテゴリに対してマッチングする場合は以下の１行
    size_t allMaxIdx = std::distance(outputs.begin(), std::max_element(outputs.begin(), outputs.end()));
    NSLog(@"AllMaxProbability: %f", outputs[allMaxIdx] );
    NSLog([[model_synset objectAtIndex:allMaxIdx] componentsJoinedByString:@" "]);

    
    
    // 犬種のラベルが付けられた152 ~ 269 番の中で確率最大のものを探すのであればこれ
    max_idx = std::distance(outputs.begin(),
                            std::max_element(outputs.begin()+151, outputs.begin()+268 ));

    NSLog([[model_synset objectAtIndex:max_idx] componentsJoinedByString:@" "]);
    NSLog(@"maxProbability: %f", outputs[max_idx] );
    
    
    // labelDescription は既に didFinishPickingMediaWithInfo 内部で変更されている
    
    dogProbability = outputs[max_idx];
    
    struct Comp{
        Comp( const std::vector<float>& v ) : _v(v) {}
        bool operator ()(int a, int b) { return _v[a] > _v[b]; }
        const std::vector<float>& _v;
    };
    
    [self clearRankingText];
    
    if( dogProbability > 0.01 ){
        // 犬であると判定した
        
        long unsigned idx = max_idx - [MyColor inceptionOffset];
        
        // RLMRealm *realm = [RLMRealm defaultRealm];
        RLMResults *dogs = [DogRecord objectsWhere:[NSString stringWithFormat:@"inceptionIndex == %lu", idx ]  ];
        bool alreadySaved;
        if( dogs.count == 0 ){
            alreadySaved = false;
            self.unseenIndicatorLabel.text = @"(NEW!)";
        }else{
            alreadySaved = true;
            self.unseenIndicatorLabel.text = @"";
        }
        
        self.dogProbabilityLabel.font =[self.dogProbabilityLabel.font fontWithSize:45];
        self.dogProbabilityLabel.text =
        [ NSString stringWithFormat:@"%.1f", [self roundProbability: dogProbability   ] ];

        self.dogPercentLabel.text = @"%";

        self.baloonLabel.text = @"";
        
        self.inceptionIndexPrefixLabel.text = @"No.";
        self.inceptionIndexLabel.text = [NSString stringWithFormat:@"%lu", idx ];
        
        if (dogProbability < 0.6 ) {
            // 他に正解の候補がありそう
            std::vector<int> vx;
            vx.resize(outputs.size());
            for( int i= 0; i<outputs.size(); ++i ) vx[i]= i;
            partial_sort( vx.begin(), vx.begin()+5, vx.end(), Comp(outputs) );
            NSLog(@"outputs[%d]: %.3f %@", vx[0], outputs[vx[0]], [[model_synset objectAtIndex:vx[0]] componentsJoinedByString:@" "] );
            NSLog(@"outputs[%d]: %.3f %@", vx[1], outputs[vx[1]], [[model_synset objectAtIndex:vx[1]] componentsJoinedByString:@" "] );
            NSLog(@"outputs[%d]: %.3f %@", vx[2], outputs[vx[2]], [[model_synset objectAtIndex:vx[2]] componentsJoinedByString:@" "] );
            NSLog(@"outputs[%d]: %.3f %@", vx[3], outputs[vx[3]], [[model_synset objectAtIndex:vx[3]] componentsJoinedByString:@" "] );
            NSLog(@"outputs[%d]: %.3f %@", vx[4], outputs[vx[4]], [[model_synset objectAtIndex:vx[4]] componentsJoinedByString:@" "] );
            
           [self displaySecond];
            self.secondDescriptionLabel.text = [[model_synset objectAtIndex:vx[1]] componentsJoinedByString:@" "];
            self.secondProbabilityLabel.text =
            [ NSString stringWithFormat:@"%.1f", [self roundProbability: outputs[vx[1]] ]];

           [self displayThird];
            self.thirdDescriptionLabel.text = [[model_synset objectAtIndex:vx[2]] componentsJoinedByString:@" "];
            self.thirdProbabilityLabel.text =
            [ NSString stringWithFormat:@"%.1f", [self roundProbability: outputs[vx[2]] ]];
            
            if( outputs[vx[3]] > 0.01 ){
                
                [self displayFourth];
                self.fourthDescriptionLabel.text = [[model_synset objectAtIndex:vx[3]] componentsJoinedByString:@" "];
                self.fourthProbabilityLabel.text =
                [ NSString stringWithFormat:@"%.1f", [self roundProbability: outputs[vx[3]] ]];
                
            }
            
        }
    }else{
        // 犬以外であると判定した
        self.dogPercentLabel.text = @"%";

        // self.labelDescription.text = @"犬が写っている可能性は ... "; // FIXME : async の方が優先されてしまう
        // self.dogProbabilityLabel.font =[self.dogProbabilityLabel.font fontWithSize:15];
        self.dogProbabilityLabel.text = // noticeNSString;
          [ NSString stringWithFormat:@"%.1f", [self roundProbability: outputs[allMaxIdx] ] ];
        // self.dogPercentLabel.text = @"";
        
        // self.allProbabilityLabel.text =
        // [ NSString stringWithFormat:@"%.1f", [self roundProbability: outputs[allMaxIdx] ] ];
        
        [self displaySecond];
        self.secondDescriptionLabel.text =
          [[model_synset objectAtIndex:allMaxIdx] componentsJoinedByString:@" "]; // "バインダー" などの物体名
        self.secondProbabilityLabel.text = @"";
        self.secondPercentSymbolLabel.text = @"";
        
        // self.allPercentLabel.text = @"%";
        self.inceptionIndexPrefixLabel.text = @"No.";
        self.inceptionIndexLabel.text = @" --";
        
    }
    
    if( [self.dogProbabilityLabel.text  isEqual: @"100.0"] ){
        self.dogProbabilityLabel.text = @"100";
    }
   

    
    return [[model_synset objectAtIndex:max_idx] componentsJoinedByString:@" "];
}

- (void)displaySecond {
    // self.secondDescriptionLabel.backgroundColor = [MyColor backColor];
//    self.baloonImageView.image = [UIImage imageNamed: @"baloon.png"];
    self.baloonLabel.text = @"もしかして...";
    self.secondPercentSymbolLabel.text = @"%";
//    self.baloonLabel2.text = @"かも？";
}

- (void)displayThird {
    // self.thirdDescriptionLabel.backgroundColor = [MyColor backColor];
    //    self.baloonImageView.image = [UIImage imageNamed: @"baloon.png"];
    self.baloonLabel.text = @"もしかして...";
    self.thirdPercentSymbolLabel.text = @"%";
    //    self.baloonLabel2.text = @"かも？";
}

- (void)displayFourth {
    // self.fourthDescriptionLabel.backgroundColor = [MyColor backColor];
    //    self.baloonImageView.image = [UIImage imageNamed: @"baloon.png"];
    self.baloonLabel.text = @"もしかして...";
    self.fourthPercentSymbolLabel.text = @"%";
    //    self.baloonLabel2.text = @"かも？";
}

- (void)clearRankingText {
    self.secondDescriptionLabel.backgroundColor = [MyColor backColor];
    self.thirdDescriptionLabel.backgroundColor = [MyColor backColor];
    self.fourthDescriptionLabel.backgroundColor = [MyColor backColor];
    self.secondPercentSymbolLabel.backgroundColor = [MyColor backColor];
    self.thirdPercentSymbolLabel.backgroundColor = [MyColor backColor];
    self.fourthPercentSymbolLabel.backgroundColor = [MyColor backColor];
    self.secondProbabilityLabel.backgroundColor = [MyColor backColor];
    self.thirdProbabilityLabel.backgroundColor = [MyColor backColor];
    self.fourthProbabilityLabel.backgroundColor = [MyColor backColor];
    
    self.secondDescriptionLabel.text   = @"";
    self.thirdDescriptionLabel.text    = @"";
    self.fourthDescriptionLabel.text   = @"";
    self.secondPercentSymbolLabel.text = @"";
    self.thirdPercentSymbolLabel.text  = @"";
    self.fourthPercentSymbolLabel.text = @"";
    self.secondProbabilityLabel.text   = @"";
    self.thirdProbabilityLabel.text    = @"";
    self.fourthProbabilityLabel.text   = @"";
}


- (void)viewDidLoad {
    
    self.imageViewPhoto.layer.borderWidth = 3.0f;
    self.imageViewPhoto.layer.cornerRadius = 10.0f;
    self.imageViewPhoto.layer.masksToBounds = true;
    self.imageViewPhoto.layer.borderColor = [MyColor textColor].CGColor;
    
    self.borderLabel.layer.borderColor = [MyColor textColor].CGColor;
    self.borderLabel.layer.borderWidth = 3.0;
    
//    self.saveResultButton.backgroundColor = [MyColorClass backColor];

    [self clearRankingText];
    self.unseenIndicatorLabel.text = @"";

    self.baloonLabel.text         = @"";
    self.baloonLabel2.text        = @"";
    self.dogPercentLabel.text     = @"";
    self.baloonImageView.image = nil;
    
    self.inceptionIndexLabel.text = @"";
    self.inceptionIndexPrefixLabel.text = @"";

    
    self.labelDescription.numberOfLines = 0;
    self.secondDescriptionLabel.numberOfLines = 0;
    
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.indicatorView = [UIActivityIndicatorView new];
    [self.indicatorView setActivityIndicatorViewStyle:UIActivityIndicatorViewStyleGray];
    
    if (!predictor) {
        NSString *jsonPath = [[NSBundle mainBundle] pathForResource:@"Inception_BN-symbol.json" ofType:nil];
        NSString *paramsPath = [[NSBundle mainBundle] pathForResource:@"Inception_BN-0039.params" ofType:nil];
        NSString *meanPath = [[NSBundle mainBundle] pathForResource:@"mean_224.bin" ofType:nil];
      //NSString *synsetPath = [[NSBundle mainBundle] pathForResource:@"synset.txt" ofType:nil];
      //NSString *synsetPath = [[NSBundle mainBundle] pathForResource:@"synset.jan.txt" ofType:nil];
        NSString *synsetPath = [[NSBundle mainBundle] pathForResource:@"synset.ej.txt" ofType:nil];
        NSLog(@"%@", meanPath);
        model_symbol = [[NSString alloc] initWithData:[[NSFileManager defaultManager] contentsAtPath:jsonPath] encoding:NSUTF8StringEncoding];
        model_params = [[NSFileManager defaultManager] contentsAtPath:paramsPath];
        
        NSString *input_name = @"data";
        const char *input_keys[1];
        input_keys[0] = [input_name UTF8String];
        const mx_uint input_shape_indptr[] = {0, 4};
        const mx_uint input_shape_data[] = {1, kDefaultChannels, kDefaultWidth, kDefaultHeight};
        MXPredCreate([model_symbol UTF8String], [model_params bytes], (int)[model_params length], 1, 0, 1,
                     input_keys, input_shape_indptr, input_shape_data, &predictor);
        
        NSData *meanData = [[NSFileManager defaultManager] contentsAtPath:meanPath];
        [meanData getBytes:model_mean length:[meanData length]];
        
        model_synset = [NSMutableArray new];
        NSString* synsetText = [NSString stringWithContentsOfFile:synsetPath
                                  encoding:NSUTF8StringEncoding error:nil];
        NSArray* lines = [synsetText componentsSeparatedByCharactersInSet:
                                    [NSCharacterSet newlineCharacterSet]];
        for (NSString *l in lines) {
            NSArray *parts = [l componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            if ([parts count] > 1) {
                [model_synset addObject:[parts subarrayWithRange:NSMakeRange(1, [parts count]-1)]];
            }
        }
        
        //< Visualize the Mean Data
//        std::vector<uint8_t> mean_with_alpha(kDefaultWidth*kDefaultHeight*(kDefaultChannels+1), 0);
//        float *p_mean[3] = {
//            model_mean,
//            model_mean + kDefaultWidth*kDefaultHeight,
//            model_mean + kDefaultWidth*kDefaultHeight*2};
//        for (int i = 0, map_idx = 0, glb_idx = 0; i < kDefaultHeight; i++) {
//            for (int j = 0; j < kDefaultWidth; j++) {
//                mean_with_alpha[glb_idx++] = p_mean[0][map_idx];
//                mean_with_alpha[glb_idx++] = p_mean[1][map_idx];
//                mean_with_alpha[glb_idx++] = p_mean[2][map_idx];
//                mean_with_alpha[glb_idx++] = 0;
//                map_idx++;
//            }
//        }
//        
//        NSData *mean_data = [NSData dataWithBytes:mean_with_alpha.data() length:mean_with_alpha.size()*sizeof(float)];
//        CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)mean_data);
//        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
//        // Creating CGImage from cv::Mat
//        CGImageRef imageRef = CGImageCreate(kDefaultWidth,
//                                            kDefaultHeight,
//                                            8,
//                                            8*(kDefaultChannels+1),
//                                            kDefaultWidth*(kDefaultChannels+1),
//                                            colorSpace,
//                                            kCGImageAlphaNone|kCGBitmapByteOrderDefault,
//                                            provider,
//                                            NULL,
//                                            false,
//                                            kCGRenderingIntentDefault
//                                            );
//        meanImage = [UIImage imageWithCGImage:imageRef];
//        CGImageRelease(imageRef);
//        CGDataProviderRelease(provider);
//        self.imageViewPhoto.image = meanImage;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)selectPhotoButtonTapped:(id)sender {
    UIImagePickerController *imagePicker = [UIImagePickerController new];
    imagePicker.allowsEditing = NO;
    imagePicker.sourceType =  UIImagePickerControllerSourceTypePhotoLibrary;
    imagePicker.delegate = self;
    [self presentViewController:imagePicker animated:YES completion:nil];
}

- (IBAction)capturePhotoButtonTapped:(id)sender {
    UIImagePickerController *imagePicker = [UIImagePickerController new];
    imagePicker.allowsEditing = NO;
    imagePicker.sourceType =  UIImagePickerControllerSourceTypeCamera;
    imagePicker.delegate = self;
    [self presentViewController:imagePicker animated:YES completion:nil];
}

- (NSString *)currentTimeInNSString{
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"ja_JP"]]; // Localeの指定
    [df setDateFormat:@"yyyy/MM/dd HH:mm:ss"];
    
    // 日付(NSDate) => 文字列(NSString)に変換
    NSDate *now = [NSDate date];
    NSString *strNow = [df stringFromDate:now];
    
    NSLog(@"CurrentTime：%@", strNow);
    return strNow;
}

// メイン画面で "Save Photo" ボタンを押したときに呼ばれる関数。
// 認識された結果である犬の情報を、NSUserDefaults に保存する。
- (IBAction)saveSelectedImage:(id)sender {
    
    NSString * alertNSString = @"";
    if( self.imageViewPhoto.image == nil ){
       alertNSString = @"Please specify your image first.";
    }else if( self.imageViewPhoto.image == previousSavedImage ){
       alertNSString = @"Already saved.";
    }
    
    if( self.imageViewPhoto.image == nil or
        self.imageViewPhoto.image == meanImage or
        self.imageViewPhoto.image == previousSavedImage ){
        
        // アラートを出す
        UIAlertController *alertController =
        [UIAlertController alertControllerWithTitle:@"Not Saved"
                                            message: alertNSString
                                     preferredStyle:UIAlertControllerStyleAlert];
        
        // addActionした順に左から右にボタンが配置される
        [alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            // otherボタンが押された時の処理
            [self otherButtonPushed];
        }]];
        [self presentViewController:alertController animated:YES completion:nil];
        
        return ;

    }
    
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];  // 取得
    
//    [ud setInteger:100 forKey:@"KEY_I"];  // int型の100をKEY_Iというキーで保存
//    [ud setFloat:1.23 forKey:@"KEY_F"];  // float型の1.23をKEY_Fというキーで保存
//    [ud setDouble:1.23 forKey:@"KEY_D"];  // double型の1.23をKEY_Dというキーで保存
//    [ud setBool:YES forKey:@"KEY_B"];  // BOOL型のYESをKEY_Bというキーで保存
//    [ud setObject:@"あいう" forKey:@"KEY_S"];  // "あいう"をKEY_Sというキーで保存

    
    // NSMutableArray* array = [NSMutableArray array];  // これだと配列が毎回、初期化されてしまう
    
    // NSDefaults から、 KEY_S というキーで保存されている配列を読み込む
    NSArray * savedArrayOfDogInfoDictionary = [ud arrayForKey:@"KEY_S"];
    
    // 読み込んだ段階では immutable (変更不可能) なので、 mutable な配列に一度変換する
    NSMutableArray * mutableArray = [NSMutableArray arrayWithArray:savedArrayOfDogInfoDictionary];
    
    // 一枚の写真に写った犬の情報を表す[ 値A, キーA, 値B, キーB, ... , nil ] という dictionary を追加する
    // self.labelDescription.text には "ウェルシュ・コーギー" や "柴犬" などの認識結果文字列が入っている
    [mutableArray addObject: [NSDictionary dictionaryWithObjectsAndKeys: self.labelDescription.text, @"objname", nil]  ];
    
    // 「 NSUserDefaults に KEY_S というキーで保存されているオブジェクト」を上書きする
    [ud setObject:mutableArray forKey:@"KEY_S"];
    
    [ud synchronize];  // その変更を NSUserDefaults に即時反映させる（即時で無くてもよい場合は不要）
    
    // ローカルデータベースであるRealmを呼び出す。CREATE DATABASEに相当する一行。
    DogRecord *mydog = [[DogRecord alloc] init];
    mydog.recognizedNameString = @"Rex";
    
    
    
    
    // NSData には 16 MB までしか入らない。 シミュレータ内の画像で 11.3 MB ほど。
    // 問題にそなえ、リサイズしておく
    // FIXME: 16 MB 以下になるまでリサイズを繰り返す
    
    UIImage * image = self.imageViewPhoto.image;
    previousSavedImage = image; // 重複保存をさけるための条件分岐に使う
    
    CGImageRef imageRef = [image CGImage];
    size_t w = CGImageGetWidth(imageRef);
    size_t h = CGImageGetHeight(imageRef);
    size_t resize_w, resize_h;
    
    if (w>h) {
        resize_w = 320; // FIXME
        resize_h = h * resize_w / w;
    } else {
        resize_h = 480;
        resize_w = w * resize_h / h;
    }
    
    UIGraphicsBeginImageContext(CGSizeMake(resize_w, resize_h));
    [image drawInRect:CGRectMake(0, 0, resize_w, resize_h)];
    image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    
    NSLog( @" Image size is %d KB", (int) floor( UIImagePNGRepresentation( image ).length / 1000 ) );
    
    mydog.pictureNSData = UIImagePNGRepresentation( image );
    if( dogProbability < 0.01 ){
        mydog.recognizedNameString = self.labelDescription.text;
        mydog.percent = self.dogProbabilityLabel.text;
        mydog.isDog = false;
        mydog.createdAt = [self currentTimeInNSString];
        mydog.inceptionIndex = -1; // placeholder
    }else{
        mydog.recognizedNameString = self.labelDescription.text;
        mydog.percent = self.dogProbabilityLabel.text;
        mydog.isDog = true;
        mydog.createdAt = [self currentTimeInNSString];
        mydog.inceptionIndex = max_idx - [MyColor inceptionOffset]; // チワワが1のはず
    }
    
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm transactionWithBlock:^{
        [realm addObject:mydog];
    }];
    
    
    NSLog(@"Saved"); // デバッグ用。右下に Saved と表示させる。
    NSLog(self.labelDescription.text); // デバッグ用。右下に 保存した認識結果の文字列を表示する。
    
    
    // アラートを出す
    UIAlertController *alertController =
      [UIAlertController alertControllerWithTitle:@"SUCCESS"
                                          message:@"Saved to your album."
                                   preferredStyle:UIAlertControllerStyleAlert];
    
    // addActionした順に左から右にボタンが配置される
    [alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        // otherボタンが押された時の処理
        [self otherButtonPushed];
    }]];
    [self presentViewController:alertController animated:YES completion:nil];
    
}

- (void)otherButtonPushed {

}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    UIImage *chosenImage = info[UIImagePickerControllerOriginalImage];
    self.imageViewPhoto.image = chosenImage;
    [picker dismissViewControllerAnimated:YES completion:^(void){
        [self.view addSubview:self.indicatorView];
        self.indicatorView.frame = self.view.bounds;
        [self.indicatorView startAnimating];
        
        // 非同期 asynchronous に、ニューラルネットワークによる認識処理 (predictImage関数) を進める
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(){
            dispatch_async(dispatch_get_main_queue(), ^(){
                
                self.labelDescription.text = [self predictImage:self.imageViewPhoto.image];
                [self.indicatorView stopAnimating];
                
                // 認識結果を示す文字列（「コーギー」「柴犬」など）が更新されている
                // NSLog(@"%@",self.labelDescription.text);
                
            });
        });
    }];
    
    // async なので、ここに書いたとしても上記の処理のあとに実行されるとは限らない
    // たとえば NSLogをここに書いた場合、認識されるまえの文字列が表示されてしまうことがある
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)goBackToTop:(id)sender{
    // この一行がないと、次にTakePhotoの画面に来たときに、解放済みの読み込んだ画像にアクセスして BAD_ACCESS エラーが出る
    self.imageViewPhoto.image = meanImage;

    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
