//
//  main.m
//  calutil
//
//  Created by miyako on 2016/01/04.
//  Copyright © 2016年 miyako. All rights reserved.
//

#import <Foundation/Foundation.h>

@import EventKit;

EKEventStore *eventStore = nil;

#define EVENT_ACCESS_ALLOWED [EKEventStore authorizationStatusForEntityType:EKEntityTypeEvent]==[EKAuthorizationStatusAuthorized]

typedef void (*basic_function_t)(int, int, int, int, NSArray *);

typedef enum {
				RANGE_YEAR = 0,
				RANGE_MONTH,
				RANGE_DAY
} range_unit_t;

typedef enum {
				OPERATION_COUNT = 0,
				OPERATION_DELETE
} operation_type_t;

//http://stackoverflow.com/questions/7266165/objective-c-simple-string-input-from-console
bool getInput(NSString *goodResponse) {
    NSFileHandle *input = [NSFileHandle fileHandleWithStandardInput];
    NSString *inputString = [[NSString alloc] initWithData:[input availableData] encoding:NSUTF8StringEncoding];
    return (NSOrderedSame == [[inputString stringByTrimmingCharactersInSet: [NSCharacterSet newlineCharacterSet]]caseInsensitiveCompare:goodResponse]);
}

void listCalendars(int a, int b, int c, int d, NSArray *e) {

#if __MAC_OS_X_VERSION_MAX_ALLOWED >= 101100
				NSArray<EKCalendar *> *calendars = [eventStore calendarsForEntityType:EKEntityTypeEvent];
#else
				NSArray *calendars = [eventStore calendarsForEntityType:EKEntityTypeEvent];
#endif

				NSMutableArray *cloudCalendars = [[NSMutableArray alloc]init];
				
				for(NSUInteger i = 0; i < [calendars count]; ++i) {
								EKCalendar *calendar = [calendars objectAtIndex:i];
								EKSource *source = [calendar source];
								if ((source.sourceType == EKSourceTypeCalDAV) && [source.title isEqualToString:@"iCloud"]){
												[cloudCalendars addObject:[calendar title]];
								}
				}
				
				NSLog(@"List of iCloud calendars: %@", [[cloudCalendars valueForKey:@"description"] componentsJoinedByString:@" "]);
				
				exit(0);
}

void countEvents(int a, int b, int c, int d, NSArray *e) {

				range_unit_t rangeType = a;
				NSUInteger numberOfIterations = b;
				operation_type_t operation = c;
				NSUInteger keep = d;
				NSArray *calendarNames = e;
				
#if __MAC_OS_X_VERSION_MAX_ALLOWED >= 101100
				NSArray<EKCalendar *> *calendars = [eventStore calendarsForEntityType:EKEntityTypeEvent];
#else
				NSArray *calendars = [eventStore calendarsForEntityType:EKEntityTypeEvent];
#endif
				NSMutableArray *cloudCalendars = [[NSMutableArray alloc]init];
				NSMutableArray *realCalendarNames = [[NSMutableArray alloc]init];
				
				for(NSUInteger i = 0; i < [calendars count]; ++i) {
								EKCalendar *calendar = [calendars objectAtIndex:i];
								EKSource *source = [calendar source];
								if ((source.sourceType == EKSourceTypeCalDAV) && [source.title isEqualToString:@"iCloud"]) {
												if(![calendarNames containsObject:[calendar title]]) {
																[cloudCalendars addObject:calendar];
																[realCalendarNames addObject:[calendar title]];
												}
								}
				}
				
				NSMutableArray *events = [[NSMutableArray alloc]init];
				NSString *calendarNamesList = [[realCalendarNames valueForKey:@"description"] componentsJoinedByString:@" "];
				unsigned unitFlags = NSCalendarUnitYear | NSCalendarUnitMonth |  NSCalendarUnitDay;
				NSCalendar *currentCalendar = [NSCalendar autoupdatingCurrentCalendar];
				
				if ([cloudCalendars count]) {
								
								NSDateComponents *previousDay = [[NSDateComponents alloc]init];
								[previousDay setDay:-1];
								NSDateComponents *previousYear = [[NSDateComponents alloc]init];
								[previousYear setYear:-1];
								NSDateComponents *previousMonth = [[NSDateComponents alloc]init];
								[previousMonth setMonth:-1];
								
								NSDate *endDay, *startDay, *realStartDay;
								NSDateComponents *realStart, *realEnd;
								endDay = [currentCalendar dateByAddingComponents:previousDay toDate:[NSDate date] options:0];
								
								if(keep){
												switch (rangeType){
																case RANGE_DAY:
																realEnd = [[NSDateComponents alloc]init];
																[realEnd setDay:-1 * keep];
																endDay = [currentCalendar dateByAddingComponents:realEnd toDate:endDay options:0];
																				break;
																case RANGE_MONTH:
																realEnd = [[NSDateComponents alloc]init];
																[realEnd setMonth:-1 * keep];
																endDay = [currentCalendar dateByAddingComponents:realEnd toDate:endDay options:0];
																				break;
															default: //RANGE_YEAR
																realEnd = [[NSDateComponents alloc]init];
																[realEnd setYear:-1 * keep];
																endDay = [currentCalendar dateByAddingComponents:realEnd toDate:endDay options:0];
																				break;
												}
								}

								switch (rangeType){
												case RANGE_DAY:
																startDay = [currentCalendar dateByAddingComponents:previousDay toDate:endDay options:0];
																realStart = [[NSDateComponents alloc]init];
																[realStart setDay:-1 * numberOfIterations];
																realStartDay = [currentCalendar dateByAddingComponents:realStart toDate:endDay options:0];
																break;
																
												case RANGE_MONTH:
																startDay = [currentCalendar dateByAddingComponents:previousMonth toDate:endDay options:0];
																realStart = [[NSDateComponents alloc]init];
																[realStart setMonth:-1 * numberOfIterations];
																realStartDay = [currentCalendar dateByAddingComponents:realStart toDate:endDay options:0];
																break;
								
												default: //RANGE_YEAR
																startDay = [currentCalendar dateByAddingComponents:previousYear toDate:endDay options:0];
																realStart = [[NSDateComponents alloc]init];
																[realStart setYear:-1 * numberOfIterations];
																realStartDay = [currentCalendar dateByAddingComponents:realStart toDate:endDay options:0];
												break;
								}

								NSDateComponents *compsTo = [currentCalendar components:unitFlags fromDate:endDay];
								NSDateComponents *compsFrom = [currentCalendar components:unitFlags fromDate:realStartDay];
								
								NSLog(@"events from: %04i-%02i-%02i to: %04i-%02i-%02i in %@",
												(int)[compsFrom year], (int)[compsFrom month], (int)[compsFrom day],
												(int)[compsTo year], (int)[compsTo month], (int)[compsTo day],
												calendarNamesList);
								
								for (NSUInteger i = numberOfIterations; i > 0; --i) {
												
												NSDate *startDate = [currentCalendar dateBySettingHour:0 minute:0 second:0 ofDate:startDay options:0];
												NSDate *endDate = [currentCalendar dateBySettingHour:23 minute:59 second:59 ofDate:endDay options:0];
												NSPredicate *allEventsPredicate = [eventStore predicateForEventsWithStartDate:startDate endDate:endDate calendars:cloudCalendars];

												[eventStore enumerateEventsMatchingPredicate:allEventsPredicate usingBlock:^(EKEvent *event, BOOL *stop) {
																if ((!event.recurrenceRules) || (![event.recurrenceRules count])) {
																				[events addObject:event];
																}
												}];

												switch (rangeType){
																case RANGE_DAY:
																				startDay = [currentCalendar dateByAddingComponents:previousDay toDate:startDay options:0];
																				endDay = [currentCalendar dateByAddingComponents:previousDay toDate:endDay options:0];
																				break;
																				
																case RANGE_MONTH:
																				startDay = [currentCalendar dateByAddingComponents:previousMonth toDate:startDay options:0];
																				endDay = [currentCalendar dateByAddingComponents:previousMonth toDate:endDay options:0];
																				break;
												
																default: //RANGE_YEAR
																				startDay = [currentCalendar dateByAddingComponents:previousYear toDate:startDay options:0];
																				endDay = [currentCalendar dateByAddingComponents:previousYear toDate:endDay options:0];
																break;
												}
								}
				}
				
				switch (operation) {
								case OPERATION_COUNT:
												NSLog(@"Number of iCloud events: %i", (int)[events count]);
								break;
								case OPERATION_DELETE:
												switch ([events count]){
																case 0:
																				NSLog(@"No events to delete.");
																				break;
																case 1:
																				NSLog(@"Are you sure you want to delete 1 iCloud event? (y/n)");
																				break;
																default:
																				NSLog(@"Are you sure you want to delete %i iCloud events? (y/n)", (int)[events count]);
																				break;
												}
												
												if ([events count]) {
																if (getInput(@"y")) {
																				NSError *error = nil;
																				for (NSUInteger i = 0; i < [events count];++i) {
																								EKEvent *event = [events objectAtIndex:i];
																								BOOL success = [eventStore removeEvent:event
																								span:EKSpanThisEvent
																								commit:NO error:&error];
																								if (!success) {
																												NSDateComponents *compsDate = [currentCalendar components:unitFlags fromDate:event.startDate];
																												NSLog(@"Can't to remove event: %@ of %04i-%02i-%02i", event.title,
																												(int)[compsDate year], (int)[compsDate month], (int)[compsDate day]);
																								}
																				}
																				NSLog(@"ARE YOU REALLY SURE YOU WANT TO DELETE THE EVENTS? (Y/N)");
																				if (getInput(@"y")) {
																								if ([eventStore commit:&error]) {
																												NSLog(@"Success!");
																								}else{
																												NSLog(@"Failed.");
																								}
																				}
																}
																
												}
								break;
  default:
    break;
}
				
				exit(0);
}

void requestAccessAndDoIt(basic_function_t doIt, int a, int b, int c, int d, NSArray *e) {
#if __MAC_OS_X_VERSION_MAX_ALLOWED >= 1090
				eventStore = [[EKEventStore alloc]init];
				[eventStore requestAccessToEntityType:EKEntityTypeEvent completion:^(BOOL granted, NSError *error) {
								if (granted) {
												dispatch_async(dispatch_get_main_queue(), ^{
																doIt(a, b, c, d, e);
												});
								}else{
												NSLog(@"Calendar access denied!");
												exit(0);
								}
				}];
				[[NSRunLoop currentRunLoop] runUntilDate:[NSDate distantFuture]];
#else
				eventStore = [[EKEventStore alloc]initWithAccessToEntityTypes:EKEntityMaskEvent];
				if (EVENT_ACCESS_ALLOWED) {
								doIt(a, b, c, d, e);
				}
#endif
}

int main(int argc, const char * argv[]) {

	@autoreleasepool {
#if __MAC_OS_X_VERSION_MAX_ALLOWED >= 101100
				NSArray <NSString *> *arguments = [[NSProcessInfo processInfo]arguments];
#else
				NSArray *arguments = [[NSProcessInfo processInfo]arguments];
#endif
				NSUInteger i;
				NSUInteger lastArgumentIndex = [arguments count] - 1;
				NSMutableArray *calendarNames = [[NSMutableArray alloc]init];
				
				if ([arguments containsObject:@"reset"]) {
								NSArray * arguments = [NSArray arrayWithObjects:@"reset", @"Calendar", nil];
								[NSTask launchedTaskWithLaunchPath:@"/usr/bin/tccutil" arguments:arguments];
				}

				if ([arguments containsObject:@"list"]) {
								requestAccessAndDoIt(listCalendars, 0, 0, 0, 0, nil);
				}else
				
				i = [arguments indexOfObject:@"except"];
				
				if ((i != NSNotFound) && (i <  lastArgumentIndex)) {
								for (NSUInteger calendarNameIndex = i + 1; calendarNameIndex <= lastArgumentIndex; ++calendarNameIndex) {
												[calendarNames addObject:[arguments objectAtIndex:calendarNameIndex]];
								}
				}
				
				//defaults
				int rangeType = RANGE_YEAR;
				int numberOfIterations = 10;
				int keep = 0;

				i = [arguments indexOfObject:@"keep"];
				if ((i != NSNotFound) && (i > 1)){
								int _keep = [[arguments objectAtIndex:i - 1]intValue];
								if ((_keep != INT_MAX) && (_keep != INT_MIN) && (_keep > 0)) {
												keep = _keep;
								}
				}
					
				i = [arguments indexOfObject:@"year"];
				if ((i != NSNotFound) && (i > 1)){
								int _numberOfIterations = [[arguments objectAtIndex:i - 1]intValue];
								if ((_numberOfIterations != INT_MAX) && (_numberOfIterations != INT_MIN) && (_numberOfIterations > 0)) {
												numberOfIterations = _numberOfIterations;
								}
				}else{
								i = [arguments indexOfObject:@"month"];
								if ((i != NSNotFound) && (i > 1)){
												rangeType = RANGE_MONTH;
												int _numberOfIterations = [[arguments objectAtIndex:i - 1]intValue];
												if ((_numberOfIterations != INT_MAX) && (_numberOfIterations != INT_MIN) && (_numberOfIterations > 0)) {
																numberOfIterations = _numberOfIterations;
												}
				}else{
												i = [arguments indexOfObject:@"day"];
												if ((i != NSNotFound) && (i > 1)){
																rangeType = RANGE_DAY;
																int _numberOfIterations = [[arguments objectAtIndex:i - 1]intValue];
																if ((_numberOfIterations != INT_MAX) && (_numberOfIterations != INT_MIN) && (_numberOfIterations > 0)) {
																				numberOfIterations = _numberOfIterations;
																}
												}
								}
				}
					
				if ([arguments containsObject:@"count"]) {
								requestAccessAndDoIt(countEvents, rangeType, numberOfIterations, OPERATION_COUNT, keep, calendarNames);
				}

				if ([arguments containsObject:@"delete"]) {
								requestAccessAndDoIt(countEvents, rangeType, numberOfIterations, OPERATION_DELETE, keep, calendarNames);
				}
				
	}
    return 0;
}
