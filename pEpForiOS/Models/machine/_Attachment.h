// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Attachment.h instead.

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

@interface AttachmentID : NSManagedObjectID {}
@end

@protocol _IAttachment

@property (nonatomic, strong, nullable) NSString* contentType;

@property (nonatomic, strong, nullable) NSData* data;

@property (nonatomic, strong, nullable) NSString* filename;

@property (nonatomic, strong) NSNumber* size;

@property (atomic) int64_t sizeValue;
- (int64_t)sizeValue;
- (void)setSizeValue:(int64_t)value_;

@property (nonatomic, strong) Message *message;

@end

@interface _Attachment : BaseManagedObject <_IAttachment>
+ (instancetype)insertInManagedObjectContext:(NSManagedObjectContext *)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
@property (nonatomic, readonly, strong) AttachmentID *objectID;

@property (nonatomic, strong, nullable) NSString* contentType;

@property (nonatomic, strong, nullable) NSData* data;

@property (nonatomic, strong, nullable) NSString* filename;

@property (nonatomic, strong) NSNumber* size;

@property (atomic) int64_t sizeValue;
- (int64_t)sizeValue;
- (void)setSizeValue:(int64_t)value_;

@property (nonatomic, strong) Message *message;

@end

@interface _Attachment (CoreDataGeneratedPrimitiveAccessors)

- (NSString*)primitiveContentType;
- (void)setPrimitiveContentType:(NSString*)value;

- (NSData*)primitiveData;
- (void)setPrimitiveData:(NSData*)value;

- (NSString*)primitiveFilename;
- (void)setPrimitiveFilename:(NSString*)value;

- (NSNumber*)primitiveSize;
- (void)setPrimitiveSize:(NSNumber*)value;

- (int64_t)primitiveSizeValue;
- (void)setPrimitiveSizeValue:(int64_t)value_;

- (Message*)primitiveMessage;
- (void)setPrimitiveMessage:(Message*)value;

@end

@interface AttachmentAttributes: NSObject 
+ (NSString *)contentType;
+ (NSString *)data;
+ (NSString *)filename;
+ (NSString *)size;
@end

@interface AttachmentRelationships: NSObject
+ (NSString *)message;
@end

NS_ASSUME_NONNULL_END
