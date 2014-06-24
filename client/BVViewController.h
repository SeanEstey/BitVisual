//  BVViewController.h
//  BitVisual
//
//  Created by Sean Estey on 1/18/2014.
//  Copyright (c) 2014 Sean Estey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "BVPriceGraph.h"
#import "BVMenu.h"


typedef enum DateType : NSUInteger
{
    unixTime,
    stringTime,
} DateType;

typedef enum ConnectionType: NSUInteger {
	MARKET_DATA,
	HISTORY_DATA
} ConnectionType;

@interface ConnectionData: NSObject
	@property (strong, nonatomic) NSURLConnection* connection;
	@property (strong, nonatomic) NSMutableData* data;
	@property (nonatomic) ConnectionType type;
@end

@interface BVViewController : UIViewController <NSURLConnectionDelegate, BVMenuDelegate, UIPickerViewDataSource,UIPickerViewDelegate, NSCoding>

@property (strong, nonatomic) NSMutableArray* connections;
@property (strong, nonatomic) IBOutlet UILabel* priceLabel;
@property (strong, nonatomic) IBOutlet UILabel* priceChangeLabel;
@property (strong, nonatomic) IBOutlet UILabel* timeLabel;
@property (strong, nonatomic) IBOutlet UILabel* volumeLabel;
@property (strong, nonatomic) IBOutlet UILabel* priceDeltaLabel;
@property (strong, nonatomic) IBOutlet BVMenu* currenciesMenu;
@property (strong, nonatomic) IBOutlet BVMenu* timeSpanMenu;
@property (strong, nonatomic) IBOutlet BVMenu* exchangesMenu;
@property (strong, nonatomic) IBOutlet BVMenu* themesMenu;
@property (strong, nonatomic) IBOutlet UIButton* exchangeButton;
@property (strong, nonatomic) IBOutlet UIButton* currencyButton;
@property (strong, nonatomic) IBOutlet UIButton* timeSpanButton;
@property (strong, nonatomic) IBOutlet UIButton* themesButton;
@property (strong, nonatomic) IBOutlet UIButton* retryConnectionButton;
@property (strong, nonatomic) UIActivityIndicatorView* loadSpinner;
@property (strong, nonatomic) UIImageView *wallpaperImageView;
@property (strong, nonatomic) UIToolbar *toolbar;
@property (strong, nonatomic) IBOutlet UIPickerView *pickerView;
@property (strong, nonatomic) IBOutlet UIPickerView *pickerViewLbl;
@property (strong, nonatomic) NSMutableDictionary* marketPrices;
@property (strong, nonatomic) NSMutableDictionary* marketTradeTimes;
@property (strong, nonatomic) NSDictionary* exchangeSymbols;
@property (strong, nonatomic) NSDictionary* periodSymbols;
@property (strong, nonatomic) NSDictionary* currencyUnicodes;
@property (strong, nonatomic) NSDictionary* humanReadablePeriodList;
@property (strong, nonatomic) NSArray* secondsInPeriod;
@property (strong, nonatomic) NSMutableDictionary* cachedData;
@property (strong, nonatomic) NSMutableArray* exchangesArray;
@property (strong, nonatomic) NSMutableArray* currenciesArray;
@property (strong, nonatomic) NSTimer* marketDataTimer;
@property (strong, nonatomic) NSTimer* graphDataTimer;
@property (strong, nonatomic) NSString* symbol;
@property (strong, nonatomic) NSString* currency;
@property (strong, nonatomic) NSString* exchange;
@property (strong, nonatomic) NSNumber* lastTickerUpdate;
@property (nonatomic) TimePeriod period;
@property (nonatomic) NSTimeInterval lastQueriedStartTime;
@property (nonatomic) NSTimeInterval lastQueriedEndTime;
@property (nonatomic) int theme_index;
@property (nonatomic) bool background_mode;
@property (strong, nonatomic) BVPriceGraph* priceGraph;
@property (strong, nonatomic) UIColor* themeColor;

-(void)initialize;
-(void)goInactive;
-(void)changeExchangeTo:(NSString*)s;
-(void)changeCurrencyTo:(NSString*)c;
-(NSArray*)getSortedExchangesForCurrency:(NSString*)c;
-(void)changeTimePeriodTo:(enum TimePeriod)p;
-(void)updateView;
-(void)checkTickerTimer:(NSTimer*)timer;
-(void)checkGraphTimer;
-(void)getMarketPrices:(bool)in_background;
-(void)setTheme:(int)index;
-(void)viewBecameActiveAgain;
-(void)setThemeColor:(UIColor*)color;
-(IBAction)toggleExchangesMenu:(id)sender;
-(IBAction)toggleCurrenciesMenu:(id)sender;
-(IBAction)toggleTimeSpanMenu:(id)sender;
-(void)connection:(NSURLConnection *)c didReceiveResponse:(NSURLResponse *)response;
-(void)connection:(NSURLConnection *)c didReceiveData:(NSData *)data;
-(void)connection:(NSURLConnection *)c didFailWithError:(NSError *)error;
-(void)connectionDidFinishLoading:(NSURLConnection *)c;
-(IBAction)retryConnection:(id)sender;

@end
