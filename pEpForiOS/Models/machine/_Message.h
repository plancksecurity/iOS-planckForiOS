// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Message.h instead.

#if __has_feature(modules)
    @import Foundation;
    @import CoreData;
#else
    #import <Foundation/Foundation.h>
    #import <CoreData/CoreData.h>
#endif

#import "BaseManagedObject.h"

NS_ASSUME_NONNULL_BEGIN

@class Attachment;
@class Contact;
@class Contact;
@class Folder;
@class Contact;
@class MessageReference;
@class MessageReference;
@class Contact;

@interface MessageID : NSManagedObjectID {}
@end

@protocol _IMessage

@property (nonatomic, strong) NSNumber* bodyFetched;

@property (atomic) BOOL bodyFetchedValue;
- (BOOL)bodyFetchedValue;
- (void)setBodyFetchedValue:(BOOL)value_;

@property (nonatomic, strong, nullable) NSString* boundary;

@property (nonatomic, strong, nullable) NSString* contentType;

@property (nonatomic, strong) NSNumber* flagAnswered;

@property (atomic) BOOL flagAnsweredValue;
- (BOOL)flagAnsweredValue;
- (void)setFlagAnsweredValue:(BOOL)value_;

@property (nonatomic, strong) NSNumber* flagDeleted;

@property (atomic) BOOL flagDeletedValue;
- (BOOL)flagDeletedValue;
- (void)setFlagDeletedValue:(BOOL)value_;

@property (nonatomic, strong) NSNumber* flagDraft;

@property (atomic) BOOL flagDraftValue;
- (BOOL)flagDraftValue;
- (void)setFlagDraftValue:(BOOL)value_;

@property (nonatomic, strong) NSNumber* flagFlagged;

@property (atomic) BOOL flagFlaggedValue;
- (BOOL)flagFlaggedValue;
- (void)setFlagFlaggedValue:(BOOL)value_;

@property (nonatomic, strong) NSNumber* flagRecent;

@property (atomic) BOOL flagRecentValue;
- (BOOL)flagRecentValue;
- (void)setFlagRecentValue:(BOOL)value_;

@property (nonatomic, strong) NSNumber* flagSeen;

@property (atomic) BOOL flagSeenValue;
- (BOOL)flagSeenValue;
- (void)setFlagSeenValue:(BOOL)value_;

@property (nonatomic, strong) NSNumber* flags;

@property (atomic) int16_t flagsValue;
- (int16_t)flagsValue;
- (void)setFlagsValue:(int16_t)value_;

@property (nonatomic, strong) NSNumber* flagsFromServer;

@property (atomic) int16_t flagsFromServerValue;
- (int16_t)flagsFromServerValue;
- (void)setFlagsFromServerValue:(int16_t)value_;

@property (nonatomic, strong, nullable) NSString* longMessage;

@property (nonatomic, strong, nullable) NSString* longMessageFormatted;

@property (nonatomic, strong, nullable) NSString* messageID;

@property (nonatomic, strong, nullable) NSNumber* messageNumber;

@property (atomic) uint32_t messageNumberValue;
- (uint32_t)messageNumberValue;
- (void)setMessageNumberValue:(uint32_t)value_;

@property (nonatomic, strong, nullable) NSNumber* pepColorRating;

@property (atomic) int16_t pepColorRatingValue;
- (int16_t)pepColorRatingValue;
- (void)setPepColorRatingValue:(int16_t)value_;

@property (nonatomic, strong, nullable) NSDate* receivedDate;

@property (nonatomic, strong, nullable) NSString* subject;

@property (nonatomic, strong) NSNumber* uid;

@property (atomic) uint32_t uidValue;
- (uint32_t)uidValue;
- (void)setUidValue:(uint32_t)value_;

@property (nonatomic, strong) NSOrderedSet<Attachment*> *attachments;
- (NSMutableOrderedSet<Attachment*>*)attachmentsSet;

@property (nonatomic, strong, nullable) NSOrderedSet<Contact*> *bcc;
- (nullable NSMutableOrderedSet<Contact*>*)bccSet;

@property (nonatomic, strong, nullable) NSOrderedSet<Contact*> *cc;
- (nullable NSMutableOrderedSet<Contact*>*)ccSet;

@property (nonatomic, strong) Folder *folder;

@property (nonatomic, strong, nullable) Contact *from;

@property (nonatomic, strong, nullable) MessageReference *messageReference;

@property (nonatomic, strong, nullable) NSOrderedSet<MessageReference*> *references;
- (nullable NSMutableOrderedSet<MessageReference*>*)referencesSet;

@property (nonatomic, strong, nullable) NSOrderedSet<Contact*> *to;
- (nullable NSMutableOrderedSet<Contact*>*)toSet;

@end

@interface _Message : BaseManagedObject <_IMessage>
+ (instancetype)insertInManagedObjectContext:(NSManagedObjectContext *)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
@property (nonatomic, readonly, strong) MessageID *objectID;

@property (nonatomic, strong) NSNumber* bodyFetched;

@property (atomic) BOOL bodyFetchedValue;
- (BOOL)bodyFetchedValue;
- (void)setBodyFetchedValue:(BOOL)value_;

@property (nonatomic, strong, nullable) NSString* boundary;

@property (nonatomic, strong, nullable) NSString* contentType;

@property (nonatomic, strong) NSNumber* flagAnswered;

@property (atomic) BOOL flagAnsweredValue;
- (BOOL)flagAnsweredValue;
- (void)setFlagAnsweredValue:(BOOL)value_;

@property (nonatomic, strong) NSNumber* flagDeleted;

@property (atomic) BOOL flagDeletedValue;
- (BOOL)flagDeletedValue;
- (void)setFlagDeletedValue:(BOOL)value_;

@property (nonatomic, strong) NSNumber* flagDraft;

@property (atomic) BOOL flagDraftValue;
- (BOOL)flagDraftValue;
- (void)setFlagDraftValue:(BOOL)value_;

@property (nonatomic, strong) NSNumber* flagFlagged;

@property (atomic) BOOL flagFlaggedValue;
- (BOOL)flagFlaggedValue;
- (void)setFlagFlaggedValue:(BOOL)value_;

@property (nonatomic, strong) NSNumber* flagRecent;

@property (atomic) BOOL flagRecentValue;
- (BOOL)flagRecentValue;
- (void)setFlagRecentValue:(BOOL)value_;

@property (nonatomic, strong) NSNumber* flagSeen;

@property (atomic) BOOL flagSeenValue;
- (BOOL)flagSeenValue;
- (void)setFlagSeenValue:(BOOL)value_;

@property (nonatomic, strong) NSNumber* flags;

@property (atomic) int16_t flagsValue;
- (int16_t)flagsValue;
- (void)setFlagsValue:(int16_t)value_;

@property (nonatomic, strong) NSNumber* flagsFromServer;

@property (atomic) int16_t flagsFromServerValue;
- (int16_t)flagsFromServerValue;
- (void)setFlagsFromServerValue:(int16_t)value_;

@property (nonatomic, strong, nullable) NSString* longMessage;

@property (nonatomic, strong, nullable) NSString* longMessageFormatted;

@property (nonatomic, strong, nullable) NSString* messageID;

@property (nonatomic, strong, nullable) NSNumber* messageNumber;

@property (atomic) uint32_t messageNumberValue;
- (uint32_t)messageNumberValue;
- (void)setMessageNumberValue:(uint32_t)value_;

@property (nonatomic, strong, nullable) NSNumber* pepColorRating;

@property (atomic) int16_t pepColorRatingValue;
- (int16_t)pepColorRatingValue;
- (void)setPepColorRatingValue:(int16_t)value_;

@property (nonatomic, strong, nullable) NSDate* receivedDate;

@property (nonatomic, strong, nullable) NSString* subject;

@property (nonatomic, strong) NSNumber* uid;

@property (atomic) uint32_t uidValue;
- (uint32_t)uidValue;
- (void)setUidValue:(uint32_t)value_;

@property (nonatomic, strong) NSOrderedSet<Attachment*> *attachments;
- (NSMutableOrderedSet<Attachment*>*)attachmentsSet;

@property (nonatomic, strong, nullable) NSOrderedSet<Contact*> *bcc;
- (nullable NSMutableOrderedSet<Contact*>*)bccSet;

@property (nonatomic, strong, nullable) NSOrderedSet<Contact*> *cc;
- (nullable NSMutableOrderedSet<Contact*>*)ccSet;

@property (nonatomic, strong) Folder *folder;

@property (nonatomic, strong, nullable) Contact *from;

@property (nonatomic, strong, nullable) MessageReference *messageReference;

@property (nonatomic, strong, nullable) NSOrderedSet<MessageReference*> *references;
- (nullable NSMutableOrderedSet<MessageReference*>*)referencesSet;

@property (nonatomic, strong, nullable) NSOrderedSet<Contact*> *to;
- (nullable NSMutableOrderedSet<Contact*>*)toSet;

@end

@interface _Message (AttachmentsCoreDataGeneratedAccessors)
- (void)addAttachments:(NSOrderedSet<Attachment*>*)value_;
- (void)removeAttachments:(NSOrderedSet<Attachment*>*)value_;
- (void)addAttachmentsObject:(Attachment*)value_;
- (void)removeAttachmentsObject:(Attachment*)value_;

- (void)insertObject:(Attachment*)value inAttachmentsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromAttachmentsAtIndex:(NSUInteger)idx;
- (void)insertAttachments:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeAttachmentsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInAttachmentsAtIndex:(NSUInteger)idx withObject:(Attachment*)value;
- (void)replaceAttachmentsAtIndexes:(NSIndexSet *)indexes withAttachments:(NSArray *)values;

@end

@interface _Message (BccCoreDataGeneratedAccessors)
- (void)addBcc:(NSOrderedSet<Contact*>*)value_;
- (void)removeBcc:(NSOrderedSet<Contact*>*)value_;
- (void)addBccObject:(Contact*)value_;
- (void)removeBccObject:(Contact*)value_;

- (void)insertObject:(Contact*)value inBccAtIndex:(NSUInteger)idx;
- (void)removeObjectFromBccAtIndex:(NSUInteger)idx;
- (void)insertBcc:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeBccAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInBccAtIndex:(NSUInteger)idx withObject:(Contact*)value;
- (void)replaceBccAtIndexes:(NSIndexSet *)indexes withBcc:(NSArray *)values;

@end

@interface _Message (CcCoreDataGeneratedAccessors)
- (void)addCc:(NSOrderedSet<Contact*>*)value_;
- (void)removeCc:(NSOrderedSet<Contact*>*)value_;
- (void)addCcObject:(Contact*)value_;
- (void)removeCcObject:(Contact*)value_;

- (void)insertObject:(Contact*)value inCcAtIndex:(NSUInteger)idx;
- (void)removeObjectFromCcAtIndex:(NSUInteger)idx;
- (void)insertCc:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeCcAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInCcAtIndex:(NSUInteger)idx withObject:(Contact*)value;
- (void)replaceCcAtIndexes:(NSIndexSet *)indexes withCc:(NSArray *)values;

@end

@interface _Message (ReferencesCoreDataGeneratedAccessors)
- (void)addReferences:(NSOrderedSet<MessageReference*>*)value_;
- (void)removeReferences:(NSOrderedSet<MessageReference*>*)value_;
- (void)addReferencesObject:(MessageReference*)value_;
- (void)removeReferencesObject:(MessageReference*)value_;

- (void)insertObject:(MessageReference*)value inReferencesAtIndex:(NSUInteger)idx;
- (void)removeObjectFromReferencesAtIndex:(NSUInteger)idx;
- (void)insertReferences:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeReferencesAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInReferencesAtIndex:(NSUInteger)idx withObject:(MessageReference*)value;
- (void)replaceReferencesAtIndexes:(NSIndexSet *)indexes withReferences:(NSArray *)values;

@end

@interface _Message (ToCoreDataGeneratedAccessors)
- (void)addTo:(NSOrderedSet<Contact*>*)value_;
- (void)removeTo:(NSOrderedSet<Contact*>*)value_;
- (void)addToObject:(Contact*)value_;
- (void)removeToObject:(Contact*)value_;

- (void)insertObject:(Contact*)value inToAtIndex:(NSUInteger)idx;
- (void)removeObjectFromToAtIndex:(NSUInteger)idx;
- (void)insertTo:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeToAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInToAtIndex:(NSUInteger)idx withObject:(Contact*)value;
- (void)replaceToAtIndexes:(NSIndexSet *)indexes withTo:(NSArray *)values;

@end

@interface _Message (CoreDataGeneratedPrimitiveAccessors)

- (NSNumber*)primitiveBodyFetched;
- (void)setPrimitiveBodyFetched:(NSNumber*)value;

- (BOOL)primitiveBodyFetchedValue;
- (void)setPrimitiveBodyFetchedValue:(BOOL)value_;

- (NSString*)primitiveBoundary;
- (void)setPrimitiveBoundary:(NSString*)value;

- (NSString*)primitiveContentType;
- (void)setPrimitiveContentType:(NSString*)value;

- (NSNumber*)primitiveFlagAnswered;
- (void)setPrimitiveFlagAnswered:(NSNumber*)value;

- (BOOL)primitiveFlagAnsweredValue;
- (void)setPrimitiveFlagAnsweredValue:(BOOL)value_;

- (NSNumber*)primitiveFlagDeleted;
- (void)setPrimitiveFlagDeleted:(NSNumber*)value;

- (BOOL)primitiveFlagDeletedValue;
- (void)setPrimitiveFlagDeletedValue:(BOOL)value_;

- (NSNumber*)primitiveFlagDraft;
- (void)setPrimitiveFlagDraft:(NSNumber*)value;

- (BOOL)primitiveFlagDraftValue;
- (void)setPrimitiveFlagDraftValue:(BOOL)value_;

- (NSNumber*)primitiveFlagFlagged;
- (void)setPrimitiveFlagFlagged:(NSNumber*)value;

- (BOOL)primitiveFlagFlaggedValue;
- (void)setPrimitiveFlagFlaggedValue:(BOOL)value_;

- (NSNumber*)primitiveFlagRecent;
- (void)setPrimitiveFlagRecent:(NSNumber*)value;

- (BOOL)primitiveFlagRecentValue;
- (void)setPrimitiveFlagRecentValue:(BOOL)value_;

- (NSNumber*)primitiveFlagSeen;
- (void)setPrimitiveFlagSeen:(NSNumber*)value;

- (BOOL)primitiveFlagSeenValue;
- (void)setPrimitiveFlagSeenValue:(BOOL)value_;

- (NSNumber*)primitiveFlags;
- (void)setPrimitiveFlags:(NSNumber*)value;

- (int16_t)primitiveFlagsValue;
- (void)setPrimitiveFlagsValue:(int16_t)value_;

- (NSNumber*)primitiveFlagsFromServer;
- (void)setPrimitiveFlagsFromServer:(NSNumber*)value;

- (int16_t)primitiveFlagsFromServerValue;
- (void)setPrimitiveFlagsFromServerValue:(int16_t)value_;

- (NSString*)primitiveLongMessage;
- (void)setPrimitiveLongMessage:(NSString*)value;

- (NSString*)primitiveLongMessageFormatted;
- (void)setPrimitiveLongMessageFormatted:(NSString*)value;

- (NSString*)primitiveMessageID;
- (void)setPrimitiveMessageID:(NSString*)value;

- (NSNumber*)primitiveMessageNumber;
- (void)setPrimitiveMessageNumber:(NSNumber*)value;

- (uint32_t)primitiveMessageNumberValue;
- (void)setPrimitiveMessageNumberValue:(uint32_t)value_;

- (NSNumber*)primitivePepColorRating;
- (void)setPrimitivePepColorRating:(NSNumber*)value;

- (int16_t)primitivePepColorRatingValue;
- (void)setPrimitivePepColorRatingValue:(int16_t)value_;

- (NSDate*)primitiveReceivedDate;
- (void)setPrimitiveReceivedDate:(NSDate*)value;

- (NSString*)primitiveSubject;
- (void)setPrimitiveSubject:(NSString*)value;

- (NSNumber*)primitiveUid;
- (void)setPrimitiveUid:(NSNumber*)value;

- (uint32_t)primitiveUidValue;
- (void)setPrimitiveUidValue:(uint32_t)value_;

- (NSMutableOrderedSet<Attachment*>*)primitiveAttachments;
- (void)setPrimitiveAttachments:(NSMutableOrderedSet<Attachment*>*)value;

- (NSMutableOrderedSet<Contact*>*)primitiveBcc;
- (void)setPrimitiveBcc:(NSMutableOrderedSet<Contact*>*)value;

- (NSMutableOrderedSet<Contact*>*)primitiveCc;
- (void)setPrimitiveCc:(NSMutableOrderedSet<Contact*>*)value;

- (Folder*)primitiveFolder;
- (void)setPrimitiveFolder:(Folder*)value;

- (Contact*)primitiveFrom;
- (void)setPrimitiveFrom:(Contact*)value;

- (MessageReference*)primitiveMessageReference;
- (void)setPrimitiveMessageReference:(MessageReference*)value;

- (NSMutableOrderedSet<MessageReference*>*)primitiveReferences;
- (void)setPrimitiveReferences:(NSMutableOrderedSet<MessageReference*>*)value;

- (NSMutableOrderedSet<Contact*>*)primitiveTo;
- (void)setPrimitiveTo:(NSMutableOrderedSet<Contact*>*)value;

@end

@interface MessageAttributes: NSObject 
+ (NSString *)bodyFetched;
+ (NSString *)boundary;
+ (NSString *)contentType;
+ (NSString *)flagAnswered;
+ (NSString *)flagDeleted;
+ (NSString *)flagDraft;
+ (NSString *)flagFlagged;
+ (NSString *)flagRecent;
+ (NSString *)flagSeen;
+ (NSString *)flags;
+ (NSString *)flagsFromServer;
+ (NSString *)longMessage;
+ (NSString *)longMessageFormatted;
+ (NSString *)messageID;
+ (NSString *)messageNumber;
+ (NSString *)pepColorRating;
+ (NSString *)receivedDate;
+ (NSString *)subject;
+ (NSString *)uid;
@end

@interface MessageRelationships: NSObject
+ (NSString *)attachments;
+ (NSString *)bcc;
+ (NSString *)cc;
+ (NSString *)folder;
+ (NSString *)from;
+ (NSString *)messageReference;
+ (NSString *)references;
+ (NSString *)to;
@end

NS_ASSUME_NONNULL_END
