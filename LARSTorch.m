//
//  LATorch.m
//  Light²
//
//  Created by Lars Anderson on 6/4/11.
//  Copyright 2011 Lars Anderson. All rights reserved.
//

#import "LATorch.h"
#import <Foundation/Foundation.h>
#include <sys/types.h>
#include <sys/sysctl.h>

#define ON YES
#define OFF NO

#define NSLog //NSLog

@implementation LATorch


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
        NSLog(@"System version is %f", [self systemVersion]);
        
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
        return [[self torchDevice] torchMode] == AVCaptureTorchModeOn;
    }
    return  [[self torchSession] isRunning] && 
            ([[self torchDevice] torchMode] == AVCaptureTorchModeOn);
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

- (void)setTorchOn:(BOOL)torchOn{
#if !TARGET_IPHONE_SIMULATOR
    if (![self torchSession] && ([self systemVersion] < 5.0f)) {
        NSLog(@"Creating session");
        _torchSession = [[AVCaptureSession alloc] init];
        NSLog(@"Done!");
    }
    
    if (![self torchDevice]) {
        NSLog(@"Creating device");
        _torchDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        NSLog(@"Done!");
    }
    
    if ([self torchDevice] && [[self torchDevice] hasTorch]) {

        NSLog(@"Device has useable torch!");
        //set session preset to lowest allowed to conserve system resources
        if ([self systemVersion] < 5.0f){
            NSLog(@"Session preset set to low");
            [[self torchSession] setSessionPreset:AVCaptureSessionPresetLow];
        }
        
        NSError *lockError = nil;
        NSLog(@"Locking device for configuration");
        if(![[self torchDevice] lockForConfiguration:&lockError]){
            NSLog(@"Lock error: %@\nReason: %@", [lockError localizedDescription], [lockError localizedFailureReason]);
        }
        
        NSLog(@"Beginning configuration");
        [[self torchSession] beginConfiguration];
        
        NSLog(@"Verifying session input");
        if (![[[self torchSession] inputs] containsObject:[self torchDeviceInput]] && ([self systemVersion] < 5.0f)) {
            NSLog(@"Input is not attached to session");
            if (![self torchDeviceInput]) {
                NSLog(@"Creating...");
                NSError *deviceError = nil;
                _torchDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:[self torchDevice] error:&deviceError];
                
                if (deviceError) {
                    NSLog(@"Device Error: %@\nReason: %@", [deviceError localizedDescription], [deviceError localizedFailureReason]);
                }
                NSLog(@"Done!");
            }
            NSLog(@"Adding input to session");
            [[self torchSession] addInput:[self torchDeviceInput]];
        }
        
        NSLog(@"Verifying session output");
        //light does not function without capture output
        if (![[[self torchSession] outputs] containsObject:[self torchOutput]] && ([self systemVersion] < 5.0f)) {
            NSLog(@"Output not attached to session");
            if (![self torchOutput]) {
                NSLog(@"Creating...");
                _torchOutput = [[AVCaptureVideoDataOutput alloc] init];
            }
            NSLog(@"Adding input to session");
            [[self torchSession] addOutput:[self torchOutput]];
        }
        
        NSLog(@"Setting torch mode to %@", torchOn ? @"ON" : @"OFF");
        if (torchOn) {
            [[self torchDevice] setTorchMode:AVCaptureTorchModeOn];
            [[self torchDevice] setFlashMode:AVCaptureFlashModeOn];
        }
        else {
            [[self torchDevice] setTorchMode:AVCaptureTorchModeOff];
            [[self torchDevice] setFlashMode:AVCaptureFlashModeOff];
        }
        
        NSLog(@"Unlocking device for configuration");
        [[self torchDevice] unlockForConfiguration];
        
        NSLog(@"Committing configuration");
        [[self torchSession] commitConfiguration];
        
        
        if (![[self torchSession] isRunning] && ([self systemVersion] < 5.000000f)) {
            NSLog(@"Starting session");
            [[self torchSession] startRunning];
        }
        else{
            NSLog(@"Session is already started or session does not need to exist");
        }
    }
#endif
}

- (void)verifyTorchSubsystemsWithTorchOn:(BOOL)torchOn{
#if !TARGET_IPHONE_SIMULATOR
    //session
    if (![self torchDevice]) {
        _torchDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    }
    
    if ([[self torchDevice] hasTorch] && [[self torchDevice] hasFlash]){
        if (![self torchDeviceInput]) {
            NSError *deviceError = nil;
            
            _torchDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:[self torchDevice] error: &deviceError];
        }
        
        //light does not function without capture output
        if (![self torchOutput]) {
            _torchOutput = [[AVCaptureVideoDataOutput alloc] init];
        }
        
        //check if torch session is functioning properly
        if (![self torchSession]) {
            _torchSession = [[AVCaptureSession alloc] init];
            
            //verify session preset
            [[self torchSession] setSessionPreset:AVCaptureSessionPresetLow];
            [self setTorchOn:torchOn];
            
            [[self torchSession] startRunning];
        }
        else{//torch session is running, verify session subsystems
            [[self torchSession] setSessionPreset:AVCaptureSessionPresetLow];
            if ([self isTorchOn] != torchOn) {
                [self setTorchOn:torchOn];
            }
            if (![[self torchSession] isRunning]) {
                [[self torchSession] startRunning];
            }
        }
    }
#endif
}

-(void)flashlightSessionResumeFromInturrupt{
	//NSLog(@"Flashlight is resuming from inturruption");
    [self setTorchOn:[self torchStateOnResume]];
}

- (void)dealloc{
#if !TARGET_IPHONE_SIMULATOR
    [_torchDevice release];
    [_torchDeviceInput release];
    [_torchOutput release];

    
    if ([[self torchSession] isRunning]) {
        [[self torchSession] stopRunning];
    }
    [_torchSession release];
#endif
    [super dealloc];
}

@end
