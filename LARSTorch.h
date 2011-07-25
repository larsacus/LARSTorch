//
//  LATorch.h
//  Light²
//
//  Created by Lars Anderson on 6/4/11.
//  Copyright 2011 Lars Anderson. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface LATorch : NSObject {
    
@private

    float _systemVersion;
#if !TARGET_IPHONE_SIMULATOR
    AVCaptureSession *_torchSession;
    AVCaptureDevice *_torchDevice;
    AVCaptureDeviceInput *_torchDeviceInput;
    AVCaptureOutput *_torchOutput;
#endif
    id _delegate;
    BOOL _torchStateOnResume;

    
}


@property (nonatomic) float systemVersion;
#if !TARGET_IPHONE_SIMULATOR
@property (nonatomic, retain) AVCaptureSession *torchSession;
@property (nonatomic, retain) AVCaptureDevice *torchDevice;
@property (nonatomic, retain) AVCaptureDeviceInput *torchDeviceInput;
@property (nonatomic, retain) AVCaptureOutput *torchOutput;
#endif
@property (nonatomic, retain) id delegate;
@property (nonatomic) BOOL torchStateOnResume;


- (id)initWithTorchOn:(BOOL)torchOn;
- (void)setTorchOn:(BOOL)torchOn;
- (BOOL)isTorchOn;
- (BOOL)isInturrupted;
- (void)verifyTorchSubsystemsWithTorchOn:(BOOL)torchOn;

@end
