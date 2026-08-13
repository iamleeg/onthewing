// SPDX-License-Identifier: AGPL-3.0-or-later
// OTWRedirect.h

#import <WebObjects/WOComponent.h>

@interface OTWRedirect : WOComponent {
    NSString *_url;
}

@property (nonatomic, copy) NSString *url;

@end
