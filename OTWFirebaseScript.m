// SPDX-License-Identifier: AGPL-3.0-or-later
//
// OTWFirebaseScript.m - A component that adds Firebase scripts
// Copyright (C) 2026 Graham Lee
//

#import "OTWFirebaseScript.h"

@implementation OTWFirebaseScript

- (void)appendToResponse:(WOResponse *)response inContext:(WOContext *)context {
    NSString *url = [[context application] urlForResourceNamed:@"FirebaseAuth.js"
                                                   inFramework:nil
                                                     languages:[context languages]
                                                       request:[context request]];
    NSString *scripts = [NSString stringWithFormat:
        @"<script src=\"https://www.gstatic.com/firebasejs/10.8.0/firebase-app-compat.js\"></script>\n"
        @"<script src=\"https://www.gstatic.com/firebasejs/10.8.0/firebase-auth-compat.js\"></script>\n"
        @"<script src=\"https://www.gstatic.com/firebasejs/10.8.0/firebase-storage-compat.js\"></script>\n"
        @"<script src=\"%@\"></script>\n", url];
    [response appendContentString:scripts];
}

@end
