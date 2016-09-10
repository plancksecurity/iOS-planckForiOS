// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Account.m instead.

#import "_Account.h"

@implementation AccountID
@end

@implementation _Account

+ (instancetype)insertInManagedObjectContext:(NSManagedObjectContext *)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"Account" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"Account";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"Account" inManagedObjectContext:moc_];
}

- (AccountID*)objectID {
	return (AccountID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];

	if ([key isEqualToString:@"accountTypeValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"accountType"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}
	if ([key isEqualToString:@"imapServerPortValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"imapServerPort"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}
	if ([key isEqualToString:@"imapTransportValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"imapTransport"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}
	if ([key isEqualToString:@"smtpServerPortValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"smtpServerPort"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}
	if ([key isEqualToString:@"smtpTransportValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"smtpTransport"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}

	return keyPaths;
}

@dynamic accountType;

- (int16_t)accountTypeValue {
	NSNumber *result = [self accountType];
	return [result shortValue];
}

- (void)setAccountTypeValue:(int16_t)value_ {
	[self setAccountType:@(value_)];
}

- (int16_t)primitiveAccountTypeValue {
	NSNumber *result = [self primitiveAccountType];
	return [result shortValue];
}

- (void)setPrimitiveAccountTypeValue:(int16_t)value_ {
	[self setPrimitiveAccountType:@(value_)];
}

@dynamic email;

@dynamic folderSeparator;

@dynamic imapServerName;

@dynamic imapServerPort;

- (int16_t)imapServerPortValue {
	NSNumber *result = [self imapServerPort];
	return [result shortValue];
}

- (void)setImapServerPortValue:(int16_t)value_ {
	[self setImapServerPort:@(value_)];
}

- (int16_t)primitiveImapServerPortValue {
	NSNumber *result = [self primitiveImapServerPort];
	return [result shortValue];
}

- (void)setPrimitiveImapServerPortValue:(int16_t)value_ {
	[self setPrimitiveImapServerPort:@(value_)];
}

@dynamic imapTransport;

- (int16_t)imapTransportValue {
	NSNumber *result = [self imapTransport];
	return [result shortValue];
}

- (void)setImapTransportValue:(int16_t)value_ {
	[self setImapTransport:@(value_)];
}

- (int16_t)primitiveImapTransportValue {
	NSNumber *result = [self primitiveImapTransport];
	return [result shortValue];
}

- (void)setPrimitiveImapTransportValue:(int16_t)value_ {
	[self setPrimitiveImapTransport:@(value_)];
}

@dynamic imapUsername;

@dynamic nameOfTheUser;

@dynamic smtpServerName;

@dynamic smtpServerPort;

- (int16_t)smtpServerPortValue {
	NSNumber *result = [self smtpServerPort];
	return [result shortValue];
}

- (void)setSmtpServerPortValue:(int16_t)value_ {
	[self setSmtpServerPort:@(value_)];
}

- (int16_t)primitiveSmtpServerPortValue {
	NSNumber *result = [self primitiveSmtpServerPort];
	return [result shortValue];
}

- (void)setPrimitiveSmtpServerPortValue:(int16_t)value_ {
	[self setPrimitiveSmtpServerPort:@(value_)];
}

@dynamic smtpTransport;

- (int16_t)smtpTransportValue {
	NSNumber *result = [self smtpTransport];
	return [result shortValue];
}

- (void)setSmtpTransportValue:(int16_t)value_ {
	[self setSmtpTransport:@(value_)];
}

- (int16_t)primitiveSmtpTransportValue {
	NSNumber *result = [self primitiveSmtpTransport];
	return [result shortValue];
}

- (void)setPrimitiveSmtpTransportValue:(int16_t)value_ {
	[self setPrimitiveSmtpTransport:@(value_)];
}

@dynamic smtpUsername;

@dynamic folders;

- (NSMutableSet<Folder*>*)foldersSet {
	[self willAccessValueForKey:@"folders"];

	NSMutableSet<Folder*> *result = (NSMutableSet<Folder*>*)[self mutableSetValueForKey:@"folders"];

	[self didAccessValueForKey:@"folders"];
	return result;
}

@end

@implementation AccountAttributes 
+ (NSString *)accountType {
	return @"accountType";
}
+ (NSString *)email {
	return @"email";
}
+ (NSString *)folderSeparator {
	return @"folderSeparator";
}
+ (NSString *)imapServerName {
	return @"imapServerName";
}
+ (NSString *)imapServerPort {
	return @"imapServerPort";
}
+ (NSString *)imapTransport {
	return @"imapTransport";
}
+ (NSString *)imapUsername {
	return @"imapUsername";
}
+ (NSString *)nameOfTheUser {
	return @"nameOfTheUser";
}
+ (NSString *)smtpServerName {
	return @"smtpServerName";
}
+ (NSString *)smtpServerPort {
	return @"smtpServerPort";
}
+ (NSString *)smtpTransport {
	return @"smtpTransport";
}
+ (NSString *)smtpUsername {
	return @"smtpUsername";
}
@end

@implementation AccountRelationships 
+ (NSString *)folders {
	return @"folders";
}
@end

