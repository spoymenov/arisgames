//
//  AccountSettingsViewController.m
//  ARIS
//
//  Created by Ben Longoria on 2/11/09.
//  Copyright 2009 University of Wisconsin. All rights reserved.
//

#import "AccountSettingsViewController.h"
#import "ForgotViewController.h"

@implementation AccountSettingsViewController

//Override init for passing title and icon to tab bar
- (id)initWithNibName:(NSString *)nibName bundle:(NSBundle *)nibBundle
{
    self = [super initWithNibName:nibName bundle:nibBundle];
    if (self) {
        self.title = @"Account";
        self.tabBarItem.image = [UIImage imageNamed:@"123-id-card"];
    }
    return self;
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
	warningLabel.text = NSLocalizedString(@"LogoutWarningKey", @"");
	[logoutButton setTitle:NSLocalizedString(@"LogoutKey",@"") forState:UIControlStateNormal];
	//[passButton setTitle:NSLocalizedString(@"ChangePasswordKey",@"") forState:UIControlStateNormal];
	[passButton setTitle:@"Change Password" forState:UIControlStateNormal];
	//[profileButton setTitle:NSLocalizedString(@"ProfileKey",@"") forState:UIControlStateNormal];
	[profileButton setTitle:@"Profile" forState:UIControlStateNormal];
	
    [super viewDidLoad];	
	NSLog(@"Account Settings View Controller Loaded");
}

- (IBAction)logoutButtonPressed: (id) sender {
	NSLog(@"Logout Requested");
	
	NSNotification *logoutRequestNotification = [NSNotification notificationWithName:@"LogoutRequested" object:self];
	[[NSNotificationCenter defaultCenter] postNotification:logoutRequestNotification];
}

- (IBAction)passButtonPressed: (id) sender {
	NSLog(@"Password Change Requested");

	NSLog(@"Login: Change Password Button Touched");
	ForgotViewController *forgotPassViewController = [[ForgotViewController alloc]
                                                      initWithNibName:@"ForgotViewController" bundle:[NSBundle mainBundle]];
	//Put the view on the screen
	[[self navigationController] pushViewController:forgotPassViewController animated:YES];
}

- (IBAction)profileButtonPressed: (id) sender {
	NSLog(@"Profile Settings Requested");
	
	NSNotification *profSettingsRequestNotification = [NSNotification notificationWithName:@"ProfSettingsRequested" object:self];
	[[NSNotificationCenter defaultCenter] postNotification:profSettingsRequestNotification];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}

@end