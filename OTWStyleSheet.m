// SPDX-License-Identifier: AGPL-3.0-or-later
#import "OTWStyleSheet.h"

@implementation OTWStyleSheet

- (void)appendToResponse:(WOResponse *)response inContext:(WOContext *)context {
    NSString *url = [[context application] urlForResourceNamed:self.stylesheetName
                                                   inFramework:nil
                                                     languages:[context languages]
                                                       request:[context request]];
    NSString *tag = [NSString stringWithFormat:@"<link rel=\"stylesheet\" href=\"%@\" type=\"text/css\" />", url];
    [response appendContentString:tag];
}

@end
