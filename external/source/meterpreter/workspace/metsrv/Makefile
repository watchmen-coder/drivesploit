BASEVPATH=../../source/server:../../source/common/crypto:../../source/common/arch/posix:../../source/server/zlib:../../source/server/posix:../../source/server/elf
SRCPATH=../../source/server
COMMONPATH=../../source/common
ELFPATH=../../source/server/elf
SSLPATH=../../source/openssl/include
ULIBCPATH=../../source/ulibc
XOR_PATH=../../source/common/crypto
ZLIB_PATH=../../source/common/zlib
CFLAGS= -D_UNIX -I$(SRCPATH) -DPIC -I$(SSLPATH) -I$(COMMONPATH) -I$(ULIBCPATH) -I$(ELFPATH) -I$(ZLIB_PATH) -I.
CFLAGS+= -fPIC  -g -nostdinc
#CFLAGS+= -Os
CPPFLAGS= -I$(COMMONPATH) -DPIC 
LDFLAGS= -fPIC	-Bshareable

CC=gcc
AR=ar
AS=as -c
LD=ld 
RM=rm


####### check platform
OSNAME= $(shell uname -s)
ARCH= $(shell uname -m | sed 's/i[456]86/i386/g')
RARCH=$(ARCH)

ifeq ($(ARCH), i386)
	CFLAGS+= -D__i386__
	RARCH=i386
endif

ifeq ($(OSNAME), Linux)
	OSNAME= linux
endif

ifeq ($(OSNAME), FreeBSD)
	OS= bsd
# FreeBSD doesn't compile its C runtime glue PIC
# need to compile it ourselves
	CRT1= crt1.o crti.o 
else
	OS=$(OSNAME)
	START=late_start.o
	CFLAGS+= -fno-stack-protector -D__linux__
	DL= -ldl 
endif

CFLAGS+= -L../../source/openssl/lib/$(OS)/$(RARCH)

ELFARCHPATH=$(ELFPATH)/$(RARCH)
CFLAGS+= -I$(ELFARCHPATH) -DIN_RTLD

OSVPATH= ../../source/common/arch/$(OS)
ARCHVPATH= $(OSVPATH)/$(RARCH):$(ELFARCHPATH)
VPATH=$(BASEVPATH):$(OSVPATH):$(ARCHVPATH)

objects = metsrv.o libloader.o zlib.o rtld_late.o rtld_malloc.o rtld_lock.o \
	map_object.o xmalloc.o reloc.o rtld_start.o scheduler.o $(START)
server_objects = server_setup.o remote_dispatch_common.o remote_dispatch.o \
	metsrv_main.o metsrv_standalone.o 
other_objects = metsrv_test.o $(CRT1) crtn.o
library_headers = metsrv_main.h libcrypto_so.h libssl_so.h libuc_so.h

all:  metsrv.a  metsrv.so metsrv_test metsrv_main 
# metsrv_standalone

libserver.a: $(server_objects)
	$(AR) rc $@ $(server_objects)

metsrv_main.h: metsrv_main
	../../tools/so2h.pl metsrv_main metsrv_main

libcrypto_so.h: ../../source/openssl/lib/$(OS)/$(RARCH)/libcrypto.so.gz
	@echo 	../../tools/so2h.pl ../../source/openssl/lib/$(OS)/$(RARCH)/libcrypto.so.gz libcrypto_so
	../../tools/so2h.pl ../../source/openssl/lib/$(OS)/$(RARCH)/libcrypto.so.gz libcrypto_so

libssl_so.h: ../../source/openssl/lib/$(OS)/$(RARCH)/libssl.so.gz 
	../../tools/so2h.pl ../../source/openssl/lib/$(OS)/$(RARCH)/libssl.so.gz  libssl_so
libuc_so.h: ../ulibc/libuc.so
	../../tools/so2h.pl ../ulibc/libuc.so  libuc_so

metsrv.a: $(library_headers) $(server_objects)
	$(AR) rc $@ $(server_objects)

metsrv.so: $(library_headers) $(objects) 
	$(LD) -Bshareable -o $@ $(objects)

ifeq ($(OSNAME), FreeBSD)
metsrv_main: metsrv.o libserver.a ../common/libsupport.a $(CRT1) crtn.o
	$(LD) -pie --unresolved-symbols=ignore-all -o $@ $(CRT1) crtbegin.o \
	libserver.a  ../common/libsupport.a \
	crtend.o crtn.o -nostdlib --allow-shlib-undefined -L. \
	-lcrypto -lssl -L../common -lcommon
else
metsrv_main: metsrv.o libserver.a ../common/libsupport.a 
#	$(CC) -pie -o $@ libserver.a  ../common/libsupport.a  -lcrypto -lssl
	$(CC) $(CFLAGS) -o $@ libserver.a  ../common/libsupport.a  -lcrypto -lssl \
	-export-dynamic
endif


metsrv_test: metsrv_test.o $(library_headers)
	$(CC) $(CFLAGS) metsrv_test.o metsrv.a $(DL)  -o $@ 

clean:
	@echo "ARCHVPATH= " $(ARCHVPATH) " VPATH= " $(VPATH)
	$(RM) -f *.o *.h *.so *.gz *~ *.a metsrv_test metsrv_main \
	metsrv_main_standalone
.PHONY: clean
