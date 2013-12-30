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

#ifdef LOG_FLAG_ERROR

#define TOL_FLASH_LOG_CONTEXT 912
#define TOLFlashLogError(frmt, ...)     SYNC_LOG_OBJC_MAYBE(ddLogLevel, LOG_FLAG_ERROR,   TOL_FLASH_LOG_CONTEXT, @"%s [Line %d] " frmt, __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
#define TOLFlashLogWarn(frmt, ...)     ASYNC_LOG_OBJC_MAYBE(ddLogLevel, LOG_FLAG_WARN,    TOL_FLASH_LOG_CONTEXT, @"%s [Line %d] " frmt, __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
#define TOLFlashLogInfo(frmt, ...)     ASYNC_LOG_OBJC_MAYBE(ddLogLevel, LOG_FLAG_INFO,    TOL_FLASH_LOG_CONTEXT, @"%s [Line %d] " frmt, __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
#define TOLFlashLogDebug(frmt, ...)     ASYNC_LOG_OBJC_MAYBE(ddLogLevel, LOG_FLAG_DEBUG,  TOL_FLASH_LOG_CONTEXT, @"%s [Line %d] " frmt, __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
#define TOLFlashLogVerbose(frmt, ...)  ASYNC_LOG_OBJC_MAYBE(ddLogLevel, LOG_FLAG_VERBOSE, TOL_FLASH_LOG_CONTEXT, @"%s [Line %d] " frmt, __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)

#else
#define TOLFlashLogError(frmt, ...)    NSLog(frmt, ##__VA_ARGS__)
#define TOLFlashLogWarn(frmt, ...)     NSLog(frmt, ##__VA_ARGS__)
#define TOLFlashLogInfo(frmt, ...)     NSLog(frmt, ##__VA_ARGS__)
#define TOLFlashLogDebug(frmt, ...)    NSLog(frmt, ##__VA_ARGS__)
#define TOLFlashLogVerbose(frmt, ...)  NSLog(frmt, ##__VA_ARGS__)

#endif

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
#if !TARGET_IPHONE_SIMULATOR
    return ([[LARSTorch sharedTorch] torchDevice] != nil);
#else
    return NO;
#endif
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


- (AVCaptureDevice *)torchDevice{
#if !TARGET_IPHONE_SIMULATOR
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
#else
    return nil;
#endif
}

- (void)setTorchState:(LARSTorchState)torchOn{
#if !TARGET_IPHONE_SIMULATOR
    if ([self systemVersion] < 5.0f){
        TOLFlashLogInfo(@"Using pre-5.0 flash method: iOS %1.1f", self.systemVersion);
        if (self.torchSession == nil) {
            _torchSession = [[AVCaptureSession alloc] init];
        }
        
        if (self.torchDevice && [self.torchDevice hasTorch]) {
            
            //set session preset to lowest allowed to conserve system resources
            [self.torchSession setSessionPreset:AVCaptureSessionPresetLow];
            
            NSError *lockError = nil;
            if(self.torchDevice && [self.torchDevice lockForConfiguration:&lockError] == NO){
                TOLFlashLogError(@"%@ Lock error: %@\nReason: %@",self.class, [lockError localizedDescription], [lockError localizedFailureReason]);
                [self.torchDevice unlockForConfiguration];
                return;
            }
            
            [[self torchSession] beginConfiguration];
            
            if ( ([self.torchSession.inputs containsObject:self.torchDeviceInput] == NO) &&
                ([self systemVersion] < 5.0f)) {
                if (![self torchDeviceInput]) {
                    NSError *deviceError = nil;
                    _torchDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:self.torchDevice error:&deviceError];
                    
                    if (deviceError) {
                        TOLFlashLogError(@"%@ Device Error: %@\nReason: %@",
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
        TOLFlashLogInfo(@"Using post-5.0 torch method: iOS %1.1f", self.systemVersion);
        NSError *lockError = nil;
        if(self.torchDevice && [self.torchDevice lockForConfiguration:&lockError] == NO){
            TOLFlashLogError(@"%@ Lock error: %@\nReason: %@", self.class, [lockError localizedDescription], [lockError localizedFailureReason]);
            [self.torchDevice unlockForConfiguration];
            return;
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

#undef TOL_FLASH_LOG_CONTEXT
#undef TOLFlashLogError
#undef TOLFlashLogWarn
#undef TOLFlashLogInfo
#undef TOLFlashLogDebug
#undef TOLFlashLogVerbose
