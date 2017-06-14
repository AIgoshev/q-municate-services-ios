//
//  QMMediaStoreServiceDelegate.h
//  QMMediaKit
//
//  Created by Vitaliy Gurkovsky on 2/7/17.
//  Copyright © 2017 quickblox. All rights reserved.
//

#import <Foundation/Foundation.h>


@class  QBChatAttachment;

NS_ASSUME_NONNULL_BEGIN


@protocol QMMediaStoreServiceDelegate <NSObject>

@required

- (void)didUpdateAttachment:(QBChatAttachment *)attachment messageID:(NSString *)messageID dialogID:(NSString *)dialogID;
- (void)didRemoveAttachment:(QBChatAttachment *)attachment messageID:(NSString *)messageID dialogID:(NSString *)dialogID;

@end

NS_ASSUME_NONNULL_END
