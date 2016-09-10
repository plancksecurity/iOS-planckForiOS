// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Contact.m instead.

#import "_Contact.h"

@implementation ContactID
@end

@implementation _Contact

+ (instancetype)insertInManagedObjectContext:(NSManagedObjectContext *)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"Contact" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"Contact";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"Contact" inManagedObjectContext:moc_];
}

- (ContactID*)objectID {
	return (ContactID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];

	if ([key isEqualToString:@"addressBookIDValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"addressBookID"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}
	if ([key isEqualToString:@"isMySelfValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"isMySelf"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}

	return keyPaths;
}

@dynamic addressBookID;

- (int32_t)addressBookIDValue {
	NSNumber *result = [self addressBookID];
	return [result intValue];
}

- (void)setAddressBookIDValue:(int32_t)value_ {
	[self setAddressBookID:@(value_)];
}

- (int32_t)primitiveAddressBookIDValue {
	NSNumber *result = [self primitiveAddressBookID];
	return [result intValue];
}

- (void)setPrimitiveAddressBookIDValue:(int32_t)value_ {
	[self setPrimitiveAddressBookID:@(value_)];
}

@dynamic email;

@dynamic isMySelf;

- (BOOL)isMySelfValue {
	NSNumber *result = [self isMySelf];
	return [result boolValue];
}

- (void)setIsMySelfValue:(BOOL)value_ {
	[self setIsMySelf:@(value_)];
}

- (BOOL)primitiveIsMySelfValue {
	NSNumber *result = [self primitiveIsMySelf];
	return [result boolValue];
}

- (void)setPrimitiveIsMySelfValue:(BOOL)value_ {
	[self setPrimitiveIsMySelf:@(value_)];
}

@dynamic name;

@dynamic pepUserID;

@dynamic bccMessages;

- (NSMutableSet<Message*>*)bccMessagesSet {
	[self willAccessValueForKey:@"bccMessages"];

	NSMutableSet<Message*> *result = (NSMutableSet<Message*>*)[self mutableSetValueForKey:@"bccMessages"];

	[self didAccessValueForKey:@"bccMessages"];
	return result;
}

@dynamic ccMessages;

- (NSMutableSet<Message*>*)ccMessagesSet {
	[self willAccessValueForKey:@"ccMessages"];

	NSMutableSet<Message*> *result = (NSMutableSet<Message*>*)[self mutableSetValueForKey:@"ccMessages"];

	[self didAccessValueForKey:@"ccMessages"];
	return result;
}

@dynamic fromMessages;

- (NSMutableSet<Message*>*)fromMessagesSet {
	[self willAccessValueForKey:@"fromMessages"];

	NSMutableSet<Message*> *result = (NSMutableSet<Message*>*)[self mutableSetValueForKey:@"fromMessages"];

	[self didAccessValueForKey:@"fromMessages"];
	return result;
}

@dynamic toMessages;

- (NSMutableSet<Message*>*)toMessagesSet {
	[self willAccessValueForKey:@"toMessages"];

	NSMutableSet<Message*> *result = (NSMutableSet<Message*>*)[self mutableSetValueForKey:@"toMessages"];

	[self didAccessValueForKey:@"toMessages"];
	return result;
}

@end

@implementation ContactAttributes 
+ (NSString *)addressBookID {
	return @"addressBookID";
}
+ (NSString *)email {
	return @"email";
}
+ (NSString *)isMySelf {
	return @"isMySelf";
}
+ (NSString *)name {
	return @"name";
}
+ (NSString *)pepUserID {
	return @"pepUserID";
}
@end

@implementation ContactRelationships 
+ (NSString *)bccMessages {
	return @"bccMessages";
}
+ (NSString *)ccMessages {
	return @"ccMessages";
}
+ (NSString *)fromMessages {
	return @"fromMessages";
}
+ (NSString *)toMessages {
	return @"toMessages";
}
@end

