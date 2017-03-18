//
//  QMMediaUploadService.m
//  QMMediaKit
//
//  Created by Vitaliy Gurkovsky on 2/9/17.
//  Copyright © 2017 quickblox. All rights reserved.
//
#import <Quickblox/Quickblox.h>
#import "QMMediaUploadService.h"
#import "QMSLog.h"

@implementation QMMediaUploadService

- (void)dealloc {
    
    QMSLog(@"%@ - %@",  NSStringFromSelector(_cmd), self);
}

- (void)uploadMediaWithData:(NSData *)data
                   mimeType:(NSString *)mimeType
        withCompletionBlock:(QMMediaUploadCompletionBlock)completionBlock
              progressBlock:(QMMediaProgressBlock)progressBlock {
    
    [QBRequest TUploadFile:data fileName:@"MediaAttachment" contentType:mimeType isPublic:NO successBlock:^(QBResponse * _Nonnull response, QBCBlob * _Nonnull blob) {
        
        if (completionBlock) {
            completionBlock(blob, nil);
        }
    } statusBlock:^(QBRequest * _Nonnull request, QBRequestStatus * _Nullable status) {
        
        progressBlock(status.percentOfCompletion);
        
    } errorBlock:^(QBResponse * _Nonnull response) {
        
        completionBlock(nil, response.error.error);
    }];
    
}

- (BFTask *)uploadMediaWithData:(NSData *)data
                       mimeType:(NSString *)mimeType
                  progressBlock:(QMMediaProgressBlock)progressBlock {
    
    BFTaskCompletionSource *source = [BFTaskCompletionSource taskCompletionSource];
    
    [self uploadMediaWithData:data mimeType:mimeType withCompletionBlock:^(QBCBlob *blob, NSError *error) {
        if (error) {
            [source setError:error];
        }
        else {
            [source setResult:blob];
        }
    } progressBlock:^(float progress) {
        progressBlock(progress);
    }];
    
    return source.task;
}


@end
