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

#define ON YES
#define OFF NO

@implementation LARSTorch


@synthesize systemVersion = _systemVersion;
#if !TARGET_IPHONE_SIMULATOR
@synthesize torchSession = _torchSession;
@synthesize torchDevice = _torchDevice;
@synthesize torchDeviceInput = _torchDeviceInput;
@synthesize torchOutput = _torchOutput;
#endif
@synthesize delegate = _delegate;
@synthesize torchStateOnResume = _torchStateOnResume;

- (id)init{
    return [self initWithTorchOn:NO];
}

- (id)initWithTorchOn:(BOOL)torchOn{
    self = [super init];
    if(self){
        [self setSystemVersion:[[[UIDevice currentDevice] systemVersion] floatValue]];
        //NSLog(@"System version is %f", [self systemVersion]);
        
        [self setTorchOn:torchOn];
    }
#if !TARGET_IPHONE_SIMULATOR
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(flashlightSessionResumeFromInturrupt) 
                                                 name:AVCaptureSessionInterruptionEndedNotification
                                               object:nil
     ];
#endif
    [self setTorchStateOnResume:ON];   
    return self;
}

- (BOOL)isTorchOn{
#if !TARGET_IPHONE_SIMULATOR
    if ([self systemVersion] >= 5.0) {
        //>5.0 doesn't require AVCaptureSession
        return [self.torchDevice torchMode] == AVCaptureTorchModeOn;
    }
    return  [[self torchSession] isRunning] && 
            ([self.torchDevice torchMode] == AVCaptureTorchModeOn);
#else
    return NO;
#endif
}

- (BOOL)isInturrupted{
#if !TARGET_IPHONE_SIMULATOR
    return [[self torchSession] isInterrupted];
#else
    return NO;
#endif
}

#if !TARGET_IPHONE_SIMULATOR
- (AVCaptureDevice *)torchDevice{
    if (_torchDevice == nil) {
//        NSLog(@"Creating device");
        _torchDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
//        NSLog(@"Device created!");
    }
    
    return _torchDevice;
}

#endif

- (void)setTorchOn:(BOOL)torchOn{
#if !TARGET_IPHONE_SIMULATOR
    if ([self systemVersion] < 5.0f){
        if (![self torchSession]) {
            //NSLog(@"Creating session");
            _torchSession = [[AVCaptureSession alloc] init];
            //NSLog(@"Done!");
        }
        
        if (self.torchDevice && [self.torchDevice hasTorch]) {

            //NSLog(@"Device has useable torch!");
            //set session preset to lowest allowed to conserve system resources
            //NSLog(@"Session preset set to low");
            [[self torchSession] setSessionPreset:AVCaptureSessionPresetLow];
            
            NSError *lockError = nil;
            //NSLog(@"Locking device for configuration");
            if(![self.torchDevice lockForConfiguration:&lockError]){
                NSLog(@"Lock error: %@\nReason: %@", [lockError localizedDescription], [lockError localizedFailureReason]);
            }
            
            //NSLog(@"Beginning configuration");
            [[self torchSession] beginConfiguration];
            
            //NSLog(@"Verifying session input");
            if (![[[self torchSession] inputs] containsObject:[self torchDeviceInput]] && ([self systemVersion] < 5.0f)) {
                //NSLog(@"Input is not attached to session");
                if (![self torchDeviceInput]) {
                    //NSLog(@"Creating...");
                    NSError *deviceError = nil;
                    _torchDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:self.torchDevice error:&deviceError];
                    
                    if (deviceError) {
                        NSLog(@"Device Error: %@\nReason: %@", [deviceError localizedDescription], [deviceError localizedFailureReason]);
                    }
                    //NSLog(@"Done!");
                }
                //NSLog(@"Adding input to session");
                [[self torchSession] addInput:[self torchDeviceInput]];
            }
            
            //NSLog(@"Verifying session output");
            //light does not function without capture output
            if (![[[self torchSession] outputs] containsObject:[self torchOutput]]) {
                //NSLog(@"Output not attached to session");
                if (![self torchOutput]) {
                    //NSLog(@"Creating...");
                    _torchOutput = [[AVCaptureVideoDataOutput alloc] init];
                }
                //NSLog(@"Adding input to session");
                [[self torchSession] addOutput:[self torchOutput]];
            }
            
            //NSLog(@"Setting torch mode to %@", torchOn ? @"ON" : @"OFF");
            if (torchOn) {
                [self.torchDevice setTorchMode:AVCaptureTorchModeOn];
                [self.torchDevice setFlashMode:AVCaptureFlashModeOn];
            }
            else {
                [self.torchDevice setTorchMode:AVCaptureTorchModeOff];
                [self.torchDevice setFlashMode:AVCaptureFlashModeOff];
            }
            
            //NSLog(@"Unlocking device for configuration");
            [self.torchDevice unlockForConfiguration];
            
            //NSLog(@"Committing configuration");
            [[self torchSession] commitConfiguration];
            
            
            if (![[self torchSession] isRunning]) {
                //NSLog(@"Starting session");
                [[self torchSession] startRunning];
            }
            else{
                //NSLog(@"Session is already started or session does not need to exist");
            }
        }
    }
    else{
        //the only required methods for devices with >iOS 5.0
        NSError *lockError = nil;
        //NSLog(@"Locking device for configuration");
        if(![self.torchDevice lockForConfiguration:&lockError]){
            NSLog(@"Lock error: %@\nReason: %@", [lockError localizedDescription], [lockError localizedFailureReason]);
        }
        //NSLog(@"Beginning configuration");
        [[self torchSession] beginConfiguration];
    
        if ([self.torchDevice isTorchAvailable] == YES) {
            if (torchOn) {
                self.torchDevice.torchMode = AVCaptureTorchModeOn;
            }
            else {
                self.torchDevice.torchMode = AVCaptureTorchModeOff;
            }
        }
        
        //NSLog(@"Committing configuration");
        [[self torchSession] commitConfiguration];
        
        //NSLog(@"Unlocking device for configuration");
        [self.torchDevice unlockForConfiguration];
    }
#endif
}

- (void)setTorchOnWithLevel:(CGFloat)level{
    [self.torchDevice lockForConfiguration:nil];
    
    [self.torchDevice setTorchModeOnWithLevel:level error:nil];
    
    [self.torchDevice unlockForConfiguration];
}

- (void)setIdleTimerDisabled:(BOOL)disabled{
    [UIApplication sharedApplication].idleTimerDisabled = disabled;
}

-(void)flashlightSessionResumeFromInturrupt{
	//NSLog(@"Flashlight is resuming from inturruption");
    [self setTorchOn:[self torchStateOnResume]];
}


@end
