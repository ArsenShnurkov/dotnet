# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI="5"

GTK_SHARP_REQUIRED_VERSION="2.12.23"

inherit gtk-sharp-module

SLOT="2"
KEYWORDS="~amd64 ~ppc ~x86 ~x86-fbsd"
SRC_URI="https://github.com/mono/gtk-sharp/archive/2.12.23.tar.gz"
S=${WORKDIR}/gtk-sharp-2.12.23

RESTRICT="test"
