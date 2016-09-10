// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Account.h instead.

#if __has_feature(modules)
    @import Foundation;
    @import CoreData;
#else
    #import <Foundation/Foundation.h>
    #import <CoreData/CoreData.h>
#endif

#import "BaseManagedObject.h"

NS_ASSUME_NONNULL_BEGIN

@class Folder;

@interface AccountID : NSManagedObjectID {}
@end

@protocol _IAccount

@property (nonatomic, strong) NSNumber* accountType;

@property (atomic) int16_t accountTypeValue;
- (int16_t)accountTypeValue;
- (void)setAccountTypeValue:(int16_t)value_;

@property (nonatomic, strong) NSString* email;

@property (nonatomic, strong, nullable) NSString* folderSeparator;

@property (nonatomic, strong) NSString* imapServerName;

@property (nonatomic, strong) NSNumber* imapServerPort;

@property (atomic) int16_t imapServerPortValue;
- (int16_t)imapServerPortValue;
- (void)setImapServerPortValue:(int16_t)value_;

@property (nonatomic, strong) NSNumber* imapTransport;

@property (atomic) int16_t imapTransportValue;
- (int16_t)imapTransportValue;
- (void)setImapTransportValue:(int16_t)value_;

@property (nonatomic, strong, nullable) NSString* imapUsername;

@property (nonatomic, strong) NSString* nameOfTheUser;

@property (nonatomic, strong) NSString* smtpServerName;

@property (nonatomic, strong) NSNumber* smtpServerPort;

@property (atomic) int16_t smtpServerPortValue;
- (int16_t)smtpServerPortValue;
- (void)setSmtpServerPortValue:(int16_t)value_;

@property (nonatomic, strong) NSNumber* smtpTransport;

@property (atomic) int16_t smtpTransportValue;
- (int16_t)smtpTransportValue;
- (void)setSmtpTransportValue:(int16_t)value_;

@property (nonatomic, strong, nullable) NSString* smtpUsername;

@property (nonatomic, strong, nullable) NSSet<Folder*> *folders;
- (nullable NSMutableSet<Folder*>*)foldersSet;

@end

@interface _Account : BaseManagedObject <_IAccount>
+ (instancetype)insertInManagedObjectContext:(NSManagedObjectContext *)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
@property (nonatomic, readonly, strong) AccountID *objectID;

@property (nonatomic, strong) NSNumber* accountType;

@property (atomic) int16_t accountTypeValue;
- (int16_t)accountTypeValue;
- (void)setAccountTypeValue:(int16_t)value_;

@property (nonatomic, strong) NSString* email;

@property (nonatomic, strong, nullable) NSString* folderSeparator;

@property (nonatomic, strong) NSString* imapServerName;

@property (nonatomic, strong) NSNumber* imapServerPort;

@property (atomic) int16_t imapServerPortValue;
- (int16_t)imapServerPortValue;
- (void)setImapServerPortValue:(int16_t)value_;

@property (nonatomic, strong) NSNumber* imapTransport;

@property (atomic) int16_t imapTransportValue;
- (int16_t)imapTransportValue;
- (void)setImapTransportValue:(int16_t)value_;

@property (nonatomic, strong, nullable) NSString* imapUsername;

@property (nonatomic, strong) NSString* nameOfTheUser;

@property (nonatomic, strong) NSString* smtpServerName;

@property (nonatomic, strong) NSNumber* smtpServerPort;

@property (atomic) int16_t smtpServerPortValue;
- (int16_t)smtpServerPortValue;
- (void)setSmtpServerPortValue:(int16_t)value_;

@property (nonatomic, strong) NSNumber* smtpTransport;

@property (atomic) int16_t smtpTransportValue;
- (int16_t)smtpTransportValue;
- (void)setSmtpTransportValue:(int16_t)value_;

@property (nonatomic, strong, nullable) NSString* smtpUsername;

@property (nonatomic, strong, nullable) NSSet<Folder*> *folders;
- (nullable NSMutableSet<Folder*>*)foldersSet;

@end

@interface _Account (FoldersCoreDataGeneratedAccessors)
- (void)addFolders:(NSSet<Folder*>*)value_;
- (void)removeFolders:(NSSet<Folder*>*)value_;
- (void)addFoldersObject:(Folder*)value_;
- (void)removeFoldersObject:(Folder*)value_;

@end

@interface _Account (CoreDataGeneratedPrimitiveAccessors)

- (NSNumber*)primitiveAccountType;
- (void)setPrimitiveAccountType:(NSNumber*)value;

- (int16_t)primitiveAccountTypeValue;
- (void)setPrimitiveAccountTypeValue:(int16_t)value_;

- (NSString*)primitiveEmail;
- (void)setPrimitiveEmail:(NSString*)value;

- (NSString*)primitiveFolderSeparator;
- (void)setPrimitiveFolderSeparator:(NSString*)value;

- (NSString*)primitiveImapServerName;
- (void)setPrimitiveImapServerName:(NSString*)value;

- (NSNumber*)primitiveImapServerPort;
- (void)setPrimitiveImapServerPort:(NSNumber*)value;

- (int16_t)primitiveImapServerPortValue;
- (void)setPrimitiveImapServerPortValue:(int16_t)value_;

- (NSNumber*)primitiveImapTransport;
- (void)setPrimitiveImapTransport:(NSNumber*)value;

- (int16_t)primitiveImapTransportValue;
- (void)setPrimitiveImapTransportValue:(int16_t)value_;

- (NSString*)primitiveImapUsername;
- (void)setPrimitiveImapUsername:(NSString*)value;

- (NSString*)primitiveNameOfTheUser;
- (void)setPrimitiveNameOfTheUser:(NSString*)value;

- (NSString*)primitiveSmtpServerName;
- (void)setPrimitiveSmtpServerName:(NSString*)value;

- (NSNumber*)primitiveSmtpServerPort;
- (void)setPrimitiveSmtpServerPort:(NSNumber*)value;

- (int16_t)primitiveSmtpServerPortValue;
- (void)setPrimitiveSmtpServerPortValue:(int16_t)value_;

- (NSNumber*)primitiveSmtpTransport;
- (void)setPrimitiveSmtpTransport:(NSNumber*)value;

- (int16_t)primitiveSmtpTransportValue;
- (void)setPrimitiveSmtpTransportValue:(int16_t)value_;

- (NSString*)primitiveSmtpUsername;
- (void)setPrimitiveSmtpUsername:(NSString*)value;

- (NSMutableSet<Folder*>*)primitiveFolders;
- (void)setPrimitiveFolders:(NSMutableSet<Folder*>*)value;

@end

@interface AccountAttributes: NSObject 
+ (NSString *)accountType;
+ (NSString *)email;
+ (NSString *)folderSeparator;
+ (NSString *)imapServerName;
+ (NSString *)imapServerPort;
+ (NSString *)imapTransport;
+ (NSString *)imapUsername;
+ (NSString *)nameOfTheUser;
+ (NSString *)smtpServerName;
+ (NSString *)smtpServerPort;
+ (NSString *)smtpTransport;
+ (NSString *)smtpUsername;
@end

@interface AccountRelationships: NSObject
+ (NSString *)folders;
@end

NS_ASSUME_NONNULL_END
