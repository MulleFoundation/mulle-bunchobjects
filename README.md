# mulle-bunchobjects

#### 👨‍👩‍👧‍👦 mulle-bunchobjects efficently allocate instances

Instead of allocating memory for each single object, this library allocates
memory for a bunch of objects. The memory can be released or reused, if all
objects of the bunch have been released.

* reduces time spent in malloc
* may waste memory



| Release Version                                       | Release Notes  | AI Documentation
|-------------------------------------------------------|----------------|---------------
| ![Mulle kybernetiK tag](https://img.shields.io/github/tag/MulleFoundation/mulle-bunchobjects.svg) [![Build Status](https://github.com/MulleFoundation/mulle-bunchobjects/workflows/CI/badge.svg)](//github.com/MulleFoundation/mulle-bunchobjects/actions) | [RELEASENOTES](RELEASENOTES.md) | [DeepWiki for mulle-bunchobjects](https://deepwiki.com/MulleFoundation/mulle-bunchobjects)






## Requirements

|   Requirement         | Release Version  | Description
|-----------------------|------------------|---------------
| [objc-compat](https://github.com/MulleFoundation/objc-compat) | ![Mulle kybernetiK tag](https://img.shields.io/github/tag/MulleFoundation/objc-compat.svg) [![Build Status](https://github.com/MulleFoundation/objc-compat/workflows/CI/badge.svg?branch=release)](https://github.com/MulleFoundation/objc-compat/actions/workflows/mulle-sde-ci.yml) | 🔗 Glue for Objective-C code to support different Foundations

### You are here

![Overview](overview.dot.svg)

## Add

Use [mulle-sde](//github.com/mulle-sde) to add mulle-bunchobjects to your project:

``` sh
mulle-sde add github:MulleFoundation/mulle-bunchobjects
```

## Install

Use [mulle-sde](//github.com/mulle-sde) to build and install mulle-bunchobjects and all dependencies:

``` sh
mulle-sde install --prefix /usr/local \
   https://github.com/MulleFoundation/mulle-bunchobjects/archive/latest.tar.gz
```

### Legacy Installation

Install the requirements:

| Requirements                                 | Description
|----------------------------------------------|-----------------------
| [objc-compat](https://github.com/MulleFoundation/objc-compat)             | 🔗 Glue for Objective-C code to support different Foundations

Download the latest [tar](https://github.com/MulleFoundation/mulle-bunchobjects/archive/refs/tags/latest.tar.gz) or [zip](https://github.com/MulleFoundation/mulle-bunchobjects/archive/refs/tags/latest.zip) archive and unpack it.

Install **mulle-bunchobjects** into `/usr/local` with [cmake](https://cmake.org):

``` sh
PREFIX_DIR="/usr/local"
cmake -B build                               \
      -DMULLE_SDK_PATH="${PREFIX_DIR}"       \
      -DCMAKE_INSTALL_PREFIX="${PREFIX_DIR}" \
      -DCMAKE_PREFIX_PATH="${PREFIX_DIR}"    \
      -DCMAKE_BUILD_TYPE=Release &&
cmake --build build --config Release &&
cmake --install build --config Release
```

## Author

[Nat!](https://mulle-kybernetik.com/weblog) for Mulle kybernetiK  


