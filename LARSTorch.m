//
//  LARSTorch.m
//  Light²
//
//  Created by Lars Anderson on 6/4/11.
//
// Copyright (c) 2011 Lars Anderson, drink&apple
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


#import "LARSTorch.h"
#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface LARSTorch ()

@property (nonatomic) CGFloat systemVersion;
#if !TARGET_IPHONE_SIMULATOR
@property (nonatomic, retain) AVCaptureSession *torchSession;
@property (nonatomic, retain) AVCaptureDevice *torchDevice;
@property (nonatomic, retain) AVCaptureDeviceInput *torchDeviceInput;
@property (nonatomic, retain) AVCaptureOutput *torchOutput;
#endif

@end

@implementation LARSTorch

static LARSTorch *__sharedTorch = nil;

+ (instancetype)sharedTorch{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __sharedTorch = [[self alloc] initWithTorchState:LARSTorchStateOff];
    });
    
    return __sharedTorch;
}

+ (BOOL)isTorchAvailable{
    return ([[LARSTorch sharedTorch] torchDevice] != nil);
}

- (instancetype)init{
    return [self initWithTorchState:LARSTorchStateOff];
}

- (instancetype)initWithTorchState:(LARSTorchState)torchOn{
    self = [super init];
    if(self){
        [self setSystemVersion:[[[UIDevice currentDevice] systemVersion] floatValue]];
        
        [self setTorchState:torchOn];
    }
#if !TARGET_IPHONE_SIMULATOR
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(flashlightSessionResumeFromInturrupt)
                                                 name:AVCaptureSessionInterruptionEndedNotification
                                               object:nil
     ];
#endif
    [self setTorchStateOnResume:LARSTorchStateOn];
    return self;
}

- (BOOL)isTorchOn{
#if !TARGET_IPHONE_SIMULATOR
    if ([self systemVersion] >= 5.0) {
        //>5.0 doesn't require AVCaptureSession
        return [self.torchDevice torchMode] == AVCaptureTorchModeOn;
    }
    else{
        return  (([self.torchSession isRunning]) &&
                 ([self.torchDevice torchMode] == AVCaptureTorchModeOn));
    }
#else
    return NO;
#endif
}

- (BOOL)isInturrupted{
#if !TARGET_IPHONE_SIMULATOR
    return [self.torchSession isInterrupted];
#else
    return NO;
#endif
}

#if !TARGET_IPHONE_SIMULATOR
- (AVCaptureDevice *)torchDevice{
    if (_torchDevice == nil) {
        NSArray *videoDevices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
        for (AVCaptureDevice *device in videoDevices) {
            if ([device isTorchModeSupported:AVCaptureTorchModeOn]) {
                _torchDevice = device;
                break;
            }
        }
    }
    
    return _torchDevice;
}

#endif

- (void)setTorchState:(LARSTorchState)torchOn{
#if !TARGET_IPHONE_SIMULATOR
    if ([self systemVersion] < 5.0f){
        if (self.torchSession == nil) {
            _torchSession = [[AVCaptureSession alloc] init];
        }
        
        if (self.torchDevice && [self.torchDevice hasTorch]) {
            
            //set session preset to lowest allowed to conserve system resources
            [self.torchSession setSessionPreset:AVCaptureSessionPresetLow];
            
            NSError *lockError = nil;
            if(![self.torchDevice lockForConfiguration:&lockError]){
                NSLog(@"%@ Lock error: %@\nReason: %@",self.class, [lockError localizedDescription], [lockError localizedFailureReason]);
            }
            
            [[self torchSession] beginConfiguration];
            
            if ( ([self.torchSession.inputs containsObject:self.torchDeviceInput] == NO) &&
                ([self systemVersion] < 5.0f)) {
                if (![self torchDeviceInput]) {
                    NSError *deviceError = nil;
                    _torchDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:self.torchDevice error:&deviceError];
                    
                    if (deviceError) {
                        NSLog(@"%@ Device Error: %@\nReason: %@",
                              self.class,
                              [deviceError localizedDescription], [deviceError localizedFailureReason]);
                    }
                }
                [self.torchSession addInput:self.torchDeviceInput];
            }
            
            //light does not function without capture output
            if (![self.torchSession.outputs containsObject:self.torchOutput]) {
                if (self.torchOutput == nil) {
                    _torchOutput = [[AVCaptureVideoDataOutput alloc] init];
                }
                [self.torchSession addOutput:[self torchOutput]];
            }
            
            if (torchOn) {
                [self.torchDevice setTorchMode:AVCaptureTorchModeOn];
                [self.torchDevice setFlashMode:AVCaptureFlashModeOn];
            }
            else {
                [self.torchDevice setTorchMode:AVCaptureTorchModeOff];
                [self.torchDevice setFlashMode:AVCaptureFlashModeOff];
            }
            
            [self.torchDevice unlockForConfiguration];
            
            [self.torchSession commitConfiguration];
            
            
            if (![self.torchSession isRunning]) {
                [self.torchSession startRunning];
            }
        }
    }
    else{
        //the only required methods for devices with >iOS 5.0
        NSError *lockError = nil;
        if(![self.torchDevice lockForConfiguration:&lockError]){
            NSLog(@"%@ Lock error: %@\nReason: %@", self.class, [lockError localizedDescription], [lockError localizedFailureReason]);
        }
        
        [self.torchSession beginConfiguration];
        
        if ([self.torchDevice isTorchAvailable] == YES) {
            if (torchOn) {
                self.torchDevice.torchMode = AVCaptureTorchModeOn;
            }
            else {
                self.torchDevice.torchMode = AVCaptureTorchModeOff;
            }
        }
        
        [self.torchSession commitConfiguration];
        [self.torchDevice unlockForConfiguration];
    }
#endif
}

- (BOOL)setTorchOnWithLevel:(CGFloat)level{
#if !TARGET_IPHONE_SIMULATOR
    [self.torchDevice lockForConfiguration:nil];
    
    BOOL wasTorchSet = [self.torchDevice setTorchModeOnWithLevel:level error:nil];
    
    [self.torchDevice unlockForConfiguration];
    
    return wasTorchSet;
#else
    return YES;
#endif
}

-(void)flashlightSessionResumeFromInturrupt{
    [self setTorchState:self.torchStateOnResume];
}

- (void)dealloc{
#if !TARGET_IPHONE_SIMULATOR
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    self.torchDevice = nil;
    self.torchSession = nil;
    self.torchDeviceInput = nil;
    self.torchOutput = nil;
#endif
}

@end
