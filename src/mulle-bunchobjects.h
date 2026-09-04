//
//  mulle-bunchobjects.h
//  mulle-bunchobjects
//
//  Copyright (c) 2021 Nat! - Mulle kybernetiK.
//  All rights reserved.
//
//
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions are met:
//
//  Redistributions of source code must retain the above copyright notice, this
//  list of conditions and the following disclaimer.
//
//  Redistributions in binary form must reproduce the above copyright notice,
//  this list of conditions and the following disclaimer in the documentation
//  and/or other materials provided with the distribution.
//
//  Neither the name of Mulle kybernetiK nor the names of its contributors
//  may be used to endorse or promote products derived from this software
//  without specific prior written permission.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
//  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
//  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
//  ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
//  LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
//  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
//  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
//  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
//  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
//  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
//  POSSIBILITY OF SUCH DAMAGE.
//
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

#define MULLE_BUNCHOBJECTS_VERSION   ((0UL << 20) | (20 << 8) | 10)

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
