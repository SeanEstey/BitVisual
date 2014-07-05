//  BVPriceGraph.h
//  BitVisual
//
//  Created by Sean Estey on 1/18/2014.
//  Copyright (c) 2014 Sean Estey. All rights reserved.
//


#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

typedef enum TimePeriod: NSUInteger {
	_1D,
    _3D,
	_1W,
	_1M,
	_6M,
	_1Y,
	_2Y
} TimePeriod;


struct VertexInfo
{
    bool animated;
    int text_y_offset;
};

@interface VertexAnnotation: NSObject

	@property (nonatomic) int vertex_index;
	@property (strong, nonatomic) CALayer* dot;
	@property (strong, nonatomic) CALayer* background;
	@property (strong, nonatomic) CAShapeLayer* line;
	@property (strong, nonatomic) CATextLayer* caption;
	@property (nonatomic) int y_vertex_offset; // how many pixels above/below vertex
	@property (strong, nonatomic) CABasicAnimation* animation;
	@property (nonatomic) bool animated;
	@property (nonatomic) bool hidden;
    @property (nonatomic) bool line_connects_at_top;
    @property (nonatomic) float dot_radius;

@end

@interface BVPriceGraph: UIView <UIScrollViewDelegate, NSURLConnectionDelegate>

@property (strong, nonatomic) NSMutableArray* dates;
@property (strong, nonatomic) NSMutableArray* prices;
@property (strong, nonatomic) NSString* symbol;
@property (strong, nonatomic) NSString* frequency_symbol;
@property (strong, nonatomic) NSString* getGraphURL;
@property (nonatomic) TimePeriod period;
@property (nonatomic) NSRange displayRange;
@property (strong, nonatomic) NSArray* minMaxIndices;
@property (strong, nonatomic) NSNumber* priceSpread;
@property (strong, nonatomic) NSNumber* tickerPrice;
@property (nonatomic) CGPoint dragVelocity;
@property (nonatomic) CGPoint dragDisplacement;
@property (nonatomic) float last_offset_x;
@property (nonatomic) float fraction_offset_x;
@property (nonatomic) float x_spacing;
@property (nonatomic) float top_y_padding;
@property (nonatomic) float bottom_y_padding;
@property (nonatomic) int num_horizontal_graphlines;
@property (nonatomic) bool lineDrawn;
@property (strong, nonatomic) UIView* graphView; // Primary view containing graph line, annotations, x-axis labels, etc
@property (strong, nonatomic) IBOutlet UILabel* priceDeltaLabel;
@property (strong, nonatomic) IBOutlet UILabel* statusCaptionLabel; // Loading, History not available, etc
@property (strong, nonatomic) IBOutlet UIButton* retryConnectionButton;
@property (strong, nonatomic) UIImageView *imageView;
@property (strong, nonatomic) UIActivityIndicatorView* loadSpinner;
@property (strong, nonatomic) UIScrollView* scrollView;
@property (strong, nonatomic) NSArray* vertexAnnotations;
@property (strong, nonatomic) NSMutableArray* dateAnnotations;
@property (strong, nonatomic) CAShapeLayer* graphLineLayer;
@property (strong, nonatomic) NSMutableArray* horizontalLineLayers; // contains CAShapeLayer*
@property (strong, nonatomic) NSDictionary *annotationAttributes;
@property (strong, nonatomic) CAGradientLayer* gradientLayer;
@property (strong, nonatomic) UIBezierPath* linePath;
@property (strong, nonatomic) CABasicAnimation* lineAnimation;
@property (strong, nonatomic) UIColor* themeColor;
@property (strong, nonatomic) NSMutableData* connectionData;
@property (strong, nonatomic) NSURLConnection* connection;
@property (strong, nonatomic) NSArray* secondsInPeriod;
@property (nonatomic) unsigned int queried_display_start_timestamp;
@property (nonatomic) unsigned int queried_display_end_timestamp;
@property (nonatomic) unsigned int queried_left_buffer_timestamp;
@property (nonatomic) unsigned int queried_right_buffer_timestamp;
@property (nonatomic) int frequency;
@property (nonatomic) bool bWaitingForDisplayData;
@property (nonatomic) bool bWaitingForLeftBufferData;
@property (nonatomic) bool bWaitingForRightBufferData;
@property (nonatomic) bool bMostRecentData;
@property (strong, nonatomic) NSDate* lastRightEdgeUpdate;
@property (strong, nonatomic) IBOutlet UILabel* centeredDateLabel;
@property (strong, nonatomic) NSDateFormatter* centeredDateLabelFormat;
@property (nonatomic) bool b_centered_date_label_is_animating;
@property (strong, nonatomic) NSDate* centeredDate;
@property (strong, nonatomic) CABasicAnimation* centeredDateLabelAnimation;

-(id)initWithFrame:(CGRect) frame;
-(void)setThemeColor:(UIColor*)color;
-(void)clear;
-(void)load;
-(void)annotateXAxis;
-(void)findMinMaxIndices;
-(void)updatePriceDelta;
-(void)queryStart:(int)start end:(int)end;
-(void)queryLatest:(int)records;
-(void)draw:(bool)animated;
-(void)drawHorizontalGraphLines;
-(void)plot:(bool)animatedLine;
-(void)annotateVertices;
-(void)receiveData:(NSArray*)priceData :(NSArray*)dateData;
-(void)setSymbol:(NSString*)s withPeriod:(enum TimePeriod)p;
-(void)changePeriodTo:(enum TimePeriod)p;
-(CGPoint)getGraphLineCoordsFor:(int)datapointIndex;
-(NSString*)getStrAnnotationFor:(int)index newline:(bool)newline;
-(void)updateCurrentDateLabelFormat;
-(void)updateCurrentDateLabel;


@end