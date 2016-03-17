# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=6
AUTOTOOLS_PRUNE_LIBTOOL_FILES="all"
AUTOTOOLS_AUTORECONF=1

inherit eutils linux-info mono-env flag-o-matic pax-utils versionator

DESCRIPTION="Mono runtime and class libraries, a C# compiler/interpreter"

GITHUBNAME="mono/mono"
EGIT_BRANCH="master"
EGIT_COMMIT="3736375ac24304ac7aa49c05df84572f5224b8d1"
# how to get parts of string with bash - http://stackoverflow.com/a/10638555/6017919
GITHUBACC=${GITHUBNAME%/*}
GITHUBREPO=${GITHUBNAME#*/}
# http://stackoverflow.com/questions/8377081/github-api-download-zip-or-tarball-link
# https://developer.github.com/v3/repos/contents/#get-archive-link
# GET /repos/:owner/:repo/:archive_format/:ref
# archive_format 	string 	Can be either tarball or zipball. Default: tarball
# ref 	string 	A valid Git reference. Default: the repository’s default branch (usually master)
GITFILENAME=${GITHUBREPO}-${GITHUBACC}-${PV}-${EGIT_COMMIT}
SRC_URI="https://api.github.com/repos/${GITHUBACC}/${GITHUBREPO}/zipball/${EGIT_COMMIT} -> ${GITFILENAME}.zip"
# http://stackoverflow.com/a/27658733/6017919
# GITFOLDERNAME=${GITHUBREPO}-${GITHUBACC}-${EGIT_COMMIT::-33}
S="${WORKDIR}/${GITFILENAME}"

HOMEPAGE="http://www.mono-project.com/Main_Page"

LICENSE="MIT LGPL-2.1 GPL-2 BSD-4 NPL-1.1 Ms-PL GPL-2-with-linking-exception IDPL"
SLOT="0"

KEYWORDS="~amd64 ~ppc ~ppc64 ~x86 ~amd64-linux"

IUSE="nls minimal pax_kernel xen doc +gdiplus +debug +developer"

COMMONDEPEND="
	gdiplus? ( >=dev-dotnet/libgdiplus-2.10 )
	ia64? ( sys-libs/libunwind )
	nls? ( sys-devel/gettext )
"
RDEPEND="${COMMONDEPEND}
	|| ( www-client/links www-client/lynx )
"
DEPEND="${COMMONDEPEND}
	sys-devel/bc
	virtual/yacc
	pax_kernel? ( sys-apps/elfix )
	!dev-lang/mono-basic
"

MAKEOPTS="${MAKEOPTS} -j1" #nowarn

pkg_pretend() {
	# https://github.com/gentoo/gentoo/blob/f200e625bda8de696a28338318c9005b69e34710/eclass/linux-info.eclass#L686
	# If CONFIG_SYSVIPC is not set in your kernel .config, mono will hang while compiling.
	# See http://bugs.gentoo.org/261869 for more info."
	CONFIG_CHECK="SYSVIPC"
	use kernel_linux && check_extra_config
}

pkg_setup() {
	linux-info_pkg_setup
	mono-env_pkg_setup
}

src_unpack() {
	default_src_unpack

	# http://stackoverflow.com/questions/16072306/how-can-i-modify-the-folder-name-inside-the-zip-downloaded-from-my-github-repo
	mv "${WORKDIR}/"* "${WORKDIR}/${GITFILENAME}" || die
	cd "${WORKDIR}/${GITFILENAME}" || die

	# *** No rule to make target '../../external/ikvm/reflect/*.cs', needed by '../class/lib/basic/basic.exe'.  Stop.
	# http://stackoverflow.com/questions/13852153
	# git submodule init || die
	# git submodule update || die
	# fatal: Not a git repository (or any of the parent directories): .git
}

src_prepare() {
	# https://forums.gentoo.org/viewtopic-t-923884-view-previous.html
	./autogen.sh || die "autogen failed" 
	#eautoreconf - doesn't work

	# we need to sed in the paxctl-ng -mr in the runtime/mono-wrapper.in so it don't
	# get killed in the build proces when MPROTECT is enable. #286280
	# RANDMMAP kill the build proces to #347365
	# use paxmark.sh to get PT/XT logic #532244
	if use pax_kernel ; then
		ewarn "We are disabling MPROTECT on the mono binary."

		# issue 9 : https://github.com/Heather/gentoo-dotnet/issues/9
		sed '/exec "/ i\paxmark.sh -mr "$r/@mono_runtime@"' -i "${S}"/runtime/mono-wrapper.in || die "Failed to sed mono-wrapper.in"
	fi

	# mono build system can fail otherwise
	strip-flags


	# Fix VB targets
	# http://osdir.com/ml/general/2015-05/msg20808.html
	#eapply "${FILESDIR}/add_missing_vb_portable_targets.patch"

	# Fix build when sgen disabled
	# https://bugzilla.xamarin.com/show_bug.cgi?id=32015
	#eapply "${FILESDIR}/${PN}-4.0.2.5-fix-mono-dis-makefile-am-when-without-sgen.patch"

	# TODO: update patch
	# Fix atomic_add_i4 support for 32-bit ppc
	# https://github.com/mono/mono/compare/f967c79926900343f399c75624deedaba460e544^...8f379f0c8f98493180b508b9e68b9aa76c0c5bdf
	#epatch "${FILESDIR}/${PN}-4.0.2.5-fix-ppc-atomic-add-i4.patch"

	# TODO: update patch
	#epatch "${FILESDIR}/systemweb3.patch"
	#epatch "${FILESDIR}/fix-for-GitExtensions-issue-2710-another-resolution.patch"
	#epatch "${FILESDIR}/fix-for-bug36724.patch"

	default_src_prepare
	#eapply_user
}

src_configure() {
	local myeconfargs=(
		--disable-silent-rules
		$(use_with xen xen_opt)
		--without-ikvm-native
		--disable-dtrace
		$(use_with doc mcs-docs)
		$(use_enable nls)
	)

	# default_src_configure
	./configure ${myeconfargs} || die
}

src_compile() {
	default_src_compile
}

src_test() {
	cd mcs/tests || die
	emake check
}

src_install() {
	default_src_install

	# Remove files not respecting LDFLAGS and that we are not supposed to provide, see Fedora
	# mono.spec and http://www.mail-archive.com/mono-devel-list@lists.ximian.com/msg24870.html
	# for reference.
	rm -f "${ED}"/usr/lib/mono/{2.0,4.5}/mscorlib.dll.so || die
	rm -f "${ED}"/usr/lib/mono/{2.0,4.5}/mcs.exe.so || die
}
