#import "MockURLProtocol.h"

static NSData *mockData = nil;
static NSError *mockError = nil;
static NSInteger mockStatusCode = 200;
static NSMutableArray *recordedRequests = nil;

@implementation MockURLProtocol

+ (void)setResponseData:(NSData *)data {
    [mockData release];
    mockData = [data retain];
}

+ (void)setResponseError:(NSError *)error {
    [mockError release];
    mockError = [error retain];
}

+ (void)setResponseStatusCode:(NSInteger)statusCode {
    mockStatusCode = statusCode;
}

+ (NSMutableArray *)requests {
    if (!recordedRequests) {
        recordedRequests = [[NSMutableArray alloc] init];
    }
    return recordedRequests;
}

+ (void)clearMocks {
    [mockData release]; mockData = nil;
    [mockError release]; mockError = nil;
    mockStatusCode = 200;
    [recordedRequests release]; recordedRequests = nil;
}

+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
    return YES;
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
    return request;
}

- (void)startLoading {
    [[MockURLProtocol requests] addObject:self.request];
    
    if (mockError) {
        [self.client URLProtocol:self didFailWithError:mockError];
        return;
    }
    
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:[self.request URL] statusCode:mockStatusCode HTTPVersion:@"1.1" headerFields:nil];
    [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
    [response release];
    
    if (mockData) {
        [self.client URLProtocol:self didLoadData:mockData];
    }
    
    [self.client URLProtocolDidFinishLoading:self];
}

- (void)stopLoading {}

@end
