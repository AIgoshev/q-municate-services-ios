//
//  QMMediaBlocks.h
//  QMMediaKit
//
//  Created by Vitaliy Gurkovsky on 2/8/17.
//  Copyright © 2017 quickblox. All rights reserved.
//

#import "QMChatTypes.h"


@class QBCBlob;
@class QMMediaError;

NS_ASSUME_NONNULL_BEGIN

typedef void (^QMAttachmentDownloadCancellBlock)(QBChatAttachment *attachment);
typedef void (^QMAttachmentMessageStatusBlock)(QMMessageAttachmentStatus status, QBChatMessage *message);
typedef void (^QMAttachmentMesssageUploadProgressBlock)(float progress, QBChatMessage *message);
typedef void (^QMAttachmentDownloadProgressBlock)(float progress, QBChatMessage *message, QBChatAttachment *attachment);
typedef void (^QMAttachmentMessageDidStartUploading)(QBChatMessage *message);
typedef void (^QMAttachmentDownloadProgressBlock)(float progress, QBChatMessage *message, QBChatAttachment *attachment);
typedef void (^QMAttachmentDataCompletionBlock)(NSString *attachmentID, NSData *data, QMMediaError *error);
typedef void (^QMMediaProgressBlock)(float progress);
typedef void (^QMMediaErrorBlock)(NSError *error, QBResponseStatusCode);
typedef void (^QMMediaUploadCompletionBlock)(QBCBlob *blob, NSError *error);
typedef void (^QMAttachmentUploadCompletionBlock)(NSError *error);
typedef void (^QMMessageUploadProgressBlock)(float progress);
typedef void(^QMMediaInfoServiceCompletionBlock)(UIImage * _Nullable image, Float64 durationSeconds, CGSize size, NSError * _Nullable error, NSString *messageID, BOOL cancelled);

NS_ASSUME_NONNULL_END

