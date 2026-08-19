// SPDX-License-Identifier: AGPL-3.0-or-later
//
// OTWApp.m - Application class
// Copyright (C) 2026 Graham Lee
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published
// by the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.

#ifndef GNUSTEP
#include <GNUstepBase/GNUstep.h>
#endif

#import "OTWApp.h"
#import <EOControl/EOControl.h>
#import <EOAccess/EOAccess.h>
#import <EOAccess/EOSQLExpression.h>
#import <EOAccess/EOSchemaSynchronization.h>
#import "Observer.h"
#import "Observation.h"
#import "JournalEntry.h"
#import "OTWRedisSessionStore.h"
#import <EOAccess/EODatabaseContext.h>
#import "ErrorPage.h"




@implementation OTWApp

@synthesize databaseSchemaReady = _databaseSchemaReady;

extern int GSWebNamingConv;
extern NSDictionary* globalMime;

+ (void)initialize {
  if (self == [OTWApp class]) {
    GSWebNamingConv = 1; // WONAMES_INDEX
    
    // Register custom MIME types for CSS and JS
    NSMutableDictionary *mimes = [globalMime mutableCopy];
    if (mimes == nil) {
      mimes = [[NSMutableDictionary alloc] init];
    }
    [mimes setObject:@"text/css" forKey:@"css"];
    [mimes setObject:@"application/javascript" forKey:@"js"];
    globalMime = [mimes copy];
    [mimes release];

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *d = @{
      @"WOAdaptor" : @"WODefaultAdaptor",
      @"GSWAdaptor" : @"WODefaultAdaptor",
      @"WODirectActionRequestHandlerKey" : @"wa",
      @"GSWDirectActionRequestHandlerKey" : @"dr",
      @"WOComponentRequestHandlerKey" : @"wo",
      @"GSWComponentRequestHandlerKey" : @"cr",
      @"WOResourceRequestHandlerKey" : @"wr",
      @"GSWResourceRequestHandlerKey" : @"rr",
      @"WOPingActionRequestHandlerKey" : @"wlb",
      @"GSWPingActionRequestHandlerKey" : @"lb",
      @"WOStreamActionRequestHandlerKey" : @"wis",
      @"GSWStreamActionRequestHandlerKey" : @"sr",
      @"AjaxRequestHandlerKey" : @"ja",
      @"GSWContextClassName" : @"WOContext",
      @"WOContextClassName" : @"WOContext"
    };
    [defaults registerDefaults:d];
    [defaults synchronize];
  }
}

- (void)initializeDatabase {
    EOModel *model = [[EOModelGroup defaultGroup] modelNamed:@"OnTheWing"];
    if (model == nil) {
        NSLog(@"CRITICAL: Failed to load OnTheWing.eomodeld!");
        return;
    }

    NSProcessInfo *processInfo = [NSProcessInfo processInfo];
    NSString *dbHost = [[processInfo environment] objectForKey:@"DB_HOST"] ?: @"127.0.0.1";
    NSString *dbPort = [[processInfo environment] objectForKey:@"DB_PORT"] ?: @"5432";
    NSString *dbName = [[processInfo environment] objectForKey:@"DB_NAME"] ?: @"onthewing-eedce-database";
    NSString *dbUser = [[processInfo environment] objectForKey:@"DB_USER"] ?: NSUserName();
    NSString *dbPassword = [[processInfo environment] objectForKey:@"DB_PASSWORD"] ?: @"";

    NSMutableDictionary *connDict = [[model connectionDictionary] mutableCopy];
    if (connDict == nil) {
        connDict = [[NSMutableDictionary alloc] init];
    }
    [connDict setObject:dbHost forKey:@"hostName"];
    [connDict setObject:dbPort forKey:@"port"];
    [connDict setObject:dbName forKey:@"databaseName"];
    if (dbUser && [dbUser length] > 0) {
        [connDict setObject:dbUser forKey:@"userName"];
    }
    if (dbPassword && [dbPassword length] > 0) {
        [connDict setObject:dbPassword forKey:@"password"];
    }
    [model setConnectionDictionary:connDict];
    [connDict release];

    [self attemptSchemaInitialization];
}

// Verifies (creating if needed) the DB schema via GDL2 schema generation.
// Runs once synchronously from -initializeDatabase at startup; if it fails,
// it schedules itself to retry
// via a timer on the app's own run loop rather than blocking the main
// thread or giving up permanently.
- (void)attemptSchemaInitialization {
    EOEditingContext *ec = [[[EOEditingContext alloc] init] autorelease];
    EODatabaseContext *databaseContext = [ec databaseContextForModelNamed:@"OnTheWing"];
    [databaseContext lock];
    BOOL succeeded = NO;
    NS_DURING {
        EODatabaseChannel *databaseChannel = [databaseContext availableChannel];
        EOAdaptorChannel *adaptorChannel = [databaseChannel adaptorChannel];
        if (![adaptorChannel isOpen]) {
            [adaptorChannel openChannel];
        }

        // Checking all three expected tables (rather than just "observers",
        // as before this schema grew to include journal_entries/observations)
        // matters for upgrading an existing deployment: on first deploy after
        // this change, "observers" already exists but the two new tables
        // don't - gating schema creation on a single table's existence would
        // silently skip creating the new ones forever. Schema-creation
        // statements are safe to re-run for tables that already exist.
        NSArray *expectedTableNames = @[@"observers", @"journal_entries", @"observations"];
        BOOL allTablesExist = NO;
        NS_DURING {
            NSArray *tableNames = [adaptorChannel describeTableNames];
            NSMutableSet *existingTableNames = [NSMutableSet set];
            for (NSString *name in tableNames) {
                [existingTableNames addObject:[name lowercaseString]];
            }
            allTablesExist = YES;
            for (NSString *expected in expectedTableNames) {
                if (![existingTableNames containsObject:expected]) {
                    allTablesExist = NO;
                    break;
                }
            }
        }
        NS_HANDLER {
            NSLog(@"Failed to describe table names: %@", localException);
        }
        NS_ENDHANDLER;

        if (!allTablesExist) {
            EOModel *m = [[EOModelGroup defaultGroup] modelNamed:@"OnTheWing"];
            NSArray *entities = [m entities];
            Class exprClass = [[EOAdaptor adaptorWithModel:m] expressionClass];

            NSDictionary *options = @{
                EODropTablesKey: @"NO",
                EODropPrimaryKeySupportKey: @"NO",
                EOCreatePrimaryKeySupportKey: @"NO"
            };
            NSArray *statements = [exprClass schemaCreationStatementsForEntities:entities
                                                                          options:options];
            for (EOSQLExpression *expr in statements) {
                NS_DURING {
                    NSLog(@"Executing: %@", [expr statement]); [adaptorChannel evaluateExpression:expr];
                }
                NS_HANDLER {
                    // Ignore duplicate table/sequence exceptions (safe when run repeatedly)
                    NSLog(@"Schema generation statement execution message: %@", localException);
                }
                NS_ENDHANDLER;
            }
        }
        
        [self updateDatabaseColumnsForAdaptorChannel:adaptorChannel expectedTableNames:expectedTableNames];
        
        succeeded = YES;
    }
    NS_HANDLER {
        NSLog(@"Error initializing database tables: %@", localException);
    }
    NS_ENDHANDLER
    [databaseContext unlock];

    self.databaseSchemaReady = succeeded;

    if (!succeeded) {
        NSTimer *retryTimer = [NSTimer timerWithTimeInterval:5.0
                                                       target:self
                                                     selector:@selector(attemptSchemaInitialization)
                                                     userInfo:nil
                                                      repeats:NO];
        [self addTimer:retryTimer];
    }
}

- (id)init {
  if ((self = [super init])) {
    [WOMessage setDefaultEncoding:NSUTF8StringEncoding];
    NSString *directActionHandlerKey =
        [[self class] directActionRequestHandlerKey];
    WORequestHandler *directActionHandler =
        [self requestHandlerForKey:directActionHandlerKey];
    [self setDefaultRequestHandler:directActionHandler];
    [self initializeDatabase];
  }
  return self;
}

- (WOSessionStore *)createSessionStore {
    NSProcessInfo *processInfo = [NSProcessInfo processInfo];
    NSString *redisHost = [[processInfo environment] objectForKey:@"REDIS_HOST"];
    if (redisHost) {
        NSString *redisPortStr = [[processInfo environment] objectForKey:@"REDIS_PORT"];
        int redisPort = redisPortStr ? [redisPortStr intValue] : 6379;
        OTWRedisSessionStore *store = [[OTWRedisSessionStore alloc] initWithHost:redisHost port:redisPort];
        return [store autorelease];
    }
    return [super createSessionStore];
}

+ (NSNumber *)sessionTimeOut {
  return [NSNumber numberWithInt:60];
}

- (NSString *)contextClassName {
  return @"WOContext";
}

- (GSWResponse *)handleException:(NSException *)exception inContext:(GSWContext *)aContext {
    NSString *correlationId = [[NSProcessInfo processInfo] globallyUniqueString];
    NSLog(@"Unhandled application exception [%@]: %@", correlationId, exception);
    
    ErrorPage *errorPage = (ErrorPage *)[self pageWithName:@"ErrorPage" inContext:aContext];
    [errorPage setCorrelationId:correlationId];
    return [errorPage generateResponse];
}


- (void)updateDatabaseColumnsForAdaptorChannel:(EOAdaptorChannel *)adaptorChannel expectedTableNames:(NSArray *)expectedTableNames {
    NS_DURING {
        EOModel *m = [[EOModelGroup defaultGroup] modelNamed:@"OnTheWing"];
        Class exprClass = [[EOAdaptor adaptorWithModel:m] expressionClass];
        EOModel *dbModel = [adaptorChannel describeModelWithTableNames:expectedTableNames];
        
        for (EOEntity *appEntity in [m entities]) {
            EOEntity *dbEntity = nil;
            for (EOEntity *e in [dbModel entities]) {
                if ([[e externalName] caseInsensitiveCompare:[appEntity externalName]] == NSOrderedSame) {
                    dbEntity = e;
                    break;
                }
            }
            
            if (dbEntity) {
                for (EOAttribute *appAttr in [appEntity attributes]) {
                    if (![appAttr columnName]) continue;
                    
                    BOOL found = NO;
                    for (EOAttribute *dbAttr in [dbEntity attributes]) {
                        if ([dbAttr columnName] && [[dbAttr columnName] caseInsensitiveCompare:[appAttr columnName]] == NSOrderedSame) {
                            found = YES;
                            break;
                        }
                    }
                    
                    if (!found) {
                        NS_DURING {
                            NSArray *statements = [exprClass statementsToInsertColumnForAttribute:appAttr options:nil];
                            if (statements) {
                                for (EOSQLExpression *expr in statements) {
                                    NS_DURING {
                                        [adaptorChannel evaluateExpression:expr];
                                    }
                                    NS_HANDLER {
                                        NSLog(@"Failed to add column %@: %@", [appAttr columnName], localException);
                                    }
                                    NS_ENDHANDLER;
                                }
                            }
                        }
                        NS_HANDLER {
                            NSLog(@"Failed to generate column insertion for %@: %@", [appAttr columnName], localException);
                        }
                        NS_ENDHANDLER;
                    }
                }
            }
        }
    }
    NS_HANDLER {
        NSLog(@"Failed to check/update schema columns: %@", localException);
    }
    NS_ENDHANDLER;
}

@end
