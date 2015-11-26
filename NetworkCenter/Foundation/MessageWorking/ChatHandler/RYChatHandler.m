//
//  RYBaseChatAPI.m
//  Client
//
//  Created by wwt on 15/10/17.
//  Copyright (c) 2015年 xiaochuan. All rights reserved.
//

#import "RYChatHandler.h"
#import "RYChatAPIManager.h"
#import "CommonModel.h"
#import "MessageCenterUserModel.h"
#import "MessageCenterMessageModel.h"
#import "MessageCenterMetadataModel.h"
#import "PomeloMessageCenterDBManager.h"
#import "RYNotifyHandler.h"
#import "ConnectToServer.h"
#import "MessageTool.h"
#import "GetMembersAPICmd.h"

#define GROUP_LIST_NUMBER 20
//消息中心获取组成员(组ID 4D3F8221-1CD7-44BC-80A6-C8BED5AFE904 这个有数据)
#define GetMembers  @"api_v2/MsgGroupMemberInfo/%@/getMembers"


static RYChatHandler *shareHandler = nil;

@interface RYChatHandler () <APICmdApiCallBackDelegate>

@property (nonatomic, weak) id <RYChatHandlerDelegate> chatDelegate;


@property (nonatomic, strong) NSNumber *recordedRequestId;

//connector的host和port
@property (nonatomic, copy) NSString *hostStr;
@property (nonatomic, copy) NSString *portStr;

@property (nonatomic, strong) RYChatHandler *clientInfoChatHandler;
@property (nonatomic, strong) RYChatHandler *findUserChatHandler;
//获取组信息（如果本地数据已过期）
@property (nonatomic, strong) RYChatHandler *getGroupsHandler;
//获取组成员
@property (nonatomic, strong) GetMembersAPICmd *getMembersAPICmd;

//推送消息
//设置推送监听，并根据类型进行操作
@property (nonatomic, strong) RYNotifyHandler *onAllNotifyHandler;

@end

static RYChatHandler *shareChatHandler = nil;

@implementation RYChatHandler

/*-------------------------------------------------------------------------------*/

#pragma mark - life cycle

- (instancetype)initWithDelegate:(id)delegate {
    
    self = [super init];
    if (self) {
        _chatDelegate = delegate;
    }
    return self;
}

/*---------------------------------gate、connector、chat服务器交互------------------------------*/

#pragma mark - public methods

- (NSInteger)chat {
    
    __block RYChatHandler *weakSelf= self;;
    
    if (self.chatServerType == RouteConnectorTypeInit) {
        self.parameters = [RYChatAPIManager parametersWithType:NO];
    }
    ConnectToServer *connectToServer = [ConnectToServer shareInstance];
    
    NSNumber *chatNumber = [self generateRequestId];
    
    [connectToServer.chatClient requestWithRoute:[RYChatAPIManager routeWithType:self.chatServerType] andParams:self.parameters andCallback:^(id arg, NSString *route) {
        
        NSDictionary *connectorInitDict = (NSDictionary *)arg;
        
        
        /*
         NSMutableString *logString = [NSMutableString stringWithString:@"\n\n**************************************************************\n*                       message chat                        *\n**************************************************************\n\n"];
         [logString appendFormat:@"Route:\t\t%@\n", [RYChatAPIManager routeWithType:self.chatServerType]];
         [logString appendFormat:@"params:\t\t\n%@", weakSelf.parameters];
         [logString appendFormat:@"\n---------------------------Response---------------------------\n"];
         [logString appendFormat:@"params:\t\t\n%@", arg];
         [logString appendFormat:@"\n\n**************************************************************\n*                         message End                        *\n**************************************************************\n\n\n\n"];
         NSLog(@"%@", logString);
         
         */
        
        if ([[NSString stringWithFormat:@"%@",connectorInitDict[@"code"]] isEqualToString:[NSString stringWithFormat:@"%d",(int)ResultCodeTypeSuccess]]) {
            
            if ([route isEqualToString:[RYChatAPIManager routeWithType:RouteConnectorTypeInit]]) {
                
                if ([[NSString stringWithFormat:@"%@",connectorInitDict[@"code"]] isEqualToString:[NSString stringWithFormat:@"%d",(int)ResultCodeTypeSuccess]]) {
                    
                    NSDictionary *userInfos = connectorInitDict[@"userInfo"];
                    
                    [MessageTool setUserID:userInfos[@"userId"]];
                    [MessageTool setSessionId:connectorInitDict[@"sessionId"]];
                    [MessageTool setConnectState:@"YES"];
                    
                    //[[PomeloMessageCenterDBManager shareInstance] addDataToTableWithType:MessageCenterDBManagerTypeUSER data:[NSArray arrayWithObjects:userInfos, nil]];
                    
                    //如果有置顶信息，则设置置顶
                    if (userInfos[@"topGroupId"] && ![userInfos[@"topGroupId"] isKindOfClass:[NSNull class]] && [userInfos[@"topGroupId"] length] != 0) {
                        
                        [MessageTool setTopGroupId:userInfos[@"topGroupId"]];
                        [[PomeloMessageCenterDBManager shareInstance] markTopTableWithType:MessageCenterDBManagerTypeMETADATA SQLvalue:userInfos[@"topGroupId"]];
                        
                    }
                    
                    //连接服务器成功之后提交App Client信息
                    [weakSelf.clientInfoChatHandler chat];
                    
                    if (0 == [connectorInitDict[@"clientCacheExprired"] intValue]) {
                        
                        [MessageTool setClientCacheExprired:@"NO"];
                        
                    }else {
                        
                        //如果是已过期的状态，需要删除本地缓存
                        [MessageTool setClientCacheExprired:@"YES"];
                        [[PomeloMessageCenterDBManager shareInstance] clearLocalDBData];
                        
                        //全部组，包括未读已读
                        [weakSelf.getGroupsHandler chat];
                        
                    }
                    
                    //连接服务器成功之后注册所有通知
                    [weakSelf.onAllNotifyHandler onAllNotify];
                }
                
            }else if ([route isEqualToString:[RYChatAPIManager routeWithType:RouteChatTypeWriteClientInfo]]) {
                
                if ([[NSString stringWithFormat:@"%@",connectorInitDict[@"code"]] isEqualToString:[NSString stringWithFormat:@"%d",(int)ResultCodeTypeSuccess]]) {
                    
                    NSLog(@"WriteClientInfo －－ 发送客户信息成功");
                }
                
            } else if ([route isEqualToString:[RYChatAPIManager routeWithType:RouteChatTypeGetGroupInfo]]) {
                //获取组和组成员信息
                
                if ([[NSString stringWithFormat:@"%@",connectorInitDict[@"code"]] isEqualToString:[NSString stringWithFormat:@"%d",(int)ResultCodeTypeSuccess]]) {
                    
                    //如果获取组和组成员成功，更新MsgMetadata表
                    
                    NSDictionary *tempDict = (NSDictionary *)connectorInitDict[@"groupInfo"];
                    [weakSelf storeGroupInfoWithDict:tempDict];
                    
                    /*
                     if (![[PomeloMessageCenterDBManager shareInstance] existTableWithType:MessageCenterDBManagerTypeMETADATA markID:groupInfo[@"GroupId"]]) {
                     
                     //赋初值
                     [groupInfo setValue:@"1" forKey:@"UnReadMsgCount"];
                     
                     [[PomeloMessageCenterDBManager shareInstance] addDataToTableWithType:MessageCenterDBManagerTypeMETADATA data:[NSArray arrayWithObjects:groupInfo, nil]];
                     
                     }else{
                     
                     //如果是－1，数据库则不更新
                     [groupInfo setValue:@"-1" forKey:@"UnReadMsgCount"];
                     
                     [[PomeloMessageCenterDBManager shareInstance] updateGroupLastedMessageWithTableWithType:MessageCenterDBManagerTypeMETADATA SQLvalue:tempDict[@"groupId"] parameters:groupInfo];
                     
                     }
                     
                     if (tempDict[@"users"] && ![tempDict[@"users"] isKindOfClass:[NSNull class]]) {
                     
                     NSArray *usersArr= tempDict[@"users"];
                     
                     
                     
                     //根据userid获取用户数据（暂时先不用存）
                     //                            [[PomeloMessageCenterDBManager shareInstance] addDataToTableWithType:MessageCenterDBManagerTypeUSER data:tempDict[@"users"]];
                     
                     }
                     */
                    
                }
                
            }else if ([route isEqualToString:[RYChatAPIManager routeWithType:RouteChatTypeRead]]) {
                //设置已读
                
                if ([[NSString stringWithFormat:@"%@",connectorInitDict[@"code"]] isEqualToString:[NSString stringWithFormat:@"%d",(int)ResultCodeTypeSuccess]]) {
                    
                    //成功之后更新组MsgMetadata表中的统计字段清0
                    
                    [[PomeloMessageCenterDBManager shareInstance] markReadTableWithType:MessageCenterDBManagerTypeMETADATA SQLvalue:weakSelf.parameters[@"groupId"] parameters:[NSDictionary dictionaryWithObjectsAndKeys:weakSelf.parameters[@"lastedReadMsgId"],@"LastedReadMsgId",weakSelf.parameters[@"time"],@"LastedReadTime",@"0",@"UnReadMsgCount",nil]];
                    
                }
                
            }else if ([route isEqualToString:[RYChatAPIManager routeWithType:RouteChatTypeGetMsg]]) {
                //如果是已过期状态，需要重新获取单个组消息列表
                
                if ([[NSString stringWithFormat:@"%@",connectorInitDict[@"code"]] isEqualToString:[NSString stringWithFormat:@"%d",(int)ResultCodeTypeSuccess]]) {
                    
                    NSMutableDictionary *tempDict = [[NSMutableDictionary alloc] initWithDictionary:arg];
                    NSArray *msgs = tempDict[@"msgs"];
                    for (NSDictionary *subDict in msgs) {
                        [weakSelf storeMessageWithDict:subDict];
                    }
                    
                }
                
            }else if ([route isEqualToString:[RYChatAPIManager routeWithType:RouteChatTypeGetGroups]]) {
                //如果是已过期状态，需要获取组列表
                
                if ([[NSString stringWithFormat:@"%@",connectorInitDict[@"code"]] isEqualToString:[NSString stringWithFormat:@"%d",(int)ResultCodeTypeSuccess]]) {
                    
                    NSMutableDictionary *tempDict = [[NSMutableDictionary alloc] initWithDictionary:arg];
                    
                    
                    
                    if (tempDict[@"groups"] && ![tempDict[@"groups"] isKindOfClass:[NSNull class]]) {
                        
                        NSArray *groups = tempDict[@"groups"];
                        
                        [weakSelf storeGroupInfoWithArr:groups];
                    }
                }
                
            }
            
            if ([weakSelf.chatDelegate respondsToSelector:@selector(connectToChatSuccess:result:requestId:)]) {
                [weakSelf.chatDelegate connectToChatSuccess:weakSelf result:connectorInitDict requestId:chatNumber.integerValue];
            }else{
                NSAssert(0,@"connectToChatSuccess:result:-方法必须实现");
            }
            
        }else{
            
            if ([weakSelf.chatDelegate respondsToSelector:@selector(connectToChatFailure:result:requestId:)]) {
                [weakSelf.chatDelegate connectToChatFailure:weakSelf result:connectorInitDict requestId:chatNumber.integerValue];
            }else{
                NSAssert(0,@"connectToChatFailure:result:-方法必须实现");
            }
        }
        
    }];
    return chatNumber.integerValue;
}

#pragma mark - APICmdApiCallBackDelegate

- (void)apiCmdDidSuccess:(RYBaseAPICmd *)baseAPICmd responseData:(id)responseData {
    
    if ([baseAPICmd isKindOfClass:[GetMembersAPICmd class]]) {
        
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
    }
    
}

- (void)apiCmdDidFailed:(RYBaseAPICmd *)baseAPICmd error:(NSError *)error {
    
}

//组消息存储(多个组)
- (void)storeGroupInfoWithArr:(NSArray *)groups {
    
    NSMutableArray *tempGroups = [[NSMutableArray alloc] initWithCapacity:20];
    
    for (int i = 0; i < groups.count; i ++) {
        
        NSDictionary *tempDict = groups[i];
        
        NSMutableDictionary *groupInfo = [[NSMutableDictionary alloc] init];
        
        [groupInfo setValue:[NSString stringWithFormat:@"%@",tempDict[@"createTime"]] forKey:@"CreateTime"];
        [groupInfo setValue:[NSString stringWithFormat:@"%@",tempDict[@"companyName"]] forKey:@"CompanyName"];
        [groupInfo setValue:[NSString stringWithFormat:@"%@",tempDict[@"groupName"]] forKey:@"GroupName"];
        [groupInfo setValue:[NSString stringWithFormat:@"%@",tempDict[@"groupType"]] forKey:@"GroupType"];
        [groupInfo setValue:[MessageTool getUserID] forKey:@"AccountId"];
        [groupInfo setValue:[NSString stringWithFormat:@"%@",tempDict[@"groupId"]] forKey:@"GroupId"];
        
        if (tempDict[@"lastedMsg"] && ![tempDict[@"lastedMsg"] isKindOfClass:[NSNull class]]) {
            
            [groupInfo setValue:[NSString stringWithFormat:@"%@",tempDict[@"lastedMsg"][@"msgId"]] forKey:@"LastedMsgId"];
            [groupInfo setValue:[NSString stringWithFormat:@"%@",tempDict[@"lastedMsg"][@"sender"]] forKey:@"LastedMsgSenderName"];
            
            if (tempDict[@"lastedMsg"][@"time"]) {
                
                [groupInfo setValue:[NSString stringWithFormat:@"%@",tempDict[@"lastedMsg"][@"time"]] forKey:@"LastedMsgTime"];
                
            }else{
                
                [groupInfo setValue:[NSString stringWithFormat:@"%@",tempDict[@"createTime"]] forKey:@"LastedMsgTime"];
                
            }
            
            
            [groupInfo setValue:[NSString stringWithFormat:@"%@",tempDict[@"lastedMsg"][@"content"]] forKey:@"LastedMsgContent"];
            
        }else{
            
            [groupInfo setValue:[NSString stringWithFormat:@"%@",tempDict[@"createTime"]] forKey:@"LastedMsgTime"];
            
        }
        
        [groupInfo setValue:[NSString stringWithFormat:@"%@",tempDict[@"unReadMsgCount"]] forKey:@"UnReadMsgCount"];
        
        [tempGroups addObject:groupInfo];
        
        //获取组成员信息
        self.getMembersAPICmd.path = [NSString stringWithFormat:GetMembers,groupInfo[@"GroupId"]];
        [self.getMembersAPICmd loadData];
        
    }
    
    [[PomeloMessageCenterDBManager shareInstance] addDataToTableWithType:MessageCenterDBManagerTypeMETADATA data:tempGroups];
    
}

//组消息存储(单个组)
- (void)storeGroupInfoWithDict:(NSDictionary *)tempDict {
    
    NSMutableDictionary *groupInfo = [[NSMutableDictionary alloc] init];
    
    [groupInfo setValue:[NSString stringWithFormat:@"%@",tempDict[@"createTime"]] forKey:@"CreateTime"];
    [groupInfo setValue:[NSString stringWithFormat:@"%@",tempDict[@"companyName"]] forKey:@"CompanyName"];
    [groupInfo setValue:[NSString stringWithFormat:@"%@",tempDict[@"groupName"]] forKey:@"GroupName"];
    [groupInfo setValue:[NSString stringWithFormat:@"%@",tempDict[@"groupType"]] forKey:@"GroupType"];
    [groupInfo setValue:[MessageTool getUserID] forKey:@"AccountId"];
    [groupInfo setValue:[NSString stringWithFormat:@"%@",tempDict[@"groupId"]] forKey:@"GroupId"];
    
    if (tempDict[@"lastedMsg"] && ![tempDict[@"lastedMsg"] isKindOfClass:[NSNull class]]) {
        
        
        
        [groupInfo setValue:[NSString stringWithFormat:@"%@",tempDict[@"lastedMsg"][@"msgId"]] forKey:@"LastedMsgId"];
        [groupInfo setValue:[NSString stringWithFormat:@"%@",tempDict[@"lastedMsg"][@"sender"]] forKey:@"LastedMsgSenderName"];
        
        if (tempDict[@"lastedMsg"][@"time"]) {
            [groupInfo setValue:[NSString stringWithFormat:@"%@",tempDict[@"lastedMsg"][@"time"]] forKey:@"LastedMsgTime"];
        }else{
            [groupInfo setValue:[NSString stringWithFormat:@"%@",tempDict[@"createTime"]] forKey:@"LastedMsgTime"];
        }
        
        
        [groupInfo setValue:[NSString stringWithFormat:@"%@",tempDict[@"lastedMsg"][@"content"]] forKey:@"LastedMsgContent"];
        
    }else{
        
        [groupInfo setValue:[NSString stringWithFormat:@"%@",tempDict[@"createTime"]] forKey:@"LastedMsgTime"];
        
    }
    
    //赋初值
    [groupInfo setValue:@"-1" forKey:@"UnReadMsgCount"];
    
    [[PomeloMessageCenterDBManager shareInstance] addDataToTableWithType:MessageCenterDBManagerTypeMETADATA data:[NSArray arrayWithObjects:groupInfo, nil]];
    
}

//单个信息处理

- (void)storeMessageWithDict:(NSDictionary *)dict {
    
    NSMutableDictionary *tempDict = [[NSMutableDictionary alloc] init];
    
    [tempDict setValue:[NSString stringWithFormat:@"%@",dict[@"_id"]]     forKey:@"MessageId"];
    [tempDict setValue:[NSString stringWithFormat:@"%@",dict[@"time"]]    forKey:@"CreateTime"];
    [tempDict setValue:[NSString stringWithFormat:@"%@",dict[@"from"]]    forKey:@"UserId"];
    
    [tempDict setValue:[NSString stringWithFormat:@"%@",dict[@"groupId"]] forKey:@"GroupId"];
    [tempDict setValue:[NSString stringWithFormat:@"%@",dict[@"content"]] forKey:@"MsgContent"];
    [tempDict setValue:@"1"               forKey:@"Status"];
    
    [tempDict setValue:[MessageTool getUserID] forKey:@"accountId"];
    [tempDict setValue:[NSString stringWithFormat:@"%@",dict[@"clientMsgId"]] forKey:@"clientMsgId"];
    [tempDict setValue:[NSString stringWithFormat:@"%@",dict[@"type"]] forKey:@"type"];
    
    if ([tempDict[@"type"] isEqualToString:@"101"]) {
        
        [tempDict setValue:[NSString stringWithFormat:@"%@",dict[@"creditApplicationStatus"]] forKey:@"creditApplicationStatus"];
    }
    
    //存储信息
    [[PomeloMessageCenterDBManager shareInstance] addDataToTableWithType:MessageCenterDBManagerTypeMESSAGE data:[NSArray arrayWithObjects:tempDict, nil]];
    
}

#pragma mark - inner Method

/**
 *   @author xiaerfei, 15-10-30 17:10:04
 *
 *   发送数据 生成的requestId
 *
 *   @return
 */
- (NSNumber *)generateRequestId
{
    if (_recordedRequestId == nil) {
        _recordedRequestId = @(1);
    } else {
        if ([_recordedRequestId integerValue] == NSIntegerMax) {
            _recordedRequestId = @(1);
        } else {
            _recordedRequestId = @([_recordedRequestId integerValue] + 1);
        }
    }
    return _recordedRequestId;
}

#pragma mark - getters and setters

- (RYChatHandler *)clientInfoChatHandler {
    if (!_clientInfoChatHandler) {
        _clientInfoChatHandler = [[RYChatHandler alloc] initWithDelegate:[[ConnectToServer shareInstance] delegate]];
        _clientInfoChatHandler.chatServerType = RouteChatTypeWriteClientInfo;
        _clientInfoChatHandler.parameters = @{@"appClientId":@"1219041c8c3b9bdff326f0f3e3615930",
                                              @"deviceToken":@"f4a52dbda1af30249c27421214468d24bfdacbea16298f4cd2da35a3929daad5"};
    }
    return _clientInfoChatHandler;
}

- (RYChatHandler *)findUserChatHandler {
    
    if (!_findUserChatHandler) {
        _findUserChatHandler = [[RYChatHandler alloc] initWithDelegate:[[ConnectToServer shareInstance] delegate]];
        _findUserChatHandler.chatServerType = RouteChatTypeFindUser;
    }
    return _findUserChatHandler;
}


//推送消息
- (RYNotifyHandler *)onAllNotifyHandler {
    if (!_onAllNotifyHandler) {
        _onAllNotifyHandler = [[RYNotifyHandler alloc] init];
    }
    return _onAllNotifyHandler;
}

- (RYChatHandler *)getGroupsHandler {
    if (!_getGroupsHandler) {
        _getGroupsHandler = [[RYChatHandler alloc] initWithDelegate:[[ConnectToServer shareInstance] delegate]];
        _getGroupsHandler.chatServerType = RouteChatTypeGetGroups;
        _getGroupsHandler.parameters = @{@"skipCount":[NSNumber numberWithInteger:0],@"readType":@"0",@"count":[NSNumber numberWithInteger:GROUP_LIST_NUMBER]};
    }
    return _getGroupsHandler;
}

- (GetMembersAPICmd *)getMembersAPICmd {
    if (!_getMembersAPICmd) {
        _getMembersAPICmd = [[GetMembersAPICmd alloc] init];
        _getMembersAPICmd.delegate = self;
    }
    return _getMembersAPICmd;
}


@end
