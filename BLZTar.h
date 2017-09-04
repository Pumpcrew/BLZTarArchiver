//
//  TNiOSTar.h
//  TARTEST
//
//  Created by Seung-wooLee on 2014. 11. 17..
//  Copyright (c) 2014년 LSW. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
@interface BLZTar : NSObject
+(BOOL)TarArchive:(NSString*)ToPath List:(NSMutableArray*)FilePathList FileName:(NSMutableArray*)Arr_filename;
/*
 Use Sample
 
 
 // Do any additional setup after loading the view, typically from a nib.
 NSMutableDictionary *tempdata=[[NSMutableDictionary alloc] init];
 [tempdata setObject:@"1" forKey:@"aa"];
 [tempdata setObject:@"2" forKey:@"aa"];
 [tempdata setObject:@"3" forKey:@"aa"];
 [tempdata setObject:@"4" forKey:@"aa"];
 
 //테스트용array
 NSArray *homePaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
 NSString *homeDir = [homePaths objectAtIndex:0];
 //File Path Array
 NSMutableArray *filepatharr=[[NSMutableArray alloc] init];
 //File name Array
 NSMutableArray *filenamearr=[[NSMutableArray alloc] init];
 
 for (int a = 0; a<10; a++) {
 NSString *Mainfilename = [NSString stringWithFormat:@"%d.txt",a];
 
 NSString *filePath = [homeDir stringByAppendingPathComponent:Mainfilename];
 [tempdata writeToFile:filePath atomically:YES];
 //Insert file Path data
 [filepatharr addObject:filePath];
 [filenamearr addObject:Mainfilename];
 
 }
 
 [BLZTar TarArchive:@"Temp" List:filepatharr FileName:filenamearr];

 
 
 */

@end
