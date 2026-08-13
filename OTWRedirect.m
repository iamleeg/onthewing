// SPDX-License-Identifier: AGPL-3.0-or-later
// OTWRedirect.m

#import "OTWRedirect.h"
#import <WebObjects/WOResponse.h>

@implementation OTWRedirect

@synthesize url = _url;

- (void)dealloc {
    [_url release];
    [super dealloc];
}

- (void)appendToResponse:(WOResponse *)response inContext:(WOContext *)context {
    [response setStatus:302];
    [response setHeader:self.url forKey:@"Location"];
    // Do not call super because we don't need a body.
}

@end
