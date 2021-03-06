//
//  RoutePlanner.m
//  iWVU
//
//  Created by Jared Crawford on 6/25/09.
//  Copyright 2009 Jared Crawford. All rights reserved.
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

#import "RoutePlanner.h"



@implementation RoutePlanner

@synthesize startingBuilding;
@synthesize endingBuilding;





- (void)viewDidLoad {
    [super viewDidLoad];
	
	self.startingBuilding = @"Not Selected";
	self.endingBuilding = @"Not Selected";
	theDatePicker.date = [NSDate date];
	float bottom = self.view.frame.size.height;
	float DPheight = theDatePicker.frame.size.height;
	float DPwidth = theDatePicker.frame.size.width;
	theDatePicker.frame = CGRectMake(0, bottom, DPwidth, DPheight);
	
	
}



#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	if(section == 0){
		return 2;
	}
	else if(section == 1){
		return 1;
	}
	else if(section == 2){
		return 1;
	}
	return 0;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath{
    iWVUAppDelegate *AppDelegate = [UIApplication sharedApplication].delegate;
    [AppDelegate configureTableViewCell:cell inTableView:tableView forIndexPath:indexPath];
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier] autorelease];
    }

	
	cell.textLabel.adjustsFontSizeToFitWidth = YES;
	cell.detailTextLabel.adjustsFontSizeToFitWidth = YES;
	
	
	if(indexPath.section == 0){
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		if(indexPath.row == 0){
			cell.textLabel.text = @"Starting Point";
			cell.detailTextLabel.text = startingBuilding;
			
		}
		else {
			cell.textLabel.text = @"Destination";
			cell.detailTextLabel.text = endingBuilding;
		}
		

		if([cell.detailTextLabel.text isEqualToString:@"Not Selected"]){
			cell.detailTextLabel.textColor = [UIColor grayColor];
		}
		
	}
	else if(indexPath.section == 2){
		cell.textLabel.text = @"Departure Time";
		NSString *dateInMilTime = [[theDatePicker.date.description substringToIndex:16] substringFromIndex:11];
		NSString *displayDate;
		int hours = [[dateInMilTime substringToIndex:3] intValue];
		if(hours > 12){
			displayDate = [NSString stringWithFormat:@"%d%@ PM",(hours-12),[dateInMilTime substringFromIndex:2]];
		}
		else{
			displayDate = [NSString stringWithFormat:@"%d%@ AM",(hours),[dateInMilTime substringFromIndex:2]];
		}
		cell.detailTextLabel.text = displayDate;
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	}
	else if(indexPath.section == 1){
		cell.textLabel.text = @"                   Map Route";
		cell.accessoryType = UITableViewCellAccessoryNone;
	}
	
		
    return cell;
		
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	
	if(indexPath.section == 0){
		
		BuildingList *theBuildingView = [[BuildingList alloc] initWithDelegate:self];
		if(indexPath.row == 0){
			theBuildingView.navigationItem.title = @"Starting Point";
		}
		else {
			theBuildingView.navigationItem.title = @"Destination";
		}

		UIBarButtonItem *backBuildingButton = [[UIBarButtonItem alloc] initWithTitle:@"Buildings" style:UIBarButtonItemStyleBordered	target:nil action:nil];
		theBuildingView.navigationItem.backBarButtonItem = backBuildingButton;
		[backBuildingButton release];
		[self.navigationController pushViewController:theBuildingView animated:YES];
		[theBuildingView release];
		
		
		
	}
	else if(indexPath.section == 2){
		[self displayOrHideDatePicker];
	}
	else if(indexPath.section == 1){
		//
		BOOL locationError = NO;
		NSIndexPath *startIndex = [NSIndexPath indexPathForRow:0 inSection:0];
		NSIndexPath *endIndex = [NSIndexPath indexPathForRow:1 inSection:0];
		NSString *startBuilding = [tableView cellForRowAtIndexPath:startIndex].detailTextLabel.text;
		NSString *endBuilding = [tableView cellForRowAtIndexPath:endIndex].detailTextLabel.text;
		
		if((![startBuilding isEqualToString:@"Not Selected"])
		   && (![endBuilding isEqualToString:@"Not Selected"])){
			
			//
			NSString *buildingsLatPath = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"BuildingsLat.plist"];
			NSString *buildingsLongPath = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"BuildingsLong.plist"];
			
			//Get Long and Lat of Building
			
			NSDictionary *buildingsLat = [NSDictionary dictionaryWithContentsOfFile:buildingsLatPath];
			NSDictionary *buildingsLong = [NSDictionary dictionaryWithContentsOfFile:buildingsLongPath];
			
			double startLong = [[buildingsLong objectForKey:startBuilding] doubleValue];
			double startLat = [[buildingsLat objectForKey:startBuilding] doubleValue];
			
			double endLong = [[buildingsLong objectForKey:endBuilding] doubleValue];
			double endLat = [[buildingsLat objectForKey:endBuilding] doubleValue];
			
			
			
			
			if ([@"Current Location" isEqualToString:startBuilding]) {
				CLLocation *loc = aLocationManagaer.location;
				if (loc){
					if (NSOrderedAscending == [timeStampOfFirstUpdate compare:aLocationManagaer.location.timestamp] ) {
						CLLocationCoordinate2D currectLocation = aLocationManagaer.location.coordinate;
						startLong = currectLocation.longitude;
						startLat = currectLocation.latitude;
					}
					else {
						locationError = YES;
					}

				}
				else {
					locationError = YES;
				}

			}
			
			if ([@"Current Location" isEqualToString:endBuilding]) {
				CLLocation *loc = aLocationManagaer.location;
				if (loc){
					if (NSOrderedAscending == [timeStampOfFirstUpdate compare:aLocationManagaer.location.timestamp] ) {
						CLLocationCoordinate2D currectLocation = aLocationManagaer.location.coordinate;
						endLong = currectLocation.longitude;
						endLat = currectLocation.latitude;
					}
					else {
						locationError = YES;
					}
					
				}
				else {
					locationError = YES;
				}
			}
			
			
			
			
			
			//Type of routing - Departing Time or Arival Time
			NSString *timeType=@"dep"; //@"arr"
			
			//Get start time
			NSString *dateInMilTime = [[theDatePicker.date.description substringToIndex:16] substringFromIndex:11];
			NSString *displayDate;
			int hours = [[dateInMilTime substringToIndex:3] intValue];
			if(hours > 12){
				displayDate = [NSString stringWithFormat:@"%d%@PM",(hours-12),[dateInMilTime substringFromIndex:2]];
			}
			else{
				displayDate = [NSString stringWithFormat:@"%d%@AM",(hours),[dateInMilTime substringFromIndex:2]];
			}
			displayDate = [displayDate stringByReplacingOccurrencesOfString:@":" withString:@"%3A"];
			
			NSString *month = [[theDatePicker.date.description substringFromIndex:5] substringToIndex:2];
			NSString *day = [[theDatePicker.date.description substringFromIndex:8] substringToIndex:2];
			NSString *year = [[theDatePicker.date.description substringFromIndex:2] substringToIndex:2];
			NSString *MDY = [NSString stringWithFormat:@"%@%@%@%@%@",month,@"%2F",day,@"%2F",year];
			////////////////////////////
			
			if (locationError) {
				NSString *message = @"";
				if ([CLLocationManager locationServicesEnabled] == NO) {
					message = @"You have disable Location Services on your device. iWVU must be able to determine your location to use this feature.";
				}
				else {
					message = @"Your current location could not be determined with enough accuracy to use this feature. Wait a few seconds before trying again.";
				}

				
				UIAlertView *err = [[UIAlertView alloc] initWithTitle:@"Current Location Unavailable" message:message delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
				[err show];
				[err release];
			}
			else if((startLat==0)||(startLong==0)||(endLong==0)||(endLat==0)){
				UIAlertView *err = [[UIAlertView alloc] initWithTitle:@"Location Unavailable" message:@"The location of this building is unknown to the developer. If you know the location of this building, please contact him." delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
				[err show];
				[err release];
			}
			else{
				NSString *startBuildingEscaped = [startBuilding stringByReplacingOccurrencesOfString:@"&" withString:@"%26"];
				NSString *endBuildingEscaped = [endBuilding stringByReplacingOccurrencesOfString:@"&" withString:@"%26"];
				
				NSString *transitURL = [NSString stringWithFormat:@"http://maps.google.com/maps?saddr=%@@%f,%f&daddr=%@@%f,%f&dirflg=r&t=k&ttype=%@&date=%@&time=%@",startBuildingEscaped,startLat,startLong,endBuildingEscaped,endLat,endLong,timeType,MDY,displayDate];
				transitURL = [transitURL stringByReplacingOccurrencesOfString:@" " withString:@"+"];
				
				NSLog(@"transitURL: %@",transitURL);
				[[UIApplication sharedApplication] openURL:[NSURL URLWithString:transitURL]];
			}
			
		}
		else{
			UIAlertView *err = [[UIAlertView alloc] initWithTitle:nil message:@"You must select a starting point and a destination" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
			[err show];
			[err release];
		}
			
	}
	
	
	
}


- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section{
	if(section == 1){
		return @"The Maps application will be opened.\n\nYou can use the clock button to view alternate route suggestions or adjust arival and departure times.\n\nUse list view to see step by step instructions. List view is found by clicking the page curl button.";
	}
	
	return nil;
}



#pragma mark BuildingListDelegate Methods

-(void)BuildingList:(BuildingList *)aBuildingList didFinishWithSelectionType:(BuildingSelectionType)type{
	static BOOL havePickedBothBuildings = NO;
	
	if (havePickedBothBuildings == NO) {
	
		NSString *firstBuildingType = aBuildingList.navigationItem.title;
		
		if (type == BuildingSelectionTypeBuilding) {
			
			NSString *buildingName = [aBuildingList selectedBuildingName];
			
			if ([firstBuildingType isEqualToString:@"Starting Point"]) {
				startingBuilding = buildingName;
			}
			else {
				endingBuilding = buildingName;
			}
		}
		else if(type == BuildingSelectionTypeAllBuildings){
			//not possible
		}
		else if(type == BuildingSelectionTypeCurrentLocation){
			timeStampOfFirstUpdate = [[NSDate date] retain];
			aLocationManagaer = [[CLLocationManager alloc] init];
			aLocationManagaer.distanceFilter = 25;
			aLocationManagaer.desiredAccuracy = 250;
			[aLocationManagaer startUpdatingLocation];
			if ([firstBuildingType isEqualToString:@"Starting Point"]) {
				startingBuilding = @"Current Location";
			}
			else {
				endingBuilding = @"Current Location";
			}
		}
		
		BuildingList *theBuildingView = [[BuildingList alloc] initWithDelegate:self];
		if([firstBuildingType isEqualToString:@"Destination"]){
			theBuildingView.navigationItem.title = @"Starting Point";
		}
		else {
			theBuildingView.navigationItem.title = @"Destination";
		}
		UIBarButtonItem *backBuildingButton = [[UIBarButtonItem alloc] initWithTitle:@"Buildings" style:UIBarButtonItemStyleBordered	target:nil action:nil];
		theBuildingView.navigationItem.backBarButtonItem = backBuildingButton;
		[backBuildingButton release];
		[self.navigationController popViewControllerAnimated:NO];
		[self.navigationController pushViewController:theBuildingView animated:YES];
		[theBuildingView release];
		
		
		havePickedBothBuildings = YES;
	}
	else if (havePickedBothBuildings) {
		
		NSString *firstBuildingType = aBuildingList.navigationItem.title;
		
		if (type == BuildingSelectionTypeBuilding) {
			
			NSString *buildingName = [aBuildingList selectedBuildingName];
			
			if ([firstBuildingType isEqualToString:@"Starting Point"]) {
				startingBuilding = buildingName;
			}
			else {
				endingBuilding = buildingName;
			}
		}
		else if(type == BuildingSelectionTypeAllBuildings){
			//not possible
		}
		else if(type == BuildingSelectionTypeCurrentLocation){
			timeStampOfFirstUpdate = [[NSDate date] retain];
			aLocationManagaer = [[CLLocationManager alloc] init];
			aLocationManagaer.distanceFilter = 25;
			aLocationManagaer.desiredAccuracy = 250;
			[aLocationManagaer startUpdatingLocation];
			if ([firstBuildingType isEqualToString:@"Starting Point"]) {
				startingBuilding = @"Current Location";
			}
			else {
				endingBuilding = @"Current Location";
			}
		}
		
		
		[self.navigationController popViewControllerAnimated:YES];
	}
	[theTableView reloadData];
}



-(BOOL)allowsCurrentLocation{
	return YES;
}

-(BOOL)allowsAllBuildings{
	return NO;
}








- (void)dealloc {
	self.startingBuilding = nil;
	self.endingBuilding = nil;
    [super dealloc];
}

	
	
-(void)setBuilding:(NSString *)BuildingName forStartOrEnd:(NSString *)startingOrEnding{
	NSIndexPath *theIndexPath;
	if([startingOrEnding isEqualToString:@"Starting"]){
		self.startingBuilding = BuildingName;
		theIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
	}
	else{
		self.endingBuilding = BuildingName;
		theIndexPath = [NSIndexPath indexPathForRow:1 inSection:0];
	}
	UITableViewCell *cell = [theTableView cellForRowAtIndexPath:theIndexPath];
	cell.detailTextLabel.text = BuildingName;
}




-(void)displayOrHideDatePicker{
	
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
	[UIView setAnimationBeginsFromCurrentState:YES];
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDuration:.7];	
	
	
	float bottom = self.view.frame.size.height;
	float DPheight = theDatePicker.frame.size.height;
	float DPwidth = theDatePicker.frame.size.width;
	if(theDatePicker.frame.origin.y == (bottom-DPheight)){
		theDatePicker.frame = CGRectMake(0, bottom, DPwidth, DPheight);
		theTableView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
	}
	else{
		theDatePicker.frame = CGRectMake(0, bottom-DPheight, DPwidth, DPheight);
		theTableView.contentInset = UIEdgeInsetsMake(0, 0, DPheight, 0);
		
	}
	
	
	
	[UIView commitAnimations];
}



-(IBAction) dateChanged:(UIDatePicker *)sender{
	//
	[theTableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationFade];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation{
	//these are the default's, but I'm going to explicitly define them, just to be safe
	if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
		return NO;
	}
	return YES;
}


@end

