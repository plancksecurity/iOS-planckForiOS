// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Message.m instead.

#import "_Message.h"

@implementation MessageID
@end

@implementation _Message

+ (instancetype)insertInManagedObjectContext:(NSManagedObjectContext *)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"Message" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"Message";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"Message" inManagedObjectContext:moc_];
}

- (MessageID*)objectID {
	return (MessageID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];

	if ([key isEqualToString:@"bodyFetchedValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"bodyFetched"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}
	if ([key isEqualToString:@"flagAnsweredValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"flagAnswered"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}
	if ([key isEqualToString:@"flagDeletedValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"flagDeleted"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}
	if ([key isEqualToString:@"flagDraftValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"flagDraft"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}
	if ([key isEqualToString:@"flagFlaggedValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"flagFlagged"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}
	if ([key isEqualToString:@"flagRecentValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"flagRecent"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}
	if ([key isEqualToString:@"flagSeenValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"flagSeen"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}
	if ([key isEqualToString:@"flagsValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"flags"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}
	if ([key isEqualToString:@"flagsFromServerValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"flagsFromServer"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}
	if ([key isEqualToString:@"messageNumberValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"messageNumber"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}
	if ([key isEqualToString:@"pepColorRatingValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"pepColorRating"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}
	if ([key isEqualToString:@"uidValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"uid"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}

	return keyPaths;
}

@dynamic bodyFetched;

- (BOOL)bodyFetchedValue {
	NSNumber *result = [self bodyFetched];
	return [result boolValue];
}

- (void)setBodyFetchedValue:(BOOL)value_ {
	[self setBodyFetched:@(value_)];
}

- (BOOL)primitiveBodyFetchedValue {
	NSNumber *result = [self primitiveBodyFetched];
	return [result boolValue];
}

- (void)setPrimitiveBodyFetchedValue:(BOOL)value_ {
	[self setPrimitiveBodyFetched:@(value_)];
}

@dynamic boundary;

@dynamic contentType;

@dynamic flagAnswered;

- (BOOL)flagAnsweredValue {
	NSNumber *result = [self flagAnswered];
	return [result boolValue];
}

- (void)setFlagAnsweredValue:(BOOL)value_ {
	[self setFlagAnswered:@(value_)];
}

- (BOOL)primitiveFlagAnsweredValue {
	NSNumber *result = [self primitiveFlagAnswered];
	return [result boolValue];
}

- (void)setPrimitiveFlagAnsweredValue:(BOOL)value_ {
	[self setPrimitiveFlagAnswered:@(value_)];
}

@dynamic flagDeleted;

- (BOOL)flagDeletedValue {
	NSNumber *result = [self flagDeleted];
	return [result boolValue];
}

- (void)setFlagDeletedValue:(BOOL)value_ {
	[self setFlagDeleted:@(value_)];
}

- (BOOL)primitiveFlagDeletedValue {
	NSNumber *result = [self primitiveFlagDeleted];
	return [result boolValue];
}

- (void)setPrimitiveFlagDeletedValue:(BOOL)value_ {
	[self setPrimitiveFlagDeleted:@(value_)];
}

@dynamic flagDraft;

- (BOOL)flagDraftValue {
	NSNumber *result = [self flagDraft];
	return [result boolValue];
}

- (void)setFlagDraftValue:(BOOL)value_ {
	[self setFlagDraft:@(value_)];
}

- (BOOL)primitiveFlagDraftValue {
	NSNumber *result = [self primitiveFlagDraft];
	return [result boolValue];
}

- (void)setPrimitiveFlagDraftValue:(BOOL)value_ {
	[self setPrimitiveFlagDraft:@(value_)];
}

@dynamic flagFlagged;

- (BOOL)flagFlaggedValue {
	NSNumber *result = [self flagFlagged];
	return [result boolValue];
}

- (void)setFlagFlaggedValue:(BOOL)value_ {
	[self setFlagFlagged:@(value_)];
}

- (BOOL)primitiveFlagFlaggedValue {
	NSNumber *result = [self primitiveFlagFlagged];
	return [result boolValue];
}

- (void)setPrimitiveFlagFlaggedValue:(BOOL)value_ {
	[self setPrimitiveFlagFlagged:@(value_)];
}

@dynamic flagRecent;

- (BOOL)flagRecentValue {
	NSNumber *result = [self flagRecent];
	return [result boolValue];
}

- (void)setFlagRecentValue:(BOOL)value_ {
	[self setFlagRecent:@(value_)];
}

- (BOOL)primitiveFlagRecentValue {
	NSNumber *result = [self primitiveFlagRecent];
	return [result boolValue];
}

- (void)setPrimitiveFlagRecentValue:(BOOL)value_ {
	[self setPrimitiveFlagRecent:@(value_)];
}

@dynamic flagSeen;

- (BOOL)flagSeenValue {
	NSNumber *result = [self flagSeen];
	return [result boolValue];
}

- (void)setFlagSeenValue:(BOOL)value_ {
	[self setFlagSeen:@(value_)];
}

- (BOOL)primitiveFlagSeenValue {
	NSNumber *result = [self primitiveFlagSeen];
	return [result boolValue];
}

- (void)setPrimitiveFlagSeenValue:(BOOL)value_ {
	[self setPrimitiveFlagSeen:@(value_)];
}

@dynamic flags;

- (int16_t)flagsValue {
	NSNumber *result = [self flags];
	return [result shortValue];
}

- (void)setFlagsValue:(int16_t)value_ {
	[self setFlags:@(value_)];
}

- (int16_t)primitiveFlagsValue {
	NSNumber *result = [self primitiveFlags];
	return [result shortValue];
}

- (void)setPrimitiveFlagsValue:(int16_t)value_ {
	[self setPrimitiveFlags:@(value_)];
}

@dynamic flagsFromServer;

- (int16_t)flagsFromServerValue {
	NSNumber *result = [self flagsFromServer];
	return [result shortValue];
}

- (void)setFlagsFromServerValue:(int16_t)value_ {
	[self setFlagsFromServer:@(value_)];
}

- (int16_t)primitiveFlagsFromServerValue {
	NSNumber *result = [self primitiveFlagsFromServer];
	return [result shortValue];
}

- (void)setPrimitiveFlagsFromServerValue:(int16_t)value_ {
	[self setPrimitiveFlagsFromServer:@(value_)];
}

@dynamic longMessage;

@dynamic longMessageFormatted;

@dynamic messageID;

@dynamic messageNumber;

- (uint32_t)messageNumberValue {
	NSNumber *result = [self messageNumber];
	return [result unsignedIntValue];
}

- (void)setMessageNumberValue:(uint32_t)value_ {
	[self setMessageNumber:@(value_)];
}

- (uint32_t)primitiveMessageNumberValue {
	NSNumber *result = [self primitiveMessageNumber];
	return [result unsignedIntValue];
}

- (void)setPrimitiveMessageNumberValue:(uint32_t)value_ {
	[self setPrimitiveMessageNumber:@(value_)];
}

@dynamic pepColorRating;

- (int16_t)pepColorRatingValue {
	NSNumber *result = [self pepColorRating];
	return [result shortValue];
}

- (void)setPepColorRatingValue:(int16_t)value_ {
	[self setPepColorRating:@(value_)];
}

- (int16_t)primitivePepColorRatingValue {
	NSNumber *result = [self primitivePepColorRating];
	return [result shortValue];
}

- (void)setPrimitivePepColorRatingValue:(int16_t)value_ {
	[self setPrimitivePepColorRating:@(value_)];
}

@dynamic receivedDate;

@dynamic subject;

@dynamic uid;

- (uint32_t)uidValue {
	NSNumber *result = [self uid];
	return [result unsignedIntValue];
}

- (void)setUidValue:(uint32_t)value_ {
	[self setUid:@(value_)];
}

- (uint32_t)primitiveUidValue {
	NSNumber *result = [self primitiveUid];
	return [result unsignedIntValue];
}

- (void)setPrimitiveUidValue:(uint32_t)value_ {
	[self setPrimitiveUid:@(value_)];
}

@dynamic attachments;

- (NSMutableOrderedSet<Attachment*>*)attachmentsSet {
	[self willAccessValueForKey:@"attachments"];

	NSMutableOrderedSet<Attachment*> *result = (NSMutableOrderedSet<Attachment*>*)[self mutableOrderedSetValueForKey:@"attachments"];

	[self didAccessValueForKey:@"attachments"];
	return result;
}

@dynamic bcc;

- (NSMutableOrderedSet<Contact*>*)bccSet {
	[self willAccessValueForKey:@"bcc"];

	NSMutableOrderedSet<Contact*> *result = (NSMutableOrderedSet<Contact*>*)[self mutableOrderedSetValueForKey:@"bcc"];

	[self didAccessValueForKey:@"bcc"];
	return result;
}

@dynamic cc;

- (NSMutableOrderedSet<Contact*>*)ccSet {
	[self willAccessValueForKey:@"cc"];

	NSMutableOrderedSet<Contact*> *result = (NSMutableOrderedSet<Contact*>*)[self mutableOrderedSetValueForKey:@"cc"];

	[self didAccessValueForKey:@"cc"];
	return result;
}

@dynamic folder;

@dynamic from;

@dynamic messageReference;

@dynamic references;

- (NSMutableOrderedSet<MessageReference*>*)referencesSet {
	[self willAccessValueForKey:@"references"];

	NSMutableOrderedSet<MessageReference*> *result = (NSMutableOrderedSet<MessageReference*>*)[self mutableOrderedSetValueForKey:@"references"];

	[self didAccessValueForKey:@"references"];
	return result;
}

@dynamic to;

- (NSMutableOrderedSet<Contact*>*)toSet {
	[self willAccessValueForKey:@"to"];

	NSMutableOrderedSet<Contact*> *result = (NSMutableOrderedSet<Contact*>*)[self mutableOrderedSetValueForKey:@"to"];

	[self didAccessValueForKey:@"to"];
	return result;
}

@end

@implementation _Message (AttachmentsCoreDataGeneratedAccessors)
- (void)addAttachments:(NSOrderedSet<Attachment*>*)value_ {
	[self.attachmentsSet unionOrderedSet:value_];
}
- (void)removeAttachments:(NSOrderedSet<Attachment*>*)value_ {
	[self.attachmentsSet minusOrderedSet:value_];
}
- (void)addAttachmentsObject:(Attachment*)value_ {
	[self.attachmentsSet addObject:value_];
}
- (void)removeAttachmentsObject:(Attachment*)value_ {
	[self.attachmentsSet removeObject:value_];
}
- (void)insertObject:(Attachment*)value inAttachmentsAtIndex:(NSUInteger)idx {
    NSIndexSet* indexes = [NSIndexSet indexSetWithIndex:idx];
    [self willChange:NSKeyValueChangeInsertion valuesAtIndexes:indexes forKey:@"attachments"];
    NSMutableOrderedSet *tmpOrderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:[self attachments]];
    [tmpOrderedSet insertObject:value atIndex:idx];
    [self setPrimitiveValue:tmpOrderedSet forKey:@"attachments"];
    [self didChange:NSKeyValueChangeInsertion valuesAtIndexes:indexes forKey:@"attachments"];
}
- (void)removeObjectFromAttachmentsAtIndex:(NSUInteger)idx {
    NSIndexSet* indexes = [NSIndexSet indexSetWithIndex:idx];
    [self willChange:NSKeyValueChangeRemoval valuesAtIndexes:indexes forKey:@"attachments"];
    NSMutableOrderedSet *tmpOrderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:[self attachments]];
    [tmpOrderedSet removeObjectAtIndex:idx];
    [self setPrimitiveValue:tmpOrderedSet forKey:@"attachments"];
    [self didChange:NSKeyValueChangeRemoval valuesAtIndexes:indexes forKey:@"attachments"];
}
- (void)insertAttachments:(NSArray *)value atIndexes:(NSIndexSet *)indexes {
    [self willChange:NSKeyValueChangeInsertion valuesAtIndexes:indexes forKey:@"attachments"];
    NSMutableOrderedSet *tmpOrderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:[self attachments]];
    [tmpOrderedSet insertObjects:value atIndexes:indexes];
    [self setPrimitiveValue:tmpOrderedSet forKey:@"attachments"];
    [self didChange:NSKeyValueChangeInsertion valuesAtIndexes:indexes forKey:@"attachments"];
}
- (void)removeAttachmentsAtIndexes:(NSIndexSet *)indexes {
    [self willChange:NSKeyValueChangeRemoval valuesAtIndexes:indexes forKey:@"attachments"];
    NSMutableOrderedSet *tmpOrderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:[self attachments]];
    [tmpOrderedSet removeObjectsAtIndexes:indexes];
    [self setPrimitiveValue:tmpOrderedSet forKey:@"attachments"];
    [self didChange:NSKeyValueChangeRemoval valuesAtIndexes:indexes forKey:@"attachments"];
}
- (void)replaceObjectInAttachmentsAtIndex:(NSUInteger)idx withObject:(Attachment*)value {
    NSIndexSet* indexes = [NSIndexSet indexSetWithIndex:idx];
    [self willChange:NSKeyValueChangeReplacement valuesAtIndexes:indexes forKey:@"attachments"];
    NSMutableOrderedSet *tmpOrderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:[self attachments]];
    [tmpOrderedSet replaceObjectAtIndex:idx withObject:value];
    [self setPrimitiveValue:tmpOrderedSet forKey:@"attachments"];
    [self didChange:NSKeyValueChangeReplacement valuesAtIndexes:indexes forKey:@"attachments"];
}
- (void)replaceAttachmentsAtIndexes:(NSIndexSet *)indexes withAttachments:(NSArray *)value {
    [self willChange:NSKeyValueChangeReplacement valuesAtIndexes:indexes forKey:@"attachments"];
    NSMutableOrderedSet *tmpOrderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:[self attachments]];
    [tmpOrderedSet replaceObjectsAtIndexes:indexes withObjects:value];
    [self setPrimitiveValue:tmpOrderedSet forKey:@"attachments"];
    [self didChange:NSKeyValueChangeReplacement valuesAtIndexes:indexes forKey:@"attachments"];
}
@end

@implementation _Message (BccCoreDataGeneratedAccessors)
- (void)addBcc:(NSOrderedSet<Contact*>*)value_ {
	[self.bccSet unionOrderedSet:value_];
}
- (void)removeBcc:(NSOrderedSet<Contact*>*)value_ {
	[self.bccSet minusOrderedSet:value_];
}
- (void)addBccObject:(Contact*)value_ {
	[self.bccSet addObject:value_];
}
- (void)removeBccObject:(Contact*)value_ {
	[self.bccSet removeObject:value_];
}
- (void)insertObject:(Contact*)value inBccAtIndex:(NSUInteger)idx {
    NSIndexSet* indexes = [NSIndexSet indexSetWithIndex:idx];
    [self willChange:NSKeyValueChangeInsertion valuesAtIndexes:indexes forKey:@"bcc"];
    NSMutableOrderedSet *tmpOrderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:[self bcc]];
    [tmpOrderedSet insertObject:value atIndex:idx];
    [self setPrimitiveValue:tmpOrderedSet forKey:@"bcc"];
    [self didChange:NSKeyValueChangeInsertion valuesAtIndexes:indexes forKey:@"bcc"];
}
- (void)removeObjectFromBccAtIndex:(NSUInteger)idx {
    NSIndexSet* indexes = [NSIndexSet indexSetWithIndex:idx];
    [self willChange:NSKeyValueChangeRemoval valuesAtIndexes:indexes forKey:@"bcc"];
    NSMutableOrderedSet *tmpOrderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:[self bcc]];
    [tmpOrderedSet removeObjectAtIndex:idx];
    [self setPrimitiveValue:tmpOrderedSet forKey:@"bcc"];
    [self didChange:NSKeyValueChangeRemoval valuesAtIndexes:indexes forKey:@"bcc"];
}
- (void)insertBcc:(NSArray *)value atIndexes:(NSIndexSet *)indexes {
    [self willChange:NSKeyValueChangeInsertion valuesAtIndexes:indexes forKey:@"bcc"];
    NSMutableOrderedSet *tmpOrderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:[self bcc]];
    [tmpOrderedSet insertObjects:value atIndexes:indexes];
    [self setPrimitiveValue:tmpOrderedSet forKey:@"bcc"];
    [self didChange:NSKeyValueChangeInsertion valuesAtIndexes:indexes forKey:@"bcc"];
}
- (void)removeBccAtIndexes:(NSIndexSet *)indexes {
    [self willChange:NSKeyValueChangeRemoval valuesAtIndexes:indexes forKey:@"bcc"];
    NSMutableOrderedSet *tmpOrderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:[self bcc]];
    [tmpOrderedSet removeObjectsAtIndexes:indexes];
    [self setPrimitiveValue:tmpOrderedSet forKey:@"bcc"];
    [self didChange:NSKeyValueChangeRemoval valuesAtIndexes:indexes forKey:@"bcc"];
}
- (void)replaceObjectInBccAtIndex:(NSUInteger)idx withObject:(Contact*)value {
    NSIndexSet* indexes = [NSIndexSet indexSetWithIndex:idx];
    [self willChange:NSKeyValueChangeReplacement valuesAtIndexes:indexes forKey:@"bcc"];
    NSMutableOrderedSet *tmpOrderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:[self bcc]];
    [tmpOrderedSet replaceObjectAtIndex:idx withObject:value];
    [self setPrimitiveValue:tmpOrderedSet forKey:@"bcc"];
    [self didChange:NSKeyValueChangeReplacement valuesAtIndexes:indexes forKey:@"bcc"];
}
- (void)replaceBccAtIndexes:(NSIndexSet *)indexes withBcc:(NSArray *)value {
    [self willChange:NSKeyValueChangeReplacement valuesAtIndexes:indexes forKey:@"bcc"];
    NSMutableOrderedSet *tmpOrderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:[self bcc]];
    [tmpOrderedSet replaceObjectsAtIndexes:indexes withObjects:value];
    [self setPrimitiveValue:tmpOrderedSet forKey:@"bcc"];
    [self didChange:NSKeyValueChangeReplacement valuesAtIndexes:indexes forKey:@"bcc"];
}
@end

@implementation _Message (CcCoreDataGeneratedAccessors)
- (void)addCc:(NSOrderedSet<Contact*>*)value_ {
	[self.ccSet unionOrderedSet:value_];
}
- (void)removeCc:(NSOrderedSet<Contact*>*)value_ {
	[self.ccSet minusOrderedSet:value_];
}
- (void)addCcObject:(Contact*)value_ {
	[self.ccSet addObject:value_];
}
- (void)removeCcObject:(Contact*)value_ {
	[self.ccSet removeObject:value_];
}
- (void)insertObject:(Contact*)value inCcAtIndex:(NSUInteger)idx {
    NSIndexSet* indexes = [NSIndexSet indexSetWithIndex:idx];
    [self willChange:NSKeyValueChangeInsertion valuesAtIndexes:indexes forKey:@"cc"];
    NSMutableOrderedSet *tmpOrderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:[self cc]];
    [tmpOrderedSet insertObject:value atIndex:idx];
    [self setPrimitiveValue:tmpOrderedSet forKey:@"cc"];
    [self didChange:NSKeyValueChangeInsertion valuesAtIndexes:indexes forKey:@"cc"];
}
- (void)removeObjectFromCcAtIndex:(NSUInteger)idx {
    NSIndexSet* indexes = [NSIndexSet indexSetWithIndex:idx];
    [self willChange:NSKeyValueChangeRemoval valuesAtIndexes:indexes forKey:@"cc"];
    NSMutableOrderedSet *tmpOrderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:[self cc]];
    [tmpOrderedSet removeObjectAtIndex:idx];
    [self setPrimitiveValue:tmpOrderedSet forKey:@"cc"];
    [self didChange:NSKeyValueChangeRemoval valuesAtIndexes:indexes forKey:@"cc"];
}
- (void)insertCc:(NSArray *)value atIndexes:(NSIndexSet *)indexes {
    [self willChange:NSKeyValueChangeInsertion valuesAtIndexes:indexes forKey:@"cc"];
    NSMutableOrderedSet *tmpOrderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:[self cc]];
    [tmpOrderedSet insertObjects:value atIndexes:indexes];
    [self setPrimitiveValue:tmpOrderedSet forKey:@"cc"];
    [self didChange:NSKeyValueChangeInsertion valuesAtIndexes:indexes forKey:@"cc"];
}
- (void)removeCcAtIndexes:(NSIndexSet *)indexes {
    [self willChange:NSKeyValueChangeRemoval valuesAtIndexes:indexes forKey:@"cc"];
    NSMutableOrderedSet *tmpOrderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:[self cc]];
    [tmpOrderedSet removeObjectsAtIndexes:indexes];
    [self setPrimitiveValue:tmpOrderedSet forKey:@"cc"];
    [self didChange:NSKeyValueChangeRemoval valuesAtIndexes:indexes forKey:@"cc"];
}
- (void)replaceObjectInCcAtIndex:(NSUInteger)idx withObject:(Contact*)value {
    NSIndexSet* indexes = [NSIndexSet indexSetWithIndex:idx];
    [self willChange:NSKeyValueChangeReplacement valuesAtIndexes:indexes forKey:@"cc"];
    NSMutableOrderedSet *tmpOrderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:[self cc]];
    [tmpOrderedSet replaceObjectAtIndex:idx withObject:value];
    [self setPrimitiveValue:tmpOrderedSet forKey:@"cc"];
    [self didChange:NSKeyValueChangeReplacement valuesAtIndexes:indexes forKey:@"cc"];
}
- (void)replaceCcAtIndexes:(NSIndexSet *)indexes withCc:(NSArray *)value {
    [self willChange:NSKeyValueChangeReplacement valuesAtIndexes:indexes forKey:@"cc"];
    NSMutableOrderedSet *tmpOrderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:[self cc]];
    [tmpOrderedSet replaceObjectsAtIndexes:indexes withObjects:value];
    [self setPrimitiveValue:tmpOrderedSet forKey:@"cc"];
    [self didChange:NSKeyValueChangeReplacement valuesAtIndexes:indexes forKey:@"cc"];
}
@end

@implementation _Message (ReferencesCoreDataGeneratedAccessors)
- (void)addReferences:(NSOrderedSet<MessageReference*>*)value_ {
	[self.referencesSet unionOrderedSet:value_];
}
- (void)removeReferences:(NSOrderedSet<MessageReference*>*)value_ {
	[self.referencesSet minusOrderedSet:value_];
}
- (void)addReferencesObject:(MessageReference*)value_ {
	[self.referencesSet addObject:value_];
}
- (void)removeReferencesObject:(MessageReference*)value_ {
	[self.referencesSet removeObject:value_];
}
- (void)insertObject:(MessageReference*)value inReferencesAtIndex:(NSUInteger)idx {
    NSIndexSet* indexes = [NSIndexSet indexSetWithIndex:idx];
    [self willChange:NSKeyValueChangeInsertion valuesAtIndexes:indexes forKey:@"references"];
    NSMutableOrderedSet *tmpOrderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:[self references]];
    [tmpOrderedSet insertObject:value atIndex:idx];
    [self setPrimitiveValue:tmpOrderedSet forKey:@"references"];
    [self didChange:NSKeyValueChangeInsertion valuesAtIndexes:indexes forKey:@"references"];
}
- (void)removeObjectFromReferencesAtIndex:(NSUInteger)idx {
    NSIndexSet* indexes = [NSIndexSet indexSetWithIndex:idx];
    [self willChange:NSKeyValueChangeRemoval valuesAtIndexes:indexes forKey:@"references"];
    NSMutableOrderedSet *tmpOrderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:[self references]];
    [tmpOrderedSet removeObjectAtIndex:idx];
    [self setPrimitiveValue:tmpOrderedSet forKey:@"references"];
    [self didChange:NSKeyValueChangeRemoval valuesAtIndexes:indexes forKey:@"references"];
}
- (void)insertReferences:(NSArray *)value atIndexes:(NSIndexSet *)indexes {
    [self willChange:NSKeyValueChangeInsertion valuesAtIndexes:indexes forKey:@"references"];
    NSMutableOrderedSet *tmpOrderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:[self references]];
    [tmpOrderedSet insertObjects:value atIndexes:indexes];
    [self setPrimitiveValue:tmpOrderedSet forKey:@"references"];
    [self didChange:NSKeyValueChangeInsertion valuesAtIndexes:indexes forKey:@"references"];
}
- (void)removeReferencesAtIndexes:(NSIndexSet *)indexes {
    [self willChange:NSKeyValueChangeRemoval valuesAtIndexes:indexes forKey:@"references"];
    NSMutableOrderedSet *tmpOrderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:[self references]];
    [tmpOrderedSet removeObjectsAtIndexes:indexes];
    [self setPrimitiveValue:tmpOrderedSet forKey:@"references"];
    [self didChange:NSKeyValueChangeRemoval valuesAtIndexes:indexes forKey:@"references"];
}
- (void)replaceObjectInReferencesAtIndex:(NSUInteger)idx withObject:(MessageReference*)value {
    NSIndexSet* indexes = [NSIndexSet indexSetWithIndex:idx];
    [self willChange:NSKeyValueChangeReplacement valuesAtIndexes:indexes forKey:@"references"];
    NSMutableOrderedSet *tmpOrderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:[self references]];
    [tmpOrderedSet replaceObjectAtIndex:idx withObject:value];
    [self setPrimitiveValue:tmpOrderedSet forKey:@"references"];
    [self didChange:NSKeyValueChangeReplacement valuesAtIndexes:indexes forKey:@"references"];
}
- (void)replaceReferencesAtIndexes:(NSIndexSet *)indexes withReferences:(NSArray *)value {
    [self willChange:NSKeyValueChangeReplacement valuesAtIndexes:indexes forKey:@"references"];
    NSMutableOrderedSet *tmpOrderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:[self references]];
    [tmpOrderedSet replaceObjectsAtIndexes:indexes withObjects:value];
    [self setPrimitiveValue:tmpOrderedSet forKey:@"references"];
    [self didChange:NSKeyValueChangeReplacement valuesAtIndexes:indexes forKey:@"references"];
}
@end

@implementation _Message (ToCoreDataGeneratedAccessors)
- (void)addTo:(NSOrderedSet<Contact*>*)value_ {
	[self.toSet unionOrderedSet:value_];
}
- (void)removeTo:(NSOrderedSet<Contact*>*)value_ {
	[self.toSet minusOrderedSet:value_];
}
- (void)addToObject:(Contact*)value_ {
	[self.toSet addObject:value_];
}
- (void)removeToObject:(Contact*)value_ {
	[self.toSet removeObject:value_];
}
- (void)insertObject:(Contact*)value inToAtIndex:(NSUInteger)idx {
    NSIndexSet* indexes = [NSIndexSet indexSetWithIndex:idx];
    [self willChange:NSKeyValueChangeInsertion valuesAtIndexes:indexes forKey:@"to"];
    NSMutableOrderedSet *tmpOrderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:[self to]];
    [tmpOrderedSet insertObject:value atIndex:idx];
    [self setPrimitiveValue:tmpOrderedSet forKey:@"to"];
    [self didChange:NSKeyValueChangeInsertion valuesAtIndexes:indexes forKey:@"to"];
}
- (void)removeObjectFromToAtIndex:(NSUInteger)idx {
    NSIndexSet* indexes = [NSIndexSet indexSetWithIndex:idx];
    [self willChange:NSKeyValueChangeRemoval valuesAtIndexes:indexes forKey:@"to"];
    NSMutableOrderedSet *tmpOrderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:[self to]];
    [tmpOrderedSet removeObjectAtIndex:idx];
    [self setPrimitiveValue:tmpOrderedSet forKey:@"to"];
    [self didChange:NSKeyValueChangeRemoval valuesAtIndexes:indexes forKey:@"to"];
}
- (void)insertTo:(NSArray *)value atIndexes:(NSIndexSet *)indexes {
    [self willChange:NSKeyValueChangeInsertion valuesAtIndexes:indexes forKey:@"to"];
    NSMutableOrderedSet *tmpOrderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:[self to]];
    [tmpOrderedSet insertObjects:value atIndexes:indexes];
    [self setPrimitiveValue:tmpOrderedSet forKey:@"to"];
    [self didChange:NSKeyValueChangeInsertion valuesAtIndexes:indexes forKey:@"to"];
}
- (void)removeToAtIndexes:(NSIndexSet *)indexes {
    [self willChange:NSKeyValueChangeRemoval valuesAtIndexes:indexes forKey:@"to"];
    NSMutableOrderedSet *tmpOrderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:[self to]];
    [tmpOrderedSet removeObjectsAtIndexes:indexes];
    [self setPrimitiveValue:tmpOrderedSet forKey:@"to"];
    [self didChange:NSKeyValueChangeRemoval valuesAtIndexes:indexes forKey:@"to"];
}
- (void)replaceObjectInToAtIndex:(NSUInteger)idx withObject:(Contact*)value {
    NSIndexSet* indexes = [NSIndexSet indexSetWithIndex:idx];
    [self willChange:NSKeyValueChangeReplacement valuesAtIndexes:indexes forKey:@"to"];
    NSMutableOrderedSet *tmpOrderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:[self to]];
    [tmpOrderedSet replaceObjectAtIndex:idx withObject:value];
    [self setPrimitiveValue:tmpOrderedSet forKey:@"to"];
    [self didChange:NSKeyValueChangeReplacement valuesAtIndexes:indexes forKey:@"to"];
}
- (void)replaceToAtIndexes:(NSIndexSet *)indexes withTo:(NSArray *)value {
    [self willChange:NSKeyValueChangeReplacement valuesAtIndexes:indexes forKey:@"to"];
    NSMutableOrderedSet *tmpOrderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:[self to]];
    [tmpOrderedSet replaceObjectsAtIndexes:indexes withObjects:value];
    [self setPrimitiveValue:tmpOrderedSet forKey:@"to"];
    [self didChange:NSKeyValueChangeReplacement valuesAtIndexes:indexes forKey:@"to"];
}
@end

@implementation MessageAttributes 
+ (NSString *)bodyFetched {
	return @"bodyFetched";
}
+ (NSString *)boundary {
	return @"boundary";
}
+ (NSString *)contentType {
	return @"contentType";
}
+ (NSString *)flagAnswered {
	return @"flagAnswered";
}
+ (NSString *)flagDeleted {
	return @"flagDeleted";
}
+ (NSString *)flagDraft {
	return @"flagDraft";
}
+ (NSString *)flagFlagged {
	return @"flagFlagged";
}
+ (NSString *)flagRecent {
	return @"flagRecent";
}
+ (NSString *)flagSeen {
	return @"flagSeen";
}
+ (NSString *)flags {
	return @"flags";
}
+ (NSString *)flagsFromServer {
	return @"flagsFromServer";
}
+ (NSString *)longMessage {
	return @"longMessage";
}
+ (NSString *)longMessageFormatted {
	return @"longMessageFormatted";
}
+ (NSString *)messageID {
	return @"messageID";
}
+ (NSString *)messageNumber {
	return @"messageNumber";
}
+ (NSString *)pepColorRating {
	return @"pepColorRating";
}
+ (NSString *)receivedDate {
	return @"receivedDate";
}
+ (NSString *)subject {
	return @"subject";
}
+ (NSString *)uid {
	return @"uid";
}
@end

@implementation MessageRelationships 
+ (NSString *)attachments {
	return @"attachments";
}
+ (NSString *)bcc {
	return @"bcc";
}
+ (NSString *)cc {
	return @"cc";
}
+ (NSString *)folder {
	return @"folder";
}
+ (NSString *)from {
	return @"from";
}
+ (NSString *)messageReference {
	return @"messageReference";
}
+ (NSString *)references {
	return @"references";
}
+ (NSString *)to {
	return @"to";
}
@end

