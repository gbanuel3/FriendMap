//
//  LocationManager.m
//  FriendMap
//
//  Created by Gildardo Banuelos on 7/22/21.
//

#import <UIKit/UIKit.h>
#import "LocationManager.h"
#import <Parse/Parse.h>


@interface LocationManager() <CLLocationManagerDelegate>

@end

@implementation LocationManager

+ (id)sharedManager {
    static id sharedMyModel = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        sharedMyModel = [[self alloc] init];
    });
    
    return sharedMyModel;
}


#pragma mark - CLLocationManager

- (void)startMonitoringLocation {
    if (_anotherLocationManager)
        [_anotherLocationManager startUpdatingLocation];
    
    self.anotherLocationManager = [[CLLocationManager alloc]init];
    _anotherLocationManager.delegate = self;
    _anotherLocationManager.distanceFilter = kCLDistanceFilterNone;
    _anotherLocationManager.desiredAccuracy = kCLLocationAccuracyBest;
    _anotherLocationManager.activityType = CLActivityTypeOtherNavigation;
    [_anotherLocationManager setPausesLocationUpdatesAutomatically:NO];
    [_anotherLocationManager setAllowsBackgroundLocationUpdates:YES];
    
    if(IS_OS_8_OR_LATER){
        [_anotherLocationManager requestAlwaysAuthorization];
    }
    [_anotherLocationManager startUpdatingLocation];
}

- (void)restartMonitoringLocation {
    [_anotherLocationManager stopUpdatingLocation];
    
    if(IS_OS_8_OR_LATER){
        [_anotherLocationManager requestAlwaysAuthorization];
    }
    [_anotherLocationManager startUpdatingLocation];
}


#pragma mark - CLLocationManager Delegate

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations{
    CLLocation *location = [locations lastObject];

    NSDate *now = [NSDate date];
    NSTimeInterval interval = self.lastTimestamp ? [now timeIntervalSinceDate:self.lastTimestamp] : 0;
    if (!self.lastTimestamp || interval >= 1 * 15){
        self.lastTimestamp = now;
        PFUser *user = [PFUser currentUser];
        [user setValue:[NSNumber numberWithFloat:location.coordinate.latitude] forKey:@"lat"];
        [user setValue:[NSNumber numberWithFloat:location.coordinate.longitude] forKey:@"lon"];
        [user saveInBackground];
    }
    [self addLocationToPList:_afterResume];
}



#pragma mark - Plist helper methods

- (NSString *)appState{
    UIApplication* application = [UIApplication sharedApplication];
    NSString * appState;
    if([application applicationState]==UIApplicationStateActive)
        appState = @"UIApplicationStateActive";
    if([application applicationState]==UIApplicationStateBackground)
        appState = @"UIApplicationStateBackground";
    if([application applicationState]==UIApplicationStateInactive)
        appState = @"UIApplicationStateInactive";
    return appState;
}

- (void)addResumeLocationToPList{
    NSString * appState = [self appState];
    self.myLocationDictInPlist = [[NSMutableDictionary alloc] init];
    [_myLocationDictInPlist setObject:@"UIApplicationLaunchOptionsLocationKey" forKey:@"Resume"];
    [_myLocationDictInPlist setObject:appState forKey:@"AppState"];
    [_myLocationDictInPlist setObject:[NSDate date] forKey:@"Time"];
    [self saveLocationsToPlist];
}



- (void)addLocationToPList:(BOOL)fromResume {
    
    NSString * appState = [self appState];
    self.myLocationDictInPlist = [[NSMutableDictionary alloc]init];
    [_myLocationDictInPlist setObject:[NSNumber numberWithDouble:self.myLocation.latitude] forKey:@"Latitude"];
    [_myLocationDictInPlist setObject:[NSNumber numberWithDouble:self.myLocation.longitude] forKey:@"Longitude"];
    [_myLocationDictInPlist setObject:[NSNumber numberWithDouble:self.myLocationAccuracy] forKey:@"Accuracy"];
    
    [_myLocationDictInPlist setObject:appState forKey:@"AppState"];
    
    if (fromResume) {
        [_myLocationDictInPlist setObject:@"YES" forKey:@"AddFromResume"];
    } else {
        [_myLocationDictInPlist setObject:@"NO" forKey:@"AddFromResume"];
    }
    
    [_myLocationDictInPlist setObject:[NSDate date] forKey:@"Time"];
    
    [self saveLocationsToPlist];
}

- (void)addApplicationStatusToPList:(NSString*)applicationStatus {
    NSString * appState = [self appState];
    self.myLocationDictInPlist = [[NSMutableDictionary alloc]init];
    [_myLocationDictInPlist setObject:applicationStatus forKey:@"applicationStatus"];
    [_myLocationDictInPlist setObject:appState forKey:@"AppState"];
    [_myLocationDictInPlist setObject:[NSDate date] forKey:@"Time"];
    [self saveLocationsToPlist];
}

- (void)saveLocationsToPlist {
    NSString *plistName = [NSString stringWithFormat:@"LocationArray.plist"];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docDir = [paths objectAtIndex:0];
    NSString *fullPath = [NSString stringWithFormat:@"%@/%@", docDir, plistName];
    NSMutableDictionary *savedProfile = [[NSMutableDictionary alloc] initWithContentsOfFile:fullPath];
    if (!savedProfile){
        savedProfile = [[NSMutableDictionary alloc] init];
        self.myLocationArrayInPlist = [[NSMutableArray alloc]init];
    }else{
        self.myLocationArrayInPlist = [savedProfile objectForKey:@"LocationArray"];
    }
    
    if(_myLocationDictInPlist){
        [_myLocationArrayInPlist addObject:_myLocationDictInPlist];
        [savedProfile setObject:_myLocationArrayInPlist forKey:@"LocationArray"];
    }
    
}


@end
