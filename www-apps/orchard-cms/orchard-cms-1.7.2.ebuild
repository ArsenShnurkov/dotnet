# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=6
KEYWORDS="~amd64 ~x86"

USE_DOTNET="net45"
inherit dotnet

IUSE="vhosts"

# NAME is used in 2 places - github repository name, and directory name inside the downloaded archive
NAME=Orchard
EGIT_REF="7dff22a47864b794a28ae3f05b939c7ac7b98e93"
HOMEPAGE="https://github.com/OrchardCMS/${NAME}"
SRC_URI="${HOMEPAGE}/archive/${EGIT_REF}.zip -> ${PF}.zip"
S="${WORKDIR}/${NAME}-${EGIT_REF}"
RESTRICT="mirror"
LICENSE="BSD"
DESCRIPTION="CMS written with CSharp"

SLOT="1.7.2"

CDEPEND="
	www-apache/mod_mono
	>=dev-dotnet/system-web-4.6.0.182-r1
"
DEPEND="${CDEPEND}"
RDEPEND="${CDEPEND}"

src_prepare() {
	epatch "${FILESDIR}/case-of-path-letters.patch"
	epatch "${FILESDIR}/add-reference-to-system-data.patch"
	epatch "${FILESDIR}/web-config.patch"
	eapply_user
}

src_compile() {
	exbuild "${S}/src/Orchard.sln"
}

src_install() {
	# see https://wiki.gentoo.org/wiki/GLEP:11#Installation_Paths
	dodir /usr/share/webapps/${PF}/htdocs/
	#insinto /usr/share/webapps/${PF}/htdocs/
	# http://askubuntu.com/questions/86822/how-can-i-copy-the-contents-of-a-folder-to-another-folder-in-a-different-directo
	cp -a "${S}/src/Orchard.Web/." "${D}/usr/share/webapps/${PF}/htdocs/" || die
}
