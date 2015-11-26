//
//  MessageTool.m
//  Client
//
//  Created by xiaerfei on 15/10/27.
//  Copyright (c) 2015年 xiaochuan. All rights reserved.
//

#import "MessageTool.h"
@implementation MessageTool


+ (void)setToken:(NSString *)token {
    NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
    [settings setObject:token forKey:@"token"];
    [settings synchronize];
}

+ (NSString *)token {
    NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
    return [settings objectForKey:@"token"];
}

+ (NSString *)PushGlobalNotificationStr {
    return @"PushGlobalNotification";
}

+ (NSString *)DBChangeNotificationStr {
    return @"DBChangeNotification";
}

+ (NSString *)disConnectNotificationStr {
    return @"disConnectNotificationStr";
}

+ (void)setConnectState:(NSString *)connectState {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setValue:connectState forKey:[NSString stringWithFormat:@"%@connectState",[MessageTool getOwerUserID]]];
    [defaults synchronize];
}

+ (NSString *)connectState {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults objectForKey:[NSString stringWithFormat:@"%@connectState",[MessageTool getOwerUserID]]];
}


+ (void)setDisturbed:(NSString *)disturbedStr {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setValue:disturbedStr forKey:[NSString stringWithFormat:@"%@disturb",[MessageTool getOwerUserID]]];
    [defaults synchronize];
}

+ (NSString *)getDisturbed {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults objectForKey:[NSString stringWithFormat:@"%@disturb",[MessageTool getOwerUserID]]];
}

+ (void)setUserID:(NSString *)userID {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setValue:userID forKey:[NSString stringWithFormat:@"%@userID",[MessageTool getOwerUserID]]];
    [defaults synchronize];
}

+ (NSString *)getUserID {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults objectForKey:[NSString stringWithFormat:@"%@userID",[MessageTool getOwerUserID]]];
}

+ (void)setSessionId:(NSString *)sessionId {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setValue:sessionId forKey:[NSString stringWithFormat:@"%@sessionId",[MessageTool getOwerUserID]]];
    [defaults synchronize];
}

+ (NSString *)sessionId {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults objectForKey:[NSString stringWithFormat:@"%@sessionId",[MessageTool getOwerUserID]]];
}

+ (void)setClientCacheExprired:(NSString *)clientCacheExprired {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setValue:clientCacheExprired forKey:[NSString stringWithFormat:@"%@clientCacheExprired",[MessageTool getOwerUserID]]];
    [defaults synchronize];
}

+ (NSString *)clientCacheExprired {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults objectForKey:[NSString stringWithFormat:@"%@clientCacheExprired",[MessageTool getOwerUserID]]];
}

+ (void)setLastedReadTime:(NSString *)lastedReadTime {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setValue:lastedReadTime forKey:[NSString stringWithFormat:@"%@lastedReadTime",[MessageTool getOwerUserID]]];
    [defaults synchronize];
}

+ (NSString *)lastedReadTime {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults objectForKey:[NSString stringWithFormat:@"%@lastedReadTime",[MessageTool getOwerUserID]]];
}

+ (void)setDBChange:(NSString *)isChanged {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setValue:isChanged forKey:[NSString stringWithFormat:@"%@isChanged",[MessageTool getOwerUserID]]];
    [defaults synchronize];
    
}

+ (NSString *)DBChange {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults objectForKey:[NSString stringWithFormat:@"%@isChanged",[MessageTool getOwerUserID]]];
}

//置顶groupid
+ (void)setTopGroupId:(NSString *)topGroupId {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setValue:topGroupId forKey:[NSString stringWithFormat:@"%@topGroupId",[MessageTool getOwerUserID]]];
    [defaults synchronize];
}

+ (NSString *)topGroupId {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults objectForKey:[NSString stringWithFormat:@"%@topGroupId",[MessageTool getOwerUserID]]];
}
//区别有无未读消息
+ (void)setUnReadMessage:(NSString *)unReadMessage {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setValue:unReadMessage forKey:[NSString stringWithFormat:@"%@unReadMessage",[MessageTool getOwerUserID]]];
    [defaults synchronize];
}

+ (NSString *)unReadMessage {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults objectForKey:[NSString stringWithFormat:@"%@unReadMessage",[MessageTool getOwerUserID]]];
}

+ (NSString *)getOwerUserID {
    return @"distinctAccount";
}

@end
