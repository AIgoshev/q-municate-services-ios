//
//  QMChatCache.m
//  QMChatCache
//
//  Created by Andrey on 06.11.14.
//
//

#import "QMChatCache.h"
#import "ModelIncludes.h"

@implementation QMChatCache

static QMChatCache *_chatCacheInstance = nil;

#pragma mark - Singleton

+ (QMChatCache *)instance {
    
    NSAssert(_chatCacheInstance, @"You must first perform @selector(setupDBWithStoreNamed:)");
    return _chatCacheInstance;
}

#pragma mark - Configure store

+ (void)setupDBWithStoreNamed:(NSString *)storeName {
    
    NSManagedObjectModel *model = [NSManagedObjectModel QM_newModelNamed:@"QMChatServiceModel.momd"
                                                           inBundleNamed:@"QMChatCacheModel.bundle"];
    
    _chatCacheInstance = [[QMChatCache alloc] initWithStoreNamed:storeName
                                                           model:model
                                                      queueLabel:"com.qmunicate.QMChatCacheBackgroundQueue"];
}

+ (void)cleanDBWithStoreName:(NSString *)name {
    
    if (_chatCacheInstance) {
        _chatCacheInstance = nil;
    }
    
    [super cleanDBWithStoreName:name];
}

#pragma mark -
#pragma mark Dialogs
#pragma mark -

- (NSArray *)convertCDDialogsTOQBChatDialogs:(NSArray *)cdDialogs {
    
    NSMutableArray *qbChatDialogs = [NSMutableArray arrayWithCapacity:cdDialogs.count];
    
    for (CDDialog *dialog in cdDialogs) {
        
        QBChatDialog *qbUser = [dialog toQBChatDialog];
        [qbChatDialogs addObject:qbUser];
    }
    
    return qbChatDialogs;
}

#pragma mark Fetch Dialogs

- (void)dialogsSortedBy:(NSString *)sortTerm
              ascending:(BOOL)ascending
             completion:(void(^)(NSArray *dialogs))completion {
    
    __weak __typeof(self)weakSelf = self;
    
    [self async:^(NSManagedObjectContext *context) {
        
        NSArray *cdChatDialogs = [CDDialog QM_findAllSortedBy:sortTerm
                                                    ascending:ascending
                                                    inContext:context];
        
        NSArray *allDialogs = [weakSelf convertCDDialogsTOQBChatDialogs:cdChatDialogs];
        DO_AT_MAIN(completion(allDialogs));
        
    }];
}

- (void)dialogsSortedBy:(NSString *)sortTerm
              ascending:(BOOL)ascending
          withPredicate:(NSPredicate *)predicate
             completion:(void(^)(NSArray *dialogs))completion {
    
    __weak __typeof(self)weakSelf = self;
    
    [self async:^(NSManagedObjectContext *context) {
        
        NSArray *cdChatDialogs = [CDDialog QM_findAllSortedBy:sortTerm
                                                    ascending:ascending
                                                withPredicate:predicate];
        
        NSArray *allDialogs = [weakSelf convertCDDialogsTOQBChatDialogs:cdChatDialogs];
        DO_AT_MAIN(completion(allDialogs));
        
    }];
}

#pragma mark Insert / Update / Delete

- (void)insertOrUpdateDialog:(QBChatDialog *)dialog
                  completion:(void(^)(void))completion {
    
    __weak __typeof(self)weakSelf = self;
    
    [self async:^(NSManagedObjectContext *context) {
        
        CDDialog *cachedDialog = [CDDialog QM_findFirstWithPredicate:IS(@"id", dialog.ID)
                                                           inContext:context];
        if (cachedDialog) {
            //Update if needed
            QBChatDialog *qbDialog = [cachedDialog toQBChatDialog];
            
            if (![dialog isEqual:qbDialog]) {
                [cachedDialog updateWithQBChatDialog:dialog];
                NSLog(@"Update dialog - %@", dialog.ID);
            }
        }
        else {
            //Insert new dialog
            CDDialog *dialogToInsert = [CDDialog QM_createEntityInContext:context];
            [dialogToInsert updateWithQBChatDialog:dialog];
            NSLog(@"Insert New dialog - %@", dialog.ID);
        }
        
        [weakSelf save:completion];
    }];
}

- (void)mergeDialogs:(NSArray *)dialogs
          completion:(void(^)(void))completion {
    
    __weak __typeof(self)weakSelf = self;
    
    [self async:^(NSManagedObjectContext *context) {
        
        NSArray *cdAllDialogs =
        [CDDialog QM_findAllInContext:context];
        
        NSArray *allDialogs =
        [weakSelf convertCDDialogsTOQBChatDialogs:cdAllDialogs];
        
        NSMutableArray *toInsert = [NSMutableArray array];
        NSMutableArray *toUpdate = [NSMutableArray array];
        NSMutableArray *toDelete = [NSMutableArray arrayWithArray:allDialogs];
        
        // To delete
        for (QBChatDialog *dialog in dialogs) {
            
            [toDelete removeObject:dialog];
        }
        
        //To Insert / Update
        for (QBChatDialog *dialog in dialogs) {
            
            CDDialog *cdChatDialog = [CDDialog QM_findFirstWithPredicate:IS(@"id", dialog.ID)
                                                               inContext:context];
            if (cdChatDialog) {
                
                [toUpdate addObject:dialog];
            }
            else {
                
                [toInsert addObject:dialog];
            }
        }
        
        if (toUpdate.count > 0) {
            
            [weakSelf updateQBChatDialogs:toUpdate
                                inContext:context];
        }
        
        if (toInsert.count > 0) {
            
            [weakSelf insertQBChatDialogs:toInsert
                                inContext:context];
        }
        
        if (toDelete.count > 0) {
            
            [weakSelf deleteDialogs:toDelete
                          inContext:context];
        }
        
        if (toInsert.count + toInsert.count > 0) {
            [weakSelf save:completion];
        }
        
        NSLog(@"Dialogs to insert %lu", (unsigned long)toInsert.count);
        NSLog(@"Dialogs to update %lu", (unsigned long)toUpdate.count);
        NSLog(@"Dialogs to remove %lu", (unsigned long)toDelete.count);
        
    }];
}

- (void)insertQBChatDialogs:(NSArray *)qbChatDialogs
                  inContext:(NSManagedObjectContext *)context {
    
    for (QBChatDialog *qbChatDialog in qbChatDialogs) {
        
        CDDialog *dialogToInsert = [CDDialog QM_createEntityInContext:context];
        [dialogToInsert updateWithQBChatDialog:qbChatDialog];
    }
}

- (void)deleteDialogs:(NSArray *)qbChatDialogs
            inContext:(NSManagedObjectContext *)context {
    
    for (QBChatDialog *qbChatDialog in qbChatDialogs) {
        
        [self deleteDialogWithID:qbChatDialog.ID inContext:context];
    }
}

- (void)updateQBChatDialogs:(NSArray *)qbChatDialogs
                  inContext:(NSManagedObjectContext *)context {
    
    for (QBChatDialog *qbChatDialog in qbChatDialogs) {
        
        CDDialog *dialogToUpdate = [CDDialog QM_findFirstWithPredicate:IS(@"id", qbChatDialog.ID)
                                                             inContext:context];
        [dialogToUpdate updateWithQBChatDialog:qbChatDialog];
    }
}

- (void)deleteDialogWithID:(NSString *)dialogID
                 inContext:(NSManagedObjectContext *)context {
    
    CDDialog *dialogToDelete = [CDDialog QM_findFirstWithPredicate:IS(@"id", dialogID)
                                                         inContext:context];
    [dialogToDelete QM_deleteEntityInContext:context];
}

- (void)deleteDialogWithID:(NSString *)dialogID
                completion:(void(^)(void))completion {
    
    __weak __typeof(self)weakSelf = self;
    [self async:^(NSManagedObjectContext *context) {
        
        [weakSelf deleteDialogWithID:dialogID inContext:context];
        
        completion();
    }];
}

- (void)deleteAllDialogs:(void(^)(void))completion {
    
    [self async:^(NSManagedObjectContext *context) {
        
        NSArray *cdAllDialogs =
        [CDDialog QM_findAllInContext:context];
        
        for (CDDialog *dialog in cdAllDialogs) {
            [dialog QM_deleteEntityInContext:context];
        }
        
        completion();
    }];
}

#pragma mark -
#pragma mark  Messages
#pragma mark -

- (NSArray *)convertCDMessagesTOQBChatHistoryMesages:(NSArray *)cdMessages {
    
    NSMutableArray *messages = [NSMutableArray arrayWithCapacity:cdMessages.count];
    
    for (CDMessage *message in cdMessages) {
        
        QBChatHistoryMessage *qbChatHistoryMessage = [message toQBChatHistoryMessage];
        [messages addObject:qbChatHistoryMessage];
    }
    
    return messages;
}

#pragma mark Fetch Messages

- (void)messagesWithDialogId:(NSString *)dialogId
                    sortedBy:(NSString *)sortTerm
                   ascending:(BOOL)ascending
                  completion:(void(^)(NSArray *array))completion {
    
    [self messagesWithPredicate:IS(@"dialogId", dialogId)
                       sortedBy:sortTerm
                      ascending:ascending
                     completion:completion];
}

- (void)messagesWithPredicate:(NSPredicate *)predicate
                     sortedBy:(NSString *)sortTerm
                    ascending:(BOOL)ascending
                   completion:(void(^)(NSArray *messages))completion {
    
    __weak __typeof(self)weakSelf = self;
    [self async:^(NSManagedObjectContext *context) {
        
        NSArray *messages = [CDMessage QM_findAllSortedBy:sortTerm
                                                ascending:ascending
                                            withPredicate:predicate
                                                inContext:context];
        
        NSArray *result = [weakSelf convertCDMessagesTOQBChatHistoryMesages:messages];
        
        DO_AT_MAIN(completion(result));
    }];
}

#pragma mark Insert / Update / Delete

- (void)insertOrUpdateMessage:(QBChatHistoryMessage *)message
                 withDialogId:(NSString *)dialogID
                   completion:(void(^)(void))completion {
    
    __weak __typeof(self)weakSelf = self;
    
    [self async:^(NSManagedObjectContext *context) {
        
        CDMessage *cdMessage = [CDMessage QM_findFirstWithPredicate:IS(@"dialogID", dialogID)
                                                          inContext:context];
        if (cdMessage) {
            //Update if needed
            QBChatHistoryMessage *qmMessage = [cdMessage toQBChatHistoryMessage];
            
            if (![message isEqual:qmMessage]) {
                [cdMessage updateWithQBChatHistoryMessage:message];
                NSLog(@"Update new QBChatHistoryMessage -  %@ with dialogID - %@",message.ID, dialogID);
            }
        }
        else {
            //Insert new message
            CDMessage *messageToInsert = [CDMessage QM_createEntityInContext:context];
            [messageToInsert updateWithQBChatHistoryMessage:message];
            NSLog(@"Insert new QBChatHistoryMessage -  %@ with dialogID - %@",message.ID, dialogID);
            
        }
        
        [weakSelf save:completion];
    }];
}

- (void)mergeMessages:(NSArray *)messages
         withDialogId:(NSString *)dialogID
           completion:(void(^)(void))completion {
    
    __weak __typeof(self)weakSelf = self;
    
    [self async:^(NSManagedObjectContext *context) {
        
        NSArray *messagesFromCache =
        [CDMessage QM_findAllWithPredicate:IS(@"dialogID", dialogID)
                                 inContext:context];
        
        NSArray *qbMessagesFromCache =
        [weakSelf convertCDMessagesTOQBChatHistoryMesages:messagesFromCache];
        
        NSMutableArray *toInsert = [NSMutableArray array];
        NSMutableArray *toUpdate = [NSMutableArray array];
        NSMutableArray *toDelete = [NSMutableArray arrayWithArray:qbMessagesFromCache];
        
        // To delete
        for (QBChatHistoryMessage *dialog in messages) {
            
            [toDelete removeObject:dialog];
        }
        
        //To Insert / Update
        for (QBChatHistoryMessage *message in messages) {
            
            CDMessage *cdMessage =
            [CDMessage QM_findFirstWithPredicate:IS(@"id", message.ID)
                                       inContext:context];
            if (cdMessage) {
                
                [toUpdate addObject:message];
            }
            else {
                
                [toInsert addObject:messages];
            }
        }
        
        if (toUpdate.count > 0) {
            
            [weakSelf updateMessages:toUpdate
                           inContext:context];
        }
        
        if (toInsert.count > 0) {
            
            [weakSelf insertMessages:toInsert
                           inContext:context];
        }
        
        if (toDelete.count > 0) {
            
            [weakSelf deleteMessages:toDelete
                           inContext:context];
        }
        
        if (toInsert.count + toInsert.count > 0) {
            [weakSelf save:completion];
        }
        
        NSLog(@"Messages to insert %lu", (unsigned long)toInsert.count);
        NSLog(@"Messages to update %lu", (unsigned long)toUpdate.count);
        NSLog(@"Messages to remove %lu", (unsigned long)toDelete.count);
        
    }];
}

- (void)insertMessages:(NSArray *)messages
             inContext:(NSManagedObjectContext *)context {
    
    for (QBChatHistoryMessage *message in messages) {
        
        CDMessage *messageToInsert = [CDMessage QM_createEntityInContext:context];
        [messageToInsert updateWithQBChatHistoryMessage:message];
    }
}

- (void)deleteMessages:(NSArray *)messages
             inContext:(NSManagedObjectContext *)context {
    
    for (QBChatHistoryMessage *qbChatHistoryMessage in messages) {
        
        [self deleteMessage:qbChatHistoryMessage
                  inContext:context];
    }
}

- (void)updateMessages:(NSArray *)messages
             inContext:(NSManagedObjectContext *)context {
    
    for (QBChatHistoryMessage *message in messages) {
        
        CDMessage *messageToUpdate = [CDMessage QM_findFirstWithPredicate:IS(@"id", message.ID)
                                                                inContext:context];
        [messageToUpdate updateWithQBChatHistoryMessage:message];
    }
}

- (void)deleteMessage:(QBChatHistoryMessage *)message
            inContext:(NSManagedObjectContext *)context {
    
    CDMessage *messageToDelete = [CDMessage QM_findFirstWithPredicate:IS(@"id", message.ID)
                                                            inContext:context];
    [messageToDelete QM_deleteEntityInContext:context];
}

- (void)deleteMessage:(QBChatHistoryMessage *)message
         withDialogID:(NSString *)dialogID
           completion:(void(^)(void))completion {
    
    __weak __typeof(self)weakSelf = self;
    [self async:^(NSManagedObjectContext *context) {
        
        [weakSelf deleteMessage:message inContext:context];
        completion();
    }];
}

@end