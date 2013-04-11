//
//  AppServices.m
//  ARIS
//
//  Created by David J Gagnon on 5/11/11.
//  Copyright 2011 University of Wisconsin. All rights reserved.
//

#import "AppServices.h"
#import "ARISUploader.h"

static const int kDefaultCapacity = 10;
static const int kEmptyValue = -1;
NSString *const kARISServerServicePackage = @"v1";

@interface AppServices()

- (NSInteger) validIntForKey:(NSString *const)aKey inDictionary:(NSDictionary *const)aDictionary;
- (id) validObjectForKey:(NSString *const)aKey inDictionary:(NSDictionary *const)aDictionary;

@end

@implementation AppServices

@synthesize currentlyFetchingLocationList, currentlyFetchingInventory, currentlyFetchingQuestList, currentlyUpdatingServerWithPlayerLocation,currentlyFetchingGameNoteList,currentlyFetchingPlayerNoteList;
@synthesize currentlyFetchingOneGame, currentlyFetchingNearbyGamesList, currentlyFetchingPopularGamesList, currentlyFetchingRecentGamesList, currentlyFetchingSearchGamesList;
@synthesize currentlyUpdatingServerWithMapViewed, currentlyUpdatingServerWithQuestsViewed, currentlyUpdatingServerWithInventoryViewed;
@synthesize currentlyInteractingWithObject;

+ (id)sharedAppServices
{
    static dispatch_once_t pred = 0;
    __strong static id _sharedObject = nil;
    dispatch_once(&pred, ^{
        _sharedObject = [[self alloc] init]; // or some other init method
    });
    return _sharedObject;
}

#pragma mark Communication with Server
- (void)login {
	NSLog(@"AppModel: Login Requested");
	NSArray *arguments = [NSArray arrayWithObjects:[AppModel sharedAppModel].userName, [AppModel sharedAppModel].password, nil];
	JSONConnection *jsonConnection = [[JSONConnection alloc] initWithServer:[AppModel sharedAppModel].serverURL
                                                             andServiceName: @"players"
                                                              andMethodName:@"getLoginPlayerObject"
                                                               andArguments:arguments
                                                                andUserInfo:nil];
	[jsonConnection performAsynchronousRequestWithHandler:@selector(parseLoginResponseFromJSON:)];
}

- (void)createUserAndLoginWithGroup:(NSString *)groupName
{
    NSLog(@"AppModel: Create User And Login Requested");
	NSArray *arguments = [NSArray arrayWithObjects:groupName, nil];
	JSONConnection *jsonConnection = [[JSONConnection alloc] initWithServer:[AppModel sharedAppModel].serverURL
                                                             andServiceName: @"players"
                                                              andMethodName:@"createPlayerAndGetLoginPlayerObject"
                                                               andArguments:arguments
                                                                andUserInfo:nil];
	[jsonConnection performAsynchronousRequestWithHandler:@selector(parseLoginResponseFromJSON:)];
}

-(void)setShowPlayerOnMap{
	NSArray *arguments = [NSArray arrayWithObjects: [NSString stringWithFormat:@"%d", [AppModel sharedAppModel].playerId],[NSString stringWithFormat:@"%d", [AppModel sharedAppModel].showPlayerOnMap], nil];
	JSONConnection *jsonConnection = [[JSONConnection alloc] initWithServer:[AppModel sharedAppModel].serverURL
                                                             andServiceName:@"players"
                                                              andMethodName:@"setShowPlayerOnMap"
                                                               andArguments:arguments
                                                                andUserInfo:nil];
	[jsonConnection performAsynchronousRequestWithHandler:nil];
}

- (void)registerNewUser:(NSString*)userName password:(NSString*)pass
			  firstName:(NSString*)firstName lastName:(NSString*)lastName email:(NSString*)email {
	NSLog(@"AppModel: New User Registration Requested");
	//createPlayer($strNewUserName, $strPassword, $strFirstName, $strLastName, $strEmail)
	NSArray *arguments = [NSArray arrayWithObjects:userName, pass, firstName, lastName, email, nil];
    [AppModel sharedAppModel].userName = userName;
    [AppModel sharedAppModel].password = pass;
	JSONConnection *jsonConnection = [[JSONConnection alloc] initWithServer:[AppModel sharedAppModel].serverURL
                                                             andServiceName:@"players"
                                                              andMethodName:@"createPlayer"
                                                               andArguments:arguments
                                                                andUserInfo:nil];
	
	[jsonConnection performAsynchronousRequestWithHandler:@selector(parseSelfRegistrationResponseFromJSON:)];
}

- (void)updateServerNodeViewed: (int)nodeId fromLocation:(int)locationId {
	NSLog(@"Model: Node %d Viewed, update server", nodeId);
	
	//Call server service
	NSArray *arguments = [NSArray arrayWithObjects: [NSString stringWithFormat:@"%d",[AppModel sharedAppModel].currentGame.gameId],
						  [NSString stringWithFormat:@"%d", [AppModel sharedAppModel].playerId],
						  [NSString stringWithFormat:@"%d", nodeId],
                          [NSString stringWithFormat:@"%d",locationId],
						  nil];
	JSONConnection *jsonConnection = [[JSONConnection alloc]initWithServer:[AppModel sharedAppModel].serverURL
                                                            andServiceName:@"players"
                                                             andMethodName:@"nodeViewed"
                                                              andArguments:arguments
                                                               andUserInfo:nil];
	[jsonConnection performAsynchronousRequestWithHandler:@selector(fetchAllPlayerLists)];
}

- (void)updateServerWebPageViewed: (int)webPageId fromLocation:(int)locationId {
	NSLog(@"Model: WebPage %d Viewed, update server", webPageId);
	
	//Call server service
	NSArray *arguments = [NSArray arrayWithObjects:
						  [NSString stringWithFormat:@"%d",[AppModel sharedAppModel].currentGame.gameId],
						  [NSString stringWithFormat:@"%d",[AppModel sharedAppModel].playerId],
						  [NSString stringWithFormat:@"%d",webPageId],
                          [NSString stringWithFormat:@"%d",locationId],
						  nil];
	JSONConnection *jsonConnection = [[JSONConnection alloc]initWithServer:[AppModel sharedAppModel].serverURL
                                                            andServiceName:@"players"
                                                             andMethodName:@"webPageViewed"
                                                              andArguments:arguments
                                                               andUserInfo:nil];
	[jsonConnection performAsynchronousRequestWithHandler:@selector(fetchAllPlayerLists)];
    
}
- (void)updateServerPanoramicViewed: (int)panoramicId fromLocation:(int)locationId{
	NSLog(@"Model: Panoramic %d Viewed, update server", panoramicId);
	
	//Call server service
	NSArray *arguments = [NSArray arrayWithObjects:
						  [NSString stringWithFormat:@"%d",[AppModel sharedAppModel].currentGame.gameId],
						  [NSString stringWithFormat:@"%d",[AppModel sharedAppModel].playerId],
						  [NSString stringWithFormat:@"%d",panoramicId],
                          [NSString stringWithFormat:@"%d",locationId],
						  nil];
	JSONConnection *jsonConnection = [[JSONConnection alloc]initWithServer:[AppModel sharedAppModel].serverURL
                                                            andServiceName:@"players"
                                                             andMethodName:@"augBubbleViewed"
                                                              andArguments:arguments
                                                               andUserInfo:nil];
	[jsonConnection performAsynchronousRequestWithHandler:@selector(fetchAllPlayerLists)];
    
}

- (void)updateServerItemViewed: (int)itemId fromLocation:(int)locationId{
	NSLog(@"Model: Item %d Viewed, update server", itemId);
	
	//Call server service
	NSArray *arguments = [NSArray arrayWithObjects:
						  [NSString stringWithFormat:@"%d",[AppModel sharedAppModel].currentGame.gameId],
						  [NSString stringWithFormat:@"%d",[AppModel sharedAppModel].playerId],
						  [NSString stringWithFormat:@"%d",itemId],
                          [NSString stringWithFormat:@"%d",locationId],
						  nil];
	JSONConnection *jsonConnection = [[JSONConnection alloc]initWithServer:[AppModel sharedAppModel].serverURL
                                                            andServiceName:@"players"
                                                             andMethodName:@"itemViewed"
                                                              andArguments:arguments
                                                               andUserInfo:nil];
	[jsonConnection performAsynchronousRequestWithHandler:@selector(fetchAllPlayerLists)];
    
}

- (void)updateServerNpcViewed: (int)npcId fromLocation:(int)locationId {
	NSLog(@"Model: Npc %d Viewed, update server", npcId);
	
	//Call server service
	NSArray *arguments = [NSArray arrayWithObjects: [NSString stringWithFormat:@"%d",[AppModel sharedAppModel].currentGame.gameId],
						  [NSString stringWithFormat:@"%d",[AppModel sharedAppModel].playerId],
						  [NSString stringWithFormat:@"%d",npcId],
						  [NSString stringWithFormat:@"%d",locationId],
						  nil];
	JSONConnection *jsonConnection = [[JSONConnection alloc]initWithServer:[AppModel sharedAppModel].serverURL
                                                            andServiceName:@"players"
                                                             andMethodName:@"npcViewed"
                                                              andArguments:arguments
                                                               andUserInfo:nil];
	[jsonConnection performAsynchronousRequestWithHandler:@selector(fetchAllPlayerLists)];
    
}

- (void)updateServerGameSelected{
	NSLog(@"Model: Game %d Selected, update server", [AppModel sharedAppModel].currentGame.gameId);
	
	//Call server service
	NSArray *arguments = [NSArray arrayWithObjects:
						  [NSString stringWithFormat:@"%d",[AppModel sharedAppModel].playerId],
						  [NSString stringWithFormat:@"%d",[AppModel sharedAppModel].currentGame.gameId],
						  nil];
	JSONConnection *jsonConnection = [[JSONConnection alloc]initWithServer:[AppModel sharedAppModel].serverURL
                                                            andServiceName:@"players"
                                                             andMethodName:@"updatePlayerLastGame"
                                                              andArguments:arguments
                                                               andUserInfo:nil];
    [jsonConnection performAsynchronousRequestWithHandler:@selector(fetchAllPlayerLists)]; //This is a cheat to make sure that the fetch Happens After
    
}

- (void)updateServerMapViewed{
	NSLog(@"Model: Map Viewed, update server");
	
	//Call server service
	NSArray *arguments = [NSArray arrayWithObjects:
						  [NSString stringWithFormat:@"%d",[AppModel sharedAppModel].currentGame.gameId],
						  [NSString stringWithFormat:@"%d",[AppModel sharedAppModel].playerId],
						  nil];
	JSONConnection *jsonConnection = [[JSONConnection alloc]initWithServer:[AppModel sharedAppModel].serverURL
                                                            andServiceName:@"players"
                                                             andMethodName:@"mapViewed"
                                                              andArguments:arguments
                                                               andUserInfo:nil];
    [jsonConnection performAsynchronousRequestWithHandler:@selector(fetchAllPlayerLists)]; //This is a cheat to make sure that the fetch Happens After
    
}

- (void)updateServerQuestsViewed{
	NSLog(@"Model: Quests Viewed, update server");
	
	//Call server service
	NSArray *arguments = [NSArray arrayWithObjects:
						  [NSString stringWithFormat:@"%d",[AppModel sharedAppModel].currentGame.gameId],
						  [NSString stringWithFormat:@"%d",[AppModel sharedAppModel].playerId],
						  nil];
	JSONConnection *jsonConnection = [[JSONConnection alloc]initWithServer:[AppModel sharedAppModel].serverURL
                                                            andServiceName:@"players"
                                                             andMethodName:@"questsViewed"
                                                              andArguments:arguments
                                                               andUserInfo:nil];
    [jsonConnection performAsynchronousRequestWithHandler:@selector(fetchAllPlayerLists)]; //This is a cheat to make sure that the fetch Happens After
    
}

- (void)updateServerInventoryViewed{
	NSLog(@"Model: Inventory Viewed, update server");
	
	//Call server service
	NSArray *arguments = [NSArray arrayWithObjects:
						  [NSString stringWithFormat:@"%d",[AppModel sharedAppModel].currentGame.gameId],
						  [NSString stringWithFormat:@"%d",[AppModel sharedAppModel].playerId],
						  nil];
	JSONConnection *jsonConnection = [[JSONConnection alloc]initWithServer:[AppModel sharedAppModel].serverURL
                                                            andServiceName:@"players"
                                                             andMethodName:@"inventoryViewed"
                                                              andArguments:arguments
                                                               andUserInfo:nil];
    [jsonConnection performAsynchronousRequestWithHandler:@selector(fetchAllPlayerLists)]; //This is a cheat to make sure that the fetch Happens After
    
}
-(void)resetAndEmailNewPassword:(NSString *)email{
    NSLog(@"Resetting Email: %@",email);
    NSArray *arguments = [NSArray arrayWithObjects:
                          email,
						  nil];
	JSONConnection *jsonConnection = [[JSONConnection alloc]
                                      initWithServer:[AppModel sharedAppModel].serverURL
                                      andServiceName:@"players"
                                      andMethodName:@"resetAndEmailNewPassword"
                                      andArguments:arguments
                                      andUserInfo:nil];
	[jsonConnection performAsynchronousRequestWithHandler:
     @selector(parseResetAndEmailNewPassword:)];
}

-(void)parseResetAndEmailNewPassword:(JSONResult *)jsonResult{
    if(jsonResult == nil){
        [[RootViewController sharedRootViewController] showAlert:NSLocalizedString(@"ForgotPasswordTitleKey", nil) message:NSLocalizedString(@"ForgotPasswordMessageKey", nil)];
    }
    else{
        [[RootViewController sharedRootViewController] showAlert:NSLocalizedString(@"ForgotEmailSentTitleKey", @"") message:NSLocalizedString(@"ForgotMessageKey", @"")];
    }
}

- (void)startOverGame:(int)gameId{
	NSLog(@"Model: Start Over");
    NSLog(@"%d", gameId);
    
    [self resetAllPlayerLists];
    
    [self resetAllGameLists];
    
	//Call server service
	NSArray *arguments = [NSArray arrayWithObjects:
						  [NSString stringWithFormat:@"%d", gameId],
						  [NSString stringWithFormat:@"%d",[AppModel sharedAppModel].playerId],
						  nil];
	JSONConnection *jsonConnection = [[JSONConnection alloc]
                                      initWithServer:[AppModel sharedAppModel].serverURL
                                      andServiceName:@"players"
                                      andMethodName:@"startOverGameForPlayer"
                                      andArguments:arguments
                                      andUserInfo:nil];
	[jsonConnection performAsynchronousRequestWithHandler:
     @selector(parseStartOverFromJSON:)];
}

- (void)updateServerPickupItem: (int)itemId fromLocation: (int)locationId qty:(int)qty{
	NSLog(@"Model: Informing the Server the player picked up item");
	
	//Call server service
	NSArray *arguments = [NSArray arrayWithObjects: [NSString stringWithFormat:@"%d",[AppModel sharedAppModel].currentGame.gameId],
						  [NSString stringWithFormat:@"%d",[AppModel sharedAppModel].playerId],
						  [NSString stringWithFormat:@"%d",itemId],
						  [NSString stringWithFormat:@"%d",locationId],
						  [NSString stringWithFormat:@"%d",qty],
						  nil];
	JSONConnection *jsonConnection = [[JSONConnection alloc]initWithServer:[AppModel sharedAppModel].serverURL
                                                            andServiceName:@"players"
                                                             andMethodName:@"pickupItemFromLocation"
                                                              andArguments:arguments
                                                               andUserInfo:nil];
	[jsonConnection performAsynchronousRequestWithHandler:@selector(fetchAllPlayerLists)]; //This is a cheat to make sure that the fetch Happens After
}

- (void)updateServerDropItemHere: (int)itemId qty:(int)qty{
	NSLog(@"Model: Informing the Server the player dropped an item");
	
	//Call server service
	NSArray *arguments = [NSArray arrayWithObjects: [NSString stringWithFormat:@"%d",[AppModel sharedAppModel].currentGame.gameId],
						  [NSString stringWithFormat:@"%d",[AppModel sharedAppModel].playerId],
						  [NSString stringWithFormat:@"%d",itemId],
						  [NSString stringWithFormat:@"%f",[AppModel sharedAppModel].playerLocation.coordinate.latitude],
						  [NSString stringWithFormat:@"%f",[AppModel sharedAppModel].playerLocation.coordinate.longitude],
						  [NSString stringWithFormat:@"%d",qty],
						  nil];
	JSONConnection *jsonConnection = [[JSONConnection alloc]initWithServer:[AppModel sharedAppModel].serverURL
                                                            andServiceName:@"players"
                                                             andMethodName:@"dropItem"
                                                              andArguments:arguments
                                                               andUserInfo:nil];
	[jsonConnection performAsynchronousRequestWithHandler:@selector(fetchAllPlayerLists)]; //This is a cheat to make sure that the fetch Happens After
}

- (void)updateServerDropNoteHere: (int)noteId atCoordinate: (CLLocationCoordinate2D) coordinate{
	NSLog(@"Model: Informing the Server the player dropped an item");
	
	//Call server service
	NSArray *arguments = [NSArray arrayWithObjects: [NSString stringWithFormat:@"%d",[AppModel sharedAppModel].currentGame.gameId],
						  [NSString stringWithFormat:@"%d",[AppModel sharedAppModel].playerId],
						  [NSString stringWithFormat:@"%d",noteId],
						  [NSString stringWithFormat:@"%f",coordinate.latitude],
						  [NSString stringWithFormat:@"%f",coordinate.longitude],
						  nil];
	JSONConnection *jsonConnection = [[JSONConnection alloc]initWithServer:[AppModel sharedAppModel].serverURL
                                                            andServiceName:@"players"
                                                             andMethodName:@"dropNote"
                                                              andArguments:arguments
                                                               andUserInfo:nil];
	[jsonConnection performAsynchronousRequestWithHandler:@selector(fetchAllPlayerLists)]; //This is a cheat to make sure that the fetch Happens After
}

- (void)updateServerDestroyItem: (int)itemId qty:(int)qty {
	NSLog(@"Model: Informing the Server the player destroyed an item");
	
	//Call server service
	NSArray *arguments = [NSArray arrayWithObjects: [NSString stringWithFormat:@"%d",[AppModel sharedAppModel].currentGame.gameId],
						  [NSString stringWithFormat:@"%d",[AppModel sharedAppModel].playerId],
						  [NSString stringWithFormat:@"%d",itemId],
						  [NSString stringWithFormat:@"%d",qty],
						  nil];
	JSONConnection *jsonConnection = [[JSONConnection alloc]initWithServer:[AppModel sharedAppModel].serverURL
                                                            andServiceName:@"players"
                                                             andMethodName:@"destroyItem"
                                                              andArguments:arguments
                                                               andUserInfo:nil];
	[jsonConnection performAsynchronousRequestWithHandler:@selector(fetchAllPlayerLists)]; //This is a cheat to make sure that the fetch Happens After
}

- (void)updateServerInventoryItem:(int)itemId qty:(int)qty
{
    NSLog(@"Model: Enforcing a qty of player inventory item on server");
	
	//Call server service
	NSArray *arguments = [NSArray arrayWithObjects:
                          [NSString stringWithFormat:@"%d",[AppModel sharedAppModel].currentGame.gameId],
						  [NSString stringWithFormat:@"%d",itemId],
                          [NSString stringWithFormat:@"%d",[AppModel sharedAppModel].playerId],
						  [NSString stringWithFormat:@"%d",qty],
						  nil];
	JSONConnection *jsonConnection = [[JSONConnection alloc]initWithServer:[AppModel sharedAppModel].serverURL
                                                            andServiceName:@"players"
                                                             andMethodName:@"setItemCountForPlayer"
                                                              andArguments:arguments
                                                               andUserInfo:nil];
	[jsonConnection performAsynchronousRequestWithHandler:@selector(fetchAllPlayerLists)]; //This is a cheat to make sure that the fetch Happens After
}

- (void)updateServerAddInventoryItem:(int)itemId addQty:(int)qty
{
    NSLog(@"Model: adds a qty of player inventory item on server");
	
	//Call server service
	NSArray *arguments = [NSArray arrayWithObjects:
                          [NSString stringWithFormat:@"%d",[AppModel sharedAppModel].currentGame.gameId],
						  [NSString stringWithFormat:@"%d",itemId],
                          [NSString stringWithFormat:@"%d",[AppModel sharedAppModel].playerId],
						  [NSString stringWithFormat:@"%d",qty],
						  nil];
	JSONConnection *jsonConnection = [[JSONConnection alloc]initWithServer:[AppModel sharedAppModel].serverURL
                                                            andServiceName:@"players"
                                                             andMethodName:@"giveItemToPlayer"
                                                              andArguments:arguments
                                                               andUserInfo:nil];
	[jsonConnection performAsynchronousRequestWithHandler:@selector(fetchAllPlayerLists)]; //This is a cheat to make sure that the fetch Happens After
}

- (void)updateServerRemoveInventoryItem:(int)itemId removeQty:(int)qty
{
    NSLog(@"Model: Enforcing a qty of player inventory item on server");
	
	//Call server service
	NSArray *arguments = [NSArray arrayWithObjects:
                          [NSString stringWithFormat:@"%d",[AppModel sharedAppModel].currentGame.gameId],
						  [NSString stringWithFormat:@"%d",itemId],
                          [NSString stringWithFormat:@"%d",[AppModel sharedAppModel].playerId],
						  [NSString stringWithFormat:@"%d",qty],
						  nil];
	JSONConnection *jsonConnection = [[JSONConnection alloc]initWithServer:[AppModel sharedAppModel].serverURL
                                                            andServiceName:@"players"
                                                             andMethodName:@"takeItemFromPlayer"
                                                              andArguments:arguments
                                                               andUserInfo:nil];
	[jsonConnection performAsynchronousRequestWithHandler:@selector(fetchAllPlayerLists)]; //This is a cheat to make sure that the fetch Happens After
}

-(void)createItemAndPlaceOnMap:(Item *)item {
    NSLog(@"AppModel: Creating Note: %@",item.name);
	
	//Call server service
	NSArray *arguments = [NSArray arrayWithObjects:
						  [NSString stringWithFormat:@"%d",[AppModel sharedAppModel].currentGame.gameId],
						  [NSString stringWithFormat:@"%d",[AppModel sharedAppModel].playerId],
                          item.name,
						  item.description,
                          @"note123",
						  @"1", //dropable
						  @"1", //destroyable
						  [NSString stringWithFormat:@"%f",[AppModel sharedAppModel].playerLocation.coordinate.latitude],
						  [NSString stringWithFormat:@"%f",[AppModel sharedAppModel].playerLocation.coordinate.longitude],
                          @"NOTE",
						  nil];
	JSONConnection *jsonConnection = [[JSONConnection alloc]initWithServer:[AppModel sharedAppModel].serverURL
                                                            andServiceName:@"items"
                                                             andMethodName:@"createItemAndPlaceOnMap"
                                                              andArguments:arguments
                                                               andUserInfo:nil];
	[jsonConnection performAsynchronousRequestWithHandler:@selector(fetchAllPlayerLists)];
    
}

- (void)commitInventoryTrade:(int)gameId fromMe:(int)playerOneId toYou:(int)playerTwoId giving:(NSString *)giftsJSON receiving:(NSString *)receiptsJSON
{
    /*
     * Gifts/Receipts json should be of following format:
     * {"items":[{"item_id":1,"qtyDelta":3},{"item_id":2,"qtyDelta":4}]}
     */
    
    //Call server service
	NSArray *arguments = [NSArray arrayWithObjects:
						  [NSString stringWithFormat:@"%d",gameId],
						  [NSString stringWithFormat:@"%d",playerOneId],
						  [NSString stringWithFormat:@"%d",playerTwoId],
                          giftsJSON,
                          receiptsJSON,
						  nil];
	JSONConnection *jsonConnection = [[JSONConnection alloc]initWithServer:[AppModel sharedAppModel].serverURL
                                                            andServiceName:@"items"
                                                             andMethodName:@"commitTradeTransaction"
                                                              andArguments:arguments
                                                               andUserInfo:nil];
	[jsonConnection performAsynchronousRequestWithHandler:@selector(fetchInventory)];
}

-(void)createItemAndGivetoPlayer:(Item *)item {
    NSLog(@"AppModel: Creating Note: %@",item.name);
	
	//Call server service
	NSArray *arguments = [NSArray arrayWithObjects:
						  [NSString stringWithFormat:@"%d",[AppModel sharedAppModel].currentGame.gameId],
						  [NSString stringWithFormat:@"%d",[AppModel sharedAppModel].playerId],
                          item.name,
						  item.description,
                          @"note123",
						  @"1", //dropable
						  @"1", //destroyable
						  [NSString stringWithFormat:@"%f",[AppModel sharedAppModel].playerLocation.coordinate.latitude],
						  [NSString stringWithFormat:@"%f",[AppModel sharedAppModel].playerLocation.coordinate.longitude],
                          @"NOTE",
						  nil];
	JSONConnection *jsonConnection = [[JSONConnection alloc]initWithServer:[AppModel sharedAppModel].serverURL
                                                            andServiceName:@"items"
                                                             andMethodName:@"createItemAndGiveToPlayer"
                                                              andArguments:arguments
                                                               andUserInfo:nil];
	[jsonConnection performAsynchronousRequestWithHandler:@selector(fetchAllPlayerLists)];
    
}

-(void)updateCommentWithId:(int)noteId andTitle:(NSString *)title andRefresh:(BOOL)refresh{
    NSLog(@"AppModel: Updating Comment Rating");
	
	//Call server service
	NSArray *arguments = [NSArray arrayWithObjects:
						  [NSString stringWithFormat:@"%d",noteId],
                          title,
                          nil];
	JSONConnection *jsonConnection = [[JSONConnection alloc]initWithServer:[AppModel sharedAppModel].serverURL
                                                            andServiceName:@"notes"
                                                             andMethodName:@"updateComment"
                                                              andArguments:arguments
                                                               andUserInfo:nil];
    
    if(refresh)
        [jsonConnection performAsynchronousRequestWithHandler:@selector(fetchPlayerNoteListAsync)];
    
    else
        [jsonConnection performAsynchronousRequestWithHandler:nil];
	
}

-(void)likeNote:(int)noteId{
    NSLog(@"Liking Note: %d",noteId);
    NSArray *arguments = [NSArray arrayWithObjects:
						  [NSString stringWithFormat:@"%d",[AppModel sharedAppModel].playerId],
                          [NSString stringWithFormat:@"%d",noteId],
                          nil];
	JSONConnection *jsonConnection = [[JSONConnection alloc]initWithServer:[AppModel sharedAppModel].serverURL
                                                            andServiceName:@"notes"
                                                             andMethodName:@"likeNote"
                                                              andArguments:arguments
                                                               andUserInfo:nil];
	[jsonConnection performAsynchronousRequestWithHandler:@selector(fetchAllPlayerLists)]; //This is a cheat to make sure that the fetch Happens After
    
}

-(void)unLikeNote:(int)noteId{
    NSLog(@"Unliking Note: %d",noteId);
    
    NSArray *arguments = [NSArray arrayWithObjects:
						  [NSString stringWithFormat:@"%d",[AppModel sharedAppModel].playerId],
                          [NSString stringWithFormat:@"%d",noteId],
                          nil];
	JSONConnection *jsonConnection = [[JSONConnection alloc]initWithServer:[AppModel sharedAppModel].serverURL
                                                            andServiceName:@"notes"
                                                             andMethodName:@"unlikeNote"
                                                              andArguments:arguments
                                                               andUserInfo:nil];
    [jsonConnection performAsynchronousRequestWithHandler:@selector(fetchAllPlayerLists)]; //This is a cheat to make sure that the fetch Happens After
}

-(int)addCommentToNoteWithId:(int)noteId andTitle:(NSString *)title{
    NSLog(@"AppModel: Adding Comment To Note");
	
	//Call server service
	NSArray *arguments = [NSArray arrayWithObjects:
						  [NSString stringWithFormat:@"%d",[AppModel sharedAppModel].currentGame.gameId],
						  [NSString stringWithFormat:@"%d",[AppModel sharedAppModel].playerId],
                          [NSString stringWithFormat:@"%d",noteId],
                          title,
                          nil];
	JSONConnection *jsonConnection = [[JSONConnection alloc]initWithServer:[AppModel sharedAppModel].serverURL
                                                            andServiceName:@"notes"
                                                             andMethodName:@"addCommentToNoteStartIncomplete"
                                                              andArguments:arguments
                                                               andUserInfo:nil];
	JSONResult *jsonResult = [jsonConnection performSynchronousRequest];
    [self fetchAllPlayerLists];
	
	if (!jsonResult) {
		NSLog(@"\tFailed.");
		return 0;
	}
	
	return [(NSDecimalNumber*)jsonResult.data intValue];
}

-(void)setNoteCompleteForNoteId:(int)noteId {
    NSLog(@"AppModel: Setting Note Complete");
	
	//Call server service
	NSArray *arguments = [NSArray arrayWithObjects:
                          [NSString stringWithFormat:@"%d",noteId],
                          nil];
	JSONConnection *jsonConnection = [[JSONConnection alloc]initWithServer:[AppModel sharedAppModel].serverURL
                                                            andServiceName:@"notes"
                                                             andMethodName:@"setNoteComplete"
                                                              andArguments:arguments
                                                               andUserInfo:nil];
	JSONResult *jsonResult = [jsonConnection performSynchronousRequest];
    [self fetchAllPlayerLists];
	
	if (!jsonResult) {
		NSLog(@"\tFailed.");
        
	}
	
}

-(int)createNote{
    NSLog(@"AppModel: Creating New Note");
	
	//Call server service
	NSArray *arguments = [NSArray arrayWithObjects:
						  [NSString stringWithFormat:@"%d",[AppModel sharedAppModel].currentGame.gameId],
						  [NSString stringWithFormat:@"%d",[AppModel sharedAppModel].playerId],
						  [NSString stringWithFormat:@"%f",[AppModel sharedAppModel].playerLocation.coordinate.latitude],
						  [NSString stringWithFormat:@"%f",[AppModel sharedAppModel].playerLocation.coordinate.longitude],
                          nil];
	JSONConnection *jsonConnection = [[JSONConnection alloc]initWithServer:[AppModel sharedAppModel].serverURL
                                                            andServiceName:@"notes"
                                                             andMethodName:@"createNewNote"
                                                              andArguments:arguments
                                                               andUserInfo:nil];
	JSONResult *jsonResult = [jsonConnection performSynchronousRequest];
    [self fetchAllPlayerLists]; //This is a cheat to make sure that the fetch Happens After
	if (!jsonResult) {
		NSLog(@"\tFailed.");
		return 0;
	}
	
	return (jsonResult.data != [NSNull null]) ? [(NSDecimalNumber*)jsonResult.data intValue] : 0;
}

-(int)createNoteStartIncomplete{
    NSLog(@"AppModel: Creating New Note Start Incomplete");
	
	//Call server service
	NSArray *arguments = [NSArray arrayWithObjects:
						  [NSString stringWithFormat:@"%d",[AppModel sharedAppModel].currentGame.gameId],
						  [NSString stringWithFormat:@"%d",[AppModel sharedAppModel].playerId],
						  [NSString stringWithFormat:@"%f",[AppModel sharedAppModel].playerLocation.coordinate.latitude],
						  [NSString stringWithFormat:@"%f",[AppModel sharedAppModel].playerLocation.coordinate.longitude],
                          nil];
	JSONConnection *jsonConnection = [[JSONConnection alloc]initWithServer:[AppModel sharedAppModel].serverURL
                                                            andServiceName:@"notes"
                                                             andMethodName:@"createNewNoteStartIncomplete"
                                                              andArguments:arguments
                                                               andUserInfo:nil];
	JSONResult *jsonResult = [jsonConnection performSynchronousRequest];
    [self fetchAllPlayerLists]; //This is a cheat to make sure that the fetch Happens After
	if (!jsonResult) {
		NSLog(@"\tFailed.");
		return 0;
	}
	
	return (jsonResult.data != [NSNull null]) ? [(NSDecimalNumber*)jsonResult.data intValue] : 0;
}

-(void) contentAddedToNoteWithText:(JSONResult *)result
{
    if([result.userInfo objectForKey:@"noteId"] != [NSNull null])
        [[AppModel sharedAppModel].uploadManager deleteContentFromNoteId:[self validIntForKey:@"noteId" inDictionary:result.userInfo] andFileURL:[result.userInfo objectForKey:@"localURL"]];
    [[AppModel sharedAppModel].uploadManager contentFinishedUploading];
    [self fetchPlayerNoteListAsync];
}

-(void) addContentToNoteWithText:(NSString *)text type:(NSString *) type mediaId:(int) mediaId andNoteId:(int)noteId andFileURL:(NSURL *)fileURL{
    NSLog(@"AppModel: Adding Text Content To Note: %d",noteId);
	
	//Call server service
	NSArray *arguments = [NSArray arrayWithObjects:
						  [NSString stringWithFormat:@"%d",noteId],
                          [NSString stringWithFormat:@"%d",[AppModel sharedAppModel].currentGame.gameId],
                          [NSString stringWithFormat:@"%d",[AppModel sharedAppModel].playerId],
						  [NSString stringWithFormat:@"%d",mediaId],
                          type,
						  text,
						  nil];
    
    NSMutableDictionary* userInfo = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:noteId], @"noteId", fileURL, @"localURL", nil];
	JSONConnection *jsonConnection = [[JSONConnection alloc]initWithServer:[AppModel sharedAppModel].serverURL
                                                            andServiceName:@"notes"
                                                             andMethodName:@"addContentToNote"
                                                              andArguments:arguments
                                                               andUserInfo:userInfo];
	[jsonConnection performAsynchronousRequestWithHandler:@selector(contentAddedToNoteWithText:)];
}

-(void)deleteNoteContentWithContentId:(int)contentId{
    if(contentId != -1){
        NSLog(@"AppModel: Deleting Content From Note with contentId: %d",contentId);
        
        //Call server service
        NSArray *arguments = [NSArray arrayWithObjects:
                              [NSString stringWithFormat:@"%d",contentId],
                              nil];
        JSONConnection *jsonConnection = [[JSONConnection alloc]initWithServer:[AppModel sharedAppModel].serverURL
                                                                andServiceName:@"notes"
                                                                 andMethodName:@"deleteNoteContent"
                                                                  andArguments:arguments
                                                                   andUserInfo:nil];
        [jsonConnection performAsynchronousRequestWithHandler:@selector(sendNotificationToNoteViewer)];
    }
    
}

-(void)deleteNoteLocationWithNoteId:(int)noteId{
    NSLog(@"AppModel: Deleting Location of Note: %d",noteId);
	
	//Call server service
	NSArray *arguments = [NSArray arrayWithObjects:
                          [NSString stringWithFormat:@"%d",[AppModel sharedAppModel].currentGame.gameId],
                          @"PlayerNote",
						  [NSString stringWithFormat:@"%d",noteId],
						  nil];
	JSONConnection *jsonConnection = [[JSONConnection alloc]initWithServer:[AppModel sharedAppModel].serverURL
                                                            andServiceName:@"locations"
                                                             andMethodName:@"deleteLocationsForObject"
                                                              andArguments:arguments
                                                               andUserInfo:nil];
    [jsonConnection performAsynchronousRequestWithHandler:@selector(fetchAllPlayerLists)]; //This is a cheat to make sure that the fetch Happens After
	
}

-(void)deleteNoteWithNoteId:(int)noteId{
    if(noteId != 0){
        NSLog(@"AppModel: Deleting Note: %d",noteId);
        
        //Call server service
        NSArray *arguments = [NSArray arrayWithObjects:
                              [NSString stringWithFormat:@"%d",noteId],
                              nil];
        JSONConnection *jsonConnection = [[JSONConnection alloc]initWithServer:[AppModel sharedAppModel].serverURL
                                                                andServiceName:@"notes"
                                                                 andMethodName:@"deleteNote"
                                                                  andArguments:arguments
                                                                   andUserInfo:nil];
        [jsonConnection performAsynchronousRequestWithHandler:@selector(sendNotificationToNotebookViewer)];
    }
    else{
        NSLog(@"Tried deleting note 0 and that's a no-no!");
    }
    
}

-(void)sendNotificationToNoteViewer{
    [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:@"NewContentListReady" object:nil]];
    [self fetchPlayerNoteListAsync];
}

-(void)sendNotificationToNotebookViewer{
    [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:@"NoteDeleted" object:nil]];
    [self fetchPlayerNoteListAsync];
}

-(void) uploadContentToNoteWithFileURL:(NSURL *)fileURL name:(NSString *)name noteId:(int) noteId type: (NSString *)type{
    ARISUploader *uploader = [[ARISUploader alloc]initWithURLToUpload:fileURL gameSpecific:YES delegate:self doneSelector:@selector(noteContentUploadDidfinish: ) errorSelector:@selector(uploadNoteContentDidFail:)];
    
    NSNumber *nId = [[NSNumber alloc]initWithInt:noteId];
    
    NSMutableDictionary *userInfo = [[NSMutableDictionary alloc]initWithCapacity:4];
    [userInfo setValue:name forKey:@"title"];
    [userInfo setValue:nId forKey:@"noteId"];
    [userInfo setValue:type forKey: @"type"];
    [userInfo setValue:fileURL forKey:@"url"];
	[uploader setUserInfo:userInfo];
	
	NSLog(@"Model: Uploading File. gameID:%d title:%@ noteId:%d",[AppModel sharedAppModel].currentGame.gameId,name,noteId);
	
	//ARISAppDelegate* appDelegate = (ARISAppDelegate *)[[UIApplication sharedApplication] delegate];
    //[[[RootViewController sharedRootViewController] showNewWaitingIndicator:@"Uploading" displayProgressBar:YES];
	//[request setUploadProgressDelegate:appDelegate.waitingIndicator.progressView];
    
	[uploader upload];
    
    [self fetchAllPlayerLists];
}

-(void) uploadPlayerPicMediaWithFileURL:(NSURL *)fileURL type:(NSString *)type{
    ARISUploader *uploader = [[ARISUploader alloc]initWithURLToUpload:fileURL gameSpecific:NO delegate:self doneSelector:@selector(playerPicUploadDidfinish: ) errorSelector:@selector(playerPicUploadDidFail:)];
    
    NSMutableDictionary *userInfo = [[NSMutableDictionary alloc]initWithCapacity:2];
    [userInfo setValue:type forKey: @"type"];
    [userInfo setValue:fileURL forKey:@"url"];
	[uploader setUserInfo:userInfo];
	
	NSLog(@"Model: Uploading File. gameID:%d ",[AppModel sharedAppModel].currentGame.gameId);
	
	//ARISAppDelegate* appDelegate = (ARISAppDelegate *)[[UIApplication sharedApplication] delegate];
    //[[[RootViewController sharedRootViewController] showNewWaitingIndicator:@"Uploading" displayProgressBar:YES];
	//[request setUploadProgressDelegate:appDelegate.waitingIndicator.progressView];
    
	[uploader upload];
}

-(void) updatePlayer:(int)playerId Name:(NSString *)name Image:(int)mid
{
    if(playerId != 0){
        NSLog(@"AppModel: Updating Player info: %@ %d", name, mid);
        
        //Call server service
        NSArray *arguments = [NSArray arrayWithObjects:
                              [NSString stringWithFormat:@"%d",playerId],
                              name,
                              [NSString stringWithFormat:@"%d",mid],
                              nil];
        JSONConnection *jsonConnection = [[JSONConnection alloc]initWithServer:[AppModel sharedAppModel].serverURL
                                                                andServiceName:@"players"
                                                                 andMethodName:@"updatePlayerNameMedia"
                                                                  andArguments:arguments
                                                                   andUserInfo:nil];
        [jsonConnection performAsynchronousRequestWithHandler:nil];
    }
    else{
        NSLog(@"Tried updating non-existent player! (playerId = 0)");
    }
}

-(void)fetchPlayerNoteListAsync{
    ///if([AppModel sharedAppModel].isGameNoteList)
    [self fetchGameNoteListAsynchronously:YES];
    // else
    [self fetchPlayerNoteListAsynchronously:YES];
}

- (void)noteContentUploadDidfinish:(ARISUploader*)uploader {
	NSLog(@"Model: Upload Note Content Request Finished. Response: %@", [uploader responseString]);
	
    int noteId = ([[uploader userInfo] objectForKey:@"noteId"] != [NSNull null]) ? [self validIntForKey:@"noteId" inDictionary:[uploader userInfo]] : 0;
	NSString *title = [[uploader userInfo] objectForKey:@"title"];
    NSString *type = [[uploader userInfo] objectForKey:@"type"];
    NSURL *localUrl = [[uploader userInfo] objectForKey:@"url"];
    NSString *newFileName = [uploader responseString];
    
    //TODO: Check that the response string is actually a new filename that was made on the server, not an error
    
    NoteContent *newContent = [[NoteContent alloc] init];
    newContent.noteId = noteId;
    newContent.title = @"Refreshing From Server...";
    newContent.type = type;
    newContent.contentId = 0;
    
    
    [[[[[AppModel sharedAppModel] playerNoteList] objectForKey:[NSNumber numberWithInt:noteId]] contents] addObject:newContent];
    [[AppModel sharedAppModel].uploadManager deleteContentFromNoteId:noteId andFileURL:localUrl];
    [[AppModel sharedAppModel].uploadManager contentFinishedUploading];
    
	NSLog(@"AppModel: Creating Note Content for Title:%@ File:%@",title,newFileName);
	
	//Call server service
	NSArray *arguments = [NSArray arrayWithObjects:
						  [NSString stringWithFormat:@"%d",[AppModel sharedAppModel].currentGame.gameId],
						  [NSString stringWithFormat:@"%d",noteId],
                          [NSString stringWithFormat:@"%d",[AppModel sharedAppModel].playerId],
						  newFileName,
                          type,
                          title,
                          nil];
	JSONConnection *jsonConnection = [[JSONConnection alloc]initWithServer:[AppModel sharedAppModel].serverURL
                                                            andServiceName:@"notes"
                                                             andMethodName:@"addContentToNoteFromFileName"
                                                              andArguments:arguments
                                                               andUserInfo:nil];
    //[AppModel sharedAppModel].isGameNoteList = NO;
	[jsonConnection performAsynchronousRequestWithHandler:@selector(fetchPlayerNoteListAsync)];
    [self fetchAllPlayerLists];
}

- (void)uploadNoteContentDidFail:(ARISUploader *)uploader {
    NSError *error = uploader.error;
	NSLog(@"Model: uploadRequestFailed: %@",[error localizedDescription]);
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle: NSLocalizedString(@"UploadFailedKey", @"") message: NSLocalizedString(@"AppServicesUploadFailedMessageKey", @"") delegate: self cancelButtonTitle: NSLocalizedString(@"OkKey", @"") otherButtonTitles: nil];
	
	[alert show];
    
    NSNumber *nId = [[NSNumber alloc]initWithInt:5];
    nId = [[uploader userInfo] objectForKey:@"noteId"];
	//if (description == NULL) description = @"filename";
    
    [[AppModel sharedAppModel].uploadManager contentFailedUploading];
    [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:@"NewNoteListReady" object:nil]];
}

- (void)playerPicUploadDidfinish:(ARISUploader*)uploader {
	NSLog(@"Model: Upload Note Content Request Finished. Response: %@", [uploader responseString]);
    
    //Call server service
    
    NSString *newFileName = [uploader responseString];
    
	NSArray *arguments = [NSArray arrayWithObjects:
                          [NSString stringWithFormat:@"%d",[AppModel sharedAppModel].playerId],
						  newFileName,
                          nil];
	JSONConnection *jsonConnection = [[JSONConnection alloc]initWithServer:[AppModel sharedAppModel].serverURL
                                                            andServiceName:@"players"
                                                             andMethodName:@"addPlayerPicFromFilename"
                                                              andArguments:arguments
                                                               andUserInfo:nil];
    [jsonConnection performAsynchronousRequestWithHandler:@selector(parseNewPlayerMediaResponseFromJSON:)];
    [[AppModel sharedAppModel].uploadManager contentFinishedUploading];
}

-(void)parseNewPlayerMediaResponseFromJSON: (JSONResult *)jsonResult{
	NSLog(@"AppModel: parseNewPlayerMediaResponseFromJSON");
	
	[[RootViewController sharedRootViewController] removeNewWaitingIndicator];
    
	if ((NSNull *)jsonResult.data != [NSNull null] && jsonResult.data != nil && [((NSDictionary *)jsonResult.data) objectForKey:@"media_id"])
    {
        [AppModel sharedAppModel].playerMediaId = [self validIntForKey:@"media_id" inDictionary:((NSDictionary*)jsonResult.data)];
        [[AppModel sharedAppModel] saveUserDefaults];
    }
}


- (void)playerPicUploadDidFail:(ARISUploader *)uploader {
    NSError *error = uploader.error;
	NSLog(@"Model: uploadRequestFailed: %@",[error localizedDescription]);
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle: NSLocalizedString(@"UploadFailedKey", @"") message: NSLocalizedString(@"AppServicesUploadFailedMessageKey", @"") delegate: self cancelButtonTitle: NSLocalizedString(@"OkKey", @"") otherButtonTitles: nil];
	
	[alert show];
    
    [[AppModel sharedAppModel].uploadManager contentFailedUploading];
}

-(void)updateNoteWithNoteId:(int)noteId title:(NSString *)title publicToMap:(BOOL)publicToMap publicToList:(BOOL)publicToList{
    NSLog(@"Model: Updating Note with ID: %d andTitle: %@ andPublicToMap:%d andPublicToList: %d",noteId,title,publicToMap,publicToList);
	
	//Call server service
	NSArray *arguments = [NSArray arrayWithObjects: [NSString stringWithFormat:@"%d",noteId],
						  title,
                          [NSString stringWithFormat:@"%d",publicToMap],
                          [NSString stringWithFormat:@"%d",publicToList],
						  nil];
	JSONConnection *jsonConnection = [[JSONConnection alloc]initWithServer:[AppModel sharedAppModel].serverURL
                                                            andServiceName:@"notes"
                                                             andMethodName:@"updateNote"
                                                              andArguments:arguments
                                                               andUserInfo:nil];
	[jsonConnection performAsynchronousRequestWithHandler:@selector(fetchAllPlayerLists)]; //This is a cheat to make sure that the fetch Happens After
    
}

- (void)updateNoteContent:(int)contentId title:(NSString *)text;
{
    NSLog(@"Model: Updating Note Content Title");
	
	//Call server service
	NSArray *arguments = [NSArray arrayWithObjects: [NSString stringWithFormat:@"%d",contentId],
						  text,
						  nil];
	JSONConnection *jsonConnection = [[JSONConnection alloc]initWithServer:[AppModel sharedAppModel].serverURL
                                                            andServiceName:@"notes"
                                                             andMethodName:@"updateContentTitle"
                                                              andArguments:arguments
                                                               andUserInfo:nil];
	[jsonConnection performAsynchronousRequestWithHandler:@selector(fetchAllPlayerLists)]; //This is a cheat to make sure that the fetch Happens After
    
}

-(void)updateNoteContent:(int)contentId text:(NSString *)text{
    NSLog(@"Model: Updating Note Text Content");
	
	//Call server service
	NSArray *arguments = [NSArray arrayWithObjects: [NSString stringWithFormat:@"%d",contentId],
						  text,
						  nil];
	JSONConnection *jsonConnection = [[JSONConnection alloc]initWithServer:[AppModel sharedAppModel].serverURL
                                                            andServiceName:@"notes"
                                                             andMethodName:@"updateContent"
                                                              andArguments:arguments
                                                               andUserInfo:nil];
	[jsonConnection performAsynchronousRequestWithHandler:@selector(fetchAllPlayerLists)]; //This is a cheat to make sure that the fetch Happens After
    
}

-(void)updateItem:(Item *)item {
    NSLog(@"Model: Updating Item");
	
	//Call server service
	NSArray *arguments = [NSArray arrayWithObjects: [NSString stringWithFormat:@"%d",[AppModel sharedAppModel].currentGame.gameId],
						  [NSString stringWithFormat:@"%d",item.itemId],
						  item.name,
						  item.description,
                          [NSString stringWithFormat:@"%d",item.iconMediaId],
						  [NSString stringWithFormat:@"%d",item.mediaId],
						  [NSString stringWithFormat:@"%d",item.dropable],
                          [NSString stringWithFormat:@"%d",item.destroyable],
						  [NSString stringWithFormat:@"%d",item.isAttribute],
						  [NSString stringWithFormat:@"%d",item.maxQty],
                          [NSString stringWithFormat:@"%d",item.weight],
						  item.url,
						  item.type,
						  nil];
	JSONConnection *jsonConnection = [[JSONConnection alloc]initWithServer:[AppModel sharedAppModel].serverURL
                                                            andServiceName:@"items"
                                                             andMethodName:@"updateItem"
                                                              andArguments:arguments
                                                               andUserInfo:nil];
	[jsonConnection performAsynchronousRequestWithHandler:@selector(fetchAllPlayerLists)]; //This is a cheat to make sure that the fetch Happens After
    
}

- (void)uploadImageForMatching:(NSURL *)fileURL{
    
    ARISUploader *uploader = [[ARISUploader alloc]initWithURLToUpload:fileURL gameSpecific:YES delegate:self doneSelector:@selector(uploadImageForMatchingDidFinish: ) errorSelector:@selector(uploadImageForMatchingDidFail:)];
    
    NSLog(@"Model: Uploading File. gameID:%d",[AppModel sharedAppModel].currentGame.gameId);
    
    [AppModel sharedAppModel].fileToDeleteURL = fileURL;
    
    [[RootViewController sharedRootViewController] showNewWaitingIndicator:@"Uploading" displayProgressBar:YES];
    //[uplaoder setUploadProgressDelegate:appDelegate.waitingIndicator.progressView];
    [uploader upload];
    
}

- (void)uploadImageForMatchingDidFinish:(ARISUploader *)uploader
{
	[[RootViewController sharedRootViewController] removeNewWaitingIndicator];
    
    [[RootViewController sharedRootViewController] showNewWaitingIndicator:@"Decoding Image" displayProgressBar:NO];
	
	NSString *response = [uploader responseString];
    
	NSLog(@"Model: uploadImageForMatchingRequestFinished: Upload Media Request Finished. Response: %@", response);
    
	NSString *newFileName = [uploader responseString];
    
	NSLog(@"AppModel: uploadImageForMatchingRequestFinished: Trying to Match:%@",newFileName);
	
	//Call server service
	NSArray *arguments = [NSArray arrayWithObjects:
						  [NSString stringWithFormat:@"%d",[AppModel sharedAppModel].currentGame.gameId],
						  [NSString stringWithFormat:@"%d",[AppModel sharedAppModel].playerId],
						  newFileName,
						  nil];
	JSONConnection *jsonConnection = [[JSONConnection alloc]initWithServer:[AppModel sharedAppModel].serverURL
                                                            andServiceName:@"qrcodes"
                                                             andMethodName:@"getBestImageMatchNearbyObjectForPlayer"
                                                              andArguments:arguments
                                                               andUserInfo:nil];
	[jsonConnection performAsynchronousRequestWithHandler:@selector(parseQRCodeObjectFromJSON:)];
    
    
    
    // delete temporary image file
    NSError *error;
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    
    if ([fileMgr removeItemAtURL:[AppModel sharedAppModel].fileToDeleteURL error:&error] != YES)
        NSLog(@"Unable to delete file: %@", [error localizedDescription]);
    
}

- (void)uploadImageForMatchingDidFail:(ARISUploader *)uploader
{
	[[RootViewController sharedRootViewController] removeNewWaitingIndicator];
	NSError *error = [uploader error];
	NSLog(@"Model: uploadRequestFailed: %@",[error localizedDescription]);
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle: NSLocalizedString(@"UploadFailedKey", @"") message: NSLocalizedString(@"AppServicesUploadFailedMessageKey", @"") delegate: self cancelButtonTitle: NSLocalizedString(@"OkKey", @"") otherButtonTitles: nil];
    
    // delete temporary image file
    NSError *error2;
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    
    if ([fileMgr removeItemAtURL:[AppModel sharedAppModel].fileToDeleteURL error:&error2] != YES)
        NSLog(@"Unable to delete file: %@", [error localizedDescription]);;
	
	[alert show];
}

- (void)updateServerWithPlayerLocation {
	NSLog(@"Model: updating player position on server and determining nearby Locations");
	
	if (![AppModel sharedAppModel].loggedIn) {
		NSLog(@"Model: Player Not logged in yet, skip the location update");
		return;
	}
	
	if (currentlyUpdatingServerWithPlayerLocation) {
        NSLog(@"AppModel: Currently Updating server with player location, skipping this update");
        return;
    }
    
    currentlyUpdatingServerWithPlayerLocation = YES;
    
	//Update the server with the new Player Location
	NSArray *arguments = [NSArray arrayWithObjects: [NSString stringWithFormat:@"%d",[AppModel sharedAppModel].playerId],
						  [NSString stringWithFormat:@"%d",[AppModel sharedAppModel].currentGame.gameId],
						  [NSString stringWithFormat:@"%f",[AppModel sharedAppModel].playerLocation.coordinate.latitude],
						  [NSString stringWithFormat:@"%f",[AppModel sharedAppModel].playerLocation.coordinate.longitude],
						  nil];
	JSONConnection *jsonConnection = [[JSONConnection alloc] initWithServer:[AppModel sharedAppModel].serverURL
                                                             andServiceName:@"players"
                                                              andMethodName:@"updatePlayerLocation"
                                                               andArguments:arguments
                                                                andUserInfo:nil];
	[jsonConnection performAsynchronousRequestWithHandler:@selector(parseUpdateServerWithPlayerLocationFromJSON:)];
	
}

- (void) silenceNextServerUpdate {
	NSLog(@"AppModel: silenceNextServerUpdate");
	
	NSNotification *notification = [NSNotification notificationWithName:@"SilentNextUpdate" object:nil];
	[[NSNotificationCenter defaultCenter] postNotification:notification];
}

#pragma mark Sync Fetch selectors
- (id) fetchFromService:(NSString *)aService usingMethod:(NSString *)aMethod
			   withArgs:(NSArray *)arguments usingParser:(SEL)aSelector
{
	NSLog(@"JSON://%@/%@/%@", aService, aMethod, arguments);
	
	JSONConnection *jsonConnection = [[JSONConnection alloc]initWithServer:[AppModel sharedAppModel].serverURL
                                                            andServiceName:aService
                                                             andMethodName:aMethod
                                                              andArguments:arguments
                                                               andUserInfo:nil];
	JSONResult *jsonResult = [jsonConnection performSynchronousRequest];
	
	
	if (!jsonResult) {
		NSLog(@"\tFailed.");
		return nil;
	}
	
	return [self performSelector:aSelector withObject:jsonResult.data];
}

-(Item *)fetchItem:(int)itemId{
	NSLog(@"Model: Fetch Requested for Item %d", itemId);
	NSArray *arguments = [NSArray arrayWithObjects: [NSString stringWithFormat:@"%d",[AppModel sharedAppModel].currentGame.gameId],
						  [NSString stringWithFormat:@"%d",itemId],
						  nil];
    
	return [self fetchFromService:@"items" usingMethod:@"getItem" withArgs:arguments
					  usingParser:@selector(parseItemFromDictionary:)];
}

-(Node *)fetchNode:(int)nodeId{
	NSLog(@"Model: Fetch Requested for Node %d", nodeId);
	NSArray *arguments = [NSArray arrayWithObjects: [NSString stringWithFormat:@"%d",[AppModel sharedAppModel].currentGame.gameId],
						  [NSString stringWithFormat:@"%d",nodeId],
						  nil];
	
	return [self fetchFromService:@"nodes" usingMethod:@"getNode" withArgs:arguments
					  usingParser:@selector(parseNodeFromDictionary:)];
}

-(Note *)fetchNote:(int)noteId{
    NSLog(@"AppModel: Fetching Note:%d",noteId);
	
	NSArray *arguments = [NSArray arrayWithObjects:[NSString stringWithFormat:@"%d",noteId],[NSString stringWithFormat:@"%d",[AppModel sharedAppModel].playerId], nil];
	
    return [self fetchFromService:@"notes" usingMethod:@"getNoteById" withArgs:arguments
					  usingParser:@selector(parseNoteFromDictionary:)];
    
}

-(Npc *)fetchNpc:(int)npcId{
	NSLog(@"Model: Fetch Requested for Npc %d", npcId);
	NSArray *arguments = [NSArray arrayWithObjects: [NSString stringWithFormat:@"%d",[AppModel sharedAppModel].currentGame.gameId],
						  [NSString stringWithFormat:@"%d",npcId],
						  [NSString stringWithFormat:@"%d",[AppModel sharedAppModel].playerId],
						  nil];
	return [self fetchFromService:@"npcs" usingMethod:@"getNpcWithConversationsForPlayer"
						 withArgs:arguments usingParser:@selector(parseNpcFromDictionary:)];
}

-(int)getItemViewed:(int)itemId{
	NSLog(@"Model: Get item viewed by player");
	NSArray *arguments = [NSArray arrayWithObjects: [NSString stringWithFormat:@"%d",[AppModel sharedAppModel].currentGame.gameId],
						  [NSString stringWithFormat:@"%d",itemId],
						  [NSString stringWithFormat:@"%d",[AppModel sharedAppModel].playerId],
						  nil];
	return [self fetchFromService:@"players" usingMethod:@"getItemViewed"
						 withArgs:arguments usingParser:@selector(parseItemViewed:)];
}

-(int)parseItemViewed: (NSDictionary *)itemDictionary {
	int iViewed = [itemDictionary valueForKey:@"viewed"];
	return iViewed;
}

#pragma mark ASync Fetch selectors

- (void)fetchAllGameLists {
	[self fetchGameItemListAsynchronously:YES];
	[self fetchGameNpcListAsynchronously:YES];
	[self fetchGameNodeListAsynchronously:YES];
	[self fetchGameMediaListAsynchronously:YES];
    [self fetchGamePanoramicListAsynchronously:YES];
    [self fetchGameWebpageListAsynchronously:YES];
    [self fetchPlayerNoteListAsynchronously:YES];
    [self fetchGameNoteListAsynchronously:NO];
    
}

- (void)resetAllGameLists {
	NSLog(@"AppModel: resetAllGameLists");
    
	//Clear them out
	[[AppModel sharedAppModel].gameItemList removeAllObjects];
	[[AppModel sharedAppModel].gameNodeList removeAllObjects];
    [[AppModel sharedAppModel].gameNpcList removeAllObjects];
    [[AppModel sharedAppModel].gameMediaList removeAllObjects];
    [[AppModel sharedAppModel].gameWebPageList removeAllObjects];
    [[AppModel sharedAppModel].gamePanoramicList removeAllObjects];
    [[AppModel sharedAppModel].playerNoteList removeAllObjects];
    [[AppModel sharedAppModel].gameNoteList removeAllObjects];
}

- (void)fetchOverlayListAsynchronously:(BOOL)YesForAsyncOrNoForSync {
	NSLog(@"AppModel: Fetching Map Overlay List");
	
	NSArray *arguments = [NSArray arrayWithObjects:[NSString stringWithFormat:@"%d",[AppModel sharedAppModel].currentGame.gameId],
                          [NSString stringWithFormat:@"%d",[AppModel sharedAppModel].playerId], nil];
    
	JSONConnection *jsonConnection = [[JSONConnection alloc]initWithServer:[AppModel sharedAppModel].serverURL
                                                            andServiceName:@"overlays"
                                                             andMethodName:@"getCurrentOverlaysForPlayer"
                                                              andArguments:arguments andUserInfo:nil];
	
	if (YesForAsyncOrNoForSync){
		[jsonConnection performAsynchronousRequestWithHandler:@selector(parseOverlayListFromJSON:)];
	}
    else [self parseOverlayListFromJSON: [jsonConnection performSynchronousRequest]];
}

-(void)parseOverlayListFromJSON: (JSONResult *)jsonResult{
    //   currentlyFetchingGamesList = NO; Is there a reason for this?
    
    [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:@"RecievedOverlayList" object:nil]];
    
    if ([jsonResult.hash isEqualToString:[[AppModel sharedAppModel] overlayListHash]] && [AppModel sharedAppModel].overlayIsVisible ==true)
    {
		NSLog(@"AppModel: Hash is same as last overlay list update, continue");
        
        return;
	}
	
	//Save this hash for later comparisions
    [AppModel sharedAppModel].overlayIsVisible = false;
	[AppModel sharedAppModel].overlayListHash = [jsonResult.hash copy];
    
    
    NSArray *overlayListArray = (NSArray *)jsonResult.data;
    
    NSMutableArray *tempOverlayList = [[NSMutableArray alloc] init];
    Overlay *tempOverlay = [[Overlay alloc] init];
    
    NSEnumerator *overlayListEnumerator = [overlayListArray objectEnumerator];
    NSDictionary *overlayDictionary;
    // step through results and create overlays
    int currentOverlayID = -1;
    int overlaysIndex = 0;
    while (overlayDictionary = [overlayListEnumerator nextObject]) {
        // if new overlay in database
        if (currentOverlayID != [self validIntForKey:@"overlay_id" inDictionary:overlayDictionary]) {
            // add previous overlay to overlay list
            [tempOverlayList addObject:tempOverlay];
            
            // create new overlay
            tempOverlay.index = overlaysIndex;
            tempOverlay.overlayId = [self validIntForKey:@"overlay_id" inDictionary:overlayDictionary];;
            tempOverlay.num_tiles = [self validIntForKey:@"num_tiles" inDictionary:overlayDictionary];;
            //tempOverlay.alpha = [[overlayDictionary valueForKey:@"alpha"] floatValue] ;
            tempOverlay.alpha = 1.0;
            [tempOverlay.tileFileName addObject:[overlayDictionary valueForKey:@"file_path"]];
            [tempOverlay.tileMediaID addObject:[overlayDictionary valueForKey:@"media_id"]];
            [tempOverlay.tileX addObject:[overlayDictionary valueForKey:@"x"]];
            [tempOverlay.tileY addObject:[overlayDictionary valueForKey:@"y"]];
            [tempOverlay.tileZ addObject:[overlayDictionary valueForKey:@"zoom"]];
            Media *media = [[AppModel sharedAppModel] mediaForMediaId:[self validIntForKey:@"media_id" inDictionary:overlayDictionary]];
            [tempOverlay.tileImage addObject:media];
            currentOverlayID = tempOverlay.overlayId;
            overlaysIndex += 1;
            //        if([RootViewController sharedRootViewController].loadingVC){
            //          [RootViewController sharedRootViewController].loadingVC.progressLabel.text = NSLocalizedString(@"AppServicesReceivedOverlayListKey", @"");
            //        [RootViewController sharedRootViewController].loadingVC.progressLabel.text = [[RootViewController sharedRootViewController].loadingVC.progressLabel.text stringByAppendingString:[NSString stringWithFormat:@" (%d of %d)", overlaysIndex,[overlayListArray count]]];;
            //}
        }
        else {
            // add tiles to existing overlay
            [tempOverlay.tileFileName addObject:[overlayDictionary valueForKey:@"file_path"]];
            [tempOverlay.tileMediaID addObject:[overlayDictionary valueForKey:@"media_id"]];
            [tempOverlay.tileX addObject:[overlayDictionary valueForKey:@"x"]];
            [tempOverlay.tileY addObject:[overlayDictionary valueForKey:@"y"]];
            [tempOverlay.tileZ addObject:[overlayDictionary valueForKey:@"zoom"]];
            Media *media = [[AppModel sharedAppModel] mediaForMediaId:[self validIntForKey:@"media_id" inDictionary:overlayDictionary]];
            [tempOverlay.tileImage addObject:media];
            currentOverlayID = tempOverlay.overlayId;
        }
        
        //  if([RootViewController sharedRootViewController].loadingVC)
        //      [RootViewController sharedRootViewController].loadingVC.receivedData++;
        
    }
    
    [AppModel sharedAppModel].overlayList = tempOverlayList;
    
    for (int iOverlay=0; iOverlay < [[AppModel sharedAppModel].overlayList count]; iOverlay++) {
        Overlay *currentOverlay = [[AppModel sharedAppModel].overlayList objectAtIndex:iOverlay];
        int iTiles = [currentOverlay.tileX count];
        for (int iTile = 0; iTile < iTiles; iTile++) {
            
            // step through tile list and update media with images
            AsyncMediaImageView *aImageView = [[AsyncMediaImageView alloc] init ];
            [aImageView loadImageFromMedia:[currentOverlay.tileImage objectAtIndex:iTile]];
            
        }
    }
    
    
    NSError *error;
    if (![[AppModel sharedAppModel].mediaCache.context save:&error]) {
        NSLog(@"Whoops, couldn't save: %@", [error localizedDescription]);
    }
    
    NSLog(@"AppModel: parsOverlayListFromJSON Complete, sending notification");
    
    [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:@"NewOverlayListReady" object:nil]];
    
}

- (void)fetchAllPlayerLists{
	[self fetchLocationList];
	[self fetchQuestList];
	[self fetchInventory];
    [self fetchOverlayListAsynchronously:YES];
}

- (void)resetAllPlayerLists {
	NSLog(@"AppModel: resetAllPlayerLists");
    
	//Clear the Hashes
	[AppModel sharedAppModel].questListHash = @"";
	[AppModel sharedAppModel].inventoryHash = @"";
    [AppModel sharedAppModel].playerNoteListHash = @"";
    [AppModel sharedAppModel].gameNoteListHash = @"";
    [AppModel sharedAppModel].overlayListHash = @"";
	//Clear them out
    NSMutableArray *locationListAlloc = [[NSMutableArray alloc] initWithCapacity:0];
	[AppModel sharedAppModel].locationList = locationListAlloc;
    NSMutableArray *nearbyLocationListAlloc = [[NSMutableArray alloc] initWithCapacity:0];
	[AppModel sharedAppModel].nearbyLocationsList = nearbyLocationListAlloc;
    
	NSMutableArray *completedQuestObjects = [[NSMutableArray alloc] init];
	NSMutableArray *activeQuestObjects = [[NSMutableArray alloc] init];
	NSMutableDictionary *tmpQuestList = [[NSMutableDictionary alloc] init];
	[tmpQuestList setObject:activeQuestObjects forKey:@"active"];
	[tmpQuestList setObject:completedQuestObjects forKey:@"completed"];
	[AppModel sharedAppModel].questList = tmpQuestList;
    
    [[AppModel sharedAppModel].overlayList removeAllObjects];
    
	NSMutableDictionary *inventoryAlloc = [[NSMutableDictionary alloc] initWithCapacity:10];
	[AppModel sharedAppModel].inventory = inventoryAlloc;
    NSMutableDictionary *attributesAlloc = [[NSMutableDictionary alloc] initWithCapacity:10];
	[AppModel sharedAppModel].attributes = attributesAlloc;
	
	//Tell the VCs
	[self silenceNextServerUpdate];
    
	[[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:@"NewLocationListReady" object:nil]];
	[[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:@"NewQuestListReady" object:nil]];
	[[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:@"NewInventoryReady" object:nil]];
	[[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:@"ReceivedNearbyLocationList" object:nil]];
}

-(void)fetchTabBarItemsForGame:(int)gameId {
    NSLog(@"Fetching TabBar Items for game: %d",gameId);
    NSArray *arguments = [NSArray arrayWithObjects: [NSString stringWithFormat:@"%d",gameId],
						  nil];
    
    JSONConnection *jsonConnection = [[JSONConnection alloc]initWithServer:[AppModel sharedAppModel].serverURL
                                                            andServiceName:@"games"
                                                             andMethodName:@"getTabBarItemsForGame"
                                                              andArguments:arguments andUserInfo:nil];
	[jsonConnection performAsynchronousRequestWithHandler:@selector(parseGameTabListFromJSON:)];
}

-(void)fetchQRCode:(NSString*)code{
	NSLog(@"Model: Fetch Requested for QRCode Code: %@", code);
	
	//Call server service
	NSArray *arguments = [NSArray arrayWithObjects: [NSString stringWithFormat:@"%d",[AppModel sharedAppModel].currentGame.gameId],
						  [NSString stringWithFormat:@"%@",code],
						  [NSString stringWithFormat:@"%d",[AppModel sharedAppModel].playerId],
						  nil];
	/*
     return [self fetchFromService:@"qrcodes" usingMethod:@"getQRCodeObjectForPlayer"
     withArgs:arguments usingParser:@selector(parseQRCodeObjectFromDictionary:)];
     */
	JSONConnection *jsonConnection = [[JSONConnection alloc]initWithServer:[AppModel sharedAppModel].serverURL
                                                            andServiceName:@"qrcodes"
                                                             andMethodName:@"getQRCodeNearbyObjectForPlayer"
                                                              andArguments:arguments andUserInfo:nil];
	[jsonConnection performAsynchronousRequestWithHandler:@selector(parseQRCodeObjectFromJSON:)];
	
}

-(void)fetchNpcConversations:(int)npcId afterViewingNode:(int)nodeId{
	NSLog(@"Model: Fetch Requested for Npc %d Conversations after Viewing node %d", npcId, nodeId);
	NSArray *arguments = [NSArray arrayWithObjects: [NSString stringWithFormat:@"%d",[AppModel sharedAppModel].currentGame.gameId],
						  [NSString stringWithFormat:@"%d",npcId],
						  [NSString stringWithFormat:@"%d",[AppModel sharedAppModel].playerId],
						  [NSString stringWithFormat:@"%d",nodeId],
						  nil];
	
	JSONConnection *jsonConnection = [[JSONConnection alloc]initWithServer:[AppModel sharedAppModel].serverURL
                                                            andServiceName:@"npcs"
                                                             andMethodName:@"getNpcConversationsForPlayerAfterViewingNode"
                                                              andArguments:arguments andUserInfo:nil];
	[jsonConnection performAsynchronousRequestWithHandler:@selector(parseConversationNodeOptionsFromJSON:)];
}

- (void)fetchGameNpcListAsynchronously:(BOOL)YesForAsyncOrNoForSync {
	NSLog(@"AppModel: Fetching Npc List");
	
	NSArray *arguments = [NSArray arrayWithObjects:[NSString stringWithFormat:@"%d",[AppModel sharedAppModel].currentGame.gameId], nil];
	
	JSONConnection *jsonConnection = [[JSONConnection alloc]initWithServer:[AppModel sharedAppModel].serverURL
                                                            andServiceName:@"npcs"
                                                             andMethodName:@"getNpcs"
                                                              andArguments:arguments andUserInfo:nil];
	if (YesForAsyncOrNoForSync){
		[jsonConnection performAsynchronousRequestWithHandler:@selector(parseGameNpcListFromJSON:)];
	}
	else [self parseGameNpcListFromJSON: [jsonConnection performSynchronousRequest]];
}

- (void)fetchGameNoteListAsynchronously:(BOOL)YesForAsyncOrNoForSync {
	NSLog(@"AppModel: Fetching Game Note List");
    
    /*if (currentlyFetchingGameNoteList) {
     NSLog(@"AppModel: Already fetching location list, skipping");
     return;
     }
     
     currentlyFetchingGameNoteList = YES;*/
	NSArray *arguments = [NSArray arrayWithObjects:[NSString stringWithFormat:@"%d",[AppModel sharedAppModel].currentGame.gameId], [NSString stringWithFormat:@"%d",[AppModel sharedAppModel].playerId],nil];
	
	JSONConnection *jsonConnection = [[JSONConnection alloc]initWithServer:[AppModel sharedAppModel].serverURL
                                                            andServiceName:@"notes"
                                                             andMethodName:@"getNotesForGame"
                                                              andArguments:arguments andUserInfo:nil];
	if (YesForAsyncOrNoForSync){
		[jsonConnection performAsynchronousRequestWithHandler:@selector(parseGameNoteListFromJSON:)];
	}
	else [self parseGameNoteListFromJSON: [jsonConnection performSynchronousRequest]];
}

- (void)fetchPlayerNoteListAsynchronously:(BOOL)YesForAsyncOrNoForSync {
	NSLog(@"AppModel: Fetching Player Note List");
    
	/*if (currentlyFetchingPlayerNoteList) {
     NSLog(@"AppModel: Already fetching location list, skipping");
     return;
     }
     
     currentlyFetchingPlayerNoteList = YES;*/
    
	NSArray *arguments = [NSArray arrayWithObjects:[NSString stringWithFormat:@"%d",[AppModel sharedAppModel].playerId],[NSString stringWithFormat:@"%d",[AppModel sharedAppModel].currentGame.gameId], nil];
	
	JSONConnection *jsonConnection = [[JSONConnection alloc]initWithServer:[AppModel sharedAppModel].serverURL
                                                            andServiceName:@"notes"
                                                             andMethodName:@"getNotesForPlayer"
                                                              andArguments:arguments andUserInfo:nil];
	if (YesForAsyncOrNoForSync){
		[jsonConnection performAsynchronousRequestWithHandler:@selector(parsePlayerNoteListFromJSON:)];
	}
	else [self parsePlayerNoteListFromJSON: [jsonConnection performSynchronousRequest]];
}

- (void)fetchGameWebpageListAsynchronously:(BOOL)YesForAsyncOrNoForSync {
	NSLog(@"AppModel: Fetching Webpage List");
	
	NSArray *arguments = [NSArray arrayWithObjects:[NSString stringWithFormat:@"%d",[AppModel sharedAppModel].currentGame.gameId], nil];
	
	JSONConnection *jsonConnection = [[JSONConnection alloc]initWithServer:[AppModel sharedAppModel].serverURL
                                                            andServiceName:@"webpages"
                                                             andMethodName:@"getWebPages"
                                                              andArguments:arguments andUserInfo:nil];
	if (YesForAsyncOrNoForSync){
		[jsonConnection performAsynchronousRequestWithHandler:@selector(parseGameWebPageListFromJSON:)];
	}
	else [self parseGameWebPageListFromJSON: [jsonConnection performSynchronousRequest]];
    
	
}

- (void) fetchIndividualMediaById:(int)mediaId
{
    NSLog(@"AppModel: Fetching Individual media: %d",mediaId);
    
    NSArray *arguments = [NSArray arrayWithObjects:
                          (([AppModel sharedAppModel].currentGame.gameId != 0) ? [NSString stringWithFormat:@"%d",[AppModel sharedAppModel].currentGame.gameId] : @"player"),
                          [NSString stringWithFormat:@"%d",mediaId],
                          nil];
    
    JSONConnection *jsonConnection = [[JSONConnection alloc]initWithServer:[AppModel sharedAppModel].serverURL
                                                            andServiceName:@"media"
                                                             andMethodName:@"getMediaObject"
                                                              andArguments:arguments andUserInfo:nil];
    
    [jsonConnection performAsynchronousRequestWithHandler:@selector(parseSingleMediaFromJSON:)];
}

- (void)fetchGameMediaListAsynchronously:(BOOL)YesForAsyncOrNoForSync {
	NSLog(@"AppModel: Fetching Media List");
	
	NSArray *arguments = [NSArray arrayWithObjects:[NSString stringWithFormat:@"%d",[AppModel sharedAppModel].currentGame.gameId], nil];
    
	JSONConnection *jsonConnection = [[JSONConnection alloc]initWithServer:[AppModel sharedAppModel].serverURL
                                                            andServiceName:@"media"
                                                             andMethodName:@"getMedia"
                                                              andArguments:arguments andUserInfo:nil];
	
	if (YesForAsyncOrNoForSync){
		[jsonConnection performAsynchronousRequestWithHandler:@selector(parseGameMediaListFromJSON:)];
	}
	else [self parseGameMediaListFromJSON: [jsonConnection performSynchronousRequest]];
}

- (void)fetchGamePanoramicListAsynchronously:(BOOL)YesForAsyncOrNoForSync {
	NSLog(@"AppModel: Fetching Panoramic List");
	
	NSArray *arguments = [NSArray arrayWithObjects:[NSString stringWithFormat:@"%d",[AppModel sharedAppModel].currentGame.gameId], nil];
    
	JSONConnection *jsonConnection = [[JSONConnection alloc]initWithServer:[AppModel sharedAppModel].serverURL
                                                            andServiceName:@"augbubbles"
                                                             andMethodName:@"getAugBubbles"
                                                              andArguments:arguments andUserInfo:nil];
	
	if (YesForAsyncOrNoForSync){
		[jsonConnection performAsynchronousRequestWithHandler:@selector(parseGamePanoramicListFromJSON:)];
	}
	else [self parseGamePanoramicListFromJSON: [jsonConnection performSynchronousRequest]];
}


- (void)fetchGameItemListAsynchronously:(BOOL)YesForAsyncOrNoForSync {
	NSLog(@"AppModel: Fetching Item List");
	
	NSArray *arguments = [NSArray arrayWithObjects:[NSString stringWithFormat:@"%d",[AppModel sharedAppModel].currentGame.gameId], nil];
	
	JSONConnection *jsonConnection = [[JSONConnection alloc]initWithServer:[AppModel sharedAppModel].serverURL
                                                            andServiceName:@"items"
                                                             andMethodName:@"getItems"
                                                              andArguments:arguments andUserInfo:nil];
	if (YesForAsyncOrNoForSync) {
		[jsonConnection performAsynchronousRequestWithHandler:@selector(parseGameItemListFromJSON:)];
	}
	else [self parseGameItemListFromJSON: [jsonConnection performSynchronousRequest]];
	
}



- (void)fetchGameNodeListAsynchronously:(BOOL)YesForAsyncOrNoForSync  {
	NSLog(@"AppModel: Fetching Node List");
	
	NSArray *arguments = [NSArray arrayWithObjects:[NSString stringWithFormat:@"%d",[AppModel sharedAppModel].currentGame.gameId], nil];
	
	JSONConnection *jsonConnection = [[JSONConnection alloc]initWithServer:[AppModel sharedAppModel].serverURL
                                                            andServiceName:@"nodes"
                                                             andMethodName:@"getNodes"
                                                              andArguments:arguments andUserInfo:nil];
	if (YesForAsyncOrNoForSync) {
		[jsonConnection performAsynchronousRequestWithHandler:@selector(parseGameNodeListFromJSON:)];
	}
    
	else {
        JSONResult *result = [jsonConnection performSynchronousRequest];
        [self parseGameNodeListFromJSON: result];
    }
    
	
}
- (void)fetchGameTags{
	NSLog(@"AppModel: Fetching TAG List");
	
	NSArray *arguments = [NSArray arrayWithObjects:[NSString stringWithFormat:@"%d",[AppModel sharedAppModel].currentGame.gameId], nil];
	
	JSONConnection *jsonConnection = [[JSONConnection alloc]initWithServer:[AppModel sharedAppModel].serverURL
                                                            andServiceName:@"notes"
                                                             andMethodName:@"getAllTagsInGame"
                                                              andArguments:arguments andUserInfo:nil];
    [jsonConnection performAsynchronousRequestWithHandler:@selector(parseGameTagsListFromJSON:)];
}

-(void)parseGameTagsListFromJSON:(JSONResult *)jsonResult{
    NSLog(@"AppModel: parseGameTagListFromJSON Beginning");
    
    NSArray *gameTagsArray = (NSArray *)jsonResult.data;
	
	NSMutableArray *tempTagsList = [[NSMutableArray alloc] initWithCapacity:10];
	
	NSEnumerator *gameTagEnumerator = [gameTagsArray objectEnumerator];
	NSDictionary *tagDictionary;
	while ((tagDictionary = [gameTagEnumerator nextObject])) {
        Tag *t = [[Tag alloc]init];
        t.tagName = [tagDictionary objectForKey:@"tag"];
        t.playerCreated = [[tagDictionary objectForKey:@"player_created"]boolValue];
        t.tagId = [self validIntForKey:@"tag_id" inDictionary:tagDictionary];
		[tempTagsList addObject:t];
	}
    
	[AppModel sharedAppModel].gameTagList = tempTagsList;
    
    [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:@"NewNoteListReady" object:nil]];
}

-(void)addTagToNote:(int)noteId tagName:(NSString *)tag{
    NSLog(@"AppModel: Adding Tag to note");
	
	NSArray *arguments = [NSArray arrayWithObjects:[NSString stringWithFormat:@"%d",noteId],[NSString stringWithFormat:@"%d",[AppModel sharedAppModel].currentGame.gameId],tag, nil];
	
	JSONConnection *jsonConnection = [[JSONConnection alloc]initWithServer:[AppModel sharedAppModel].serverURL
                                                            andServiceName:@"notes"
                                                             andMethodName:@"addTagToNote"
                                                              andArguments:arguments andUserInfo:nil];
    [jsonConnection performAsynchronousRequestWithHandler:nil];
    
}

-(void)deleteTagFromNote:(int)noteId tagId:(int)tagId{
    NSLog(@"AppModel: Deleting tag from note");
	
	NSArray *arguments = [NSArray arrayWithObjects:[NSString stringWithFormat:@"%d",noteId],[NSString stringWithFormat:@"%d",tagId], nil];
	
	JSONConnection *jsonConnection = [[JSONConnection alloc]initWithServer:[AppModel sharedAppModel].serverURL
                                                            andServiceName:@"notes"
                                                             andMethodName:@"deleteTagFromNote"
                                                              andArguments:arguments andUserInfo:nil];
    [jsonConnection performAsynchronousRequestWithHandler:nil];
    
}

- (void)fetchLocationList {
	NSLog(@"AppModel: Fetching Locations from Server");
	
	if (![AppModel sharedAppModel].loggedIn) {
		NSLog(@"AppModel: Player Not logged in yet, skip the location fetch");
		return;
	}
    
    if (currentlyFetchingLocationList || currentlyInteractingWithObject) {
        NSLog(@"AppModel: Already fetching location list, skipping");
        return;
    }
    
    currentlyFetchingLocationList = YES;
    
	NSArray *arguments = [NSArray arrayWithObjects:
                          [NSString stringWithFormat:@"%d", [AppModel sharedAppModel].currentGame.gameId],
						  [NSString stringWithFormat:@"%d",[AppModel sharedAppModel].playerId],
						  nil];
	
	JSONConnection *jsonConnection = [[JSONConnection alloc]initWithServer:[AppModel sharedAppModel].serverURL
                                                            andServiceName:@"locations"
                                                             andMethodName:@"getLocationsForPlayer"
                                                              andArguments:arguments andUserInfo:nil];
	[jsonConnection performAsynchronousRequestWithHandler:@selector(parseLocationListFromJSON:)];
	
}

- (void)fetchInventory {
	NSLog(@"Model: fetchInventory");
    
    if (currentlyFetchingInventory) {
        NSLog(@"AppModel: Already fetching inventory, skipping");
        return;
    }
    
    currentlyFetchingInventory = YES;
	
	NSArray *arguments = [NSArray arrayWithObjects:
                          [NSString stringWithFormat:@"%d",[AppModel sharedAppModel].currentGame.gameId],
						  [NSString stringWithFormat:@"%d",[AppModel sharedAppModel].playerId],
						  nil];
	
	JSONConnection *jsonConnection = [[JSONConnection alloc]initWithServer:[AppModel sharedAppModel].serverURL
                                                            andServiceName:@"items"
                                                             andMethodName:@"getItemsForPlayer"
                                                              andArguments:arguments andUserInfo:nil];
	[jsonConnection performAsynchronousRequestWithHandler:@selector(parseInventoryFromJSON:)];
	
}

-(void)fetchGameListBySearch:(NSString *)searchText onPage:(int)page {
    NSLog(@"Searching with Text: %@",searchText);
    
    if (currentlyFetchingSearchGamesList) {
        NSLog(@"AppModel: Already fetching Games list, skipping");
        return;
    }
    
    currentlyFetchingSearchGamesList = YES;
    
	//Call server service
	NSArray *arguments = [NSArray arrayWithObjects:
                          [NSString stringWithFormat:@"%d",[AppModel sharedAppModel].playerId],
                          [NSString stringWithFormat:@"%f",[AppModel sharedAppModel].playerLocation.coordinate.latitude],
						  [NSString stringWithFormat:@"%f",[AppModel sharedAppModel].playerLocation.coordinate.longitude],
						  searchText,
                          [NSString stringWithFormat:@"%d",[AppModel sharedAppModel].showGamesInDevelopment],
                          [NSString stringWithFormat:@"%d", page],
						  nil];
	
	JSONConnection *jsonConnection = [[JSONConnection alloc]initWithServer:[AppModel sharedAppModel].serverURL
                                                            andServiceName:@"games"
                                                             andMethodName:@"getGamesContainingText"
                                                              andArguments:arguments andUserInfo:nil];
	[jsonConnection performAsynchronousRequestWithHandler:@selector(parseSearchGameListFromJSON:)];
}

//Currently Deprecated: Originally used to fetch locational data of games for use with the Map-based game selection view
-(void)fetchMiniGamesListLocations{
    NSLog(@"AppModel: Fetch Requested for Game List.");
    
    /*   if (currentlyFetchingGamesList) {
     NSLog(@"AppModel: Already fetching Games list, skipping");
     return;
     }
     
     currentlyFetchingGamesList = YES; */
    
	//Call server service
	NSArray *arguments = [NSArray arrayWithObjects:
                          [NSString stringWithFormat:@"%f",[AppModel sharedAppModel].playerLocation.coordinate.latitude],
						  [NSString stringWithFormat:@"%f",[AppModel sharedAppModel].playerLocation.coordinate.longitude],
                          [NSString stringWithFormat:@"%d",[AppModel sharedAppModel].showGamesInDevelopment],
						  nil];
	
	JSONConnection *jsonConnection = [[JSONConnection alloc]initWithServer:[AppModel sharedAppModel].serverURL
                                                            andServiceName:@"games"
                                                             andMethodName:@"getGamesWithLocations"
                                                              andArguments:arguments andUserInfo:nil];
	
	[jsonConnection performAsynchronousRequestWithHandler:@selector(parseGameListFromJSON:)];
}






-(void)fetchQuestList {
	NSLog(@"Model: Fetch Requested for Quests");
    
    if (currentlyFetchingQuestList) {
        NSLog(@"AppModel: Already fetching quest list, skipping");
        return;
    }
    
    currentlyFetchingQuestList = YES;
	
	//Call server service
	NSArray *arguments = [NSArray arrayWithObjects: [NSString stringWithFormat:@"%d",[AppModel sharedAppModel].currentGame.gameId],
						  [NSString stringWithFormat:@"%d",[AppModel sharedAppModel].playerId],
						  nil];
	
	JSONConnection *jsonConnection = [[JSONConnection alloc]initWithServer:[AppModel sharedAppModel].serverURL
                                                            andServiceName:@"quests"
                                                             andMethodName:@"getQuestsForPlayer"
                                                              andArguments:arguments andUserInfo:nil];
	
	[jsonConnection performAsynchronousRequestWithHandler:@selector(parseQuestListFromJSON:)];
	
}

- (void)fetchGameListWithDistanceFilter: (int)distanceInMeters locational:(BOOL)locationalOrNonLocational {
	NSLog(@"AppModel: Fetch Requested for Game List.");
    
    if (currentlyFetchingNearbyGamesList) {
        NSLog(@"AppModel: Already fetching Games list, skipping");
        return;
    }
    
    currentlyFetchingNearbyGamesList = YES;
    
	//Call server service
	NSArray *arguments = [NSArray arrayWithObjects:
                          [NSString stringWithFormat:@"%d",[AppModel sharedAppModel].playerId],
						  [NSString stringWithFormat:@"%f",[AppModel sharedAppModel].playerLocation.coordinate.latitude],
						  [NSString stringWithFormat:@"%f",[AppModel sharedAppModel].playerLocation.coordinate.longitude],
                          [NSString stringWithFormat:@"%d",distanceInMeters],
                          [NSString stringWithFormat:@"%d",locationalOrNonLocational],
                          [NSString stringWithFormat:@"%d",[AppModel sharedAppModel].showGamesInDevelopment],
						  nil];
	
	JSONConnection *jsonConnection = [[JSONConnection alloc]initWithServer:[AppModel sharedAppModel].serverURL
                                                            andServiceName:@"games"
                                                             andMethodName:@"getGamesForPlayerAtLocation"
                                                              andArguments:arguments andUserInfo:nil];
	
	[jsonConnection performAsynchronousRequestWithHandler:@selector(parseNearbyGameListFromJSON:)];
}

//Not Currently Deprecated: Currently used to fetch a game reached by url
- (void)fetchOneGame:(int)gameId {
    NSLog(@"AppModel: Fetch Requested for a single game (as Game List).");
    //[self fetchTabBarItemsForGame:gameId];//Make sure to get the tabs as well
    
    if (currentlyFetchingOneGame) {
        NSLog(@"AppModel: Already fetching Games list, skipping");
        return;
    }
    
    currentlyFetchingOneGame = YES;
    
	//Call server service
	NSArray *arguments = [NSArray arrayWithObjects:
                          [NSString stringWithFormat:@"%d",gameId],
                          [NSString stringWithFormat:@"%d",[AppModel sharedAppModel].playerId],
                          [NSString stringWithFormat:@"%d",1],
                          [NSString stringWithFormat:@"%d",999999999],
						  [NSString stringWithFormat:@"%f",[AppModel sharedAppModel].playerLocation.coordinate.latitude],
						  [NSString stringWithFormat:@"%f",[AppModel sharedAppModel].playerLocation.coordinate.longitude],
                          [NSString stringWithFormat:@"%d",[AppModel sharedAppModel].showGamesInDevelopment],
						  nil];
	
	JSONConnection *jsonConnection = [[JSONConnection alloc]initWithServer:[AppModel sharedAppModel].serverURL
                                                            andServiceName:@"games"
                                                             andMethodName:@"getOneGame"
                                                              andArguments:arguments andUserInfo:nil];
	
	[jsonConnection performAsynchronousRequestWithHandler:@selector(parseOneGameFromJSON:)];
}

- (void)fetchGame:(int)gameId {
    NSLog(@"AppModel: Fetch Requested for a single game (as Game List).");
    //[self fetchTabBarItemsForGame:gameId];//Make sure to get the tabs as well
    
    if (currentlyFetchingOneGame) {
        NSLog(@"AppModel: Already fetching Games list, skipping");
        return;
    }
    
    currentlyFetchingOneGame = YES;
    
	//Call server service
	NSArray *arguments = [NSArray arrayWithObjects:
                          [NSString stringWithFormat:@"%d",gameId],
						  nil];
	
	JSONConnection *jsonConnection = [[JSONConnection alloc]initWithServer:[AppModel sharedAppModel].serverURL
                                                            andServiceName:@"games"
                                                             andMethodName:@"getGame"
                                                              andArguments:arguments andUserInfo:nil];
	
	[jsonConnection performAsynchronousRequestWithHandler:@selector(parseGameFromJSON:)];
}


- (void)fetchRecentGameListForPlayer  {
	NSLog(@"AppModel: Fetch Requested for Game List.");
    
    if (currentlyFetchingRecentGamesList) {
        NSLog(@"AppModel: Already fetching Games list, skipping");
        return;
    }
    
    currentlyFetchingRecentGamesList = YES;
    
	//Call server service
	NSArray *arguments = [NSArray arrayWithObjects:
                          [NSString stringWithFormat:@"%d",[AppModel sharedAppModel].playerId],
                          [NSString stringWithFormat:@"%f",[AppModel sharedAppModel].playerLocation.coordinate.latitude],
						  [NSString stringWithFormat:@"%f",[AppModel sharedAppModel].playerLocation.coordinate.longitude],
                          [NSString stringWithFormat:@"%d",[AppModel sharedAppModel].showGamesInDevelopment],
						  nil];
	
	JSONConnection *jsonConnection = [[JSONConnection alloc]initWithServer:[AppModel sharedAppModel].serverURL
                                                            andServiceName:@"games"
                                                             andMethodName:@"getRecentGamesForPlayer"
                                                              andArguments:arguments andUserInfo:nil];
	
	[jsonConnection performAsynchronousRequestWithHandler:@selector(parseRecentGameListFromJSON:)];
}

- (void)fetchPopularGameListForTime: (int)time {
	NSLog(@"AppModel: Fetch Requested for Game List.");
    
    if (currentlyFetchingPopularGamesList) {
        NSLog(@"AppModel: Already fetching Games list, skipping");
        return;
    }
    
    currentlyFetchingPopularGamesList = YES;
    
	//Call server service
	NSArray *arguments = [NSArray arrayWithObjects:
                          [NSString stringWithFormat:@"%d",[AppModel sharedAppModel].playerId],
                          [NSString stringWithFormat:@"%d",time],
                          [NSString stringWithFormat:@"%d",[AppModel sharedAppModel].showGamesInDevelopment],
						  nil];
	
	JSONConnection *jsonConnection = [[JSONConnection alloc]initWithServer:[AppModel sharedAppModel].serverURL
                                                            andServiceName:@"games"
                                                             andMethodName:@"getPopularGames"
                                                              andArguments:arguments andUserInfo:nil];
	
	[jsonConnection performAsynchronousRequestWithHandler:@selector(parsePopularGameListFromJSON:)];
}

#pragma mark Parsers
- (NSInteger) validIntForKey:(NSString *const)aKey inDictionary:(NSDictionary *const)aDictionary {
	id theObject = [aDictionary valueForKey:aKey];
	return [theObject respondsToSelector:@selector(intValue)] ? [theObject intValue] : kEmptyValue;
}

- (id) validObjectForKey:(NSString *const)aKey inDictionary:(NSDictionary *const)aDictionary {
	id theObject = [aDictionary valueForKey:aKey];
	return theObject == [NSNull null] ? nil : theObject;
}

-(Item *)parseItemFromDictionary: (NSDictionary *)itemDictionary{
	Item *item = [[Item alloc] init];
	item.itemId = [self validIntForKey:@"item_id" inDictionary:itemDictionary];
	item.name = [itemDictionary valueForKey:@"name"];
	item.description = [itemDictionary valueForKey:@"description"];
    item.mediaId = [self validIntForKey:@"item_id" inDictionary:itemDictionary];
	item.iconMediaId = [self validIntForKey:@"icon_media_id" inDictionary:itemDictionary];
	item.dropable = [[itemDictionary valueForKey:@"dropable"] boolValue];
	item.destroyable = [[itemDictionary valueForKey:@"destroyable"] boolValue];
    item.maxQty = [self validIntForKey:@"max_qty_in_inventory" inDictionary:itemDictionary];
    item.isAttribute = [[itemDictionary valueForKey:@"is_attribute"] boolValue];
    item.isTradeable = [[itemDictionary valueForKey:@"tradeable"] boolValue];
    item.weight = [self validIntForKey:@"weight" inDictionary:itemDictionary];
    item.url = [itemDictionary valueForKey:@"url"];
	item.type = [itemDictionary valueForKey:@"type"];
    item.creatorId = [self validIntForKey:@"creator_player_id" inDictionary:itemDictionary];
	NSLog(@"\tadded item %@", item.name);
	
	return item;
}
-(Node *)parseNodeFromDictionary: (NSDictionary *)nodeDictionary{
	//Build the node
	NSLog(@"%@", nodeDictionary);
	Node *node = [[Node alloc] init];
	node.nodeId = [self validIntForKey:@"node_id" inDictionary:nodeDictionary];
	node.name = [nodeDictionary valueForKey:@"title"];
	node.text = [nodeDictionary valueForKey:@"text"];
	NSLog(@"%@", [nodeDictionary valueForKey:@"media_id"]);
	node.mediaId = [self validIntForKey:@"media_id" inDictionary:nodeDictionary];
	node.iconMediaId = [self validIntForKey:@"icon_media_id" inDictionary:nodeDictionary];
	node.answerString = [self validObjectForKey:@"require_answer_string" inDictionary:nodeDictionary];
	node.nodeIfCorrect = [self validIntForKey:@"require_answer_correct_node_id" inDictionary:nodeDictionary];
	node.nodeIfIncorrect = [self validIntForKey:@"require_answer_incorrect_node_id" inDictionary:nodeDictionary];
	
	//Add options here
	int optionNodeId;
	NSString *text;
	NodeOption *option;
	
	if ([nodeDictionary valueForKey:@"opt1_node_id"] != [NSNull null] && [self validIntForKey:@"opt1_node_id" inDictionary:nodeDictionary] > 0) {
		optionNodeId= [self validIntForKey:@"opt1_node_id" inDictionary:nodeDictionary];
		text = [nodeDictionary valueForKey:@"opt1_text"];
		option = [[NodeOption alloc] initWithText:text andNodeId: optionNodeId andHasViewed:NO];
		[node addOption:option];
	}
	if ([nodeDictionary valueForKey:@"opt2_node_id"] != [NSNull null] && [self validIntForKey:@"opt2_node_id" inDictionary:nodeDictionary] > 0) {
		optionNodeId = [self validIntForKey:@"opt2_node_id" inDictionary:nodeDictionary];
		text = [nodeDictionary valueForKey:@"opt2_text"];
		option = [[NodeOption alloc] initWithText:text andNodeId: optionNodeId andHasViewed:NO];
		[node addOption:option];
	}
	if ([nodeDictionary valueForKey:@"opt3_node_id"] != [NSNull null] && [self validIntForKey:@"opt3_node_id" inDictionary:nodeDictionary] > 0) {
		optionNodeId = [self validIntForKey:@"opt3_node_id" inDictionary:nodeDictionary];
		text = [nodeDictionary valueForKey:@"opt3_text"];
		option = [[NodeOption alloc] initWithText:text andNodeId: optionNodeId andHasViewed:NO];
		[node addOption:option];
	}
	
	
	return node;
}
-(Note *)parseNoteFromDictionary: (NSDictionary *)noteDictionary {
	Note *aNote = [[Note alloc] init];
	aNote.noteId = [self validIntForKey:@"note_id" inDictionary:noteDictionary];
	aNote.title = [noteDictionary valueForKey:@"title"];
	aNote.text = [noteDictionary valueForKey:@"text"];
    aNote.averageRating = [[noteDictionary valueForKey:@"ave_rating"] floatValue];
    aNote.parentNoteId = [self validIntForKey:@"parent_note_id" inDictionary:noteDictionary];
    aNote.parentRating = [self validIntForKey:@"parent_rating" inDictionary:noteDictionary];
    aNote.numRatings = [self validIntForKey:@"likes" inDictionary:noteDictionary];
    aNote.creatorId = [self validIntForKey:@"owner_id" inDictionary:noteDictionary];
    aNote.showOnMap = [[noteDictionary valueForKey:@"public_to_map"]boolValue];
    aNote.showOnList = [[noteDictionary valueForKey:@"public_to_notebook"]boolValue];
    aNote.userLiked = [[noteDictionary valueForKey:@"player_liked"]boolValue];
    aNote.username = [noteDictionary valueForKey:@"username"];
    aNote.dropped = [[noteDictionary valueForKey:@"dropped"]boolValue];
    aNote.latitude = [[noteDictionary valueForKey:@"lat"]doubleValue];
    aNote.longitude = [[noteDictionary valueForKey:@"lon"]doubleValue];
    
    NSArray *contents = [noteDictionary valueForKey:@"contents"];
    for (NSDictionary *content in contents) {
        
        NoteContent *c = [[NoteContent alloc] init];
        c.text = [content objectForKey:@"text"];
        c.title = [content objectForKey:@"title"];
        c.contentId = [self validIntForKey:@"content_id" inDictionary:content];
        c.mediaId = [self validIntForKey:@"media_id" inDictionary:content];
        c.noteId = [self validIntForKey:@"note_id" inDictionary:content];
        c.sortIndex =[self validIntForKey:@"sort_index" inDictionary:content];
        c.type = [content objectForKey:@"type"];
        int returnCode = [self validIntForKey:@"returnCode" inDictionary:[content objectForKey:@"media"]];
        NSDictionary *m = [[content objectForKey:@"media"] objectForKey:@"data"];
        if(returnCode == 0 && m){
            Media *media = [[AppModel sharedAppModel].mediaCache mediaForMediaId:c.mediaId];
            NSString *fileName = [m objectForKey:@"file_path"];
            if(fileName == nil) fileName = [m valueForKey:@"file_name"];
            NSString *urlPath = [m objectForKey:@"url_path"];
            NSString *fullUrl = [NSString stringWithFormat:@"%@%@", urlPath, fileName];
            media.url = fullUrl;
            media.type = [m objectForKey:@"type"];
        }
        
        [aNote.contents addObject:c];
    }
    
    NSArray *tags = [noteDictionary valueForKey:@"tags"];
    for (NSDictionary *tagOb in tags) {
        
        Tag *tag = [[Tag alloc] init];
        tag.tagName = [tagOb objectForKey:@"tag"];
        tag.playerCreated = [[tagOb objectForKey:@"player_created"]boolValue];
        tag.tagId = [self validIntForKey:@"tag_id" inDictionary:tagOb];
        [aNote.tags addObject:tag];
    }
    NSArray *comments = [noteDictionary valueForKey:@"comments"];
    NSEnumerator *enumerator = [((NSArray *)comments) objectEnumerator];
	NSDictionary *dict;
    while ((dict = [enumerator nextObject])) {
        //This is returning an object with playerId,tex, and rating. Right now, we just want the text
        //TODO: Create a Comments object
        Note *c = [self parseNoteFromDictionary:dict];
        [aNote.comments addObject:c];
    }
    
	NSSortDescriptor *sortDescriptor;
    sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"noteId"
                                                 ascending:NO];
    NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
    
    aNote.comments = [[aNote.comments sortedArrayUsingDescriptors:sortDescriptors] mutableCopy];
	return aNote;
}

-(Npc *)parseNpcFromDictionary: (NSDictionary *)npcDictionary {
	Npc *npc = [[Npc alloc] init];
	npc.npcId = [self validIntForKey:@"npc_id" inDictionary:npcDictionary];
	npc.name = [npcDictionary valueForKey:@"name"];
	npc.greeting = [npcDictionary valueForKey:@"text"];
	
	npc.closing = [npcDictionary valueForKey:@"closing"];
	if ((NSNull *)npc.closing == [NSNull null]) npc.closing = @"";
    
	npc.description = [npcDictionary valueForKey:@"description"];
	npc.mediaId = [self validIntForKey:@"media_id" inDictionary:npcDictionary];
	npc.iconMediaId = [self validIntForKey:@"icon_media_id" inDictionary:npcDictionary];
    
	return npc;
}

- (Tab *)parseTabFromDictionary:(NSDictionary *)tabDictionary{
    Tab *tab = [[Tab alloc] init];
    tab.tabName = [tabDictionary valueForKey:@"tab"];
    tab.tabIndex = [self validIntForKey:@"tab_index" inDictionary:tabDictionary];
    tab.tabDetail1 = [tabDictionary valueForKey:@"tab_detail_1"] ? [self validIntForKey:@"tab_detail_1" inDictionary:tabDictionary] : 0;
    return tab;
}

-(WebPage *)parseWebPageFromDictionary: (NSDictionary *)webPageDictionary {
	WebPage *webPage = [[WebPage alloc] init];
	webPage.webPageId = [self validIntForKey:@"web_page_id" inDictionary:webPageDictionary];
	webPage.name = [webPageDictionary valueForKey:@"name"];
	webPage.url = [webPageDictionary valueForKey:@"url"];
	webPage.iconMediaId = [self validIntForKey:@"icon_media_id" inDictionary:webPageDictionary];
    
	return webPage;
}

-(Panoramic *)parsePanoramicFromDictionary: (NSDictionary *)panoramicDictionary {
	Panoramic *pan = [[Panoramic alloc] init];
    pan.panoramicId  = [self validIntForKey:@"aug_bubble_id" inDictionary:panoramicDictionary];
    pan.name = [panoramicDictionary valueForKey:@"name"];
	pan.description = [panoramicDictionary valueForKey:@"description"];
    pan.alignMediaId = [self validIntForKey:@"alignment_media_id" inDictionary:panoramicDictionary];
    pan.iconMediaId = [self validIntForKey:@"icon_media_id" inDictionary:panoramicDictionary];
    
    
    
    /*NSMutableArray *activeQuestObjects = [[NSMutableArray alloc] init];
     NSArray *activeQuests = [questListDictionary objectForKey:@"active"];
     NSEnumerator *activeQuestsEnumerator = [activeQuests objectEnumerator];
     NSDictionary *activeQuest;
     while ((activeQuest = [activeQuestsEnumerator nextObject])) {
     //We have a quest, parse it into a quest abject and add it to the activeQuestObjects array
     Quest *quest = [[Quest alloc] init];
     quest.questId = [[activeQuest objectForKey:@"quest_id"] intValue];
     quest.name = [activeQuest objectForKey:@"name"];
     quest.description = [activeQuest objectForKey:@"description"];
     quest.iconMediaId = [[activeQuest objectForKey:@"icon_media_id"] intValue];
     [activeQuestObjects addObject:quest];
     [quest release];
     }
     */
    
    
    //parse out the active quests into quest objects
	NSMutableArray *media = [[NSMutableArray alloc] init];
	NSArray *incomingPanMediaArray = [panoramicDictionary objectForKey:@"media"];
	NSEnumerator *incomingPanMediaEnumerator = [incomingPanMediaArray objectEnumerator];
    NSDictionary* currentPanMediaDictionary;
	while (currentPanMediaDictionary = (NSDictionary*)[incomingPanMediaEnumerator nextObject]) {
        PanoramicMedia *pm = [[PanoramicMedia alloc]init];
        pm.text = [currentPanMediaDictionary objectForKey:@"text"];
        if ([currentPanMediaDictionary objectForKey:@"media_id"] != [NSNull null] && [self validIntForKey:@"media_id" inDictionary:currentPanMediaDictionary] > 0)
            pm.mediaId = [self validIntForKey:@"media_id" inDictionary:currentPanMediaDictionary];
		[media addObject:pm];
	}
    
    pan.media = [NSArray arrayWithArray: media];
    
	return pan;
}

-(void)parseGameNoteListFromJSON: (JSONResult *)jsonResult{
    NSLog(@"Parsing Game Note List");
    
    if ([jsonResult.hash isEqualToString:[AppModel sharedAppModel].gameNoteListHash]) {
		NSLog(@"AppModel: Hash is same as last game note list update, continue");
		//return;
	}
	
	//Save this hash for later comparisions
	[AppModel sharedAppModel].gameNoteListHash = jsonResult.hash;
    
	NSArray *noteListArray = (NSArray *)jsonResult.data;
    NSMutableDictionary *tempNoteList = [[NSMutableDictionary alloc]init];
    
	NSEnumerator *enumerator = [((NSArray *)noteListArray) objectEnumerator];
	NSDictionary *dict;
	while ((dict = [enumerator nextObject])) {
        Note *tmpNote = [self parseNoteFromDictionary:dict];
        [tempNoteList setObject:tmpNote forKey:[NSNumber numberWithInt:tmpNote.noteId]];
	}
    
	[AppModel sharedAppModel].gameNoteList = tempNoteList;
    [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:@"NewNoteListReady" object:nil]];
    [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:@"GameNoteListRefreshed" object:nil]];
    [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:@"RecievedNoteList" object:nil]];
    //^ This is ridiculous. Each notification is a paraphrasing of the last. <3 Phil
    NSLog(@"DONE Parsing Game Note List");
    
    self.currentlyFetchingGameNoteList = NO;
}

-(void)parsePlayerNoteListFromJSON: (JSONResult *)jsonResult{
    NSLog(@"Parsing Player Note List");
    if ([jsonResult.hash isEqualToString:[AppModel sharedAppModel].playerNoteListHash]) {
		NSLog(@"AppModel: Hash is same as last player note list update, continue");
		//return;
	}
	
	//Save this hash for later comparisions
	[AppModel sharedAppModel].playerNoteListHash = [jsonResult.hash copy];
    
	NSArray *noteListArray = (NSArray *)jsonResult.data;
    [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:@"RecievedNoteList" object:nil]];
	NSMutableDictionary *tempNoteList = [[NSMutableDictionary alloc] init];
	NSEnumerator *enumerator = [((NSArray *)noteListArray) objectEnumerator];
	NSDictionary *dict;
	while ((dict = [enumerator nextObject])) {
		Note *tmpNote = [self parseNoteFromDictionary:dict];
		
		[tempNoteList setObject:tmpNote forKey:[NSNumber numberWithInt:tmpNote.noteId]];
	}
    
    
	[AppModel sharedAppModel].playerNoteList = tempNoteList;
    [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:@"NewNoteListReady" object:nil]];
    NSLog(@"DONE Parsing Player Note List");
    self.currentlyFetchingPlayerNoteList = NO;
    
}
-(void)parseConversationNodeOptionsFromJSON: (JSONResult *)jsonResult {
	
    [self fetchInventory];
    [self fetchQuestList];
    
    NSArray *conversationOptionsArray = (NSArray *)jsonResult.data;
	
	NSMutableArray *conversationNodeOptions = [[NSMutableArray alloc] initWithCapacity:3];
	
	NSEnumerator *conversationOptionsEnumerator = [conversationOptionsArray objectEnumerator];
	NSDictionary *conversationDictionary;
	
	while ((conversationDictionary = [conversationOptionsEnumerator nextObject])) {
		//Make the Node Option and add it to the Npc
		int optionNodeId = [self validIntForKey:@"node_id" inDictionary:conversationDictionary];
		NSString *text = [conversationDictionary valueForKey:@"text"];
        BOOL hasViewed = [[conversationDictionary valueForKey:@"has_viewed"] boolValue];
		NodeOption *option = [[NodeOption alloc] initWithText:text andNodeId: optionNodeId andHasViewed:hasViewed];
		[conversationNodeOptions addObject:option];
	}
	
	//return conversationNodeOptions;
	[[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:@"ConversationNodeOptionsReady" object:conversationNodeOptions]];
}

-(void)parseLoginResponseFromJSON: (JSONResult *)jsonResult{
	NSLog(@"AppModel: parseLoginResponseFromJSON");
	
	[[RootViewController sharedRootViewController] removeNewWaitingIndicator];
    
	if ((NSNull *)jsonResult.data != [NSNull null] && jsonResult.data != nil) {
		[AppModel sharedAppModel].loggedIn = YES;
		[AppModel sharedAppModel].playerId = [self validIntForKey:@"player_id" inDictionary:((NSDictionary*)jsonResult.data)];
		[AppModel sharedAppModel].playerMediaId = [self validIntForKey:@"media_id" inDictionary:((NSDictionary*)jsonResult.data)];
		[AppModel sharedAppModel].userName = [((NSDictionary*)jsonResult.data) objectForKey:@"user_name"];
		[AppModel sharedAppModel].displayName = [((NSDictionary*)jsonResult.data) objectForKey:@"display_name"];
        [[AppServices sharedAppServices] setShowPlayerOnMap];
        [[AppModel sharedAppModel] saveUserDefaults];
        
        //Subscribe to player channel
        [RootViewController sharedRootViewController].playerChannel = [[RootViewController sharedRootViewController].client subscribeToPrivateChannelNamed:[NSString stringWithFormat:@"%d-player-channel",[AppModel sharedAppModel].playerId]];
    }
	else {
		[AppModel sharedAppModel].loggedIn = NO;
	}
    
	[[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:@"NewLoginResponseReady" object:nil]];
    
    //Should never excecute following code... (why would loading vc be up now?) -Phil 9/18/12
    if([RootViewController sharedRootViewController].loadingVC){
        [RootViewController sharedRootViewController].loadingVC.progressLabel.text = NSLocalizedString(@"AppServicesRecievedLocationListKey", @"");
        [RootViewController sharedRootViewController].loadingVC.receivedData++;
    }
    
}



-(void)parseSelfRegistrationResponseFromJSON: (JSONResult *)jsonResult{
    
	
	if (!jsonResult) {
		NSLog(@"AppModel registerNewUser: No result Data, return");
		[[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:@"SelfRegistrationFailed" object:nil]];
	}
    
    int newId = [(NSDecimalNumber*)jsonResult.data intValue];
    
	if (newId > 0) {
		NSLog(@"AppModel: Result from new user request successfull");
		[[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:@"SelfRegistrationSucceeded" object:nil]];
	}
	else {
		NSLog(@"AppModel: Result from new user request unsuccessfull");
		[[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:@"SelfRegistrationFailed" object:nil]];
	}
}

- (Game *)parseGame:(NSDictionary *)gameSource {
    //create a new game
    Game *game = [[Game alloc] init];
    
    game.gameId = [self validIntForKey:@"game_id" inDictionary:gameSource];
    //NSLog(@"AppModel: Parsing Game: %d", game.gameId);
    
    NSString *hasBeenPlayed = [gameSource valueForKey:@"has_been_played"];
    if ((NSNull *)hasBeenPlayed != [NSNull null]) game.hasBeenPlayed = [hasBeenPlayed boolValue];
    else game.hasBeenPlayed = NO;
    
    game.name = [gameSource valueForKey:@"name"];
    if ((NSNull *)game.name == [NSNull null]) game.name = @"";
    
    NSString *isLocational = [gameSource valueForKey:@"is_locational"];
    if ((NSNull *)isLocational != [NSNull null]) game.isLocational = [isLocational boolValue];
    else game.isLocational = NO;
    
    NSString *showPlayerLocation = [gameSource valueForKey:@"show_player_location"];
    if ((NSNull *)showPlayerLocation != [NSNull null]) game.showPlayerLocation = [showPlayerLocation boolValue];
    else game.showPlayerLocation = YES;
    
    game.inventoryWeightCap = [self validIntForKey:@"inventory_weight_cap" inDictionary:gameSource];
    
    game.description = [gameSource valueForKey:@"description"];
    if ((NSNull *)game.description == [NSNull null]) game.description = @"";
    
    game.mapType = [gameSource valueForKey:@"map_type"];
    if ((NSNull *)game.mapType == [NSNull null] || (![game.mapType isEqualToString:@"STREET"] && ![game.mapType isEqualToString:@"SATELLITE"] && ![game.mapType isEqualToString:@"HYBRID"])) game.mapType = @"STREET";
    
    game.rating = [self validIntForKey:@"rating" inDictionary:gameSource];
    
    game.pcMediaId = [self validIntForKey:@"pc_media_id" inDictionary:gameSource];
    
    NSString *distance = [gameSource valueForKey:@"distance"];
    if ((NSNull *)distance != [NSNull null]) game.distanceFromPlayer = [distance doubleValue];
    else game.distanceFromPlayer = 999999999;
    
    NSString *latitude = [gameSource valueForKey:@"latitude"];
    NSString *longitude = [gameSource valueForKey:@"longitude"];
    if ((NSNull *)latitude != [NSNull null] && (NSNull *)longitude != [NSNull null] ){
        CLLocation *locationAlloc = [[CLLocation alloc] initWithLatitude:[latitude doubleValue]
                                                               longitude:[longitude doubleValue]];
        game.location = locationAlloc;
    }
    else{
        CLLocation *locationAlloc = [[CLLocation alloc] init];
        game.location = locationAlloc;
    }
    
    game.authors = [gameSource valueForKey:@"editors"];
    if ((NSNull *)game.authors == [NSNull null]) game.authors = @"";
    
    game.numPlayers = [self validIntForKey:@"numPlayers" inDictionary:gameSource];
    
    game.playerCount = [self validIntForKey:@"count" inDictionary:gameSource];
    
    NSString *iconMediaUrl = [gameSource valueForKey:@"icon_media_url"];
    if ((NSNull *)iconMediaUrl != [NSNull null] && [iconMediaUrl length]>0) {
        game.iconMediaUrl = [NSURL URLWithString:iconMediaUrl];
        game.iconMedia = [[AppModel sharedAppModel].mediaCache mediaForUrl:game.iconMediaUrl];
    }
    
    NSString *mediaUrl = [gameSource valueForKey:@"media_url"];
    if ((NSNull *)mediaUrl != [NSNull null] && [mediaUrl length]>0){
        game.mediaUrl = [NSURL URLWithString:mediaUrl];
        game.splashMedia = [[AppModel sharedAppModel].mediaCache mediaForUrl:game.mediaUrl];
    }
    
    game.completedQuests = [self validIntForKey:@"completedQuests" inDictionary:gameSource];
    
    game.totalQuests = [self validIntForKey:@"totalQuests" inDictionary:gameSource];
    
    game.launchNodeId = [self validIntForKey:@"on_launch_node_id" inDictionary:gameSource];
    
    game.completeNodeId = [self validIntForKey:@"game_complete_node_id" inDictionary:gameSource];
    
    game.calculatedScore = [self validIntForKey:@"calculatedScore" inDictionary:gameSource];
    
    game.numReviews = [self validIntForKey:@"numComments" inDictionary:gameSource];
    
    game.allowsPlayerTags = [[gameSource valueForKey:@"allow_player_tags"]boolValue];
    
    game.allowShareNoteToMap = [[gameSource valueForKey:@"allow_share_note_to_map"]boolValue];
    game.allowShareNoteToList = [[gameSource valueForKey:@"allow_share_note_to_book"]boolValue];
    game.allowNoteComments = [[gameSource valueForKey:@"allow_note_comments"]boolValue];
    game.allowNoteLikes = [[gameSource valueForKey:@"allow_note_likes"]boolValue];
    game.allowTrading = [[gameSource valueForKey:@"allow_trading"]boolValue];
    
    NSArray *comments = [gameSource valueForKey:@"comments"];
    for (NSDictionary *comment in comments) {
        //This is returning an object with playerId,tex, and rating. Right now, we just want the text
        //TODO: Create a Comments object
        Comment *c = [[Comment alloc] init];
        c.text = [comment objectForKey:@"text"];
        c.playerName = [comment objectForKey:@"username"];
        NSString *cRating = [comment objectForKey:@"rating"];
        if ((NSNull *)cRating != [NSNull null]) c.rating = [cRating intValue];
        [game.comments addObject:c];
    }
    
    
    //NSLog(@"Model: Adding Game: %@", game.name);
    return game;
}

-(NSMutableArray *)parseGameListFromJSON: (JSONResult *)jsonResult{
    
    [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:@"RecievedGameList" object:nil]];
    
    NSArray *gameListArray = (NSArray *)jsonResult.data;
    
    NSMutableArray *tempGameList = [[NSMutableArray alloc] init];
    
    NSEnumerator *gameListEnumerator = [gameListArray objectEnumerator];
    NSDictionary *gameDictionary;
    while ((gameDictionary = [gameListEnumerator nextObject])) {
        [tempGameList addObject:[self parseGame:(gameDictionary)]];
    }
    
    NSError *error;
    if (![[AppModel sharedAppModel].mediaCache.context save:&error]) {
        NSLog(@"Whoops, couldn't save: %@", [error localizedDescription]);
    }
    
    NSLog(@"AppModel: parseGameListFromJSON Complete, sending notification");
    
    return tempGameList;
}

-(void)parseGameFromJSON: (JSONResult *)jsonResult{
    NSLog(@"parseGameFromJSON called");
    currentlyFetchingOneGame = NO;
    
    [AppModel sharedAppModel].currentGame = [self parseGame:jsonResult.data];
    [[AppModel sharedAppModel] saveUserDefaults];
    [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:@"GameReady" object:nil]];
}

-(void)parseOneGameFromJSON: (JSONResult *)jsonResult{
    NSLog(@"parseOneGameFromJSON called");
    currentlyFetchingOneGame = NO;
    [AppModel sharedAppModel].singleGameList = [self parseGameListFromJSON:jsonResult];
    [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:@"OneGameReady" object:nil]];
}

-(void)parseNearbyGameListFromJSON: (JSONResult *)jsonResult{
    currentlyFetchingNearbyGamesList = NO;
    [AppModel sharedAppModel].nearbyGameList = [self parseGameListFromJSON:jsonResult];
    [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:@"NewNearbyGameListReady" object:nil]];
}

-(void)parseSearchGameListFromJSON: (JSONResult *)jsonResult{
    currentlyFetchingSearchGamesList = NO;
    [AppModel sharedAppModel].searchGameList = [self parseGameListFromJSON:jsonResult];
    [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:@"NewSearchGameListReady" object:nil]];
}

-(void)parsePopularGameListFromJSON: (JSONResult *)jsonResult{
    currentlyFetchingPopularGamesList = NO;
    [AppModel sharedAppModel].popularGameList = [self parseGameListFromJSON:jsonResult];
    [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:@"NewPopularGameListReady" object:nil]];
}

-(void)parseRecentGameListFromJSON: (JSONResult *)jsonResult{
    NSLog(@"AppModel: parseRecentGameListFromJSON Beginning");
    
    currentlyFetchingRecentGamesList = NO;
    
    [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:@"RecievedGameList" object:nil]];
    
    NSArray *gameListArray = (NSArray *)jsonResult.data;
    
    NSMutableArray *tempGameList = [[NSMutableArray alloc] init];
    
    NSEnumerator *gameListEnumerator = [gameListArray objectEnumerator];
    NSDictionary *gameDictionary;
    while ((gameDictionary = [gameListEnumerator nextObject])) {
        [tempGameList addObject:[self parseGame:(gameDictionary)]];
    }
    
    [AppModel sharedAppModel].recentGameList = tempGameList;
    NSError *error;
    if (![[AppModel sharedAppModel].mediaCache.context save:&error]) {
        NSLog(@"Whoops, couldn't save: %@", [error localizedDescription]);
    }
    NSLog(@"AppModel: parseGameListFromJSON Complete, sending notification");
    
    [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:@"NewRecentGameListReady" object:nil]];
    
}

- (void)saveComment:(NSString*)comment game:(int)gameId starRating:(int)rating{
	NSLog(@"AppModel: Save Comment Requested");
	NSArray *arguments = [NSArray arrayWithObjects:[NSString stringWithFormat:@"%d", [AppModel sharedAppModel].playerId], [NSString stringWithFormat:@"%d", gameId], [NSString stringWithFormat:@"%d", rating], comment, nil];
	JSONConnection *jsonConnection = [[JSONConnection alloc] initWithServer:[AppModel sharedAppModel].serverURL
                                                             andServiceName: @"games"
                                                              andMethodName:@"saveComment"
                                                               andArguments:arguments andUserInfo:nil];
	
	[jsonConnection performAsynchronousRequestWithHandler:@selector(parseSaveCommentResponseFromJSON:)];
	
}

- (void)parseSaveCommentResponseFromJSON: (JSONResult *)jsonResult{
	
	if (!jsonResult) {
		NSLog(@"AppModel saveComment: No result Data, return");
		[[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:@"SaveCommentFailed" object:nil]];
	}
	else {
		NSLog(@"AppModel: Result from save comment request unsuccessfull");
		[[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:@"SaveCommentFailed" object:nil]];
	}
}

- (void)parseLocationListFromJSON: (JSONResult *)jsonResult{
    
	NSLog(@"AppModel: Parsing Location List");
	
    currentlyFetchingLocationList = NO;
    
	[[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:@"ReceivedLocationList" object:nil]];
	
	//Continue parsing
	NSArray *locationsArray = (NSArray *)jsonResult.data;
    
	//Build the location list
	NSMutableArray *tempLocationsList = [[NSMutableArray alloc] init];
	NSEnumerator *locationsEnumerator = [locationsArray objectEnumerator];
	NSDictionary *locationDictionary;
	while ((locationDictionary = [locationsEnumerator nextObject])) {
		//create a new location
        Location *location = [self parseLocationFromDictionary:locationDictionary];
		
		NSLog(@"AppServices: Adding Location: %@ - Type:%@ Id:%d Hidden:%d ForceDisp:%d QuickTravel:%d Qty:%d",
			  location.name, location.objectType, location.objectId,
			  location.hidden, location.forcedDisplay, location.allowsQuickTravel, location.qty);
		[tempLocationsList addObject:location];
	}
	
	[AppModel sharedAppModel].locationList = tempLocationsList;
	
	//Tell everyone
	NSLog(@"AppServices: Finished fetching locations from server, model updated");
	[[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:@"NewLocationListReady" object:nil]];
	
}


-(Location*)parseLocationFromDictionary: (NSDictionary*)locationDictionary {
    NSLog(@"AppServices: parseLocationFromDictionary");
    
    Location *location = [[Location alloc] init];
    location.locationId = [self validIntForKey:@"location_id" inDictionary:locationDictionary];
    location.name = [locationDictionary valueForKey:@"name"];
    location.iconMediaId = [self validIntForKey:@"icon_media_id" inDictionary:locationDictionary];
    CLLocation *tmpLocation = [[CLLocation alloc] initWithLatitude:[[locationDictionary valueForKey:@"latitude"] doubleValue]
                                                         longitude:[[locationDictionary valueForKey:@"longitude"] doubleValue]];
    location.location = tmpLocation;
    location.error = [[locationDictionary valueForKey:@"error"] doubleValue];
    location.objectType = [locationDictionary valueForKey:@"type"];
    location.objectId = [self validIntForKey:@"type_id" inDictionary:locationDictionary];
    location.hidden = [[locationDictionary valueForKey:@"hidden"] boolValue];
    location.forcedDisplay = [[locationDictionary valueForKey:@"force_view"] boolValue];
    location.allowsQuickTravel = [[locationDictionary valueForKey:@"allow_quick_travel"] boolValue];
    location.qty = [self validIntForKey:@"item_qty" inDictionary:locationDictionary];
    location.hasBeenViewed = NO;
    location.showTitle = [[locationDictionary valueForKey:@"show_title"] boolValue];
    location.wiggle = [[locationDictionary valueForKey:@"wiggle"] boolValue];
    NSNumber *num = [NSNumber numberWithInt:location.wiggle];
    if(num == nil)  location.wiggle = 0;
    //if(location.wiggle == nil)  location.wiggle = 0;
    location.deleteWhenViewed = [self validIntForKey:@"delete_when_viewed" inDictionary:locationDictionary];
    
    if(location.objectType &&[location.objectType isEqualToString:@"PlayerNote"]){
        Note *note = [[AppModel sharedAppModel]noteForNoteId:location.objectId playerListYesGameListNo:YES];
        if(!note) note = [[AppModel sharedAppModel]noteForNoteId:location.objectId playerListYesGameListNo:NO];
        if(!note)
            NSLog(@"this shouldn't happen");
        if(note && note.showOnList)location.allowsQuickTravel = YES;
        else location.allowsQuickTravel = NO;
    }
    return location;
}

-(void)parseSingleMediaFromJSON: (JSONResult *)jsonResult
{
    //Just convert the data into a dictionary and pretend it is a full game list, so same thing as 'parseGameMediaListFromJSON'
    NSArray * data = [[NSArray alloc] initWithObjects:jsonResult.data, nil];
    jsonResult.data = data;
    [self performSelector:@selector(startCachingMedia:) withObject:jsonResult afterDelay:.1];
}

-(void)parseGameMediaListFromJSON: (JSONResult *)jsonResult{
    if([RootViewController sharedRootViewController].loadingVC)
        [RootViewController sharedRootViewController].loadingVC.receivedData++;
    
    [self performSelector:@selector(startCachingMedia:) withObject:jsonResult afterDelay:.1];
}

-(void)startCachingMedia:(JSONResult *)jsonResult
{
    //Get server media
    NSArray *serverMediaArray = (NSArray *)jsonResult.data;
    
    //Get cached media
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(gameid = 0) OR (gameid = %d)", [AppModel sharedAppModel].currentGame.gameId];
    NSArray *cachedMediaArray = [[AppModel sharedAppModel].mediaCache mediaForPredicate:predicate];
    
    //Construct cached media map (dictionary with identical key/values of mediaId) to quickly check for existence of media
    NSMutableDictionary *cachedMediaMap = [[NSMutableDictionary alloc]initWithCapacity:cachedMediaArray.count];
    for(int i = 0; i < cachedMediaArray.count; i++)
        [cachedMediaMap setObject:[cachedMediaArray objectAtIndex:i] forKey:[[cachedMediaArray objectAtIndex:i] uid]];
    
    //For every media in server array
    int mediaLoaded = 0;
    Media *tmpMedia;
    for(int i = 0; i < [serverMediaArray count]; i++)
    {
        //Check if the id is valid, but doesn't exist in the cached array
        int mediaId = [self validIntForKey:@"media_id" inDictionary:[serverMediaArray objectAtIndex:i]];
        if(mediaId >= 1 && ![cachedMediaMap objectForKey:[NSNumber numberWithInt:mediaId]])
        {
            //Cache it
            NSDictionary *tempMediaDict = [serverMediaArray objectAtIndex:i];
            NSString *fileName = [tempMediaDict valueForKey:@"file_path"] ? [tempMediaDict valueForKey:@"file_path"] : [tempMediaDict valueForKey:@"file_name"];
            tmpMedia = [[AppModel sharedAppModel].mediaCache addMediaToCache:mediaId];
            tmpMedia.url = [NSString stringWithFormat:@"%@%@", [tempMediaDict valueForKey:@"url_path"], fileName];
            tmpMedia.type = [tempMediaDict valueForKey:@"type"];
            tmpMedia.gameid = [NSNumber numberWithInt:[self validIntForKey:@"game_id" inDictionary:tempMediaDict]];
            NSLog(@"Cached Media: %d with URL: %@",mediaId,tmpMedia.url);
        }
        else if((tmpMedia = [cachedMediaMap objectForKey:[NSNumber numberWithInt:mediaId]]) && (tmpMedia.url == nil || tmpMedia.type == nil || tmpMedia.gameid == nil))
        {
            NSDictionary *tempMediaDict = [serverMediaArray objectAtIndex:i];
            NSString *fileName = [tempMediaDict valueForKey:@"file_path"] ? [tempMediaDict valueForKey:@"file_path"] : [tempMediaDict valueForKey:@"file_name"];
            tmpMedia.url = [NSString stringWithFormat:@"%@%@", [tempMediaDict valueForKey:@"url_path"], fileName];
            tmpMedia.type = [tempMediaDict valueForKey:@"type"];
            tmpMedia.gameid = [NSNumber numberWithInt:[self validIntForKey:@"game_id" inDictionary:tempMediaDict]];
            NSLog(@"Cached Media: %d with URL: %@",mediaId,tmpMedia.url);
        }
        
        //Update progress 
        if([RootViewController sharedRootViewController].loadingVC){
            [RootViewController sharedRootViewController].loadingVC.progressLabel.text = NSLocalizedString(@"AppServicesCachingGameMediaKey", @"");
            [RootViewController sharedRootViewController].loadingVC.progressLabel.text = [[RootViewController sharedRootViewController].loadingVC.progressLabel.text stringByAppendingString:[NSString stringWithFormat:@" (%d of %d)", mediaLoaded,[serverMediaArray count]]];
        }
        [[RootViewController sharedRootViewController].loadingVC.progressLabel setNeedsDisplay];
        
        mediaLoaded++;
    }
    NSError *error;
    if (![[AppModel sharedAppModel].mediaCache.context save:&error])
        NSLog(@"Whoops, couldn't save: %@", [error localizedDescription]);
    
    [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:@"ReceivedMediaList" object:nil]];
    
    [[RootViewController sharedRootViewController] removeNewWaitingIndicator];
    
    if([RootViewController sharedRootViewController].loadingVC){
        [RootViewController sharedRootViewController].loadingVC.progressLabel.text = NSLocalizedString(@"AppServicesStartingGameKey", @"");
        [RootViewController sharedRootViewController].loadingVC.receivedData++;
    }
}

-(void)parseGameItemListFromJSON: (JSONResult *)jsonResult{
	NSArray *itemListArray = (NSArray *)jsonResult.data;
    
	NSMutableDictionary *tempItemList = [[NSMutableDictionary alloc] init];
	NSEnumerator *enumerator = [itemListArray objectEnumerator];
	NSDictionary *dict;
    int itemsParsed = 0;
	while ((dict = [enumerator nextObject])) {
		Item *tmpItem = [self parseItemFromDictionary:dict];
		
		[tempItemList setObject:tmpItem forKey:[NSNumber numberWithInt:tmpItem.itemId]];
        
        itemsParsed++;
        if([RootViewController sharedRootViewController].loadingVC){
            [RootViewController sharedRootViewController].loadingVC.progressLabel.text = NSLocalizedString(@"AppServicesReceivedGameItemListKey", @"");
            [RootViewController sharedRootViewController].loadingVC.progressLabel.text = [[RootViewController sharedRootViewController].loadingVC.progressLabel.text stringByAppendingString:[NSString stringWithFormat:@" (%d of %d)", itemsParsed,[itemListArray count]]];
        }
	}
	
	[AppModel sharedAppModel].gameItemList = tempItemList;
    
    if([RootViewController sharedRootViewController].loadingVC) [RootViewController sharedRootViewController].loadingVC.receivedData++;
}


-(void)parseGameNodeListFromJSON: (JSONResult *)jsonResult{
	NSArray *nodeListArray = (NSArray *)jsonResult.data;
	NSMutableDictionary *tempNodeList = [[NSMutableDictionary alloc] init];
	NSEnumerator *enumerator = [nodeListArray objectEnumerator];
	NSDictionary *dict;
    int nodesParsed = 0;
	while ((dict = [enumerator nextObject])) {
		Node *tmpNode = [self parseNodeFromDictionary:dict];
		
		[tempNodeList setObject:tmpNode forKey:[NSNumber numberWithInt:tmpNode.nodeId]];
        
        nodesParsed++;
        if([RootViewController sharedRootViewController].loadingVC){
            [RootViewController sharedRootViewController].loadingVC.progressLabel.text = NSLocalizedString(@"AppServicesReceivedGameNodeListKey", @"");
            [RootViewController sharedRootViewController].loadingVC.progressLabel.text = [[RootViewController sharedRootViewController].loadingVC.progressLabel.text stringByAppendingString:[NSString stringWithFormat:@" (%d of %d)", nodesParsed,[nodeListArray count]]];
        }
	}
	
	[AppModel sharedAppModel].gameNodeList = tempNodeList;
    
    if([RootViewController sharedRootViewController].loadingVC)
        [RootViewController sharedRootViewController].loadingVC.receivedData++;
}

-(void)parseGameTabListFromJSON: (JSONResult *)jsonResult{
	NSArray *tabListArray = (NSArray *)jsonResult.data;
	NSArray *tempTabList = [[NSMutableArray alloc] initWithCapacity:10];
	NSEnumerator *enumerator = [tabListArray objectEnumerator];
	NSDictionary *dict;
    int tabsParsed = 0;
	while ((dict = [enumerator nextObject])) {
		Tab *tmpTab = [self parseTabFromDictionary:dict];
		tempTabList = [tempTabList arrayByAddingObject:tmpTab];
        
        tabsParsed++;
        if([RootViewController sharedRootViewController].loadingVC){
            [RootViewController sharedRootViewController].loadingVC.progressLabel.text = NSLocalizedString(@"AppServicesReceivedGameNodeListKey", @"");
            [RootViewController sharedRootViewController].loadingVC.progressLabel.text = [[RootViewController sharedRootViewController].loadingVC.progressLabel.text stringByAppendingString:[NSString stringWithFormat:@" (%d of %d)", tabsParsed,[tabListArray count]]];
        }
	}
	
	[AppModel sharedAppModel].gameTabList = tempTabList;
    [[RootViewController sharedRootViewController] changeTabBar];
    
    if([RootViewController sharedRootViewController].loadingVC)
        [RootViewController sharedRootViewController].loadingVC.receivedData++;
}


-(void)parseGameNpcListFromJSON: (JSONResult *)jsonResult{
	NSArray *npcListArray = (NSArray *)jsonResult.data;
	
	NSMutableDictionary *tempNpcList = [[NSMutableDictionary alloc] init];
	NSEnumerator *enumerator = [((NSArray *)npcListArray) objectEnumerator];
	NSDictionary *dict;
    int npcsParsed = 0;
	while ((dict = [enumerator nextObject])) {
		Npc *tmpNpc = [self parseNpcFromDictionary:dict];
		
		[tempNpcList setObject:tmpNpc forKey:[NSNumber numberWithInt:tmpNpc.npcId]];
        
        npcsParsed++;
        if([RootViewController sharedRootViewController].loadingVC){
            [RootViewController sharedRootViewController].loadingVC.progressLabel.text = NSLocalizedString(@"AppServicesReceivedGameNPCListKey", @"");
            [RootViewController sharedRootViewController].loadingVC.progressLabel.text = [[RootViewController sharedRootViewController].loadingVC.progressLabel.text stringByAppendingString:[NSString stringWithFormat:@" (%d of %d)", npcsParsed,[npcListArray count]]];
        }
	}
	
	[AppModel sharedAppModel].gameNpcList = tempNpcList;
    
    if([RootViewController sharedRootViewController].loadingVC)
        [RootViewController sharedRootViewController].loadingVC.receivedData++;
}

-(void)parseGameWebPageListFromJSON: (JSONResult *)jsonResult{
	NSArray *webpageListArray = (NSArray *)jsonResult.data;
	
	NSMutableDictionary *tempWebPageList = [[NSMutableDictionary alloc] init];
	NSEnumerator *enumerator = [((NSArray *)webpageListArray) objectEnumerator];
	NSDictionary *dict;
    int webpagesParsed = 0;
	while ((dict = [enumerator nextObject])) {
		WebPage *tmpWebpage = [self parseWebPageFromDictionary:dict];
		
		[tempWebPageList setObject:tmpWebpage forKey:[NSNumber numberWithInt:tmpWebpage.webPageId]];
        
        webpagesParsed++;
        if([RootViewController sharedRootViewController].loadingVC){
            [RootViewController sharedRootViewController].loadingVC.progressLabel.text = NSLocalizedString(@"AppServicesReceivedGameWebpageListKey", @"");
            [RootViewController sharedRootViewController].loadingVC.progressLabel.text = [[RootViewController sharedRootViewController].loadingVC.progressLabel.text stringByAppendingString:[NSString stringWithFormat:@" (%d of %d)", webpagesParsed,[webpageListArray count]]];
        }
	}
	
	[AppModel sharedAppModel].gameWebPageList = tempWebPageList;
    
    if([RootViewController sharedRootViewController].loadingVC)
        [RootViewController sharedRootViewController].loadingVC.receivedData++;
}
-(void)parseGamePanoramicListFromJSON: (JSONResult *)jsonResult{
	NSArray *panListArray = (NSArray *)jsonResult.data;
	
	NSMutableDictionary *tempPanoramicList = [[NSMutableDictionary alloc] init];
	NSEnumerator *enumerator = [((NSArray *)panListArray) objectEnumerator];
	NSDictionary *dict;
    int panoramicsParsed = 0;
	while ((dict = [enumerator nextObject])) {
		Panoramic *tmpPan = [self parsePanoramicFromDictionary:dict];
		
		[tempPanoramicList setObject:tmpPan forKey:[NSNumber numberWithInt:tmpPan.panoramicId]];
        
        panoramicsParsed++;
        if([RootViewController sharedRootViewController].loadingVC){
            [RootViewController sharedRootViewController].loadingVC.progressLabel.text = NSLocalizedString(@"AppServicesReceivedGamePanoramicListKey", @"");
            [RootViewController sharedRootViewController].loadingVC.progressLabel.text = [[RootViewController sharedRootViewController].loadingVC.progressLabel.text stringByAppendingString:[NSString stringWithFormat:@" (%d of %d)", panoramicsParsed,[panListArray count]]];
        }
	}
	
	[AppModel sharedAppModel].gamePanoramicList = tempPanoramicList;
    
    if([RootViewController sharedRootViewController].loadingVC)
        [RootViewController sharedRootViewController].loadingVC.receivedData++;
}


-(void)parseInventoryFromJSON: (JSONResult *)jsonResult{
	NSLog(@"AppModel: Parsing Inventory");
	
	[[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:@"ReceivedInventory" object:nil]];
    
    currentlyFetchingInventory = NO;
    
    
	//Check for an error
	
	//Compare this hash to the last one. If the same, stop hee
    
	if ([jsonResult.hash isEqualToString:[AppModel sharedAppModel].inventoryHash]) {
		NSLog(@"AppModel: Hash is same as last inventory listy update, continue");
		return;
	}
	
	//Save this hash for later comparisions
	[AppModel sharedAppModel].inventoryHash = [jsonResult.hash copy];
	
	//Continue parsing
	NSArray *inventoryArray = (NSArray *)jsonResult.data;
	
	NSMutableDictionary *tempInventory = [[NSMutableDictionary alloc] initWithCapacity:10];
    NSMutableDictionary *tempAttributes = [[NSMutableDictionary alloc] initWithCapacity:10];
    
	NSEnumerator *inventoryEnumerator = [((NSArray *)inventoryArray) objectEnumerator];
	NSDictionary *itemDictionary;
    int inventoryParsed = 0;
	while ((itemDictionary = [inventoryEnumerator nextObject])) {
		Item *item = [[Item alloc] init];
		item.itemId = [self validIntForKey:@"item_id" inDictionary:itemDictionary];
		item.name = [itemDictionary valueForKey:@"name"];
		item.description = [itemDictionary valueForKey:@"description"];
		item.mediaId = [self validIntForKey:@"media_id" inDictionary:itemDictionary];
		item.iconMediaId = [self validIntForKey:@"icon_media_id" inDictionary:itemDictionary];
		item.dropable = [[itemDictionary valueForKey:@"dropable"] boolValue];
		item.destroyable = [[itemDictionary valueForKey:@"destroyable"] boolValue];
		item.qty = [self validIntForKey:@"qty" inDictionary:itemDictionary];
        if ([self validIntForKey:@"viewed" inDictionary:itemDictionary] > 0)
            item.hasViewed = YES;
        else
            item.hasViewed = NO;
        item.maxQty = [self validIntForKey:@"max_qty_in_inventory" inDictionary:itemDictionary];
        item.isAttribute = [[itemDictionary valueForKey:@"is_attribute"] boolValue];
        item.isTradeable = [[itemDictionary valueForKey:@"tradeable"] boolValue];
        item.weight = [self validIntForKey:@"weight" inDictionary:itemDictionary];
        item.url = [itemDictionary valueForKey:@"url"];
        item.type = [itemDictionary valueForKey:@"type"];
        item.creatorId = [self validIntForKey:@"creator_player_id" inDictionary:itemDictionary];
		NSLog(@"Model: Adding Item: %@", item.name);
        if(item.isAttribute)[tempAttributes setObject:item forKey:[NSString stringWithFormat:@"%d",item.itemId]];
        else [tempInventory setObject:item forKey:[NSString stringWithFormat:@"%d",item.itemId]];
        
        inventoryParsed++;
        if([RootViewController sharedRootViewController].loadingVC){
            [RootViewController sharedRootViewController].loadingVC.progressLabel.text = NSLocalizedString(@"AppServicesReceivedInventoryKey", @"");
            [RootViewController sharedRootViewController].loadingVC.progressLabel.text = [[RootViewController sharedRootViewController].loadingVC.progressLabel.text stringByAppendingString:[NSString stringWithFormat:@" (%d of %d)", inventoryParsed,[inventoryArray count]]];
        }
	}
    
	[AppModel sharedAppModel].inventory = tempInventory;
    [AppModel sharedAppModel].attributes = tempAttributes;
	
	NSLog(@"AppModel: Finished fetching inventory from server, model updated");
	[[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:@"NewInventoryReady" object:nil]];
	
	//Note: The inventory list VC listener will add the badge now that it knows something is different
    
    if([RootViewController sharedRootViewController].loadingVC)
        [RootViewController sharedRootViewController].loadingVC.receivedData++;
}

/*
 - (void)parseGetBestImageMatchFromJSON: (JSONResult *)jsonResult {
 
 NSLog(@"AppModel: parseGetBestImageMatchFromJSON");
 
 //Continue parsing
 UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"Data from Server"
 message:(NSString *)jsonResult.data
 delegate:nil
 cancelButtonTitle:nil
 otherButtonTitles: nil];
 
 [alert show];
 [alert release];
 
 }
 */

-(void)parseQRCodeObjectFromJSON: (JSONResult *)jsonResult {
    NSLog(@"ParseQRCodeObjectFromJSON: Coolio!");
    [[RootViewController sharedRootViewController] removeNewWaitingIndicator];
    
	NSObject<QRCodeProtocol> *qrCodeObject;
    
	if ((NSNull*)jsonResult.data != [NSNull null]) {
		NSDictionary *qrCodeDictionary = (NSDictionary *)jsonResult.data;
        if(![qrCodeDictionary isKindOfClass:[NSString class]]){
            NSString *type = [qrCodeDictionary valueForKey:@"link_type"];
            NSDictionary *objectDictionary = [qrCodeDictionary valueForKey:@"object"];
            if ([type isEqualToString:@"Location"]) qrCodeObject = [self parseLocationFromDictionary:objectDictionary];
        }
        else qrCodeObject = qrCodeDictionary;
	}
	
	[[NSNotificationCenter defaultCenter] postNotification: [NSNotification notificationWithName:@"QRCodeObjectReady" object:qrCodeObject]];
    
	
}


-(void)parseStartOverFromJSON:(JSONResult *)jsonResult{
	NSLog(@"AppModel: Parsing start over result and firing off fetches");
	//[self silenceNextServerUpdate];
}


-(void)parseUpdateServerWithPlayerLocationFromJSON:(JSONResult *)jsonResult{
    NSLog(@"AppModel: parseUpdateServerWithPlayerLocationFromJSON");
    currentlyUpdatingServerWithPlayerLocation = NO;
}

-(void)parseQuestListFromJSON: (JSONResult *)jsonResult{
    
	NSLog(@"AppModel: Parsing Quests");
    
    currentlyFetchingQuestList = NO;
	
	//Check for an error
	
	//Tell everyone we just recieved the questList
	[[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:@"ReceivedQuestList" object:nil]];
	
	//Compare this hash to the last one. If the same, stop here
	if ([jsonResult.hash isEqualToString:[AppModel sharedAppModel].questListHash]) {
		NSLog(@"AppModel: Hash is same as last quest list update, continue");
		return;
	}
	
	//Save this hash for later comparisions
	[AppModel sharedAppModel].questListHash = [jsonResult.hash copy];
	
	//Continue parsing
    
	NSDictionary *questListDictionary = (NSDictionary *)jsonResult.data;
	
	//parse out the active quests into quest objects
	NSMutableArray *activeQuestObjects = [[NSMutableArray alloc] init];
	NSArray *activeQuests = [questListDictionary objectForKey:@"active"];
	NSEnumerator *activeQuestsEnumerator = [activeQuests objectEnumerator];
	NSDictionary *activeQuest;
    
    //parse out the completed quests into quest objects
	NSMutableArray *completedQuestObjects = [[NSMutableArray alloc] init];
	NSArray *completedQuests = [questListDictionary objectForKey:@"completed"];
	NSEnumerator *completedQuestsEnumerator = [completedQuests objectEnumerator];
	NSDictionary *completedQuest;
    
    int questsParsed = 0;
    if([RootViewController sharedRootViewController].loadingVC){
        [RootViewController sharedRootViewController].loadingVC.progressLabel.text = NSLocalizedString(@"AppServicesReceivedQuestListKey", @"");
        [RootViewController sharedRootViewController].loadingVC.progressLabel.text = [[RootViewController sharedRootViewController].loadingVC.progressLabel.text stringByAppendingString:[NSString stringWithFormat:@" %d of %d", questsParsed,([activeQuests count] + [completedQuests count])]];
    }
    
	while ((activeQuest = [activeQuestsEnumerator nextObject])) {
        questsParsed++;
		//We have a quest, parse it into a quest abject and add it to the activeQuestObjects array
		Quest *quest = [[Quest alloc] init];
		quest.questId = [self validIntForKey:@"quest_id" inDictionary:activeQuest];
		quest.name = [activeQuest objectForKey:@"name"];
		quest.description = [activeQuest objectForKey:@"description"];
        quest.exitToTabName = ([activeQuest objectForKey:@"exit_to_tab"] != [NSNull null]) ? [activeQuest objectForKey:@"exit_to_tab"] : @"NONE";
        if ([quest.exitToTabName isEqualToString:@"QUESTS"]) quest.exitToTabName = NSLocalizedString(@"QuestViewTitleKey",@"");
        else if([quest.exitToTabName isEqualToString:@"GPS"]) quest.exitToTabName = NSLocalizedString(@"MapViewTitleKey",@"");
        else if([quest.exitToTabName isEqualToString:@"INVENTORY"]) quest.exitToTabName = NSLocalizedString(@"InventoryViewTitleKey",@"");
        else if([quest.exitToTabName isEqualToString:@"QR"]) quest.exitToTabName = NSLocalizedString(@"QRScannerTitleKey",@"");
        else if([quest.exitToTabName isEqualToString:@"PLAYER"]) quest.exitToTabName = NSLocalizedString(@"PlayerTitleKey",@"");
        else if([quest.exitToTabName isEqualToString:@"NOTE"]) quest.exitToTabName = NSLocalizedString(@"NotebookTitleKey",@"");
        else if([quest.exitToTabName isEqualToString:@"PICKGAME"]) quest.exitToTabName = NSLocalizedString(@"GamePickerTitleKey",@"");
        quest.fullScreenNotification = [[activeQuest objectForKey:@"full_screen_notify"] boolValue];
        quest.mediaId = [self validIntForKey:@"active_media_id" inDictionary:activeQuest];
		quest.iconMediaId = [self validIntForKey:@"active_icon_media_id" inDictionary:activeQuest];
        quest.sortNum = [self validIntForKey:@"sort_index" inDictionary:activeQuest];
		[activeQuestObjects addObject:quest];
        
        if([RootViewController sharedRootViewController].loadingVC){
            [RootViewController sharedRootViewController].loadingVC.progressLabel.text = NSLocalizedString(@"AppServicesReceivedQuestListKey", @"");
            [RootViewController sharedRootViewController].loadingVC.progressLabel.text = [[RootViewController sharedRootViewController].loadingVC.progressLabel.text stringByAppendingString:[NSString stringWithFormat:@" %d of %d", questsParsed,([activeQuests count] + [completedQuests count])]];
        }
	}
    
	while ((completedQuest = [completedQuestsEnumerator nextObject])) {
        questsParsed++;
		//We have a quest, parse it into a quest object and add it to the completedQuestObjects array
		Quest *quest = [[Quest alloc] init];
		quest.questId = [self validIntForKey:@"quest_id" inDictionary:completedQuest];
		quest.name = [completedQuest objectForKey:@"name"];
		quest.description = [completedQuest objectForKey:@"text_when_complete"];
        quest.exitToTabName = ([completedQuest objectForKey:@"exit_to_tab"] != [NSNull null]) ? [completedQuest objectForKey:@"exit_to_tab"] : @"NONE";
        if ([quest.exitToTabName isEqualToString:@"QUESTS"]) quest.exitToTabName = NSLocalizedString(@"QuestViewTitleKey",@"");
        else if([quest.exitToTabName isEqualToString:@"GPS"]) quest.exitToTabName = NSLocalizedString(@"MapViewTitleKey",@"");
        else if([quest.exitToTabName isEqualToString:@"INVENTORY"]) quest.exitToTabName = NSLocalizedString(@"InventoryViewTitleKey",@"");
        else if([quest.exitToTabName isEqualToString:@"QR"]) quest.exitToTabName = NSLocalizedString(@"QRScannerTitleKey",@"");
        else if([quest.exitToTabName isEqualToString:@"PLAYER"]) quest.exitToTabName = NSLocalizedString(@"PlayerTitleKey",@"");
        else if([quest.exitToTabName isEqualToString:@"NOTE"]) quest.exitToTabName = NSLocalizedString(@"NotebookTitleKey",@"");
        else if([quest.exitToTabName isEqualToString:@"PICKGAME"]) quest.exitToTabName = NSLocalizedString(@"GamePickerTitleKey",@"");
        quest.fullScreenNotification = [[completedQuest objectForKey:@"full_screen_notify"] boolValue];
        quest.mediaId = [self validIntForKey:@"complete_media_id" inDictionary:completedQuest];
        quest.iconMediaId = [self validIntForKey:@"complete_icon_media_id" inDictionary:completedQuest];
        quest.sortNum = [self validIntForKey:@"sort_index" inDictionary:completedQuest];
		[completedQuestObjects addObject:quest];
        
        if([RootViewController sharedRootViewController].loadingVC){
            [RootViewController sharedRootViewController].loadingVC.progressLabel.text = NSLocalizedString(@"AppServicesReceivedQuestListKey", @"");
            [RootViewController sharedRootViewController].loadingVC.progressLabel.text = [[RootViewController sharedRootViewController].loadingVC.progressLabel.text stringByAppendingString:[NSString stringWithFormat:@" (%d of %d)", questsParsed,([activeQuests count] + [completedQuests count])]];
        }
	}
    
    
	//Package the two object arrays in a Dictionary
	NSMutableDictionary *tmpQuestList = [[NSMutableDictionary alloc] init];
	[tmpQuestList setObject:activeQuestObjects forKey:@"active"];
	[tmpQuestList setObject:completedQuestObjects forKey:@"completed"];
	[AppModel sharedAppModel].questList = tmpQuestList;
    
    
    //Update Game Object
	[AppModel sharedAppModel].currentGame.completedQuests = [completedQuestObjects count];
	[AppModel sharedAppModel].currentGame.activeQuests = [activeQuestObjects count];
    
	[AppModel sharedAppModel].currentGame.totalQuests = [self validIntForKey:@"totalQuests" inDictionary:questListDictionary];
	
    
	//Sound the alarm
	NSLog(@"AppModel: Finished fetching quests from server, model updated");
	[[NSNotificationCenter defaultCenter] postNotification: [NSNotification notificationWithName:@"NewQuestListReady" object:nil]];
    
    if([RootViewController sharedRootViewController].loadingVC) [RootViewController sharedRootViewController].loadingVC.receivedData++;
}


@end