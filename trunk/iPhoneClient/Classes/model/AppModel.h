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
}


@property(nonatomic, retain) NSURL *serverURL;
@property(readwrite) BOOL loggedIn;
@property(readwrite) BOOL showGamesInDevelopment;
@property(readwrite) BOOL showPlayerOnMap;

@property(readwrite) BOOL profilePic;

@property(readwrite) BOOL hidePlayers;
@property(readwrite) BOOL isGameNoteList;



@property(nonatomic, retain) NSString *userName;
@property(nonatomic, retain) NSString *password;
@property(readwrite) int playerId;

@property(nonatomic,retain) Game *currentGame;

@property(nonatomic, retain) NSMutableArray *gameList;
@property(nonatomic, retain) NSMutableArray *recentGameList;	
@property(nonatomic, retain) NSMutableArray *locationList;
@property(nonatomic, retain) NSString *locationListHash;
@property(nonatomic, retain) NSMutableArray *playerList;
@property(nonatomic, retain) NSMutableDictionary *questList;
@property(nonatomic, retain) NSString *questListHash;
@property(nonatomic, retain) NSMutableArray *nearbyLocationsList;	
@property(nonatomic, retain) CLLocation *playerLocation;
@property(nonatomic, retain) NSString *inventoryHash;
@property(nonatomic, retain) NSString *playerNoteListHash;
@property(nonatomic, retain) NSString *gameNoteListHash;

@property(nonatomic, retain) NSMutableDictionary *inventory;
@property(nonatomic, retain) NSMutableDictionary *attributes;
@property(nonatomic, retain) NSMutableDictionary *gameNoteList;
@property(nonatomic, retain) NSMutableDictionary *playerNoteList;
@property(nonatomic, retain) NSMutableArray *gameTagList;



@property(nonatomic, retain) NSMutableDictionary *gameMediaList;
@property(nonatomic, retain) NSMutableDictionary *gameItemList;
@property(nonatomic, retain) NSMutableDictionary *gameNodeList;
@property(nonatomic, retain) NSArray *gameTabList;
@property(nonatomic, retain) NSArray *defaultGameTabList;


@property(nonatomic, retain) NSMutableDictionary *gameNpcList;
@property(nonatomic, retain) NSMutableDictionary *gameWebPageList;

@property(nonatomic, retain) NSMutableDictionary *gamePanoramicList;


@property(nonatomic, retain) UIAlertView *networkAlert;
@property(nonatomic,retain)UIProgressView *progressBar;

//Training Flags
@property(readwrite) BOOL hasSeenNearbyTabTutorial;
@property(readwrite) BOOL hasSeenQuestsTabTutorial;
@property(readwrite) BOOL hasSeenMapTabTutorial;
@property(readwrite) BOOL hasSeenInventoryTabTutorial;
@property(readwrite) BOOL tabsReady;

// CORE Data
@property (nonatomic, retain, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, retain, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;


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
