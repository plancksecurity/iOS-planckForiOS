//
//  NSString+Markdown.m
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 16.08.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "cmark.h"

#import "NSString+Markdown.h"

@implementation NSString (Markdown)

- (NSString *)nsMarkdownToHtml {
    const char* utf8Chars = [[self convertLinesAndParagraphsToHtmlTags] cStringUsingEncoding:NSUTF8StringEncoding];
    size_t len = strlen(utf8Chars);
    char *htmlBytes = cmark_markdown_to_html(utf8Chars, len, 0);
    if (strlen(htmlBytes) > 0) {
        NSString *resultString = [NSString
                                  stringWithCString:htmlBytes encoding:NSUTF8StringEncoding];
        free(htmlBytes);
        return [resultString stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    }
    return nil;
}

/// Private function to convert lines and tabs to html tags. For example \n and \t
- (NSString *)convertLinesAndParagraphsToHtmlTags {
    const NSDictionary* convertFromTo = @{@"\n" : @"<br>",
                                          @"\t" : @"&emsp;"};

    NSString* converted = [[NSMutableString alloc] initWithString:self];
    for (NSString * key in convertFromTo) {
        converted = [converted stringByReplacingOccurrencesOfString:key withString:convertFromTo[key]];
    }

    return [[NSString alloc] initWithString:converted];
}

@end
