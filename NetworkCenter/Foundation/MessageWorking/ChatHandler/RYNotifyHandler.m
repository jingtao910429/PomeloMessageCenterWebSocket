//
//  RYRouteHandler.m
//  Client
//
//  Created by wwt on 15/10/22.
//  Copyright (c) 2015年 xiaochuan. All rights reserved.
//

#import "RYNotifyHandler.h"
#import "PomeloClient.h"
#import "RYChatAPIManager.h"
#import "ConnectToServer.h"
#import "MessageTool.h"
#import "PomeloMessageCenterDBManager.h"
#import "RYChatHandler.h"
#import "MessageCenterUserModel.h"
#import "GetMembersAPICmd.h"
#import "GetGroupMemberAPICmd.h"
#import "RefreshUIManager.h"
#import "LZAudioTool.h"
#import "NSString+Extension.h"

//消息中心获取组单个成员信息
#define GetGroupMember @"api_v2/MsgGroupMemberInfo/%@/getMember?userId=%@"
//消息中心获取组成员(组ID 4D3F8221-1CD7-44BC-80A6-C8BED5AFE904 这个有数据)
#define GetMembers  @"api_v2/MsgGroupMemberInfo/%@/getMembers"

static RYNotifyHandler *shareHandler = nil;

@interface RYNotifyHandler () <APICmdApiCallBackDelegate>

@property (nonatomic, strong) RYChatHandler *getGroupInfoChatHandler;
@property (nonatomic, strong) RYChatHandler *findUserChatHandler;

//获取组成员
@property (nonatomic, strong) GetMembersAPICmd *getMembersAPICmd;
//获取组单个成员信息
@property (nonatomic, strong) GetGroupMemberAPICmd *getGroupMemberAPICmd;

@end

@implementation RYNotifyHandler

+ (instancetype)shareHandler {
    
    static dispatch_once_t onceInstance;
    dispatch_once(&onceInstance, ^{
        shareHandler = [[RYNotifyHandler alloc] init];
    });
    return shareHandler;
}

//- (void)onNotify {
//
//    ConnectToServer *connectToServer = [ConnectToServer shareInstance];
//
//    [connectToServer.chatClient onRoute:[RYChatAPIManager notifyWithType:self.notifyType] withCallback:^(id arg, NSString *route) {
//
//        dispatch_async(dispatch_get_main_queue(), ^{
//            [[NSNotificationCenter defaultCenter] postNotificationName:[MessageTool PushGlobalNotificationStr] object:arg userInfo:nil];
//        });
//
//    }];
//
//}

- (void)onAllNotify {
    
    NSArray *tempNotifyArr = @[[NSNumber numberWithInt:NotifyTypeOnChat],[NSNumber numberWithInt:NotifyTypeOnRead],[NSNumber numberWithInt:NotifyTypeOnTop],[NSNumber numberWithInt:NotifyTypeOnDisturbed],[NSNumber numberWithInt:NotifyTypeOnGroupMsgList],[NSNumber numberWithInt:NotifyTypeOnClientStatus],[NSNumber numberWithInt:NotifyTypeOnClientShow],[NSNumber numberWithInt:NotifyTypeOnChatHistory]];
    
    for (NSNumber *subNumber in tempNotifyArr) {
        
        ConnectToServer *connectToServer = [ConnectToServer shareInstance];
        
        self.notifyType = [subNumber intValue];
        
        __block RYNotifyHandler *weakSelf = self;
        
        [connectToServer.chatClient onRoute:[RYChatAPIManager notifyWithType:self.notifyType] withCallback:^(id arg , NSString *route) {
            
            [RefreshUIManager defaultManager].isPushNoReadMessage = NO;
            
            if ([route isEqualToString:[RYChatAPIManager notifyWithType:NotifyTypeOnChat]]) {
                
                NSMutableDictionary *tempDict = [[NSMutableDictionary alloc] initWithDictionary:arg];
                
#pragma mark  待测试
                [weakSelf storeMessageWithDict:tempDict];
                
                //                dispatch_queue_t queue = dispatch_queue_create([[NSString stringWithFormat:@"route%d",arc4random()] UTF8String], NULL);
                //                dispatch_async(queue, ^{
                //                    [weakSelf storeMessageWithDict:tempDict];
                //                });
                
            }else if ([route isEqualToString:[RYChatAPIManager notifyWithType:NotifyTypeOnChatHistory]]) {
                
                NSArray *messages = [[NSArray alloc] initWithArray:arg];
                
                [RefreshUIManager defaultManager].isPushNoReadMessage = YES;
                
                for (int i = 0; i < [messages count]; i ++ ) {
                    
                    NSMutableDictionary *tempDict = [[NSMutableDictionary alloc] init];
                    
                    [tempDict setValue:[NSString stringWithFormat:@"%@",messages[i][@"_id"]]     forKey:@"MessageId"];
                    [tempDict setValue:[NSString stringWithFormat:@"%@",messages[i][@"time"]]    forKey:@"CreateTime"];
                    [tempDict setValue:[NSString stringWithFormat:@"%@",messages[i][@"from"]]    forKey:@"UserId"];
                    
                    [tempDict setValue:[NSString stringWithFormat:@"%@",messages[i][@"groupId"]] forKey:@"GroupId"];
                    [tempDict setValue:[[NSString stringWithFormat:@"%@",messages[i][@"content"]] unescape] forKey:@"MsgContent"];
                    [tempDict setValue:@"1"               forKey:@"Status"];
                    
                    [tempDict setValue:[MessageTool getUserID] forKey:@"accountId"];
                    [tempDict setValue:[NSString stringWithFormat:@"%@",messages[i][@"clientMsgId"]] forKey:@"clientMsgId"];
                    [tempDict setValue:[NSString stringWithFormat:@"%@",messages[i][@"type"]] forKey:@"type"];
                    
                    //存储信息
                    [[PomeloMessageCenterDBManager shareInstance] addDataToTableWithType:MessageCenterDBManagerTypeMESSAGE data:[NSArray arrayWithObjects:tempDict, nil]];
                    
                    if (i == messages.count - 1) {
                        //设置未读消息
                        [MessageTool setLastedReadTime:tempDict[@"MessageId"]];
                    }
                    
                }
                
                
            }else if ([route isEqualToString:[RYChatAPIManager notifyWithType:NotifyTypeOnTop]]) {
                
                //置顶操作
                NSString *groupID = arg[@"groupId"];
                
                if (groupID && ![groupID isKindOfClass:[NSNull class]]) {
                    
                    
                    [MessageTool setTopGroupId:groupID];
                    //如果groupid存在，则为置顶组
                    [[PomeloMessageCenterDBManager shareInstance] markTopTableWithType:MessageCenterDBManagerTypeMETADATA SQLvalue:groupID];
                }else {
                    
                    [MessageTool setTopGroupId:@"NULL"];
                    //如果groupid不存在，则为取消置顶
                    [[PomeloMessageCenterDBManager shareInstance] markTopTableWithType:MessageCenterDBManagerTypeMETADATA SQLvalue:nil];
                    
                }
                
            }else if ([route isEqualToString:[RYChatAPIManager notifyWithType:NotifyTypeOnDisturbed]]) {
                //全局设置
                
                if (1 == [arg[@"isDisturbed"] intValue]) {
                    [MessageTool setDisturbed:@"YES"];
                }else {
                    [MessageTool setDisturbed:@"NO"];
                }
            }
            
            if (![[RefreshUIManager defaultManager] isPushNoReadMessage]) {
                [[NSNotificationCenter defaultCenter] postNotificationName:[MessageTool PushGlobalNotificationStr] object:arg userInfo:@{@"route":route}];
            }
            
        }];
    }
    
}

- (void)offNotify {
    [self.client offRoute:[RYChatAPIManager notifyWithType:self.notifyType]];
}

- (void)offAllNotify {
    
    [self.client offAllRoute];
}

#pragma mark APICmdApiCallBackDelegate

- (void)apiCmdDidSuccess:(RYBaseAPICmd *)baseAPICmd responseData:(id)responseData {
    
    if (baseAPICmd == self.getMembersAPICmd) {
        
        //保存用户信息
        
        NSArray *users = (NSArray *)responseData;
        
        if ([users isKindOfClass:[NSArray class]] && [users count] != 0) {
            
            NSMutableArray *tempUsers = [[NSMutableArray alloc] initWithCapacity:20];
            
            for (NSDictionary *subDict in users) {
                
                NSMutableDictionary *userDict = [[NSMutableDictionary alloc] initWithCapacity:20];
                [userDict setValue:[NSString stringWithFormat:@"%@",subDict[@"MsgGroupMemberName"]] forKey:@"PersonName"];
                [userDict setValue:[NSString stringWithFormat:@"%@",subDict[@"UserId"]] forKey:@"UserId"];
                [userDict setValue:[NSString stringWithFormat:@"%@",subDict[@"UserRole"]] forKey:@"UserRole"];
                [userDict setValue:[NSString stringWithFormat:@"%@",subDict[@"PhoneNo"]] forKey:@"PhoneNo"];
                
                [tempUsers addObject:userDict];
            }
            
            //增加userid
            [[PomeloMessageCenterDBManager shareInstance] addDataToTableWithType:MessageCenterDBManagerTypeUSER data:tempUsers];
            
        }
    }else if (baseAPICmd == self.getGroupMemberAPICmd) {
        
        NSDictionary *userDict = responseData[@"Result"];
        
        if (userDict && ![userDict isKindOfClass:[NSNull class]]) {
            
            NSMutableDictionary *tempUserDict = [[NSMutableDictionary alloc] initWithCapacity:20];
            [tempUserDict setValue:[NSString stringWithFormat:@"%@",userDict[@"MsgGroupMemberName"]] forKey:@"PersonName"];
            [tempUserDict setValue:[NSString stringWithFormat:@"%@",userDict[@"UserId"]] forKey:@"UserId"];
            [tempUserDict setValue:[NSString stringWithFormat:@"%@",userDict[@"UserRole"]] forKey:@"UserRole"];
            [tempUserDict setValue:[NSString stringWithFormat:@"%@",userDict[@"PhoneNo"]] forKey:@"PhoneNo"];
            
            //增加userid
            [[PomeloMessageCenterDBManager shareInstance] addDataToTableWithType:MessageCenterDBManagerTypeUSER data:[NSArray arrayWithObjects:tempUserDict, nil]];
        }
        
    }
    
}

- (void)apiCmdDidFailed:(RYBaseAPICmd *)baseAPICmd error:(NSError *)error {
    
}

#pragma mark private method

//单个信息处理

- (void)storeMessageWithDict:(NSDictionary *)dict {
    
    NSMutableDictionary *tempDict = [[NSMutableDictionary alloc] init];
    
    [tempDict setValue:[NSString stringWithFormat:@"%@",dict[@"_id"]]     forKey:@"MessageId"];
    [tempDict setValue:[NSString stringWithFormat:@"%@",dict[@"time"]]    forKey:@"CreateTime"];
    [tempDict setValue:[NSString stringWithFormat:@"%@",dict[@"from"]]    forKey:@"UserId"];
    
    [tempDict setValue:[NSString stringWithFormat:@"%@",dict[@"groupId"]] forKey:@"GroupId"];
    [tempDict setValue:[[NSString stringWithFormat:@"%@",dict[@"content"]] unescape] forKey:@"MsgContent"];
    [tempDict setValue:@"1"               forKey:@"Status"];
    
    [tempDict setValue:[MessageTool getUserID] forKey:@"accountId"];
    [tempDict setValue:[NSString stringWithFormat:@"%@",dict[@"clientMsgId"]] forKey:@"clientMsgId"];
    [tempDict setValue:[NSString stringWithFormat:@"%@",dict[@"type"]] forKey:@"type"];
    
    [MessageTool setLastedReadTime:[NSString stringWithFormat:@"%@",tempDict[@"CreateTime"]]];
    
    
    NSString *approveStatusStr = @"";
    
    if ([tempDict[@"type"] isEqualToString:@"101"]) {
        
        approveStatusStr = tempDict[@"MessageId"];
        [tempDict setValue:[NSString stringWithFormat:@"%@",dict[@"creditApplicationStatus"]] forKey:@"creditApplicationStatus"];
    }
    
    //存储信息
    [[PomeloMessageCenterDBManager shareInstance] addDataToTableWithType:MessageCenterDBManagerTypeMESSAGE data:[NSArray arrayWithObjects:tempDict, nil]];
    
    
    if (![[PomeloMessageCenterDBManager shareInstance] existTableWithType:MessageCenterDBManagerTypeMETADATA markID:tempDict[@"GroupId"]]) {
        
        //获取组
        
        if ([dict[@"from"] isEqualToString:[MessageTool getUserID]]) {
            
            [[PomeloMessageCenterDBManager shareInstance] addDataToTableWithType:MessageCenterDBManagerTypeMETADATA data:[NSArray arrayWithObjects:[NSDictionary dictionaryWithObjectsAndKeys:tempDict[@"GroupId"],@"GroupId",[MessageTool getUserID],@"accountId",@"0",@"UnReadMsgCount",[NSString stringWithFormat:@"%@",tempDict[@"MessageId"]],@"LastedMsgId",[NSString stringWithFormat:@"%@",tempDict[@"UserId"]],@"LastedMsgSenderName",[NSString stringWithFormat:@"%@",tempDict[@"CreateTime"]],@"LastedMsgTime",[NSString stringWithFormat:@"%@",tempDict[@"MsgContent"]],@"LastedMsgContent",approveStatusStr,@"ApproveStatus", nil], nil]];
            
        }else{
            
            //如果是YES，则为免打扰模式
            if ([[MessageTool getDisturbed] isEqualToString:@"NO"] || ![MessageTool getDisturbed] || [[MessageTool getDisturbed] isKindOfClass:[NSNull class]]) {
#if TARGET_IPHONE_SIMULATOR
                
                //模拟器
                
#elif TARGET_OS_IPHONE
                
                //真机
                //声音播放
                [LZAudioTool playMusic:@"msg.mp3"];
#endif
                
            }
            
            [[PomeloMessageCenterDBManager shareInstance] addDataToTableWithType:MessageCenterDBManagerTypeMETADATA data:[NSArray arrayWithObjects:[NSDictionary dictionaryWithObjectsAndKeys:tempDict[@"GroupId"],@"GroupId",[MessageTool getUserID],@"accountId",@"1",@"UnReadMsgCount",[NSString stringWithFormat:@"%@",tempDict[@"MessageId"]],@"LastedMsgId",[NSString stringWithFormat:@"%@",tempDict[@"UserId"]],@"LastedMsgSenderName",[NSString stringWithFormat:@"%@",tempDict[@"CreateTime"]],@"LastedMsgTime",[NSString stringWithFormat:@"%@",tempDict[@"MsgContent"]],@"LastedMsgContent",approveStatusStr,@"ApproveStatus", nil], nil]];
            
        }
        
        
        
        self.getGroupInfoChatHandler.parameters = @{@"groupId":tempDict[@"GroupId"]};
        [self.getGroupInfoChatHandler chat];
        
        //获取组成员
        self.getMembersAPICmd.path = [NSString stringWithFormat:GetMembers,tempDict[@"GroupId"]];
        [self.getMembersAPICmd loadData];
        
        
    }else {
        
        //不管对应用户在不在，都需要＋1操作，如果拿到用户信息，再反过来更新（数据库操作）
        
        if ([dict[@"from"] isEqualToString:[MessageTool getUserID]]) {
            
            [[PomeloMessageCenterDBManager shareInstance] updateGroupLastedMessageWithTableWithType:MessageCenterDBManagerTypeMETADATA SQLvalue:[NSString stringWithFormat:@"%@",tempDict[@"GroupId"]] parameters:[NSDictionary dictionaryWithObjectsAndKeys:@"UnReadMsgCount + '0'",@"UnReadMsgCount",[NSString stringWithFormat:@"%@",tempDict[@"MessageId"]],@"LastedMsgId",[NSString stringWithFormat:@"%@",tempDict[@"UserId"]],@"LastedMsgSenderName",[NSString stringWithFormat:@"%@",tempDict[@"CreateTime"]],@"LastedMsgTime",[NSString stringWithFormat:@"%@",tempDict[@"MsgContent"]],@"LastedMsgContent",approveStatusStr,@"ApproveStatus", nil]];
            
        }else{
            
            //如果是YES，则为免打扰模式
            if ([[MessageTool getDisturbed] isEqualToString:@"NO"] || ![MessageTool getDisturbed] || [[MessageTool getDisturbed] isKindOfClass:[NSNull class]]) {
#if TARGET_IPHONE_SIMULATOR
                
                //模拟器
                
#elif TARGET_OS_IPHONE
                
                //真机
                //声音播放
                [LZAudioTool playMusic:@"msg.mp3"];
#endif
                
            }
            
            
            
            [[PomeloMessageCenterDBManager shareInstance] updateGroupLastedMessageWithTableWithType:MessageCenterDBManagerTypeMETADATA SQLvalue:[NSString stringWithFormat:@"%@",tempDict[@"GroupId"]] parameters:[NSDictionary dictionaryWithObjectsAndKeys:@"UnReadMsgCount + '1'",@"UnReadMsgCount",[NSString stringWithFormat:@"%@",tempDict[@"MessageId"]],@"LastedMsgId",[NSString stringWithFormat:@"%@",tempDict[@"UserId"]],@"LastedMsgSenderName",[NSString stringWithFormat:@"%@",tempDict[@"CreateTime"]],@"LastedMsgTime",[NSString stringWithFormat:@"%@",tempDict[@"MsgContent"]],@"LastedMsgContent",approveStatusStr,@"ApproveStatus", nil]];
        }
        
        
        
        NSArray *users =  [[PomeloMessageCenterDBManager shareInstance] fetchDataInfosWithType:MessageCenterDBManagerTypeUSER conditionName:@"UserId" SQLvalue:tempDict[@"UserId"]];
        
        if (users.count == 0) {
            //获取成员
            self.getGroupMemberAPICmd.path = [NSString stringWithFormat:GetGroupMember,tempDict[@"GroupId"],tempDict[@"UserId"]];
            [self.getGroupMemberAPICmd loadData];
        }
        
        /*
         
         NSArray *users =  [[PomeloMessageCenterDBManager shareInstance] fetchDataInfosWithType:MessageCenterDBManagerTypeUSER conditionName:@"UserId" SQLvalue:tempDict[@"UserId"]];
         
         NSString *personName = @"";
         
         if (users.count != 0) {
         
         MessageCenterUserModel *userModel = (MessageCenterUserModel *)users[0];
         personName = userModel.personName;
         
         }else{
         
         //获取用户信息之后－－－－－（更新表对应personname）
         //self.getMembersAPICmd.path = [NSString stringWithFormat:GetMembers,tempDict[@"GroupId"]];
         self.getMembersAPICmd.path = [NSString stringWithFormat:GetMembers,@"4D3F8221-1CD7-44BC-80A6-C8BED5AFE904"];
         [self.getMembersAPICmd loadData];
         
         }
         
         */
        
        
    }
    
}

- (void)updateMetedateTableWithDict:(NSDictionary *)tempDict {
    
    NSArray *users =  [[PomeloMessageCenterDBManager shareInstance] fetchDataInfosWithType:MessageCenterDBManagerTypeUSER conditionName:@"UserId" SQLvalue:tempDict[@"UserId"]];
    
    if (users.count != 0) {
        
        //如果存在用户信息，则使用用户信息更新METADATA表
        MessageCenterUserModel *userModel = (MessageCenterUserModel *)users[0];
        
        [[PomeloMessageCenterDBManager shareInstance] updateGroupLastedMessageWithTableWithType:MessageCenterDBManagerTypeMETADATA SQLvalue:tempDict[@"GroupId"] parameters:[NSDictionary dictionaryWithObjectsAndKeys:tempDict[@"MessageId"],@"LastedMsgId",userModel.personName,@"LastedMsgSenderName",tempDict[@"CreateTime"],@"LastedMsgTime",tempDict[@"MsgContent"],@"LastedMsgContent", nil]];
        
    }
}

#pragma mark getters & setters

- (RYChatHandler *)findUserChatHandler {
    
    if (!_findUserChatHandler) {
        _findUserChatHandler = [[RYChatHandler alloc] initWithDelegate:[[ConnectToServer shareInstance] delegate]];
        _findUserChatHandler.chatServerType = RouteChatTypeFindUser;
    }
    return _findUserChatHandler;
}

- (RYChatHandler *)getGroupInfoChatHandler {
    if (!_getGroupInfoChatHandler) {
        _getGroupInfoChatHandler = [[RYChatHandler alloc] initWithDelegate:[[ConnectToServer shareInstance] delegate]];
        _getGroupInfoChatHandler.chatServerType = RouteChatTypeGetGroupInfo;
    }
    return _getGroupInfoChatHandler;
}

- (GetMembersAPICmd *)getMembersAPICmd {
    if (!_getMembersAPICmd) {
        _getMembersAPICmd = [[GetMembersAPICmd alloc] init];
        _getMembersAPICmd.delegate = self;
    }
    return _getMembersAPICmd;
}

- (GetGroupMemberAPICmd *)getGroupMemberAPICmd {
    if (!_getGroupMemberAPICmd) {
        _getGroupMemberAPICmd = [[GetGroupMemberAPICmd alloc] init];
        _getGroupMemberAPICmd.delegate = self;
    }
    return _getGroupMemberAPICmd;
}


@end
