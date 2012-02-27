    //
//  RouteListViewController.m
//  CycleStreets
//
//  Created by neil on 12/03/2011.
//  Copyright 2011 CycleStreets Ltd. All rights reserved.
//

#import "RouteListViewController.h"
#import "RouteCellView.h"
#import "SavedRoutesManager.h"
#import "StyleManager.h"
#import "NSDate+Helper.h"
#import "RouteToolCellView.h"


@interface RouteListViewController(Private) 

-(void)createRowHeightsArray;
-(void)createSectionHeadersArray;

- (NSIndexPath *)modelIndexPathforIndexPath:(NSIndexPath *)indexPath;

@end



@implementation RouteListViewController
@synthesize isSectioned;
@synthesize keys;
@synthesize dataProvider;
@synthesize tableDataProvider;
@synthesize rowHeightsArray;
@synthesize rowHeightDictionary;
@synthesize tableSectionArray;
@synthesize dataType;
@synthesize tableEditMode;
@synthesize selectedCellDictionary;
@synthesize selectedCount;
@synthesize deleteButton;
@synthesize tableView;
@synthesize toolView;
@synthesize tappedIndexPath;
@synthesize toolRowIndexPath;
@synthesize indexPathToDelete;



//=========================================================== 
// dealloc
//=========================================================== 
- (void)dealloc
{
    [keys release], keys = nil;
    [dataProvider release], dataProvider = nil;
    [tableDataProvider release], tableDataProvider = nil;
    [rowHeightsArray release], rowHeightsArray = nil;
    [rowHeightDictionary release], rowHeightDictionary = nil;
    [tableSectionArray release], tableSectionArray = nil;
    [dataType release], dataType = nil;
    [selectedCellDictionary release], selectedCellDictionary = nil;
    [deleteButton release], deleteButton = nil;
    [tableView release], tableView = nil;
    [toolView release], toolView = nil;
    [tappedIndexPath release], tappedIndexPath = nil;
    [toolRowIndexPath release], toolRowIndexPath = nil;
    [indexPathToDelete release], indexPathToDelete = nil;
	
    [super dealloc];
}








//
/***********************************************
 * @description		NOTIFICATIONS
 ***********************************************/
//

-(void)listNotificationInterests{
	
	BetterLog(@"");
	
	[self initialise];
    
    [notifications addObject:NEWROUTEBYIDRESPONSE]; // user initiated route by id response
    [notifications addObject:SAVEDROUTEUPDATE]; // new route search, recent>fav move etc
	[notifications addObject:CALCULATEROUTERESPONSE];
	
	[super listNotificationInterests];
	
}

-(void)didReceiveNotification:(NSNotification*)notification{
	
	BetterLog(@"");
	
	[super didReceiveNotification:notification];
    
	if([notification.name isEqualToString:NEWROUTEBYIDRESPONSE]){
		[self refreshUIFromDataProvider];
	}
    
    if([notification.name isEqualToString:SAVEDROUTEUPDATE]){
		[self refreshUIFromDataProvider];
	}
	
	if([notification.name isEqualToString:CALCULATEROUTERESPONSE]){
		[self refreshUIFromDataProvider];
	}
	
}


//
/***********************************************
 * @description			DATA UPDATING
 ***********************************************/
//

-(void)refreshUIFromDataProvider{
	
    self.dataProvider=[[SavedRoutesManager sharedInstance] dataProviderForType:dataType];
    
    if([dataProvider count]>0){
        
        if(isSectioned==YES){
            self.tableDataProvider=[GlobalUtilities newKeyedDictionaryFromArray:dataProvider usingKey:@"dateOnlyString"];
            self.keys=[GlobalUtilities newTableIndexArrayFromDictionary:tableDataProvider withSearch:NO];
        }
        [self createRowHeightsArray];
		[self createSectionHeadersArray];
        [self.tableView reloadData];
        
    }else{
        [self showViewOverlayForType:kViewOverlayTypeNoResults show:YES withMessage:nil];
    }
    
	/*
    [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationRight];
	*/
}


//
/***********************************************
 * @description			UI CREATION
 ***********************************************/
//

- (void)viewDidLoad {
	
	[super viewDidLoad];
	
    if([dataType isEqualToString:SAVEDROUTE_RECENTS]){
        isSectioned=YES;
    }
	
}


-(void)createPersistentUI{
	
	self.toolView=[[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 40)];
	toolView.backgroundColor=[UIColor redColor];
	
}


-(void)viewWillAppear:(BOOL)animated{
	
	[self createNonPersistentUI];
	
	[super viewWillAppear:animated];
}

-(void)createNonPersistentUI{
	
	if(dataProvider==nil){
		[self refreshUIFromDataProvider];
	}
	
	[self deSelectRowForTableView:tableView];
}


//
/***********************************************
 * @description		TABLEVIEW DELEGATE METHODS
 ***********************************************/
//

#pragma mark UITableView delegate methods


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	if(isSectioned==YES){
		return [keys count];
	}else {
		return 1;
	}

}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
	if(isSectioned==YES){
		NSString *key=[keys objectAtIndex:section];
		NSMutableArray *sectionDataProvider=[tableDataProvider objectForKey:key];
		if(toolRowIndexPath){
			if(section==[tappedIndexPath section]){
				return [sectionDataProvider count]+1;
			}
		}
		return [sectionDataProvider count];
	}else {
		return [dataProvider count];
	}

}



- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{  
	
	if (isSectioned==YES) {
		return [tableSectionArray objectAtIndex:section];
	}
	return nil;
	
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
	if(isSectioned==NO){
		return 0.0f;
	}
	return 24.0f;
}


- (UITableViewCell *)tableView:(UITableView *)table cellForRowAtIndexPath:(NSIndexPath *)indexPath{
	
    RouteCellView *cell = (RouteCellView *)[RouteCellView cellForTableView:table fromNib:[RouteCellView nib]];
	
	if(isSectioned==YES){
	
		NSString *key=[keys objectAtIndex:[indexPath section]];
		NSMutableArray *sectionDataProvider=[tableDataProvider objectForKey:key];
		
		if([indexPath isEqual:toolRowIndexPath]){
			
			RouteToolCellView *cell = (RouteToolCellView *)[RouteToolCellView cellForTableView:table fromNib:[RouteToolCellView nib]];
			return cell;
			
		}else {
			cell.dataProvider=[sectionDataProvider objectAtIndex:[indexPath row]];
			[cell populate];
		}
		
		
	}else {
		cell.dataProvider=[dataProvider objectAtIndex:[indexPath row]];
		[cell populate];
	}

	
	
    return cell;
}



- (void)tableView:(UITableView *)tbv didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
	
	
	if (tableEditMode==YES){
		return;
	}else {
		
		//if user tapped the same row twice let's start getting rid of the control cell
		if([indexPath isEqual:tappedIndexPath]){
			[tableView deselectRowAtIndexPath:indexPath animated:NO];
		}
		
		//update the indexpath if needed... I explain this below 
		indexPath = [self modelIndexPathforIndexPath:indexPath];
		
		//pointer to delete the control cell
		self.indexPathToDelete = toolRowIndexPath;
		
		//if in fact I tapped the same row twice lets clear our tapping trackers 
		if([indexPath isEqual:tappedIndexPath]){
			self.tappedIndexPath = nil;
			self.toolRowIndexPath = nil;
		}
		//otherwise let's update them appropriately 
		else{
			self.tappedIndexPath = indexPath; //the row the user just tapped. 
			//Now I set the location of where I need to add the dummy cell 
			self.toolRowIndexPath = [NSIndexPath indexPathForRow:indexPath.row + 1   inSection:indexPath.section];
		}
		
		//all logic is done, lets start updating the table
		[self.tableView beginUpdates];
		
		//lets delete the control cell, either the user tapped the same row twice or tapped another row
		if(indexPathToDelete){
			[self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPathToDelete] 
								  withRowAnimation:UITableViewRowAnimationNone];
		}
		//lets add the new control cell in the right place 
		if(toolRowIndexPath){
			[self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:toolRowIndexPath] 
								  withRowAnimation:UITableViewRowAnimationNone];
		}
		
		//and we are done... 
		[self.tableView endUpdates];
		
		self.indexPathToDelete=nil;
		
        /*
        if([delegate respondsToSelector:@selector(doNavigationPush: withDataProvider: andIndex:)]){
            
            RouteVO *route;
            
            if(isSectioned==YES){
                NSString *key=[keys objectAtIndex:[indexPath section]];
                NSMutableArray *sectionDataProvider=[tableDataProvider objectForKey:key];
                route=[sectionDataProvider objectAtIndex:[indexPath row]];
            }else{
                route=[dataProvider objectAtIndex:[indexPath row]];
            }
			
			[delegate doNavigationPush:@"RouteSummary" withDataProvider:route andIndex:-1];
		}
		 */
		
	}

}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
	
	if(isSectioned==NO){
		return [[rowHeightsArray objectAtIndex:[indexPath row]] floatValue];
	}else{
		NSString *key=[keys objectAtIndex:[indexPath section]];
		NSMutableArray *arr=[rowHeightDictionary objectForKey:key];
		
		if([indexPath isEqual:toolRowIndexPath]){
			return [RouteToolCellView rowHeight];
		}else {
			
			int rowIndex=[indexPath row];
			CGFloat cellheight=[[arr objectAtIndex:rowIndex] floatValue];
			return cellheight;
			
		}
		
	}
}

- (NSIndexPath *)modelIndexPathforIndexPath:(NSIndexPath *)indexPath
{
    int whereIsTheControlRow = toolRowIndexPath.row;
    if(toolRowIndexPath != nil && indexPath.row > whereIsTheControlRow)
        return [NSIndexPath indexPathForRow:indexPath.row - 1 inSection:indexPath.section]; 
    return indexPath;
}


//
/***********************************************
 * @description			Table view utitlity
 ***********************************************/
//

       
-(void)createRowHeightsArray{
    
    if(isSectioned==NO){
   
       if(rowHeightsArray==nil){
           self.rowHeightsArray=[[NSMutableArray alloc]init];
       }else{
           [rowHeightsArray	removeAllObjects];
       }
       
       for (int i=0; i<[dataProvider count]; i++) {
           
           RouteVO *route = [dataProvider objectAtIndex:i];
           [rowHeightsArray addObject:[RouteCellView heightForCellWithDataProvider:route]];
           
       }
        
    }else{
        
        if(rowHeightDictionary==nil){
            self.rowHeightDictionary=[[NSMutableDictionary alloc]init];
        }else{
            [rowHeightDictionary removeAllObjects];
        }
        
        for( NSString *key in keys){
            
            NSMutableArray *sectionDataProvider=[tableDataProvider objectForKey:key];
			NSMutableArray *sectionrowheightarray=[[NSMutableArray alloc]init];
        
            for (int i=0; i<[sectionDataProvider count]; i++) {
                
                RouteVO *route = [sectionDataProvider objectAtIndex:i];
                [sectionrowheightarray addObject:[RouteCellView heightForCellWithDataProvider:route]];
                
            }
			[rowHeightDictionary setObject:sectionrowheightarray forKey:key];
			[sectionrowheightarray release];
            
        }
        
    }
   
   
}

-(void)createSectionHeadersArray{
	
	if(isSectioned==YES){
		
		if(tableSectionArray==nil){
            self.tableSectionArray=[[NSMutableArray alloc]init];
        }else{
            [tableSectionArray removeAllObjects];
        }
		
		for (int i=0;i<[keys count];i++){
			
			UIView *headerView=[[UIView	alloc]initWithFrame:CGRectMake(0, 0, 320, 24)];
			headerView.backgroundColor=[[StyleManager sharedInstance] colorForType:@"darkgreen"];
			
			UILabel *sectionLabel=[[UILabel alloc]initWithFrame:CGRectMake(10.0, 0, 280, 24)];
			sectionLabel.backgroundColor=[UIColor clearColor];
			sectionLabel.textColor=UIColorFromRGB(0xFFFFFF);
			sectionLabel.font=[UIFont boldSystemFontOfSize:11.5];
			
			// create ui string
			NSString *key=[keys objectAtIndex:i];
			NSDate *sectionDate=[NSDate dateFromString:key];
			NSDateFormatter *displayFormatter = [[NSDateFormatter alloc] init];
			[displayFormatter setDateFormat:@"EEEE d MMM YYYY"];
			NSString *timeString = [displayFormatter stringFromDate:sectionDate];
			[displayFormatter release];
			sectionLabel.text=timeString;
			
			
			[headerView addSubview:sectionLabel];
			[sectionLabel release];
			
			[tableSectionArray addObject:headerView];
			[headerView release];
		}
		
	}
	
	
}


//
/***********************************************
 * @description		UI EVENTS
 ***********************************************/
//
//
/***********************************************
 * @description			Multi edit Cell support
 ***********************************************/
//


-(void)toggleTableEditing{
	
	BOOL newstate = !tableEditMode;
	[self setTableEditingState:newstate];
}


-(void)setTableEditingState:(BOOL)state{
	
	tableEditMode=state;
	
	[tableView reloadData];
	
}


- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
	return UITableViewCellEditingStyleDelete;
}

- (void)deleteRow:(NSIndexPath*)indexPath{
    
    RouteVO *route=nil;
    
    if(isSectioned==YES){
        NSString *key=[keys objectAtIndex:[indexPath section]];
        NSMutableArray *sectionDataProvider=[tableDataProvider objectForKey:key];
        route=[sectionDataProvider objectAtIndex:[indexPath row]];
    }else{
        route=[dataProvider objectAtIndex:[indexPath row]];
    }
	
	[[SavedRoutesManager sharedInstance] removeRoute:route fromDataProvider:dataType];
	
}

- (void)tableView:(UITableView *)tv commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	[self deleteRow:indexPath];
	[tv deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:YES];
    [self refreshUIFromDataProvider];
}

/* this needs further work
-(void)tableView:(UITableView*)tableView performAction:(SEL)action forRowAtIndexPath:(NSIndexPath*)indexPath withSender:(id)sender{
   
   BetterLog(@"");
   
}
-(BOOL)tableView:(UITableView*)tableView canPerformAction:(SEL)action forRowAtIndexPath:(NSIndexPath*)indexPath withSender:(id)sender{
   return YES;
   
}
-(BOOL)tableView:(UITableView*)tableView shouldShowMenuForRowAtIndexPath:(NSIndexPath*)indexPath{
   
   UIMenuItem* miCustom1 = [[[UIMenuItem alloc] initWithTitle: @"Custom 1" action:@selector( onCustom1: )] autorelease];
   UIMenuItem* miCustom2 = [[[UIMenuItem alloc] initWithTitle: @"Custom 2" action:@selector( onCustom2: )] autorelease];
   UIMenuController* mc = [UIMenuController sharedMenuController];
   mc.menuItems = [NSArray arrayWithObjects: miCustom1, miCustom2, nil];
   
   return YES;
}
 */


- (void)updateDeleteButtonState{
	deleteButton.enabled=selectedCount>0;
}


//
/***********************************************
 * @description			GENERIC METHODS
 ***********************************************/
//

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
}

- (void)viewDidUnload {
    [super viewDidUnload];
}


@end
