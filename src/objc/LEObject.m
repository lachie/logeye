#import "LEObject.h"
#include <objc/objc.h>
#include <objc/objc-class.h>

#define RUBY_DEBUG_P      RTEST(ruby_debug)
#define RUBYCOCOA_DEBUG_P RTEST(rubycocoa_debug)
#define DEBUG_P           1

// (RUBY_DEBUG_P || RUBYCOCOA_DEBUG_P)

#define DLOG(mod, fmt, args...)                  \
  do {                                           \
    if (DEBUG_P) {                             \
      NSAutoreleasePool * pool;                  \
      NSString *          nsfmt;                 \
                                                 \
      pool = [[NSAutoreleasePool alloc] init];   \
      nsfmt = [NSString stringWithFormat:        \
        [NSString stringWithFormat:@"%s : %s",   \
          mod, fmt], ##args];                    \
      NSLog(nsfmt);                              \
      [pool release];                            \
    }                                            \
  }                                              \
  while (0)

#define CNAME(c)    ((Class)(((id)c)->isa))->name
#define CLOG(action,cls,obj)    \
  if(cls != [NSAutoreleasePool class] && cls != [NSInvocation class]) { \
    NSLog(@"%s %s %p", action, CNAME(cls),obj); \
  }    

@implementation LEObject

+ (id)alloc {
  id obj = [super alloc];
  
  CLOG("allocating",self,obj);
  
  return obj;
}

- (void)dealloc {
  
  CLOG("deallocating", [self class], self);

  [super dealloc];
}

// - (id)autorelease {
//   if([self class] != [NSAutoreleasePool class]) { 
//     NSLog(@"autoreleasing %s %p", CNAME([self class]), self);
//   }
//   
//   return [super autorelease];
// }
// 
// - (oneway void)release {
//   if([self class] != [NSAutoreleasePool class]) { 
//     NSLog(@"releasing %s %p", CNAME([self class]), self);
//   }
//   
//   [super release];
// }
// 
// - (id)retain {
//   if([self class] != [NSAutoreleasePool class]) {
//     NSLog(@"retaining %s %p", CNAME([self class]), self);
//   }
//   
//   return [super retain];
// }
@end