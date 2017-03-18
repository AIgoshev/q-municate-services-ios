//
//  QMMediaDownloadService.m
//  QMMediaKit
//
//  Created by Vitaliy Gurkovsky on 2/7/17.
//  Copyright © 2017 quickblox. All rights reserved.
//

#import "QMMediaDownloadServiceDelegate.h"
#import "QMMediaDownloadService.h"

#import "QMMediaBlocks.h"
#import "QMSLog.h"
#import "QMMediaError.h"
#import "QMMediaItem.h"

@implementation QMMediaDownloadService

- (void)dealloc {
    
    QMSLog(@"%@ - %@",  NSStringFromSelector(_cmd), self);
}

- (void)downloadMediaItemWithID:(NSString *)mediaID
            withCompletionBlock:(QMMediaRestCompletionBlock)completionBlock
                  progressBlock:(QMMediaProgressBlock)progressBlock {
    
    [QBRequest downloadFileWithUID:mediaID  successBlock:^(QBResponse *response, NSData *fileData) {
        
        if (fileData) {
            completionBlock(mediaID, fileData, nil);
        }
    } statusBlock:^(QBRequest *request, QBRequestStatus *status) {
        
        progressBlock(status.percentOfCompletion);
        
    } errorBlock:^(QBResponse *response) {
        
        QMMediaError *error = [QMMediaError errorWithResponse:response];
        completionBlock(mediaID, nil, error);
    }];
}


- (BFTask *)downloadMediaItemWithID:(NSString *)mediaID
                      progressBlock:(QMMediaProgressBlock)progressBlock {
    
    BFTaskCompletionSource *source = [BFTaskCompletionSource taskCompletionSource];
    
    [self downloadMediaItemWithID:mediaID withCompletionBlock:^(NSString *mediaID, NSData *data, QMMediaError *error) {
        if (error) {
            [source setError:error];
        }
        else {
            [source setResult:data];
        }
    } progressBlock:^(float progress) {
        progressBlock(progress);
    }];
    
    return source.task;
}


@end
