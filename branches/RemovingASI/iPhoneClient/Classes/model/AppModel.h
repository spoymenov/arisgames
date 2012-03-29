//
//  AppModel.h
//  ARIS
//
//  Created by Ben Longoria on 2/17/09.
//  Copyright 2009 University of Wisconsin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CLLocation.h>
#import <CoreData/CoreData.h>
#import "Game.h"
#import "Item.h"
#import "Node.h"
#import "Npc.h"
#import "Media.h"
#import "WebPage.h"
#import "Panoramic.h"
#import "Note.h"
#import "UploadMan.h"

extern NSDictionary *InventoryElements;

@interface AppModel : NSObject {
	NSUserDefaults *defaults;
	NSURL *serverURL;
    BOOL showGamesInDevelopment;
    BOOL showPlayerOnMap;
	Game *currentGame;
	UIAlertView *networkAlert;
	
	BOOL loggedIn;
	int playerId;
	NSString *userName;
	NSString *password;
	CLLocation *playerLocation;

	NSMutableArray *gameList;
    NSMutableArray *recentGamelist;
	NSMutableArray *locationList;
	NSString *locationListHash;
	NSMutableArray *playerList;
	NSMutableArray *nearbyLocationsList;
	NSMutableDictionary *inventory;
    NSMutableDictionary *attributes;

	NSString *inventoryHash,*playerNoteListHash,*gameNoteListHash; 
	NSMutableDictionary *questList;
	NSString *questListHash;
	NSMutableDictionary *gameMediaList;
	NSMutableDictionary *gameItemList;
	NSMutableDictionary *gameNodeList;
	NSMutableDictionary *gameNpcList;
    NSMutableDictionary *gameWebPageList;
    NSMutableDictionary *gamePanoramicList;
    NSMutableDictionary *gameNoteList;
    NSMutableDictionary *playerNoteList;
    NSMutableArray *gameTagList;


    NSArray *gameTabList;
    NSArray *defaultGameTabList;

    UIProgressView *progressBar;

	//Training Flags
	BOOL hasSeenNearbyTabTutorial;
	BOOL hasSeenQuestsTabTutorial;
	BOOL hasSeenMapTabTutorial;
	BOOL hasSeenInventoryTabTutorial;
    BOOL profilePic,tabsReady,hidePlayers,isGameNoteList;
    
    //CORE Data
    NSManagedObjectModel *managedObjectModel;
    NSManagedObjectContext *managedObjectContext;	    
    NSPersistentStoreCoordinator *persistentStoreCoordinator;
    UploadMan *uploadManager;
}


@property(nonatomic) NSURL *serverURL;
@property(readwrite) BOOL loggedIn;
@property(readwrite) BOOL showGamesInDevelopment;
@property(readwrite) BOOL showPlayerOnMap;

@property(readwrite) BOOL profilePic;

@property(readwrite) BOOL hidePlayers;
@property(readwrite) BOOL isGameNoteList;



@property(nonatomic) NSString *userName;
@property(nonatomic) NSString *password;
@property(readwrite) int playerId;

@property(nonatomic) Game *currentGame;

@property(nonatomic) NSMutableArray *gameList;
@property(nonatomic) NSMutableArray *recentGameList;	
@property(nonatomic) NSMutableArray *locationList;
@property(nonatomic) NSString *locationListHash;
@property(nonatomic) NSMutableArray *playerList;
@property(nonatomic) NSMutableDictionary *questList;
@property(nonatomic) NSString *questListHash;
@property(nonatomic) NSMutableArray *nearbyLocationsList;	
@property(nonatomic) CLLocation *playerLocation;
@property(nonatomic) NSString *inventoryHash;
@property(nonatomic) NSString *playerNoteListHash;
@property(nonatomic) NSString *gameNoteListHash;

@property(nonatomic) NSMutableDictionary *inventory;
@property(nonatomic) NSMutableDictionary *attributes;
@property(nonatomic) NSMutableDictionary *gameNoteList;
@property(nonatomic) NSMutableDictionary *playerNoteList;
@property(nonatomic) NSMutableArray *gameTagList;



@property(nonatomic) NSMutableDictionary *gameMediaList;
@property(nonatomic) NSMutableDictionary *gameItemList;
@property(nonatomic) NSMutableDictionary *gameNodeList;
@property(nonatomic) NSArray *gameTabList;
@property(nonatomic) NSArray *defaultGameTabList;


@property(nonatomic) NSMutableDictionary *gameNpcList;
@property(nonatomic) NSMutableDictionary *gameWebPageList;

@property(nonatomic) NSMutableDictionary *gamePanoramicList;


@property(nonatomic) UIAlertView *networkAlert;
@property(nonatomic)UIProgressView *progressBar;

//Training Flags
@property(readwrite) BOOL hasSeenNearbyTabTutorial;
@property(readwrite) BOOL hasSeenQuestsTabTutorial;
@property(readwrite) BOOL hasSeenMapTabTutorial;
@property(readwrite) BOOL hasSeenInventoryTabTutorial;
@property(readwrite) BOOL tabsReady;

// CORE Data
@property (nonatomic, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property(nonatomic) UploadMan *uploadManager;


+ (AppModel *)sharedAppModel;

- (id)init;
- (void)setPlayerLocation:(CLLocation *) newLocation;	
- (void)loadUserDefaults;
- (void)clearUserDefaults;
- (void)saveUserDefaults;
- (void)saveCOREData;
- (void)initUserDefaults;
- (void)clearGameLists;
- (void)modifyQuantity: (int)quantityModifier forLocationId: (int)locationId;
- (void)removeItemFromInventory: (Item*)item qtyToRemove:(int)qty;

- (Media *)mediaForMediaId:(int)mId;
- (Item *)itemForItemId: (int)mId;
- (Node *)nodeForNodeId: (int)mId;
- (Npc *)npcForNpcId: (int)mId;
- (WebPage *)webPageForWebPageID: (int)mId;
- (Panoramic *)panoramicForPanoramicId: (int)mId;
- (Note *)noteForNoteId:(int)mId playerListYesGameListNo:(BOOL)playerorGame;

@end
