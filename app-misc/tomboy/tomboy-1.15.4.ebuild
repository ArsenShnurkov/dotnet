# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI="5"
GCONF_DEBUG="no"
GNOME2_LA_PUNT="yes"

inherit autotools eutils gnome2 mono

DESCRIPTION="Desktop note-taking application"
HOMEPAGE="http://projects.gnome.org/tomboy/"

LICENSE="LGPL-2.1"
SLOT="0"
KEYWORDS="amd64 ~ppc x86"
IUSE="eds test"

#	dev-libs/atk:=
#	x11-libs/gtk+:2

RDEPEND="
	>=dev-lang/mono-4.0.2.5
	>=dev-dotnet/mono-addins-1.0[gtk]
	>=dev-dotnet/dbus-sharp-0.8.1
	>=dev-dotnet/dbus-sharp-glib-0.6
	>=dev-dotnet/gtk-sharp-2.12.23:2
	app-text/gtkspell:2
	dev-dotnet/gconf-sharp:2
	gnome-base/gconf:2
	eds? ( dev-libs/gmime:2.6[mono] )
"
DEPEND="${RDEPEND}
	app-text/gnome-doc-utils
	app-text/rarian
	dev-util/intltool
	virtual/pkgconfig
	sys-devel/gettext
"

src_prepare() {
	sed	\
		-e "s:AM_CONFIG_HEADER:AC_CONFIG_HEADERS:g" \
		-i configure.in || die

	eautoreconf
	gnome2_src_prepare
}

src_configure() {
	gnome2_src_configure \
		--disable-panel-applet \
		--disable-galago \
		--disable-update-mimedb \
		$(use_enable eds evolution) \
		$(use_enable test tests)
}

src_compile() {
	# http://dev.gentoo.org/~zmedico/portage/doc/api/repoman.checks.EMakeParallelDisabled-class.html
	# Not parallel build safe due upstream bug https://bugzilla.gnome.org/show_bug.cgi?id=631546
	MAKEOPTS="${MAKEOPTS} -j1" gnome2_src_compile
}
