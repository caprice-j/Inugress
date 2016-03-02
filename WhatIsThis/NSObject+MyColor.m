//
//  NSObject+MyColor.m
//  Inugress
//
//  Created by PCUser on 3/1/16.
//  Copyright © 2016 Haoxiang Li. All rights reserved.
//

#import "Inugress-Bridging-Header.h"

@implementation MyColor

+ (UIColor *)backColor{
    return [UIColor colorWithRed:255.0/255.0 green:243.0/255.0 blue:227.0/255.0 alpha:1.0];
}

+ (UIColor *)textColor{
    return [UIColor colorWithRed:71.0/255.0 green:63.0/255.0 blue:60.0/255.0 alpha:1.0];
}

+ (UIColor *)accentColor{
    return [UIColor colorWithRed:211.0/255.0 green:62.0/255.0 blue:67.0/255.0 alpha:1.0];
}

+ (unsigned long)inceptionOffset{
    return 150;
}

@end

//    static let   textColor = UIColor(red: 71.0 / 255, green: 63.0 / 255, blue: 60.0 / 255, alpha: 1)
// static let accentColor = UIColor(red:  211 / 255, green:   62 / 255, blue:   67 / 255, alpha: 1)
