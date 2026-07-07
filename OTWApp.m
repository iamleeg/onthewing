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
#import "Observation.h"
#import "JournalEntry.h"

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

    // --- Observation ("observations" table) ---
    EOEntity *observationEntity = [[[EOEntity alloc] init] autorelease];
    [observationEntity setName:@"Observation"];
    [observationEntity setExternalName:@"observations"];
    [observationEntity setClassName:@"Observation"];

    EOAttribute *observationIdAttr = [[[EOAttribute alloc] init] autorelease];
    [observationIdAttr setName:@"observationId"];
    [observationIdAttr setColumnName:@"id"];
    [observationIdAttr setValueClassName:@"NSString"];
    [observationIdAttr setExternalType:@"varchar"];
    [observationIdAttr setWidth:64];
    [observationIdAttr setAllowsNull:NO];
    [observationEntity addAttribute:observationIdAttr];

    EOAttribute *captureDateAttr = [[[EOAttribute alloc] init] autorelease];
    [captureDateAttr setName:@"captureDate"];
    [captureDateAttr setColumnName:@"capture_date"];
    [captureDateAttr setValueClassName:@"NSDate"];
    [captureDateAttr setExternalType:@"timestamp"];
    [captureDateAttr setAllowsNull:YES];
    [observationEntity addAttribute:captureDateAttr];

    // photoURL is an NSURL on the Objective-C side, but GDL2 has no native
    // NSURL value-class support (checked: zero references in libs-gdl2) -
    // this attribute maps to Observation's photoURLString pass-through
    // accessor instead (see Observation.h/.m), not photoURL directly.
    EOAttribute *photoURLStringAttr = [[[EOAttribute alloc] init] autorelease];
    [photoURLStringAttr setName:@"photoURLString"];
    [photoURLStringAttr setColumnName:@"photo_url"];
    [photoURLStringAttr setValueClassName:@"NSString"];
    [photoURLStringAttr setExternalType:@"varchar"];
    [photoURLStringAttr setWidth:2048];
    [photoURLStringAttr setAllowsNull:YES];
    [observationEntity addAttribute:photoURLStringAttr];

    // ObservationLocation's 4 numeric fields are embedded as flat columns
    // here rather than a separate entity/table (per the epic's design) -
    // these map to Observation's latitude/longitude/accuracy/bearing
    // pass-through accessors, which proxy through -location.
    EOAttribute *latitudeAttr = [[[EOAttribute alloc] init] autorelease];
    [latitudeAttr setName:@"latitude"];
    [latitudeAttr setColumnName:@"latitude"];
    [latitudeAttr setValueClassName:@"NSNumber"];
    [latitudeAttr setExternalType:@"double precision"];
    [latitudeAttr setAllowsNull:YES];
    [observationEntity addAttribute:latitudeAttr];

    EOAttribute *longitudeAttr = [[[EOAttribute alloc] init] autorelease];
    [longitudeAttr setName:@"longitude"];
    [longitudeAttr setColumnName:@"longitude"];
    [longitudeAttr setValueClassName:@"NSNumber"];
    [longitudeAttr setExternalType:@"double precision"];
    [longitudeAttr setAllowsNull:YES];
    [observationEntity addAttribute:longitudeAttr];

    EOAttribute *accuracyAttr = [[[EOAttribute alloc] init] autorelease];
    [accuracyAttr setName:@"accuracy"];
    [accuracyAttr setColumnName:@"accuracy"];
    [accuracyAttr setValueClassName:@"NSNumber"];
    [accuracyAttr setExternalType:@"double precision"];
    [accuracyAttr setAllowsNull:YES];
    [observationEntity addAttribute:accuracyAttr];

    EOAttribute *bearingAttr = [[[EOAttribute alloc] init] autorelease];
    [bearingAttr setName:@"bearing"];
    [bearingAttr setColumnName:@"bearing"];
    [bearingAttr setValueClassName:@"NSNumber"];
    [bearingAttr setExternalType:@"double precision"];
    [bearingAttr setAllowsNull:YES];
    [observationEntity addAttribute:bearingAttr];

    // Foreign key backing the journalEntry relationship below - deliberately
    // NOT a class property (not directly KVC-exposed; the relationship is).
    EOAttribute *observationJournalEntryFKAttr = [[[EOAttribute alloc] init] autorelease];
    [observationJournalEntryFKAttr setName:@"journalEntryForeignKey"];
    [observationJournalEntryFKAttr setColumnName:@"journal_entry_id"];
    [observationJournalEntryFKAttr setValueClassName:@"NSString"];
    [observationJournalEntryFKAttr setExternalType:@"varchar"];
    [observationJournalEntryFKAttr setWidth:64];
    [observationJournalEntryFKAttr setAllowsNull:NO];
    [observationEntity addAttribute:observationJournalEntryFKAttr];

    [observationEntity setPrimaryKeyAttributes:@[observationIdAttr]];
    [observationEntity setAttributesUsedForLocking:@[observationIdAttr]];

    // --- JournalEntry ("journal_entries" table) ---
    EOEntity *journalEntryEntity = [[[EOEntity alloc] init] autorelease];
    [journalEntryEntity setName:@"JournalEntry"];
    [journalEntryEntity setExternalName:@"journal_entries"];
    [journalEntryEntity setClassName:@"JournalEntry"];

    EOAttribute *journalEntryIdAttr = [[[EOAttribute alloc] init] autorelease];
    [journalEntryIdAttr setName:@"journalEntryId"];
    [journalEntryIdAttr setColumnName:@"id"];
    [journalEntryIdAttr setValueClassName:@"NSString"];
    [journalEntryIdAttr setExternalType:@"varchar"];
    [journalEntryIdAttr setWidth:64];
    [journalEntryIdAttr setAllowsNull:NO];
    [journalEntryEntity addAttribute:journalEntryIdAttr];

    EOAttribute *journalEntryTitleAttr = [[[EOAttribute alloc] init] autorelease];
    [journalEntryTitleAttr setName:@"title"];
    [journalEntryTitleAttr setColumnName:@"title"];
    [journalEntryTitleAttr setValueClassName:@"NSString"];
    [journalEntryTitleAttr setExternalType:@"varchar"];
    [journalEntryTitleAttr setWidth:255];
    [journalEntryTitleAttr setAllowsNull:YES];
    [journalEntryEntity addAttribute:journalEntryTitleAttr];

    EOAttribute *journalEntryReflectionsAttr = [[[EOAttribute alloc] init] autorelease];
    [journalEntryReflectionsAttr setName:@"reflections"];
    [journalEntryReflectionsAttr setColumnName:@"reflections"];
    [journalEntryReflectionsAttr setValueClassName:@"NSString"];
    [journalEntryReflectionsAttr setExternalType:@"text"];
    [journalEntryReflectionsAttr setAllowsNull:YES];
    [journalEntryEntity addAttribute:journalEntryReflectionsAttr];

    // Foreign key backing the observer relationship below - not a class
    // property, same reasoning as observationJournalEntryFKAttr above.
    EOAttribute *journalEntryObserverFKAttr = [[[EOAttribute alloc] init] autorelease];
    [journalEntryObserverFKAttr setName:@"observerForeignKey"];
    [journalEntryObserverFKAttr setColumnName:@"observer_uid"];
    [journalEntryObserverFKAttr setValueClassName:@"NSString"];
    [journalEntryObserverFKAttr setExternalType:@"varchar"];
    [journalEntryObserverFKAttr setWidth:128];
    [journalEntryObserverFKAttr setAllowsNull:NO];
    [journalEntryEntity addAttribute:journalEntryObserverFKAttr];

    [journalEntryEntity setPrimaryKeyAttributes:@[journalEntryIdAttr]];
    [journalEntryEntity setAttributesUsedForLocking:@[journalEntryIdAttr]];

    // --- Relationships ---
    // Both sides of each relationship are defined explicitly with reciprocal
    // joins (swapped source/destination attributes).

    EORelationship *observationToJournalEntry = [[[EORelationship alloc] init] autorelease];
    [observationToJournalEntry setName:@"journalEntry"];
    [observationToJournalEntry setEntity:observationEntity];
    [observationToJournalEntry setToMany:NO];
    EOJoin *observationToJournalEntryJoin =
        [[[EOJoin alloc] initWithSourceAttribute:observationJournalEntryFKAttr
                            destinationAttribute:journalEntryIdAttr] autorelease];
    [observationToJournalEntry addJoin:observationToJournalEntryJoin];
    [observationEntity addRelationship:observationToJournalEntry];

    EORelationship *journalEntryToObservations = [[[EORelationship alloc] init] autorelease];
    [journalEntryToObservations setName:@"observations"];
    [journalEntryToObservations setEntity:journalEntryEntity];
    [journalEntryToObservations setToMany:YES];
    EOJoin *journalEntryToObservationsJoin =
        [[[EOJoin alloc] initWithSourceAttribute:journalEntryIdAttr
                            destinationAttribute:observationJournalEntryFKAttr] autorelease];
    [journalEntryToObservations addJoin:journalEntryToObservationsJoin];
    // Deleting a JournalEntry must delete its Observations - this is EOF's
    // own app-level cascade (EOEditingContext propagates deletes through the
    // object graph per this delete rule when -deleteObject:/-saveChanges are
    // called), independent of any DB-level FK constraint.
    [journalEntryToObservations setDeleteRule:EODeleteRuleCascade];
    [journalEntryEntity addRelationship:journalEntryToObservations];

    EORelationship *journalEntryToObserver = [[[EORelationship alloc] init] autorelease];
    [journalEntryToObserver setName:@"observer"];
    [journalEntryToObserver setEntity:journalEntryEntity];
    [journalEntryToObserver setToMany:NO];
    EOJoin *journalEntryToObserverJoin =
        [[[EOJoin alloc] initWithSourceAttribute:journalEntryObserverFKAttr
                            destinationAttribute:uidAttr] autorelease];
    [journalEntryToObserver addJoin:journalEntryToObserverJoin];
    [journalEntryEntity addRelationship:journalEntryToObserver];

    EORelationship *observerToJournalEntries = [[[EORelationship alloc] init] autorelease];
    [observerToJournalEntries setName:@"journalEntries"];
    [observerToJournalEntries setEntity:observerEntity];
    [observerToJournalEntries setToMany:YES];
    EOJoin *observerToJournalEntriesJoin =
        [[[EOJoin alloc] initWithSourceAttribute:uidAttr
                            destinationAttribute:journalEntryObserverFKAttr] autorelease];
    [observerToJournalEntries addJoin:observerToJournalEntriesJoin];
    // Deliberately NOT cascade, we will revisit this on account deletion.
    [observerEntity addRelationship:observerToJournalEntries];

    [observationEntity setClassProperties:@[observationIdAttr, captureDateAttr, photoURLStringAttr,
                                             latitudeAttr, longitudeAttr, accuracyAttr, bearingAttr,
                                             observationToJournalEntry]];
    [journalEntryEntity setClassProperties:@[journalEntryIdAttr, 
                                              journalEntryToObserver, journalEntryToObservations]];
    // Re-set (not append) Observer's class properties to include the new
    // to-many relationship alongside its original 5 attributes.
    [observerEntity setClassProperties:@[uidAttr, nameAttr, emailAttr, avatarUrlAttr, tokenAttr,
                                          observerToJournalEntries]];

    [model addEntity:observerEntity];
    [model addEntity:journalEntryEntity];
    [model addEntity:observationEntity];
    [[EOModelGroup defaultGroup] addModel:model];

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
                    [adaptorChannel evaluateExpression:expr];
                }
                NS_HANDLER {
                    // Ignore duplicate table/sequence exceptions (safe when run repeatedly)
                    NSLog(@"Schema generation statement execution message: %@", localException);
                }
                NS_ENDHANDLER;
            }
        }
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

+ (NSNumber *)sessionTimeOut {
  return [NSNumber numberWithInt:60];
}

- (NSString *)contextClassName {
  return @"WOContext";
}

@end
