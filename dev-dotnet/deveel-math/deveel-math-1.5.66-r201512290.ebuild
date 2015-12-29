# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=5

inherit versionator dotnet nupkg

HOMEPAGE="https://github.com/deveel/deveel-math/"
DESCRIPTION="A library for handling big numbers and decimals under Mono/.NET frameworks"
LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="~amd64 ~x86"
# debug = debug configuration (symbols and defines for debugging)
# developer = generate symbols information (to view line numbers in stack traces, either in debug or release configuration)
# test = allow NUnit tests to run
# nupkg = create .nupkg file from .nuspec
# gac = install into gac
# pkg-config = register in pkg-config database
IUSE="net45 debug developer test +nupkg +gac +pkg-config"
USE_DOTNET="net45"

COMMON_DEPEND=">=dev-lang/mono-4.0.2.5
"

RDEPEND="${COMMON_DEPEND}
"

DEPEND="${COMMON_DEPEND}
	test? ( dev-dotnet/nunit:2[nupkg] )
	virtual/pkgconfig
"

NAME="deveel-math"
REPOSITORY_NAME="ArsenShnurkov/${NAME}"
REPOSITORY_URL="https://github.com/${REPOSITORY_NAME}"
EGIT_BRANCH="portage-packaging"
EGIT_COMMIT="4635fb321ac931d0b381547d06ca6625a57ea343"

# PV 	Package version (excluding revision, if any), for example 6.3
# PF 	Full package name, ${PN}-${PVR}, for example vim-6.3-r1
#SRC_URI="${REPOSITORY_URL}/archive/dmath-${PV}.tar.gz -> ${PF}.tar.gz
SRC_URI="${REPOSITORY_URL}/archive/${EGIT_BRANCH}/${EGIT_COMMIT}.zip -> ${PF}.zip
	mirror://gentoo/mono.snk.bz2"
#S="${WORKDIR}/dmath-${PV}"
S="${WORKDIR}/${NAME}-${EGIT_BRANCH}"

METAFILETOBUILD=src/Deveel.Math.sln

#NUSPEC_FILE_NAME=nuget/dmath.tmpl.nuspec
NUSPEC_FILE_NAME=nuget/dmath.noplatform.tmpl.nuspec

# PVR 	Package version and revision (if any), for example 6.3, 6.3-r1
# for 4-parts version this will not work properly:
#NUSPEC_VERSION="${PVR//-r/.}"
# that is why we use "inherit versionator"
#if revision matches the tag exactly, we can omit revision:
#NUSPEC_VERSION=$(get_version_component_range 1-3)
# The same version of package can be build from later commits, then we append revision:
# PR 	Package revision, or r0 if no revision exists.
NUSPEC_VERSION=$(get_version_component_range 1-3)"${PR//r/.}"

ICON_URL="https://raw.githubusercontent.com/ArsenShnurkov/dotnet/master/dev-dotnet/deveel-math/files/Deveel.Math.png"

# rm -rf /var/tmp/portage/dev-dotnet/deveel-math-*
# emerge =deveel-math-1.5.66-r201507280
# leafpad /var/tmp/portage/dev-dotnet/deveel-math-1.5.66-r201507280/temp/build.log &

src_unpack()
{
	default
	rm ${S}/src/.nuget/NuGet.exe || die
}

src_prepare() {
	# /var/tmp/portage/dev-dotnet/deveel-math-1.5.66-r201512290/work/deveel-math-portage-packaging
	einfo "patching project files"
	epatch "${FILESDIR}/Deveel.Math.csproj.patch"
	epatch "${FILESDIR}/Deveel.Math.sln.patch"
	if ! use test ; then
		epatch "${FILESDIR}/Deveel.Math.sln.test.patch"
	fi

	einfo "restoring packages (NUnit)"
	enuget_restore "${METAFILETOBUILD}"

	patch_nuspec_file "${S}/${NUSPEC_FILE_NAME}"
}

src_configure() {
	:;
}

#PLATFORM="mono4"

src_compile() {
	exbuild /p:SignAssembly=true "/p:AssemblyOriginatorKeyFile=${WORKDIR}/mono.snk" "${METAFILETOBUILD}"

	# run nuget_pack
	einfo "setting .nupkg version to ${NUSPEC_VERSION}"
	enuspec -Prop "version=${NUSPEC_VERSION};package_iconUrl=${ICON_URL}" "${S}/${NUSPEC_FILE_NAME}"
}

src_test() {
	default
}

src_install() {
	enupkg "${WORKDIR}/dmath.${NUSPEC_VERSION}.nupkg"

	egacinstall "src/Deveel.Math/bin/AnyCPU/${DIR}/Deveel.Math.dll"

	install_pc_file
}

patch_nuspec_file()
{
	if use nupkg; then
		if use debug; then
			DIR="Debug"
FILES_STRING=`cat <<-EOF || die "${DIR} files at patch_nuspec_file()"
	<files> <!-- https://docs.nuget.org/create/nuspec-reference -->
		<file src="src/Deveel.Math/bin/AnyCPU/${DIR}/Deveel.Math.dll" target="lib\net45\" />
		<file src="src/Deveel.Math/bin/AnyCPU/${DIR}/Deveel.Math.dll.mdb" target="lib\net45\" />
	</files>
EOF
`
	else
		DIR="Release"
FILES_STRING=`cat <<-EOF || die "${DIR} files at patch_nuspec_file()"
	<files> <!-- https://docs.nuget.org/create/nuspec-reference -->
		<file src="src/Deveel.Math/bin/AnyCPU/${DIR}/Deveel.Math.dll" target="lib\net45\" />
	</files>
EOF
`
		fi

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
			-e 's*@LIBS@*-r:${libdir}'"/mono/${PC_FILE_NAME}/DeveelMath.dll"'*' \
			<<\EOF >"${D}/usr/$(get_libdir)/pkgconfig/${PC_FILE_NAME}.pc" || die
prefix=${pcfiledir}/../..
exec_prefix=${prefix}
libdir=${exec_prefix}/@LIBDIR@

Name: @PACKAGENAME@
Description: @DESCRIPTION@
Version: @VERSION@
Libs: @LIBS@
EOF

		einfo PKG_CONFIG_PATH="${D}/usr/$(get_libdir)/pkgconfig/" pkg-config --exists "${PC_FILE_NAME}"
		PKG_CONFIG_PATH="${D}/usr/$(get_libdir)/pkgconfig/" pkg-config --exists "${PC_FILE_NAME}" || die ".pc file failed to validate."
		eend $?
	fi
}