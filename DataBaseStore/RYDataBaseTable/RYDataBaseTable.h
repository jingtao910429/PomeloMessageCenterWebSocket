//
//  RYDataBaseTable.h
//  RYDataBaseStore
//
//  Created by xiaerfei on 15/11/8.
//  Copyright © 2015年 geren. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RYDataBaseCriteria;

@protocol RYDataBaseTableProtocol <NSObject>

@required
/**
 *  return the name of databse file, RYDataBaseTableProtocol will create CTDatabase by this string.
 *
 *  @return return the name of database file
 */
- (NSString *)databaseName;

/**
 *  the name of your table
 *
 *  @return return the name of your table
 */
- (NSString *)tableName;

/**
 *  column info with this table. If table not exists in database, RYDataBaseTable will create a table based on the column info you provided
 *
 *  @return return the column info of your table
 */
- (NSDictionary *)columnInfo;

@optional

- (Class)recordClass;

@end



@interface RYDataBaseTable : NSObject

@property (nonatomic, weak, readonly) RYDataBaseTable <RYDataBaseTableProtocol> *child;

@property (nonatomic, copy, readonly) NSString *dbPath;

@property (nonatomic, copy) NSMutableString *sqlString;

/**
 *   @author xiaerfei, 15-11-24 20:11:04
 *
 *   insert data
 *
 *   @param tableName tableName
 *   @param dataList  dataList
 *
 *   @return is failed
 */
- (BOOL)insertDataList:(NSArray *)dataList;
/**
 *   @author xiaerfei, 15-11-24 20:11:00
 *
 *   insert data of Class
 *
 *   @param tableName     tableName
 *   @param dataClassList dataClassList
 *
 *   @return is failed
 */
- (BOOL)insertDataClassList:(NSArray *)dataClassList;
/**
 *   @author xiaerfei, 15-11-24 20:11:01
 *
 *   update data
 *
 *   @param tableName      tableName
 *   @param keyValueList   keyValueList
 *   @param conditionParam update param
 *
 *   @return is failed
 */
- (BOOL)updateKeyValueList:(NSDictionary *)keyValueList whereConditionParam:(NSDictionary *)conditionParam;
/**
 *   @author xiaerfei, 15-11-24 20:11:36
 *
 *   update data Class
 *
 *   @param tableName      tableName
 *   @param dataClass      dataClass
 *   @param conditionParam update param
 *   @param shouldOverride is override data
 *
 *   @return is failed
 */
- (BOOL)updateDataClass:(id)dataClass whereConditionParam:(NSDictionary *)conditionParam shouldOverride:(BOOL)shouldOverride;
/**
 *   @author xiaerfei, 15-11-24 20:11:52
 *
 *   update data array
 *
 *   @param tableName      tableName
 *   @param dataClassList  dataClassList
 *   @param conditionParam update param
 *   @param shouldOverride is override data
 */
- (void)updateDataClassList:(NSArray *)dataClassList whereConditionParam:(NSDictionary *)conditionParam shouldOverride:(BOOL)shouldOverride;
/**
 *   @author xiaerfei, 15-11-24 20:11:39
 *
 *   update data common
 *
 *   @param tableName      tableName
 *   @param keyValueList   keyValueList
 *   @param condition      condition
 *   @param conditionParam conditionParam
 *
 *   @return is failed
 */
- (BOOL)updateKeyValueList:(NSDictionary *)keyValueList whereCondition:(NSString *)condition conditionParam:(NSDictionary *)conditionParam;
/**
 *   @author xiaerfei, 15-11-25 09:11:13
 *
 *   record count of record list with matches where condition
 *
 *   @param sqlString SQL
 *   @param params    where condition params
 *
 *   @return a dictionary which contains count column.
 */
- (NSDictionary *)countWithSQL:(NSString *)sqlString params:(NSDictionary *)params;
/**
 *   @author xiaerfei, 15-11-25 09:11:31
 *
 *   record count of record list with matches where condition
 *
 *   @return total record count in this table
 */
- (NSNumber *)countTotalRecord;
/**
 *   @author xiaerfei, 15-11-25 09:11:27
 *
 *   record count of record list with matches where condition
 *
 *   @param whereCondition  whereCondition
 *   @param conditionParams conditionParams
 *
 *   @return record count of record list with matches where condition
 */
- (NSNumber *)countWithWhereCondition:(NSString *)whereCondition conditionParams:(NSDictionary *)conditionParams;


/**
 *   @author xiaerfei, 15-11-25 14:11:36
 *
 *   fetch all data with where condition
 *
 *   @param condition               condition
 *   @param conditionParams         conditionParams
 *   @param isDistinct              isDistinct
 *   @param isTransformItemsToClass is transform items to class
 *
 *   @return fetch data list
 */
- (NSArray *)fetchDataWithWhereCondition:(NSString *)condition conditionParams:(NSDictionary *)conditionParams isDistinct:(BOOL)isDistinct isTransformItemsToClass:(BOOL)isTransformItemsToClass;
/**
 *   @author xiaerfei, 15-11-25 14:11:57
 *
 *   more fine search condition
 *
 *   @param criteria                criteria
 *   @param isTransformItemsToClass is transform items to class
 *
 *   @return fetch data list
 */
- (NSArray *)fetchAllWithCriteria:(RYDataBaseCriteria *)criteria isTransformItemsToClass:(BOOL)isTransformItemsToClass;
/**
 *   @author xiaerfei, 15-11-25 15:11:41
 *
 *   close DataBase
 */
- (void)closeDataBase;


@end
