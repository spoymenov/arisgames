//
//  IMViewController.m
//  ARIS
//
//  Created by Ben Longoria on 2/11/09.
//  Copyright 2009 University of Wisconsin. All rights reserved.
//

#import "IMViewController.h"


@implementation IMViewController

@synthesize webview;
@synthesize moduleName;

//Override init for passing title and icon to tab bar
- (id)initWithNibName:(NSString *)nibName bundle:(NSBundle *)nibBundle
{
    self = [super initWithNibName:nibName bundle:nibBundle];
    if (self) {
        self.title = @"IM";
        self.tabBarItem.image = [UIImage imageNamed:@"IM.png"];
    }
    return self;
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	webview.delegate = self;
	moduleName = @"RESTNodeViewer";
	
	NSLog(@"IMView Loaded");
}

- (void)viewDidAppear {
	[webview loadRequest:[appModel getURLForModule:moduleName]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}

-(void) setModel:(AppModel *)model {
	if(appModel != model) {
		[appModel release];
		appModel = model;
		[appModel retain];
	}
	[webview loadRequest:[appModel getURLForModule:moduleName]];
	
	NSLog(@"model set for IM");
}

- (void)dealloc {
	[appModel release];
	[moduleName release];
    [super dealloc];
}

#pragma mark WebView Delegate
- (void)webViewDidStartLoad:(UIWebView *)webView {
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	
}


@end
