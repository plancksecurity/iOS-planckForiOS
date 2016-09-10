// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Folder.h instead.

#if __has_feature(modules)
    @import Foundation;
    @import CoreData;
#else
    #import <Foundation/Foundation.h>
    #import <CoreData/CoreData.h>
#endif

#import "BaseManagedObject.h"

NS_ASSUME_NONNULL_BEGIN

@class Account;
@class Folder;
@class Message;
@class Folder;

@interface FolderID : NSManagedObjectID {}
@end

@protocol _IFolder

@property (nonatomic, strong) NSNumber* existsCount;

@property (atomic) uint64_t existsCountValue;
- (uint64_t)existsCountValue;
- (void)setExistsCountValue:(uint64_t)value_;

@property (nonatomic, strong) NSNumber* folderType;

@property (atomic) int16_t folderTypeValue;
- (int16_t)folderTypeValue;
- (void)setFolderTypeValue:(int16_t)value_;

@property (nonatomic, strong) NSString* name;

@property (nonatomic, strong) NSNumber* nextUID;

@property (atomic) uint64_t nextUIDValue;
- (uint64_t)nextUIDValue;
- (void)setNextUIDValue:(uint64_t)value_;

@property (nonatomic, strong, nullable) NSNumber* uidValidity;

@property (atomic) int64_t uidValidityValue;
- (int64_t)uidValidityValue;
- (void)setUidValidityValue:(int64_t)value_;

@property (nonatomic, strong) Account *account;

@property (nonatomic, strong, nullable) NSOrderedSet<Folder*> *children;
- (nullable NSMutableOrderedSet<Folder*>*)childrenSet;

@property (nonatomic, strong) NSSet<Message*> *messages;
- (NSMutableSet<Message*>*)messagesSet;

@property (nonatomic, strong, nullable) Folder *parent;

@end

@interface _Folder : BaseManagedObject <_IFolder>
+ (instancetype)insertInManagedObjectContext:(NSManagedObjectContext *)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
@property (nonatomic, readonly, strong) FolderID *objectID;

@property (nonatomic, strong) NSNumber* existsCount;

@property (atomic) uint64_t existsCountValue;
- (uint64_t)existsCountValue;
- (void)setExistsCountValue:(uint64_t)value_;

@property (nonatomic, strong) NSNumber* folderType;

@property (atomic) int16_t folderTypeValue;
- (int16_t)folderTypeValue;
- (void)setFolderTypeValue:(int16_t)value_;

@property (nonatomic, strong) NSString* name;

@property (nonatomic, strong) NSNumber* nextUID;

@property (atomic) uint64_t nextUIDValue;
- (uint64_t)nextUIDValue;
- (void)setNextUIDValue:(uint64_t)value_;

@property (nonatomic, strong, nullable) NSNumber* uidValidity;

@property (atomic) int64_t uidValidityValue;
- (int64_t)uidValidityValue;
- (void)setUidValidityValue:(int64_t)value_;

@property (nonatomic, strong) Account *account;

@property (nonatomic, strong, nullable) NSOrderedSet<Folder*> *children;
- (nullable NSMutableOrderedSet<Folder*>*)childrenSet;

@property (nonatomic, strong) NSSet<Message*> *messages;
- (NSMutableSet<Message*>*)messagesSet;

@property (nonatomic, strong, nullable) Folder *parent;

@end

@interface _Folder (ChildrenCoreDataGeneratedAccessors)
- (void)addChildren:(NSOrderedSet<Folder*>*)value_;
- (void)removeChildren:(NSOrderedSet<Folder*>*)value_;
- (void)addChildrenObject:(Folder*)value_;
- (void)removeChildrenObject:(Folder*)value_;

- (void)insertObject:(Folder*)value inChildrenAtIndex:(NSUInteger)idx;
- (void)removeObjectFromChildrenAtIndex:(NSUInteger)idx;
- (void)insertChildren:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeChildrenAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInChildrenAtIndex:(NSUInteger)idx withObject:(Folder*)value;
- (void)replaceChildrenAtIndexes:(NSIndexSet *)indexes withChildren:(NSArray *)values;

@end

@interface _Folder (MessagesCoreDataGeneratedAccessors)
- (void)addMessages:(NSSet<Message*>*)value_;
- (void)removeMessages:(NSSet<Message*>*)value_;
- (void)addMessagesObject:(Message*)value_;
- (void)removeMessagesObject:(Message*)value_;

@end

@interface _Folder (CoreDataGeneratedPrimitiveAccessors)

- (NSNumber*)primitiveExistsCount;
- (void)setPrimitiveExistsCount:(NSNumber*)value;

- (uint64_t)primitiveExistsCountValue;
- (void)setPrimitiveExistsCountValue:(uint64_t)value_;

- (NSNumber*)primitiveFolderType;
- (void)setPrimitiveFolderType:(NSNumber*)value;

- (int16_t)primitiveFolderTypeValue;
- (void)setPrimitiveFolderTypeValue:(int16_t)value_;

- (NSString*)primitiveName;
- (void)setPrimitiveName:(NSString*)value;

- (NSNumber*)primitiveNextUID;
- (void)setPrimitiveNextUID:(NSNumber*)value;

- (uint64_t)primitiveNextUIDValue;
- (void)setPrimitiveNextUIDValue:(uint64_t)value_;

- (NSNumber*)primitiveUidValidity;
- (void)setPrimitiveUidValidity:(NSNumber*)value;

- (int64_t)primitiveUidValidityValue;
- (void)setPrimitiveUidValidityValue:(int64_t)value_;

- (Account*)primitiveAccount;
- (void)setPrimitiveAccount:(Account*)value;

- (NSMutableOrderedSet<Folder*>*)primitiveChildren;
- (void)setPrimitiveChildren:(NSMutableOrderedSet<Folder*>*)value;

- (NSMutableSet<Message*>*)primitiveMessages;
- (void)setPrimitiveMessages:(NSMutableSet<Message*>*)value;

- (Folder*)primitiveParent;
- (void)setPrimitiveParent:(Folder*)value;

@end

@interface FolderAttributes: NSObject 
+ (NSString *)existsCount;
+ (NSString *)folderType;
+ (NSString *)name;
+ (NSString *)nextUID;
+ (NSString *)uidValidity;
@end

@interface FolderRelationships: NSObject
+ (NSString *)account;
+ (NSString *)children;
+ (NSString *)messages;
+ (NSString *)parent;
@end

NS_ASSUME_NONNULL_END
