//
//  AppModel.h
//  ARIS
//
//  Created by Ben Longoria on 2/17/09.
//  Copyright 2009 University of Wisconsin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CLLocation.h>
#import <CoreMotion/CoreMotion.h>
#import <CoreData/CoreData.h>
#import "Game.h"
#import "Location.h"
#import "Item.h"
#import "Node.h"
#import "Npc.h"
#import "Media.h"
#import "WebPage.h"
#import "Panoramic.h"
#import "Note.h"
#import "MediaCache.h"
#import "UploadMan.h"
#import "Overlay.h"

extern NSDictionary *InventoryElements;

@interface AppModel : NSObject <UIAccelerometerDelegate>{
	NSUserDefaults *defaults;
	NSURL *serverURL;
    BOOL showGamesInDevelopment;
    BOOL showPlayerOnMap;
    BOOL museumMode;
    BOOL skipGameDetails;
    BOOL inGame;
	Game *currentGame;
	UIAlertView *networkAlert;
    
    CMMotionManager *motionManager;
	
	BOOL loggedIn;
	int playerId;
	int fallbackGameId;
    int playerMediaId;
	NSString *groupName;
	int groupGame;
	NSString *userName;
	NSString *displayName;
	NSString *password;
	CLLocation *playerLocation;

    NSMutableArray *singleGameList;
	NSMutableArray *nearbyGameList;
    NSMutableArray *searchGameList;
    NSMutableArray *popularGameList;
    NSMutableArray *recentGamelist;
	NSMutableArray *locationList;
	NSMutableArray *playerList;
	NSMutableArray *nearbyLocationsList;
	NSMutableDictionary *inventory;
    NSMutableDictionary *attributes;

	NSString *inventoryHash,*playerNoteListHash,*gameNoteListHash, *overlayListHash; 
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
    NSMutableArray *overlayList;

    NSArray *gameTabList;
    NSArray *defaultGameTabList;

    UIProgressView *progressBar;
    
    BOOL overlayIsVisible;

    //Accelerometer Data
    float averageAccelerometerReadingX;
    float averageAccelerometerReadingY;
    float averageAccelerometerReadingZ;
    
	//Training Flags
	BOOL hasSeenNearbyTabTutorial;
	BOOL hasSeenQuestsTabTutorial;
	BOOL hasSeenMapTabTutorial;
	BOOL hasSeenInventoryTabTutorial;
    BOOL profilePic,tabsReady,hidePlayers,isGameNoteList;
    BOOL hasReceivedMediaList;

    //CORE Data
    NSManagedObjectModel *managedObjectModel;
    NSManagedObjectContext *managedObjectContext;	    
    NSPersistentStoreCoordinator *persistentStoreCoordinator;
    UploadMan *uploadManager;
    MediaCache *mediaCache;
}


@property(nonatomic) NSURL *serverURL;
@property(readwrite) BOOL loggedIn;
@property(readwrite) BOOL showGamesInDevelopment;
@property(readwrite) BOOL showPlayerOnMap;
@property(readwrite) BOOL museumMode;
@property(readwrite) BOOL skipGameDetails;
@property(readwrite) BOOL inGame;

@property(nonatomic, retain) CMMotionManager *motionManager;

@property(readwrite) BOOL profilePic;

@property(readwrite) BOOL hidePlayers;
@property(readwrite) BOOL isGameNoteList;

@property(readwrite) BOOL hasReceivedMediaList;

@property(readwrite) BOOL overlayIsVisible;

@property(readwrite) float averageAccelerometerReadingX;
@property(readwrite) float averageAccelerometerReadingY;
@property(readwrite) float averageAccelerometerReadingZ;

@property(nonatomic) NSString *userName;
@property(nonatomic) NSString *groupName;
@property(readwrite) int groupGame;
@property(nonatomic) NSString *displayName;
@property(nonatomic) NSString *password;
@property(readwrite) int playerId;
@property(readwrite) int fallbackGameId;//Used only to recover from crashes
@property(readwrite) int playerMediaId;

@property(nonatomic) Game *currentGame;

@property(nonatomic) NSURL *fileToDeleteURL;
@property(nonatomic) NSMutableArray *singleGameList;
@property(nonatomic) NSMutableArray *nearbyGameList;
@property(nonatomic) NSMutableArray *searchGameList;
@property(nonatomic) NSMutableArray *popularGameList;
@property(nonatomic) NSMutableArray *recentGameList;	
@property(nonatomic) NSMutableArray *locationList;
@property(nonatomic) NSMutableArray *playerList;
@property(nonatomic) NSMutableDictionary *questList;
@property(nonatomic) NSString *questListHash;
@property(nonatomic) NSMutableArray *nearbyLocationsList;	
@property(nonatomic) CLLocation *playerLocation;
@property(nonatomic) NSString *inventoryHash;
@property(nonatomic) NSString *playerNoteListHash;
@property(nonatomic) NSString *gameNoteListHash;
@property(nonatomic) NSString *overlayListHash;

@property(nonatomic) NSMutableDictionary *inventory;
@property(nonatomic) NSMutableDictionary *attributes;
@property(nonatomic) NSMutableDictionary *gameNoteList;
@property(nonatomic) NSMutableDictionary *playerNoteList;
@property(nonatomic) NSMutableArray *gameTagList;
@property(nonatomic) NSMutableArray *overlayList;


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
@property(nonatomic) MediaCache *mediaCache;





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
- (Location *)locationForLocationId: (int)lId;

@end