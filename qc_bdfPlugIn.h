//
//  qc_bdfPlugIn.h
//  qc_bdf
//
//  Created by Anatol Ulrich on 3.1.09.
//  Copyright (c) 2009 hypnocode. All rights reserved.
//

#import <Quartz/Quartz.h>
#include "SDL_bdf.h"

int currentWidth, currentHeight;
int filepos;
char* filecontents;

@interface qc_bdfPlugIn : QCPlugIn
{
	NSString* loadedFontPath;
	BDF_Font* font;
	unsigned int* pixels;
}

- (BOOL) slurp;

/*
Declare here the Obj-C 2.0 properties to be used as input and output ports for the plug-in e.g.
@property double inputFoo;
@property(assign) NSString* outputBar;
You can access their values in the appropriate plug-in methods using self.inputFoo or self.inputBar
*/

@property(assign) NSString* inputFontPath;
@property(assign) NSString* inputText;
@property(assign) CGColorRef inputColor;
@property double inputOffsetX;
@property double inputOffsetY;
@property(assign) NSString* outputText;
@property NSUInteger outputW, outputH;
@property(assign) id<QCPlugInOutputImageProvider> outputImage;


@end


@interface PixelImage : NSObject <QCPlugInOutputImageProvider>
{
	NSUInteger _width, _height;
}
@end