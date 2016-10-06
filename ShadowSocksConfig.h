//
//  ShadowSocksConfig.h
//  ShadowsocksSW
//
//  Created by Xuhui on 16/9/25.
//  Copyright © 2016年 Xuhui. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ShadowSocksConfig : NSObject

@property (nonatomic, copy) NSString *ssServerAddress;
@property (nonatomic, copy) NSString *ssServerPort;
@property (nonatomic, copy) NSString *password;
@property (nonatomic, copy) NSString *encryptionMethod;
@property (nonatomic, copy) NSString *configName;

@end
