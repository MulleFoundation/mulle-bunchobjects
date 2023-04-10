// HOWTO:
//
//
// #define USE_BUNCH_OBJECTS
// #include "mulle-bunchobjects.h"
//
// @implementation YourClass
//
// static struct mulle_bunchinfo   bunchinfo;
//
// + (void) initialize
// {
//    if( ! mulle_bunchinfo_is_initialized( &bunchinfo))
//       mulle_bunchinfo_initialize( &bunchinfo);
// }
//
//
// + (void) deinitialize
// {
//    if( mulle_bunchinfo_is_initialized( &bunchinfo))
//       mulle_bunchinfo_deinitialize( &bunchinfo);
// }
//
//
// + (id) alloc
// {
//    return( mulle_bunchinfo_alloc_instance( &bunchinfo, self, 0));
// }
//
//
// + (id) allocWithZone:(NSZone *) zone
// {
//    return( mulle_bunchinfo_alloc_instance( &bunchinfo, self, 0));
// }
//
//
// + (id) new
// {
//    return( mulle_bunchinfo_alloc_instance( &bunchinfo, self, 0));
// }
//
//
// - (void) dealloc
// {
//    // release ivars
//    mulle_bunchinfo_dealloc_instance( &bunchinfo, self);
// }
//
//
// use `mulle_bunchinfo_alloc_instance` whereever you are using `[self alloc]`
//
#ifdef USE_BUNCH_OBJECTS

#define MULLE_BUNCHOBJECTS_VERSION   ((0 << 20) | (20 << 8) | 3)

#include <mulle-thread/mulle-thread.h>
#include <stdint.h>
#include <stddef.h>


//
// The structure at the beginning of
// every struct mulle_bunch
//
#pragma pack( 4)
struct mulle_bunchheader
{
   int32_t   s_instance;
   uint8_t   alignment;
   uint8_t   freed;
   uint8_t   allocated;          // allocated by "user"
};
#pragma pack()


struct mulle_bunch
{
   struct mulle_bunchheader   header;
};


struct mulle_bunchinfo
{
   struct mulle_bunch         *curr;        // need this be volatile ?
   mulle_thread_mutex_t       lock;
   struct mulle_bunchheader   dummy;
};



static inline int   mulle_bunchinfo_is_initialized( struct mulle_bunchinfo *info)
{
   return( info->curr != NULL);
}


void   mulle_bunchinfo_initialize( struct mulle_bunchinfo *info);
void   mulle_bunchinfo_deinitialize( struct mulle_bunchinfo *info);
id     mulle_bunchinfo_alloc_instance( struct mulle_bunchinfo *info, Class self, size_t extra);
void   mulle_bunchinfo_dealloc_instance( struct mulle_bunchinfo *info, id self);

#else

#define mulle_bunchinfo_initialize( info)
#define mulle_bunchinfo_deinitialize( info)
#define mulle_bunchinfo_alloc_instance( info, self, extra)  [self alloc]
#define mulle_bunchinfo_dealloc_instance( info, self)       [super dealloc]

#endif
