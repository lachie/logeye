#import "LEArrayController.h"

@implementation LEArrayController
- (void)rearrangeObjects {
  NSLog(@"rearranging objects");
  [super rearrangeObjects];
}

- (NSArray *)arrangeObjects:(NSArray *)objects {
  NSArray *arranged = [super arrangeObjects: objects];
  
  NSLog(@"arranging objects %d", [objects count]);
  NSLog(@"rearranged %d", [arranged count]);
  
  return arranged;
}
@end