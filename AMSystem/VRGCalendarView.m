//
//  VRGCalendarView.m
//  Vurig
//
//  Created by in 't Veen Tjeerd on 5/8/12.
//  Copyright (c) 2012 Vurig Media. All rights reserved.
//

#import "VRGCalendarView.h"
#import <QuartzCore/QuartzCore.h>
#import "NSDate+convenience.h"
#import "NSMutableArray+convenience.h"
#import "UIView+convenience.h"
#import "AMSystemManager.h"//


@implementation VRGCalendarView
@synthesize currentMonth,delegate,labelCurrentMonth, animationView_A,animationView_B;
@synthesize markedDates,markedColors,calendarHeight,selectedDate;

#pragma mark - Select Date
-(void)selectDate:(int)date {
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *comps = [gregorian components:NSYearCalendarUnit | NSMonthCalendarUnit |  NSDayCalendarUnit fromDate:self.currentMonth];
    [comps setDay:date];
    self.selectedDate = [gregorian dateFromComponents:comps];
    
    int selectedDateYear = [selectedDate year];
    int selectedDateMonth = [selectedDate month];
    int currentMonthYear = [currentMonth year];
    int currentMonthMonth = [currentMonth month];
    
    if (selectedDateYear < currentMonthYear) {
        [self showPreviousMonth];
    } else if (selectedDateYear > currentMonthYear) {
        [self showNextMonth];
    } else if (selectedDateMonth < currentMonthMonth) {
        [self showPreviousMonth];
    } else if (selectedDateMonth > currentMonthMonth) {
        [self showNextMonth];
    } else {
        [self setNeedsDisplay];
    }
    
    if ([delegate respondsToSelector:@selector(calendarView:dateSelected:)]) [delegate calendarView:self dateSelected:self.selectedDate];
}

#pragma mark - Mark Dates
//NSArray can either contain NSDate objects or NSNumber objects with an int of the day.

-(void)markDates:(NSArray *)dates {
    
    self.markedDates = [NSArray arrayWithArray:dates];
//    NSMutableArray *colors = [[NSMutableArray alloc] init];
//
//    for (int i = 0; i<[dates count]; i++) {
//        
////        [colors addObject:[UIColor colorWithHexString:@"FF0000"]];////
//        [colors addObject:[UIColor colorWithHexString:@"#FF00FF"]];
//    }
//    
//    self.markedColors = [NSArray arrayWithArray:colors];
//   
//    
//    [self setNeedsDisplay];
}

-(NSArray *)libRandDays{
    NSMutableArray *randomArr = [[NSMutableArray alloc] init];
    
    do {
        int random = arc4random()%27 +1;
        
        NSString *randomString = [NSString stringWithFormat:@"%d",random];
        
        if (![randomArr containsObject:randomString]) {
            [randomArr addObject:randomString];
        }
        else{
            NSLog(@"数组中有已有该随机数，重新取数！");
        }
        
    } while (randomArr.count != 10);
    return randomArr;
}
-(NSDictionary *)permitMarkDatasSetRedColor:(NSString *)day{
//    self.markedDates=[self libRandDays];
    //@[@"3",@"5",@"6",@"12",@"13",@"14"]
    NSMutableDictionary *dict=[[NSMutableDictionary alloc]init];
    NSString *temp_string=day;
    if (temp_string.length==1) {
        temp_string=[NSString stringWithFormat:@"0%@",temp_string];
    }
    for (int i=0; i<self.markedDates.count; i++) {
        if ([self daysIsEqualForSourceDay:[[self.markedDates objectAtIndex:i] objectForKey:@"date"] andNowUseDay:day]) {
            dict=[NSMutableDictionary dictionaryWithDictionary:[self.markedDates objectAtIndex:i]];
            [dict setObject:@"1" forKey:@"result"];
            [dict setObject:[NSString stringWithFormat:@"%d",i] forKey:@"index"];
            return dict;
        }
//        NSString *day_string=[[self.markedDates objectAtIndex:i] objectForKey:@"date"];
//        if (day_string.length!=2&&day_string.length==10) {
//            day_string=[day_string substringFromIndex:5];
//        }
//        
//        if ([day_string isEqualToString:temp_string]) {
//            return YES;
//        }
//        if ([[[self.markedDates objectAtIndex:i] objectForKey:@"day"] isEqualToString:day]) {
//            return YES;
//        }
    }
    [dict setObject:@"0" forKey:@"result"];
    return dict;
}

-(BOOL)daysIsEqualForSourceDay:(NSString *)dayString andNowUseDay:(NSString *)day{
    if (dayString.length==10) {
        dayString=[dayString substringFromIndex:8];
        if (day.length!=2) {
            if (day.length<2) {
                day=[NSString stringWithFormat:@"0%@",day];
            }
        }
        if ([dayString isEqualToString:day]) {
            return YES;
        }
    }
    return NO;
}
//NSArray can either contain NSDate objects or NSNumber objects with an int of the day.
-(void)markDates:(NSArray *)dates withColors:(NSArray *)colors {
    self.markedDates = dates;
    self.markedColors = colors;
    
    [self setNeedsDisplay];
}

#pragma mark - Set date to now
-(void)reset {
    NSCalendar *gregorian = [[NSCalendar alloc]
                             initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *components =
    [gregorian components:(NSYearCalendarUnit | NSMonthCalendarUnit |
                           NSDayCalendarUnit) fromDate: [NSDate date]];
    self.currentMonth = [gregorian dateFromComponents:components]; //clean month
    
    [self updateSize];
    [self setNeedsDisplay];
    [delegate calendarView:self switchedToMonth:[currentMonth month] targetHeight:self.calendarHeight animated:NO];
}

#pragma mark - Next & Previous
-(void)showNextMonth {
    if (isAnimating) return;
    self.markedDates=nil;
    isAnimating=YES;
    prepAnimationNextMonth=YES;
    
    [self setNeedsDisplay];
    
    int lastBlock = [currentMonth firstWeekDayInMonth]+[currentMonth numDaysInMonth]-1;
    int numBlocks = [self numRows]*7;
    BOOL hasNextMonthDays = lastBlock<numBlocks;
    
    //Old month
    float oldSize = self.calendarHeight;
    UIImage *imageCurrentMonth = [self drawCurrentState];
    
    //New month
    self.currentMonth = [currentMonth offsetMonth:1];
    if ([delegate respondsToSelector:@selector(calendarView:switchedToMonth:targetHeight: animated:)]) [delegate calendarView:self switchedToMonth:[currentMonth month] targetHeight:self.calendarHeight animated:YES];
    prepAnimationNextMonth=NO;
    [self setNeedsDisplay];
    
    UIImage *imageNextMonth = [self drawCurrentState];
    float targetSize = fmaxf(oldSize, self.calendarHeight);
    UIView *animationHolder = [[UIView alloc] initWithFrame:CGRectMake(0, kVRGCalendarViewTopBarHeight, kVRGCalendarViewWidth, targetSize-kVRGCalendarViewTopBarHeight)];
    [animationHolder setClipsToBounds:YES];
    [self addSubview:animationHolder];
  
    
    //Animate
    self.animationView_A = [[UIImageView alloc] initWithImage:imageCurrentMonth];
    self.animationView_B = [[UIImageView alloc] initWithImage:imageNextMonth];
    [animationHolder addSubview:animationView_A];
    [animationHolder addSubview:animationView_B];
    
    if (hasNextMonthDays) {
        animationView_B.frameY = animationView_A.frameY + animationView_A.frameHeight - (kVRGCalendarViewDayHeight+3);
    } else {
        animationView_B.frameY = animationView_A.frameY + animationView_A.frameHeight -3;
    }
    
    //Animation
    __block VRGCalendarView *blockSafeSelf = self;
    [UIView animateWithDuration:.35
                     animations:^{
                         [self updateSize];
                         //blockSafeSelf.frameHeight = 100;
                         if (hasNextMonthDays) {
                             animationView_A.frameY = -animationView_A.frameHeight + kVRGCalendarViewDayHeight+3;
                         } else {
                             animationView_A.frameY = -animationView_A.frameHeight + 3;
                         }
                         animationView_B.frameY = 0;
                     }
                     completion:^(BOOL finished) {
                         [animationView_A removeFromSuperview];
                         [animationView_B removeFromSuperview];
                         blockSafeSelf.animationView_A=nil;
                         blockSafeSelf.animationView_B=nil;
                         isAnimating=NO;
                         [animationHolder removeFromSuperview];
                     }
     ];
}

-(void)showPreviousMonth {
    if (isAnimating) return;
    isAnimating=YES;
    self.markedDates=nil;
    //Prepare current screen
    prepAnimationPreviousMonth = YES;
    [self setNeedsDisplay];
    BOOL hasPreviousDays = [currentMonth firstWeekDayInMonth]>1;
    float oldSize = self.calendarHeight;
    UIImage *imageCurrentMonth = [self drawCurrentState];
    
    //Prepare next screen
    self.currentMonth = [currentMonth offsetMonth:-1];
    if ([delegate respondsToSelector:@selector(calendarView:switchedToMonth:targetHeight:animated:)]) [delegate calendarView:self switchedToMonth:[currentMonth month] targetHeight:self.calendarHeight animated:YES];
    prepAnimationPreviousMonth=NO;
    [self setNeedsDisplay];
    UIImage *imagePreviousMonth = [self drawCurrentState];
    
    float targetSize = fmaxf(oldSize, self.calendarHeight);
    UIView *animationHolder = [[UIView alloc] initWithFrame:CGRectMake(0, kVRGCalendarViewTopBarHeight, kVRGCalendarViewWidth, targetSize-kVRGCalendarViewTopBarHeight)];
    
    [animationHolder setClipsToBounds:YES];
    [self addSubview:animationHolder];
  
    
    self.animationView_A = [[UIImageView alloc] initWithImage:imageCurrentMonth];
    self.animationView_B = [[UIImageView alloc] initWithImage:imagePreviousMonth];
    [animationHolder addSubview:animationView_A];
    [animationHolder addSubview:animationView_B];
    
    if (hasPreviousDays) {
        animationView_B.frameY = animationView_A.frameY - (animationView_B.frameHeight-kVRGCalendarViewDayHeight) + 3;
    } else {
        animationView_B.frameY = animationView_A.frameY - animationView_B.frameHeight + 3;
    }
    
    __block VRGCalendarView *blockSafeSelf = self;
    [UIView animateWithDuration:.35
                     animations:^{
                         [self updateSize];
                         
                         if (hasPreviousDays) {
                             animationView_A.frameY = animationView_B.frameHeight-(kVRGCalendarViewDayHeight+3); 
                             
                         } else {
                             animationView_A.frameY = animationView_B.frameHeight-3;
                         }
                         
                         animationView_B.frameY = 0;
                     }
                     completion:^(BOOL finished) {
                         [animationView_A removeFromSuperview];
                         [animationView_B removeFromSuperview];
                         blockSafeSelf.animationView_A=nil;
                         blockSafeSelf.animationView_B=nil;
                         isAnimating=NO;
                         [animationHolder removeFromSuperview];
                     }
     ];
}


#pragma mark - update size & row count
-(void)updateSize {
    self.frameHeight = self.calendarHeight;
    [self setNeedsDisplay];
}

-(float)calendarHeight {
    return kVRGCalendarViewTopBarHeight + [self numRows]*(kVRGCalendarViewDayHeight+2)+1;
}

-(int)numRows {
    float lastBlock = [self.currentMonth numDaysInMonth]+([self.currentMonth firstWeekDayInMonth]-1);
    return ceilf(lastBlock/7);
}

#pragma mark - Touches
-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event 
{       
    UITouch *touch = [touches anyObject];
    CGPoint touchPoint = [touch locationInView:self];
    
    self.selectedDate=nil;
    
    //Touch a specific day
    if (touchPoint.y > kVRGCalendarViewTopBarHeight) {
        float xLocation = touchPoint.x;
        float yLocation = touchPoint.y-kVRGCalendarViewTopBarHeight;
        
        int column = floorf(xLocation/(kVRGCalendarViewDayWidth+2));
        int row = floorf(yLocation/(kVRGCalendarViewDayHeight+2));
        
        int blockNr = (column+1)+row*7;
        int firstWeekDay = [self.currentMonth firstWeekDayInMonth]-1; //-1 because weekdays begin at 1, not 0
        int date = blockNr-firstWeekDay;
        [self selectDate:date];
        return;
    }
    
    self.markedDates=nil;
    self.markedColors=nil;  
    
    CGRect rectArrowLeft = CGRectMake(0, 0, 50, 40);
    CGRect rectArrowRight = CGRectMake(self.frame.size.width-50, 0, 50, 40);
    
    //Touch either arrows or month in middle
    if (CGRectContainsPoint(rectArrowLeft, touchPoint)) {
        [self showPreviousMonth];
    } else if (CGRectContainsPoint(rectArrowRight, touchPoint)) {
        [self showNextMonth];
    } else if (CGRectContainsPoint(self.labelCurrentMonth.frame, touchPoint)) {
        //Detect touch in current month
        int currentMonthIndex = [self.currentMonth month];
        int todayMonth = [[NSDate date] month];
        [self reset];
        if ((todayMonth!=currentMonthIndex) && [delegate respondsToSelector:@selector(calendarView:switchedToMonth:targetHeight:animated:)]) [delegate calendarView:self switchedToMonth:[currentMonth month] targetHeight:self.calendarHeight animated:NO];
    }
}

#pragma mark - Drawing
- (void)drawRect:(CGRect)rect
{
    int firstWeekDay = [self.currentMonth firstWeekDayInMonth]-1; //-1 because weekdays begin at 1, not 0
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"MMMM yyyy"];
    NSDateFormatter *formatter2 = [[NSDateFormatter alloc] init];
    
    [formatter2 setDateFormat:@"yyyy  MM"];
    NSString *date1 = [formatter2 stringFromDate:self.currentMonth];
    //第一次进来如果字符串里有中文，文本不显示内容
    labelCurrentMonth.text=date1;
    NSLog(@"labelCurrentMonth.text:%@",labelCurrentMonth.text);
    [labelCurrentMonth sizeToFit];
    labelCurrentMonth.frameX = roundf(self.frame.size.width/2 - labelCurrentMonth.frameWidth/2);
    labelCurrentMonth.frameY = 10;
    
    [currentMonth firstWeekDayInMonth];
    
    CGContextClearRect(UIGraphicsGetCurrentContext(),rect);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGRect rectangle = CGRectMake(0,0,self.frame.size.width,kVRGCalendarViewTopBarHeight);
    CGContextAddRect(context, rectangle);
    CGContextSetFillColorWithColor(context, [UIColor whiteColor].CGColor);
    CGContextFillPath(context);
    
//    //Arrows
//    int arrowSize = 12;
//    int xmargin = 20;
//    int ymargin = 18;
//    
//    //Arrow Left
////    UIImage *newImage=[self image:[UIImage imageNamed:@"rephotograph.png"] rotation:UIImageOrientationLeft];
////    CGContextDrawImage(context, CGRectMake(20, 20, 20, 20), newImage.CGImage);
//
//    CGContextBeginPath(context);
//    CGContextMoveToPoint(context, xmargin+arrowSize/1.5, ymargin);
//    CGContextAddLineToPoint(context,xmargin+arrowSize/1.5,ymargin+arrowSize);
//    CGContextAddLineToPoint(context,xmargin,ymargin+arrowSize/2);
//    CGContextAddLineToPoint(context,xmargin+arrowSize/1.5, ymargin);
//    
//    CGContextSetFillColorWithColor(context, 
//                                   [UIColor blackColor].CGColor);
//    CGContextFillPath(context);
//    
//    //Arrow right
//    CGContextBeginPath(context);
//    CGContextMoveToPoint(context, self.frame.size.width-(xmargin+arrowSize/1.5), ymargin);
//    CGContextAddLineToPoint(context,self.frame.size.width-xmargin,ymargin+arrowSize/2);
//    CGContextAddLineToPoint(context,self.frame.size.width-(xmargin+arrowSize/1.5),ymargin+arrowSize);
//    CGContextAddLineToPoint(context,self.frame.size.width-(xmargin+arrowSize/1.5), ymargin);
//    
//    CGContextSetFillColorWithColor(context, 
//                                   [UIColor blackColor].CGColor);
//    CGContextFillPath(context);
    
    //Weekdays
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat=@"EEE";
    //always assume gregorian with monday first
    NSMutableArray *weekdays = [[NSMutableArray alloc] initWithArray:[dateFormatter shortWeekdaySymbols]];
    [weekdays moveObjectFromIndex:0 toIndex:6];
    //55;107;187
    CGContextSetFillColorWithColor(context, 
                                   [UIColor colorWithHexString:@"376AAA"].CGColor);
    for (int i =0; i<[weekdays count]; i++) {
        NSString *weekdayValue = (NSString *)[weekdays objectAtIndex:i];
        UIFont *font = [UIFont fontWithName:@"HelveticaNeue" size:12];
        [weekdayValue drawInRect:CGRectMake(i*(kVRGCalendarViewDayWidth+2), 40, kVRGCalendarViewDayWidth+2, 20) withFont:font lineBreakMode:NSLineBreakByCharWrapping alignment:NSTextAlignmentCenter];
    }
    
    int numRows = [self numRows];
    
    CGContextSetAllowsAntialiasing(context, NO);
    
    //Grid background
    float gridHeight = numRows*(kVRGCalendarViewDayHeight+2)+1;
    CGRect rectangleGrid = CGRectMake(0,kVRGCalendarViewTopBarHeight,self.frame.size.width,gridHeight);
    CGContextAddRect(context, rectangleGrid);
    CGContextSetFillColorWithColor(context, [UIColor colorWithHexString:@"0xf3f3f3"].CGColor);//背景颜色
    //CGContextSetFillColorWithColor(context, [UIColor colorWithHexString:@"0xff0000"].CGColor);
    CGContextFillPath(context);
    //Grid white lines
    CGContextSetStrokeColorWithColor(context, [UIColor whiteColor].CGColor);
    CGContextBeginPath(context);
    CGContextMoveToPoint(context, 0, kVRGCalendarViewTopBarHeight+1);
    CGContextAddLineToPoint(context, kVRGCalendarViewWidth, kVRGCalendarViewTopBarHeight+1);
    for (int i = 1; i<7; i++) {
        CGContextMoveToPoint(context, i*(kVRGCalendarViewDayWidth+1)+i*1-1, kVRGCalendarViewTopBarHeight);
        CGContextAddLineToPoint(context, i*(kVRGCalendarViewDayWidth+1)+i*1-1, kVRGCalendarViewTopBarHeight+gridHeight);
        
        if (i>numRows-1) continue;
        //rows
        CGContextMoveToPoint(context, 0, kVRGCalendarViewTopBarHeight+i*(kVRGCalendarViewDayHeight+1)+i*1+1);
        CGContextAddLineToPoint(context, kVRGCalendarViewWidth, kVRGCalendarViewTopBarHeight+i*(kVRGCalendarViewDayHeight+1)+i*1+1);
    }
    
    CGContextStrokePath(context);
    
    //Grid dark lines
    CGContextSetStrokeColorWithColor(context, [UIColor colorWithHexString:@"0xcfd4d8"].CGColor);
    CGContextBeginPath(context);
    CGContextMoveToPoint(context, 0, kVRGCalendarViewTopBarHeight);
    CGContextAddLineToPoint(context, kVRGCalendarViewWidth, kVRGCalendarViewTopBarHeight);
    for (int i = 1; i<7; i++) {
        //columns
        CGContextMoveToPoint(context, i*(kVRGCalendarViewDayWidth+1)+i*1, kVRGCalendarViewTopBarHeight);
        CGContextAddLineToPoint(context, i*(kVRGCalendarViewDayWidth+1)+i*1, kVRGCalendarViewTopBarHeight+gridHeight);
        
        if (i>numRows-1) continue;
        //rows
        CGContextMoveToPoint(context, 0, kVRGCalendarViewTopBarHeight+i*(kVRGCalendarViewDayHeight+1)+i*1);
        CGContextAddLineToPoint(context, kVRGCalendarViewWidth, kVRGCalendarViewTopBarHeight+i*(kVRGCalendarViewDayHeight+1)+i*1);
    }
    CGContextMoveToPoint(context, 0, gridHeight+kVRGCalendarViewTopBarHeight);
    CGContextAddLineToPoint(context, kVRGCalendarViewWidth, gridHeight+kVRGCalendarViewTopBarHeight);
    
    CGContextStrokePath(context);
    
    CGContextSetAllowsAntialiasing(context, YES);
    
    //Draw days
    CGContextSetFillColorWithColor(context, 
                                   [UIColor colorWithHexString:@"0x383838"].CGColor);
    
    
    //NSLog(@"currentMonth month = %i, first weekday in month = %i",[self.currentMonth month],[self.currentMonth firstWeekDayInMonth]);
    
    int numBlocks = numRows*7;
    NSDate *previousMonth = [self.currentMonth offsetMonth:-1];
    int currentMonthNumDays = [currentMonth numDaysInMonth];
    int prevMonthNumDays = [previousMonth numDaysInMonth];
    
    int selectedDateBlock = ([selectedDate day]-1)+firstWeekDay;
    
    //prepAnimationPreviousMonth nog wat mee doen
    
    //prev next month
    BOOL isSelectedDatePreviousMonth = prepAnimationPreviousMonth;
    BOOL isSelectedDateNextMonth = prepAnimationNextMonth;
    
    if (self.selectedDate!=nil) {
        isSelectedDatePreviousMonth = ([selectedDate year]==[currentMonth year] && [selectedDate month]<[currentMonth month]) || [selectedDate year] < [currentMonth year];
        
        if (!isSelectedDatePreviousMonth) {
            isSelectedDateNextMonth = ([selectedDate year]==[currentMonth year] && [selectedDate month]>[currentMonth month]) || [selectedDate year] > [currentMonth year];
        }
    }
    
    if (isSelectedDatePreviousMonth) {
        int lastPositionPreviousMonth = firstWeekDay-1;
        selectedDateBlock=lastPositionPreviousMonth-([selectedDate numDaysInMonth]-[selectedDate day]);
    } else if (isSelectedDateNextMonth) {
        selectedDateBlock = [currentMonth numDaysInMonth] + (firstWeekDay-1) + [selectedDate day];
    }
    
    
    NSDate *todayDate = [NSDate date];
    int todayBlock = -1;
    
//    NSLog(@"currentMonth month = %i day = %i, todaydate day = %i",[currentMonth month],[currentMonth day],[todayDate month]);
    
    if ([todayDate month] == [currentMonth month] && [todayDate year] == [currentMonth year]) {
        todayBlock = [todayDate day] + firstWeekDay - 1;
    }
    
    for (int i=0; i<numBlocks; i++) {
        int targetDate = i;
        int targetColumn = i%7;
        int targetRow = i/7;
        int targetX = targetColumn * (kVRGCalendarViewDayWidth+2);
        int targetY = kVRGCalendarViewTopBarHeight + targetRow * (kVRGCalendarViewDayHeight+2);
        //字体颜色...
        // BOOL isCurrentMonth = NO;
        if (i<firstWeekDay) { //previous month
            targetDate = (prevMonthNumDays-firstWeekDay)+(i+1);
//            NSString *hex = (isSelectedDatePreviousMonth) ? @"0x383838" : @"aaaaaa";
            
//            CGContextSetFillColorWithColor(context, 
//                                           [UIColor colorWithHexString:hex].CGColor);
            CGContextSetRGBFillColor(context, 0.8, 0.8, 0.8, 1.0);
//            CGContextSetFillColorWithColor(context,
//                                           [UIColor grayColor].CGColor);

        } else if (i>=(firstWeekDay+currentMonthNumDays)) { //next month
            targetDate = (i+1) - (firstWeekDay+currentMonthNumDays);
//            NSString *hex = (isSelectedDateNextMonth) ? @"0x383838" : @"aaaaaa";
//            CGContextSetFillColorWithColor(context,
//                                           [UIColor colorWithHexString:hex].CGColor);
            CGContextSetFillColorWithColor(context,
                                        [UIColor grayColor].CGColor);

        } else { //current month
            // isCurrentMonth = YES;
            targetDate = (i-firstWeekDay)+1;
//            NSString *hex = (isSelectedDatePreviousMonth || isSelectedDateNextMonth) ? @"0xaaaaaa" : @"0x383838";
//            CGContextSetFillColorWithColor(context,
//                                           [UIColor colorWithHexString:hex].CGColor);
            CGContextSetRGBFillColor(context, 0.8, 0.8, 0.8, 1.0);
//            CGContextSetFillColorWithColor(context,
//                                           [UIColor greenColor].CGColor);

        }
        
        NSString *date = [NSString stringWithFormat:@"%i",targetDate];
        //背景颜色...
        //draw selected date
//        NSData *now_month=currentMonth;´
        if ([date integerValue]<=i+1) {
            if (i>=(firstWeekDay+currentMonthNumDays)) {//下月
            }
            else{
                //本月
                NSDictionary *day_infomationDict=[self permitMarkDatasSetRedColor:date];
                if (todayBlock==i) {//当天的
                    CGContextSetLineWidth(context, 2.0);
                    CGRect rectangleGrid = CGRectMake(targetX,targetY,kVRGCalendarViewDayWidth+2,kVRGCalendarViewDayHeight+2);
                    CGContextAddRect(context, rectangleGrid);
                    //绿色边框
//                    CGContextSetRGBStrokeColor(context, 0.3, 0.72, 0.3, 1.0);
//                    CGContextStrokePath(context);
                    CGContextSetRGBFillColor(context, 38/256.0, 109/256.0, 191/256.0, 1.0f);
                    CGContextFillRect(context, rectangleGrid);
//                    CGContextSetFillColorWithColor(context, [UIColor yellowColor].CGColor);//当日
                    CGContextFillPath(context);
                    
                    CGContextSetFillColorWithColor(context,
                                                   [UIColor whiteColor].CGColor);
                }
                
                else if (selectedDate && i==selectedDateBlock) {//选中的
                    
                    CGContextSetLineWidth(context, 2.0);
                    CGRect rectangleGrid = CGRectMake(targetX,targetY,kVRGCalendarViewDayWidth+2,kVRGCalendarViewDayHeight+2);
                    CGContextAddRect(context, rectangleGrid);
                    //77;184;77===绿色边框
                    CGContextSetRGBStrokeColor(context, 0.3, 0.72, 0.3, 1.0);
                    CGContextStrokePath(context);
                    CGContextFillPath(context);
                    CGContextSetFillColorWithColor(context,
                                                   [UIColor blueColor].CGColor);
                }
                else if ([[day_infomationDict objectForKey:@"NOR_OR_EXC"] isEqualToString:@"-1"]) {//非正常的
                    CGContextSetLineWidth(context, 2.0);
                    CGRect rectangleGrid = CGRectMake(targetX,targetY,kVRGCalendarViewDayWidth+2,kVRGCalendarViewDayHeight+2);
                    CGContextAddRect(context, rectangleGrid);
                    //红色
//                    CGContextSetRGBStrokeColor(context, 0.99, 0.22, 0.22, 1.0);
//                    CGContextSetStrokeColorWithColor(context, [UIColor greenColor].CGColor);
//                    CGContextStrokePath(context);
                    //255,153,50
                    CGContextSetRGBFillColor(context, 0.99, 153.0/256, 50.0/256, 1.0);
                    CGContextFillRect(context, rectangleGrid);
                    
                    
                    CGContextSetLineWidth(context, 1.0);
                    //蓝色
                    CGContextSetRGBFillColor(context, 0.2, 0.2f, 0.99f, 1.0f);
                    UIFont *charFont=[UIFont systemFontOfSize:10.0f];
                    NSString *drwaString=[[self.markedDates objectAtIndex:[[day_infomationDict objectForKey:@"index"]integerValue]] objectForKey:@"NOR_OR_EXC"];
                    
                    //                    for (int i=0; i<self.markedDates.count; i++) {
                    //                        if ([[[self.markedDates objectAtIndex:i] objectForKey:@"date"] isEqualToString:date]) {
                    //                            drwaString=[[self.markedDates objectAtIndex:i] objectForKey:@"NOR_OR_EXC"];
                    //                        }
                    //                    }
                    
                    [drwaString drawInRect:rectangleGrid withAttributes:@{charFont:NSFontAttributeName,[UIColor orangeColor]:NSForegroundColorAttributeName}];
                    CGContextFillPath(context);
                    CGContextSetFillColorWithColor(context, [UIColor whiteColor].CGColor);
                }
                else{
                    CGRect rectangleGrid = CGRectMake(targetX,targetY,kVRGCalendarViewDayWidth+2,kVRGCalendarViewDayHeight+2);
                    CGContextAddRect(context, rectangleGrid);
                    CGContextSetLineWidth(context, 0.1);
                    CGContextSetRGBStrokeColor(context, 0.88, 0.88, 0.88, 1.0);
                    
                    CGContextStrokePath(context);
                    CGContextFillPath(context);
                    CGContextSetRGBFillColor(context, 0.3, 0.3, 0.3, 1.0);
//                    CGContextSetFillColorWithColor(context, [UIColor cyanColor].CGColor);
                    
                }
                
            }
        }
//        else if (selectedDate && i==selectedDateBlock) {//选中的
//            CGRect rectangleGrid = CGRectMake(targetX,targetY,kVRGCalendarViewDayWidth+2,kVRGCalendarViewDayHeight+2);
//            CGContextAddRect(context, rectangleGrid);
////            CGContextSetFillColorWithColor(context, [UIColor colorWithHexString:@"0x006dbc"].CGColor);
//                CGContextSetFillColorWithColor(context,
//                                               [UIColor yellowColor].CGColor);
//            CGContextFillPath(context);
//            
//            CGContextSetFillColorWithColor(context, 
//                                           [UIColor yellowColor].CGColor);
//        } else if (todayBlock==i) {//当天的
//            CGRect rectangleGrid = CGRectMake(targetX,targetY,kVRGCalendarViewDayWidth+2,kVRGCalendarViewDayHeight+2);
//            CGContextAddRect(context, rectangleGrid);
//            CGContextSetRGBStrokeColor(context, 0.5, 0.5, 0.5, 0.5);
////            CGContextSetFillColorWithColor(context, [UIColor colorWithHexString:@"0000FF"].CGColor);//当日
////            CGContextSetFillColorWithColor(context, [UIColor purpleColor].CGColor);//当日
//            CGContextFillPath(context);
//            
//            CGContextSetFillColorWithColor(context, 
//                                           [UIColor yellowColor].CGColor);
//        }
//        else if (i>=(firstWeekDay+currentMonthNumDays)){//下月的...
////            CGRect rectangleGrid = CGRectMake(targetX,targetY,kVRGCalendarViewDayWidth+2,kVRGCalendarViewDayHeight+2);
////            CGContextAddRect(context, rectangleGrid);
////            //            CGContextSetFillColorWithColor(context, [UIColor colorWithHexString:@"0000FF"].CGColor);//当日
////            CGContextSetFillColorWithColor(context, [UIColor whiteColor].CGColor);//
////            
////            CGContextFillPath(context);
//        }
        
        [date drawInRect:CGRectMake(targetX+2, targetY+10, kVRGCalendarViewDayWidth, kVRGCalendarViewDayHeight) withFont:[UIFont fontWithName:@"HelveticaNeue-Bold" size:17] lineBreakMode:UILineBreakModeClip alignment:UITextAlignmentCenter];
    }
    
    CGContextClosePath(context);
//    CGFloat view_height=self.frame.size.height;
//    CGContextSetRGBStrokeColor(context, 0.9, 0.0, 0.0, 1.0);//线条颜色
//    
//    CGContextSetLineWidth(context, 2.0);
//    CGContextAddRect(context, CGRectMake(1, 0, 318, view_height-1));
//    CGContextStrokePath(context);
    NSDictionary *strokeAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[UIFont systemFontOfSize:20.0F], NSFontAttributeName, [UIColor colorWithRed:50/256.0 green:50/256.0 blue:50/256.0 alpha:1.0], NSStrokeColorAttributeName, @3.0, NSStrokeWidthAttributeName, nil];
    CGFloat hhhhh=(numBlocks/7+1)*(kVRGCalendarViewDayHeight+2)+kVRGCalendarViewTopBarHeight;
    NSString *back_red_string_white=@"红色背景的日期为有异常情况";
    [back_red_string_white drawInRect:CGRectMake(20, hhhhh, self.frame.size.width-40, 100) withAttributes:strokeAttributes];
    UIImage *new_image_left=[self image:[UIImage imageNamed:@"attendance3-3.png"] rotation:UIImageOrientationRight];
    CGContextDrawImage(context, CGRectMake(20, 15, 23, 23), new_image_left.CGImage);
    UIImage *new_image_right=[self image:[UIImage imageNamed:@"attendance3-3.png"] rotation:UIImageOrientationLeft];
    CGContextDrawImage(context, CGRectMake(280, 15, 23, 23), new_image_right.CGImage);
    //Draw markings
    if (!self.markedDates || isSelectedDatePreviousMonth || isSelectedDateNextMonth) return;
    
    for (int i = 0; i<[self.markedDates count]; i++) {
        id markedDateObj = [self.markedDates objectAtIndex:i];
        
        int targetDate;
        if ([markedDateObj isKindOfClass:[NSNumber class]]) {
            targetDate = [(NSNumber *)markedDateObj intValue];
        } else if ([markedDateObj isKindOfClass:[NSDate class]]) {
            NSDate *date = (NSDate *)markedDateObj;
            targetDate = [date day];
        } else {
            continue;
        }
        
        
        
        int targetBlock = firstWeekDay + (targetDate-1);
        int targetColumn = targetBlock%7;
        int targetRow = targetBlock/7;
        
        int targetX = targetColumn * (kVRGCalendarViewDayWidth+2) + 7;
        int targetY = kVRGCalendarViewTopBarHeight + targetRow * (kVRGCalendarViewDayHeight+2) + 38;
        
        CGRect rectangle = CGRectMake(targetX,targetY,32,2);
        CGContextAddRect(context, rectangle);
        
        UIColor *color;
        if (selectedDate && selectedDateBlock==targetBlock) {
            color = [UIColor whiteColor];
        }  else if (todayBlock==targetBlock) {
            color = [UIColor whiteColor];
        } else {
            color  = (UIColor *)[markedColors objectAtIndex:i];
        }
        
        
        CGContextSetFillColorWithColor(context, color.CGColor);
        CGContextFillPath(context);
    }
}

#pragma mark - Draw image for animation
-(UIImage *)drawCurrentState {
    float targetHeight = kVRGCalendarViewTopBarHeight + [self numRows]*(kVRGCalendarViewDayHeight+2)+7;
    
    UIGraphicsBeginImageContext(CGSizeMake(kVRGCalendarViewWidth, targetHeight-kVRGCalendarViewTopBarHeight));
    CGContextRef c = UIGraphicsGetCurrentContext();
    CGContextTranslateCTM(c, 0, -kVRGCalendarViewTopBarHeight);    // <-- shift everything up by 40px when drawing.
    [self.layer renderInContext:c];
    UIImage* viewImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return viewImage;
}

#pragma mark - Init
-(id)init {
    self = [super initWithFrame:CGRectMake(0, 0, kVRGCalendarViewWidth, 0)];
    if (self) {
        self.contentMode = UIViewContentModeTop;
        self.clipsToBounds=YES;
        
        isAnimating=NO;
        self.labelCurrentMonth = [[UILabel alloc] initWithFrame:CGRectMake(34, 0, kVRGCalendarViewWidth-68, 40)];
        [self addSubview:labelCurrentMonth];
        labelCurrentMonth.backgroundColor=[UIColor whiteColor];
        labelCurrentMonth.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:17];
        labelCurrentMonth.textColor = [UIColor colorWithHexString:@"0x383838"];//#FFFFFF
        labelCurrentMonth.textAlignment = NSTextAlignmentCenter;
        
        [self performSelector:@selector(reset) withObject:nil afterDelay:0.1]; //so delegate can be set after init and still get called on init
        //        [self reset];
    }
    return self;
}

-(void)dealloc {
    
    self.delegate=nil;
    self.currentMonth=nil;
    self.labelCurrentMonth=nil;
    
    self.markedDates=nil;
    self.markedColors=nil;
    
}

-(UIImage *)image:(UIImage *)image rotation:(UIImageOrientation)orientation
{
    long double rotate = 0.0;
    CGRect rect;
    float translateX = 0;
    float translateY = 0;
    float scaleX = 1.0;
    float scaleY = 1.0;
    
    switch (orientation) {
        case UIImageOrientationLeft:
            rotate = M_PI_2;
            rect = CGRectMake(0, 0, image.size.height, image.size.width);
            translateX = 0;
            translateY = -rect.size.width;
            scaleY = rect.size.width/rect.size.height;
            scaleX = rect.size.height/rect.size.width;
            break;
        case UIImageOrientationRight:
            rotate = 3 * M_PI_2;
            rect = CGRectMake(0, 0, image.size.height, image.size.width);
            translateX = -rect.size.height;
            translateY = 0;
            scaleY = rect.size.width/rect.size.height;
            scaleX = rect.size.height/rect.size.width;
            break;
        case UIImageOrientationDown:
            rotate = M_PI;
            rect = CGRectMake(0, 0, image.size.width, image.size.height);
            translateX = -rect.size.width;
            translateY = -rect.size.height;
            break;
        default:
            rotate = 0.0;
            rect = CGRectMake(0, 0, image.size.width, image.size.height);
            translateX = 0;
            translateY = 0;
            break;
    }
    NSLog(@"\nrotate:%Lf\n translateX:%f\ntranslateY:%f",rotate,translateX,translateY);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    //做CTM变换
    CGContextTranslateCTM(context, 0.0, rect.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    CGContextRotateCTM(context, rotate);
    CGContextTranslateCTM(context, translateX, translateY);
    
    CGContextScaleCTM(context, scaleX, scaleY);
    //绘制图片
    CGContextDrawImage(context, CGRectMake(0, 0, rect.size.width, rect.size.height), image.CGImage);
    
    UIImage *newPic = UIGraphicsGetImageFromCurrentImageContext();
    
    return newPic;
}
@end
