// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Contact.h instead.

#if __has_feature(modules)
    @import Foundation;
    @import CoreData;
#else
    #import <Foundation/Foundation.h>
    #import <CoreData/CoreData.h>
#endif

#import "BaseManagedObject.h"

NS_ASSUME_NONNULL_BEGIN

@class Message;
@class Message;
@class Message;
@class Message;

@interface ContactID : NSManagedObjectID {}
@end

@protocol _IContact

@property (nonatomic, strong, nullable) NSNumber* addressBookID;

@property (atomic) int32_t addressBookIDValue;
- (int32_t)addressBookIDValue;
- (void)setAddressBookIDValue:(int32_t)value_;

@property (nonatomic, strong) NSString* email;

@property (nonatomic, strong) NSNumber* isMySelf;

@property (atomic) BOOL isMySelfValue;
- (BOOL)isMySelfValue;
- (void)setIsMySelfValue:(BOOL)value_;

@property (nonatomic, strong, nullable) NSString* name;

@property (nonatomic, strong, nullable) NSString* pepUserID;

@property (nonatomic, strong, nullable) NSSet<Message*> *bccMessages;
- (nullable NSMutableSet<Message*>*)bccMessagesSet;

@property (nonatomic, strong, nullable) NSSet<Message*> *ccMessages;
- (nullable NSMutableSet<Message*>*)ccMessagesSet;

@property (nonatomic, strong, nullable) NSSet<Message*> *fromMessages;
- (nullable NSMutableSet<Message*>*)fromMessagesSet;

@property (nonatomic, strong, nullable) NSSet<Message*> *toMessages;
- (nullable NSMutableSet<Message*>*)toMessagesSet;

@end

@interface _Contact : BaseManagedObject <_IContact>
+ (instancetype)insertInManagedObjectContext:(NSManagedObjectContext *)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
@property (nonatomic, readonly, strong) ContactID *objectID;

@property (nonatomic, strong, nullable) NSNumber* addressBookID;

@property (atomic) int32_t addressBookIDValue;
- (int32_t)addressBookIDValue;
- (void)setAddressBookIDValue:(int32_t)value_;

@property (nonatomic, strong) NSString* email;

@property (nonatomic, strong) NSNumber* isMySelf;

@property (atomic) BOOL isMySelfValue;
- (BOOL)isMySelfValue;
- (void)setIsMySelfValue:(BOOL)value_;

@property (nonatomic, strong, nullable) NSString* name;

@property (nonatomic, strong, nullable) NSString* pepUserID;

@property (nonatomic, strong, nullable) NSSet<Message*> *bccMessages;
- (nullable NSMutableSet<Message*>*)bccMessagesSet;

@property (nonatomic, strong, nullable) NSSet<Message*> *ccMessages;
- (nullable NSMutableSet<Message*>*)ccMessagesSet;

@property (nonatomic, strong, nullable) NSSet<Message*> *fromMessages;
- (nullable NSMutableSet<Message*>*)fromMessagesSet;

@property (nonatomic, strong, nullable) NSSet<Message*> *toMessages;
- (nullable NSMutableSet<Message*>*)toMessagesSet;

@end

@interface _Contact (BccMessagesCoreDataGeneratedAccessors)
- (void)addBccMessages:(NSSet<Message*>*)value_;
- (void)removeBccMessages:(NSSet<Message*>*)value_;
- (void)addBccMessagesObject:(Message*)value_;
- (void)removeBccMessagesObject:(Message*)value_;

@end

@interface _Contact (CcMessagesCoreDataGeneratedAccessors)
- (void)addCcMessages:(NSSet<Message*>*)value_;
- (void)removeCcMessages:(NSSet<Message*>*)value_;
- (void)addCcMessagesObject:(Message*)value_;
- (void)removeCcMessagesObject:(Message*)value_;

@end

@interface _Contact (FromMessagesCoreDataGeneratedAccessors)
- (void)addFromMessages:(NSSet<Message*>*)value_;
- (void)removeFromMessages:(NSSet<Message*>*)value_;
- (void)addFromMessagesObject:(Message*)value_;
- (void)removeFromMessagesObject:(Message*)value_;

@end

@interface _Contact (ToMessagesCoreDataGeneratedAccessors)
- (void)addToMessages:(NSSet<Message*>*)value_;
- (void)removeToMessages:(NSSet<Message*>*)value_;
- (void)addToMessagesObject:(Message*)value_;
- (void)removeToMessagesObject:(Message*)value_;

@end

@interface _Contact (CoreDataGeneratedPrimitiveAccessors)

- (NSNumber*)primitiveAddressBookID;
- (void)setPrimitiveAddressBookID:(NSNumber*)value;

- (int32_t)primitiveAddressBookIDValue;
- (void)setPrimitiveAddressBookIDValue:(int32_t)value_;

- (NSString*)primitiveEmail;
- (void)setPrimitiveEmail:(NSString*)value;

- (NSNumber*)primitiveIsMySelf;
- (void)setPrimitiveIsMySelf:(NSNumber*)value;

- (BOOL)primitiveIsMySelfValue;
- (void)setPrimitiveIsMySelfValue:(BOOL)value_;

- (NSString*)primitiveName;
- (void)setPrimitiveName:(NSString*)value;

- (NSString*)primitivePepUserID;
- (void)setPrimitivePepUserID:(NSString*)value;

- (NSMutableSet<Message*>*)primitiveBccMessages;
- (void)setPrimitiveBccMessages:(NSMutableSet<Message*>*)value;

- (NSMutableSet<Message*>*)primitiveCcMessages;
- (void)setPrimitiveCcMessages:(NSMutableSet<Message*>*)value;

- (NSMutableSet<Message*>*)primitiveFromMessages;
- (void)setPrimitiveFromMessages:(NSMutableSet<Message*>*)value;

- (NSMutableSet<Message*>*)primitiveToMessages;
- (void)setPrimitiveToMessages:(NSMutableSet<Message*>*)value;

@end

@interface ContactAttributes: NSObject 
+ (NSString *)addressBookID;
+ (NSString *)email;
+ (NSString *)isMySelf;
+ (NSString *)name;
+ (NSString *)pepUserID;
@end

@interface ContactRelationships: NSObject
+ (NSString *)bccMessages;
+ (NSString *)ccMessages;
+ (NSString *)fromMessages;
+ (NSString *)toMessages;
@end

NS_ASSUME_NONNULL_END
