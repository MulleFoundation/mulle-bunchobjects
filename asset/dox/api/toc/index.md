# mulle-bunchobjects Library Documentation for AI
<!-- Keywords: bunch, allocation, objc, pool, allocator, threadsafe, pooling -->
## 1. Introduction & Purpose

- mulle-bunchobjects provides a lightweight object-pool allocator for Objective-C objects: instead of malloc/free per-instance it allocates "bunches" (chunks) that contain multiple object instances.
- Problem solved: reduce malloc overhead when creating many short-lived small Objective-C instances.
- Key features: chunked allocation, per-class instance allocation helper, minimal per-instance metadata (offset field), automatic reuse and delayed free of bunches, thread-safe via a mutex inside the bunch info.
- Relationship: integrates with MulleObjC and depends on mulle-allocator and mulle-thread for allocation and locking.

## 2. Key Concepts & Design Philosophy

- Bunch: a single malloc region containing a header plus N aligned instance slots (OBJECTS_PER_MALLOC: 2 in DEBUG, 16 in Release).
- Per-class bunchinfo: struct mulle_bunchinfo tracks the current bunch and a mutex; user classes keep one static bunchinfo.
- Offset trick: for each allocated instance, the integer placed just before the instance stores the offset to the bunch header so deallocation can find its bunch.
- Allocation strategy: allocate objects from the current bunch; when exhausted, create a new bunch. Deallocation increments freed count; when all objects in a bunch are freed the bunch is released.
- Threading: a mutex serializes alloc/dealloc operations on a bunchinfo, making API safe for concurrent use.

## 3. Core API & Data Structures

### 3.1. [mulle-bunchobjects.h]

#### `struct mulle_bunchheader`
- Purpose: small header placed at the start of each bunch describing instance size, alignment and counts.
- Key fields:
  - `int32_t s_instance` : size in bytes available for instances (includes extra if requested).
  - `uint8_t alignment` : alignment used for instances.
  - `uint8_t freed` : count of freed instances in this bunch.
  - `uint8_t allocated` : number of instances allocated in this bunch (by user allocation).

#### `struct mulle_bunch`
- Purpose: public-visible container starting with a mulle_bunchheader; represents an allocated bunch region.
- Key Fields: `struct mulle_bunchheader header`.

#### `struct mulle_bunchinfo`
- Purpose: per-class (or per-purpose) allocator state. Holds current bunch and lock.
- Key Fields:
  - `struct mulle_bunch *curr` : pointer to the current bunch (or &dummy if none)
  - `mulle_thread_mutex_t lock` : mutex protecting the info
  - `struct mulle_bunchheader dummy` : placeholder header used when no real bunch exists

#### Lifecycle & Core Operations
- `static inline int mulle_bunchinfo_is_initialized(struct mulle_bunchinfo *info)`
  - Returns non-zero when info->curr != NULL.
- `void mulle_bunchinfo_initialize(struct mulle_bunchinfo *info)`
  - Initialize mutex and set curr to dummy if not already initialized.
- `void mulle_bunchinfo_deinitialize(struct mulle_bunchinfo *info)`
  - Free the current bunch if it isn't the dummy; leaves mutex state (init happens only once).
- `id mulle_bunchinfo_alloc_instance(struct mulle_bunchinfo *info, Class self, size_t extra)`
  - Allocate and return an object instance for class `self`. `extra` allows larger instance payloads.
  - Internals: locks mutex, checks if current bunch fits size/alignment, creates a bunch if necessary, places offset before instance, sets object's class/isa, may create next ready bunch when current becomes exhausted, unlocks and returns object.
- `void mulle_bunchinfo_dealloc_instance(struct mulle_bunchinfo *info, id self)`
  - Deallocate an instance: finds its bunch via stored offset, increments `freed`, if all objects freed then frees the bunch (and if it was current, replaces it with a fresh bunch).

#### Macros when USE_BUNCH_OBJECTS not defined
- When USE_BUNCH_OBJECTS is not defined the header defines macros that map:
  - `mulle_bunchinfo_initialize(info)` -> no-op
  - `mulle_bunchinfo_deinitialize(info)` -> no-op
  - `mulle_bunchinfo_alloc_instance(info,self,extra)` -> `[self alloc]`
  - `mulle_bunchinfo_dealloc_instance(info,self)` -> `[super dealloc]`

### 3.2. [Implementation notes from mulle-bunchobjects.m]
- OBJECTS_PER_MALLOC is 2 in DEBUG, 16 otherwise; controls amortized allocation granularity.
- Alignments are computed for the header-to-instance layout; offsets are stored as an int32 immediately before each instance.
- Uses `mulle-allocator` (`mulle_calloc`, `mulle_free`) and `mulle-thread` mutex calls.

## 4. Performance Characteristics

- Allocation: O(1) amortized per instance; real work only when a new bunch is created.
- Deallocation: O(1) per instance; when last instance of a bunch is freed, the whole bunch memory is freed.
- Memory tradeoff: may waste memory because each bunch holds OBJECTS_PER_MALLOC instances with fixed alignment and header overhead; good for many small frequent allocations.
- Typical throughput improvement: fewer system malloc/free calls; beneficial when creating many small Objective-C objects.
- Thread-safety: allocation and deallocation are protected by a mutex in mulle_bunchinfo, therefore safe for concurrent uses of the same bunchinfo.

## 5. AI Usage Recommendations & Patterns

- Best practices:
  - Define a single static `struct mulle_bunchinfo` per class (or per allocation domain).
  - Initialize in `+initialize` via `mulle_bunchinfo_initialize(&bunchinfo)` after checking `mulle_bunchinfo_is_initialized`.
  - Provide `+deinitialize` or similar to call `mulle_bunchinfo_deinitialize(&bunchinfo)` when appropriate.
  - For allocation override: implement `+alloc`, `+new`, and `-dealloc` to call `mulle_bunchinfo_alloc_instance` and `mulle_bunchinfo_dealloc_instance` respectively (see tests for exact placement).
  - Respect the header’s macro fallback: define `USE_BUNCH_OBJECTS` to enable pooling; otherwise the macros map to normal alloc/dealloc.
- Common pitfalls:
  - Do not access internal fields of `struct mulle_bunch` or `mulle_bunchheader` directly from user code.
  - The code assumes class instance size fits in int32; avoid extremely large instance sizes.
  - Alignment is approximated (uses sizeof(double) or __alignof(self)); for exotic alignments verify behavior.
- Idiomatic usage:
  - Use the exact pattern from tests: static `bunchinfo`, initialize in `+initialize`, call alloc/dealloc helpers in `+new`/`-dealloc`.

## 6. Integration Examples

### Example 1: Creating a pooled Objective-C class (from test/bunch.m)

```c
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
```

- This example shows the full lifecycle: initialize, allocate, and dealloc via the bunch helpers.

### Example 2: Fallback to normal alloc when pooling disabled

```c
// If USE_BUNCH_OBJECTS not defined, the header provides macros mapping
// mulle_bunchinfo_alloc_instance(...) to [self alloc] and
// mulle_bunchinfo_dealloc_instance(...) to [super dealloc].
// Code using the API is therefore portable with and without pooling.
```

## 7. Dependencies

- MulleObjC (runtime / user-facing Objective-C usage in tests)
- objc-compat (glue for Objective-C compatibility)
- mulle-allocator (mulle_calloc / mulle_free used in implementation)
- mulle-thread (mulle_thread_mutex_t and lock API)

--
Notes for AI consumers:
- Primary source of truth: src/mulle-bunchobjects.h (public API) and src/mulle-bunchobjects.m (behavioral details).
- Test example: test/25_bunchobjects/bunch.m demonstrates intended lifecycle and is the canonical usage sample.
- Use the header macros to detect whether pooling is enabled (USE_BUNCH_OBJECTS).