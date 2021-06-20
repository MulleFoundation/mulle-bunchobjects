#import <Foundation/Foundation.h>

#define USE_BUNCH_OBJECTS  1
#include <mulle-bunchobjects/mulle-bunchobjects.h>



@interface TestBunchData : NSData
{
   unsigned char    bytes_[ 12];
}
@end



@implementation TestBunchData


static struct mulle_bunchinfo   bunchinfo;


+ (void) initialize
{
   if( ! mulle_bunchinfo_is_initialized( &bunchinfo))
      mulle_bunchinfo_initialize( &bunchinfo);
}


+ (void) deinitialize
{
   if( mulle_bunchinfo_is_initialized( &bunchinfo))
      mulle_bunchinfo_deinitialize( &bunchinfo);
}


+ (id) new
{
   return( mulle_bunchinfo_alloc_instance( &bunchinfo, self, 0));
}


- (void) dealloc
{
   mulle_bunchinfo_dealloc_instance( &bunchinfo, self);
}

@end


int  main( int argc, char *argv[])
{
   NSMutableArray    *array;
   NSUInteger        i, n;
   id                obj;

   array = [NSMutableArray array];
   for( i = 0; i < 100; i++)
   {
      obj = [[TestBunchData new] autorelease];
      [array addObject:obj];
   }

   while( (n = [array count]) > 50)
      [array removeObjectAtIndex:rand() % n];

   for( i = 0; i < 50; i++)
   {
      obj = [[TestBunchData new] autorelease];
      [array addObject:obj];
   }

   while( (n = [array count]))
      [array removeObjectAtIndex:rand() % n];

   return( 0);
}
