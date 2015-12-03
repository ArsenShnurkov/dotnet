# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=5
inherit nupkg

NAME="slntools"
HOMEPAGE="https://github.com/ArsenShnurkov/${NAME}"

EGIT_COMMIT="a2843a3c3b0e3ae6b88582fccd1bd55c92299285"
SRC_URI="${HOMEPAGE}/archive/${EGIT_COMMIT}.zip -> ${PF}.zip"
S="${WORKDIR}/${NAME}-${EGIT_COMMIT}"

SLOT=0

DESCRIPTION="C# library to work with solution and project files"
LICENSE="MIT" # https://github.com/ArsenShnurkov/slntools/blob/master/LICENSE
KEYWORDS="~amd64 ~x86"
IUSE="net45 developer nupkg debug"
USE_DOTNET="net45"

RDEPEND=">=dev-lang/mono-4.0.2.5"
DEPEND="${RDEPEND}
	sys-apps/sed"

S="${WORKDIR}/${NAME}-${EGIT_COMMIT}"
SLN_FILE=SLNTools.sln
METAFILETOBUILD="${S}/Main/${SLN_FILE}"

src_prepare() {
	default

	epatch "${FILESDIR}/remove-wix-project-from-sln-file-v2.patch"

	# System.EntryPointNotFoundException: GetStdHandle
	#   at (wrapper managed-to-native) CWDev.SLNTools.CommandLine.Parser:GetStdHandle (int)
	#   at CWDev.SLNTools.CommandLine.Parser.GetConsoleWindowWidth () [0x00000] in <filename unknown>:0 
	#   at CWDev.SLNTools.CommandLine.Parser.ArgumentsUsage (System.Type argumentType) [0x00000] in <filename unknown>:0 
	#   at CWDev.SLNTools.Program.Main (System.String[] args) [0x00000] in <filename unknown>:0 
	# http://stackoverflow.com/questions/23824961/c-sharp-to-mono-getconsolewindow-exception
	epatch "${FILESDIR}/console-window-width.patch"

	nuget restore "${METAFILETOBUILD}" || die
}

src_compile() {
	ARGS=""
	ARGSN=""

	if use debug; then
		ARGS="${ARGS} /p:Configuration=Debug"
		ARGSN="${ARGSN} Configuration=Debug"
	else
		ARGS="${ARGS} /p:Configuration=Release"
		ARGSN="${ARGSN} Configuration=Release"
	fi

	if use developer; then
		ARGS="${ARGS} /p:DebugSymbols=True"
	else
		ARGS="${ARGS} /p:DebugSymbols=False"
	fi

	exbuild ${ARGS} ${METAFILETOBUILD}

	if use nupkg; then
		nuget pack "${FILESDIR}/${SLN_FILE}.nuspec" -Properties ${ARGSN} -BasePath "${S}" -OutputDirectory "${WORKDIR}" -NonInteractive -Verbosity detailed
	fi
}

src_install() {
	default

	DIR=""
	if use debug; then
		DIR="Debug"
	else
		DIR="Release"
	fi

	# insinto "/usr/$(get_libdir)"	
	insinto "/usr/share/slntools/"

	# || die is not necessary after doins,
	# see examples at https://devmanual.gentoo.org/ebuild-writing/functions/src_install/index.html
	doins Main/SLNTools.exe/bin/${DIR}/CWDev.SLNTools.Core.dll
	doins Main/SLNTools.exe/bin/${DIR}/CWDev.SLNTools.Core.dll.mdb
	doins Main/SLNTools.exe/bin/${DIR}/CWDev.SLNTools.UIKit.dll
	doins Main/SLNTools.exe/bin/${DIR}/CWDev.SLNTools.UIKit.dll.mdb
	doins Main/SLNTools.exe/bin/${DIR}/SLNTools.exe
	doins Main/SLNTools.exe/bin/${DIR}/SLNTools.exe.mdb

	make_wrapper slntools "mono /usr/share/slntools/SLNTools.exe"

	if use nupkg; then
		if [ -d "/var/calculate/remote/distfiles" ]; then
			# Control will enter here if the directory exist.
			# this is necessary to handle calculate linux profiles feature (for corporate users)
			elog "Installing .nupkg into /var/calculate/remote/packages/NuGet"
			insinto /var/calculate/remote/packages/NuGet
		else
			# this is for all normal gentoo-based distributions
			elog "Installing .nupkg into /usr/local/nuget/nupkg"
			insinto /usr/local/nuget/nupkg
		fi
		doins "${WORKDIR}/SLNTools.1.1.3.nupkg"
	fi
}

# Usage:
# SLNTools.exe 
# @<file>    Read response file for more options
# <Command>  Command Name (CompareSolutions|MergeSolutions|CreateFilterFileFromSolution|EditFilterFile|OpenFilterFile|SortProjects)
