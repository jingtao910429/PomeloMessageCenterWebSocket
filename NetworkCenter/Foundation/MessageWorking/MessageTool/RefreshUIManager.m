//
//  RefreshUIManager.m
//  RongYu100
//
//  Created by wwt on 15/11/13.
//  Copyright (c) 2015年 ___RongYu100___. All rights reserved.
//

#import "RefreshUIManager.h"
#import "PomeloMessageCenterDBManager.h"
#import "MessageTool.h"

@implementation RefreshUIManager

+(instancetype)defaultManager{
    
    static RefreshUIManager *refreshUIManager = nil;
    @synchronized(self){
        if (refreshUIManager == nil) {
            refreshUIManager = [[RefreshUIManager alloc]init];
        }
    }
    
    return refreshUIManager;
}
- (instancetype)init
{
    self = [super init];
    if (self) {
        _timer = [NSTimer timerWithTimeInterval:3 target:self selector:@selector(timerControl) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:_timer forMode:NSRunLoopCommonModes];
        [_timer fire];

        _dataBaseFreshTimer = [NSTimer timerWithTimeInterval:1.5 target:self selector:@selector(dataBaseFreshTimerControl) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:_dataBaseFreshTimer forMode:NSRunLoopCommonModes];
        [_dataBaseFreshTimer fire];
    }
    return self;
}

- (void)timerControl {
    
    if (self.isPushNoReadMessage) {
        [[PomeloMessageCenterDBManager shareInstance] loadDataWhenPushHistoryMessage];
        [[NSNotificationCenter defaultCenter] postNotificationName:[MessageTool DBChangeNotificationStr] object:nil];
        [_timer invalidate];
        _timer = nil;
    }
    
}

- (void)dataBaseFreshTimerControl {
    
    if (!self.isPushNoReadMessage && [[MessageTool DBChange] isEqualToString:@"YES"]) {
        [MessageTool setDBChange:@"NO"];
        [[NSNotificationCenter defaultCenter] postNotificationName:[MessageTool DBChangeNotificationStr] object:nil];
    }
    
}

@end
