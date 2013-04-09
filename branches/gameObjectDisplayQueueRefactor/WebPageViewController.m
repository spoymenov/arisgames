//
//  WebPageViewController.m
//  ARIS
//
//  Created by Brian Thiel on 6/14/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "WebPageViewController.h"
#import "AppModel.h"
#import "AppServices.h"
#import "ARISAppDelegate.h"
#import "Media.h"
#import "AsyncMediaImageView.h"
#import "NpcViewController.h"
#import "NodeViewController.h"
#import "QuestsViewController.h"
#import "ItemViewController.h"

@implementation WebPageViewController

@synthesize webView,webPage,activityIndicator,blackView, audioPlayers, bumpSendString, isConnectedToBump, loaded;

- (id)initWithWebPage:(WebPage *)w
{
    self = [super initWithNibName:@"WebPageViewController" bundle:nil];
    if (self)
    {
        self.webPage = w;

        // Custom initialization
        self.isConnectedToBump = NO;
        self.bumpSendString = @"";
    }
    return self;
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.audioPlayers = [[NSMutableDictionary alloc] init];
    self.loaded = NO;
    self.webView.delegate = self;
    self.webView.hidden = YES;
    //Create a close button
	self.navigationItem.leftBarButtonItem = 
	[[UIBarButtonItem alloc] initWithTitle:@"Close"
									 style: UIBarButtonItemStyleBordered
									target:self 
									action:@selector(backButtonTouchAction:)];	
    
    //Create a URL object.
    NSString *urlAddress = self.webPage.url;
    
    //Check to prepend url query with '?' or '&'
    if([self.webPage.url rangeOfString:@"?"].location == NSNotFound)
        urlAddress = [self.webPage.url stringByAppendingString: [NSString stringWithFormat: @"?gameId=%d&webPageId=%d&playerId=%d",[AppModel sharedAppModel].currentGame.gameId, webPage.webPageId, [AppModel sharedAppModel].playerId]];
    else       
        urlAddress = [self.webPage.url stringByAppendingString: [NSString stringWithFormat: @"&gameId=%d&webPageId=%d&playerId=%d",[AppModel sharedAppModel].currentGame.gameId, webPage.webPageId, [AppModel sharedAppModel].playerId]];
    
    NSLog(@"WebPageViewController: Loading URL: %@",urlAddress);
    NSURL *url = [NSURL URLWithString:urlAddress];
    //URL Requst Object
    NSURLRequest *requestObj = [NSURLRequest requestWithURL:url];
    
    //Config the webVie
    webView.allowsInlineMediaPlayback = YES;
    webView.mediaPlaybackRequiresUserAction = NO;
    
    //Load the request in the UIWebView.
    [webView loadRequest:requestObj];
    
}

-(void)viewDidAppear:(BOOL)animated{
    //[RootViewController sharedRootViewController].webpageChannel = [[RootViewController sharedRootViewController].client subscribeToPrivateChannelNamed:[NSString stringWithFormat:@"%d-webpage-channel",self.webPage.webPageId]];

    if(!self.loaded)
    {
        self.webView.hidden = YES;
        self.blackView.hidden = NO;
    }
}

- (void)viewDidUnload
{
    NSLog(@"WebPageViewController: viewDidUnload");
    [super viewDidUnload];
}

- (void)dealloc
{
    webView.delegate = nil;
    [webView stopLoading];
}

- (void)viewWillDisappear:(BOOL)animated {
    NSLog(@"WebPageViewController: viewWillDisapear");
    //if([RootViewController sharedRootViewController].webpageChannel) [[RootViewController sharedRootViewController].client unsubscribeFromChannel:(PTPusherChannel *)[RootViewController sharedRootViewController].webpageChannel];

    [self.audioPlayers enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop){
        AVPlayer *player = obj;
        [player pause]; 
    }];
}

#pragma mark -
#pragma mark General Logic
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

-(BOOL)shouldAutorotate{
    return YES;
}

-(NSInteger)supportedInterfaceOrientations{
    NSInteger mask = 0;
    if ([self shouldAutorotateToInterfaceOrientation: UIInterfaceOrientationLandscapeLeft])
        mask |= UIInterfaceOrientationMaskLandscapeLeft;
    if ([self shouldAutorotateToInterfaceOrientation: UIInterfaceOrientationLandscapeRight])
        mask |= UIInterfaceOrientationMaskLandscapeRight;
    if ([self shouldAutorotateToInterfaceOrientation: UIInterfaceOrientationPortrait])
        mask |= UIInterfaceOrientationMaskPortrait;
    if ([self shouldAutorotateToInterfaceOrientation: UIInterfaceOrientationPortraitUpsideDown])
        mask |= UIInterfaceOrientationMaskPortraitUpsideDown;
    return mask;
}

-(void)webViewDidFinishLoad:(UIWebView *)webView {
    self.loaded = YES;
    self.webView.hidden = NO;
    self.blackView.hidden = YES;
    [self dismissWaitingIndicator];
}
-(void)webViewDidStartLoad:(UIWebView *)webView {
    self.loaded = NO;
    [self showWaitingIndicator];
}
-(void)showWaitingIndicator {
    [self.activityIndicator startAnimating];
}

-(void)dismissWaitingIndicator {
    [self.activityIndicator stopAnimating];
}

- (IBAction)backButtonTouchAction: (id) sender
{
    if(self.isConnectedToBump) [BumpClient sharedClient].bumpable = NO;
	[delegate displayObjectViewControllerWasDismissed:self];
}

#pragma mark -
#pragma mark ARIS/JavaScript Connections

- (BOOL)webView:(UIWebView*)webViewFromMethod shouldStartLoadWithRequest: (NSURLRequest*)req navigationType:(UIWebViewNavigationType)navigationType
{
    
    ARISAppDelegate* appDelegate = (ARISAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    self.webView = webViewFromMethod;
    
    //Is this a special call from HTML back to ARIS?
    NSString* scheme = [[req URL] scheme];
    if (!([scheme isEqualToString:@"aris"] || [scheme isEqualToString:@"ARIS"])) return YES;
    
    [self.webView stringByEvaluatingJavaScriptFromString: @"ARIS.isCurrentlyCalling();"];
    
    //What was it requesting?
    NSString* mainCommand = [[req URL] host];
    NSArray *components = [[req URL]pathComponents];
    
    if ([mainCommand isEqualToString:@"closeMe"])
    {
        NSLog(@"WebPageViewController: aris://closeMe/ called");
        [self.navigationController popToRootViewControllerAnimated:YES];
        if(![[[RootViewController sharedRootViewController].nearbyObjectNavigationController.viewControllers objectAtIndex:0] isKindOfClass:[NpcViewController class]])
            [delegate displayObjectViewControllerWasDismissed:self];
        return NO; 
    }
    
    if ([mainCommand isEqualToString:@"vibrate"])
    {
        NSLog(@"WebPageViewController: aris://vibrate/ called");
        [appDelegate vibrate];
        [self.webView stringByEvaluatingJavaScriptFromString: @"ARIS.isNotCurrentlyCalling();"];
        return NO; 
    } 
    
    if ([mainCommand isEqualToString:@"player"]) {
        NSLog(@"WebPageViewController: aris://player/ called");
        
        if ([components count] > 1 && 
            [[components objectAtIndex:1] isEqualToString:@"name"]) 
        {
            [self.webView stringByEvaluatingJavaScriptFromString: [NSString stringWithFormat:@"ARIS.setPlayerName(\"%@\");",[AppModel sharedAppModel].userName]];
            [self.webView stringByEvaluatingJavaScriptFromString: @"ARIS.isNotCurrentlyCalling();"];
            return NO;
        }
        if ([components count] > 1 && 
            [[components objectAtIndex:1] isEqualToString:@"id"]) 
        {
            [self.webView stringByEvaluatingJavaScriptFromString: [NSString stringWithFormat:@"ARIS.setPlayerId(%d);",[AppModel sharedAppModel].playerId]];
            [self.webView stringByEvaluatingJavaScriptFromString: @"ARIS.isNotCurrentlyCalling();"];
            return NO; 
        }
    }
    
    if ([mainCommand isEqualToString:@"inventory"])
    {
        NSLog(@"WebPageViewController: aris://inventory/ called");
        
        if ([components count] > 2 && 
            [[components objectAtIndex:1] isEqualToString:@"get"])
        {
            int itemId = [[components objectAtIndex:2] intValue];
            NSLog(@"WebPageViewController: aris://inventory/get/ called from webpage with itemId = %d",itemId);
            int qty = [self getQtyInInventoryOfItem:itemId];
            [self.webView stringByEvaluatingJavaScriptFromString: [NSString stringWithFormat:@"ARIS.didUpdateItemQty(%d,%d);",itemId,qty]];
            [self.webView stringByEvaluatingJavaScriptFromString: @"ARIS.isNotCurrentlyCalling();"];
            return NO; 
        }
        
        if ([components count] > 3 && 
            [[components objectAtIndex:1] isEqualToString:@"set"])
        {
            int itemId = [[components objectAtIndex:2] intValue];
            int qty = [[components objectAtIndex:3] intValue];
            NSLog(@"WebPageViewController: aris://inventory/set/ called from webpage with itemId = %d and qty = %d",itemId,qty);
            int newQty = [self setQtyInInventoryOfItem:itemId toQty:qty];
            [self.webView stringByEvaluatingJavaScriptFromString: [NSString stringWithFormat:@"ARIS.didUpdateItemQty(%d,%d);",itemId,newQty]];
            [self.webView stringByEvaluatingJavaScriptFromString: @"ARIS.isNotCurrentlyCalling();"];
            return NO; 
        } 
        
        if ([components count] > 3 && 
            [[components objectAtIndex:1] isEqualToString:@"give"])
        {
            int itemId = [[components objectAtIndex:2] intValue];
            int qty = [[components objectAtIndex:3] intValue];
            NSLog(@"WebPageViewController: aris://inventory/give/ called from webpage with itemId = %d and qty = %d",itemId,qty);
            int newQty = [self giveQtyInInventoryToItem:itemId ofQty:qty];
            [self.webView stringByEvaluatingJavaScriptFromString: [NSString stringWithFormat:@"ARIS.didUpdateItemQty(%d,%d);",itemId,newQty]];
            [self.webView stringByEvaluatingJavaScriptFromString: @"ARIS.isNotCurrentlyCalling();"];
            return NO; 
        } 
        
        if ([components count] > 3 && 
            [[components objectAtIndex:1] isEqualToString:@"take"])
        {
            int itemId = [[components objectAtIndex:2] intValue];
            int qty = [[components objectAtIndex:3] intValue];
            NSLog(@"WebPageViewController: aris://inventory/take/ called from webpage with itemId = %d and qty = %d",itemId,qty);
            int newQty = [self takeQtyInInventoryFromItem:itemId ofQty:qty];
            [self.webView stringByEvaluatingJavaScriptFromString: [NSString stringWithFormat:@"ARIS.didUpdateItemQty(%d,%d);",itemId,newQty]];
            [self.webView stringByEvaluatingJavaScriptFromString: @"ARIS.isNotCurrentlyCalling();"];
            return NO; 
        } 
    } 
    
    if ([mainCommand isEqualToString:@"media"]) {
        NSLog(@"WebPageViewController: aris://media called");
        
        if ([components count] > 2 && 
            [[components objectAtIndex:1] isEqualToString:@"prepare"])
        {
            int mediaId = [[components objectAtIndex:2] intValue];
            NSLog(@"WebPageViewController: aris://media/prepare/ called from webpage with mediaId = %d",mediaId );
            [self loadAudioFromMediaId:mediaId];
            [self.webView stringByEvaluatingJavaScriptFromString: @"ARIS.isNotCurrentlyCalling();"];
            return NO; 
        }  
        
        if ([components count] > 2 && 
            [[components objectAtIndex:1] isEqualToString:@"play"])
        {
            int mediaId = [[components objectAtIndex:2] intValue];
            NSLog(@"WebPageViewController: aris://media/play/ called from webpage with mediaId = %d",mediaId );
            [self playAudioFromMediaId:mediaId];
            [self.webView stringByEvaluatingJavaScriptFromString: @"ARIS.isNotCurrentlyCalling();"];
            return NO; 
        }  
        
        if ([components count] > 2 && 
            [[components objectAtIndex:1] isEqualToString:@"playAndVibrate"]) {
            int mediaId = [[components objectAtIndex:2] intValue];
            NSLog(@"WebPageViewController: aris://media/playAndVibrate/ called from webpage with mediaId = %d",mediaId );
            [self playAudioFromMediaId:mediaId];
            [appDelegate vibrate];
            [self.webView stringByEvaluatingJavaScriptFromString: @"ARIS.isNotCurrentlyCalling();"];
            return NO; 
        }  
        
        if ([components count] > 2 && 
            [[components objectAtIndex:1] isEqualToString:@"stop"]) {
            int mediaId = [[components objectAtIndex:2] intValue];
            NSLog(@"WebPageViewController: aris://media/stop/ called from webpage with mediaId = %d",mediaId );
            [self stopAudioFromMediaId:mediaId];
            [self.webView stringByEvaluatingJavaScriptFromString: @"ARIS.isNotCurrentlyCalling();"];
            return NO; 
        }  
        
        if ([components count] > 3 && 
            [[components objectAtIndex:1] isEqualToString:@"setVolume"]) {
            int mediaId = [[components objectAtIndex:2] intValue];
            int volume = [[components objectAtIndex:3] floatValue];
            NSLog(@"WebPageViewController: aris://media/setVolume/ called from webpage with mediaId = %d and volume =%d",mediaId,volume );
            [self setMediaId:mediaId volumeTo:volume];
            [self.webView stringByEvaluatingJavaScriptFromString: @"ARIS.isNotCurrentlyCalling();"];
            return NO; 
        }
    }
    
    if ([mainCommand isEqualToString:@"bump"]) {
        NSLog(@"WebPageViewController: aris://bump/ called");
        if ([components count] > 1) 
        {
            self.bumpSendString = [components objectAtIndex:1];
            [self configureBump];
            [BumpClient sharedClient].bumpable = YES;
            [self.webView stringByEvaluatingJavaScriptFromString: @"ARIS.isNotCurrentlyCalling();"];
            return NO;
        }
    }  
    
    //Shouldn't get here. 
    NSLog(@"WebPageViewController: WARNING. An aris:// url was called with no handler");
    return YES;
}

- (void) loadAudioFromMediaId:(int)mediaId{
    NSLog(@"WebPageViewController: loadAudioFromMediaId");
    Media* media = [[AppModel sharedAppModel] mediaForMediaId: mediaId];
    NSURL* url = [NSURL URLWithString:media.url];
    AVPlayer *player = [AVPlayer playerWithURL:url];
    [audioPlayers setObject:player forKey:[NSNumber numberWithInt:mediaId]];
}


- (void) playAudioFromMediaId:(int)mediaId{
    AVPlayer *player = [audioPlayers objectForKey:[NSNumber numberWithInt:mediaId]];
    CMTime zero = CMTimeMakeWithSeconds(0, 600);
    [player seekToTime: zero];
    if (!player) {
        [self loadAudioFromMediaId:mediaId];
        player = [audioPlayers objectForKey:[NSNumber numberWithInt:mediaId]];
    }
    [player play];
}

- (void) stopAudioFromMediaId:(int)mediaId{
    AVPlayer *player = [audioPlayers objectForKey:[NSNumber numberWithInt:mediaId]];
    [player pause];
}

- (void) setMediaId:(int)mediaId volumeTo:(float)volume{    
    AVPlayer *player = [audioPlayers objectForKey:[NSNumber numberWithInt:mediaId]];
    
    NSArray *audioTracks = [player.currentItem.asset tracksWithMediaType:AVMediaTypeAudio];
    NSMutableArray *allAudioParams = [NSMutableArray array];
    for (AVAssetTrack *track in audioTracks) {
        AVMutableAudioMixInputParameters *audioInputParams = 
        [AVMutableAudioMixInputParameters audioMixInputParameters];
        [audioInputParams setVolume:volume atTime:kCMTimeZero];
        [audioInputParams setTrackID:[track trackID]];
        [allAudioParams addObject:audioInputParams];
    }
    
    AVMutableAudioMix *audioMix = [AVMutableAudioMix audioMix];
    [audioMix setInputParameters:allAudioParams];
    
    player.currentItem.audioMix = audioMix;
    
}

- (int) getQtyInInventoryOfItem:(int)itemId
{
    InGameItem *i;
    
    i = [[AppModel sharedAppModel].currentGame.inventoryModel inventoryItemForId:itemId];
    if(i) return i.qty;
    
    i = [[AppModel sharedAppModel].currentGame.attributesModel attributesItemForId:itemId];
    if(i) return i.qty;
    
    return 0;
}

- (int) setQtyInInventoryOfItem:(int)itemId toQty:(int)qty
{
    if(qty < 1) qty = 0;
    [[AppServices sharedAppServices] updateServerInventoryItem:itemId qty:qty];
    
    Item *i = [[AppModel sharedAppModel] itemForItemId:itemId];
    int newQty = 0;
    if(!i.isAttribute)
    {
        InGameItem *ii = [[AppModel sharedAppModel].currentGame.inventoryModel inventoryItemForId:itemId];
        if(ii && ii.qty < qty)
            newQty = [[AppModel sharedAppModel].currentGame.inventoryModel addItemToInventory:i qtyToAdd:qty-ii.qty];
        else if(ii && ii.qty > qty)
            newQty = [[AppModel sharedAppModel].currentGame.inventoryModel removeItemFromInventory:i qtyToRemove:ii.qty-qty];
        else if(!ii && qty > 0)
            newQty = [[AppModel sharedAppModel].currentGame.inventoryModel addItemToInventory:i qtyToAdd:qty];
    }
    else
    {
        InGameItem *ii = [[AppModel sharedAppModel].currentGame.attributesModel attributesItemForId:itemId];
        if(ii && ii.qty < qty)
            newQty = [[AppModel sharedAppModel].currentGame.attributesModel addItemToAttributes:i qtyToAdd:qty-ii.qty];
        else if(ii && ii.qty > qty)
            newQty = [[AppModel sharedAppModel].currentGame.attributesModel removeItemFromAttributes:i qtyToRemove:ii.qty-qty];
        else if(!ii && qty > 0)
            newQty = [[AppModel sharedAppModel].currentGame.attributesModel addItemToAttributes:i qtyToAdd:qty];
    }
    return newQty;
}

- (int) giveQtyInInventoryToItem:(int)itemId ofQty:(int)qty
{
    [[AppServices sharedAppServices] updateServerAddInventoryItem:itemId addQty:qty];

    Item *i = [[AppModel sharedAppModel] itemForItemId:itemId];
    int newQty = 0;
    if(!i.isAttribute)
        newQty = [[AppModel sharedAppModel].currentGame.inventoryModel addItemToInventory:i qtyToAdd:qty];
    else
        newQty = [[AppModel sharedAppModel].currentGame.attributesModel addItemToAttributes:i qtyToAdd:qty];

    return newQty;
}

- (int) takeQtyInInventoryFromItem:(int)itemId ofQty:(int)qty
{
    [[AppServices sharedAppServices] updateServerAddInventoryItem:itemId addQty:qty];

    Item *i = [[AppModel sharedAppModel] itemForItemId:itemId];
    int newQty = 0;
    if(!i.isAttribute)
        newQty = [[AppModel sharedAppModel].currentGame.inventoryModel removeItemFromInventory:i qtyToRemove:qty];
    else
        newQty = [[AppModel sharedAppModel].currentGame.attributesModel removeItemFromAttributes:i qtyToRemove:qty];    
    [[AppServices sharedAppServices] updateServerRemoveInventoryItem:itemId removeQty:qty];

    return newQty;
}

- (void) configureBump
{
    if(self.isConnectedToBump) return;
    [BumpClient configureWithAPIKey:@"4ff1c7a0c2a84bb9938dafc3a1ac770c" andUserID:[[UIDevice currentDevice] name]];
    
    [[BumpClient sharedClient] setMatchBlock:^(BumpChannelID channel) { 
        NSLog(@"Matched with user: %@", [[BumpClient sharedClient] userIDForChannel:channel]); 
        [[BumpClient sharedClient] confirmMatch:YES onChannel:channel];
    }];
    
    [[BumpClient sharedClient] setChannelConfirmedBlock:^(BumpChannelID channel) {
        NSLog(@"Channel with %@ confirmed.", [[BumpClient sharedClient] userIDForChannel:channel]);
        [[BumpClient sharedClient] sendData:[self.bumpSendString dataUsingEncoding:NSUTF8StringEncoding]
                                  toChannel:channel];
    }];
    
    [[BumpClient sharedClient] setDataReceivedBlock:^(BumpChannelID channel, NSData *data) {
        NSString *receipt = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSLog(@"Data received:\n%@",receipt);
        [self.webView stringByEvaluatingJavaScriptFromString: [NSString stringWithFormat:@"ARIS.bumpReceived(%@);",receipt]];
            }];
    
    [[BumpClient sharedClient] setConnectionStateChangedBlock:^(BOOL connected) {
        if (connected) {
            NSLog(@"Bump connected...");
            self.isConnectedToBump = YES;
        } else {
            NSLog(@"Bump disconnected...");
            self.isConnectedToBump = NO;
        }
    }];
    
    [[BumpClient sharedClient] setBumpEventBlock:^(bump_event event) {
        switch(event) {
            case BUMP_EVENT_BUMP:
                NSLog(@"Bump detected.");
                break;
            case BUMP_EVENT_NO_MATCH:
                NSLog(@"No match.");
                break;
        }
    }];
}


@end