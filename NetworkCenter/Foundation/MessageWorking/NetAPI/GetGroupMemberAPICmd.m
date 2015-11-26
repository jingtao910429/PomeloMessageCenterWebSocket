//
//  GetGroupMemberAPICmd.m
//  RongYu100
//
//  Created by wwt on 15/11/16.
//  Copyright (c) 2015年 ___RongYu100___. All rights reserved.
//

#import "GetGroupMemberAPICmd.h"

@implementation GetGroupMemberAPICmd

- (RYBaseAPICmdRequestType)requestType
{
    return RYBaseAPICmdRequestTypeGet;
}

- (NSString *)apiCmdDescription
{
    return @"获取组单个成员";
}

@end
