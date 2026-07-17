#import "OTWRedisSessionStore.h"
#import "Session.h"
#import <hiredis/hiredis.h>

@implementation OTWRedisSessionStore

- (instancetype)initWithHost:(NSString *)host port:(int)port {
    if ((self = [super init])) {
        _redisHost = [host copy];
        _redisPort = port;
    }
    return self;
}

- (void)dealloc {
    [_redisHost release];
    [super dealloc];
}

- (redisContext *)_connect {
    redisContext *c = redisConnect([_redisHost UTF8String], _redisPort);
    if (c == NULL || c->err) {
        if (c) {
            NSLog(@"OTWRedisSessionStore: Redis connection error: %s", c->errstr);
            redisFree(c);
        } else {
            NSLog(@"OTWRedisSessionStore: Redis connection error: Can't allocate redis context");
        }
        return NULL;
    }
    return c;
}

- (WOSession *)removeSessionWithID:(NSString *)aSessionID {
    if (!aSessionID) return nil;
    
    redisContext *c = [self _connect];
    if (c) {
        redisReply *reply = redisCommand(c, "DEL session:%s", [aSessionID UTF8String]);
        if (reply) {
            freeReplyObject(reply);
        }
        redisFree(c);
    }
    return nil; // super class expects nil here typically or the old session; returning nil is safe for GSWSessionStore.
}

- (WOSession *)restoreSessionWithID:(NSString *)aSessionID request:(WORequest *)aRequest {
    if (!aSessionID) return nil;
    
    Session *session = nil;
    redisContext *c = [self _connect];
    if (c) {
        redisReply *reply = redisCommand(c, "GET session:%s", [aSessionID UTF8String]);
        if (reply && reply->type == REDIS_REPLY_STRING) {
            NSData *data = [NSData dataWithBytes:reply->str length:reply->len];
            @try {
                NSDictionary *dict = [NSKeyedUnarchiver unarchiveObjectWithData:data];
                if (dict) {
                    session = [[[Session alloc] init] autorelease];
                    [session setSessionID:aSessionID];
                    [session restoreFromStateDictionary:dict];
                }
            } @catch (NSException *e) {
                NSLog(@"OTWRedisSessionStore: Failed to unarchive session %@: %@", aSessionID, e);
            }
        }
        if (reply) {
            freeReplyObject(reply);
        }
        redisFree(c);
    }
    return session;
}

- (void)saveSessionForContext:(WOContext *)aContext {
    Session *session = (Session *)[aContext session];
    NSString *sessionID = [session sessionID];
    if (!session || !sessionID || ![session isKindOfClass:[Session class]]) return;
    
    NSTimeInterval timeout = [session timeOut];
    if (timeout <= 0) timeout = 3600; // default 1 hour
    
    NSData *data = nil;
    @try {
        NSDictionary *dict = [session stateDictionary];
        data = [NSKeyedArchiver archivedDataWithRootObject:dict];
    } @catch (NSException *e) {
        NSLog(@"OTWRedisSessionStore: Failed to archive session %@: %@", sessionID, e);
        return;
    }
    
    if (data) {
        redisContext *c = [self _connect];
        if (c) {
            redisReply *reply = redisCommand(c, "SETEX session:%s %d %b",
                                             [sessionID UTF8String],
                                             (int)timeout,
                                             [data bytes],
                                             [data length]);
            if (reply) {
                freeReplyObject(reply);
            } else {
                NSLog(@"OTWRedisSessionStore: Failed to save session to Redis");
            }
            redisFree(c);
        }
    }
}

@end
