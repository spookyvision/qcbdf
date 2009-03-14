//
//  qc_bdfPlugIn.m
//  qc_bdf
//
//  Created by Anatol Ulrich on 3.1.09.
//  Copyright (c) 2009 hypnocode. All rights reserved.
//

/* It's highly recommended to use CGL macros instead of changing the current context for plug-ins that perform OpenGL rendering */
#import <OpenGL/CGLMacro.h>

#import "qc_bdfPlugIn.h"

#define	kQCPlugIn_Name				@"qc_bdf"
#define	kQCPlugIn_Description		@"qc_bdf description"

static void _BufferReleaseCallback(const void* address, void* context) {
	free((void*)address);
}


static int readByte(void *info) {
	return ((char*)info)[filepos++];
}

static void putPixel(void * surface, int x, int y, unsigned int color) {
	if (x<0 || y<0 || x >= currentWidth || y >= currentHeight) {
		return;
	}
	((unsigned int*) surface)[x+y*currentWidth] = color;
}

@implementation qc_bdfPlugIn
@dynamic inputFontPath, inputText, inputColor, inputOffsetX, inputOffsetY, outputText, outputW, outputH, outputImage;
/*
Here you need to declare the input / output properties as dynamic as Quartz Composer will handle their implementation
@dynamic inputFoo, outputBar;
*/

+ (NSDictionary*) attributes
{
	/*
	Return a dictionary of attributes describing the plug-in (QCPlugInAttributeNameKey, QCPlugInAttributeDescriptionKey...).
	*/
	
	return [NSDictionary dictionaryWithObjectsAndKeys:kQCPlugIn_Name, QCPlugInAttributeNameKey, kQCPlugIn_Description, QCPlugInAttributeDescriptionKey, nil];
}

+ (NSDictionary*) attributesForPropertyPortWithKey:(NSString*)key
{
	/*
	Specify the optional attributes for property based ports (QCPortAttributeNameKey, QCPortAttributeDefaultValueKey...).
	*/
	
	return nil;
}

+ (QCPlugInExecutionMode) executionMode
{
	/*
	Return the execution mode of the plug-in: kQCPlugInExecutionModeProvider, kQCPlugInExecutionModeProcessor, or kQCPlugInExecutionModeConsumer.
	*/
	
	return kQCPlugInExecutionModeProcessor;
}

+ (QCPlugInTimeMode) timeMode
{
	/*
	Return the time dependency mode of the plug-in: kQCPlugInTimeModeNone, kQCPlugInTimeModeIdle or kQCPlugInTimeModeTimeBase.
	*/
	
	return kQCPlugInTimeModeNone;
}

- (id) init
{
	if(self = [super init]) {
		/*
		Allocate any permanent resource required by the plug-in.
		*/
	}
	
	return self;
}

- (void) finalize
{
	/*
	Release any non garbage collected resources created in -init.
	*/
	
	[super finalize];
}

- (void) dealloc
{
	/*
	Release any resources created in -init.
	*/
	
	[super dealloc];
}

+ (NSArray*) plugInKeys
{
	/*
	Return a list of the KVC keys corresponding to the internal settings of the plug-in.
	*/
	
	return nil;
}

- (id) serializedValueForKey:(NSString*)key;
{
	/*
	Provide custom serialization for the plug-in internal settings that are not values complying to the <NSCoding> protocol.
	The return object must be nil or a PList compatible i.e. NSString, NSNumber, NSDate, NSData, NSArray or NSDictionary.
	*/
	
	return [super serializedValueForKey:key];
}

- (void) setSerializedValue:(id)serializedValue forKey:(NSString*)key
{
	/*
	Provide deserialization for the plug-in internal settings that were custom serialized in -serializedValueForKey.
	Deserialize the value, then call [self setValue:value forKey:key] to set the corresponding internal setting of the plug-in instance to that deserialized value.
	*/
	
	[super setSerializedValue:serializedValue forKey:key];
}

- (QCPlugInViewController*) createViewController
{
	/*
	Return a new QCPlugInViewController to edit the internal settings of this plug-in instance.
	You can return a subclass of QCPlugInViewController if necessary.
	*/
	
	return [[QCPlugInViewController alloc] initWithPlugIn:self viewNibName:@"Settings"];
}


- (BOOL) slurp {
	// whee, global state
	filepos = 0;
	
	FILE * pFile;
	long lSize;
	size_t result;
	
	if (self.inputFontPath == NULL)  return FALSE;
	NSString* fontPath = self.inputFontPath;
	if (![fontPath hasPrefix:@"/"]) {
		NSURL* schnitzel = [NSURL
							URLWithString:fontPath relativeToURL:[self compositionURL]];
		fontPath = [schnitzel path];
	}
	pFile = fopen ( [fontPath UTF8String] , "rb" );
	if (pFile==NULL) {return FALSE;}
	
	// obtain file size:
	fseek (pFile , 0 , SEEK_END);
	lSize = ftell (pFile);
	rewind (pFile);
	
	// allocate memory to contain the whole file:
	filecontents = (char*) malloc (sizeof(char)*lSize);
	if (filecontents == NULL) {return FALSE;}
	
	// copy the file into the buffer:
	result = fread (filecontents,1,lSize,pFile);
	if (result != lSize) {return FALSE;}
	
	fclose (pFile);
	return TRUE;
}

@end

@implementation qc_bdfPlugIn (Execution)

- (BOOL) startExecution:(id<QCPlugInContext>)context
{
	/*
	Called by Quartz Composer when rendering of the composition starts: perform any required setup for the plug-in.
	Return NO in case of fatal failure (this will prevent rendering of the composition to start).
	*/
	
	return YES;
}

- (void) enableExecution:(id<QCPlugInContext>)context
{
	/*
	Called by Quartz Composer when the plug-in instance starts being used by Quartz Composer.
	*/
}

- (BOOL) execute:(id<QCPlugInContext>)context atTime:(NSTimeInterval)time withArguments:(NSDictionary*)arguments
{
	/*
	 Called by Quartz Composer whenever the plug-in instance needs to execute.
	 Only read from the plug-in inputs and produce a result (by writing to the plug-in outputs or rendering to the destination OpenGL context) within that method and nowhere else.
	 Return NO in case of failure during the execution (this will prevent rendering of the current frame to complete).
	 
	 The OpenGL context for rendering can be accessed and defined for CGL macros using:
	 CGLContextObj cgl_ctx = [context CGLContextObj];
	 */
	
	self.outputText = @"test";
	// load bdf file if not already loaded
	if (![self.inputFontPath isEqualToString: loadedFontPath] || loadedFontPath == NULL) {
		// release old bdf, if any
		if (font != NULL) BDF_CloseFont(font);
		
		// load file into memory
		if (![self slurp]) {
			font = NULL;
			loadedFontPath = self.inputFontPath;
			return FALSE;
		}
		
		// load bdf from memory chunk
		int err;
		font = BDF_OpenFont(readByte, (void *) filecontents, &err);
		
		// cleanup
		free(filecontents);
		
		// ensure equality
		loadedFontPath = self.inputFontPath;
	}
	if (font == NULL) return TRUE;
	
	int x,y;
	x = y = 0;
	BDF_SizeH(font, (char*) [self.inputText UTF8String], &x, &y, &currentWidth, &currentHeight);
	self.outputW = currentWidth;
	self.outputH = currentHeight;
	
	id provider;
	int bpr = currentWidth*4;
	while (bpr%16) {
		bpr = (++currentWidth)*4;
	}
	pixels = calloc(currentWidth * currentHeight * 4, sizeof(unsigned int));
	
	const CGFloat* components = CGColorGetComponents(self.inputColor);
	int color = 0;
	for (short i = 0; i < 4; i++) {
		color |= (int) (components[3-i] * 255);
		color <<= 8;
	}
	
	BDF_DrawH(pixels, putPixel, font, (char*) [self.inputText UTF8String], 0 + self.inputOffsetX, currentHeight + self.inputOffsetY, color);
	
	
	provider = [context 
				outputImageProviderFromBufferWithPixelFormat:QCPlugInPixelFormatARGB8 
				pixelsWide:currentWidth 
				pixelsHigh:currentHeight 
				baseAddress:pixels 
				bytesPerRow:bpr 
				releaseCallback:_BufferReleaseCallback 
				releaseContext:NULL 
				colorSpace:[context colorSpace] 
				shouldColorMatch:YES];
	self.outputImage = provider;
	
	return TRUE;
}

- (void) disableExecution:(id<QCPlugInContext>)context
{
	/*
	Called by Quartz Composer when the plug-in instance stops being used by Quartz Composer.
	*/
}

- (void) stopExecution:(id<QCPlugInContext>)context
{
	/*
	Called by Quartz Composer when rendering of the composition stops: perform any required cleanup for the plug-in.
	*/
}


@end
