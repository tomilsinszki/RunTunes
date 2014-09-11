#import "CyclicArray.h"

/**
 * CyclicArray can only hold a certain number of objects.
 * After CyclicArray is full, oldest objects are replaced by new ones.
 */
@implementation CyclicArray

- (id)init {
	if (( self = [super init] )) {
		size = 100;
		nextIndex = 0;
		objects = [[NSMutableArray alloc] initWithCapacity:size];
	}
	return self;
}

/**
 * Initializer, that will set the most number of objects that can be stored.
 *
 * Last updated: April 2010
 *
 * @param _size Most number of objects that can be stored.
 * @return CyclicArray instance.
 */
- (id)initWithSize: (NSUInteger)_size {
	if (( self = [super init] )) {
		size = _size;
		nextIndex = 0;
		objects = [[NSMutableArray alloc] initWithCapacity:size];
	}
	return self;
}

/**
 * Calculates the inbounds index for a given number.
 *
 * Last updated: April 2010
 *
 * @param _index Number to make inbounds.
 * @return Inbounds index.
 */
- (NSUInteger)indexFor: (NSInteger)_index {
	if ( _index < 0 ) {
		_index = size + ( (NSInteger)_index % (NSInteger)size );
	}
	
	return ( _index % size );
}

/**
 * Add new object to array. Replace oldest object with new object if array is full.
 *
 * Last updated: April 2010
 *
 * @param object New object to add to CyclicArray.
 */
- (void)addObject: (id)object {
	nextIndex = [self indexFor:nextIndex];
	
	if ( [objects count] < size ) {
		[objects insertObject:object atIndex:nextIndex];
	}
	else {
		[objects replaceObjectAtIndex:nextIndex withObject:object];
	}
	
	nextIndex = [self indexFor:(nextIndex+1)];
}

/**
 * Get object for index.
 *
 * Last updated: April 2010
 *
 * @param _index Index to get object for.
 * @return Object returned from index.
 */
- (id)getObjectForIndex: (NSInteger)_index {
	_index = [self indexFor:_index];
	return [objects objectAtIndex:_index];
}

/**
 * Gets the most recently added object.
 *
 * Last updated: April 2010
 *
 * @return Most recently added object.
 */
- (id)getLatestObject {
	NSUInteger _index = [self indexFor:(nextIndex-1)];
	
	return [self getObjectForIndex:_index];
}

/**
 * Gets number of stored objects.
 *
 * Last updated: April 2010
 *
 * @return Number of stored objects.
 */
- (NSUInteger)count {
	return [objects count];
}

/**
 * Gets a number of recently added objects.
 *
 * Last updated: August 2010
 *
 * @param numberObjects Number of objects to return.
 * @return Recently added objects.
 */
- (NSArray *)getRecentlyAddedObjects: (NSUInteger)numberObjects {
	NSMutableArray * recentlyAddedObjects = [[NSMutableArray alloc] initWithCapacity:0];
	
	NSInteger lastCyclicIndexToInclude = nextIndex-1;
	NSInteger firstCyclicIndexToInclude = lastCyclicIndexToInclude - numberObjects + 1;
	
	for ( NSInteger cyclicIndex=firstCyclicIndexToInclude; cyclicIndex<=lastCyclicIndexToInclude; ++cyclicIndex ) {
		NSUInteger objectIndex = [self indexFor:cyclicIndex];
		[recentlyAddedObjects addObject:[self getObjectForIndex:objectIndex]];
	}
	
	return recentlyAddedObjects;
}

@end
