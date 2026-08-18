#import <Foundation/Foundation.h>

@interface MockURLProtocol : NSURLProtocol
+ (void)setResponseData:(NSData *)data;
+ (void)setResponseError:(NSError *)error;
+ (void)setResponseStatusCode:(NSInteger)statusCode;
+ (NSMutableArray *)requests;
+ (void)clearMocks;
@end
