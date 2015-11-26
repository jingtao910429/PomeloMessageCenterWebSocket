//
//  MessageTool.h
//  Client
//
//  Created by xiaerfei on 15/10/27.
//  Copyright (c) 2015年 xiaochuan. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MessageTool : NSObject

//设置token
+ (void)setToken:(NSString *)token;
+ (NSString *)token;
//服务器推送通知
+ (NSString *)PushGlobalNotificationStr;
//数据库更改通知
+ (NSString *)DBChangeNotificationStr;
//失去连接通知
+ (NSString *)disConnectNotificationStr;

//设置当前连接状态
+ (NSString *)connectState;
+ (void)setConnectState:(NSString *)connectState;

//消息免打扰（全局disable）-------区分用户
+ (void)setDisturbed:(NSString *)disturbedStr;
+ (NSString *)getDisturbed;

+ (void)setUserID:(NSString *)userID;
+ (NSString *)getUserID;

//会话sessionId
+ (void)setSessionId:(NSString *)sessionId;
+ (NSString *)sessionId;

//本地消息是否过期
+ (void)setClientCacheExprired:(NSString *)clientCacheExprired;
+ (NSString *)clientCacheExprired;
//客户端最新消息时间
+ (void)setLastedReadTime:(NSString *)lastedReadTime;
+ (NSString *)lastedReadTime;

+ (void)setDBChange:(NSString *)isChanged;
+ (NSString *)DBChange;

//置顶groupid
+ (void)setTopGroupId:(NSString *)topGroupId;
+ (NSString *)topGroupId;

+ (void)setUnReadMessage:(NSString *)unReadMessage;
+ (NSString *)unReadMessage;
@end
