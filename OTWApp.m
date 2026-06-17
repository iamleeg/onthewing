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
#import "Observer.h"

@implementation OTWApp

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
    if ([[EOModelGroup defaultGroup] modelNamed:@"OnTheWing"] != nil) {
        return;
    }
    NSProcessInfo *processInfo = [NSProcessInfo processInfo];
    NSString *dbHost = [[processInfo environment] objectForKey:@"DB_HOST"] ?: @"127.0.0.1";
    NSString *dbPort = [[processInfo environment] objectForKey:@"DB_PORT"] ?: @"5432";
    NSString *dbName = [[processInfo environment] objectForKey:@"DB_NAME"] ?: @"onthewing-eedce-database";
    NSString *dbUser = [[processInfo environment] objectForKey:@"DB_USER"] ?: NSUserName();
    NSString *dbPassword = [[processInfo environment] objectForKey:@"DB_PASSWORD"] ?: @"";

    EOModel *model = [EOModel model];
    [model setName:@"OnTheWing"];
    [model setAdaptorName:@"PostgreSQL"];

    NSMutableDictionary *connDict = [NSMutableDictionary dictionary];
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

    EOEntity *observerEntity = [[[EOEntity alloc] init] autorelease];
    [observerEntity setName:@"Observer"];
    [observerEntity setExternalName:@"observers"];
    [observerEntity setClassName:@"Observer"];

    EOAttribute *uidAttr = [[[EOAttribute alloc] init] autorelease];
    [uidAttr setName:@"uid"];
    [uidAttr setColumnName:@"uid"];
    [uidAttr setValueClassName:@"NSString"];
    [uidAttr setExternalType:@"varchar"];
    [uidAttr setWidth:128];
    [uidAttr setAllowsNull:NO];
    [observerEntity addAttribute:uidAttr];

    EOAttribute *nameAttr = [[[EOAttribute alloc] init] autorelease];
    [nameAttr setName:@"name"];
    [nameAttr setColumnName:@"name"];
    [nameAttr setValueClassName:@"NSString"];
    [nameAttr setExternalType:@"varchar"];
    [nameAttr setWidth:255];
    [nameAttr setAllowsNull:YES];
    [observerEntity addAttribute:nameAttr];

    EOAttribute *emailAttr = [[[EOAttribute alloc] init] autorelease];
    [emailAttr setName:@"email"];
    [emailAttr setColumnName:@"email"];
    [emailAttr setValueClassName:@"NSString"];
    [emailAttr setExternalType:@"varchar"];
    [emailAttr setWidth:255];
    [emailAttr setAllowsNull:YES];
    [observerEntity addAttribute:emailAttr];

    EOAttribute *avatarUrlAttr = [[[EOAttribute alloc] init] autorelease];
    [avatarUrlAttr setName:@"avatarUrl"];
    [avatarUrlAttr setColumnName:@"avatar_url"];
    [avatarUrlAttr setValueClassName:@"NSString"];
    [avatarUrlAttr setExternalType:@"varchar"];
    [avatarUrlAttr setWidth:2048];
    [avatarUrlAttr setAllowsNull:YES];
    [observerEntity addAttribute:avatarUrlAttr];

    EOAttribute *tokenAttr = [[[EOAttribute alloc] init] autorelease];
    [tokenAttr setName:@"token"];
    [tokenAttr setColumnName:@"token"];
    [tokenAttr setValueClassName:@"NSString"];
    [tokenAttr setExternalType:@"varchar"];
    [tokenAttr setWidth:2048];
    [tokenAttr setAllowsNull:YES];
    [observerEntity addAttribute:tokenAttr];

    [observerEntity setPrimaryKeyAttributes:@[uidAttr]];
    [observerEntity setClassProperties:@[uidAttr, nameAttr, emailAttr, avatarUrlAttr, tokenAttr]];
    [observerEntity setAttributesUsedForLocking:@[uidAttr]];

    [model addEntity:observerEntity];
    [[EOModelGroup defaultGroup] addModel:model];

    // Ensure the table exists using GDL2 schema generation (migration facility)
    EOEditingContext *ec = [[[EOEditingContext alloc] init] autorelease];
    EODatabaseContext *databaseContext = [ec databaseContextForModelNamed:@"OnTheWing"];
    [databaseContext lock];
    NS_DURING {
        EODatabaseChannel *databaseChannel = [databaseContext availableChannel];
        EOAdaptorChannel *adaptorChannel = [databaseChannel adaptorChannel];
        if (![adaptorChannel isOpen]) {
            [adaptorChannel openChannel];
        }
        
        BOOL tableExists = NO;
        NS_DURING {
            NSArray *tableNames = [adaptorChannel describeTableNames];
            for (NSString *name in tableNames) {
                if ([[name lowercaseString] isEqualToString:@"observers"]) {
                    tableExists = YES;
                    break;
                }
            }
        }
        NS_HANDLER {
            NSLog(@"Failed to describe table names: %@", localException);
        }
        NS_ENDHANDLER;

        if (!tableExists) {
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
                    [adaptorChannel evaluateExpression:expr];
                }
                NS_HANDLER {
                    // Ignore duplicate table/sequence exceptions (safe when run repeatedly)
                    NSLog(@"Schema generation statement execution message: %@", localException);
                }
                NS_ENDHANDLER;
            }
        }
    }
    NS_HANDLER {
        NSLog(@"Error initializing observers table: %@", localException);
    }
    NS_ENDHANDLER
    [databaseContext unlock];
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

+ (NSNumber *)sessionTimeOut {
  return [NSNumber numberWithInt:60];
}

- (NSString *)contextClassName {
  return @"WOContext";
}

@end
