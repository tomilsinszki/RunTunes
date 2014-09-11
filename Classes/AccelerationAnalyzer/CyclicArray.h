#import <Foundation/Foundation.h>

@interface CyclicArray : NSObject {
	NSMutableArray * objects;	// Objects stored
	NSUInteger nextIndex;		// Index for next added object in array
	NSUInteger size;			// Number of objects stored
}

- (id)init;

- (id)initWithSize: (NSUInteger)_size;

- (NSUInteger)indexFor: (NSInteger)_index;

- (void)addObject: (id)object;

- (id)getObjectForIndex: (NSInteger)_index;

- (id)getLatestObject;

- (NSUInteger)count;

- (NSArray *)getRecentlyAddedObjects: (NSUInteger)numberObjects;

@end
