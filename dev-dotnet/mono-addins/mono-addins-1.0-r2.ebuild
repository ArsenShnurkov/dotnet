# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=5

inherit eutils dotnet multilib autotools-utils

DESCRIPTION="A generic framework for creating extensible applications"
HOMEPAGE="http://www.mono-project.com/Mono.Addins"
SRC_URI="http://github.com/mono/${PN}/archive/${P}.tar.gz -> ${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~ppc ~x86"
IUSE="+gtk net45 +gac +nupkg +pkg-config debug developer"
USE_DOTNET="net45"

COMMON_DEPEND=">=dev-lang/mono-4.0.2.5
"

RDEPEND="${COMMON_DEPEND}
	gtk? ( >=dev-dotnet/gtk-sharp-2.12.21:2 )"
DEPEND="$${COMMON_DEPEND}
	virtual/pkgconfig"
MAKEOPTS="${MAKEOPTS} -j1" #nowarn

S="${WORKDIR}/${PN}-${P}"

NUSPEC_FILE="${S}/Open.Nat/Open.Nat.nuspec"
NUSPEC_VERSION="${PVR//-r/.}"
if use debug; then
    DIR="Debug"
else
    DIR="Release"
fi
OUTPUT_DIR=Open.Nat/bin
GAC_DLL_NAME=Open.Nat


src_prepare() {
	epatch "${FILESDIR}/gmcs.patch"

	eautoreconf
	autotools-utils_src_prepare
	## with dev-dotnet/gtk-sharp-2.99.1
	## it gives
	## checking for GTK_SHARP_20... no
	## configure: error: Package requirements (gtk-sharp-2.0) were not met:
	##
	## No package 'gtk-sharp-2.0' found

	sed -i "s;Mono.Cairo;Mono.Cairo, Version=4.0.0.0, Culture=neutral, PublicKeyToken=0738eb9f132ed756;g" Mono.Addins.Gui/Mono.Addins.Gui.csproj || die "sed failed"

	patch_nuspec_file ${NUSPEC_FILE}
}

src_configure() {
	econf $(use_enable gtk gui)
}

src_compile() {
	default

	# run nuget_pack
	enuspec -Prop version=${NUSPEC_VERSION} ${NUSPEC_FILE}
}

src_install() {
	default

	enupkg "${WORKDIR}/${NAME}.${NUSPEC_VERSION}.nupkg"
	egacinstall "${OUTPUT_DIR}/${DIR}/${GAC_DLL_NAME}.dll"
	install_pc_file

	dotnet_multilib_comply
}

patch_nuspec_file()
{
	if use nupkg; then
		if use debug; then
			DIR="Debug"
		else
			DIR="Release"
		fi
		FILES_STRING=`cat <<-EOF || die "files at patch_nuspec_file()"
		       <files> <!-- https://docs.nuget.org/create/nuspec-reference -->
		               <file src="${OUTPUT_DIR}/${DIR}/*.dll" target="lib\net45\" />
		               <file src="${OUTPUT_DIR}/${DIR}/*.mdb" target="lib\net45\" />
		       </files>
		EOF
		`
		einfo ${FILES_STRING}
		replace "</package>" "${FILES_STRING}</package>" -- $1 || die "replace at patch_nuspec_file()"
	fi
}

PC_FILE_NAME=${PN}

install_pc_file()
{
	if use pkg-config; then
		dodir /usr/$(get_libdir)/pkgconfig
		ebegin "Installing ${PC_FILE_NAME}.pc file"
		sed \
			-e "s:@LIBDIR@:$(get_libdir):" \
			-e "s:@PACKAGENAME@:${PC_FILE_NAME}:" \
			-e "s:@DESCRIPTION@:${DESCRIPTION}:" \
			-e "s:@VERSION@:${PV}:" \
			-e 's;@LIBS@;-r:${libdir}'"/mono/${PC_FILE_NAME}/${GAC_DLL_NAME}.dll;" \
			<<\EOF >"${D}/usr/$(get_libdir)/pkgconfig/${PC_FILE_NAME}.pc" || die
prefix=${pcfiledir}/../..
exec_prefix=${prefix}
libdir=${exec_prefix}/@LIBDIR@

Name: @PACKAGENAME@
Description: @DESCRIPTION@
Version: @VERSION@
Libs: @LIBS@
EOF
# Package exported to: /var/tmp/portage/dev-dotnet/Open-NAT-1.0.0-r201510290/image//usr/lib64/mono/Open-NAT/Open.Nat.dll -> ../gac/Open.Nat/1.0.0.0__0738eb9f132ed756/Open.Nat.dll
# Installed Open.Nat/bin/Release/Open.Nat.dll into the gac (/var/tmp/portage/dev-dotnet/Open-NAT-1.0.0-r201510290/image//usr/lib64/mono/gac)

		einfo PKG_CONFIG_PATH="${D}/usr/$(get_libdir)/pkgconfig/" pkg-config --exists "${PC_FILE_NAME}"
		PKG_CONFIG_PATH="${D}/usr/$(get_libdir)/pkgconfig/" pkg-config --exists "${PC_FILE_NAME}" || die ".pc file failed to validate."
		eend $?
	fi
}
