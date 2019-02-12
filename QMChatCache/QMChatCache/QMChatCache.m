//
//  QMChatCache.m
//  QMServices
//
//  Created by Andrey on 06.11.14.
//  Copyright (c) 2015 Quickblox Team. All rights reserved.
//

#import "QMChatCache.h"
#import "QMCCModelIncludes.h"

#import "QMSLog.h"

@implementation QMChatCache

static QMChatCache *_chatCacheInstance = nil;

#pragma mark - Singleton

+ (QMChatCache *)instance {
    
    NSAssert(_chatCacheInstance, @"You must first perform @selector(setupDBWithStoreNamed:)");
    return _chatCacheInstance;
}

#pragma mark - Configure store

+ (void)setupDBWithStoreNamed:(NSString *)storeName {
    
    [self setupDBWithStoreNamed:storeName applicationGroupIdentifier:nil];
}

+ (void)setupDBWithStoreNamed:(NSString *)storeName
applicationGroupIdentifier:(NSString *)appGroupIdentifier {
    
    NSManagedObjectModel *model =
    [NSManagedObjectModel QM_newModelNamed:@"QMChatServiceModel.momd"
                             inBundleNamed:@"QMChatCacheModel.bundle"
                                 fromClass:[self class]];
    _chatCacheInstance =
    [[QMChatCache alloc] initWithStoreNamed:storeName
                                      model:model
                 applicationGroupIdentifier:appGroupIdentifier];
    
    _chatCacheInstance.messagesLimitPerDialog = NSNotFound;
}

+ (void)cleanDBWithStoreName:(NSString *)name {
    
    if (_chatCacheInstance) {
        _chatCacheInstance = nil;
    }
    
    [super cleanDBWithStoreName:name];
}

#pragma mark - Init

- (instancetype)init
{
    self = [super init];
    
    if (self) {
        self.messagesLimitPerDialog = NSNotFound;
    }
    
    return self;
}

#pragma mark -
#pragma mark Dialogs
#pragma mark -

#pragma mark Fetch Dialogs

- (void)allDialogsWithCompletion:(void(^)(NSArray<QBChatDialog *> *dialogs))completion {
    
    [self performBackgroundQueue:^(NSManagedObjectContext *ctx) {
        
        NSArray<QBChatDialog *> *result =
        [[QMCDDialog QM_findAllInContext:ctx] toQBChatDialogs];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if (completion) {
                completion(result);
            }
        });
    }];
}

- (void)dialogsSortedBy:(NSString *)sortTerm ascending:(BOOL)ascending completion:(void(^)(NSArray<QBChatDialog *> *dialogs))completion {
    
    [self dialogsSortedBy:sortTerm ascending:ascending withPredicate:nil completion:completion];
}

- (void)dialogByID:(NSString *)dialogID
        completion:(void (^)(QBChatDialog *dialog))completion {
    
    [self performBackgroundQueue:^(NSManagedObjectContext *ctx) {
        
        QBChatDialog *result =
        [[QMCDDialog QM_findFirstByAttribute:@"dialogID"
                                   withValue:dialogID
                                   inContext:ctx] toQBChatDialog];
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(result);
            });
        }
    }];
}

- (void)dialogsSortedBy:(NSString *)sortTerm
              ascending:(BOOL)ascending
          withPredicate:(NSPredicate *)predicate
             completion:(void(^)(NSArray<QBChatDialog *> *dialogs))completion {
    
    [self performBackgroundQueue:^(NSManagedObjectContext *ctx) {
        
        NSArray<QBChatDialog *> *result =
        [[QMCDDialog QM_findAllSortedBy:sortTerm
                              ascending:ascending
                          withPredicate:predicate
                              inContext:ctx] toQBChatDialogs];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if (completion) {
                completion(result);
            }
        });
    }];
}

#pragma mark Insert / Update / Delete

- (void)insertOrUpdateDialog:(QBChatDialog *)dialog completion:(dispatch_block_t)completion {
    
    [self insertOrUpdateDialogs:@[dialog] completion:completion];
}

- (void)insertOrUpdateDialogs:(NSArray *)dialogs
                   completion:(dispatch_block_t)completion {
    
    [self save:^(NSManagedObjectContext *ctx) {
        
        for (QBChatDialog *dialog in dialogs) {
            
            QMCDDialog *cachedDialog =
            [QMCDDialog QM_findFirstOrCreateByAttribute:@"dialogID"
                                            withValue:dialog.ID
                                            inContext:ctx];
            [cachedDialog updateWithQBChatDialog:dialog];
        }
        
    } finish:completion];
}

- (void)deleteDialogWithID:(NSString *)dialogID
                completion:(dispatch_block_t)completion {
    
    [self save:^(NSManagedObjectContext *ctx) {
        [QMCDDialog QM_deleteAllMatchingPredicate:IS(@"dialogID", dialogID)
                                        inContext:ctx];
    } finish:completion];
}

- (void)deleteAllDialogsWithCompletion:(dispatch_block_t)completion {
    
    [self save:^(NSManagedObjectContext *ctx) {
        [QMCDDialog QM_truncateAllInContext:ctx];
    } finish:completion];
}

#pragma mark Utils
#pragma mark -
#pragma mark  Messages
#pragma mark -

- (NSArray *)convertCDMessagesTOQBChatHistoryMesages:(NSArray *)cdMessages {
    
    NSMutableArray *messages = [NSMutableArray arrayWithCapacity:cdMessages.count];
    
    for (QMCDMessage *message in cdMessages) {
        
        QBChatMessage *QBChatMessage = [message toQBChatMessage];
        [messages addObject:QBChatMessage];
    }
    
    return messages;
}

#pragma mark Fetch Messages

- (void)messagesWithDialogId:(NSString *)dialogId sortedBy:(NSString *)sortTerm ascending:(BOOL)ascending completion:(void(^)(NSArray<QBChatMessage *> *messages))completion {
    
    [self messagesWithPredicate:IS(@"dialogID", dialogId) sortedBy:sortTerm ascending:ascending completion:completion];
}

- (void)messagesWithPredicate:(NSPredicate *)predicate
                     sortedBy:(NSString *)sortTerm
                    ascending:(BOOL)ascending
                   completion:(void(^)(NSArray<QBChatMessage *> *messages))completion {
    
    [self performBackgroundQueue:^(NSManagedObjectContext *ctx) {
        
        NSArray<QBChatMessage *> *result =
        [[QMCDMessage QM_findAllSortedBy:sortTerm
                               ascending:ascending
                           withPredicate:predicate
                                  offset:0
                                   limit:self.messagesLimitPerDialog
                               inContext:ctx] toQBChatMessages];
        if (completion) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(result);
            });
        }
    }];
}

- (NSArray<QBChatMessage *> *)messagesWithDialogId:(NSString *)dialogId
                                          sortedBy:(NSString *)sortTerm
                                         ascending:(BOOL)ascending {
    
    __block NSArray<QBChatMessage *> *result = nil;
    
    [self performMainQueue:^(NSManagedObjectContext *ctx) {
        
        result =
        [[QMCDMessage QM_findAllSortedBy:sortTerm
                               ascending:ascending
                           withPredicate:IS(@"dialogID", dialogId)
                                  offset:0
                                   limit:self.messagesLimitPerDialog
                               inContext:ctx] toQBChatMessages];
    }];
    
    return result;
}

#pragma mark Messages Limit

#pragma mark Insert / Update / Delete

- (void)insertOrUpdateMessage:(QBChatMessage *)message withDialogId:(NSString *)dialogID read:(BOOL)isRead completion:(dispatch_block_t)completion {    
    message.dialogID = dialogID;
    
    [self insertOrUpdateMessage:message withDialogId:dialogID completion:completion];
}

- (void)insertOrUpdateMessage:(QBChatMessage *)message withDialogId:(NSString *)dialogID completion:(dispatch_block_t)completion {
 
    [self insertOrUpdateMessages:@[message] withDialogId:dialogID completion:completion];
}

- (void)insertOrUpdateMessages:(NSArray *)messages
                  withDialogId:(NSString *)dialogID
                    completion:(dispatch_block_t)completion {
    
    [self save:^(NSManagedObjectContext *ctx) {
        
        QMCDDialog *cachedDialog =
        [QMCDDialog QM_findFirstByAttribute:@"dialogID" withValue:dialogID inContext:ctx];
        
        for (QBChatMessage *message in messages) {
            
            QMCDMessage *procMessage =
            [QMCDMessage QM_findFirstOrCreateByAttribute:@"messageID"
                                               withValue:message.ID
                                               inContext:ctx];
            [procMessage updateWithQBChatMessage:message];
            [cachedDialog addMessagesObject:procMessage];
        }
        
    } finish:completion];
}

- (void)insertMessages:(NSArray *)messages inContext:(NSManagedObjectContext *)context {
    
    for (QBChatMessage *message in messages) {
        
        QMCDMessage *messageToInsert = [QMCDMessage QM_createEntityInContext:context];
        [messageToInsert updateWithQBChatMessage:message];
    }
}

- (void)deleteMessages:(NSArray *)messages
            completion:(dispatch_block_t)completion {
    
    [self save:^(NSManagedObjectContext *ctx) {
        
        for (QBChatMessage *message in messages) {
            
            QMCDMessage *messageToDelete =
            [QMCDMessage QM_findFirstByAttribute:@"messageID"
                                       withValue:message.ID
                                       inContext:ctx];
            
            [messageToDelete QM_deleteEntityInContext:ctx];
        }
        
    } finish:completion];
}

- (void)updateMessages:(NSArray *)messages inContext:(NSManagedObjectContext *)context {
    
    for (QBChatMessage *message in messages) {
        
        QMCDMessage *messageToUpdate = [QMCDMessage QM_findFirstWithPredicate:IS(@"messageID", message.ID) inContext:context];
        [messageToUpdate updateWithQBChatMessage:message];
    }
}

- (void)deleteMessage:(QBChatMessage *)message inContext:(NSManagedObjectContext *)context {
    
    QMCDMessage *messageToDelete = [QMCDMessage QM_findFirstWithPredicate:IS(@"messageID", message.ID) inContext:context];
    [messageToDelete QM_deleteEntityInContext:context];
}

- (void)deleteMessagesWithDialogID:(NSString *)dialogID inContext:(NSManagedObjectContext *)context {
    
    [QMCDMessage QM_deleteAllMatchingPredicate:IS(@"dialogID", dialogID) inContext:context];
}

- (void)deleteMessage:(QBChatMessage *)message
           completion:(dispatch_block_t)completion {
    
    [self save:^(NSManagedObjectContext *ctx) {
        
        [QMCDMessage QM_deleteAllMatchingPredicate:IS(@"messageID", message.ID)
                                         inContext:ctx];
    } finish:completion];
}

- (void)deleteMessagesWithDialogID:(NSString *)dialogID
                        completion:(dispatch_block_t)completion {
    
    [self save:^(NSManagedObjectContext *ctx) {
        [QMCDMessage QM_deleteAllMatchingPredicate:IS(@"dialogID", dialogID)
                                         inContext:ctx];
    } finish:completion];
}

- (void)deleteAllMessagesWithCompletion:(dispatch_block_t)completion {
    
    [self save:^(NSManagedObjectContext *ctx) {
        [QMCDMessage QM_truncateAllInContext:ctx];
    } finish:completion];
}

- (void)truncateAll {
    [self performMainQueue:^(NSManagedObjectContext *ctx) {
        [QMCDDialog QM_truncateAllInContext:ctx];
        [QMCDMessage QM_truncateAllInContext:ctx];
        [QMCDAttachment QM_truncateAllInContext:ctx];
        [ctx QM_saveToPersistentStoreAndWait];
    }];
}

- (void)truncateAll:(nullable dispatch_block_t)completion {
    
    [self save:^(NSManagedObjectContext *ctx) {
        [QMCDDialog QM_truncateAllInContext:ctx];
        [QMCDMessage QM_truncateAllInContext:ctx];
        [QMCDAttachment QM_truncateAllInContext:ctx];
    } finish:completion];
}

@end
