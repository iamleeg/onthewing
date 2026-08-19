// SPDX-License-Identifier: AGPL-3.0-or-later
#import <WebObjects/WebObjects.h>
#import "PresentationView.h"

@interface PublicPresentationPage : WOComponent {
    PresentationView *_presentationView;
    NSString *_currentPhoto;
}

@property (nonatomic, retain) PresentationView *presentationView;
@property (nonatomic, copy) NSString *currentPhoto;

- (BOOL)hasOpenGraphImage;
- (BOOL)hasMapLocation;
- (NSString *)blurClass;

@end
