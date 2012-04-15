//
//  Location.m
//  ARIS
//
//  Created by David Gagnon on 2/26/09.
//  Copyright 2009 University of Wisconsin - Madison. All rights reserved.
//

#import "Location.h"
#import "ARISAppDelegate.h"
#import "AppModel.h"
#import "Item.h"
#import "Node.h"
#import "Npc.h"
#import "Note.h"


@implementation Location

@synthesize locationId;
@synthesize name;
@synthesize iconMediaId;
@synthesize location;
@synthesize error;
@synthesize object;
@synthesize objectType;
@synthesize objectId;
@synthesize hidden;
@synthesize forcedDisplay;
@synthesize allowsQuickTravel;
@synthesize qty,delegate;

-(nearbyObjectKind) kind {
	nearbyObjectKind returnValue = NearbyObjectNil;
	if ([self.objectType isEqualToString:@"Node"]) returnValue = NearbyObjectNode;
	if ([self.objectType isEqualToString:@"Npc"]) returnValue = NearbyObjectNPC;
	if ([self.objectType isEqualToString:@"Item"]) returnValue = NearbyObjectItem;
	if ([self.objectType isEqualToString:@"Player"]) returnValue = NearbyObjectPlayer;
    if ([self.objectType isEqualToString:@"WebPage"]) returnValue = NearbyObjectWebPage;
    if ([self.objectType isEqualToString:@"PlayerNote"]) returnValue = NearbyObjectNote;
    if ([self.objectType isEqualToString:@"AugBubble"]) returnValue = NearbyObjectPanoramic;
	return returnValue;
}

- (int) iconMediaId{
	if (iconMediaId != 0) return iconMediaId;
	
	NSObject<NearbyObjectProtocol> *o = [self object];
	return [o iconMediaId];
}

- (NSObject<NearbyObjectProtocol>*)object {
	
	if (self.kind == NearbyObjectItem) {
		Item *item = [[AppModel sharedAppModel] itemForItemId:objectId]; 		
		item.locationId = self.locationId;
		item.qty = self.qty;
		return item;
	}
	
	if (self.kind == NearbyObjectNode) {
		return [[AppModel sharedAppModel] nodeForNodeId: objectId]; 
	}
    if (self.kind == NearbyObjectWebPage) {
		return [[AppModel sharedAppModel] webPageForWebPageID: objectId]; 
	}
    if (self.kind == NearbyObjectPanoramic) {
		return [[AppModel sharedAppModel] panoramicForPanoramicId: objectId]; 
	}
    if (self.kind == NearbyObjectNote) {
        if([[AppModel sharedAppModel] noteForNoteId:objectId playerListYesGameListNo:NO])
            return  [[AppModel sharedAppModel] noteForNoteId:objectId playerListYesGameListNo:NO];
        else return  [[AppModel sharedAppModel] noteForNoteId:objectId playerListYesGameListNo:YES];
    }
	if (self.kind == NearbyObjectNPC) {
		return [[AppModel sharedAppModel] npcForNpcId: objectId]; 
	}
	else return nil;
	
}

- (void)display {
	[self.object display];
}


@end