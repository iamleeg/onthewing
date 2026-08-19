// SPDX-License-Identifier: AGPL-3.0-or-later
#import "PublicPresentationPage.h"

@implementation PublicPresentationPage

@synthesize presentationView = _presentationView;
@synthesize currentPhoto = _currentPhoto;

- (void)setPresentationView:(PresentationView *)presentationView {
    [presentationView retain];
    [_presentationView autorelease];
    _presentationView = presentationView;
}

- (void)setCurrentPhoto:(NSString *)currentPhoto {
    NSString *newPhoto = [currentPhoto copy];
    [_currentPhoto autorelease];
    _currentPhoto = newPhoto;
}

- (BOOL)hasOpenGraphImage {
    return (self.presentationView.openGraphImage != nil && [self.presentationView.openGraphImage length] > 0);
}

- (BOOL)hasMapLocation {
    return (self.presentationView.mapLocation != nil && [self.presentationView.mapLocation length] > 0);
}

- (NSString *)blurClass {
    return self.presentationView.isTruncatedAndBlurred ? @"blur" : @"";
}

- (void)dealloc {
    [_presentationView release];
    [_currentPhoto release];
    [super dealloc];
}

@end
