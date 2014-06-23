#import "BVMenu.h"

@interface BVMenu ()
@property(nonatomic, strong) UITableView *table;
@property(nonatomic, strong) UIButton *btnSender;
@property(nonatomic, retain) NSArray *list;
@property(nonatomic, retain) NSArray *imageList;
@end

@implementation BVMenu
@synthesize table;
@synthesize btnSender;
@synthesize list;
@synthesize imageList;
@synthesize delegate;
@synthesize animationDirection;
@synthesize menuCaption;

-(id)showDropDown:(UIButton*)button hasWidth:(float)w hasHeight:(float)h hasItems:(NSArray*)items direction:(NSString*)dir editsSenderOnSelect:(bool)val caption:(NSString *)c
{
    edits_sender_title_on_select = val;
    btnSender = button;
    animationDirection = dir;
    self.table = (UITableView *)[super init];
    width = w;
    height = h;
    
    if (self)
    {
        CGRect btn = button.frame;
        self.list = items;
        
        if ([animationDirection isEqualToString:@"up"])
        {
            self.frame = CGRectMake(btn.origin.x, btn.origin.y, width, 0);
            self.layer.shadowOffset = CGSizeMake(-5, -5);
        }
        else if ([animationDirection isEqualToString:@"down"])
        {
            self.frame = CGRectMake(btn.origin.x, btn.origin.y+btn.size.height, width, 0);
            self.layer.shadowOffset = CGSizeMake(-5, 5);
            menuCaption = [[UILabel alloc]initWithFrame:CGRectMake(0, -25, width,20)];
            menuCaption.textAlignment = NSTextAlignmentCenter;
            menuCaption.text = c;
            [menuCaption setFont:[UIFont fontWithName:@"Arial-BoldMT" size:16]];
            menuCaption.textColor = [UIColor whiteColor];
            [self addSubview:menuCaption];
        }
        
        self.layer.masksToBounds = NO;
        self.layer.cornerRadius = 8;
 //       self.layer.shadowRadius = 5;
  //      self.layer.shadowOpacity = 1;
        
        table = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, width, 0)];
        table.delegate = self;
        table.dataSource = self;
        table.layer.cornerRadius = 5;
        table.backgroundColor = [UIColor clearColor];
        table.scrollEnabled = true;
        table.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
        table.separatorColor = [UIColor whiteColor];
        
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:0.5];
        if ([animationDirection isEqualToString:@"up"])
            self.frame = CGRectMake(btn.origin.x, btn.origin.y-height, width, height);
        else if([animationDirection isEqualToString:@"down"])
            self.frame = CGRectMake(btn.origin.x, btn.origin.y+btn.size.height, width, height);
        table.frame = CGRectMake(0, 0, width, height);
        [UIView commitAnimations];
        [button.superview addSubview:self];
        [self addSubview:table];
    }
    return self;
}

-(void)hideDropDown:(UIButton *)button
{
    table.hidden = YES;
    menuCaption.hidden = YES;

    
    CGRect btn = button.frame;
    
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.5];
    
    if ([animationDirection isEqualToString:@"up"])
        self.frame = CGRectMake(btn.origin.x, btn.origin.y, btn.size.width, 0);
    else if ([animationDirection isEqualToString:@"down"])
        self.frame = CGRectMake(btn.origin.x, btn.origin.y+btn.size.height, btn.size.width, 0);
    
    table.frame = CGRectMake(0, 0, btn.size.width, 0);
    [UIView commitAnimations];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 40;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.list count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.textLabel.font = [UIFont systemFontOfSize:15];
        cell.textLabel.textColor = [UIColor whiteColor];
        cell.textLabel.textAlignment = NSTextAlignmentCenter; // UITextAlignmentCenter;
    }
    
    cell.backgroundColor = [UIColor clearColor];
    
    if ([self.imageList count] == [self.list count])
        cell.textLabel.text =[list objectAtIndex:indexPath.row];
    else if ([self.imageList count] > [self.list count])
        cell.textLabel.text =[list objectAtIndex:indexPath.row];
    else if ([self.imageList count] < [self.list count])
        cell.textLabel.text =[list objectAtIndex:indexPath.row];
    
    UIView * v = [[UIView alloc] init];
  //  v.backgroundColor = [UIColor grayColor];
     v.backgroundColor = [UIColor clearColor];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self hideDropDown:btnSender];
    
    UITableViewCell *c = [tableView cellForRowAtIndexPath:indexPath];
    
    if(edits_sender_title_on_select == TRUE)
        [btnSender setTitle:c.textLabel.text forState:UIControlStateNormal];
    
    [self myDelegate:indexPath];
}

- (void) myDelegate:(NSIndexPath*)indexPath
{
    [self.delegate niDropDownDelegateMethod:self path:indexPath];
}

-(void)dealloc
{

}

@end
