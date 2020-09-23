//
//  NSObject+EPWebSafe.m
//  pEp
//
//  Created by Martin Brude on 21/09/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSObject+EPWebSafe.h"
#import <objc/runtime.h>

#define object_getIvarValue(object, name) object_getIvar(object, class_getInstanceVariable([object class], name))
#define object_setIvarValue(object, name, value) object_setIvar(object, class_getInstanceVariable([object class], name), value)

CG_INLINE void
SwizzleMethod(Class _originClass, SEL _originSelector, Class _newClass, SEL _newSelector) {
    Method oriMethod = class_getInstanceMethod(_originClass, _originSelector);
    Method newMethod = class_getInstanceMethod(_newClass, _newSelector);
    BOOL isAddedMethod = class_addMethod(_originClass, _originSelector, method_getImplementation(newMethod), method_getTypeEncoding(newMethod));
    if (isAddedMethod) {
        class_replaceMethod(_originClass, _newSelector, method_getImplementation(oriMethod), method_getTypeEncoding(oriMethod));
    } else {
        method_exchangeImplementations(oriMethod, newMethod);
    }
}

@interface HtmlReleaseDelegateCleaner : NSObject
@property (nonatomic, strong) NSPointerArray *htmlDelegates;
@end

@implementation HtmlReleaseDelegateCleaner

- (void)dealloc {
    [self cleanHtmlDelegate];
}

- (void)recordHtmlDelegate:(id)htmlDelegate {
    NSUInteger index = [self.htmlDelegates.allObjects indexOfObject:htmlDelegate];
    if (index == NSNotFound) {
        [self.htmlDelegates addPointer:(__bridge void *)(htmlDelegate)];
    }
}

- (void)removeHtmlDelegate:(id )htmlDelegate {
    NSUInteger index = [self.htmlDelegates.allObjects indexOfObject:htmlDelegate];
    if (index != NSNotFound) {
        [self.htmlDelegates removePointerAtIndex:index];
    }
}

- (void)cleanHtmlDelegate {
    [self.htmlDelegates.allObjects enumerateObjectsUsingBlock:^(id htmlDelegate, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([htmlDelegate isKindOfClass:NSClassFromString(@"_WebSafeForwarder")]) {
            object_setIvarValue(htmlDelegate, "target", nil);
        }
    }];
}

- (void)setHtmlDelegates:(NSMutableSet *)htmlDelegates {
    objc_setAssociatedObject(self, @selector(htmlDelegates), htmlDelegates, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSPointerArray *)htmlDelegates {
    NSPointerArray *htmlDelegates = objc_getAssociatedObject(self, _cmd);
    if (!htmlDelegates) {
        htmlDelegates = [NSPointerArray weakObjectsPointerArray];
        [self setHtmlDelegates:htmlDelegates];
    }
    return htmlDelegates;
}

@end

@interface NSObject (EPWebSafe_Private)

@property (nonatomic, readonly) HtmlReleaseDelegateCleaner *webDelegateCleaner;

@end

@implementation NSObject (EPWebSafe)

- (HtmlReleaseDelegateCleaner *)webDelegateCleaner {
    HtmlReleaseDelegateCleaner *cleaner = objc_getAssociatedObject(self, _cmd);
    if (!cleaner) {
        cleaner = [HtmlReleaseDelegateCleaner new];
        objc_setAssociatedObject(self, _cmd, cleaner, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return cleaner;
}


+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
       SwizzleMethod(NSClassFromString(@"_WebSafeForwarder"), NSSelectorFromString(@"initWithTarget:defaultTarget:"), self, @selector(safe_initWithTarget:defaultTarget:));
    });
}

- (id)safe_initWithTarget:(id)arg1 defaultTarget:(id)arg2 {
    if ([NSStringFromClass([arg1 class]) isEqualToString:@"NSHTMLWebDelegate"]) {
        [[arg1 webDelegateCleaner] recordHtmlDelegate: self];
    }
    return [self safe_initWithTarget:arg1 defaultTarget:arg2];
}

@end



