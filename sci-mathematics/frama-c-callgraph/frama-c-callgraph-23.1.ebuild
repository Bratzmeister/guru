# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit autotools findlib toolchain-funcs

DESCRIPTION="Callgraph plugin for frama-c"
HOMEPAGE="https://frama-c.com"
NAME="Vanadium"
SRC_URI="https://frama-c.com/download/frama-c-${PV}-${NAME}.tar.gz"

LICENSE="LGPL-2.1"
SLOT="0"
KEYWORDS="~amd64"
IUSE="gtk +ocamlopt"
RESTRICT="strip"

RDEPEND="~sci-mathematics/frama-c-${PV}:=[gtk?,ocamlopt?]"
DEPEND="${RDEPEND}"
# Eva is needed at runtime to run the callgraph plugin,
# but is not needed for compilation (and would introduce a mutual dependency)
PDEPEND="~sci-mathematics/frama-c-eva-${PV}:=[ocamlopt?]"

S="${WORKDIR}/frama-c-${PV}-${NAME}"

src_prepare() {
	mv configure.in configure.ac || die
	sed -i 's/configure\.in/configure.ac/g' Makefile.generating Makefile || die
	touch config_file || die
	eautoreconf
	eapply_user
}

src_configure() {
	econf \
		--disable-landmarks \
		--with-no-plugin \
		$(use_enable gtk gui) \
		--enable-callgraph
	printf 'include share/Makefile.config\n' > src/plugins/callgraph/Makefile || die
	sed -e '/^# *Callgraph/bl;d' -e ':l' -e '/^\$(eval/Q;n;bl' < Makefile >> src/plugins/callgraph/Makefile || die
	printf 'include share/Makefile.dynamic\n' >> src/plugins/callgraph/Makefile || die
	export FRAMAC_SHARE="${ESYSROOT}/usr/share/frama-c"
	export FRAMAC_LIBDIR="${EPREFIX}/usr/$(get_libdir)/frama-c"
	export HAS_DGRAPH=$(usex gtk yes no)
}

src_compile() {
	tc-export AR
	use gtk && emake src/plugins/callgraph/cg_viewer.ml
	emake -f src/plugins/callgraph/Makefile FRAMAC_SHARE="${FRAMAC_SHARE}" FRAMAC_LIBDIR="${FRAMAC_LIBDIR}" HAS_DGRAPH="${HAS_DGRAPH}"
}

src_install() {
	emake -f src/plugins/callgraph/Makefile FRAMAC_SHARE="${FRAMAC_SHARE}" FRAMAC_LIBDIR="${FRAMAC_LIBDIR}" HAS_DGRAPH="${HAS_DGRAPH}" DESTDIR="${ED}" install
}
