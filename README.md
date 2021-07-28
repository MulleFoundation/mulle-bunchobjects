# mulle-bunchobjects

#### 👨‍👩‍👧‍👦 mulle-bunchobjects efficently allocate instances

Instead of allocating memory for each single object, this library allocates
memory for a bunch of objects. The memory can be released or reused, if all
objects of the bunch have been released.

As an example lets create bunches of eight objects each. Each object in the
bunch is either 'unused', 'allocated', or 'freed'. Freed objects and unused
objects can be used for +alloc. Once each object is 'freed', the whole bunch
memory can be freed.

``` 
Bunch of 8 objects:
     .---.---.---.---.---.---.---.---.
     | F | F | A | A | A | A | A | U |
     '---'---'---'---'---'---'---'---'
``

You can't use bunch objects, if you need extra bytes during allocation
(see [NSAllocateObject](https://developer.apple.com/documentation/foundation/1587930-nsallocateobject?language=objc)).

This library builds on objc-compat, and therefore works with the
MulleFoundation and the AppleFoundation.


## Add

Use [mulle-sde](//github.com/mulle-sde) to add mulle-bunchobjects to your project:

``` console
mulle-sde dependency add --c --github --marks no-header MulleFoundation mulle-bunchobjects
```

## Install

### mulle-sde

Use [mulle-sde](//github.com/mulle-sde) to build and install mulle-bunchobjects
and all its dependencies:

```
mulle-sde install --prefix /usr/local \
   https://github.com/MulleFoundation/mulle-bunchobjects/archive/latest.tar.gz
```

### Manual Installation


Install the requirements:

Requirements                                               | Description
-----------------------------------------------------------|-----------------------
[compat-objc](//github.com/MulleFoundation/compat-objc)    | Portable Objective-C runtime
[mulle-thread](//github.com/mulle-concurrent/mulle-thread) | Portable locks
[mulle-allocator](//github.com/mulle-c/mulle-allocator)    | Portable memory allocation



Install into `/usr/local`:

```
mkdir build 2> /dev/null
(
   cd build ;
   cmake -DCMAKE_INSTALL_PREFIX=/usr/local \
         -DCMAKE_PREFIX_PATH=/usr/local \
         -DCMAKE_BUILD_TYPE=Release .. ;
   make install
)
```

### Steal

Read [STEAL.md](//github.com/mulle-c11/dox/STEAL.md) on how to steal the
source code and incorporate it in your own projects.
