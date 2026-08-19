// SPDX-License-Identifier: AGPL-3.0-or-later
#import "TestOTWApp.h"

@implementation TestOTWApp

- (void)updateDatabaseColumnsForAdaptorChannel:(id)adaptorChannel expectedTableNames:(NSArray *)expectedTableNames {
    // No-op for tests: bypasses GDL2 EOEntity cache bugs in describeModelWithTableNames:
}

@end
