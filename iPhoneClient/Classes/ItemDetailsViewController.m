//
//  ItemDetailsViewController.m
//  ARIS
//
//  Created by David Gagnon on 4/2/09.
//  Copyright 2009 University of Wisconsin - Madison. All rights reserved.
//

#import "ItemDetailsViewController.h"
#import "ARISAppDelegate.h"
#import "AppServices.h"
#import "Media.h"
#import "Item.h"
#import "ItemActionViewController.h"


NSString *const kItemDetailsDescriptionHtmlTemplate = 
@"<html>"
@"<head>"
@"	<title>Aris</title>"
@"	<style type='text/css'><!--"
@"	body {"
@"		background-color: #000000;"
@"		color: #FFFFFF;"
@"		font-size: 17px;"
@"		font-family: Helvetia, Sans-Serif;"
@"	}"
@"	--></style>"
@"</head>"
@"<body>%@</body>"
@"</html>";



@implementation ItemDetailsViewController
@synthesize item, inInventory,mode,itemImageView, itemWebView,activityIndicator;

// The designated initializer. Override to perform setup that is required before the view is loaded.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(movieFinishedCallback:)
													 name:MPMoviePlayerPlaybackDidFinishNotification
												   object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self 
												 selector:@selector(movieLoadStateChanged:) 
													 name:MPMoviePlayerLoadStateDidChangeNotification 
												   object:nil];
		mode = kItemDetailsViewing;
    }
	
    return self;
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
	//Show waiting Indicator in own thread so it appears on time
	//[NSThread detachNewThreadSelector: @selector(showWaitingIndicator:) toTarget: (ARISAppDelegate *)[[UIApplication sharedApplication] delegate] withObject: @"Loading..."];	
	//[(ARISAppDelegate *)[[UIApplication sharedApplication] delegate]showWaitingIndicator:NSLocalizedString(@"LoadingKey",@"") displayProgressBar:NO];

	self.itemWebView.delegate = self;
	ARISAppDelegate *appDelegate = (ARISAppDelegate *)[[UIApplication sharedApplication] delegate];
    appDelegate.modalPresent = YES;
	//Setup the Toolbar Buttons
	dropButton.title = NSLocalizedString(@"ItemDropKey", @"");
	pickupButton.title = NSLocalizedString(@"ItemPickupKey", @"");
	deleteButton.title = NSLocalizedString(@"ItemDeleteKey",@"");
	detailButton.title = NSLocalizedString(@"ItemDetailKey", @"");
	
	if (inInventory == YES) {		
		dropButton.width = 75.0;
		deleteButton.width = 75.0;
		detailButton.width = 140.0;
		
		[toolBar setItems:[NSMutableArray arrayWithObjects: dropButton, deleteButton, detailButton,  nil] animated:NO];

		if (!item.dropable) dropButton.enabled = NO;
		if (!item.destroyable) deleteButton.enabled = NO;
	}
	else {
		pickupButton.width = 150.0;
		detailButton.width = 150.0;

		[toolBar setItems:[NSMutableArray arrayWithObjects: pickupButton,detailButton, nil] animated:NO];
	}
	
	//Create a close button
	self.navigationItem.leftBarButtonItem = 
	[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"BackButtonKey",@"")
									 style: UIBarButtonItemStyleBordered
									target:self 
									action:@selector(backButtonTouchAction:)];	
	
	

	NSLog(@"ItemDetailsViewController: View Loaded. Current item: %@", item.name);


	//Set Up General Stuff
	NSString *htmlDescription = [NSString stringWithFormat:kItemDetailsDescriptionHtmlTemplate, item.description];
	[itemDescriptionView loadHTMLString:htmlDescription baseURL:nil];

	Media *media = [[AppModel sharedAppModel] mediaForMediaId: item.mediaId];

	if ([media.type isEqualToString: @"Image"] && media.url) {
		NSLog(@"ItemDetailsViewController: Image Layout Selected");
		[itemImageView loadImageFromMedia:media];
	}
	else if (([media.type isEqualToString: @"Video"] || [media.type isEqualToString: @"Audio"]) && media.url) {
		NSLog(@"ItemDetailsViewController:  AV Layout Selected");

		//Setup the Button
		mediaPlaybackButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 320, 295)];
		[mediaPlaybackButton addTarget:self action:@selector(playMovie:) forControlEvents:UIControlEventTouchUpInside];
		[mediaPlaybackButton setBackgroundImage:[UIImage imageNamed:@"clickToPlay.png"] forState:UIControlStateNormal];
		[mediaPlaybackButton setTitle:NSLocalizedString(@"PreparingToPlayKey",@"") forState:UIControlStateNormal];
		mediaPlaybackButton.enabled = NO;
		mediaPlaybackButton.titleLabel.font = [UIFont boldSystemFontOfSize:24];
		[mediaPlaybackButton setContentHorizontalAlignment:UIControlContentHorizontalAlignmentCenter];
		[mediaPlaybackButton setContentVerticalAlignment:UIControlContentVerticalAlignmentBottom];
		[scrollView addSubview:mediaPlaybackButton];	
				
		//Create movie player object
		mMoviePlayer = [[ARISMoviePlayerViewController alloc] initWithContentURL:[NSURL URLWithString:media.url]];
		[mMoviePlayer shouldAutorotateToInterfaceOrientation:YES];
		mMoviePlayer.moviePlayer.shouldAutoplay = NO;
		[mMoviePlayer.moviePlayer prepareToPlay];		
	}
	
	else {
		NSLog(@"ItemDetailsVC: Error Loading Media ID: %d. It etiher doesn't exist or is not of a valid type.", item.mediaId);
	}
    self.itemWebView.hidden = YES;
	//Stop Waiting Indicator
	//[(ARISAppDelegate *)[[UIApplication sharedApplication] delegate] removeWaitingIndicator];
	[self updateQuantityDisplay];
    if (self.item.url && (![self.item.url isEqualToString: @"0"]) &&(![self.item.url isEqualToString:@""])) {
        
        //Config the webView
        self.itemWebView.allowsInlineMediaPlayback = YES;
        self.itemWebView.mediaPlaybackRequiresUserAction = NO;
        
        
        NSString *urlAddress = [self.item.url stringByAppendingString: [NSString stringWithFormat: @"?playerId=%d&gameId=%d",[AppModel sharedAppModel].playerId,[AppModel sharedAppModel].currentGame.gameId]];
        
        //Create a URL object.
        NSURL *url = [NSURL URLWithString:urlAddress];
        
        //URL Requst Object
        NSURLRequest *requestObj = [NSURLRequest requestWithURL:url];
        
        //Load the request in the UIWebView.
        [itemWebView loadRequest:requestObj];

    }
    else itemWebView.hidden = YES;
	[super viewDidLoad];
}

- (void)updateQuantityDisplay {
	if (item.qty > 1) self.title = [NSString stringWithFormat:@"%@ x%d",item.name,item.qty];
	else self.title = item.name;
}

- (IBAction)backButtonTouchAction: (id) sender{
	NSLog(@"ItemDetailsViewController: Notify server of Item view and Dismiss Item Details View");
	
	//Notify the server this item was displayed
	[[AppServices sharedAppServices] updateServerItemViewed:item.itemId];
	
	
	[self.navigationController popToRootViewControllerAnimated:YES];
	[self dismissModalViewControllerAnimated:NO];
	
	ARISAppDelegate *appDelegate = (ARISAppDelegate *)[[UIApplication sharedApplication] delegate];
    appDelegate.modalPresent = NO;
	
}

-(IBAction)playMovie:(id)sender {
	[self presentMoviePlayerViewControllerAnimated:mMoviePlayer];
}


- (IBAction)dropButtonTouchAction: (id) sender{
	NSLog(@"ItemDetailsVC: Drop Button Pressed");
	
	mode = kItemDetailsDropping;
	if(self.item.qty > 1)
    {
        ItemActionViewController *itemActionVC = [[ItemActionViewController alloc]initWithNibName:@"ItemActionViewController" bundle:nil];
        itemActionVC.mode = mode;
        itemActionVC.item = item;
        itemActionVC.delegate = self;
        itemActionVC.modalPresentationStyle = UIModalTransitionStyleCoverVertical;
        [[self navigationController] pushViewController:itemActionVC animated:YES];
        [itemActionVC release];	
        [self updateQuantityDisplay];

    }
    else 
    {
        [self doActionWithMode:mode quantity:1];
    }    
	
}

- (IBAction)deleteButtonTouchAction: (id) sender{
	NSLog(@"ItemDetailsVC: Destroy Button Pressed");

	
	mode = kItemDetailsDestroying;
	if(self.item.qty > 1)
    {
        
        ItemActionViewController *itemActionVC = [[ItemActionViewController alloc]initWithNibName:@"ItemActionViewController" bundle:nil];
        itemActionVC.mode = mode;
        itemActionVC.item = item;
        itemActionVC.delegate = self;

        itemActionVC.modalPresentationStyle = UIModalTransitionStyleCoverVertical;
        [[self navigationController] pushViewController:itemActionVC animated:YES];
        [itemActionVC release];	
        [self updateQuantityDisplay];

        
    }
    else 
    {
        
        [self doActionWithMode:mode quantity:1];
    }
}


- (IBAction)pickupButtonTouchAction: (id) sender{
	NSLog(@"ItemDetailsViewController: pickupButtonTouched");

	
	mode = kItemDetailsPickingUp;
	
    
    if(self.item.qty > 1)
    {

        ItemActionViewController *itemActionVC = [[ItemActionViewController alloc]initWithNibName:@"ItemActionViewController" bundle:nil];
        itemActionVC.mode = mode;
        itemActionVC.item = item;
        itemActionVC.delegate = self;

        itemActionVC.modalPresentationStyle = UIModalTransitionStyleCoverVertical;
        [[self navigationController] pushViewController:itemActionVC animated:YES];
        [itemActionVC release];	
        [self updateQuantityDisplay];

        
    }
    else 
    {
        [self doActionWithMode:mode quantity:1];
    }
}


-(void)doActionWithMode: (ItemDetailsModeType) itemMode quantity: (int) quantity {
    ARISAppDelegate* appDelegate = (ARISAppDelegate *)[[UIApplication sharedApplication] delegate];
	[appDelegate playAudioAlert:@"drop" shouldVibrate:YES];
	
	//Determine the Quantity Effected based on the button touched

	
	
	//Do the action based on the mode of the VC
	if (mode == kItemDetailsDropping) {
		NSLog(@"ItemDetailsVC: Dropping %d",quantity);
		[[AppServices sharedAppServices] updateServerDropItemHere:item.itemId qty:quantity];
		[[AppModel sharedAppModel] removeItemFromInventory:item qtyToRemove:quantity];
        
			}
	else if (mode == kItemDetailsDestroying) {
		NSLog(@"ItemDetailsVC: Destroying %d",quantity);
		[[AppServices sharedAppServices] updateServerDestroyItem:self.item.itemId qty:quantity];
		[[AppModel sharedAppModel] removeItemFromInventory:item qtyToRemove:quantity];
		
	}
	else if (mode == kItemDetailsPickingUp) {
        NSString *errorMessage;

		//Determine if this item can be picked up
		Item *itemInInventory  = [[AppModel sharedAppModel].inventory objectForKey:[NSString stringWithFormat:@"%d",item.itemId]];
		if (itemInInventory.qty + quantity > item.maxQty && item.maxQty != -1) {
            
			[appDelegate playAudioAlert:@"error" shouldVibrate:YES];
			
			if (itemInInventory.qty < item.maxQty) {
				quantity = item.maxQty - itemInInventory.qty;
                
                if([AppModel sharedAppModel].currentGame.inventoryWeightCap != 0){
                while((quantity*item.weight + [AppModel sharedAppModel].currentGame.currentWeight) > [AppModel sharedAppModel].currentGame.inventoryWeightCap){
                    quantity--;
                }
                }
				errorMessage = [NSString stringWithFormat:@"You can't carry that much. Only %d picked up",quantity];

			}
			else if (item.maxQty == 0) {
				errorMessage = @"This item cannot be picked up.";
				quantity = 0;
			}
            else {
				errorMessage = @"You cannot carry any more of this item.";
				quantity = 0;
			}
            
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle: @"Inventory over Limit"
															message: errorMessage
														   delegate: self cancelButtonTitle: NSLocalizedString(@"OkKey", @"") otherButtonTitles: nil];
			[alert show];
			[alert release];
            
            
		}
        else if (((quantity*item.weight +[AppModel sharedAppModel].currentGame.currentWeight) > [AppModel sharedAppModel].currentGame.inventoryWeightCap)&&([AppModel sharedAppModel].currentGame.inventoryWeightCap != 0)){
            while ((quantity*item.weight + [AppModel sharedAppModel].currentGame.currentWeight) > [AppModel sharedAppModel].currentGame.inventoryWeightCap) {
                quantity--;
            }
            errorMessage = [NSString stringWithFormat:@"Too Heavy! Only %d picked up",quantity];
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle: @"Inventory over Limit"
															message: errorMessage
														   delegate: self cancelButtonTitle: NSLocalizedString(@"OkKey", @"") otherButtonTitles: nil];
			[alert show];
			[alert release];
        }

		if (quantity > 0) {
			[[AppServices sharedAppServices] updateServerPickupItem:self.item.itemId fromLocation:self.item.locationId qty:quantity];
			[[AppModel sharedAppModel] modifyQuantity:-quantity forLocationId:self.item.locationId];
			item.qty -= quantity; //the above line does not give us an update, only the map
			
            }
		
	}
	
	[self updateQuantityDisplay];
	
	//Possibly Dismiss Item Details View
	if (item.qty < 1) {
		[self.navigationController popToRootViewControllerAnimated:YES];
		[self dismissModalViewControllerAnimated:NO];
        ARISAppDelegate *appDelegate = (ARISAppDelegate *)[[UIApplication sharedApplication] delegate];
        appDelegate.modalPresent = NO;
	}
	

}

#pragma mark MPMoviePlayerController Notification Handlers


- (void)movieLoadStateChanged:(NSNotification*) aNotification{
	MPMovieLoadState state = [(MPMoviePlayerController *) aNotification.object loadState];
	
	if( state & MPMovieLoadStateUnknown ) {
		NSLog(@"ItemDetailsViewController: Unknown Load State");
	}
	if( state & MPMovieLoadStatePlayable ) {
		NSLog(@"ItemDetailsViewController: Playable Load State");
	} 
	if( state & MPMovieLoadStatePlaythroughOK ) {
		NSLog(@"ItemDetailsViewController: Playthrough OK Load State");
		[mediaPlaybackButton setTitle:NSLocalizedString(@"TouchToPlayKey",@"") forState:UIControlStateNormal];
		mediaPlaybackButton.enabled = YES;	
	} 
	if( state & MPMovieLoadStateStalled ) {
		NSLog(@"ItemDetailsViewController: Stalled Load State");
	} 
	
}


- (void)movieFinishedCallback:(NSNotification*) aNotification
{
	NSLog(@"ItemDetailsViewController: movieFinishedCallback");
	[self dismissMoviePlayerViewControllerAnimated];
}


#pragma mark Zooming delegate methods

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
	NSLog(@"got a viewForZooming.");
	return itemImageView;
}

- (void) scrollViewDidEndZooming: (UIScrollView *) scrollView withView: (UIView *) view atScale: (float) scale
{
	NSLog(@"got a scrollViewDidEndZooming. Scale: %f", scale);
	CGAffineTransform transform = CGAffineTransformIdentity;
	transform = CGAffineTransformScale(transform, scale, scale);
	itemImageView.transform = transform;
}

- (void) touchesEnded:(NSSet*)touches withEvent:(UIEvent*)event
{
    UITouch       *touch = [touches anyObject];
	NSLog(@"got a touchesEnded.");
	
    if([touch tapCount] == 2) {
		//NSLog(@"TouchCount is 2.");
		CGAffineTransform transform = CGAffineTransformIdentity;
		transform = CGAffineTransformScale(transform, 1.0, 1.0);
		itemImageView.transform = transform;
    }
}

#pragma mark Animate view show/hide

- (void)showView:(UIView *)aView {
	CGRect superFrame = [aView superview].bounds;
	CGRect viewFrame = [aView frame];
	viewFrame.origin.y = superFrame.origin.y + superFrame.size.height - 175;
	[UIView beginAnimations:nil context:NULL]; //we animate the transition
	[aView setFrame:viewFrame];
	[UIView commitAnimations]; //run animation
}

- (void)hideView:(UIView *)aView {
	CGRect superFrame = [aView superview].bounds;
	CGRect viewFrame = [aView frame];
	viewFrame.origin.y = superFrame.origin.y + superFrame.size.height;
	[UIView beginAnimations:nil context:NULL]; //we animate the transition
	[aView setFrame:viewFrame];
	[UIView commitAnimations]; //run animation
}

- (void)toggleDescription:(id)sender {
	ARISAppDelegate* appDelegate = (ARISAppDelegate *)[[UIApplication sharedApplication] delegate];
	[appDelegate playAudioAlert:@"swish" shouldVibrate:NO];
	
	if (descriptionShowing) { //description is showing, so hide
		[self hideView:itemDescriptionView];
		//[notesButton setStyle:UIBarButtonItemStyleBordered]; //set button style
		descriptionShowing = NO;
	} else {  //description is not showing, so show
		[self showView:itemDescriptionView];
		//[notesButton setStyle:UIBarButtonItemStyleDone];
		descriptionShowing = YES;
	}
}
#pragma mark WebViewDelegate 
- (BOOL)webView:(UIWebView*)webView shouldStartLoadWithRequest: (NSURLRequest*)req navigationType:(UIWebViewNavigationType)navigationType { 
    
    if ([[[req URL] absoluteString] hasPrefix:@"aris://closeMe"]) {
        [self.navigationController popToRootViewControllerAnimated:YES];
        [self dismissModalViewControllerAnimated:NO];
        return NO; 
    }  
    else if ([[[req URL] absoluteString] hasPrefix:@"aris://refreshStuff"]) {
        [[AppServices sharedAppServices] fetchAllPlayerLists];
        return NO; 
    }   
    return YES;
}

-(void)webViewDidFinishLoad:(UIWebView *)webView {
    self.itemWebView.hidden = NO;
    [self dismissWaitingIndicator];
}
-(void)webViewDidStartLoad:(UIWebView *)webView {
    [self showWaitingIndicator];
}
-(void)showWaitingIndicator {
    [self.activityIndicator startAnimating];
}

-(void)dismissWaitingIndicator {
    [self.activityIndicator stopAnimating];
}


#pragma mark Memory Management

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}

- (void)dealloc {
    NSLog(@"Item Details View: Deallocating");
	
	// free our movie player
    [mMoviePlayer release];
	
	[mediaPlaybackButton release];
	
	//remove listeners
	[[NSNotificationCenter defaultCenter] removeObserver:self];

	[super dealloc];
}


@end
