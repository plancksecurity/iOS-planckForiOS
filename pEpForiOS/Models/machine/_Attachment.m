// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Attachment.m instead.

#import "_Attachment.h"

@implementation AttachmentID
@end

@implementation _Attachment

+ (instancetype)insertInManagedObjectContext:(NSManagedObjectContext *)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"Attachment" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"Attachment";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"Attachment" inManagedObjectContext:moc_];
}

- (AttachmentID*)objectID {
	return (AttachmentID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];

	if ([key isEqualToString:@"sizeValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"size"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}

	return keyPaths;
}

@dynamic contentType;

@dynamic data;

@dynamic filename;

@dynamic size;

- (int64_t)sizeValue {
	NSNumber *result = [self size];
	return [result longLongValue];
}

- (void)setSizeValue:(int64_t)value_ {
	[self setSize:@(value_)];
}

- (int64_t)primitiveSizeValue {
	NSNumber *result = [self primitiveSize];
	return [result longLongValue];
}

- (void)setPrimitiveSizeValue:(int64_t)value_ {
	[self setPrimitiveSize:@(value_)];
}

@dynamic message;

@end

@implementation AttachmentAttributes 
+ (NSString *)contentType {
	return @"contentType";
}
+ (NSString *)data {
	return @"data";
}
+ (NSString *)filename {
	return @"filename";
}
+ (NSString *)size {
	return @"size";
}
@end

@implementation AttachmentRelationships 
+ (NSString *)message {
	return @"message";
}
@end

