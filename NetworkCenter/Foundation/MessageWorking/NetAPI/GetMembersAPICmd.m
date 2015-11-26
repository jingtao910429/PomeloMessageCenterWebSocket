//
//  GetMembersAPICmd.m
//  RongYu100
//
//  Created by wwt on 15/11/10.
//  Copyright (c) 2015年 ___RongYu100___. All rights reserved.
//

#import "GetMembersAPICmd.h"

@implementation GetMembersAPICmd

- (RYBaseAPICmdRequestType)requestType
{
    return RYBaseAPICmdRequestTypeGet;
}

- (NSString *)apiCmdDescription
{
    return @"获取组成员";
}

@end
