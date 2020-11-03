//
//  NSString+Markdown.h
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 16.08.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

#ifndef NSString_Markdown_h
#define NSString_Markdown_h

@interface NSString (Markdown)

/**
 Assuming that this NSString is markdown, parse and convert that to HTML.
 */
- (nullable NSString *)nsMarkdownToHtml;
- (nullable NSString *)convertLinesAndParagraphsToHtmlTags;

@end


#endif /* NSString_Markdown_h */
