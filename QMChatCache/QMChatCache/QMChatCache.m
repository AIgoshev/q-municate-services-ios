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
    
    [self setupDBWithStoreNamed:storeName
     applicationGroupIdentifier:nil];
}

+ (void)setupDBWithStoreNamed:(NSString *)storeName
   applicationGroupIdentifier:(NSString *)appGroupIdentifier {
    
    NSManagedObjectModel *model = [NSManagedObjectModel QM_newModelNamed:@"QMChatServiceModel.momd"
                                                           inBundleNamed:@"QMChatCacheModel.bundle"
                                                               fromClass:[self class]];
    
    _chatCacheInstance = [[QMChatCache alloc] initWithStoreNamed:storeName
                                                           model:model
                                      applicationGroupIdentifier:appGroupIdentifier];
}

+ (void)cleanDBWithStoreName:(NSString *)name {
    
    if (_chatCacheInstance) {
        _chatCacheInstance = nil;
    }
    
    [super cleanDBWithStoreName:name];
}

#pragma mark - Init

- (instancetype)init {
    
    self = [super init];
    
    if (self) {
        _messagesLimitPerDialog = NSNotFound;
    }
    
    return self;
}

//MARK: - Fetch Dialogs

//MARK: Main queue

- (QBChatDialog *)dialogByID:(NSString *)dialogID {
    
    __block QBChatDialog *result = nil;
    [self performMainQueue:^(NSManagedObjectContext *ctx) {
        result = [[CDDialog QM_findFirstByAttribute:@"dialogID"
                                          withValue:dialogID
                                          inContext:ctx] toQBChatDialog];
    }];
    
    return result;
}

- (NSArray<QBChatDialog *> *)allDialogs {
    
    __block NSArray<QBChatDialog *> *result = nil;
    [self performMainQueue:^(NSManagedObjectContext *ctx) {
        result = [[CDDialog QM_findAllInContext:ctx] toQBChatDialogs];
    }];
    
    return result;
}

- (NSArray<QBChatDialog *> *)dialogsSortedBy:(NSString *)sortTerm
                                   ascending:(BOOL)ascending
                               withPredicate:(NSPredicate *)predicate {
    
    __block NSArray<QBChatDialog *> *result = nil;
    [self performMainQueue:^(NSManagedObjectContext *ctx) {
        result = [[CDDialog QM_findAllSortedBy:sortTerm
                                     ascending:ascending
                                 withPredicate:nil
                                     inContext:ctx] toQBChatDialogs];
    }];
    
    return result;
}

//MARK: Background queue

- (void)allDialogsWithCompletion:(void(^)(NSArray<QBChatDialog *> *dialogs))completion {
    
    [self performBackgroundQueue:^(NSManagedObjectContext *ctx) {
        
        NSArray<QBChatDialog *> *result =
        [[CDDialog QM_findAllInContext:ctx] toQBChatDialogs];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if (completion) {
                completion(result);
            }
        });
    }];
}

- (void)dialogsSortedBy:(NSString *)sortTerm
              ascending:(BOOL)ascending
             completion:(void(^)(NSArray<QBChatDialog *> *dialogs))completion {
    
    [self dialogsSortedBy:sortTerm
                ascending:ascending
            withPredicate:nil
               completion:completion];
}

- (void)dialogsSortedBy:(NSString *)sortTerm
              ascending:(BOOL)ascending
          withPredicate:(NSPredicate *)predicate
             completion:(void(^)(NSArray<QBChatDialog *> *dialogs))completion {
    
    [self performBackgroundQueue:^(NSManagedObjectContext *ctx) {
        
        NSArray<CDDialog *> *result =
        [[CDDialog QM_findAllSortedBy:sortTerm
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

//MARK: - Insert / Update

- (void)insertOrUpdateDialog:(QBChatDialog *)dialog
                  completion:(dispatch_block_t)completion {
    
    [self insertOrUpdateDialogs:@[dialog]
                     completion:completion];
}

- (void)insertOrUpdateDialogs:(NSArray *)dialogs
                   completion:(dispatch_block_t)completion {
    
    [self save:^(NSManagedObjectContext *ctx) {
        
        for (QBChatDialog *dialog in dialogs) {
            
            CDDialog *cachedDialog =
            [CDDialog QM_findFirstOrCreateByAttribute:@"dialogID"
                                            withValue:dialog.ID
                                            inContext:ctx];
            [cachedDialog updateWithQBChatDialog:dialog];
        }
        
        
        QMSLog(@"[%@] Dialogs to insert %tu, update %tu",
               NSStringFromClass([self class]),
               ctx.insertedObjects.count,
               ctx.updatedObjects.count);
        
    } finish:completion];
}

//MARK: Delete

- (void)deleteDialogWithID:(NSString *)dialogID
                completion:(dispatch_block_t)completion {
    
    [self save:^(NSManagedObjectContext *ctx) {
        [CDDialog QM_deleteAllMatchingPredicate:IS(@"dialogID", dialogID)
                                      inContext:ctx];
    } finish:completion];
}

- (void)deleteAllDialogsWithCompletion:(dispatch_block_t)completion {
    
    [self save:^(NSManagedObjectContext *ctx) {
        [CDDialog QM_truncateAllInContext:ctx];
    } finish:completion];
}

//MARK: - Messages

- (void)messagesWithDialogId:(NSString *)dialogId
                    sortedBy:(NSString *)sortTerm
                   ascending:(BOOL)ascending
                  completion:(void(^)(NSArray<QBChatMessage *> *messages))completion {
    
    [self messagesWithPredicate:IS(@"dialogID", dialogId)
                       sortedBy:sortTerm
                      ascending:ascending
                     completion:completion];
}

- (void)messagesWithPredicate:(NSPredicate *)predicate
                     sortedBy:(NSString *)sortTerm
                    ascending:(BOOL)ascending
                   completion:(void(^)(NSArray<QBChatMessage *> *messages))completion {
    
    
    [self performMainQueue:^(NSManagedObjectContext *ctx) {
        
        NSArray<CDMessage *> *result =
        [CDMessage QM_findAllSortedBy:sortTerm
                            ascending:ascending
                        withPredicate:predicate
                            inContext:ctx];
        if (completion) {
            completion([result toQBChatMessages]);
        }
    }];
}

#pragma mark Messages Limit

- (void)checkMessagesLimitForDialogWithID:(NSString *)dialogID
                           withCompletion:(dispatch_block_t)completion {
    
    if (self.messagesLimitPerDialog == NSNotFound) {
        
        if (completion) completion();
        return;
    }
    
    [self save:^(NSManagedObjectContext *ctx) {
        
        NSPredicate *messagePredicate = IS(@"dialogID", dialogID);
        
        if ([CDMessage QM_countOfEntitiesWithPredicate:messagePredicate inContext:ctx] > self.messagesLimitPerDialog) {
            
            NSFetchRequest *oldestMessageRequest = [NSFetchRequest fetchRequestWithEntityName:[CDMessage entityName]];
            
            oldestMessageRequest.fetchOffset = self.messagesLimitPerDialog;
            oldestMessageRequest.predicate = messagePredicate;
            oldestMessageRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"dateSend" ascending:NO]];
            
            NSArray *oldestMessagesForDialogID = [CDMessage QM_executeFetchRequest:oldestMessageRequest inContext:ctx];
            
            for (CDMessage *oldestMessage in oldestMessagesForDialogID) {
                [ctx deleteObject:oldestMessage];
            }
        }
        
    } finish:completion];
}

#pragma mark Insert / Update / Delete

- (void)insertOrUpdateMessage:(QBChatMessage *)message
                 withDialogId:(NSString *)dialogID
                         read:(BOOL)isRead
                   completion:(dispatch_block_t)completion {
    
    message.dialogID = dialogID;
    message.read = isRead;
    
    [self insertOrUpdateMessage:message
                   withDialogId:dialogID
                     completion:completion];
}

- (void)insertOrUpdateMessage:(QBChatMessage *)message
                 withDialogId:(NSString *)dialogID
                   completion:(dispatch_block_t)completion {
    
    [self insertOrUpdateMessages:@[message]
                    withDialogId:dialogID
                      completion:completion];
}

- (void)insertOrUpdateMessages:(NSArray *)messages
                  withDialogId:(NSString *)dialogID
                    completion:(dispatch_block_t)completion {
    
    [self save:^(NSManagedObjectContext *ctx) {
        
        for (QBChatMessage *message in messages) {
            
            CDMessage *procMessage =
            [CDMessage QM_findFirstOrCreateByAttribute:@"messageID"
                                             withValue:message.ID
                                             inContext:ctx];
            
            [procMessage updateWithQBChatMessage:message];
        }
        
        if (self.messagesLimitPerDialog != NSNotFound ) {
            
            NSPredicate *messagePredicate = IS(@"dialogID", dialogID);
            NSUInteger count =
            [CDMessage QM_countOfEntitiesWithPredicate:messagePredicate
                                             inContext:ctx];
            
//            self.messagesLimitPerDialog
            
            if (count > self.messagesLimitPerDialog) {
                
                NSFetchRequest *oldestMessageRequest = [NSFetchRequest fetchRequestWithEntityName:[CDMessage entityName]];
                
                oldestMessageRequest.fetchOffset = self.messagesLimitPerDialog;
                oldestMessageRequest.predicate = messagePredicate;
                oldestMessageRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"dateSend" ascending:NO]];
                
                NSArray *oldestMessagesForDialogID = [CDMessage QM_executeFetchRequest:oldestMessageRequest inContext:ctx];
                
                for (CDMessage *oldestMessage in oldestMessagesForDialogID) {
                    [ctx deleteObject:oldestMessage];
                }
            }
        }
        
        QMSLog(@"[%@] Messages to insert %tu, update %tu", NSStringFromClass([self class]),
               ctx.insertedObjects.count,
               ctx.updatedObjects.count);
        
    } finish:completion];
    
    //    [weakSelf save:^{
    //
    ////        if ([toInsert count] > 0) {
    ////
    ////            [weakSelf checkMessagesLimitForDialogWithID:dialogID withCompletion:completion];
    ////        }
    ////        else {
    ////
    ////        }
    //        if (completion) completion();
    //    }];
    
}

- (void)deleteMessage:(QBChatMessage *)message
           completion:(dispatch_block_t)completion {
    
    [self save:^(NSManagedObjectContext *ctx) {
        [CDMessage QM_deleteAllMatchingPredicate:IS(@"messageID", message.ID)
                                       inContext:ctx];
    } finish:completion];
}

- (void)deleteMessages:(NSArray *)messages
            completion:(dispatch_block_t)completion {
    
    [self save:^(NSManagedObjectContext *ctx) {
        
        for (QBChatMessage *message in messages) {
            
            CDMessage *messageToDelete =
            [CDMessage QM_findFirstByAttribute:@"messageID"
                                     withValue:message.ID
                                     inContext:ctx];
            
            [messageToDelete QM_deleteEntityInContext:ctx];
        }
        
    } finish:completion];
}

- (void)deleteMessageWithDialogID:(NSString *)dialogID
                       completion:(dispatch_block_t)completion {
    
    [self save:^(NSManagedObjectContext *ctx) {
        
        [CDMessage QM_deleteAllMatchingPredicate:IS(@"dialogID", dialogID)
                                       inContext:ctx];
    } finish:completion];
}

- (void)deleteAllMessagesWithCompletion:(dispatch_block_t)completion {
    
    [self save:^(NSManagedObjectContext *ctx) {
        [CDMessage QM_truncateAllInContext:ctx];
    } finish:completion];
}

@end
