//
//  PomeloDBRecord.h
//  Client
//
//  Created by wwt on 15/10/20.
//  Copyright (c) 2015年 xiaochuan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RYChatAPIManager.h"

@class MessageCenterMessageModel;

/*
 
 聊天本地处理过程：
 1、在组列表界面接受服务器推送通知（onGroupMsgList），更新列表（列表数据推送延迟，如果此时有新的聊天，无论是组还是单对单聊天（其实都是组），都需要在原本列表中添加新的聊天（即新的组更新Metadata表中数据，包括组名字、头像、等等，同时更新UserMessage表））
 2、根据推送过来的组ID获取有关组和组员信息（getGroupInfo），同时更新消息列表UserMessage和消息表Metadata，获取组员信息之后更新User表
 3、消息组内消息显示时，需要关联消息列表UserMessage和用户信息表User，获取每条信息对应的信息
 4、本地存储收到最后消息的信息，当取得列表时获取的信息ID比记录的本地最后消息‘新’，说明有新的消息（作用之一是列表中显示未读消息），当读取消息之后需要设置消息已读，将最后读取消息ID上传服务器
 5、单对单相当于组，在向单个用户发送消息前，需要获取发送消息的组，然后获取组信息（同1）
 6、置顶、消息免打扰相对简单
 
 */


/**
 *  表类型
 */
typedef NS_ENUM(NSInteger, MessageCenterDBManagerType){
    //用户表
    MessageCenterDBManagerTypeUSER = 0,
    //消息表
    MessageCenterDBManagerTypeMESSAGE  = 1,
    //消息Metadata(MsgMetadata)
    MessageCenterDBManagerTypeMETADATA = 2
};



//消息中心数据库操作

@interface PomeloMessageCenterDBManager : NSObject

/**
 *  需要操作的表类型
 */
@property (nonatomic, assign) NSInteger tableType;

/**
 *  如果是读取，则需要说明读取条数
 */

@property (nonatomic, assign) NSInteger numbers;

+ (instancetype)shareInstance;

/*---------------------------------数据库交互-------------------------------*/

- (void)addHistoryMessageToTableWithType:(MessageCenterDBManagerType)tableType data:(NSArray *)datas;

/**
 *  发送消息（本地发送消息，首先保存数据库，如果发送成功，则更新）
 *
 *  @param tableType MessageCenterDBManagerType表类型
 *  @param datas     数据组
 */

- (void)addNoSendMessageToTableWithType:(MessageCenterDBManagerType)tableType data:(NSArray *)datas;

/**
 *
 *  根据不同的表类型向表中添加数据
 *
 */
- (void)addDataToTableWithType:(MessageCenterDBManagerType)tableType data:(NSArray *)datas;

//进入某个群之后，如果缓存没有或者已经展示完缓存数据，则从服务器请求更多记录并记录在本地，如果没有，不再做请求
//如果是用户列表和组列表，则全部取出，如果是信息列表，则要根据GroupId查询所在组的消息列表，在此基础上按UserId取出用户信息

/**
 *
 *  根据不同的表类型获取表中信息,如果 pageNumber == -1 表示要取表中所有数据，否则读取指定个数(存在分页)
 *
 *  @param tableType      MessageCenterDBManagerType表类型
 *  @param conditionName  conditionName sql字段
 *  @param SQLvalue       需要拼合的sql字段
 *  @param startPos       从第几条开始取数据
 *  @param number         取多少条数据
 */

- (NSArray *)fetchDataInfosWithType:(MessageCenterDBManagerType)tableType conditionName:(NSString *)conditionName SQLvalue:(NSString *)SQLvalue messageModel:(MessageCenterMessageModel *)messageModel number:(NSInteger)number;

/**
 *
 *  根据不同的表类型获取表中信息(无分页)
 *
 *  @param tableType MessageCenterDBManagerType表类型
 *  @param conditionName  conditionName sql字段
 *  @param SQLvalue   需要拼合的sql字段
 */

- (NSArray *)fetchDataInfosWithType:(MessageCenterDBManagerType)tableType conditionName:(NSString *)conditionName SQLvalue:(NSString *)SQLvalue;

/**
 *
 *  更新数据（实际：如果表中有此数据则更新即可，否则添加到表中）
 *
 */

//- (void)updateTableWithType:(MessageCenterDBManagerType)tableType value:(NSString *)value data:(NSArray *)datas;


/**
 *  设置消息置顶
 *
 *  @param tableType MessageCenterDBManagerType表类型
 *  @param SQLvalue  SQLvalue需要拼合的sql字段
 */

- (void)markTopTableWithType:(MessageCenterDBManagerType)tableType SQLvalue:(NSString *)SQLvalue;

/**
 *  设置已读
 *
 *  @param tableType  MessageCenterDBManagerType表类型
 *  @param SQLvalue   SQLvalue需要拼合的sql字段
 *  @param parameters 所需要更新的参数列表
 */

- (void)markReadTableWithType:(MessageCenterDBManagerType)tableType SQLvalue:(NSString *)SQLvalue parameters:(NSDictionary *)parameters;

/**
 *  设置组最新消息信息和未读消息个数
 *
 *  @param tableType  MessageCenterDBManagerType表类型
 *  @param SQLvalue   SQLvalue需要拼合的sql字段
 *  @param parameters 所需要更新的参数列表
 */

- (void)updateGroupLastedMessageWithTableWithType:(MessageCenterDBManagerType)tableType SQLvalue:(NSString *)SQLvalue parameters:(NSDictionary *)parameters;

/**
 *  根据不同类型获取组列表（列表类型0:全部组;1:未读组;2:已读组）
 *
 *  @param readType ReadTypeName
 */

- (NSArray *)fetchGroupsWithGroupReadType:(GroupReadType)readType currentPage:(NSInteger)currentPage isNeedAllData:(BOOL)isNeedAllData;

/**
 *  简单组列表删除
 *
 *  @param tableType MessageCenterDBManagerType表类型
 *  @param SQLvalue  SQLvalue需要拼合的sql字段
 */

- (void)deleteDataWithTableWithType:(MessageCenterDBManagerType)tableType SQLvalue:(NSString *)SQLvalue;

/**
 *  组列表删除,附带返回删除后的数组
 *
 *  @param tableType MessageCenterDBManagerType表类型
 *  @param SQLvalue  SQLvalue需要拼合的sql字段
 */

- (NSArray *)deleteDataWithTableWithType:(MessageCenterDBManagerType)tableType groupReadType:(GroupReadType)readType SQLvalue:(NSString *)SQLvalue currentPage:(NSInteger)currentPage isNeedAllData:(BOOL)isNeedAllData;

/**
 *
 *  清除本地缓存
 *
 */

- (void)clearLocalDBData;

/**
 *
 *  推送历史消息时,最后拿取组信息
 *
 */

- (void)loadDataWhenPushHistoryMessage;

/**
 *  判断数据库中是否存在指定ID的数据
 *
 *  @param tableType 表类型
 *  @param markID    userid或者MessageId或者groupid
 *
 *  @return BOOL
 *
 */
- (BOOL)existTableWithType:(MessageCenterDBManagerType)tableType markID:(NSString *)markID;

/*---------------------------------本地存储简化对外接口-------------------------------*/

//存储用户信息   --- 对应User表操作
- (void)storeUserInfoWithDatas:(NSArray *)userDatas;
//存储消息      ---  对应message表
- (void)storeMessageInfoWithDatas:(NSArray *)messageDatas;
//消息Metadata --- 对应Metadata表
- (void)storeMetaDataWithDatas:(NSArray *)metaDatas;

@end
