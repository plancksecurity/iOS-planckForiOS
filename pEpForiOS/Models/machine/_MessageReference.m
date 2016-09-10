// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to MessageReference.m instead.

#import "_MessageReference.h"

@implementation MessageReferenceID
@end

@implementation _MessageReference

+ (instancetype)insertInManagedObjectContext:(NSManagedObjectContext *)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"MessageReference" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"MessageReference";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"MessageReference" inManagedObjectContext:moc_];
}

- (MessageReferenceID*)objectID {
	return (MessageReferenceID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];

	return keyPaths;
}

@dynamic messageID;

@dynamic message;

@dynamic referencingMessages;

- (NSMutableSet<Message*>*)referencingMessagesSet {
	[self willAccessValueForKey:@"referencingMessages"];

	NSMutableSet<Message*> *result = (NSMutableSet<Message*>*)[self mutableSetValueForKey:@"referencingMessages"];

	[self didAccessValueForKey:@"referencingMessages"];
	return result;
}

@end

@implementation MessageReferenceAttributes 
+ (NSString *)messageID {
	return @"messageID";
}
@end

@implementation MessageReferenceRelationships 
+ (NSString *)message {
	return @"message";
}
+ (NSString *)referencingMessages {
	return @"referencingMessages";
}
@end

