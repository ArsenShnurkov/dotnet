# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=5
inherit mono-env nuget dotnet

NAME="xunit"
HOMEPAGE="https://github.com/xunit/${NAME}"

EGIT_COMMIT="b1cbc40158cc53be5b9150bcdeb2e1cae40db5c9"
SRC_URI="${HOMEPAGE}/archive/${EGIT_COMMIT}.zip -> ${PF}.zip"
S="${WORKDIR}/${NAME}-${EGIT_COMMIT}"

SLOT="0"

DESCRIPTION="xUnit.net is a free, open source, community-focused unit testing tool for the .NET Framework."
LICENSE="Apache-2.0" # https://github.com/xunit/xunit/blob/master/license.txt
KEYWORDS="~amd64 ~ppc ~x86"
USE_DOTNET="net40 net45"
IUSE="${USE_DOTNET} developer debug nupkg doc"

COMMON_DEPENDENCIES=">=dev-lang/mono-4.0.2.5
"

RDEPEND="${COMMON_DEPENDENCIES}
	>=dev-lang/mono-4.0.2.5
"
DEPEND="${COMMON_DEPENDENCIES}
	dev-dotnet/nuget
	dev-dotnet/nant[nupkg]
"

S="${WORKDIR}/${NAME}-${EGIT_COMMIT}"
FILE_TO_BUILD=xunit.xbuild.sln
METAFILETOBUILD="${S}/${FILE_TO_BUILD}"

src_prepare() {
	enuget_restore "${METAFILETOBUILD}"
}

src_compile() {
	exbuild "${METAFILETOBUILD}"
	enuspec "${FILESDIR}/${PN}.nuspec"
}

src_install() {
	DIR=""
	if use debug; then
		DIR="Debug"
	else
		DIR="Release"
	fi

	FINALDIR="/usr/share/xunit/"
	insinto "${FINALDIR}"
	doins bin/${DIR}/*.{config,dll,exe}
	if use developer; then
		doins bin/${DIR}/*.mdb
	fi

	make_wrapper nunit "mono ${FINALDIR}/xunit.exe"

	if use doc; then
		doins license.txt readme.md
	fi

	enupkg "${WORKDIR}/xUnit.2.1.nupkg"
}
