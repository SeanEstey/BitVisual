//
//  BitVisualAppDelegate.m
//  BitVisual
//
//  Created by Sean Estey on 1/18/2014.
//  Copyright (c) 2014 Sean Estey. All rights reserved.
//

#import "BVViewController.h"
#import "BVAppDelegate.h"
#import "BVPriceGraph.h"

@implementation BVAppDelegate

-(BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    [self.window makeKeyAndVisible];
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
    
    BVViewController* tvc = [[BVViewController alloc] init];
    NSData *data = [[NSUserDefaults standardUserDefaults] objectForKey:@"tvc"];
    BVViewController *stored_tvc = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    
    if(stored_tvc != nil)
    {
        tvc.symbol = stored_tvc.symbol;
        tvc.period = stored_tvc.period;
        tvc.theme_index = stored_tvc.theme_index;
        tvc.exchange = stored_tvc.exchange;
        tvc.currency = stored_tvc.currency;
    }
    
    self.window.rootViewController = tvc;
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     BVViewController* tvc = (BVViewController*)self.window.rootViewController;
    [tvc goInactive];
    
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    
    BVViewController* tvc = (BVViewController*)self.window.rootViewController;
    [tvc goInactive];
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:tvc];
    [[NSUserDefaults standardUserDefaults] setObject:data forKey:@"tvc"];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    
}

-(void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    
    BVViewController* bvvc = (BVViewController*)self.window.rootViewController;
    if(bvvc.priceGraph.connection == nil)
    {
        [bvvc viewBecameActiveAgain];
    //    [self.window.rootViewController viewDidLoad];
    }
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    
    BVViewController* tvc = (BVViewController*)self.window.rootViewController;
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:tvc];
    [[NSUserDefaults standardUserDefaults] setObject:data forKey:@"tvc"];
}

/*
- (void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    BVViewController* tvc = (BVViewController*)self.window.rootViewController;

    NSLog(@"Fetched background price");
 //   tvc.priceGraph.statusCaptionLabel.hidden = false;
  //  tvc.priceGraph.statusCaptionLabel.text = @"Fetched in background";
    
    [tvc getMarketPrices:YES];

    if(tvc != nil)
    {
        if(tvc.marketPrices[tvc.symbol] != nil)
        {
            NSNumber* price = (NSNumber*)tvc.marketPrices[tvc.symbol];
            [UIApplication sharedApplication].applicationIconBadgeNumber = [price intValue];
        }
    }
    
    completionHandler(UIBackgroundFetchResultNewData);
}*/

@end
