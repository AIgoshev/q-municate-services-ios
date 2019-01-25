// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to CDMessage.h instead.

#if __has_feature(modules)
    @import Foundation;
    @import CoreData;
#else
    #import <Foundation/Foundation.h>
    #import <CoreData/CoreData.h>
#endif

NS_ASSUME_NONNULL_BEGIN

@class QMCDAttachment;
@class QMCDDialog;

@interface QMCDMessageID : NSManagedObjectID {}
@end

@interface _QMCDMessage : NSManagedObject
+ (instancetype)insertInManagedObjectContext:(NSManagedObjectContext *)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
@property (nonatomic, readonly, strong) QMCDMessageID *objectID;

@property (nonatomic, strong, nullable) NSDate* createAt;

@property (nonatomic, strong, nullable) NSData* customParameters;

@property (nonatomic, strong, nullable) NSDate* dateSend;

@property (nonatomic, strong, nullable) NSNumber* delayed;

@property (atomic) BOOL delayedValue;
- (BOOL)delayedValue;
- (void)setDelayedValue:(BOOL)value_;

@property (nonatomic, strong, nullable) NSData* deliveredIDs;

@property (nonatomic, strong, nullable) NSString* dialogID;

@property (nonatomic, strong, nullable) NSNumber* isRead;

@property (atomic) BOOL isReadValue;
- (BOOL)isReadValue;
- (void)setIsReadValue:(BOOL)value_;

@property (nonatomic, strong, nullable) NSString* messageID;

@property (nonatomic, strong, nullable) NSData* readIDs;

@property (nonatomic, strong, nullable) NSNumber* recipientID;

@property (atomic) int32_t recipientIDValue;
- (int32_t)recipientIDValue;
- (void)setRecipientIDValue:(int32_t)value_;

@property (nonatomic, strong, nullable) NSNumber* senderID;

@property (atomic) int32_t senderIDValue;
- (int32_t)senderIDValue;
- (void)setSenderIDValue:(int32_t)value_;

@property (nonatomic, strong, nullable) NSString* senderNick;

@property (nonatomic, strong, nullable) NSString* text;

@property (nonatomic, strong, nullable) NSDate* updateAt;

@property (nonatomic, strong, nullable) NSSet<QMCDAttachment*> *attachments;
- (nullable NSMutableSet<QMCDAttachment*>*)attachmentsSet;

@property (nonatomic, strong, nullable) QMCDDialog *dialog;

@end

@interface _QMCDMessage (AttachmentsCoreDataGeneratedAccessors)
- (void)addAttachments:(NSSet<QMCDAttachment*>*)value_;
- (void)removeAttachments:(NSSet<QMCDAttachment*>*)value_;
- (void)addAttachmentsObject:(QMCDAttachment*)value_;
- (void)removeAttachmentsObject:(QMCDAttachment*)value_;

@end

@interface _QMCDMessage (CoreDataGeneratedPrimitiveAccessors)

- (NSDate*)primitiveCreateAt;
- (void)setPrimitiveCreateAt:(NSDate*)value;

- (NSData*)primitiveCustomParameters;
- (void)setPrimitiveCustomParameters:(NSData*)value;

- (NSDate*)primitiveDateSend;
- (void)setPrimitiveDateSend:(NSDate*)value;

- (NSNumber*)primitiveDelayed;
- (void)setPrimitiveDelayed:(NSNumber*)value;

- (BOOL)primitiveDelayedValue;
- (void)setPrimitiveDelayedValue:(BOOL)value_;

- (NSData*)primitiveDeliveredIDs;
- (void)setPrimitiveDeliveredIDs:(NSData*)value;

- (NSString*)primitiveDialogID;
- (void)setPrimitiveDialogID:(NSString*)value;

- (NSNumber*)primitiveIsRead;
- (void)setPrimitiveIsRead:(NSNumber*)value;

- (BOOL)primitiveIsReadValue;
- (void)setPrimitiveIsReadValue:(BOOL)value_;

- (NSString*)primitiveMessageID;
- (void)setPrimitiveMessageID:(NSString*)value;

- (NSData*)primitiveReadIDs;
- (void)setPrimitiveReadIDs:(NSData*)value;

- (NSNumber*)primitiveRecipientID;
- (void)setPrimitiveRecipientID:(NSNumber*)value;

- (int32_t)primitiveRecipientIDValue;
- (void)setPrimitiveRecipientIDValue:(int32_t)value_;

- (NSNumber*)primitiveSenderID;
- (void)setPrimitiveSenderID:(NSNumber*)value;

- (int32_t)primitiveSenderIDValue;
- (void)setPrimitiveSenderIDValue:(int32_t)value_;

- (NSString*)primitiveSenderNick;
- (void)setPrimitiveSenderNick:(NSString*)value;

- (NSString*)primitiveText;
- (void)setPrimitiveText:(NSString*)value;

- (NSDate*)primitiveUpdateAt;
- (void)setPrimitiveUpdateAt:(NSDate*)value;

- (NSMutableSet<QMCDAttachment*>*)primitiveAttachments;
- (void)setPrimitiveAttachments:(NSMutableSet<QMCDAttachment*>*)value;

- (QMCDDialog*)primitiveDialog;
- (void)setPrimitiveDialog:(QMCDDialog*)value;

@end

@interface QMCDMessageAttributes: NSObject 
+ (NSString *)createAt;
+ (NSString *)customParameters;
+ (NSString *)dateSend;
+ (NSString *)delayed;
+ (NSString *)deliveredIDs;
+ (NSString *)dialogID;
+ (NSString *)isRead;
+ (NSString *)messageID;
+ (NSString *)readIDs;
+ (NSString *)recipientID;
+ (NSString *)senderID;
+ (NSString *)senderNick;
+ (NSString *)text;
+ (NSString *)updateAt;
@end

@interface QMCDMessageRelationships: NSObject
+ (NSString *)attachments;
+ (NSString *)dialog;
@end

NS_ASSUME_NONNULL_END
