//
//  Certificate.h
//  CodeSign
//
//  Created by yrtd on 15/11/6.
//  Copyright © 2015年 kuaiyong. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Certificate : NSObject
@property(nonatomic, retain) NSString* filename;
@property(nonatomic, retain) NSString* password;

@property(nonatomic, retain) NSString* label;
@property(nonatomic, retain) NSArray* summary;

- (instancetype) initWithContentOfFile:(NSString*) filename password:(NSString*) password;
@end
