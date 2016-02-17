//
//  ViewController.m
//  WhatIsThis
//
//  Created by Haoxiang Li on 1/23/16.
//  Copyright © 2016 Haoxiang Li. All rights reserved.
//

#import "ViewController.h"

@interface ViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (nonatomic, retain) UIActivityIndicatorView *indicatorView;

@end

@implementation ViewController

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
    size_t max_idx = std::distance(outputs.begin(), std::max_element(outputs.begin(), outputs.end()));
    return [[model_synset objectAtIndex:max_idx] componentsJoinedByString:@" "];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.indicatorView = [UIActivityIndicatorView new];
    [self.indicatorView setActivityIndicatorViewStyle:UIActivityIndicatorViewStyleGray];
    
    if (!predictor) {
        NSString *jsonPath = [[NSBundle mainBundle] pathForResource:@"Inception_BN-symbol.json" ofType:nil];
        NSString *paramsPath = [[NSBundle mainBundle] pathForResource:@"Inception_BN-0039.params" ofType:nil];
        NSString *meanPath = [[NSBundle mainBundle] pathForResource:@"mean_224.bin" ofType:nil];
        NSString *synsetPath = [[NSBundle mainBundle] pathForResource:@"synset.txt" ofType:nil];
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
        std::vector<uint8_t> mean_with_alpha(kDefaultWidth*kDefaultHeight*(kDefaultChannels+1), 0);
        float *p_mean[3] = {
            model_mean,
            model_mean + kDefaultWidth*kDefaultHeight,
            model_mean + kDefaultWidth*kDefaultHeight*2};
        for (int i = 0, map_idx = 0, glb_idx = 0; i < kDefaultHeight; i++) {
            for (int j = 0; j < kDefaultWidth; j++) {
                mean_with_alpha[glb_idx++] = p_mean[0][map_idx];
                mean_with_alpha[glb_idx++] = p_mean[1][map_idx];
                mean_with_alpha[glb_idx++] = p_mean[2][map_idx];
                mean_with_alpha[glb_idx++] = 0;
                map_idx++;
            }
        }
        
        NSData *mean_data = [NSData dataWithBytes:mean_with_alpha.data() length:mean_with_alpha.size()*sizeof(float)];
        CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)mean_data);
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        // Creating CGImage from cv::Mat
        CGImageRef imageRef = CGImageCreate(kDefaultWidth,
                                            kDefaultHeight,
                                            8,
                                            8*(kDefaultChannels+1),
                                            kDefaultWidth*(kDefaultChannels+1),
                                            colorSpace,
                                            kCGImageAlphaNone|kCGBitmapByteOrderDefault,
                                            provider,
                                            NULL,
                                            false,
                                            kCGRenderingIntentDefault
                                            );
        meanImage = [UIImage imageWithCGImage:imageRef];
        CGImageRelease(imageRef);
        CGDataProviderRelease(provider);
        self.imageViewPhoto.image = meanImage;
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

// メイン画面で "Save Photo" ボタンを押したときに呼ばれる関数。
// 認識された結果である犬の情報を、NSUserDefaults に保存する。
- (IBAction)saveSelectedImage:(id)sender {
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
    
    NSLog(@"Saved"); // デバッグ用。右下に Saved と表示させる。
    NSLog(self.labelDescription.text); // デバッグ用。右下に 保存した認識結果の文字列を表示する。
    
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

@end
