#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "GTMDefines.h"
#import "GTMLogger.h"
#import "GTMNSData+zlib.h"
#import "GTMStringEncoding.h"

FOUNDATION_EXPORT double GoogleToolboxForMacVersionNumber;
FOUNDATION_EXPORT const unsigned char GoogleToolboxForMacVersionString[];

