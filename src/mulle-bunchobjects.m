#define USE_BUNCH_OBJECTS

#import "mulle-bunchobjects.h"

#import <objc-compat/objc-compat.h>
#import <mulle-allocator/mulle-allocator.h>

// The alignment is _Alignof( double) or the alignment
// of the first member of the instance

#ifdef DEBUG
# define OBJECTS_PER_MALLOC  2
#else
# define OBJECTS_PER_MALLOC  16
#endif

/*
  +-------------+-- aligned
  |             |
  |   header    | s_header
  |             |
  +-------------+
  |   align1    | ???
  +-------------+
  |   offset    | s_offset
  +-------------+-- aligned
  |             |
  |  instance   | s_instance
  |             |
  +-------------+
  |   align2    | ???
  +-------------+
  |   offset    | s_offset
  +-------------+-- aligned
  |             |
  |  instance   | s_instance
  |             |
  +-------------+
*/

#define s_header   sizeof( struct mulle_bunchheader)
#define s_offset   sizeof( int32_t)

//
// calc what we would need to allocate to align first instance
// the instance needs to be aligned properly
//
static inline size_t   s_header_align1_offset( size_t alignment)
{
   size_t   size;

   size = (s_header + s_offset + (alignment - 1)) & ~(alignment - 1);
   return( size);
}


////
//// calc size of Align1
////
//static inline size_t   s_align1( size_t alignment)
//{
//   size_t   size;
//
//   size = s_header_align1_offset( alignment) - (s_header + s_offset);
//   return( size);
//}


//
// calc what we would need to add for the second instance
//
static inline size_t   s_offset_instance_align2( size_t s_instance,
                                                 size_t alignment)
{
   size_t   size;

   size = (s_instance + s_offset + (alignment - 1)) & ~(alignment - 1);
   return( size);
}


static inline size_t   s_align2( size_t s_instance, size_t alignment)
{
   size_t   size;

   size = s_offset_instance_align2( s_instance, alignment) - (s_instance + s_offset);
   return( size);
}


static inline size_t  s_bunch( size_t s_instance, size_t alignment)
{
   size_t   size;

   size = s_header_align1_offset( alignment) +
          OBJECTS_PER_MALLOC * s_offset_instance_align2( s_instance, alignment) -
          s_align2( s_instance, alignment);
   return( size);
}


static inline struct mulle_bunch  *bunch_create( size_t s_instance, size_t alignment)
{
   struct mulle_bunch   *p;
   size_t               len;

   assert( s_instance == (int32_t) s_instance);
   assert( alignment == (uint8_t) alignment);

   len                  = s_bunch( s_instance, alignment);
   p                    = mulle_calloc( 1, len);   // calloc, for compatibility
   p->header.s_instance = s_instance;
   p->header.alignment  = (uint8_t) alignment;

   return( p);
}


static inline int   bunch_fits_instance( struct mulle_bunch *p,
                                         size_t s_instance,
                                         size_t alignment)
{
   assert( p);
   return( s_instance <= p->header.s_instance &&
           alignment <= p->header.alignment);
}


static inline int   bunch_is_exhausted( struct mulle_bunch *p)
{
   assert( p);
   return( p->header.allocated == OBJECTS_PER_MALLOC);
}


static inline void   *bunch_get_allocation( struct mulle_bunch *p, uint32_t i)
{
   char   *allocation;

   allocation = (char *) &p->header;
   allocation = &allocation[ s_header_align1_offset( p->header.alignment)];
   allocation = &allocation[ i * s_offset_instance_align2( p->header.s_instance, p->header.alignment)];

   return( allocation);
}


static inline id   bunch_alloc_instance( struct mulle_bunch *p)
{
   void      *allocation;
   int32_t   *p_offset;
   id        obj;
   //
   // Build an object
   // put offset to the bunch structure ahead of the instance
   //
   allocation    = bunch_get_allocation( p, p->header.allocated++);
   p_offset      = allocation;
   p_offset[ -1] = (int32_t) ((char *) p - (char *) allocation);
   obj           = objc_getInstance( allocation);

   return( obj);
}


//
// determine struct mulle_bunch adress from object adress
//
static inline struct mulle_bunch   *object_getBunch( id self)
{
   struct mulle_bunch   *p;
   void                 *allocation;
   int32_t              *p_offset;
   int32_t              offset;

   allocation = object_getAlloc( self);
   p_offset   = allocation;
   offset     = p_offset[ -1];
   p          = (struct mulle_bunch *) &((char *) allocation)[ offset];

   return( p);
}


static inline void   bunch_free( struct mulle_bunch *p)
{
   mulle_free( p);
}

/*
##
##
##
*/
static inline void   mulle_bunchinfo_set_current( struct mulle_bunchinfo *p, struct mulle_bunch *bunch)
{

#ifdef DEBUG
   if( bunch)
      *(volatile char *) bunch;
#endif
   p->curr = bunch;
}


void   mulle_bunchinfo_initialize( struct mulle_bunchinfo *info)
{
   //
   // first time ? malloc and initialize a new bunch
   //
   if( ! info->curr)
   {
      mulle_thread_mutex_init( &info->lock);
      info->curr = (struct mulle_bunch *) &info->dummy;
   }
}


void   mulle_bunchinfo_deinitialize( struct mulle_bunchinfo *info)
{
   assert( info->curr);
   if( info->curr != (struct mulle_bunch *) &info->dummy)
      bunch_free( info->curr);
}


id   mulle_bunchinfo_alloc_instance( struct mulle_bunchinfo *info, Class self, size_t extra)
{
   id                   obj;
   struct mulle_bunch   *bunch;
   size_t               s_instance;
   size_t               alignment;

   obj        = nil;
   s_instance = class_getInstanceSize( self) + extra;
   alignment  = sizeof( double); // TODO: neet class_getInstanceAlignment

   //
   // the "trick" here is that we know that:
   // a) there is a bunch waiting for us
   // b) it has one free at least!
   // c) we aren't sure if its large enough though
   //
   mulle_thread_mutex_lock( &info->lock);

   bunch = info->curr;
   if( ! bunch_fits_instance( bunch, s_instance, alignment))
   {
      bunch = bunch_create( s_instance, alignment);
      mulle_bunchinfo_set_current( info, bunch);
   }

   //
   // grab an object from the current bunch
   // and place isa pointer there
   //
   obj = bunch_alloc_instance( bunch);
   object_setClass( obj, self);

   //
   // bunch full ? have one ready for next time
   //
   if( bunch_is_exhausted( bunch))
   {
      bunch = bunch_create( s_instance, __alignof( self));
      mulle_bunchinfo_set_current( info, bunch);
   }

   mulle_thread_mutex_unlock( &info->lock);

   return( obj);
}



void   mulle_bunchinfo_dealloc_instance( struct mulle_bunchinfo *info, id self)
{
   struct mulle_bunch   *p;
   struct mulle_bunch   *tofree;
   unsigned int         max;
   int                  is_curr;

   tofree = NULL;
   p      = object_getBunch( self);

   mulle_thread_mutex_lock( &info->lock);
   //
   // if there are varying sizes then a bunch may have gotten evicted, though
   // it was not filled up. If this is too much, we can get by comparing
   // with p->allocated (and possibly thrashing a little)
   //
   is_curr = info->curr == p;
   max     = is_curr ? OBJECTS_PER_MALLOC : p->header.allocated;
   if( ++p->header.freed == max)
   {
      if( info->curr != (struct mulle_bunch *) &info->dummy)
         tofree = p;
      if( is_curr)
         info->curr = bunch_create( p->header.s_instance, p->header.alignment);
   }
   mulle_thread_mutex_unlock( &info->lock);

   bunch_free( tofree);
}

