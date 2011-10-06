//
//  TracklistViewController.h
//  RunTunes
//
//  Created by Tamás Ilsinszki on 9/30/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>


@interface TracklistViewController : UIViewController <UITableViewDelegate, UITableViewDataSource> {
    NSManagedObjectContext *managedObjectContext;
    NSArray *listData;
}

@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain) NSArray *listData;

@end
