//
//  Use this file to import your target's public headers that you would like to expose to Swift.
//

#import <Realm/Realm.h> // see: http://qiita.com/matscube/items/3ed7de879f4efd460c44

// See: https://realm.io/jp/docs/objc/latest/
@interface DogRecord : RLMObject
@property NSString * recognizedNameString;
@property NSData * pictureNSData;
@end
RLM_ARRAY_TYPE(DogRecord)
