# LARSTorch

## Description
It's an AVFoundation-based LED driver for iOS.  Does it need more of a description than that?

## Usage
``` objective-c
[[LARSTorch alloc] initWithTorchOn:YES];
```
or via the singleton:
```objective-c
[[LARSTorch sharedTorch] setTorchState:LARSTorchStateOn];
```

## Public Methods
```objective-c
/* Replies with a boolean if the torch is currently on */
- (BOOL)isTorchOn;

/* Replies if the `AVCaptureSession` for the torch has been interrupted by a system event */
- (BOOL)isInturrupted;

/* Method to light or extinguish the torch */
- (void)setTorchState:(LARSTorchState)torchState;

/* Sets torch on with a given non-maximum torch level */
- (BOOL)setTorchOnWithLevel:(CGFloat)level;
```

That's it.

## License
Copyright (c) 2011 Lars Anderson, theonlylars

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.