//
//  TickerBar.m
//  iWVU
//
//  Created by Jared Crawford on 1/12/10.
//  Copyright Jared Crawford 2009. All rights reserved.
//

/*
 Copyright (c) 2009 Jared Crawford
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 
 The trademarks owned or managed by the West Virginia 
 University Board of Governors (WVU) are used under agreement 
 between the above copyright holder(s) and WVU. The West 
 Virginia University Board of Governors maintains ownership of all 
 trademarks. Reuse of this software or software source code, in any 
 form, must remove all references to any trademark owned or 
 managed by West Virginia University.
 */ 

#import "TickerBar.h"


#define SLIDE_OUT @"slidein"
#define SLIDE_IN @"slideout"


@implementation TickerBar

@synthesize delegate;
@synthesize rssURL;
@synthesize feedName;

-(UILabel *)getLabel{
	return _label;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event{
	if (event.type == UIEventTypeTouches) {
		for (FPItem *newsItem in newsFeed.items) {
			if ([newsItem.title isEqualToString:[self getLabel].text]) {
				[delegate tickerBar:self itemSelected:newsItem.link.href];
			}
		}
	}
}



-(id)initWithURL:(NSURL *)aURL andFeedName:(NSString *)aFeedName{
	self = [[TickerBar alloc] initWithStyle:TTActivityLabelStyleBlackBanner];
	self.rssURL = aURL;
	self.feedName = aFeedName;
	self.text = [NSString stringWithFormat:@"%@ Loading...", feedName];
	self.clipsToBounds = YES;
	cancelAnimationsBefore = nil;
	return self;
}


-(void)startTicker{
	tickerIsPaused = NO;
	if(newsFeed){
		[self displayTickerBarItem:[[NSDate date] retain]];
	}
	else if (rssURL) {
		NSThread *thread = [[NSThread alloc] initWithTarget:self selector:@selector(downloadRSSFeed) object:nil];
		[thread start];
		[thread release];
	}
}



-(void)downloadRSSFeed{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	//NSString *rssURL = @"http://wvutoday.wvu.edu/n/rss/";
	//http://reader.mac.com/mobile/v1/http%3A%2F%2Fwvutoday.wvu.edu%2Fn%2Frss%2F
	NSData *data = [NSData dataWithContentsOfURL:rssURL];
	NSError *err;
	FPFeed *aFeed = [FPParser parsedFeedWithData:data error:&err];
	if ((!data)||(!aFeed)) {
		newsFeed = nil;
		[self performSelectorOnMainThread:@selector(downloadOfRSSFailed) withObject:nil waitUntilDone:NO];
		//break
	}
	else {
		newsFeed = [aFeed retain];
		[self performSelectorOnMainThread:@selector(displayTickerBarItem:) withObject:[[NSDate date] retain] waitUntilDone:NO];
	}
	[pool release];
	
}

-(void)downloadOfRSSFailed{
	self.isAnimating = NO;
	self.text = [NSString stringWithFormat:@"%@ Unavailable", feedName];
}


-(void)willMoveToWindow:(UIWindow *)newWindow{
	if(!newWindow){
		[self pauseTicker];
	}
	else if(tickerIsPaused){
		[self startTicker];
	}
}

-(void)pauseTicker{
	tickerIsPaused = YES;
}

-(void)displayTickerBarItem:(NSDate *)timestamp{
	if(tickerIsPaused){
		return;
	}
	if (newsFeed){
		
		if ((!cancelAnimationsBefore)||([cancelAnimationsBefore compare:timestamp] < 0)) {
			static int currentItem = -1;
			currentItem++;
			if (currentItem >= [newsFeed.items count]) {
				currentItem = 0;
			}
			
			FPItem *newsItem = [newsFeed.items objectAtIndex:currentItem];
			self.isAnimating = NO;
			UILabel *label = [self getLabel];
			
			
			label.text = newsItem.title;
			CGSize size = [label.text sizeWithFont:label.font];
			float padding= 5;
			float stopPosition = (self.frame.size.width-size.width)/2.0;
			if (size.width > self.frame.size.width) {
				stopPosition = -1.0*(size.width - self.frame.size.width)-padding;
			}
			
			//start the label offscreen
			label.frame = CGRectMake(self.frame.size.width + 5, label.frame.origin.y, size.width, size.height);
			label.alpha = 1.0;
			
			//then animate it moving onscreen
			[UIView beginAnimations:SLIDE_IN context:timestamp];
			[UIView setAnimationDelegate:self];
			[UIView setAnimationDuration:TICKER_ANIMATION_DURATION];
			[UIView	setAnimationCurve:UIViewAnimationCurveEaseInOut];
			[UIView setAnimationDidStopSelector:@selector(callNextWithID:finished:context:)];
			
			label.frame = CGRectMake(stopPosition, label.frame.origin.y, size.width, size.height);
			
			[UIView commitAnimations];
			
		}
		else {
			[timestamp release];
		}

	}
}


-(void)fadeOutFeed:(NSTimeInterval)duration{
	[cancelAnimationsBefore release];
	cancelAnimationsBefore = [[NSDate date] retain];
	
	[UIView beginAnimations:@"FadeOutLabel" context:nil];
	[UIView setAnimationDuration:duration];
	[UIView	setAnimationCurve:UIViewAnimationCurveEaseIn];
	
	[self getLabel].alpha = 0;
	
	[UIView commitAnimations];
}

-(void)holdTickerBarItem:(NSDate *)timestamp{
	if(tickerIsPaused){
		return;
	}
	if ((!cancelAnimationsBefore)||([cancelAnimationsBefore compare:timestamp] < 0)) {
		[self performSelector:@selector(removeTickerBarItem:) withObject:timestamp afterDelay:TICKER_WAIT_DURATION];
	}
	else {
		[timestamp release];
	}

	
	
}

-(void)removeTickerBarItem:(NSDate *)timestamp{
	if ((!cancelAnimationsBefore)||([cancelAnimationsBefore compare:timestamp] < 0)) {
		if(tickerIsPaused){
			return;
		}
		UILabel *label = [self getLabel];
		
		
		
		
		[UIView beginAnimations:SLIDE_OUT context:timestamp];
		[UIView setAnimationDelegate:self];
		[UIView setAnimationDuration:TICKER_REMOVE_DURATION];
		[UIView	setAnimationCurve:UIViewAnimationCurveEaseInOut];
		[UIView setAnimationDidStopSelector:@selector(callNextWithID:finished:context:)];
		
		
		float x = (-1.0 * label.frame.size.width) - 5.0;
		float y = label.frame.origin.y;
		float width = label.frame.size.width;
		float height = label.frame.size.height;
		label.frame = CGRectMake(x, y, width, height);
		
		[UIView commitAnimations];
		
		
	}
	else {
		[timestamp release];
	}

}


-(void)callNextWithID:(NSString *)animationID finished:(NSNumber *)finished context:(NSDate *)timestamp{
	
	//this is to conform with animation delegate protocol so we can pass the timestamp along
	
	if ([animationID isEqualToString:SLIDE_IN]) {
		[self holdTickerBarItem:timestamp];
	}
	else {
		[self displayTickerBarItem:timestamp];
	}
}

-(void)dealloc{
	self.delegate = nil;
	self.rssURL = nil;
	self.feedName = nil;
	[newsFeed release];
	newsFeed = nil;
	[cancelAnimationsBefore release];
	cancelAnimationsBefore = nil;
	[super dealloc];
}

@end
