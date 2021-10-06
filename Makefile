# xbs-compatible wrapper Makefile for Clam AV
#

PROJECT=clamav

SHELL := /bin/sh

# Sane defaults, which are typically overridden on the command line.
SRCROOT=
OBJROOT=$(SRCROOT)
SYMROOT=$(OBJROOT)
DSTROOT=/usr/local
RC_ARCHS=
CFLAGS=-O0 $(RC_CFLAGS)

# Configuration values we customize
#

PROJECT_NAME=clamav
OS_VER=0.96.5
CLAMAV_TAR_GZ=clamav-$(OS_VER).tar.gz
CLAMAV_PATCH_DIFFS=clamav-$(OS_VER).diff

MODULES=Crypt-OpenSSL-RSA-0.26 Mail-DKIM-0.38 

PERL_VER=`perl -V:version | sed -n -e "s/[^0-9.]*\([0-9.]*\).*/\1/p"`
PERL_DIR=/System/Library/Perl
PERL_EXTRA_DIR=/System/Library/Perl/Extras
PERL_EXTRA_VER_DIR=$(PERL_EXTRA_DIR)/$(PERL_VER)

BUILD_DIR=$(OBJROOT)/build
CLAMAV_BUILD_DIR=/$(BUILD_DIR)/$(PROJECT_NAME)-$(OS_VER)
ETC_DIR=/private/etc
VAR_CLAM=/private/var/clamav
CLAM_SHARE_DIR=/private/var/clamav/share
CLAM_STATE_DIR=/private/var/clamav/state
LIB_TOOL=$(CLAMAV_BUILD_DIR)/libtool
LAUNCHDDIR=/System/Library/LaunchDaemons

BINARY_DIR=clamav.Bin
CONFIG_DIR=clamav.Conf
OS_SRC_DIR=clamav.OpenSourceInfo
LD_SRC_DIR=clamav.LaunchDaemons
UPDATE_DIR=clamav.Update

USR=/usr
USR_BIN=/usr/bin
USR_SBIN=/usr/sbin
SHARE_1_DIR=/usr/share/man/man1
SHARE_5_DIR=/usr/share/man/man5
SHARE_8_DIR=/usr/share/man/man8
USR_LOCAL=/usr/local
USR_OS_VERSION=$(USR_LOCAL)/OpenSourceVersions
USR_OS_LICENSE=$(USR_LOCAL)/OpenSourceLicenses

SETUP_EXTRAS_SRC_DIR=clamav.SetupExtras
COMMON_EXTRAS_DST_DIR=/System/Library/ServerSetup/CommonExtras

STRIP=/usr/bin/strip
GNUTAR=/usr/bin/gnutar
CHOWN=/usr/sbin/chown
PATCH=/usr/bin/patch

# Perl config
#
PERL_CONFIG = \
	PREFIX=/ \
	INSTALLPRIVLIB=/System/Library/Perl/$(PERL_VER) \
	INSTALLSITELIB=/System/Library/Perl/Extras/$(PERL_VER) \
	INSTALLMAN1DIR=/usr/share/man/man1 \
	INSTALLMAN3DIR=/usr/share/man/man3


# Clam Antivirus config
#

CLAMAV_CONFIG_SHARED= \
	--exec-prefix=/usr \
	--bindir=/usr/bin \
	--sbindir=/usr/sbin \
	--libexecdir=/usr/libexec \
	--datadir=/usr/share/clamav \
	--sysconfdir=/private/etc \
	--sharedstatedir=/private/var/clamav/share \
	--localstatedir=/private/var/clamav/state \
	--disable-dependency-tracking \
	--libdir=/usr/lib/clamav \
	--includedir=/usr/share/clamav/include \
	--oldincludedir=/usr/share/clamav/include \
	--infodir=/usr/share/clamav/info \
	--mandir=/usr/share/man \
	--with-dbdir=/private/var/clamav \
	--with-user=_clamav \
	--with-group=_clamav \
	--with-gnu-ld

CLAMAV_CONFIG_STATIC= \
	--prefix=/ \
	--exec-prefix=/usr \
	--bindir=/usr/bin \
	--sbindir=/usr/sbin \
	--libexecdir=/usr/libexec \
	--datadir=/usr/share/clamav \
	--sysconfdir=/private/etc \
	--sharedstatedir=/private/var/clamav/share \
	--localstatedir=/private/var/clamav/state \
	--disable-dependency-tracking \
	--libdir=/usr/lib/clamav \
	--includedir=/usr/share/clamav/include \
	--oldincludedir=/usr/share/clamav/include \
	--infodir=/usr/share/clamav/info \
	--mandir=/usr/share/man \
	--with-dbdir=/private/var/clamav \
	--disable-shared \
	--with-user=_clamav \
	--with-group=_clamav \
	--with-gnu-ld \
	--enable-static

# These includes provide the proper paths to system utilities
#

include $(MAKEFILEPATH)/pb_makefiles/platform.make
include $(MAKEFILEPATH)/pb_makefiles/commands-$(OS).make

default:: make_clamav

install :: make_clamav_install

clean :
	$(SILENT) ($(CD) "$(SRCROOT)/$(UPDATE_DIR)" && /usr/bin/xcodebuild clean)

installhdrs :
	$(SILENT) $(ECHO) "No headers to install"

installsrc :
	[ ! -d $(SRCROOT)/$(PROJECT) ] && mkdir -p $(SRCROOT)/$(PROJECT)
	tar cf - . | (cd $(SRCROOT) ; tar xfp -)
	find $(SRCROOT) -type d -name CVS -print0 | xargs -0 rm -rf

make_clamav :
	$(SILENT) $(ECHO) "------------ Make Clam AV ------------"
	$(SILENT) if [ ! -d "$(BUILD_DIR)" ]; then \
		$(SILENT) (mkdir "$(BUILD_DIR)"); \
	fi
	$(SILENT) if [ -e "$(SRCROOT)/$(BINARY_DIR)/$(CLAMAV_TAR_GZ)" ]; then \
		$(SILENT) ($(CD) "$(BUILD_DIR)" && $(GNUTAR) -xzpf "$(SRCROOT)/$(BINARY_DIR)/$(CLAMAV_TAR_GZ)") ; \
	fi
	$(SILENT) if [ -e "$(SRCROOT)/$(BINARY_DIR)/$(CLAMAV_PATCH_DIFFS)" ]; then \
		$(SILENT) ($(CD) "$(CLAMAV_BUILD_DIR)" && $(PATCH) -p1 < "$(SRCROOT)/$(BINARY_DIR)/$(CLAMAV_PATCH_DIFFS)") ; \
	fi
	$(SILENT) ($(CD) "$(CLAMAV_BUILD_DIR)" && ./configure $(CLAMAV_CONFIG))
	$(SILENT) ($(CD) "$(CLAMAV_BUILD_DIR)" && make CFLAGS="$(CFLAGS)")
	$(SILENT) ($(CD) "$(SRCROOT)/$(UPDATE_DIR)" && /usr/bin/xcodebuild)
	$(SILENT) ($(CD) "$(SRCROOT)/$(UPDATE_DIR)" && /usr/bin/xcodebuild clean)

make_clamav_install :
	# Unstuff archive
	$(SILENT) $(ECHO) "------------ Make Install Perl Modules ------------"
	$(SILENT) $(ECHO) "Perl Version: $(PERL_VER)"

	$(SILENT) if [ ! -d "$(BUILD_DIR)" ]; then \
		$(SILENT) (mkdir "$(BUILD_DIR)"); \
	fi

	for perl_mod in $(MODULES); \
	do \
		$(CD) "$(OBJROOT)/build" && $(GNUTAR) -xzpf "$(SRCROOT)/$(BINARY_DIR)/$$perl_mod.tar.gz"; \
		$(CD) "$(OBJROOT)/build/$$perl_mod" && perl Makefile.PL $(PERL_CONFIG) && \
				make DESTDIR=$(DSTROOT) CFLAGS="$(RC_CFLAGS)" OTHERLDFLAGS="$(RC_CFLAGS)" install; \
	done

	$(SILENT) if [ -d "$(DSTROOT)/share" ]; then \
		$(SILENT) ($(MV) "$(DSTROOT)/share" "$(DSTROOT)/usr/"); \
	fi
	$(SILENT) if [ -d "$(DSTROOT)$(PERL_DIR)/$(PERL_VER)" ]; then \
		$(SILENT) ($(RM) -r "$(DSTROOT)$(PERL_DIR)/$(PERL_VER)"); \
	fi
	$(SILENT) $(ECHO) "------------ Make Install Perl Modules Done ------------"

	$(SILENT) $(ECHO) "------------ Make Install Clam AV ------------"
	$(SILENT) if [ -e "$(SRCROOT)/$(BINARY_DIR)/$(CLAMAV_TAR_GZ)" ]; then\
		$(SILENT) ($(CD) "$(BUILD_DIR)" && $(GNUTAR) -xzpf "$(SRCROOT)/$(BINARY_DIR)/$(CLAMAV_TAR_GZ)") ; \
	fi
	$(SILENT) if [ -e "$(SRCROOT)/$(BINARY_DIR)/$(CLAMAV_PATCH_DIFFS)" ]; then\
		$(SILENT) ($(CD) "$(CLAMAV_BUILD_DIR)" && $(PATCH) -p1 < "$(SRCROOT)/$(BINARY_DIR)/$(CLAMAV_PATCH_DIFFS)") ; \
	fi

	$(SILENT) ($(CD) "$(SRCROOT)/$(UPDATE_DIR)" && /usr/bin/xcodebuild install DSTROOT="$(DSTROOT)")
	$(SILENT) ($(CD) "$(SRCROOT)/$(UPDATE_DIR)" && /usr/bin/xcodebuild clean)

	# Configure and make Clam AV
	$(SILENT) ($(CD) "$(CLAMAV_BUILD_DIR)" && ./configure $(CLAMAV_CONFIG_SHARED))
	if grep -qs 'LTCFLAGS=\"-g -O2\"' $(CLAMAV_BUILD_DIR)/libtool ; then \
		mv $(LIB_TOOL) $(LIB_TOOL).bak ; \
		sed -e 's/LTCFLAGS=\"-g -O2\"/LTCFLAGS=\"$(CFLAGS)"/g' $(LIB_TOOL).bak > $(LIB_TOOL) ; \
	fi
	$(SILENT) ($(CD) "$(CLAMAV_BUILD_DIR)" && make CFLAGS="$(CFLAGS)" CPPFLAGS="$(CFLAGS)")
	$(SILENT) ($(CD) "$(CLAMAV_BUILD_DIR)" && make "DESTDIR=$(OBJROOT)/build/temp" CFLAGS="$(CFLAGS)" CPPFLAGS="$(CFLAGS)" install)

	# next build
	$(SILENT) ($(CD) $(CLAMAV_BUILD_DIR) && make distclean)
	$(SILENT) ($(CD) "$(CLAMAV_BUILD_DIR)" && ./configure $(CLAMAV_CONFIG_STATIC))
	if grep -qs 'LTCFLAGS=\"-g -O2\"' $(CLAMAV_BUILD_DIR)/libtool ; then \
	mv $(LIB_TOOL) $(LIB_TOOL).bak ; \
		sed -e 's/LTCFLAGS=\"-g -O2\"/LTCFLAGS=\"$(CFLAGS)"/g' $(LIB_TOOL).bak > $(LIB_TOOL) ; \
	fi
	$(SILENT) ($(CD) "$(CLAMAV_BUILD_DIR)" && make CFLAGS="$(CFLAGS)" CPPFLAGS="$(CFLAGS)")
	$(SILENT) ($(CD) "$(CLAMAV_BUILD_DIR)" && make "DESTDIR=$(DSTROOT)" CFLAGS="$(CFLAGS)" CPPFLAGS="$(CFLAGS)" install)

	install -m 0755 "$(DSTROOT)/System/Library/ServerSetup/MigrationExtras/UpgradeClamAV" \
			"$(DSTROOT)/System/Library/ServerSetup/MigrationExtras/66_clamav_migrator"
	$(SILENT) ($(RM) -rf "$(DSTROOT)/System/Library/ServerSetup/MigrationExtras/UpgradeClamAV")


	# Install libs
	$(SILENT) ($(RM) -rf $(DSTROOT)/usr/lib/clamav)
	install -d -m 0755 "$(DSTROOT)/usr/lib/clamav"
	install -m 0755 $(OBJROOT)/build/temp/usr/lib/clamav/libclamunrar.6.dylib $(DSTROOT)/usr/lib/clamav/libclamunrar.6.dylib
	install -m 0755 $(OBJROOT)/build/temp/usr/lib/clamav/libclamunrar_iface.6.so $(DSTROOT)/usr/lib/clamav/libclamunrar_iface.6.so
	$(SILENT) ($(CD) $(DSTROOT)/usr/lib/clamav/ && ln -s libclamunrar_iface.6.so libclamunrar_iface.so)

	# Create install directories
	install -d -m 0755 "$(DSTROOT)$(CLAM_SHARE_DIR)"
	install -d -m 0755 "$(DSTROOT)$(CLAM_STATE_DIR)"
	install -d -m 0755 "$(DSTROOT)$(LAUNCHDDIR)"
	install -d -m 0755 "$(DSTROOT)$(USR_OS_VERSION)"
	install -d -m 0755 "$(DSTROOT)$(USR_OS_LICENSE)"
	install -d -m 0755 "$(DSTROOT)$(COMMON_EXTRAS_DST_DIR)"

	# Install defautl config files
	install -m 0644 "$(SRCROOT)/$(CONFIG_DIR)/clamd.conf" "$(DSTROOT)$(ETC_DIR)/clamd.conf"
	install -m 0644 "$(SRCROOT)/$(CONFIG_DIR)/clamd.conf" "$(DSTROOT)$(ETC_DIR)/clamd.conf.default"
	install -m 0644 "$(SRCROOT)/$(CONFIG_DIR)/freshclam.conf" "$(DSTROOT)$(ETC_DIR)/freshclam.conf"
	install -m 0644 "$(SRCROOT)/$(CONFIG_DIR)/freshclam.conf" "$(DSTROOT)$(ETC_DIR)/freshclam.conf.default"

	# Install & strip binaries
	$(SILENT) $(STRIP) -S "$(DSTROOT)/System/Library/Perl/Extras/5.10.0/darwin-thread-multi-2level/auto/Crypt/OpenSSL/RSA/RSA.bundle"
	$(SILENT) $(RM) "$(DSTROOT)/System/Library/Perl/Extras/5.10.0/darwin-thread-multi-2level/auto/Crypt/OpenSSL/RSA/RSA.bs"

	# Install default clam databases
	chmod 644 "$(DSTROOT)$(VAR_CLAM)/daily.cvd"
	chmod 644 "$(DSTROOT)$(VAR_CLAM)/main.cvd"
	chown -R 82 "$(DSTROOT)$(VAR_CLAM)"
	chmod 755 "$(DSTROOT)$(VAR_CLAM)"
	chmod 444 "$(DSTROOT)$(SHARE_1_DIR)/"*
	chmod 444 "$(DSTROOT)$(SHARE_5_DIR)/"*
	chmod 444 "$(DSTROOT)$(SHARE_8_DIR)/"*

	# Install Setup Extras
	install -m 0755 "$(SRCROOT)/$(SETUP_EXTRAS_SRC_DIR)/clamav" "$(DSTROOT)$(COMMON_EXTRAS_DST_DIR)/SetupClamAV.sh"
	install -m 0644 "$(SRCROOT)/$(LD_SRC_DIR)/org.clamav.clamd.plist" "$(DSTROOT)/$(LAUNCHDDIR)/org.clamav.clamd.plist"
	install -m 0644 "$(SRCROOT)/$(LD_SRC_DIR)/org.clamav.freshclam.plist" "$(DSTROOT)/$(LAUNCHDDIR)/org.clamav.freshclam.plist"

	# Install Open Source plist & License files
	install -m 444 "$(SRCROOT)/$(OS_SRC_DIR)/clamav.plist" "$(DSTROOT)/$(USR_OS_VERSION)/clamav.plist"
	install -m 444 "$(SRCROOT)/$(OS_SRC_DIR)/clamav.txt" "$(DSTROOT)/$(USR_OS_LICENSE)/clamav.txt"

	# Set ownership of installed directories & files
	$(SILENT) ($(CHOWN) -R root:wheel "$(DSTROOT)")
	$(SILENT) ($(CHOWN) -R clamav:clamav "$(DSTROOT)$(VAR_CLAM)")
	$(SILENT) ($(CHOWN) -R root:wheel "$(DSTROOT)/usr/share/man")
	$(SILENT) ($(CHOWN) -R root:wheel "$(DSTROOT)/usr/bin")

	$(SILENT) ($(RM) -rf "$(DSTROOT)/usr/share/clamav")

	$(SILENT) $(ECHO) "---- Building Clam AV complete."

.PHONY: installhdrs installsrc build install 

