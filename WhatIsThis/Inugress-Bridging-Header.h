//
//  Use this file to import your target's public headers that you would like to expose to Swift.
//

#import <Realm/Realm.h> // see: http://qiita.com/matscube/items/3ed7de879f4efd460c44
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
// See: https://realm.io/jp/docs/objc/latest/
@interface DogRecord : RLMObject
@property NSString * recognizedNameString;
@property NSString * percent;
@property BOOL isDog; // Boolean does not work for some reason ... too much waste of time
@property NSData * pictureNSData;
@property NSString * createdAt; // 主キーは String か 整数じゃないといけない？
@property int inceptionIndex; // 主キーは String か 整数じゃないといけない？
@end
RLM_ARRAY_TYPE(DogRecord)

@interface MyColor : NSObject

+ (UIColor *) backColor;
+ (UIColor *) textColor;
+ (UIColor *) accentColor;
@end