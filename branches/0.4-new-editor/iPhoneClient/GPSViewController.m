//
//  GPSViewController.m
//  ARIS
//
//  Created by Ben Longoria on 2/11/09.
//  Copyright 2009 University of Wisconsin. All rights reserved.
//

#import "GPSViewController.h"
#import "AppModel.h"
#import "Location.h"
#import "Player.h"
#import "ARISAppDelegate.h"
#import "AnnotationView.h"
#import "Media.h"
#import "ItemAnnotation.h"

//static int DEFAULT_ZOOM = 16;
//static float INITIAL_SPAN = 0.001;

@implementation GPSViewController

@synthesize mapView;
@synthesize autoCenter;
@synthesize mapTypeButton;
@synthesize playerTrackingButton;

//Override init for passing title and icon to tab bar
- (id)initWithNibName:(NSString *)nibName bundle:(NSBundle *)nibBundle
{
    self = [super initWithNibName:nibName bundle:nibBundle];
    if (self) {
        self.title = @"GPS";
        self.tabBarItem.image = [UIImage imageNamed:@"GPS.png"];
		appModel = [(ARISAppDelegate *)[[UIApplication sharedApplication] delegate] appModel];
		
		autoCenter = YES;
				
		//register for notifications
		NSNotificationCenter *dispatcher = [NSNotificationCenter defaultCenter];
		[dispatcher addObserver:self selector:@selector(refresh) name:@"PlayerMoved" object:nil];
		[dispatcher addObserver:self selector:@selector(refreshViewFromModel) name:@"ReceivedLocationList" object:nil];
		
		
	}
	
    return self;
}
		
- (IBAction)changeMapType: (id) sender {
	switch (mapView.mapType) {
		case MKMapTypeStandard:
			mapView.mapType=MKMapTypeSatellite;
			break;
		case MKMapTypeSatellite:
			mapView.mapType=MKMapTypeHybrid;
			break;
		case MKMapTypeHybrid:
			mapView.mapType=MKMapTypeStandard;
			break;
	}
}

- (IBAction)refreshButtonAction: (id) sender{

	NSLog(@"GPSViewController: Refresh Button Touched");
		
	//Force a location update
	ARISAppDelegate *appDelegate = (ARISAppDelegate *) [[UIApplication sharedApplication] delegate];
	[appDelegate.myCLController.locationManager stopUpdatingLocation];
	[appDelegate.myCLController.locationManager startUpdatingLocation];

	//Rerfresh all contents
	[self refresh];

}
		
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	
	NSLog(@"Begin Loading GPS View");

	//Setup the Map
	CGFloat tableViewHeight = 325; //416-44; // todo: get this from const
	CGRect mainViewBounds = self.view.bounds;
	CGRect tableFrame;
	tableFrame = CGRectMake(CGRectGetMinX(mainViewBounds),
							CGRectGetMinY(mainViewBounds),
							CGRectGetWidth(mainViewBounds),
							tableViewHeight);
	
	NSLog(@"GPSViewController: Mapview about to be inited.");
	mapView = [[MKMapView alloc] initWithFrame:tableFrame];
	MKCoordinateRegion region = mapView.region;
	region.span.latitudeDelta=0.001;
	region.span.longitudeDelta=0.001;
	[mapView setRegion:region animated:NO];
	[mapView regionThatFits:region];
	mapView.showsUserLocation = YES;
	[mapView setDelegate:self]; //View will request annotation views from us
	[self.view addSubview:mapView];
	NSLog(@"GPSViewController: Mapview inited and added to view");
	
	
	//Setup the buttons
	mapTypeButton.target = self; 
	mapTypeButton.action = @selector(changeMapType:);
	
	playerTrackingButton.target = self; 
	playerTrackingButton.action = @selector(refreshButtonAction:);
	
	[self refresh];	
	
	

	NSLog(@"GPSViewController: View Loaded");
}

- (void)viewDidAppear:(BOOL)animated {
	[self refresh];		
	NSLog(@"GPSViewController: view did appear");
}


// Updates the map to current data for player and locations from the server
- (void) refresh {
	NSLog(@"GPSViewController: refresh requested");	
	
	//Update the locations
	[appModel fetchLocationList];
	
	//Zoom and Center
	[self zoomAndCenterMap];

}

-(void) zoomAndCenterMap {
	
	//Center the map on the player
	MKCoordinateRegion region = mapView.region;
	region.center = appModel.playerLocation.coordinate;
	[mapView setRegion:region animated:YES];
	
	//Set to default zoom
	//mapView.contents.zoom = DEFAULT_ZOOM;
}



- (void)refreshViewFromModel {
	NSLog(@"GPSViewController: Refreshing view from model");
	
	//Blow away the old markers except for the player marker
	
	NSEnumerator *existingAnnotationsEnumerator = [[[mapView annotations] copy] objectEnumerator];
	NSObject <MKAnnotation> *annotation;
	while (annotation = [existingAnnotationsEnumerator nextObject]) {
		if (annotation != mapView.userLocation) [mapView removeAnnotation:annotation];
	}
	
	
	//Add the freshly loaded locations from the notification
	for ( Location* location in appModel.locationList ) {
		NSLog(@"GPSViewController: Adding location annotation for:%@ id:%d", location.name, location.locationId);
		if (location.hidden == YES) continue;
		CLLocationCoordinate2D locationLatLong = location.location.coordinate;
		
		ItemAnnotation *anItem = [[ItemAnnotation alloc]initWithCoordinate:locationLatLong];
		
		anItem.title = location.name;
		anItem.subtitle = [NSString stringWithFormat:@"%d",location.qty];
		if (location.iconMediaId != 0) { //look for info about image for icon, if we have one
			anItem.iconMediaId = location.iconMediaId;
		} else {
			location.iconMediaId = nil;
		}
		[mapView addAnnotation:anItem];
		[mapView selectAnnotation:anItem animated:YES];

		[anItem release];
	}
	
	//Add the freshly loaded players from the notification
	for ( Player *player in appModel.playerList ) {
		if (player.hidden == YES) continue;
		CLLocationCoordinate2D locationLatLong = player.location.coordinate;

		PlayerAnnotation *aPlayer = [[PlayerAnnotation alloc]initWithCoordinate:locationLatLong];
		aPlayer.title = player.name;
		[mapView addAnnotation:aPlayer];
		[aPlayer release];
	}
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}

- (void)dealloc {
	[appModel release];
    [super dealloc];
}

-(UIImage *)addTitle:(NSString *)imageTitle quantity:(int)quantity toImage:(UIImage *)img {
	
	NSString *calloutString;
	if (quantity > 1) {
		calloutString = [NSString stringWithFormat:@"%@:%d",imageTitle, quantity];
	} else {
		calloutString = imageTitle;
	}
 	UIFont *myFont = [UIFont fontWithName:@"Arial" size:12];
	CGSize textSize = [calloutString sizeWithFont:myFont];
	CGRect textRect = CGRectMake(0, 0, textSize.width + 10, textSize.height);
	
	//callout path
	CGMutablePathRef calloutPath = CGPathCreateMutable();
	CGPoint pointerPoint = CGPointMake(textRect.origin.x + 0.6 * textRect.size.width,  textRect.origin.y + textRect.size.height + 5);
	CGPathMoveToPoint(calloutPath, NULL, textRect.origin.x, textRect.origin.y);
	CGPathAddLineToPoint(calloutPath, NULL, textRect.origin.x, textRect.origin.y + textRect.size.height);
	CGPathAddLineToPoint(calloutPath, NULL, pointerPoint.x - 5.0, textRect.origin.y + textRect.size.height);
	CGPathAddLineToPoint(calloutPath, NULL, pointerPoint.x, pointerPoint.y);
	CGPathAddLineToPoint(calloutPath, NULL, pointerPoint.x + 5.0, textRect.origin.y+ textRect.size.height);
	CGPathAddLineToPoint(calloutPath, NULL, textRect.origin.x + textRect.size.width, textRect.origin.y + textRect.size.height);
	CGPathAddLineToPoint(calloutPath, NULL, textRect.origin.x + textRect.size.width, textRect.origin.y);
	CGPathAddLineToPoint(calloutPath, NULL, textRect.origin.x, textRect.origin.y);
	
	
	
	CGRect imageRect = CGRectMake(0, textSize.height + 10.0, img.size.width, img.size.height);
	CGRect backgroundRect = CGRectUnion(textRect, imageRect);
	if (backgroundRect.size.width > img.size.width) {
		imageRect.origin.x = (backgroundRect.size.width - img.size.width) / 2.0;
	}
	
	CGSize contextSize = backgroundRect.size;
	UIGraphicsBeginImageContext(contextSize);
	CGContextAddPath(UIGraphicsGetCurrentContext(), calloutPath);
	[[UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.6] set];
	CGContextFillPath(UIGraphicsGetCurrentContext());
	[[UIColor blackColor] set];
	CGContextAddPath(UIGraphicsGetCurrentContext(), calloutPath);
	CGContextStrokePath(UIGraphicsGetCurrentContext());
	[img drawAtPoint:imageRect.origin];
	[calloutString drawInRect:textRect withFont:myFont lineBreakMode:UILineBreakModeWordWrap alignment:UITextAlignmentCenter];
	UIImage *returnImage = UIGraphicsGetImageFromCurrentImageContext();
	CGPathRelease(calloutPath);
	UIGraphicsEndImageContext();
	
	return returnImage;
}


//-(UIImage *)addText:(NSString *)text1 toImage:(UIImage *)img {
//    int w = img.size.width;
//    int h = img.size.height; 
//    //lon = h - lon;
//    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
//    CGContextRef context = CGBitmapContextCreate(NULL, w, h, 8, 4 * w, colorSpace, kCGImageAlphaPremultipliedFirst);
//    
//    CGContextDrawImage(context, CGRectMake(0, 0, w, h), img.CGImage);
//    CGContextSetRGBFillColor(context, 0.0, 0.0, 1.0, 1);
//	
//    char* text	= (char *)[text1 cStringUsingEncoding:NSASCIIStringEncoding];// "05/05/09";
//    CGContextSelectFont(context, "Arial", 18, kCGEncodingMacRoman);
//    CGContextSetTextDrawingMode(context, kCGTextFill);
//    CGContextSetRGBFillColor(context, 255, 255, 255, 1);
//	
//	
//    //rotate text
//    CGContextSetTextMatrix(context, CGAffineTransformMakeRotation( -M_PI/4 ));
//	
//    CGContextShowTextAtPoint(context, 4, 52, text, strlen(text));
//	
//	
//    CGImageRef imageMasked = CGBitmapContextCreateImage(context);
//    CGContextRelease(context);
//    CGColorSpaceRelease(colorSpace);
//	
//    return [UIImage imageWithCGImage:imageMasked];
//}
//
#pragma mark Views for annotations

- (MKAnnotationView *)mapView:(MKMapView *)myMapView viewForAnnotation:(id <MKAnnotation>)annotation{

	
	//Player
	if (annotation == mapView.userLocation)
	{
		 return nil; //Let it do it's own thing
	}
	
	//Other Players
	else if ([annotation isMemberOfClass:[PlayerAnnotation class]]) {
				AnnotationView *playerAnnotationView = [[AnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"OtherPlayerAnnotation"];
				playerAnnotationView.image = [UIImage imageNamed:@"marker-other-player.png"];
				return playerAnnotationView;	
	} 
	
	//Everything else
	else {
		Media *iconMedia = [appModel.mediaList objectForKey:[NSNumber numberWithInt:[(ItemAnnotation *)annotation iconMediaId]]];
		UIImage *myImage;
		
		AnnotationView *annotationView=[[AnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:[NSString stringWithFormat:@"%@:%@",[annotation title], [annotation subtitle]]];
		if (iconMedia != nil) {
			NSLog(@"GPSViewController: %@ annotation has a custom icon",[(ItemAnnotation *)annotation title]);
			if (iconMedia.imageView != nil ) {
				NSLog(@"GPSViewController: icon media as already loaded data, reuse it.");
				myImage = iconMedia.imageView.image;
			}
			NSLog(@"GPSViewController: Begin loading annotation icon from URL: %@", iconMedia.url);
			NSData *imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:iconMedia.url]];
			NSLog(@"GPSViewController: icon loaded");
			myImage = [UIImage imageWithData:imageData];
		} else {
			myImage = [UIImage imageNamed: @"pickaxe.png"];
		}
		annotationView.image = [self addTitle:annotation.title quantity:[annotation.subtitle intValue] toImage:myImage]; 	
		return annotationView;
	}
}


@end
