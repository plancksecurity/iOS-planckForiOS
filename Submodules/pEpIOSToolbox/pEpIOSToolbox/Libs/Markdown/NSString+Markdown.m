//
//  NSString+Markdown.m
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 16.08.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "NSString+Markdown.h"

#import "cmark.h"

@implementation NSString (Markdown)

- (NSString *)nsMarkdownToHtml
{
    const char* utf8Chars = [self cStringUsingEncoding:NSUTF8StringEncoding];
    size_t len = strlen(utf8Chars);
    char *htmlBytes = cmark_markdown_to_html(utf8Chars, len, 0);
    if (strlen(htmlBytes) > 0) {
        NSString *resultString = [NSString
                                  stringWithCString:htmlBytes encoding:NSUTF8StringEncoding];
        free(htmlBytes);
        return resultString;
    }
    return nil;
}

@end
