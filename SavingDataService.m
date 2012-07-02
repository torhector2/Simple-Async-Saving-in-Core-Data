//
//  SavingDataService.h
//  IOSBoilerplate
//
//  Copyright (c) 2012 Héctor Rodríguez Forniés
//  
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the "Software"), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//  
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//  
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.
// 


#import "SavingDataService.h"


@implementation SavingDataService

@synthesize child = child_;
@synthesize parent = parent_;

@synthesize managedObjectModel = __managedObjectModel;
@synthesize persistentStoreCoordinator = __persistentStoreCoordinator;


@synthesize storeURLString = storeURLString_;
@synthesize modelURLString = modelURLString_;

//Creates and instanciates the Class
+ (id)sharedInstance {
    
    static dispatch_once_t once;
    
    static SavingDataService *sharedInstance;
    
    dispatch_once(&once, ^ { 
        
        sharedInstance = [[self alloc] init]; 
    
    });
    
    return sharedInstance;
    
}

-(id)init
{
    if (self = [super init])
    {
        // Initialization nested contexts
        
        child_ = [[NSManagedObjectContext alloc]
                  initWithConcurrencyType:NSMainQueueConcurrencyType];
        
        //The parent context has ConcurrencyType Private Queue to let him perform asyn operation
        parent_ = [[NSManagedObjectContext alloc]
                  initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        
        
        NSPersistentStoreCoordinator *coordinator = self.persistentStoreCoordinator;        
        if (coordinator != nil) {
           
            [parent_ setPersistentStoreCoordinator:coordinator];
        }
        
        
        [child_ setParentContext:parent_];
        
    }
    
    return self;
}





- (void) asyncSavingOfNSManagedObject: (NSManagedObject *) aObject{
    
    NSError *error = nil;
    __block NSError *parentError = nil;
    
    //Commit changes in child MOC (Managed Object Context)
    [self.child save:&error];
    
    if(!error){
        //Save async in the parent MOC (Managed Object Context)
        [self.parent performBlock:^{
            
            [self.parent save:&parentError];
            
            if(parentError){
                
                NSLog(@"%s Error saving parent context", __PRETTY_FUNCTION__);
            }
            
            
        }];
    }else {
        NSLog(@"%s Error saving child context", __PRETTY_FUNCTION__);
    }
    
}

#pragma mark - Core Data stack


// Returns the managed object model for the application.
// If the model doesn't already exist, it is created from the application's model.
- (NSManagedObjectModel *)managedObjectModel
{
    if (__managedObjectModel != nil) {
        return __managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:self.modelURL withExtension:@"momd"];
    __managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return __managedObjectModel;
}



// Returns the persistent store coordinator for the application.
// If the coordinator doesn't already exist, it is created and the application's store added to it.
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (__persistentStoreCoordinator != nil) {
        return __persistentStoreCoordinator;
    }
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:self.storeURL];
    
    NSError *error = nil;
    __persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![__persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }    
    
    return __persistentStoreCoordinator;
}

#pragma mark - Application's Documents directory

// Returns the URL to the application's Documents directory.
- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

@end
