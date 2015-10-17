//
//  RYBaseAPIManage.m
//  Client
//
//  Created by wwt on 15/10/17.
//  Copyright (c) 2015年 xiaochuan. All rights reserved.
//

#import "RYChatAPIManager.h"

static RYChatAPIManager *shareManager = nil;

@implementation RYChatAPIManager

+ (instancetype)shareManager {
    
    static dispatch_once_t onceInstance;
    dispatch_once(&onceInstance, ^{
        shareManager = [[RYChatAPIManager alloc] init];
    });
    return shareManager;
}

+ (NSString *)routeWithType:(NSInteger)type {
    
    NSString *routeStr = @"";
    
    switch (type) {
        case RouteGateTypeQueryEntry:
            routeStr = @"gate.gateHandler.queryEntry";
            break;
        case RouteConnectorTypeInit:
            routeStr = @"connector.entryHandler.init";
            break;
        case RouteConnectorTypePush:
            routeStr = @"connector.entryHandler.push";
            break;
        case RouteConnectorTypeProto:
            routeStr = @"connector.entryHandler.proto";
            break;
        default:
            break;
    }
    return routeStr;
}

+ (NSDictionary *)parametersWithType:(BOOL)isConnectInit {
    
    if (isConnectInit) {
        return @{@"uid":[RYChatAPIManager token]};
    }
    return @{@"token":[RYChatAPIManager token]};
}

+ (NSString *)host {
    return @"192.168.253.35";
}

+ (NSString *)port {
    return @"3014";
}

+ (NSString *)token {
    
    NSArray *cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies];
    
    for (int i = 0; i < cookies.count; i ++) {
        
        NSString *cookieName = [(NSHTTPCookie *)cookies[i] name];
        
        if ([cookieName isEqualToString:@"Token"]) {
            return [(NSHTTPCookie *)cookies[i] value];
            break;
        }
    }
    
    return nil;
}

@end
