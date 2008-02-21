
#import <Foundation/Foundation.h>
#import <RubyCocoa/RBRuntime.h>
#import "LEObject.h"

#include <stdlib.h>
#include <stdio.h>


NSUncaughtExceptionHandler *defaultUncaughtExceptionHandler;

void uncaughtExceptionHandler(NSException *exception) {
  
  NSLog(@"EXY: %@", [exception reason]);
  
  defaultUncaughtExceptionHandler(exception);
}

int main(int argc, const char* argv[])
{
  // umask(022);
  // char *log_location;
  // sprintf(log_location, "%s/Library/Logs/Logeye.log", getenv("HOME"));
  // 
  // freopen(log_location, "a", stderr);
  // fprintf(stderr, "==================================\nLogeye started\n");
  
  // [LEObject poseAsClass: [NSObject class]];
  
  defaultUncaughtExceptionHandler = NSGetUncaughtExceptionHandler();
  NSSetUncaughtExceptionHandler(&uncaughtExceptionHandler);
  
	return RBApplicationMain("rb_main.rb", argc, argv);
}

