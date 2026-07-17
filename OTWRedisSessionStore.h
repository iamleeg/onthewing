#import <Foundation/Foundation.h>
#include <WebObjects/WebObjects.h>

@interface OTWRedisSessionStore : WOSessionStore {
    NSString *_redisHost;
    int _redisPort;
}

- (instancetype)initWithHost:(NSString *)host port:(int)port;

@end
