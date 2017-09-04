//
//  TNiOSTar.m
//  TARTEST
//
//  Created by Seung-wooLee on 2014. 11. 17..
//  Copyright (c) 2014년 LSW. All rights reserved.
//
#include <iostream>
#include <fstream>
#include <cstdlib>
#import "BLZTar.h"
#include "tarball.h"

@implementation BLZTar

#pragma mark - Check iOS 6

-(BOOL)isIOS6
{
    if([[[UIDevice currentDevice] systemVersion] floatValue] >= 6.0){
        return YES;
    }else{
        return NO;
    }
}

+(BOOL)TarArchive:(NSString*)ToPath List:(NSMutableArray*)FilePathList FileName:(NSMutableArray*)Arr_filename{
    //MutableArray의 파일 갯수 체크
    if (FilePathList.count!=0) {
        //압축할 파일의 경로 작성
        NSArray *homePaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *homeDir = [homePaths objectAtIndex:0];
        NSString *filePath = [homeDir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.tar",ToPath]];
        //File Path Mutable array = > (Convert type) const char
        //File name Mutable array = > (convert type) const char
        
        //File Path Mutable Array
       const char *arrlist[FilePathList.count];
        //File name Mutable Array
        const char *arr_filenameList[Arr_filename.count];
        BOOL checkfile_exist=YES;
        
        for (int a = 0 ; a<FilePathList.count; a++) {
            //Input File Path Mutable Array value into const char
            NSString *gettext=[NSString stringWithFormat:@"%@",[FilePathList objectAtIndex:a]];
            arrlist[a]=[gettext UTF8String];
            
            //Input File Name Mutable Array value into const char
            NSString *getnametext=[NSString stringWithFormat:@"%@",[Arr_filename objectAtIndex:a]];
            arr_filenameList[a]=[getnametext UTF8String];
            if (![[NSFileManager defaultManager] fileExistsAtPath:gettext]) {
                checkfile_exist=NO;
            }
        }
        unsigned long counter=FilePathList.count;
        
        if (checkfile_exist) {
            int buildresult=build([filePath UTF8String],arrlist,arr_filenameList,counter);
            if (buildresult==EXIT_FAILURE) {
                NSLog(@"Failed");
                return NO;
                
            }else if (buildresult==EXIT_SUCCESS){
                NSLog(@"Build Success");
                return YES;
                
            }else{
                NSLog(@"Unknown Result Build Result is %d",buildresult);
                return NO;
                
            }

        }else{
            NSLog(@"Some Data file is not Found");
            
            return NO;
        }

    }else{
        NSLog(@"File Count is Zero");
        return NO;
    }
    
    
}
int build(const char *filename,const char *filePathlist[],const char *filenameList[],unsigned long ArrayCount){
    //파일명 지정
    std::fstream out(filename,std::ios::out);
    if(!out.is_open())
    {
        std::cerr << "Cannot open out" << std::endl;
        return EXIT_FAILURE;
        
    }else{
        /* create the tar file */
        lindenb::io::Tar tarball(out);
        
        //Add item
        if (ArrayCount!=0) {//갯수가 0이 아닐때
            //파일 목록을 Tar 객체 안에 추가한다
            
            for (int a = 0; a<ArrayCount; a++) {
                /*
                //Add item : tarball.put("myfiles/item1.txt","Hello World 1\n");
                //Add File : tarball.putFile("tarfile.cpp","myfiles/code.cpp");
                 putFile(압축할 파일경로,압축파일에 넣을 경로
                 
            */
                tarball.putFile(filePathlist[a],filenameList[a]);

            }
            /* add a file */
            /* finalize the tar file */
            tarball.finish();
            /* close the file */
            out.close();
            /* we're done */
            

            return EXIT_SUCCESS;;

        }else{//갯수가 0일때
            return EXIT_FAILURE;

        }
        /* add item 1 */
        
        
    }
    
}
@end
