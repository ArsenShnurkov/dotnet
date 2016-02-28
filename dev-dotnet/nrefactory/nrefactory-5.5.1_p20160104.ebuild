# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=6

inherit nupkg

HOMEPAGE="http://www.codeproject.com/Articles/408663/Using-NRefactory-for-analyzing-Csharp-code"
DESCRIPTION="System.Reflection alternative to generate and inspect .NET executables/libraries"
# https://github.com/icsharpcode/NRefactory/blob/master/doc/license.txt
LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~x86"
USE_DOTNET="net45"
IUSE="net35 net40 net45 +gac +nupkg +pkg-config debug developer"

COMMON_DEPEND=">=dev-lang/mono-4.0.2.5
    >=dev-dotnet/cecil-0.9.6
"

RDEPEND="${COMMON_DEPEND}
"

DEPEND="${COMMON_DEPEND}
	>=dev-dotnet/nunit-2.6.4:2
	dev-dotnet/ikvm
	virtual/pkgconfig
"

NAME="NRefactory"
REPOSITORY="https://github.com/icsharpcode/${NAME}"
LICENSE_URL="${REPOSITORY}/blob/master/doc/license.txt"
ICONMETA="http://www.danielgrunwald.de/jufo/2006/Jufo06-Dateien/image004.gif"
ICON_URL="file://${FILESDIR}/nuget_icon_64x64.png"

EGIT_BRANCH="master"
EGIT_COMMIT="79f9a95f93003ad77214be22a1c31387d24e5491"
SRC_URI="${REPOSITORY}/archive/${EGIT_BRANCH}/${EGIT_COMMIT}.zip -> ${PF}.zip
	mirror://gentoo/mono.snk.bz2"
#S="${WORKDIR}/${NAME}-${EGIT_COMMIT}"
S="${WORKDIR}/${NAME}-${EGIT_BRANCH}"

METAFILETOBUILD="./NRefactory.sln"

GAC_DLL_NAME=NRefactory

NUSPEC_ID="NRefactory"
NUSPEC_FILE="${S}/Packages/ICSharpCode.NRefactory.nuspec"
NUSPEC_VERSION="${PV//_p/.}"

src_prepare() {
	enuget_restore "${METAFILETOBUILD}"

	eapply "${FILESDIR}/nuspec.patch"

	eapply_user
}

src_configure() {
	:;
}

src_compile() {
	if [[ -z ${TOOLS_VERSION} ]]; then
		TOOLS_VERSION=4.0
	fi
	PARAMETERS=" /tv:${TOOLS_VERSION}"
	if use developer; then
		SARGS=/p:DebugSymbols=True
	else
		SARGS=/p:DebugSymbols=False
	fi
	PARAMETERS+=" ${SARGS}"
	PARAMETERS+=" /p:SignAssembly=true"
	PARAMETERS+=" /p:AssemblyOriginatorKeyFile=${WORKDIR}/mono.snk"
	PARAMETERS+=" /v:detailed"

	for x in ${USE_DOTNET} ; do
		FW_UPPER=${x:3:1}
		FW_LOWER=${x:4:1}
		PARAMETERS_2=" /p:TargetFrameworkVersion=v${FW_UPPER}.${FW_LOWER}"
		if use debug; then
			CARGS=/p:Configuration=net_${FW_UPPER}_${FW_LOWER}_Debug
		else
			CARGS=/p:Configuration=net_${FW_UPPER}_${FW_LOWER}_Release
		fi
		PARAMETERS_2+=" ${CARGS}"
		exbuild_raw ${PARAMETERS} ${PARAMETERS_2} "${METAFILETOBUILD}"
	done

	# run nuget_pack
	enuspec -Prop "id=${NUSPEC_ID};version=${NUSPEC_VERSION}" ${NUSPEC_FILE}
}

src_install() {
	enupkg "${WORKDIR}/${NUSPEC_ID}.${NUSPEC_VERSION}.nupkg"

	if use debug; then
		DIR=Debug
	else
		DIR=Release
	fi

	for x in ${USE_DOTNET} ; do
		FW_UPPER=${x:3:1}
		FW_LOWER=${x:4:1}
		egacinstall "bin/net_${FW_UPPER}_${FW_LOWER}_${DIR}/${GAC_DLL_NAME}.dll"
	done

	install_pc_file
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
