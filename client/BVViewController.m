#import "BVViewController.h"
#import "BVPriceGraph.h"

@implementation ConnectionData
@synthesize data, connection, type;
@end

@implementation BVViewController

@synthesize connections;
@synthesize priceLabel, priceChangeLabel, timeLabel, volumeLabel;
@synthesize marketPrices, marketTradeTimes, cachedData;
@synthesize marketDataTimer, graphDataTimer;
@synthesize currency, exchange, period, symbol;
@synthesize exchangesMenu, currenciesMenu, timeSpanMenu, themesMenu;
@synthesize exchangesArray, currenciesArray, periodSymbols, humanReadablePeriodList, secondsInPeriod;
@synthesize exchangeButton, currencyButton, timeSpanButton, themesButton, retryConnectionButton;
@synthesize priceGraph;
@synthesize exchangeSymbols, currencyUnicodes;
@synthesize lastTickerUpdate;
@synthesize wallpaperImageView;
@synthesize pickerView;
@synthesize themeColor, theme_index;
@synthesize toolbar, loadSpinner;
@synthesize lastQueriedEndTime, lastQueriedStartTime;

NSTimeInterval t1;
NSTimeInterval t2;

-(void)initialize
{
    currencyUnicodes = [NSDictionary dictionaryWithObjectsAndKeys:
                        @"\u20ac",@"EUR", @"\u00a5",@"CNY", @"\u0024",@"CAD",
                        @"\u0024",@"USD", @"\u0024",@"AUD", @"R\u0024",@"BRL",
                        @"CHF",@"CHF", @"kr",@"DKK",@"\u00a3",@"GBP",
                        @"\u0024",@"HKD", @"\u20aa",@"ILS", @"\u00a5",@"JPY",
                        @"kr",@"NOK", @"\u0024",@"NZD", @"z\u0142",@"PLN",
                        @"\u0440",@"RUB", @"kr", @"SEK", @"\u0024",@"SGD",
                        @"\u0e3f",@"THB",
                        nil];
    
    exchangeSymbols = [NSDictionary dictionaryWithObjectsAndKeys:
                       @"CryptoXChange", @"cryptox",
                       @"Bitcoin-24", @"btc24",
                       @"BtcEx", @"btcex",
                       @"BtcTree", @"btctree",
                       @"Justcoin", @"just",
                       @"CoinTrader", @"cotr",
                       @"Bitfinex", @"bitfinex",
                       @"1Coin", @"1coin",
                       @"Hitbtc", @"hitbtc",
                       @"itBit", @"itbit",
                       @"LakeBTC", @"lake",
                       @"BTC China", @"btcn",
                       @"Average", @"btcavg",
                       @"RMBTB", @"rmbtb",
                       @"Kraken", @"kraken",
                       @"Camp BX", @"cbx",
                       @"Bitkonan", @"bitkonan",
                       @"Crypto-Trade", @"crytr",
                       @"The Rock", @"rock",
                       @"Btc-E", @"btce",
                       @"Mercado", @"mrcd",
                       @"WeExchange", @"weex",
                       @"Asia Nexgen", @"anxhk",
                       @"Local Bitcoins", @"localbtc",
                       @"Bitstamp", @"bitstamp",
                       @"VirtEx", @"virtex",
                       nil];
    
    humanReadablePeriodList = [NSDictionary dictionaryWithObjectsAndKeys:
                               @"1 Day", [NSNumber numberWithInt:_1D],
                               @"3 Days", [NSNumber numberWithInt:_3D],
                               @"1 Week", [NSNumber numberWithInt:_1W],
                               @"1 Month", [NSNumber numberWithInt:_1M],
                               @"6 Months", [NSNumber numberWithInt:_6M],
                               @"1 Year", [NSNumber numberWithInt:_1Y],
                               @"2 Years", [NSNumber numberWithInt:_2Y],
                               nil];
    
    periodSymbols = [NSDictionary dictionaryWithObjectsAndKeys:
                     @"1d", [NSNumber numberWithInt:_1D],
                     @"3d", [NSNumber numberWithInt:_3D],
                     @"1w", [NSNumber numberWithInt:_1W],
                     @"1m", [NSNumber numberWithInt:_1M],
                     @"6m", [NSNumber numberWithInt:_6M],
                     @"1y", [NSNumber numberWithInt:_1Y],
                     @"2y", [NSNumber numberWithInt:_2Y],
                     nil];
    
    secondsInPeriod = [NSArray arrayWithObjects:
                       [NSNumber numberWithDouble:86400],
                       [NSNumber numberWithDouble:259200],
                       [NSNumber numberWithDouble:604800],
                       [NSNumber numberWithDouble:2592000],
                       [NSNumber numberWithDouble:15552000],
                       [NSNumber numberWithDouble:31104000],
                       [NSNumber numberWithDouble:62208000],
                       nil];
    
    connections = [[NSMutableArray alloc] init];
    for(int i=0; i<3; i++)
    {
        ConnectionData* cd = [[ConnectionData alloc] init];
        cd.data = [[NSMutableData alloc] init];
        cd.connection = [[NSURLConnection alloc] init];
        cd.type = i;
        [connections addObject:cd];
    }
    
    cachedData = [[NSMutableDictionary alloc] init];
    marketPrices = [[NSMutableDictionary alloc] init];
    marketTradeTimes = [[NSMutableDictionary alloc] init];
    exchangesArray = [[NSMutableArray alloc] init];
    currenciesArray = [NSMutableArray arrayWithObjects:@"USD",@"CAD",@"GBP",@"CNY",@"AUD",@"JPY",@"EUR",@"RUB",@"HKD",@"CHF",@"PLN",nil];
    
    marketDataTimer = [NSTimer scheduledTimerWithTimeInterval:30 target:self selector:@selector(checkTickerTimer:) userInfo:nil repeats:YES];
}

-(id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        [self initialize];
    }
    
    return self;
}

-(id)initWithCoder:(NSCoder*)decoder
{
    if(self = [super initWithCoder:decoder])
    {
        self.symbol = [decoder decodeObjectForKey:@"symbol"];
        self.theme_index = [decoder decodeIntForKey:@"theme"];
        self.period = [decoder decodeIntForKey:@"period"];
        self.exchange = [decoder decodeObjectForKey:@"exchange"];
        self.currency = [decoder decodeObjectForKey:@"currency"];
    }
    
    return self;
}

-(void)goInactive
{
    if( ((ConnectionData*)connections[MARKET_DATA]).connection != nil)
    {
        [((ConnectionData*)connections[MARKET_DATA]).connection cancel];
        ((ConnectionData*)connections[MARKET_DATA]).connection = nil;
    }
    
    if(priceGraph.connection != nil)
    {
        [priceGraph.connection cancel];
        priceGraph.connection  = nil;
    }
}


-(void)encodeWithCoder:(NSCoder *)coder
{
	[coder encodeObject:self.symbol forKey:@"symbol"];
	[coder encodeInt:self.period forKey:@"period"];
	[coder encodeInt:self.theme_index forKey:@"theme"];
    [coder encodeObject:self.exchange forKey:@"exchange"];
    [coder encodeObject:self.currency forKey:@"currency"];
}


-(void)loadView
{
	[super loadView];
    
    // first time running app, no saved settings
    if(symbol == nil)
    {
        self.currency = @"USD";
        self.exchange = @"btcavg";
        self.period = _1M;
        self.symbol = @"btcavgUSD";
        self.theme_index = 3;
    }
    
    
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    
    wallpaperImageView = [[UIImageView alloc]initWithFrame:self.view.bounds];
    wallpaperImageView.layer.opacity = 1.0f;
    [self.view insertSubview:wallpaperImageView atIndex:0];
    [wallpaperImageView setHidden:TRUE];
    
    
    
    self.pickerView.hidden = TRUE;
    NSArray* layers = self.pickerView.layer.sublayers;
    for(id n in layers)
    {
        CALayer* layer = (CALayer*)n;
        layer.hidden = TRUE;
    }
    
    retryConnectionButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [retryConnectionButton addTarget:self action:@selector(retryConnection:) forControlEvents:UIControlEventTouchUpInside];
    retryConnectionButton.titleLabel.font = [UIFont fontWithName:@"Futura" size:18];
    [retryConnectionButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    retryConnectionButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    retryConnectionButton.backgroundColor = [UIColor whiteColor];
    retryConnectionButton.layer.cornerRadius = 10;
    retryConnectionButton.clipsToBounds = YES;
    retryConnectionButton.layer.opacity = 0.75;
    retryConnectionButton.layer.borderWidth = 0.5;
    [retryConnectionButton setTitle:@"Retry" forState:UIControlStateNormal];
     [retryConnectionButton sizeToFit];
    CGRect r = retryConnectionButton.frame;
    r.size.width += 15;
    r.origin.x = self.view.frame.size.width/2 - r.size.width/2;
    r.origin.y = self.view.frame.size.height/2 - 50;
    retryConnectionButton.frame = r;
    [retryConnectionButton setHidden:YES];
    [self.view addSubview:retryConnectionButton];
    
    loadSpinner = [[UIActivityIndicatorView alloc] initWithFrame:r];
    loadSpinner.color = [UIColor blackColor];
    [loadSpinner startAnimating];
    [self.view addSubview:loadSpinner];
    
    currencyButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [currencyButton addTarget:self action:@selector(toggleCurrenciesMenu:) forControlEvents:UIControlEventTouchUpInside];
    currencyButton.frame = CGRectMake(priceLabel.frame.origin.x + priceLabel.frame.size.width, priceLabel.frame.origin.y + 15, 65, 50);
    currencyButton.titleLabel.font = [UIFont fontWithName:@"Futura" size:18];
    [currencyButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    currencyButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    // currencyButton.layer.borderWidth = 1;
    [self.view addSubview:currencyButton];
    
    themesButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [themesButton setBackgroundImage:[UIImage imageNamed:@"gear_black_bg.png"] forState:UIControlStateNormal];
    [themesButton addTarget:self action:@selector(toggleThemesMenu:) forControlEvents:UIControlEventTouchUpInside];
    themesButton.frame = CGRectMake(5,5,35,35);
    [themesButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.view addSubview:themesButton];
    
    int timeSpanBtnWidth = 100;
    int timeSpanBtnHeight = 100;
    timeSpanButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [timeSpanButton addTarget:self action:@selector(toggleTimeSpanMenu:) forControlEvents:UIControlEventTouchUpInside];
    timeSpanButton.frame = CGRectMake((self.view.frame.size.width / 2.0) - (timeSpanBtnWidth / 2.0),
                                      screenBounds.size.height - 100, timeSpanBtnWidth, timeSpanBtnHeight);
    timeSpanButton.titleLabel.font = [UIFont fontWithName:@"Futura" size:18];
    [timeSpanButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    timeSpanButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:timeSpanButton];
 
    CGRect chartFrame = CGRectMake(0, screenBounds.origin.y+(screenBounds.size.height*0.30f), screenBounds.size.width, screenBounds.size.height*0.70f);
    self.priceGraph = [[BVPriceGraph alloc] initWithFrame:chartFrame];
    [self.view insertSubview:priceGraph atIndex:1];
    
    priceGraph.retryConnectionButton = self.retryConnectionButton;
    priceGraph.loadSpinner = self.loadSpinner;
    
    
    
    exchangeButton = [[UIButton alloc] initWithFrame:CGRectMake(80, 5, 100,40)];
    [exchangeButton addTarget:self action:@selector(toggleExchangesMenu:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:exchangeButton];
    if(exchangeSymbols[exchange])
        [exchangeButton setTitle:[NSString stringWithFormat:@"%@ %C", exchangeSymbols[exchange], (unichar)0x25BC] forState:UIControlStateNormal];
    else
        [exchangeButton setTitle:[NSString stringWithFormat:@"%@ %C", exchange, (unichar)0x25BC] forState:UIControlStateNormal];
    
    
    priceLabel = [[UILabel alloc]initWithFrame:CGRectMake(80, 20, 200, 60)];
    priceLabel.text = @"";
    priceLabel.font = [UIFont fontWithName:@"Futura" size:80];
    priceLabel.numberOfLines = 1;
    priceLabel.baselineAdjustment = YES;
    priceLabel.adjustsFontSizeToFitWidth = YES;
    priceLabel.clipsToBounds = YES;
    priceLabel.backgroundColor = [UIColor clearColor];
    priceLabel.textAlignment = NSTextAlignmentCenter;
    UITapGestureRecognizer *priceLabelGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapPriceLabel:)];
    priceLabelGestureRecognizer.numberOfTapsRequired = 1;
    priceLabel.userInteractionEnabled = TRUE;
    [priceLabel addGestureRecognizer:priceLabelGestureRecognizer];
    [self.view insertSubview:priceLabel belowSubview:exchangeButton];
    
    timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(80,100,150,25)];
    [self.view addSubview:timeLabel];
    
    priceChangeLabel = [[UILabel alloc]initWithFrame:CGRectMake(screenBounds.size.width - 50, currencyButton.frame.origin.y+30, 65, 50)];
    priceChangeLabel.text = @"";
    priceChangeLabel.font = [UIFont systemFontOfSize:18];
    priceChangeLabel.numberOfLines = 1;
    priceChangeLabel.baselineAdjustment = YES;
//    priceChangeLabel.layer.borderWidth = 1;
    priceChangeLabel.adjustsFontSizeToFitWidth = YES;
    priceChangeLabel.clipsToBounds = YES;
    priceChangeLabel.backgroundColor = [UIColor clearColor];
    priceChangeLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:priceChangeLabel];
    priceGraph.priceDeltaLabel = priceChangeLabel;
    
    toolbar = [[UIToolbar alloc] init];
    toolbar.frame = self.view.bounds;
    [toolbar setBarStyle:UIBarStyleBlackTranslucent];
    toolbar.layer.opacity = 0.9f;
    toolbar.translucent = YES;
    toolbar.hidden = YES;
    UITapGestureRecognizer *singleTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(escapeMenu:)];
    singleTapGestureRecognizer.numberOfTapsRequired = 1;
    [toolbar addGestureRecognizer:singleTapGestureRecognizer];
    [self.view addSubview:toolbar];
    
 //   self.pickerView = [[UIPickerView alloc] init];
    int pickerHeight = 150;
    CGRect pickerRect = CGRectMake(0, screenBounds.size.height - pickerHeight, screenBounds.size.width, pickerHeight);
    self.pickerView = [[UIPickerView alloc] initWithFrame:pickerRect];
    self.pickerView.dataSource = self;
    self.pickerView.delegate = self;
    self.pickerView.hidden = true;
    [self.view addSubview:pickerView];
    
    [self setTheme:theme_index];
    
   //    [self.view setNeedsDisplay];
 }

-(void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setTheme:theme_index];
    [self getMarketPrices:NO];
    [priceGraph setSymbol:symbol withPeriod:period];
    [loadSpinner setHidden:NO];
    [loadSpinner startAnimating];
    timeLabel.text = @"";
}

-(void)viewBecameActiveAgain
{
    [self getMarketPrices:NO];
    [self checkGraphTimer];
}

-(void)setThemeColor:(UIColor*)color
{
	themeColor = color;
	priceLabel.textColor = themeColor;
    priceChangeLabel.textColor = themeColor;
    [currencyButton setTitleColor:themeColor forState:UIControlStateNormal];
    [exchangeButton setTitleColor:themeColor forState:UIControlStateNormal];
    timeLabel.textColor = themeColor;
    [timeSpanButton setTitleColor:themeColor forState:UIControlStateNormal];
    loadSpinner.color = color;
}

-(void)setTheme:(int)index
{
    theme_index = index;
    
    NSArray* themeFilenames = [NSArray arrayWithObjects:
        @"bw_dock.jpg",
        @"bw_ocean.jpg",
        @"bw_wet_wood.jpg",
        @"blue_circles_free.jpg",
        @"abstract_smoke_free_blur.jpg",
        @"sparkling_sea_free_small.jpg",
        @"red_gradient.jpg",
        @"nebula.jpg",
        @"wild_flowers_free.jpg",
        @"wheat_free_small.jpg",
        nil];
    
    if(theme_index > [themeFilenames count] -1)
        theme_index = [themeFilenames count] - 1;
    
    priceGraph.gradientLayer.opacity = 0.6f;
    NSMutableArray *colors = [NSMutableArray array];
    [colors addObject:(id)[UIColor colorWithRed:0.0 green:0.6 blue:0.8 alpha:1.0].CGColor];
    [colors addObject:(id)[UIColor colorWithRed:0.0 green:0.6 blue:0.8 alpha:1.0].CGColor];
    priceGraph.gradientLayer.colors = colors;

    [wallpaperImageView setImage:[UIImage imageNamed:themeFilenames[theme_index]]];
    
   
    if(index == 0) // B&W Dock
    {
	    [self setThemeColor:[UIColor whiteColor]];
        [priceGraph setThemeColor:[UIColor whiteColor]];
    }
    else if(index == 1) // B&W Ocean
    {
		[self setThemeColor:[UIColor darkGrayColor]];
		[priceGraph setThemeColor:[UIColor whiteColor]];
    }
    else if(index == 2) // B&W Wet Wood
    {
    	[self setThemeColor:[UIColor whiteColor]];
		[priceGraph setThemeColor:[UIColor whiteColor]];
    }
    else if(index == 3) // blue_circles
    {
        [self setThemeColor:[UIColor whiteColor]];
   		[priceGraph setThemeColor:[UIColor whiteColor]];
          NSMutableArray *colors = [NSMutableArray array];
        [colors addObject:(id)[UIColor colorWithRed:0.0 green:0.8 blue:0.6 alpha:1.0].CGColor];
        [colors addObject:(id)[UIColor colorWithRed:0.0 green:0.8 blue:0.6 alpha:1.0].CGColor];
        priceGraph.gradientLayer.colors = colors;

        
        
     }
    else if(index == 4) // smoke
    {
      //  priceGraph.gradientLayer.opacity = 0.8f;
        [self setThemeColor:[UIColor darkGrayColor]];
        [priceGraph setThemeColor:[UIColor darkGrayColor]];
    }
    else if(index == 5) // light_blue_gradient.jpg
    {
        [self setThemeColor:[UIColor whiteColor]];
        [priceGraph setThemeColor:[UIColor darkGrayColor]];
        NSMutableArray *colors = [NSMutableArray array];
        [colors addObject:(id)[UIColor colorWithRed:0.0 green:0.8 blue:0.6 alpha:1.0].CGColor];
        [colors addObject:(id)[UIColor colorWithRed:0.0 green:0.8 blue:0.6 alpha:1.0].CGColor];
        priceGraph.gradientLayer.colors = colors;
        

    }
    else if(index == 6) // red_gradient.jpg
    {
        [self setThemeColor:[UIColor whiteColor]];
        [priceGraph setThemeColor:[UIColor whiteColor]];
    }
    else if(index == 7) // nebula
    {
        [self setThemeColor:[UIColor whiteColor]];
        [priceGraph setThemeColor:[UIColor whiteColor]];
    }
    else if(index == 8) // wild flowers
    {
        priceGraph.gradientLayer.opacity = 0.8f;
        [self setThemeColor:[UIColor whiteColor]];
        [priceGraph setThemeColor:[UIColor blackColor]];
    }
    else if(index == 9) // wheat field
    {
        [self setThemeColor:[UIColor darkGrayColor]];
        [priceGraph setThemeColor:[UIColor whiteColor]];
    }

    [wallpaperImageView setHidden:FALSE];
}

-(void)changeExchangeTo:(NSString*)s
{
	self.period = _3D;
    if([[exchangeSymbols allKeysForObject:s] count] > 0)
        self.exchange = (NSString*)[exchangeSymbols allKeysForObject:s][0];
    else
        self.exchange = [s lowercaseString];
	self.symbol = [NSString stringWithFormat:@"%@%@", self.exchange, self.currency];
    [priceGraph setSymbol:symbol withPeriod:period];
    [loadSpinner setHidden:NO];
    [loadSpinner startAnimating];
    [self updateView];
}

-(void)changeTimePeriodTo:(enum TimePeriod)p
{
	self.period = p;
   [priceGraph changePeriodTo:p];
    [loadSpinner setHidden:NO];
    [loadSpinner startAnimating];
    [self updateView];
}

-(void)changeCurrencyTo:(NSString*)c
{
	self.currency = c;
    NSArray* exchanges = [self getSortedExchangesForCurrency:self.currency];
    self.exchange = exchanges[0];
    self.period = _3D;
    self.symbol = [NSString stringWithFormat:@"%@%@", exchange, currency];
    [priceGraph setSymbol:symbol withPeriod:period];
    [loadSpinner setHidden:NO];
    [loadSpinner startAnimating];
    [self updateView];
 }

-(void)didReceiveMemoryWarning{
    [super didReceiveMemoryWarning];
}

-(void)niDropDownDelegateMethod:(BVMenu*) sender path:(NSIndexPath *)indexPath
{
    toolbar.hidden = YES;
    
    if(sender == timeSpanMenu)
    {
        [self toggleTimeSpanMenu:timeSpanButton];
        [self changeTimePeriodTo:indexPath.row];
        timeSpanMenu = nil;
    }
    else if(sender == exchangesMenu)
    {
        NSString* s = exchangesArray[indexPath.row];
        NSArray* words = [s componentsSeparatedByString:@":"];
        
        [self toggleExchangesMenu:exchangeButton];
        [self changeExchangeTo:(NSString*)words[0]];

        exchangesMenu = nil;
    }
    else if(sender == currenciesMenu)
    {
        [self toggleCurrenciesMenu:currencyButton];
        
        
        NSMutableArray* currencies = [NSMutableArray arrayWithArray:self.currenciesArray];
        
        for(id s in currenciesArray)
        {
            if([s isEqualToString:self.currency])
            {
                [currencies removeObject:s];
            }
        }

        [self changeCurrencyTo:currencies[indexPath.row]];
        currenciesMenu = nil;
    }
    else if(sender == themesMenu)
    {
        [self toggleThemesMenu:themesButton];
        [self setTheme:indexPath.row];
    }
}

//	updates price label, volume, date
-(void)updateView
{
    if(exchangeSymbols[exchange])
        [exchangeButton setTitle:[NSString stringWithFormat:@"%@", exchangeSymbols[exchange]] forState:UIControlStateNormal];
    else
        [exchangeButton setTitle:[NSString stringWithFormat:@"%@", exchange] forState:UIControlStateNormal];
    
    id close_price = marketPrices[symbol];
    NSDate* now = [NSDate date];
    NSDateFormatter* df = [[NSDateFormatter alloc] init];
	[df setTimeZone:[NSTimeZone localTimeZone]];
    [df setDateFormat:@"h:mma"];
    NSString* s = [df stringFromDate:now];
    timeLabel.text = s;

    NSTimeInterval t2 = [now timeIntervalSince1970];
    NSTimeInterval t1 = [(NSDate*)marketTradeTimes[symbol] timeIntervalSince1970];
    NSTimeInterval diff = t2-t1;
    NSString* elapsed_str = nil;
    double hrs = diff / 3600;
    if(hrs < 1.0f)
    {
        double min = diff / 60;
        
        if(min < 1.0f)
            elapsed_str = [NSString stringWithFormat:@"%i seconds ago", (int)diff];
        else if((int)min == 1)
            elapsed_str = @"1 minute ago";
        else
            elapsed_str = [NSString stringWithFormat:@"%i minutes ago", (int)diff / 60];
    }
    else
    {
        if((int)hrs == 1)
            elapsed_str = @"1 hour ago";
        else
            elapsed_str = [NSString stringWithFormat:@"%i hours ago", (int)hrs];
    }
    
 //   [UIApplication sharedApplication].applicationIconBadgeNumber = [close_price intValue];
    
    timeLabel.text = elapsed_str;
	
	NSNumberFormatter* nf = [[NSNumberFormatter alloc] init];
    [nf setMaximumFractionDigits:0];
    [nf stringForObjectValue:close_price];
    priceLabel.text = [nf stringForObjectValue:close_price];
    
    if([priceLabel.text length] > 4)
    {
        priceLabel.font = [UIFont fontWithName:@"Futura" size:60];
    }
    else
        priceLabel.font = [UIFont fontWithName:@"Futura" size:80];
    
    [priceLabel sizeToFit];
    
    priceLabel.frame = CGRectMake((self.view.frame.size.width / 2.0) - (priceLabel.frame.size.width / 2.0),
        priceLabel.frame.origin.y,
        priceLabel.frame.size.width,
        priceLabel.frame.size.height);
    
    CGRect r = CGRectMake(priceLabel.frame.origin.x + priceLabel.frame.size.width,
                              priceLabel.frame.origin.y ,
                              65,
                              50);
    
    currencyButton.frame = r;
    [currencyButton setTitle:[NSString stringWithFormat:@"%@/BTC",currencyUnicodes[self.currency]] forState:UIControlStateNormal];
    r.origin.y+=30;
    priceChangeLabel.frame = r;
    [priceGraph updatePriceDelta];
   [self.view setNeedsDisplay];
}

-(void)checkTickerTimer:(NSTimer*)timer
{
	if(timer == marketDataTimer)
    {
        [self getMarketPrices:NO];
        [self checkGraphTimer];
    }
 }

-(void)checkGraphTimer
{
    if(priceGraph.lastRightEdgeUpdate == nil)
        return;
    
    NSCalendar* calendar = [NSCalendar currentCalendar];
    NSDateComponents* lastRightEdgeUpdateComp = [calendar components: NSMinuteCalendarUnit | NSHourCalendarUnit fromDate:priceGraph.lastRightEdgeUpdate];
    NSDate* nowDate = [NSDate date];
    NSDateComponents* now = [calendar components: NSMinuteCalendarUnit | NSHourCalendarUnit fromDate:nowDate];
    
    // If at right edge of graph and there is likely newer data available, refresh.
    if([priceGraph.prices[[priceGraph.prices count]-1] isEqual:[NSNull null]])
    {
        if(priceGraph.displayRange.location+priceGraph.displayRange.length == [priceGraph.prices count]-1)
        {
            if([lastRightEdgeUpdateComp hour] != [now hour] && [now minute] > 5)
            {
                priceGraph.statusCaptionLabel.hidden = false;
                priceGraph.statusCaptionLabel.text = @"Doing hourly graph refresh";
                [loadSpinner setHidden:NO];
                [loadSpinner startAnimating];
                NSLog(@"Time to refresh graph");
                [priceGraph setSymbol:self.symbol withPeriod:self.period];
            }
        }
    }
}

// Load most recent market prices for all exchanges/currencies
-(void)getMarketPrices:(bool)in_background
{
    self.background_mode = in_background;
    
    t1 = [[NSDate date] timeIntervalSince1970];

    NSURLRequest* r1 = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://www.seanestey.ca/bitvisual/server/get_markets.py"]];
    ((ConnectionData*)connections[MARKET_DATA]).data = [NSMutableData data];
    ((ConnectionData*)connections[MARKET_DATA]).connection = [[NSURLConnection alloc] initWithRequest:r1 delegate:self];
}

-(void)connection:(NSURLConnection *)c didReceiveResponse:(NSURLResponse *)response
{
    bool found = false;
	for(ConnectionData* item in connections)
	{
		if(item.connection == c)
        {
			[item.data setLength:0];
            found = true;
        }
	}
}

-(void)connection:(NSURLConnection *)c didReceiveData:(NSData *)data
{
	for(ConnectionData* item in connections)
	{
		if(item.connection == c)
			[item.data appendData:data];
	}
}

-(void)connection:(NSURLConnection *)c didFailWithError:(NSError *)error
{   
	for(ConnectionData* item in connections)
	{
		if(item.connection == c)
			NSLog(@"connection %u failed with error %@", item.type, error);
        
        if(self.background_mode != true)
        {
            priceGraph.statusCaptionLabel.hidden = false;
            priceGraph.statusCaptionLabel.text = @"Unable to connect to server.";
            [retryConnectionButton setHidden:NO];
        }
	}
}

-(void)connectionDidFinishLoading:(NSURLConnection *)c
{
    if(c == ((ConnectionData*)connections[MARKET_DATA]).connection)
    {
	    NSString *responseString = [[NSString alloc] initWithData:((ConnectionData*)connections[MARKET_DATA]).data encoding:NSUTF8StringEncoding];
		NSError *e = nil;
		NSData *jsonData = [responseString dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary* jsonDictData = [NSJSONSerialization JSONObjectWithData:jsonData options: NSJSONReadingMutableContainers error: &e];
        
        if(e != nil)
        {
            NSLog(@"Error in BVViewController::connectionDidFinishLoading: %@", e);
            return;
        }
        
        t2 = [[NSDate date] timeIntervalSince1970];
        NSTimeInterval delta = (t2 - t1)*1000;
        NSLog(@"Received market data (%.1fkb) in %.0fms.", [((ConnectionData*)connections[MARKET_DATA]).data length]/1000.0f, delta);
        
        [retryConnectionButton setHidden:YES];
   //     [loadSpinner setHidden:YES];

        for(NSDictionary* item in jsonDictData)
        {
            NSNumber* close_price = (NSNumber*)item[@"close"];
            NSDate* latest_trade = [NSDate dateWithTimeIntervalSince1970:[(NSNumber*)item[@"time"] doubleValue]];
            [marketPrices setValue:close_price forKey:item[@"symbol"]];
            [marketTradeTimes setValue:latest_trade forKey:item[@"symbol"]];
        }
        
        [self updateView];
    }
}

-(IBAction)toggleExchangesMenu:(id)sender
{
    ((VertexAnnotation*)priceGraph.vertexAnnotations[2]).dot.hidden = TRUE;
    ((VertexAnnotation*)priceGraph.vertexAnnotations[2]).line.hidden = TRUE;
    ((VertexAnnotation*)priceGraph.vertexAnnotations[2]).caption.hidden = TRUE;
    ((VertexAnnotation*)priceGraph.vertexAnnotations[2]).background.hidden = TRUE;

    if(exchangesMenu == nil)
    {
        toolbar.hidden = NO;
        exchangesArray = [[NSMutableArray alloc] init];
        NSArray* exchanges = [self getSortedExchangesForCurrency:self.currency];
        
        NSNumberFormatter* nf = [[NSNumberFormatter alloc] init];
        [nf setMaximumFractionDigits:0];
        
        for(id s in exchanges)
        {
            if(![s isEqualToString:self.exchange])
            {
                NSString* symbol_str = [NSString stringWithFormat:@"%@%@", s, self.currency];
                NSString* str_price = [nf stringFromNumber:marketPrices[symbol_str]];
                NSString* name = [(NSString*)s capitalizedString];
                if(exchangeSymbols[s])
                        name = exchangeSymbols[s];
                NSString* menuText = [NSString stringWithFormat:@"%@: %@%@", name, currencyUnicodes[currency], str_price];
                [exchangesArray addObject:menuText];
            }
        }

        float height = [exchangesArray count] * 40;
        float width = exchangeButton.frame.size.width;
        exchangesMenu = [[BVMenu alloc]showDropDown:sender hasWidth:width hasHeight:height hasItems:exchangesArray direction:@"down" editsSenderOnSelect:TRUE caption:exchangeSymbols[exchange]];
        exchangesMenu.delegate = self;
    }
    else
    {
        toolbar.hidden = YES;
        [exchangesMenu hideDropDown:sender];
        exchangesMenu = nil;
    }
}

-(NSArray*)getSortedExchangesForCurrency:(NSString*)c
{
    NSMutableArray* exchanges = [[NSMutableArray alloc] init];
    
    for(id key in marketPrices)
        if([[key substringFromIndex:[key length] -3] isEqualToString:c])
            [exchanges addObject:[NSMutableString stringWithString:[key substringToIndex:[key length] -3]]];
    
    NSArray* sorted = [exchanges sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    exchanges = [NSMutableArray arrayWithArray:sorted];
    
    // Put btcavg as default exchange for given currency if it exists
    if([exchanges containsObject:@"btcavg"])
    {
        [exchanges removeObject:@"btcavg"];
        [exchanges insertObject:@"btcavg" atIndex:0];
    }
    
    return exchanges;
}

-(IBAction)toggleThemesMenu:(id)sender
{
    ((VertexAnnotation*)priceGraph.vertexAnnotations[2]).dot.hidden = TRUE;
    ((VertexAnnotation*)priceGraph.vertexAnnotations[2]).line.hidden = TRUE;
    ((VertexAnnotation*)priceGraph.vertexAnnotations[2]).caption.hidden = TRUE;
    ((VertexAnnotation*)priceGraph.vertexAnnotations[2]).background.hidden = TRUE;

    if(themesMenu == nil)
    {
        toolbar.hidden = NO;
        NSArray* themeFilenames = [NSArray arrayWithObjects:
                                   @"Black & White",
                                   @"Water",
                                   @"Rain",
                                   @"Blue Circles",
                                   @"Orange Smoke",
                                   @"Blue",
                                   @"Red",
                                   @"Nebula",
                                   @"Flowers",
                                   @"Field",
                                   nil];

        float height = [themeFilenames count] * 40;
        float width = 140.0f;
        themesMenu = [[BVMenu alloc]showDropDown:sender hasWidth:width hasHeight:height hasItems:themeFilenames direction:@"down" editsSenderOnSelect:false caption:@"Theme"];
        themesMenu.delegate = self;
    }
    else
    {
        toolbar.hidden = YES;
        [themesMenu hideDropDown:sender];
        
        themesMenu = nil;
    }
}

-(IBAction)toggleCurrenciesMenu:(id)sender
{
    ((VertexAnnotation*)priceGraph.vertexAnnotations[2]).dot.hidden = TRUE;
    ((VertexAnnotation*)priceGraph.vertexAnnotations[2]).line.hidden = TRUE;
    ((VertexAnnotation*)priceGraph.vertexAnnotations[2]).caption.hidden = TRUE;
    ((VertexAnnotation*)priceGraph.vertexAnnotations[2]).background.hidden = TRUE;
    
    if(currenciesMenu == nil)
    {
        NSMutableArray* currencies = [NSMutableArray arrayWithArray:self.currenciesArray];
        
        for(id s in currenciesArray)
        {
            if([s isEqualToString:self.currency])
            {
                [currencies removeObject:s];
            }
        }
        
        float height = [currencies count] * 40;
        float width = currencyButton.frame.size.width;
        
        toolbar.hidden = NO;
        
        currenciesMenu = [[BVMenu alloc]showDropDown:sender hasWidth:width hasHeight:height hasItems:currencies direction:@"down" editsSenderOnSelect:FALSE caption:self.currency];
        currenciesMenu.delegate = self;
    }
    else
    {
        toolbar.hidden = YES;
        [currenciesMenu hideDropDown:sender];
        currenciesMenu = nil;
    }
}

-(IBAction)toggleTimeSpanMenu:(id)sender
{
    [pickerView selectRow:priceGraph.period inComponent:0 animated:false];
    [self.view setNeedsDisplay];
    
    self.timeSpanButton.hidden = TRUE;
    self.pickerView.hidden = FALSE;
    toolbar.hidden = NO;
    
    NSArray* layers = self.pickerView.layer.sublayers;
    for(id n in layers)
    {
        CALayer* layer = (CALayer*)n;
        layer.hidden = FALSE;
    }
}


-(IBAction)retryConnection:(id)sender
{
    NSLog(@"Retrying connection.");
    [self getMarketPrices:NO];
    [priceGraph setSymbol:symbol withPeriod:period];
    [retryConnectionButton setHidden:YES];
    [loadSpinner setHidden:NO];
    [loadSpinner startAnimating];
}

-(void)escapeMenu:(UITapGestureRecognizer*)sender
{
    // Close the menu currently active
    
    if(currenciesMenu != nil)
    {
        [self toggleCurrenciesMenu:currencyButton];
    }
    else if(themesMenu != nil)
    {
        [self toggleThemesMenu:themesButton];
    }
    else if(exchangesMenu != nil)
    {
        [self toggleExchangesMenu:exchangeButton];
    }
    else if(timeSpanMenu != nil)
    {
        [self toggleTimeSpanMenu:timeSpanButton];
    }
    else if(self.pickerView.hidden == NO)
    {
        self.toolbar.hidden = TRUE;
        self.timeSpanButton.hidden = FALSE;

        self.pickerView.hidden = TRUE;
        NSArray* layers = self.pickerView.layer.sublayers;
        for(id n in layers)
        {
            ((CALayer*)n).hidden = TRUE;
         }
    }
}

-(void)tapPriceLabel:(UITapGestureRecognizer*)sender
{
    if(retryConnectionButton.hidden == false)
    {
        [self getMarketPrices:NO];
    }
    
    [priceGraph setSymbol:self.symbol withPeriod:self.period];
    [loadSpinner setHidden:NO];
    [loadSpinner startAnimating];
}


-(NSAttributedString*)pickerView:(UIPickerView *)pickerView attributedTitleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    NSString* title = (NSString*)humanReadablePeriodList[[NSNumber numberWithInteger:row]];
    NSAttributedString* attString = [[NSAttributedString alloc] initWithString:title attributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]}];
    
    return attString;
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent: (NSInteger)component
{
    return [humanReadablePeriodList count];
}

-(void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    self.toolbar.hidden = TRUE;
    self.timeSpanButton.hidden = FALSE;
    [self.view setNeedsDisplay];
    [self changeTimePeriodTo:row];
    
    self.pickerView.hidden = TRUE;
    NSArray* layers = self.pickerView.layer.sublayers;
    for(id n in layers)
    {
        CALayer* layer = (CALayer*)n;
        layer.hidden = TRUE;
    }
}


@end