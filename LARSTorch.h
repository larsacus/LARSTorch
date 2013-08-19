//
//  LARSTorch.h
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
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(BOOL, LARSTorchState){
    LARSTorchStateOn = YES,
    LARSTorchStateOff = NO
};

@interface LARSTorch : NSObject

@property (nonatomic) LARSTorchState torchStateOnResume;

/** A convenience shared torch instance.
 */
+ (instancetype)sharedTorch;

/** A boolean that indicates whether or not a torch is available
 */
+ (BOOL)isTorchAvailable;

/** Initializes a new torch instance with a given torch state
 
 @param torchOn A LARSTorchState that indicates if the light should intially be turned on or not
 */
- (instancetype)initWithTorchState:(LARSTorchState)torchOn;

/** Sets torch mode to designated boolean torch state.
 
 @param torchState The state to set the torch to.
 */
- (void)setTorchState:(LARSTorchState)torchState;

/** Sets torch mode to "on" state with a given torch "level"
 
 @discussion The torch level must be between 0.f and 1.f
 @param level A torch level between 0 and 1
 */
- (BOOL)setTorchOnWithLevel:(CGFloat)level NS_AVAILABLE_IOS(6_0);

/** Indicates if torch is currently turned on or not.
 */
- (BOOL)isTorchOn;

/** Indicates if the torch is currently in an "inturruped" state or not. This may happen if the torch was running while your application went into a suspended state.
 
 @warning This value may not ever return true on iOS 5.0 and greater as iOS no longer requires an AVCaptureSession to turn on the torch.
 */
- (BOOL)isInturrupted NS_DEPRECATED_IOS(4_0, 5_0);

@end
