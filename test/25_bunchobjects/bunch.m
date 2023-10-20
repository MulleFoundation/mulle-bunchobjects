#define USE_BUNCH_OBJECTS  1
#import <MulleObjC/MulleObjC.h>
#include <mulle-bunchobjects/mulle-bunchobjects.h>



@interface TestBunchData : NSObject
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
   NSUInteger   i, j, n, count;
   id           array[ 100];

   count = 0;
   for( i = 0; i < 100; i++)
   {
      array[ i] = [TestBunchData new];
      count++;
   }

   assert( count == 100);

   while( count > 50)
   {
      i = rand() % 100;
      if( array[ i])
      {
         [array[ i] release];
         array[ i] = nil;
         --count;
      }
   }

   assert( count == 50);

   for( j = i = 0; i < 50; i++)
   {
      while( array[ j])
         ++j;
      array[ j] = [TestBunchData new];
      ++count;
   }

   assert( count == 100);

   while( count)
   {
      i = rand() % 100;
      if( array[ i])
      {
         [array[ i] release];
         array[ i] = nil;
         --count;
      }
   }

   return( 0);
}
