// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Folder.m instead.

#import "_Folder.h"

@implementation FolderID
@end

@implementation _Folder

+ (instancetype)insertInManagedObjectContext:(NSManagedObjectContext *)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"Folder" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"Folder";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"Folder" inManagedObjectContext:moc_];
}

- (FolderID*)objectID {
	return (FolderID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];

	if ([key isEqualToString:@"existsCountValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"existsCount"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}
	if ([key isEqualToString:@"folderTypeValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"folderType"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}
	if ([key isEqualToString:@"nextUIDValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"nextUID"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}
	if ([key isEqualToString:@"uidValidityValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"uidValidity"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}

	return keyPaths;
}

@dynamic existsCount;

- (uint64_t)existsCountValue {
	NSNumber *result = [self existsCount];
	return [result unsignedLongLongValue];
}

- (void)setExistsCountValue:(uint64_t)value_ {
	[self setExistsCount:@(value_)];
}

- (uint64_t)primitiveExistsCountValue {
	NSNumber *result = [self primitiveExistsCount];
	return [result unsignedLongLongValue];
}

- (void)setPrimitiveExistsCountValue:(uint64_t)value_ {
	[self setPrimitiveExistsCount:@(value_)];
}

@dynamic folderType;

- (int16_t)folderTypeValue {
	NSNumber *result = [self folderType];
	return [result shortValue];
}

- (void)setFolderTypeValue:(int16_t)value_ {
	[self setFolderType:@(value_)];
}

- (int16_t)primitiveFolderTypeValue {
	NSNumber *result = [self primitiveFolderType];
	return [result shortValue];
}

- (void)setPrimitiveFolderTypeValue:(int16_t)value_ {
	[self setPrimitiveFolderType:@(value_)];
}

@dynamic name;

@dynamic nextUID;

- (uint64_t)nextUIDValue {
	NSNumber *result = [self nextUID];
	return [result unsignedLongLongValue];
}

- (void)setNextUIDValue:(uint64_t)value_ {
	[self setNextUID:@(value_)];
}

- (uint64_t)primitiveNextUIDValue {
	NSNumber *result = [self primitiveNextUID];
	return [result unsignedLongLongValue];
}

- (void)setPrimitiveNextUIDValue:(uint64_t)value_ {
	[self setPrimitiveNextUID:@(value_)];
}

@dynamic uidValidity;

- (int64_t)uidValidityValue {
	NSNumber *result = [self uidValidity];
	return [result longLongValue];
}

- (void)setUidValidityValue:(int64_t)value_ {
	[self setUidValidity:@(value_)];
}

- (int64_t)primitiveUidValidityValue {
	NSNumber *result = [self primitiveUidValidity];
	return [result longLongValue];
}

- (void)setPrimitiveUidValidityValue:(int64_t)value_ {
	[self setPrimitiveUidValidity:@(value_)];
}

@dynamic account;

@dynamic children;

- (NSMutableOrderedSet<Folder*>*)childrenSet {
	[self willAccessValueForKey:@"children"];

	NSMutableOrderedSet<Folder*> *result = (NSMutableOrderedSet<Folder*>*)[self mutableOrderedSetValueForKey:@"children"];

	[self didAccessValueForKey:@"children"];
	return result;
}

@dynamic messages;

- (NSMutableSet<Message*>*)messagesSet {
	[self willAccessValueForKey:@"messages"];

	NSMutableSet<Message*> *result = (NSMutableSet<Message*>*)[self mutableSetValueForKey:@"messages"];

	[self didAccessValueForKey:@"messages"];
	return result;
}

@dynamic parent;

@end

@implementation _Folder (ChildrenCoreDataGeneratedAccessors)
- (void)addChildren:(NSOrderedSet<Folder*>*)value_ {
	[self.childrenSet unionOrderedSet:value_];
}
- (void)removeChildren:(NSOrderedSet<Folder*>*)value_ {
	[self.childrenSet minusOrderedSet:value_];
}
- (void)addChildrenObject:(Folder*)value_ {
	[self.childrenSet addObject:value_];
}
- (void)removeChildrenObject:(Folder*)value_ {
	[self.childrenSet removeObject:value_];
}
- (void)insertObject:(Folder*)value inChildrenAtIndex:(NSUInteger)idx {
    NSIndexSet* indexes = [NSIndexSet indexSetWithIndex:idx];
    [self willChange:NSKeyValueChangeInsertion valuesAtIndexes:indexes forKey:@"children"];
    NSMutableOrderedSet *tmpOrderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:[self children]];
    [tmpOrderedSet insertObject:value atIndex:idx];
    [self setPrimitiveValue:tmpOrderedSet forKey:@"children"];
    [self didChange:NSKeyValueChangeInsertion valuesAtIndexes:indexes forKey:@"children"];
}
- (void)removeObjectFromChildrenAtIndex:(NSUInteger)idx {
    NSIndexSet* indexes = [NSIndexSet indexSetWithIndex:idx];
    [self willChange:NSKeyValueChangeRemoval valuesAtIndexes:indexes forKey:@"children"];
    NSMutableOrderedSet *tmpOrderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:[self children]];
    [tmpOrderedSet removeObjectAtIndex:idx];
    [self setPrimitiveValue:tmpOrderedSet forKey:@"children"];
    [self didChange:NSKeyValueChangeRemoval valuesAtIndexes:indexes forKey:@"children"];
}
- (void)insertChildren:(NSArray *)value atIndexes:(NSIndexSet *)indexes {
    [self willChange:NSKeyValueChangeInsertion valuesAtIndexes:indexes forKey:@"children"];
    NSMutableOrderedSet *tmpOrderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:[self children]];
    [tmpOrderedSet insertObjects:value atIndexes:indexes];
    [self setPrimitiveValue:tmpOrderedSet forKey:@"children"];
    [self didChange:NSKeyValueChangeInsertion valuesAtIndexes:indexes forKey:@"children"];
}
- (void)removeChildrenAtIndexes:(NSIndexSet *)indexes {
    [self willChange:NSKeyValueChangeRemoval valuesAtIndexes:indexes forKey:@"children"];
    NSMutableOrderedSet *tmpOrderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:[self children]];
    [tmpOrderedSet removeObjectsAtIndexes:indexes];
    [self setPrimitiveValue:tmpOrderedSet forKey:@"children"];
    [self didChange:NSKeyValueChangeRemoval valuesAtIndexes:indexes forKey:@"children"];
}
- (void)replaceObjectInChildrenAtIndex:(NSUInteger)idx withObject:(Folder*)value {
    NSIndexSet* indexes = [NSIndexSet indexSetWithIndex:idx];
    [self willChange:NSKeyValueChangeReplacement valuesAtIndexes:indexes forKey:@"children"];
    NSMutableOrderedSet *tmpOrderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:[self children]];
    [tmpOrderedSet replaceObjectAtIndex:idx withObject:value];
    [self setPrimitiveValue:tmpOrderedSet forKey:@"children"];
    [self didChange:NSKeyValueChangeReplacement valuesAtIndexes:indexes forKey:@"children"];
}
- (void)replaceChildrenAtIndexes:(NSIndexSet *)indexes withChildren:(NSArray *)value {
    [self willChange:NSKeyValueChangeReplacement valuesAtIndexes:indexes forKey:@"children"];
    NSMutableOrderedSet *tmpOrderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:[self children]];
    [tmpOrderedSet replaceObjectsAtIndexes:indexes withObjects:value];
    [self setPrimitiveValue:tmpOrderedSet forKey:@"children"];
    [self didChange:NSKeyValueChangeReplacement valuesAtIndexes:indexes forKey:@"children"];
}
@end

@implementation FolderAttributes 
+ (NSString *)existsCount {
	return @"existsCount";
}
+ (NSString *)folderType {
	return @"folderType";
}
+ (NSString *)name {
	return @"name";
}
+ (NSString *)nextUID {
	return @"nextUID";
}
+ (NSString *)uidValidity {
	return @"uidValidity";
}
@end

@implementation FolderRelationships 
+ (NSString *)account {
	return @"account";
}
+ (NSString *)children {
	return @"children";
}
+ (NSString *)messages {
	return @"messages";
}
+ (NSString *)parent {
	return @"parent";
}
@end

