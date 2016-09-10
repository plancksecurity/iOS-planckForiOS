// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to MessageReference.h instead.

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

@interface MessageReferenceID : NSManagedObjectID {}
@end

@protocol _IMessageReference

@property (nonatomic, strong) NSString* messageID;

@property (nonatomic, strong, nullable) Message *message;

@property (nonatomic, strong, nullable) NSSet<Message*> *referencingMessages;
- (nullable NSMutableSet<Message*>*)referencingMessagesSet;

@end

@interface _MessageReference : BaseManagedObject <_IMessageReference>
+ (instancetype)insertInManagedObjectContext:(NSManagedObjectContext *)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
@property (nonatomic, readonly, strong) MessageReferenceID *objectID;

@property (nonatomic, strong) NSString* messageID;

@property (nonatomic, strong, nullable) Message *message;

@property (nonatomic, strong, nullable) NSSet<Message*> *referencingMessages;
- (nullable NSMutableSet<Message*>*)referencingMessagesSet;

@end

@interface _MessageReference (ReferencingMessagesCoreDataGeneratedAccessors)
- (void)addReferencingMessages:(NSSet<Message*>*)value_;
- (void)removeReferencingMessages:(NSSet<Message*>*)value_;
- (void)addReferencingMessagesObject:(Message*)value_;
- (void)removeReferencingMessagesObject:(Message*)value_;

@end

@interface _MessageReference (CoreDataGeneratedPrimitiveAccessors)

- (NSString*)primitiveMessageID;
- (void)setPrimitiveMessageID:(NSString*)value;

- (Message*)primitiveMessage;
- (void)setPrimitiveMessage:(Message*)value;

- (NSMutableSet<Message*>*)primitiveReferencingMessages;
- (void)setPrimitiveReferencingMessages:(NSMutableSet<Message*>*)value;

@end

@interface MessageReferenceAttributes: NSObject 
+ (NSString *)messageID;
@end

@interface MessageReferenceRelationships: NSObject
+ (NSString *)message;
+ (NSString *)referencingMessages;
@end

NS_ASSUME_NONNULL_END
