# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=6

KEYWORDS="~amd64 ~ppc ~x86"
RESTRICT="mirror"

SLOT="4"

USE_DOTNET="net45"

inherit msbuild gac

IUSE="+${USE_DOTNET} debug developer doc"

HOMEPAGE="https://github.com/autofac/Autofac"
SRC_URI="https://github.com/autofac/Autofac/archive/v4.1.1.tar.gz -> ${PN}-${PV}.tar.gz
	https://github.com/mono/mono/raw/master/mcs/class/mono.snk"

S="${WORKDIR}/Autofac-${PV}"

DESCRIPTION="An addictive .NET IoC container"
LICENSE="MIT" # https://github.com/autofac/Autofac/blob/develop/LICENSE

COMMON_DEPEND=">=dev-lang/mono-5.4.0.167 <dev-lang/mono-9999
"
RDEPEND="${COMMON_DEPEND}
"
DEPEND="${COMMON_DEPEND}
"

PROJECT_DIR="src/Autofac"
PROJECT_FILE=Autofac
ASSEMBLY_NAME=Autofac

KEY2="${DISTDIR}/mono.snk"
ASSEMBLY_VERSION="${PV}"

function output_filename ( ) {
	local DIR=""
	if use debug; then
		DIR="Debug"
	else
		DIR="Release"
	fi
	echo "${S}/${PROJECT_DIR}/bin/${DIR}/${ASSEMBLY_NAME}.dll"
}

src_prepare() {
	cp "${FILESDIR}/${PROJECT_FILE}-${PV}.csproj" "${S}/${PROJECT_DIR}/${PROJECT_FILE}.csproj" || die
	# create version info files
	cat <<-METADATA >"${S}/${PROJECT_DIR}/Properties/AssemblyVersion.cs" || die
		[assembly: System.Reflection.AssemblyVersion("4.1.1")]
	METADATA
	eapply_user
}

src_compile() {
	emsbuild "/p:SignAssembly=true" "/p:PublicSign=true" "/p:AssemblyOriginatorKeyFile=${KEY2}" "${PROJECT_DIR}/${PROJECT_FILE}.csproj"
	sn -R "$(output_filename)" "${KEY2}" || die
}

src_install() {
	insinto "/gac"
	doins "$(output_filename)"
}

pkg_preinst()
{
	echo mv "${D}/gac/${ASSEMBLY_NAME}.dll" "${T}/${ASSEMBLY_NAME}.dll"
	mv "${D}/gac/${ASSEMBLY_NAME}.dll" "${T}/${ASSEMBLY_NAME}.dll" || die
	echo rm -rf "${D}/gac"
	rm -rf "${D}/gac" || die
}

pkg_postinst()
{
	egacadd "${T}/${ASSEMBLY_NAME}.dll"
	rm "${T}/${ASSEMBLY_NAME}.dll" || die
}

pkg_prerm()
{
	egacdel "${ASSEMBLY_NAME}, Version=${ASSEMBLY_VERSION}, Culture=neutral, PublicKeyToken=0738eb9f132ed756"
}
