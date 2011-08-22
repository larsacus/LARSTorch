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
#import <AVFoundation/AVFoundation.h>

@interface LARSTorch : NSObject {
    
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

@end
