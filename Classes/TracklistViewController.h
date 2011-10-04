//
//  TracklistViewController.h
//  RunTunes
//
//  Created by Tamás Ilsinszki on 9/30/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface TracklistViewController : UIViewController <UITableViewDelegate, UITableViewDataSource> {
    NSArray *listData;
}

@property (nonatomic, retain) NSArray *listData;

@end
