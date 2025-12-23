#!/bin/bash

# Variables from Makefile
VERSION=6.0.0
PN=anything-sync-daemon
PREFIX=${PREFIX:-/usr}
CONFDIR=/etc
CRONDIR=/etc/cron.hourly
INITDIR_SYSTEMD=/usr/lib/systemd/system
INITDIR_UPSTART=/etc/init.d
BINDIR=${PREFIX}/bin
DOCDIR=${PREFIX}/share/doc/${PN}
MANDIR=${PREFIX}/share/man/man1
ZSHDIR=${PREFIX}/share/zsh/site-functions
BSHDIR=${PREFIX}/share/bash-completion/completions
COMPRESS_MAN=1

# Functions
create_main_script() {
    sed 's/@VERSION@/'${VERSION}'/' common/${PN}.in > common/${PN}
}

stop_asd() {
    if [ "$PREFIX" != "/usr" ]; then
        sudo -E asd unsync
    fi
}

disable_systemd() {
    if [ "$PREFIX" = "/usr" ]; then
        systemctl stop asd asd-resync || true
    fi
}

install_bin() {
    stop_asd
    disable_systemd
    create_main_script
    echo -e '\033[1;32mInstalling main script...\033[0m'
    install -d "${DESTDIR}${BINDIR}"
    install -m755 common/${PN} "${DESTDIR}${BINDIR}/${PN}"
    ln -sf ${PN} "${DESTDIR}${BINDIR}/asd"
    cp -n common/asd.conf "${DESTDIR}${CONFDIR}/asd.conf"
    install -d "${DESTDIR}${ZSHDIR}"
    install -m644 common/zsh-completion "${DESTDIR}${ZSHDIR}/_asd"
    install -d "${DESTDIR}${BSHDIR}"
    install -m644 common/bash-completion "${DESTDIR}${BSHDIR}/asd"
}

install_man() {
    echo -e '\033[1;32mInstalling manpage...\033[0m'
    install -d "${DESTDIR}${MANDIR}"
    install -m644 doc/asd.1 "${DESTDIR}${MANDIR}/asd.1"
    if [ "$COMPRESS_MAN" != "0" ]; then
        gzip -9 "${DESTDIR}${MANDIR}/asd.1"
        ln -sf asd.1.gz "${DESTDIR}${MANDIR}/${PN}.1.gz"
    else
        ln -sf asd.1 "${DESTDIR}${MANDIR}/${PN}.1"
    fi
}

install_systemd() {
    echo -e '\033[1;32mInstalling systemd files...\033[0m'
    install -d "${DESTDIR}${CONFDIR}"
    install -d "${DESTDIR}${INITDIR_SYSTEMD}"
    install -m644 init/asd.service "${DESTDIR}${INITDIR_SYSTEMD}/asd.service"
    install -m644 init/asd-resync.service "${DESTDIR}${INITDIR_SYSTEMD}/asd-resync.service"
    install -m644 init/asd-resync.timer "${DESTDIR}${INITDIR_SYSTEMD}/asd-resync.timer"
}

install_systemd_all() {
    install_bin
    install_man
    install_systemd
}

# Main
case "$1" in
    install-systemd-all)
        install_systemd_all
        ;;
    *)
        echo "Usage: $0 {install-systemd-all}"
        exit 1
        ;;
esac
