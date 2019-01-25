//
//  QMUsersCache.m
//  QMUsersCache
//
//  Created by Andrey Moskvin on 10/23/15.
//  Copyright © 2015 Quickblox. All rights reserved.
//

#import "QMUsersCache.h"
#import "QMUsersModelIncludes.h"

#import "QMSLog.h"

@implementation QMUsersCache

static QMUsersCache *_usersCacheInstance = nil;

#pragma mark - Singleton

+ (QMUsersCache *)instance
{
    NSAssert(_usersCacheInstance, @"You must first perform @selector(setupDBWithStoreNamed:)");
    return _usersCacheInstance;
}

#pragma mark - Configure store

+ (void)setupDBWithStoreNamed:(NSString *)storeName applicationGroupIdentifier:(NSString *)appGroupIdentifier {
    
    NSManagedObjectModel *model =
    [NSManagedObjectModel QM_newModelNamed:@"QMUsersModel.momd"
                             inBundleNamed:@"QMUsersCacheModel.bundle"
                                 fromClass:[self class]];
    
    NSParameterAssert(!_usersCacheInstance);
    _usersCacheInstance =
    [[QMUsersCache alloc] initWithStoreNamed:storeName
                                       model:model
                  applicationGroupIdentifier:appGroupIdentifier];
}

+ (void)setupDBWithStoreNamed:(NSString *)storeName
{
    return [self setupDBWithStoreNamed:storeName applicationGroupIdentifier:nil];
}

+ (void)cleanDBWithStoreName:(NSString *)name
{
    if (_usersCacheInstance) {
        _usersCacheInstance = nil;
    }
    [super cleanDBWithStoreName:name];
}

#pragma mark - Users

- (BFTask *)insertOrUpdateUser:(QBUUser *)user
{
    return [self insertOrUpdateUsers:@[user]];
}

- (BFTask *)insertOrUpdateUsers:(NSArray *)users
{
    BFTaskCompletionSource *source =
    [BFTaskCompletionSource taskCompletionSource];
    
    [self save:^(NSManagedObjectContext *ctx) {
        //To Insert / Update
        for (QBUUser *user in users) {
            
            CDUser *cachedUser =
            [CDUser QM_findFirstOrCreateByAttribute:@"id"
                                          withValue:@(user.ID)
                                          inContext:ctx];
            
            QBUUser *cachedQBUser = [cachedUser toQBUUser];
            if ([cachedQBUser.lastRequestAt compare:user.lastRequestAt] == NSOrderedDescending) {
                // always should have newest date
                user.lastRequestAt = cachedQBUser.lastRequestAt;
            }
            [cachedUser updateWithQBUser:user];
        }
        
    } finish:^{
        [source setResult:nil];
    }];
    return source.task;
}

- (BFTask *)deleteUser:(QBUUser *)user
{
    BFTaskCompletionSource *source = [BFTaskCompletionSource taskCompletionSource];
    
    [self save:^(NSManagedObjectContext *ctx) {
        
        [CDUser QM_deleteAllMatchingPredicate:IS(@"id", @(user.ID))
                                    inContext:ctx];
    } finish:^{
        
        [source setResult:nil];
    }];
    
    return source.task;
}

- (BFTask *)truncateAll {
    [self performMainQueue:^(NSManagedObjectContext *ctx) {
        [CDUser QM_truncateAllInContext:ctx];
        [ctx QM_saveToPersistentStoreAndWait];
    }];
    return [BFTask taskWithResult:nil];
}

- (BFTask *)deleteAllUsers {
    
    BFTaskCompletionSource *source =
    [BFTaskCompletionSource taskCompletionSource];
    
    [self save:^(NSManagedObjectContext *ctx) {
        
        [CDUser QM_truncateAllInContext:ctx];
        
    } finish:^{
        
        [source setResult:nil];
    }];
    
    return source.task;
}

- (BFTask *)userWithPredicate:(NSPredicate *) predicate
{
    BFTaskCompletionSource *source =
    [BFTaskCompletionSource taskCompletionSource];
    
    [self performMainQueue:^(NSManagedObjectContext *ctx) {
        
        QBUUser *user =
        [[CDUser QM_findFirstWithPredicate:predicate
                                 inContext:ctx] toQBUUser];
        [source setResult:user];
    }];
    
    return source.task;
}

- (BFTask *)usersSortedBy:(NSString *)sortTerm ascending:(BOOL)ascending
{
    return [self usersWithPredicate:nil sortedBy:sortTerm ascending:ascending];
}

- (BFTask *)usersWithPredicate:(NSPredicate *)predicate sortedBy:(NSString *)sortTerm ascending:(BOOL)ascending
{
    BFTaskCompletionSource *source =
    [BFTaskCompletionSource taskCompletionSource];
    
    [self performBackgroundQueue:^(NSManagedObjectContext *ctx) {
        
        NSArray<QBUUser *> *result =
        [[CDUser QM_findAllSortedBy:sortTerm
                          ascending:ascending
                      withPredicate:predicate
                          inContext:ctx] toQBUUsers];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [source setResult:result];
        });
    }];
    
    return source.task;
}

#pragma mark - Private

- (void)insertUsers:(NSArray *)users inContext:(NSManagedObjectContext *)context {
    
    for (QBUUser *user in users) {
        
        CDUser *newUser = [CDUser QM_createEntityInContext:context];
        [newUser updateWithQBUser:user];
    }
}

- (void)updateUsers:(NSArray *)qbUsers inContext:(NSManagedObjectContext *)context {
    
    for (QBUUser *qbUser in qbUsers) {
        
        CDUser *userToUpdate = [CDUser QM_findFirstWithPredicate:IS(@"id", @(qbUser.ID)) inContext:context];
        [userToUpdate updateWithQBUser:qbUser];
    }
}

- (NSArray *)convertCDUsertsToQBUsers:(NSArray *)cdUsers {
    
    NSMutableArray *users =
    [NSMutableArray arrayWithCapacity:cdUsers.count];
    
    for (CDUser *user in cdUsers) {
        
        QBUUser *qbUser = [user toQBUUser];
        [users addObject:qbUser];
    }
    
    return users;
}

@end
