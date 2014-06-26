#import "BVPriceGraph.h"

#define SCROLL_VIEW_WIDTH 9600
#define MIN_VERTEX 0
#define MAX_VERTEX 1
#define TAPPED_VERTEX 2
#define MIN_BUFFER_SCREEN_LENGTH 1
#define MAX_BUFFER_SCREEN_LENGTH 3
#define BASE_GRAPH_PADDING 90
#define TOP_GRAPH_PADDING 25
#define CENTERED_DATE_BASE_PADDING 45

@implementation VertexAnnotation
@synthesize vertex_index, dot, line, background, caption, y_vertex_offset, animation, animated, hidden, dot_radius, line_connects_at_top;
@end

NSTimeInterval t1;
NSTimeInterval t2;

@implementation BVPriceGraph

@synthesize dates, prices, displayRange, period, symbol, secondsInPeriod, frequency_symbol, minMaxIndices, priceSpread, frequency;
@synthesize graphLineLayer, horizontalLineLayers, gradientLayer, linePath, lineAnimation, lineDrawn, centeredDateLabelAnimation, b_centered_date_label_is_animating;
@synthesize graphView, scrollView, imageView;
@synthesize last_offset_x, fraction_offset_x, x_spacing, dragDisplacement, dragVelocity, num_horizontal_graphlines;
@synthesize themeColor;
@synthesize vertexAnnotations, dateAnnotations;
@synthesize queried_display_start_timestamp, queried_display_end_timestamp;
@synthesize bWaitingForLeftBufferData, bWaitingForRightBufferData, bWaitingForDisplayData, bMostRecentData, queried_left_buffer_timestamp, queried_right_buffer_timestamp;
@synthesize connectionData, connection, loadSpinner;
@synthesize priceDeltaLabel, centeredDateLabel, centeredDate, centeredDateLabelFormat;
@synthesize lastRightEdgeUpdate;
@synthesize statusCaptionLabel, retryConnectionButton;
@synthesize getGraphURL;

-(id)initWithFrame:(CGRect) frame
{
	self = [super initWithFrame:frame];
	if(self)
	{
        self.num_horizontal_graphlines = 5;
        
        lastRightEdgeUpdate = nil;
        connection = nil;
        bWaitingForLeftBufferData = NO;
        bWaitingForRightBufferData = NO;
        bWaitingForDisplayData = NO;
        bMostRecentData = NO;
        
        getGraphURL = @"http://www.seanestey.ca/bitvisual/python/price_history.py?symbol=%@&start=%i&end=%i&freq=%@";
        
        secondsInPeriod = [NSArray arrayWithObjects:
                           [NSNumber numberWithInt:86400],
                           [NSNumber numberWithInt:259200],
                           [NSNumber numberWithInt:604800],
                           [NSNumber numberWithInt:2592000],
                           [NSNumber numberWithInt:15552000],
                           [NSNumber numberWithInt:31104000],
                           [NSNumber numberWithInt:62208000],
                           nil];
        
		themeColor = [UIColor darkGrayColor];
            
        CGRect graphFrame = self.bounds;
        graphView = [[UIView alloc] initWithFrame:graphFrame];
        graphView.userInteractionEnabled = TRUE;
        [self addSubview:graphView];
      
        statusCaptionLabel = [[UILabel alloc]initWithFrame:CGRectMake(
                              0,
                              0,
                              self.bounds.size.width,
                              50)];
        statusCaptionLabel.textColor = [UIColor whiteColor];
        statusCaptionLabel.numberOfLines = 2;
        statusCaptionLabel.clipsToBounds = YES;
        statusCaptionLabel.textAlignment = NSTextAlignmentCenter;
        [self addSubview:statusCaptionLabel];

        centeredDateLabel = [[UILabel alloc]initWithFrame:CGRectMake(
                             self.bounds.size.width/2.0,
                             self.bounds.size.height-70,
                             150,
                             50)];
	    centeredDateLabel.text = @"";
	    centeredDateLabel.font = [UIFont systemFontOfSize:22];
	    centeredDateLabel.numberOfLines = 1;
	    centeredDateLabel.baselineAdjustment = YES;
	    centeredDateLabel.adjustsFontSizeToFitWidth = YES;
	    centeredDateLabel.clipsToBounds = YES;
	    centeredDateLabel.backgroundColor = [UIColor clearColor];
	    centeredDateLabel.textColor = [UIColor whiteColor];
        centeredDateLabel.layer.opacity = 1.0f;
	    centeredDateLabel.textAlignment = NSTextAlignmentCenter;
        centeredDateLabel.layer.anchorPoint = CGPointMake(0.0f, 0.0f);
        [self addSubview:centeredDateLabel];

        scrollView = [[UIScrollView alloc] initWithFrame:self.bounds];
        scrollView.delegate = self;
        scrollView.layer.opacity = 0.1f;
        scrollView.contentSize=CGSizeMake(SCROLL_VIEW_WIDTH,300);
        [self addSubview:scrollView];
        
        UITapGestureRecognizer *doubleTapGestureRecognizer = [[UITapGestureRecognizer alloc]
                                                              initWithTarget:self
                                                              action:@selector(doubleTap:)];
        doubleTapGestureRecognizer.numberOfTapsRequired = 2;
        [scrollView addGestureRecognizer:doubleTapGestureRecognizer];
        
        UITapGestureRecognizer *singleTapGestureRecognizer = [[UITapGestureRecognizer alloc]
                                                              initWithTarget:self
                                                              action:@selector(singleTap:)];
        singleTapGestureRecognizer.numberOfTapsRequired = 1;
        [singleTapGestureRecognizer requireGestureRecognizerToFail:doubleTapGestureRecognizer];
        [scrollView addGestureRecognizer:singleTapGestureRecognizer];
        
        NSMutableParagraphStyle *textAnnotationStyle = [[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy];
    	textAnnotationStyle.lineBreakMode = NSLineBreakByWordWrapping;
    	textAnnotationStyle.alignment = NSTextAlignmentCenter;
    	self.annotationAttributes = @{NSFontAttributeName:[UIFont systemFontOfSize:14.0f]};
      
        lineAnimation = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
        lineAnimation.duration = 0.75;
        lineAnimation.fromValue = [NSNumber numberWithFloat:0.0f];
        lineAnimation.toValue = [NSNumber numberWithFloat:1.0f];
        [lineAnimation setValue:@"lineAnimation" forKey:@"id"];
        [lineAnimation setDelegate:self];
        
        centeredDateLabelAnimation = [CABasicAnimation animationWithKeyPath:@"position"];
        centeredDateLabelAnimation.duration = 0.25;
 
        [centeredDateLabelAnimation setDelegate:self];
  	
  		vertexAnnotations = [[NSArray alloc] initWithObjects:
                             [VertexAnnotation alloc],
                             [VertexAnnotation alloc],
                             [VertexAnnotation alloc],
                             nil];
  		
        for(int i=0; i<[vertexAnnotations count]; i++)
    	{
    		VertexAnnotation* va = (VertexAnnotation*)vertexAnnotations[i];
            va.dot_radius = 2.5f;
    		va.dot = [CALayer layer];
    		va.dot.backgroundColor = themeColor.CGColor;
    		[va.dot setCornerRadius:va.dot_radius];
    		[graphView.layer addSublayer:va.dot];
            
            va.background = [CALayer layer];
            va.background.backgroundColor = [UIColor whiteColor].CGColor;
            va.background.cornerRadius = 5.0f;
            va.background.opacity = 0.7f;
            [graphView.layer addSublayer:va.background];
    		
            va.caption = [CATextLayer layer];
    		va.caption.fontSize = 14.0;
			va.caption.cornerRadius = 5.0f;
            va.caption.borderWidth = 0.75f;
            va.caption.backgroundColor = [UIColor clearColor].CGColor;
            va.caption.alignmentMode = kCAAlignmentCenter;
        	va.caption.foregroundColor = themeColor.CGColor;
        	va.caption.contentsScale = [[UIScreen mainScreen] scale];
            [graphView.layer addSublayer:va.caption];
    		
            va.line = [CAShapeLayer layer];
    		va.line.strokeColor = themeColor.CGColor;
    		va.line.fillColor = nil;
     		va.line.lineWidth = 1.0f;
            va.animated = TRUE;
            va.line_connects_at_top = FALSE;
     		[graphView.layer addSublayer:va.line];
    	}
    	
    	((VertexAnnotation*)vertexAnnotations[MIN_VERTEX]).y_vertex_offset = 5;
        ((VertexAnnotation*)vertexAnnotations[MIN_VERTEX]).line_connects_at_top = TRUE;
    	((VertexAnnotation*)vertexAnnotations[MAX_VERTEX]).y_vertex_offset = -43;
        ((VertexAnnotation*)vertexAnnotations[MAX_VERTEX]).background.opacity = 0.7f;
    	((VertexAnnotation*)vertexAnnotations[TAPPED_VERTEX]).y_vertex_offset = -83;
    	((VertexAnnotation*)vertexAnnotations[TAPPED_VERTEX]).hidden = TRUE;
        ((VertexAnnotation*)vertexAnnotations[TAPPED_VERTEX]).background.opacity = 0.7f;
        ((VertexAnnotation*)vertexAnnotations[TAPPED_VERTEX]).animated = false;
        
        horizontalLineLayers = [[NSMutableArray alloc] init];

        for(int i=0; i<num_horizontal_graphlines; i++)
        {
            CAShapeLayer* horizontal_line = [CAShapeLayer layer];
            horizontal_line.frame = self.bounds;
            horizontal_line.masksToBounds = YES;
            horizontal_line.strokeColor = [UIColor whiteColor].CGColor;
            horizontal_line.fillColor = nil;
            horizontal_line.lineWidth = 0.25f;
            horizontal_line.opacity = 0.6;
            horizontal_line.lineJoin = kCALineJoinRound;
            [graphView.layer insertSublayer:horizontal_line atIndex:0];
            [horizontalLineLayers addObject:horizontal_line];
        }
	}
    
    gradientLayer = [CAGradientLayer layer];
	return self;
}

-(void)setThemeColor:(UIColor*)color
{
	themeColor = color;
    graphLineLayer.strokeColor = themeColor.CGColor;
  //  priceDeltaLabel.textColor = themeColor;
    centeredDateLabel.textColor = themeColor;
	
	for(int i=0; i<[vertexAnnotations count]; i++)
    {
    	VertexAnnotation* va = (VertexAnnotation*)vertexAnnotations[i];
    	va.dot.backgroundColor = themeColor.CGColor;
    	va.line.strokeColor = themeColor.CGColor;
        va.line.fillColor = themeColor.CGColor;
    }
    
    for(int i=0; i<[dateAnnotations count]; i++)
    {
        ((CATextLayer*) dateAnnotations[i]).foregroundColor = themeColor.CGColor;
    }
    
    for(int i=0; i<num_horizontal_graphlines; i++)
    {
        ((CAShapeLayer*) horizontalLineLayers[i]).strokeColor = themeColor.CGColor;
    }
    
    NSMutableArray *colors = [NSMutableArray array];
    [colors addObject:(id)[UIColor colorWithRed:0.0 green:0.6 blue:0.8 alpha:1.0].CGColor];
    [colors addObject:(id)[UIColor colorWithRed:0.0 green:0.6 blue:0.8 alpha:1.0].CGColor];
    gradientLayer.colors = colors;
    gradientLayer.startPoint = CGPointMake(0.5,0.0);
    gradientLayer.endPoint = CGPointMake(0.5,1.0);
    gradientLayer.frame = self.bounds;
}

-(void)queryStart:(int)start end:(int)end
{
    NSString* connectionURL = [NSString stringWithFormat:getGraphURL, symbol, start, end, frequency_symbol];
    
    t1 = [[NSDate date] timeIntervalSince1970];
    connection = [[NSURLConnection alloc] initWithRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:connectionURL]]
                  delegate:self
                  startImmediately:NO];
    
    // Very important!!
    [connection scheduleInRunLoop:[NSRunLoop currentRunLoop]
                forMode:NSRunLoopCommonModes];
    [connection start];
}

-(void)findMinMaxIndices
{
    if(displayRange.location == 0 && [prices[0] isEqual:[NSNull null]])
    {
        NSLog(@"findMinMaxIndices error: displayRange.location == 0");
        return;
    }
    
    float min = [prices[displayRange.location] floatValue];
    float max = [prices[displayRange.location] floatValue];
    unsigned long min_ind = displayRange.location;
    unsigned long max_ind = displayRange.location;
    unsigned long i = displayRange.location;
 
    NSArray* priceRange = nil;
    
    // CRASH BUG
    @try
    {
        priceRange = [prices subarrayWithRange:displayRange];
    }
    @catch (NSException* e)
    {
        NSLog(@"Exception found in findMinMaxIndices! %@", e);
    }
    @finally
    {
        
    }
    
    for(NSNumber* n in priceRange)
    {
        float x = [n floatValue];
        if (x < min)
        {
            min = x;
            min_ind = i;
        }
        if (x > max)
        {
            max = x;
            max_ind = i;
        }
        i++;
    }
    
    minMaxIndices = [[NSArray alloc] initWithObjects:
                     [NSNumber numberWithLong:min_ind],
                     [NSNumber numberWithLong:max_ind],
                     nil];
    
    ((VertexAnnotation*)vertexAnnotations[MIN_VERTEX]).vertex_index = (int)min_ind;
    ((VertexAnnotation*)vertexAnnotations[MAX_VERTEX]).vertex_index = (int)max_ind;
        
    priceSpread = [NSNumber numberWithFloat:max-min];
    
    // Prevent div/0 error
    if([priceSpread intValue] == 0)
        priceSpread = [NSNumber numberWithFloat:1.0f];
}

-(void)receiveData:(NSArray*)priceData :(NSArray*)dateData
{
    t2 = [[NSDate date] timeIntervalSince1970];
    NSTimeInterval delta = (t2 - t1)*1000;
    
    if([priceData count] == 0 && [dateData count] == 0 && !bWaitingForDisplayData)
    {
        NSLog(@"No data for known exchange. Unknown error.");
        return;
    }
    
    statusCaptionLabel.hidden = true;
    
    if(bWaitingForDisplayData == YES)
    {
        prices = [[NSMutableArray alloc] init];
        dates = [[NSMutableArray alloc] init];
        
        NSLog(@"Received %lu display/buffer records (%.1fkb) in %.0fms",
              (unsigned long)[priceData count],
              [connectionData length]/1000.0f,
              delta);
        
        int i=0;
        for(id item in priceData)
        {
            [dates addObject:dateData[i]];
            [prices addObject:item];
            i++;
        }
        

        unsigned int left_edge_timestamp = [dateData[0] timeIntervalSince1970];
        unsigned int left_buffer_length = (queried_display_start_timestamp - left_edge_timestamp)
                                          / frequency;
        unsigned int display_length = [(NSNumber*)secondsInPeriod[period] intValue]
                                        / frequency;
        
        // Verify integrity of data
        // We know we're at right edge of graph if the last timestamp
        // returned is < (queried_display_end_timestamp - frequency)
        
        if([(NSDate*)dateData[0] timeIntervalSince1970] > queried_display_start_timestamp)
        {
            if([dateData count] < display_length)
                self.displayRange = NSMakeRange(0, [dateData count]);
            // Pushing against left edge of graph. No left buffer + adjust display range.
            else
                self.displayRange = NSMakeRange(0, display_length);
        }
        else if([(NSDate*)dateData[[dateData count]-1] timeIntervalSince1970] < (queried_display_end_timestamp-frequency))
        {
            if([dateData count] < display_length)
                self.displayRange = NSMakeRange(0, [dateData count]);
            // Pushing against right edge of graph. No right buffer + adjust display range.
            else
                self.displayRange = NSMakeRange([dates count]-display_length, display_length);
            [dates insertObject:[NSNull null]
                    atIndex:[dates count]];
            [prices insertObject:[NSNull null]
                    atIndex:[prices count]];
            lastRightEdgeUpdate = [NSDate date];
        }
        else
             self.displayRange = NSMakeRange(left_buffer_length, display_length);
        
        x_spacing = graphView.bounds.size.width / (float)(displayRange.length-1);
        bWaitingForDisplayData = NO;
        [self load];

    }
    else if(bWaitingForLeftBufferData == YES)
    {
        NSLog(@"Received %lu left buffer records (%.1fkb) in %.0fms",
              (unsigned long)[priceData count],
              [connectionData length]/1000.0f,
              delta);
        int i=0;
        int timestamp = queried_left_buffer_timestamp;
        for(id item in priceData)
        {
            [dates insertObject:dateData[i] atIndex:i];
            [prices insertObject:item atIndex:i];
            i++;
            timestamp+=frequency;
        }
        
        if([(NSDate*)dateData[0] timeIntervalSince1970] > queried_left_buffer_timestamp)
        {
            // Approaching left edge of graph.
            [dates insertObject:[NSNull null] atIndex:0];
            [prices insertObject:[NSNull null] atIndex:0];
        }
        
        displayRange.location += [priceData count];
        
        bWaitingForLeftBufferData = NO;
        
        [self findMinMaxIndices];
        [self updatePriceDelta];
        [self draw:NO];
    }
    else if(bWaitingForRightBufferData == YES)
    {
        NSLog(@"Received %lu right buffer (%.1fkb) in %.0fms.",
              (unsigned long)[priceData count],
              [connectionData length]/1000.0f,
              delta);
        
        // May be at right edge of graph. Check for NSNull at end of
        // Dates/Prices arrays, insert new data inbetween
        if([(NSDate*)dateData[[dateData count]-1] timeIntervalSince1970] < queried_right_buffer_timestamp)
        {
            // Approaching right edge of graph.
        }
        
        int i=0;
        for(id item in priceData)
        {
            [dates addObject:dateData[i]];
            [prices addObject:item];
            i++;
        }
        
        bWaitingForRightBufferData = NO;
        
        [self findMinMaxIndices];
        [self updatePriceDelta];
        [self draw:NO];
    }
    
    queried_left_buffer_timestamp = 0;
    queried_right_buffer_timestamp = 0;
    queried_display_start_timestamp = 0;
    queried_display_end_timestamp = 0;
}

-(void)clear
{
    [scrollView removeFromSuperview];
    
    CGPoint offset = scrollView.contentOffset;
    [scrollView setContentOffset:offset animated:NO];
    
    [graphLineLayer removeFromSuperlayer];
    [gradientLayer removeFromSuperlayer];
    
    for(CATextLayer* t in dateAnnotations)
        [t removeFromSuperlayer];
    
    centeredDateLabel.text = @"";
    
    for(int i=0; i<3; i++)
    {
        ((VertexAnnotation*)vertexAnnotations[i]).vertex_index = 1;
        ((VertexAnnotation*)vertexAnnotations[i]).dot.hidden = TRUE;
        ((VertexAnnotation*)vertexAnnotations[i]).line.hidden = TRUE;
        ((VertexAnnotation*)vertexAnnotations[i]).caption.hidden = TRUE;
        ((VertexAnnotation*)vertexAnnotations[i]).background.hidden = TRUE;
    }
}

-(void)setSymbol:(NSString*)s withPeriod:(enum TimePeriod)p
{
    // Always queries for latest data at right edge of graph
    bMostRecentData = YES;
    
    [self clear];
    
    // Query data from server
    bWaitingForDisplayData = YES;
    bWaitingForLeftBufferData = NO;
    bWaitingForRightBufferData = NO;
    
    self.period = p;
    self.symbol = s;
    
    if(period == _1M || period == _6M || period == _1Y || period == _2Y)
    {
        frequency = 3600 * 24;
        frequency_symbol = @"d";
    }
	else if(period == _1D || period == _3D || period == _1W)
    {
        // bMostRecentData = Yes;
        frequency = 3600;
        frequency_symbol = @"h";
    }

    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDate* now = [NSDate date];
    NSDateComponents *comps = [calendar components:
                               NSEraCalendarUnit |
                               NSYearCalendarUnit|
                               NSMonthCalendarUnit |
                               NSDayCalendarUnit |
                               NSHourCalendarUnit
                               fromDate:now];
    
    if(frequency == 3600)
        [comps setHour: [comps hour]+1];  // Possible bug: may need to check if last hour of day
    else if(frequency == 3600*24)
        [comps setDay:[comps day]+1];
   
    NSDate* roundedDate = [calendar dateFromComponents:comps];
    
    queried_display_end_timestamp = [roundedDate timeIntervalSince1970];
    queried_display_start_timestamp = queried_display_end_timestamp -
                                      [(NSNumber*)secondsInPeriod[period] intValue];
    
    queried_left_buffer_timestamp = queried_display_start_timestamp
                                    - ([(NSNumber*)secondsInPeriod[period] intValue]
                                    * MAX_BUFFER_SCREEN_LENGTH);
    queried_right_buffer_timestamp = queried_display_end_timestamp;
    
    [self queryStart:queried_left_buffer_timestamp end:queried_right_buffer_timestamp];
}

-(void)changePeriodTo:(enum TimePeriod)p
{
    // Assumes a symbol and dataset already exist
    if(symbol == nil)
    {
        NSLog(@"Cannot change period without symbol");
        return;
    }
    
    if(displayRange.location + displayRange.length == [dates count]-1)
        if([dates[[dates count]-1] isEqual:[NSNull null]])
        {
            NSLog(@"Right edge of graph. changePeriodTo calling setSymbol instead");
            [self setSymbol:self.symbol withPeriod:p];
            return;
        }
    
    [self clear];
    
    period = p;
    
    // Use date in middle of displayRange as focal point to zoon in/out of
    NSDate* midDate = (NSDate*)dates[displayRange.location + displayRange.length/2];
    
    if(period == _1M || period == _6M || period == _1Y || period == _2Y)
    {
        frequency = 3600 * 24;
        frequency_symbol = @"d";
    }
	else if(period == _1D || period == _3D || period == _1W)
    {
        frequency = 3600;
        frequency_symbol = @"h";
    }
    
    int seconds_in_period = [(NSNumber*)secondsInPeriod[period] intValue];
    queried_display_start_timestamp = [midDate timeIntervalSince1970]
                                       - (seconds_in_period / 2);
    queried_display_end_timestamp = [midDate timeIntervalSince1970]
                                    + (seconds_in_period / 2);
    
    queried_left_buffer_timestamp = queried_display_start_timestamp
                                    - ([(NSNumber*)secondsInPeriod[period] intValue] * MAX_BUFFER_SCREEN_LENGTH);
    queried_right_buffer_timestamp = queried_display_end_timestamp
                                    + ([(NSNumber*)secondsInPeriod[period] intValue] * MAX_BUFFER_SCREEN_LENGTH);
    
    [self queryStart:queried_left_buffer_timestamp
          end:queried_right_buffer_timestamp];

    bWaitingForDisplayData = YES;
    bWaitingForLeftBufferData = NO;
    bWaitingForRightBufferData = NO;
}

-(void)load
{
    [self addSubview:scrollView];
    
    last_offset_x = 0.0f;
	fraction_offset_x = 0.0f;
  	
    [gradientLayer removeFromSuperlayer];
    [graphView.layer insertSublayer:gradientLayer atIndex:1];
    
    for(int i=0; i<[vertexAnnotations count]; i++)
    {
        VertexAnnotation* va = (VertexAnnotation*)vertexAnnotations[i];
        va.dot.hidden = TRUE;
        va.caption.hidden = TRUE;
        va.line.hidden = TRUE;
        va.background.hidden = TRUE;
        va.hidden = TRUE;
    }
    
    [graphLineLayer removeFromSuperlayer];
    graphLineLayer = [CAShapeLayer layer];
    graphLineLayer.frame = self.bounds;
    graphLineLayer.masksToBounds = YES;
    graphLineLayer.strokeColor = themeColor.CGColor;
    graphLineLayer.fillColor = nil;
    graphLineLayer.lineWidth = 1.5f;
    graphLineLayer.lineJoin = kCALineJoinRound;
    linePath = [UIBezierPath bezierPath];
    [graphView.layer insertSublayer:graphLineLayer atIndex:1];
    
	[self findMinMaxIndices];	
	[self updatePriceDelta];
    [self updateCurrentDateLabelFormat];
    [self updateCurrentDateLabel];
	[self draw:YES];
}

-(void)updatePriceDelta
{
    if([prices count] == 0)
    {
        priceDeltaLabel.text = @"";
        return;
    }
    
    float price_end = [((NSNumber*)prices[displayRange.location+displayRange.length-1]) floatValue];
    float price_start = [((NSNumber*)prices[displayRange.location]) floatValue];
	float price_delta = ((price_end - price_start)/price_start)*100;
    
	NSNumberFormatter* f = [[NSNumberFormatter alloc] init];
    if(fabs(price_delta) > 25)
        [f setMaximumFractionDigits:0];
    else
        [f setMaximumFractionDigits:1];
	
	if(price_delta < 0)
		priceDeltaLabel.text = [NSString stringWithFormat:@"%C%@%%",
			(unichar)0x25BC,
			[f stringFromNumber:[NSNumber numberWithFloat:fabs(price_delta)]]];
	else 
		priceDeltaLabel.text = [NSString stringWithFormat:@"%C%@%%",
			(unichar)0x25B2,
			[f stringFromNumber:[NSNumber numberWithFloat:price_delta]]];
}

-(void)plot:(bool)animatedLine
{
    if(displayRange.location == 0 && [prices[0] isEqual:[NSNull null]])
    {
        NSLog(@"plot error: displayRange.location == 0");
        return;
    }

	CGPoint origin = graphView.bounds.origin;
	CGSize graphSize = graphView.bounds.size;
    float max_price = [(NSNumber*)prices[[(NSNumber*)minMaxIndices[MAX_VERTEX] intValue]] floatValue];
    float x = origin.x; //- fraction_offset_x;
    float start_y = origin.y + TOP_GRAPH_PADDING;
    float spread = [priceSpread floatValue];
    float maxLineHeight = graphSize.height - BASE_GRAPH_PADDING - TOP_GRAPH_PADDING;
    
    linePath = [UIBezierPath bezierPath];
    CGPoint firstPoint = CGPointMake(x, start_y + ((max_price - [prices[displayRange.location] floatValue]) / spread)* maxLineHeight);
    [linePath moveToPoint:firstPoint];

    NSArray* displayArray = [prices subarrayWithRange:displayRange];
    for(NSNumber* n in displayArray)
    {
        float y = start_y + ((max_price - [n floatValue]) / spread)* maxLineHeight;
        [linePath addLineToPoint:CGPointMake(x, y)];
        x+= x_spacing;
    }
    
    [linePath addLineToPoint:CGPointMake(origin.x + graphSize.width + 1, self.bounds.size.height+1)];
    [linePath addLineToPoint:CGPointMake(origin.x-1, self.bounds.size.height+1)];
    [linePath closePath];
    
    graphLineLayer.path = linePath.CGPath;
    graphLineLayer.fillMode = kCAFillModeForwards;
    
    CAShapeLayer* outline = [CAShapeLayer layer];
    outline.frame = self.bounds;
    outline.path = linePath.CGPath;
    [gradientLayer setMask:outline];

    if(animatedLine)
    {
        [gradientLayer setHidden:TRUE];
        [graphLineLayer addAnimation:lineAnimation forKey:@"lineAnimation"];
    }
}

-(void)annotateVertices
{
    if(displayRange.location == 0 && [prices[0] isEqual:[NSNull null]])
    {
        NSLog(@"annotateVertices error: displayRange.location == 0");
        return;
    }

	// Annotate min/max/highlighted vertices and X axis
	CGPoint origin = graphView.bounds.origin;
	CGSize graphSize = graphView.bounds.size;
	float max_price = [(NSNumber*)prices[[(NSNumber*)minMaxIndices[MAX_VERTEX] intValue]] floatValue];
    float start_x = origin.x;
    float start_y = origin.y + TOP_GRAPH_PADDING;
    float spread = [priceSpread floatValue];
    float maxLineHeight = graphSize.height - BASE_GRAPH_PADDING - TOP_GRAPH_PADDING;
    
    for(int i=0; i<[vertexAnnotations count]; i++)
    {
        VertexAnnotation* va = (VertexAnnotation*)vertexAnnotations[i];
        
        float x = start_x + (float)(va.vertex_index - displayRange.location)*x_spacing;
        float y = start_y + ((max_price - [prices[va.vertex_index] floatValue]) / spread)* maxLineHeight;
        
        CGRect dotFrame = CGRectMake(
                            x - va.dot_radius,
                            y - va.dot_radius,
                            va.dot_radius*2,
                            va.dot_radius*2);
        if(dotFrame.origin.x < 0)
            dotFrame.origin.x = 0;
        
        va.caption.string = [self getStrAnnotationFor:va.vertex_index newline:TRUE];
        CGSize strSize = [va.caption.string sizeWithAttributes:_annotationAttributes];
        CGRect strFrame = CGRectMake(
                            x - strSize.width/2,
                            y + va.y_vertex_offset,
                            strSize.width + 5,
                            strSize.height + 5);
        if(strFrame.origin.x - 5 < 0)
            strFrame.origin.x = 5;
        else if(strFrame.origin.x + strFrame.size.width + 5 > graphSize.width)
            strFrame.origin.x = graphSize.width - strFrame.size.width - 5;
        
        UIBezierPath* p = [UIBezierPath bezierPath];
        [p moveToPoint:CGPointMake(x,y)];
        
        if(va.line_connects_at_top)
            [p addLineToPoint:CGPointMake(strFrame.origin.x + strFrame.size.width/2,
                                          strFrame.origin.y)];
        else
            [p addLineToPoint:CGPointMake(strFrame.origin.x + strFrame.size.width/2,
                                          strFrame.origin.y + strFrame.size.height)];
        va.line.path = p.CGPath;
        
        if(!va.animated)
        {
            // 'Teleport' to new location, no animation
            [CATransaction begin];
            [CATransaction setDisableActions:YES];
            va.caption.frame = strFrame;
            va.background.frame = strFrame;
            [CATransaction commit];
        }
        else
        {
            va.caption.frame = strFrame;
            va.background.frame = strFrame;
            [CATransaction begin];
            [CATransaction setDisableActions:YES];
            va.dot.frame = dotFrame;
            [CATransaction commit];
        }
    }
}

-(CGPoint)getGraphLineCoordsFor:(int)datapointIndex
{
    if(displayRange.location == 0 && [prices[0] isEqual:[NSNull null]])
    {
        NSLog(@"getGraphLineCoordsFor error: displayRange.location == 0");
    }

    CGPoint origin = graphView.bounds.origin;
	CGSize graphSize = graphView.bounds.size;
    float max_price = [(NSNumber*)prices[[(NSNumber*)minMaxIndices[MAX_VERTEX] intValue]] floatValue];
    float x = origin.x;
    float start_y = origin.y + TOP_GRAPH_PADDING;
    float spread = [priceSpread floatValue];
    float maxLineHeight = graphSize.height - BASE_GRAPH_PADDING - TOP_GRAPH_PADDING;
    
    int display_index = datapointIndex - displayRange.location;
    
    CGPoint p = CGPointMake(x + (display_index * x_spacing),
                            start_y + ((max_price - [prices[datapointIndex] floatValue]) / spread)* maxLineHeight);

    return p;
}

-(void)draw:(bool)animated
{
    if([prices count] == 0 || [dates count] == 0)
        return;
    
    @try
    {
        [self drawHorizontalGraphLines];
        [self plot:animated];
        [self annotateVertices];
        [self annotateXAxis];
        [self updateCurrentDateLabel];
        
    }
    @catch (NSException* e)
    {
        NSLog(@"Exception found in priceGraph:Draw! %@", e);
    }
}

-(void)drawHorizontalGraphLines
{
    int horizontal_padding = 10;
    int vertical_padding = 15;
    int vertical_spacing = (self.bounds.size.height / (num_horizontal_graphlines-1)) - 8;
    int y = vertical_padding;
    
    for(int i=0; i<num_horizontal_graphlines; i++)
    {
        UIBezierPath* line = [UIBezierPath bezierPath];
        [line moveToPoint:CGPointMake(horizontal_padding, y)];
        [line addLineToPoint:CGPointMake(self.bounds.size.width - horizontal_padding, y)];
        [line closePath];
        ((CAShapeLayer*)horizontalLineLayers[i]).path = line.CGPath;
        y+=vertical_spacing;
    }
    
    ((CAShapeLayer*)horizontalLineLayers[num_horizontal_graphlines-1]).opacity = 1;
}


-(void)animationDidStop:(CAAnimation *)animation finished:(BOOL)flag
{
    if([[animation valueForKey:@"id"] isEqual:@"lineAnimation"])
    {
        CGPoint offset = scrollView.contentOffset;
        [scrollView setContentOffset:offset animated:YES];
        
        [gradientLayer setHidden:FALSE];
        [graphLineLayer removeAllAnimations];
        
        for(int i=0; i<[vertexAnnotations count]-1; i++)
        {
            VertexAnnotation* va = (VertexAnnotation*)vertexAnnotations[i];
            va.dot.hidden = FALSE;
            va.caption.hidden = FALSE;
            va.line.hidden = FALSE;
            va.background.hidden = FALSE;
            va.hidden = FALSE;
        }
        
        [self draw:NO];
    }
    else if([[animation valueForKey:@"id"] isEqual:@"centeredDateScrollRightAnimation"])
    {
        CGRect r = centeredDateLabel.frame;
        
        // Slid offscreen. Change position to opposite side of screen, change label to current date, slide onscreen to center
        [CATransaction begin];
        [CATransaction setDisableActions:YES];
        [centeredDateLabel sizeToFit];
        centeredDateLabel.frame = CGRectMake(
                                  r.size.width*-1,
                                  r.origin.y,
                                  r.size.width,
                                  r.size.height);
        [centeredDateLabel.layer removeAllAnimations];
        centeredDateLabel.text = [centeredDateLabelFormat stringFromDate:centeredDate];
        [CATransaction commit];
        
        centeredDateLabelAnimation.fromValue = [NSValue valueWithCGPoint:CGPointMake(
                                                r.origin.x,
                                                r.origin.y)];
        centeredDateLabelAnimation.toValue = [NSValue valueWithCGPoint:CGPointMake(
                                              self.bounds.size.width/2.0 - r.size.width/2,
                                              r.origin.y)];
        [centeredDateLabelAnimation setValue:@"centeredDateScrollCenterAnimation"
                                    forKey:@"id"];
        [centeredDateLabel.layer addAnimation:centeredDateLabelAnimation
                                 forKey:@"centeredDateScrollCenterAnimation"];
        
        [CATransaction begin];
        [CATransaction setDisableActions:YES];
        [centeredDateLabel sizeToFit];
        centeredDateLabel.frame = CGRectMake(
                                  self.bounds.size.width/2.0 - r.size.width/2,
                                  r.origin.y,
                                  r.size.width,
                                  r.size.height);
        [CATransaction commit];
    }
    else if([[animation valueForKey:@"id"] isEqual:@"centeredDateScrollLeftAnimation"])
    {
        CGRect r = centeredDateLabel.frame;
        
        [CATransaction begin];
        [CATransaction setDisableActions:YES];
        [centeredDateLabel sizeToFit];
        centeredDateLabel.frame = CGRectMake(self.bounds.size.width, r.origin.y, r.size.width, r.size.height);
        [centeredDateLabel.layer removeAllAnimations];
        centeredDateLabel.text = [centeredDateLabelFormat stringFromDate:centeredDate];
        [CATransaction commit];
        
        centeredDateLabelAnimation.fromValue = [NSValue valueWithCGPoint:CGPointMake(
                                               r.origin.x,
                                               r.origin.y)];
        centeredDateLabelAnimation.toValue = [NSValue valueWithCGPoint:CGPointMake(
                                             self.bounds.size.width/2.0 - r.size.width/2,
                                             r.origin.y)];
        [centeredDateLabelAnimation setValue:@"centeredDateScrollCenterAnimation"
                                    forKey:@"id"];
        [centeredDateLabel.layer addAnimation:centeredDateLabelAnimation
                                 forKey:@"centeredDateScrollCenterAnimation"];
        
        [CATransaction begin];
        [CATransaction setDisableActions:YES];
        [centeredDateLabel sizeToFit];
        centeredDateLabel.frame = CGRectMake(
                                  self.bounds.size.width/2.0 - r.size.width/2,
                                  r.origin.y,
                                  r.size.width,
                                  r.size.height);
        [CATransaction commit];
    }
    else if([[animation valueForKey:@"id"] isEqual:@"centeredDateScrollCenterAnimation"])
    {
        [centeredDateLabel.layer removeAllAnimations];
        b_centered_date_label_is_animating = NO;
    }
}

-(void)annotateXAxis
{
    float xAxisAnnotationOpacity = 1;
    
    for(CATextLayer* t in dateAnnotations)
        [t removeFromSuperlayer];
    
	dateAnnotations = [[NSMutableArray alloc] init];
	NSDateFormatter* df = [[NSDateFormatter alloc] init];
	[df setTimeZone:[NSTimeZone localTimeZone]];
	NSDateFormatter* outputFormat = [[NSDateFormatter alloc] init];
	[outputFormat setTimeZone:[NSTimeZone localTimeZone]];
	NSArray* displayDates = [dates subarrayWithRange:displayRange];
	
    if(period == _1D)
    {
        // Each vertex = 1 hour. 1 annotation every 4 hours: 12am, 4am, 8am, 12pm, 4pm, 8pm
        [df setDateFormat:@"h"];
        [outputFormat setDateFormat:@"ha"];
        int sub_index = 0;
        
        for(NSDate* hourlyDate in displayDates)
    	{
            NSDateComponents *calendarDay = [[NSCalendar currentCalendar]
                                             components:NSCalendarUnitHour
                                             fromDate:hourlyDate];
      		if([calendarDay hour] % 4 < 1)
            {
				CATextLayer* layer = [CATextLayer layer];
    			layer.string = [outputFormat stringFromDate:hourlyDate];
    			CGPoint p = [self getGraphLineCoordsFor:sub_index+displayRange.location];
    			layer.frame = CGRectMake(p.x, self.bounds.size.height-15, 35, 50);
    			layer.foregroundColor = themeColor.CGColor;
                layer.alignmentMode = kCAAlignmentCenter;
    			layer.fontSize = 10.0f;
                layer.opacity = xAxisAnnotationOpacity;
                layer.contentsScale = [[UIScreen mainScreen] scale];
    			[dateAnnotations addObject:layer];
                [self.layer addSublayer:layer];
    		}
    		sub_index++;
    	}
    }
    if(period == _3D)
    {
        // Each vertex = 1 hour. 1 annotation every 8 hours
        [df setDateFormat:@"ha"];
        [outputFormat setDateFormat:@"d"];
        int sub_index = 0;
        
        for(NSDate* date in displayDates)
    	{
            NSString* s = [df stringFromDate:date];
      //      NSDateComponents *calendarDay = [[NSCalendar currentCalendar] components:NSCalendarUnitHour fromDate:date];
      		if([s isEqualToString:@"12AM"])
            {
				CATextLayer* layer = [CATextLayer layer];
    			layer.string = [outputFormat stringFromDate:date];
    			CGPoint p = [self getGraphLineCoordsFor:sub_index+displayRange.location];
    			layer.frame = CGRectMake(p.x, self.bounds.size.height-15, 35, 50);
    			layer.foregroundColor = themeColor.CGColor;
                layer.alignmentMode = kCAAlignmentCenter;
    			layer.fontSize = 10.0f;
                layer.opacity = xAxisAnnotationOpacity;
                layer.contentsScale = [[UIScreen mainScreen] scale];
    			[dateAnnotations addObject:layer];
                [self.layer addSublayer:layer];
    		}
    		sub_index++;
    	}
    }
    else if(period == _1W)
	{
		// Each vertex = 1 hour. 1 annotation per calendar day
    	[df setDateFormat:@"ha"];
        [outputFormat setDateFormat:@"d"];
    		
 		int sub_index = 0;   		
    	for(NSDate* hourlyDate in displayDates)
    	{
            NSString* s = [df stringFromDate:hourlyDate];
            if([s isEqualToString:@"12AM"])
    		{
				CATextLayer* layer = [CATextLayer layer];
    			layer.string = [outputFormat stringFromDate:hourlyDate];
    			CGPoint p = [self getGraphLineCoordsFor:sub_index+displayRange.location];
    			layer.frame = CGRectMake(p.x, self.bounds.size.height-15, 35, 50);
    			layer.foregroundColor = themeColor.CGColor;
                layer.alignmentMode = kCAAlignmentCenter;
    			layer.fontSize = 10.0f;
                layer.opacity = xAxisAnnotationOpacity;
                layer.contentsScale = [[UIScreen mainScreen] scale];
    			[dateAnnotations addObject:layer];
                [self.layer addSublayer:layer];
    		}
    		sub_index++;
    	}
	}
	else if(period == _1M)
	{
		// Each vertex == 1 day. 1 annotation per calendar unit day == 1
        [outputFormat setDateFormat:@"d"];
		int sub_index = 0;   		
    	for(NSDate* dailyDate in displayDates)
    	{
    		NSDateComponents *calendarDay = [[NSCalendar currentCalendar]
                                            components:NSCalendarUnitDay
                                            fromDate:dailyDate];
            if([calendarDay day] % 3 < 1)
    		{
				CATextLayer* layer = [CATextLayer layer];
    			layer.string = [outputFormat stringFromDate:dailyDate];
    			CGPoint p = [self getGraphLineCoordsFor:sub_index+displayRange.location];
    			layer.frame = CGRectMake(p.x, self.bounds.size.height-15, 35, 25);
    			layer.foregroundColor = themeColor.CGColor;
    			layer.fontSize = 10.0f;
                layer.opacity = xAxisAnnotationOpacity;
                layer.contentsScale = [[UIScreen mainScreen] scale];
                layer.alignmentMode = kCAAlignmentCenter;
    			[dateAnnotations addObject:layer];
                [self.layer addSublayer:layer];
    		}
    		sub_index++;
    	}
	}
    else if(period == _6M)
	{
		// Each vertex == 1 day. 1 annotation per calendar month
        [outputFormat setDateFormat:@"LLL"];
		int sub_index = 0;
    	for(NSDate* dailyDate in displayDates)
    	{
    		NSDateComponents *calendarDay = [[NSCalendar currentCalendar]
                                            components:NSCalendarUnitDay
                                            fromDate:dailyDate];
            if([calendarDay day] == 1)
    		{
				CATextLayer* layer = [CATextLayer layer];
    			layer.string = [outputFormat stringFromDate:dailyDate];
    			CGPoint p = [self getGraphLineCoordsFor:sub_index+displayRange.location];
    			layer.frame = CGRectMake(p.x, self.bounds.size.height-15, 35, 25);
    			layer.foregroundColor = themeColor.CGColor;
    			layer.fontSize = 10.0f;
                layer.opacity = xAxisAnnotationOpacity;
                layer.alignmentMode = kCAAlignmentCenter;
                layer.contentsScale = [[UIScreen mainScreen] scale];
    			[dateAnnotations addObject:layer];
                [self.layer addSublayer:layer];
    		}
    		sub_index++;
    	}
	}

	else if(period == _1Y)
	{
        // Each vertex == 1 day. 1 annotation per calendar month
        [outputFormat setDateFormat:@"L"];
		int sub_index = 0;
    	for(NSDate* dailyDate in displayDates)
    	{
    		NSDateComponents *calendarDay = [[NSCalendar currentCalendar]
                                             components:NSCalendarUnitDay
                                             fromDate:dailyDate];
            if([calendarDay day] == 1)
    		{
				CATextLayer* layer = [CATextLayer layer];
    			layer.string = [outputFormat stringFromDate:dailyDate];
    			CGPoint p = [self getGraphLineCoordsFor:sub_index+displayRange.location];
    			layer.frame = CGRectMake(p.x, self.bounds.size.height-15, 35, 25);
    			layer.foregroundColor = themeColor.CGColor;
    			layer.fontSize = 10.0f;
                layer.opacity = xAxisAnnotationOpacity;
                layer.alignmentMode = kCAAlignmentCenter;
                layer.contentsScale = [[UIScreen mainScreen] scale];
    			[dateAnnotations addObject:layer];
                [self.layer addSublayer:layer];
    		}
    		sub_index++;
    	}

	}
	else if(period == _2Y)
	{
	}
}

-(NSString*)getStrAnnotationFor:(int)index newline:(bool)newline
{
    NSNumberFormatter* nf = [[NSNumberFormatter alloc] init];
    [nf setMaximumFractionDigits:0];
    
    NSDictionary* currencyUnicodes = [NSDictionary dictionaryWithObjectsAndKeys:
                        @"\u20ac",@"EUR", @"\u00a5",@"CNY", @"\u0024",@"CAD",
                        @"\u0024",@"USD", @"\u0024",@"AUD", @"R\u0024",@"BRL",
                        @"CHF",@"CHF", @"kr",@"DKK",@"\u00a3",@"GBP",
                        @"\u0024",@"HKD", @"\u20aa",@"ILS", @"\u00a5",@"JPY",
                        @"kr",@"NOK", @"\u0024",@"NZD", @"z\u0142",@"PLN",
                        @"\u0440",@"RUB", @"kr", @"SEK", @"\u0024",@"SGD",
                        @"\u0e3f",@"THB",
                        nil];
    
    NSString* currency = [self.symbol substringFromIndex: [self.symbol length] - 3];
    NSString* unicode = (NSString*)currencyUnicodes[currency];
    
    NSMutableString* displayStr = [NSMutableString stringWithFormat:@"%@%@ ",
                                   unicode,
                                   [nf stringFromNumber:(NSNumber*)prices[index]]];
    
    if(newline)
    {
        [displayStr appendString:@"\n"];
    }
    
    NSDate* indexDate = (NSDate*)dates[index];
    NSDate* today =  [NSDate date];
    
    NSDateComponents *indexDateCal = [[NSCalendar currentCalendar]
                                      components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear
                                      fromDate:indexDate];
    NSDateComponents *todayCal = [[NSCalendar currentCalendar]
                                  components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear
                                  fromDate:today];
    
    NSDateFormatter* df = [[NSDateFormatter alloc] init];
    
    if(self.period == _1M || self.period == _6M || self.period == _1Y || self.period == _2Y)
        [df setDateFormat:@"LLL d"];
    else
        [df setDateFormat:@"LLL d ha"];
    [df setTimeZone:[NSTimeZone localTimeZone]];
    
    if([todayCal year] != [indexDateCal year])
    {
    	[df setDateFormat:@"LLL d yyyy"];
    	[displayStr appendString:[df stringFromDate:indexDate]];
    }
    else if([todayCal day] == [indexDateCal day]
            && [todayCal month] == [indexDateCal month]
            && [todayCal year] == [indexDateCal year])
    {
    	[displayStr appendString:@"Today "];
        [df setDateFormat:@"ha"];
        [displayStr appendString:[df stringFromDate:indexDate]];
    }
    else if(([todayCal day] - [indexDateCal day]) == 1
            && [todayCal month] == [indexDateCal month]
            && [todayCal year] == [indexDateCal year])
    {
    	[displayStr appendString:@"Yday "];
    	[df setDateFormat:@"ha"];
    	[displayStr appendString:[df stringFromDate:indexDate]];
    }
    else
    {
		[displayStr appendString:[df stringFromDate:indexDate]];
    }
 
 	return displayStr;
}

-(void)updateCurrentDateLabelFormat
{
    centeredDate = (NSDate*)dates[displayRange.location + displayRange.length/2];
    NSDate* now = [NSDate date];
    NSDateComponents* nowCal = [[NSCalendar currentCalendar]
                                components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear
                                fromDate:now];
    NSDateComponents *centeredDateCal = [[NSCalendar currentCalendar]
                                         components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear
                                         fromDate:centeredDate];
    centeredDateLabelFormat = [[NSDateFormatter alloc] init];
    
    if(period == _1D)
    {
        if([centeredDateCal year] != [nowCal year])
            [centeredDateLabelFormat setDateFormat:@"LLL d yyyy"];
        else
            [centeredDateLabelFormat setDateFormat:@"LLL d"];
    }
    else if(period == _3D)
        [centeredDateLabelFormat setDateFormat:@"LLL yyyy"];
    else if(period == _1W)
        [centeredDateLabelFormat setDateFormat:@"LLL yyyy"];
    else if(period == _1M)
        [centeredDateLabelFormat setDateFormat:@"LLL yyyy"];
    else if(period == _6M)
        [centeredDateLabelFormat setDateFormat:@"yyyy"];
    else if(period == _1Y)
        [centeredDateLabelFormat setDateFormat:@"yyyy"];
    else if(period == _2Y)
    {
    //    NSDate* leftDate = (NSDate*)dates[displayRange.location];
    //    NSDate* rightDate = (NSDate*)dates[displayRange.location+displayRange.length-1];
        [centeredDateLabelFormat setDateFormat:@"yyyy"];
    }
    
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    [centeredDateLabel sizeToFit];
    centeredDateLabel.frame = CGRectMake(
                              self.bounds.size.width/2.0 - centeredDateLabel.frame.size.width/2,
                              centeredDateLabel.frame.origin.y,
                              centeredDateLabel.frame.size.width,
                              centeredDateLabel.frame.size.height);
    [CATransaction commit];
}

-(void)updateCurrentDateLabel
{
    if(b_centered_date_label_is_animating)
        return;
    
    NSDate* midDate = (NSDate*)dates[displayRange.location + displayRange.length/2];
    NSDateComponents *midDateCal = [[NSCalendar currentCalendar]
                                    components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear
                                    fromDate:midDate];
    
    NSDateComponents* centeredDateCal =[[NSCalendar currentCalendar]
                                        components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear
                                        fromDate:centeredDate];
    
    bool bSlideRight = NO;
    bool bSlideLeft = NO;
    
    if(period == _1D)
    {
        if([midDateCal day] < [centeredDateCal day])
        {
            if([midDateCal month] == [centeredDateCal month])
                bSlideRight = YES;
            else
                bSlideLeft = YES;
        }
        else if([midDateCal day] > [centeredDateCal day])
        {
            if([midDateCal month] == [centeredDateCal month])
                bSlideLeft = YES;
            else
                bSlideRight = YES;
        }
    }
    else if(period == _1W || period == _1M || period == _3D)
    {
        if([midDateCal month] < [centeredDateCal month])
        {
            if([midDateCal year] == [centeredDateCal year])
                bSlideRight = YES;
            else
                bSlideLeft = YES;
        }
        else if([midDateCal month] > [centeredDateCal month])
        {
            if([midDateCal year] == [centeredDateCal year])
                bSlideLeft = YES;
            else
                bSlideRight = YES;
        }
    }
    else if(period == _6M || period == _1Y || period == _2Y)
    {
        if([midDateCal year] < [centeredDateCal year])
            bSlideRight = YES;
        else if([midDateCal year] > [centeredDateCal year])
            bSlideLeft = YES;
    }
    
    CGRect r = centeredDateLabel.frame;
    
    if(bSlideRight)
    {
        centeredDate = midDate;
        centeredDateLabelAnimation.fromValue = [NSValue valueWithCGPoint:CGPointMake(
                                                r.origin.x,
                                                r.origin.y)];
        centeredDateLabelAnimation.toValue = [NSValue valueWithCGPoint:CGPointMake(
                                              self.bounds.size.width,
                                              r.origin.y)];
        [centeredDateLabelAnimation setValue:@"centeredDateScrollRightAnimation"
                                    forKey:@"id"];
        [centeredDateLabel.layer addAnimation:centeredDateLabelAnimation
                                 forKey:@"centeredDateScrollRightAnimation"];
        b_centered_date_label_is_animating = YES;
        
        [CATransaction begin];
        [CATransaction setDisableActions:YES];
        [centeredDateLabel sizeToFit];
        centeredDateLabel.frame = CGRectMake(
                                  r.size.width*-1,
                                  r.origin.y,
                                  r.size.width,
                                  r.size.height);
        [CATransaction commit];
    }
    else if(bSlideLeft)
    {
        centeredDate = midDate;
        centeredDateLabelAnimation.fromValue = [NSValue valueWithCGPoint:CGPointMake(
                                                r.origin.x,
                                                r.origin.y)];
        centeredDateLabelAnimation.toValue = [NSValue valueWithCGPoint:CGPointMake(
                                              r.size.width*-1,
                                              r.origin.y)];
        [centeredDateLabelAnimation setValue:@"centeredDateScrollLeftAnimation"
                                    forKey:@"id"];
        [centeredDateLabel.layer addAnimation:centeredDateLabelAnimation
                                 forKey:@"centeredDateScrollLeftAnimation"];
        b_centered_date_label_is_animating = YES;
        
        [CATransaction begin];
        [CATransaction setDisableActions:YES];
        [centeredDateLabel sizeToFit];
        centeredDateLabel.frame = CGRectMake(
                                  self.bounds.size.width,
                                  r.origin.y,
                                  r.size.width,
                                  r.size.height);
        [CATransaction commit];
    }
    else
    {
        centeredDateLabel.text = [centeredDateLabelFormat stringFromDate:midDate];
        [centeredDateLabel sizeToFit];
        
        [CATransaction begin];
        [CATransaction setDisableActions:YES];
        [centeredDateLabel sizeToFit];
        centeredDateLabel.frame = CGRectMake(
                                  self.bounds.size.width/2.0 - centeredDateLabel.frame.size.width/2,
                                  centeredDateLabel.frame.origin.y,
                                  centeredDateLabel.frame.size.width,
                                  centeredDateLabel.frame.size.height);
        [CATransaction commit];
    }
}

-(void)singleTap:(UITapGestureRecognizer *)sender
{
    if([prices count] == 0 || [dates count] == 0)
        return;
    
    CGPoint tapPoint = [sender locationInView:scrollView];
    CGPoint tapPointInView = [scrollView convertPoint:tapPoint
                                         toView:self.graphView];
    float n = tapPointInView.x / self.x_spacing;
    
    int tapped_index = 0;
    int tap_spread = 55;  // margin of tap error in y pixels
    
    if(fmodf(tapPointInView.x, self.x_spacing) == 0)
    {
        CGPoint vertexPoint = [self getGraphLineCoordsFor:(int)n];
        
        // Tapped exactly on the x coord of the vertex, do simple height check
        if(fabs(vertexPoint.y - tapPoint.y) < tap_spread)
            tapped_index = (int)n;
    }
    else
    {
        // Tapped between two vertices, test which one is closer
        unsigned int left_index = floor(n) + displayRange.location;
        unsigned int right_index = ceil(n) + displayRange.location;
        
        CGPoint leftVertexPoint = [self getGraphLineCoordsFor:left_index];
        CGPoint rightVertexPoint = [self getGraphLineCoordsFor:right_index];
        
        if((rightVertexPoint.x - tapPointInView.x) < (tapPointInView.x - leftVertexPoint.x))
        {
            // Right vertex closer
            if(fabs(rightVertexPoint.y - tapPointInView.y) < tap_spread)
                tapped_index = right_index;
        }
        else
        {
            // Left vertex closer
            if(fabs(leftVertexPoint.y - tapPointInView.y) < tap_spread)
                tapped_index = left_index;
        }
    }
    
    if(tapped_index > 0)
    {
        // caption and coordinate info calculated in plot method
        ((VertexAnnotation*)vertexAnnotations[TAPPED_VERTEX]).vertex_index = tapped_index;
        ((VertexAnnotation*)vertexAnnotations[TAPPED_VERTEX]).dot.hidden = FALSE;
        ((VertexAnnotation*)vertexAnnotations[TAPPED_VERTEX]).line.hidden = FALSE;
        ((VertexAnnotation*)vertexAnnotations[TAPPED_VERTEX]).caption.hidden = FALSE;
        ((VertexAnnotation*)vertexAnnotations[TAPPED_VERTEX]).background.hidden = FALSE;
        [self annotateVertices];
    }
    else
    {
        // Make it disappear
        ((VertexAnnotation*)vertexAnnotations[TAPPED_VERTEX]).vertex_index = 1;
        ((VertexAnnotation*)vertexAnnotations[TAPPED_VERTEX]).dot.hidden = YES;
        ((VertexAnnotation*)vertexAnnotations[TAPPED_VERTEX]).line.hidden = YES;
        ((VertexAnnotation*)vertexAnnotations[TAPPED_VERTEX]).caption.hidden = YES;
        ((VertexAnnotation*)vertexAnnotations[TAPPED_VERTEX]).background.hidden = YES;
        [self annotateVertices];
    }

  //  NSLog(@"Tapped x=%f, y=%f", vertexPoint.x, vertexPoint.y);
}

-(void)doubleTap:(UITapGestureRecognizer*)sender
{
    /*
    if([prices count] == 0 || [dates count] == 0)
        return;
    
    CGPoint tapPoint = [sender locationInView:scrollView];
    CGPoint tapPointInView = [scrollView convertPoint:tapPoint toView:self.graphView];
    int n = floor(tapPointInView.x / self.x_spacing);
    
    
    displayRange.location = n - displayRange.length/2;
    
    if(period >= 1)
    {
        period--;
        [self changePeriodTo:period];
   //     [self setSymbol:self.symbol withPeriod:period];
    }
    
    NSLog(@"Double tap!");
     */
}

-(void)scrollViewDidScroll:(UIScrollView *)sv
{
    if(dates == nil && prices == nil)
    {
        return;
    }
        
    ((VertexAnnotation*)vertexAnnotations[TAPPED_VERTEX]).dot.hidden = TRUE;
    ((VertexAnnotation*)vertexAnnotations[TAPPED_VERTEX]).line.hidden = TRUE;
    ((VertexAnnotation*)vertexAnnotations[TAPPED_VERTEX]).caption.hidden = TRUE;
    ((VertexAnnotation*)vertexAnnotations[TAPPED_VERTEX]).background.hidden = TRUE;
    
    // Left edge of scrollView (NOT graph though!)
    if(sv.contentOffset.x <= 0)
    {
        [sv scrollRectToVisible:CGRectMake(9600 - sv.bounds.size.width - 1,0,320,300)
            animated:NO];
        // Now scroll a bit more to the left to preserve the sense of velocity
        [sv scrollRectToVisible:CGRectMake(9600 - sv.bounds.size.width - 250,0,320,300)
            animated:YES];
        last_offset_x = 9600 - sv.bounds.size.width - 250;
        fraction_offset_x = 0.0f;
        return;
    }
    // Right edge of scrollView.
    else if(sv.contentOffset.x >= 9600 - sv.bounds.size.width)
    {
        [sv scrollRectToVisible:CGRectMake(1,0,320,300) animated:NO];
        last_offset_x = 0.0f;
        fraction_offset_x = 0.0f;
        
        return;
    }
    
    // Scrolled right
    if(sv.contentOffset.x > last_offset_x)
    {
    	if(displayRange.location + displayRange.length < [dates count])
    		fraction_offset_x += fabs(sv.contentOffset.x - last_offset_x);
    }
    // Scrolled left
    else
    {
    	if(displayRange.location > 0)
    		fraction_offset_x -= fabs(sv.contentOffset.x - last_offset_x);
    }
    
    if(fraction_offset_x > x_spacing)
    {
    	if(displayRange.location + displayRange.length + 1 <= [dates count])
    	{
            // Right edge of graph has null vertex. Cannot scroll to.
            if([dates[displayRange.location + displayRange.length] isEqual:[NSNull null]])
            {
                last_offset_x = sv.contentOffset.x;
                fraction_offset_x = 0.0f;
             //   NSLog(@"Scrolling to right graph edge");
                return;
            }
            
            // Scroll right
    		displayRange.location +=1;
        
            int prices_per_screen = [(NSNumber*)secondsInPeriod[period] intValue] / frequency;
            int min_buffer_size = MIN_BUFFER_SCREEN_LENGTH * prices_per_screen;
            int right_buffer_size = [dates count] - displayRange.location - displayRange.length;
            
            if(right_buffer_size <= min_buffer_size && bWaitingForRightBufferData == NO)
            {
                // If buffer isn't at right edge of graph already, query more right buffer
                if(![dates[[dates count]-1] isEqual:[NSNull null]])
                {
                    queried_right_buffer_timestamp = [(NSDate*)dates[[dates count]-1] timeIntervalSince1970]
                                                     + ([(NSNumber*)secondsInPeriod[period] intValue] * MAX_BUFFER_SCREEN_LENGTH);
                    int start = [(NSDate*)dates[[dates count]-1] timeIntervalSince1970]
                                + frequency;
                    bWaitingForRightBufferData = YES;
                    [self queryStart:start
                          end:queried_right_buffer_timestamp];
                }
            }
        }
    	fraction_offset_x = 0.0f;
        // NSLog(@"displayRange: [%lu-%lu]", displayIndices.location, displayIndices.location+displayIndices.length);
    }
    // Scroll left enough to uncover new vertex
    else if(fraction_offset_x < x_spacing*-1.0)
    {
        if(displayRange.location - 1 > 0)
        {
            displayRange.location -= 1;
            
            int prices_per_screen = [(NSNumber*)secondsInPeriod[period] intValue] / frequency;
            int min_buffer_size = MIN_BUFFER_SCREEN_LENGTH * prices_per_screen;
            
            if(displayRange.location <= min_buffer_size && bWaitingForLeftBufferData == NO)
            {
                if([dates[0] isEqual:[NSNull null]])
                {
                    // Left edge of graph in left buffer, not possible to query anymore data
                    NSLog(@"Left edge of graph.");
                }
                else
                {
                    queried_left_buffer_timestamp = [(NSDate*)dates[0] timeIntervalSince1970]
                                                    - ([(NSNumber*)secondsInPeriod[period] intValue] * MAX_BUFFER_SCREEN_LENGTH);
                    int queried_left_buffer_end_timestamp = [(NSDate*)dates[0] timeIntervalSince1970]
                                                            - frequency;
                    bWaitingForLeftBufferData = YES;
                    [self queryStart:queried_left_buffer_timestamp
                          end:queried_left_buffer_end_timestamp];
                }
            }
        }
       	fraction_offset_x = 0.0f;
        // NSLog(@"displayRange: [%lu-%lu]", displayIndices.location, displayIndices.location+displayIndices.length);
    }
    
    last_offset_x = sv.contentOffset.x;
    
    [self findMinMaxIndices];
    [self updatePriceDelta];
    [self updateCurrentDateLabel];
    [self draw:NO];
    
    //NSLog(@"didScroll: offsetX=%f", sv.contentOffset.x);
}

-(void)scrollViewWillBeginDragging:(UIScrollView *)sv
{
    dragDisplacement = sv.contentOffset;
}
-(void)scrollViewWillEndDragging:(UIScrollView *)sv
                    withVelocity:(CGPoint)velocity
             targetContentOffset:(inout CGPoint *)targetContentOffset
{
    dragVelocity = velocity;
}
-(void)scrollViewDidEndDragging:(UIScrollView *)sv
                 willDecelerate:(BOOL)decelerate
{}
-(void)scrollViewDidEndDecelerating:(UIScrollView *)sv
{}
-(void)scrollViewDidEndScrollingAnimation:(UIScrollView *)sv
{}
-(void)scrollViewDidEndZooming:(UIScrollView *)sv
                      withView:(UIView *)view atScale:(CGFloat)scale
{}

-(void)connection:(NSURLConnection *)c
didReceiveResponse:(NSURLResponse *)response
{
    connectionData = [NSMutableData data];
    [connectionData setLength:0];
}

-(void)connection:(NSURLConnection *)c
   didReceiveData:(NSData *)data
{
     [connectionData appendData:data];
}

-(void)connection:(NSURLConnection *)c
 didFailWithError:(NSError *)error
{
    NSLog(@"connection failed with error %@", error);
    
    statusCaptionLabel.hidden = false;
    statusCaptionLabel.text = @"Unable to connect to server for price history.";
    [retryConnectionButton setHidden:NO];
    prices = nil;
    dates = nil;
}

-(void)connectionDidFinishLoading:(NSURLConnection *)c
{
    NSString *responseString = [[NSString alloc] initWithData:connectionData
                                                 encoding:NSUTF8StringEncoding];
    NSError *e = nil;
    NSData *jsonData = [responseString dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary* historyData = [NSJSONSerialization JSONObjectWithData:jsonData
                                                     options: NSJSONReadingMutableContainers
                                                     error: &e];
    
    if(e != nil)
    {
        NSLog(@"Error in PriceGraph::connectionDidFinishLoading: %@", e);
        statusCaptionLabel.hidden = false;
        statusCaptionLabel.text = @"Error retrieving graph";
        [connection cancel];
        connection = nil;
        return;
    }
    
    [retryConnectionButton setHidden:YES];
    [loadSpinner stopAnimating];
    [loadSpinner setHidden:YES];
    
    NSMutableArray *con_prices = [[NSMutableArray alloc] init];
    NSMutableArray *con_dates = [[NSMutableArray alloc] init];
    
    for(id item in historyData)
    {
        [con_prices addObject:((NSDictionary*)item)[@"price"]];
        NSNumber* n = (NSNumber*)((NSDictionary*)item)[@"date"];
        [con_dates addObject:[NSDate dateWithTimeIntervalSince1970:[n doubleValue]]];
    }
    
    [self receiveData:con_prices :con_dates];
    [connection cancel];
    connection = nil;
}

@end
