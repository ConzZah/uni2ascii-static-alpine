#!/usr/bin/env sh

### /// uni2ascii-static-alpine.sh // ConzZah ///

doso=""
[ "$(id -u)" = "1000" ] && doso="doas"

$doso apk add build-base

## set $LDFLAGS
export LDFLAGS="-static"
## turns out: if you have gettext installed,
## the following workaround is needed for every arch, not just armv7l,
## BUT: it will grow the executable from 150kb to about 450kb.
## thus, it is conditional.
gt=""
gt="$(apk info| grep 'gettext.*')"
[ -n "$gt" ] && \
export LDFLAGS="-static -Wl,--whole-archive,/usr/lib/libintl.a,--no-whole-archive"


[ ! -f "uni2ascii-4.20.tar.gz" ] && \
wget "https://github.com/ConzZah/uni2ascii-static-alpine/raw/refs/heads/main/uni2ascii-4.20.tar.gz"

[ -f "uni2ascii-4.20.tar.gz" ] && \
[ ! -d "uni2ascii-4.20" ] && \
tar xf "uni2ascii-4.20.tar.gz"

[ -d "uni2ascii-4.20" ] && \
 cd "uni2ascii-4.20" || exit 1

## apply patches to work on musl
## NOTE: $test ensures that we don't apply them multiple times
test="$(sed -n '23p' 'enttbl.c')"
[ "$test" != '#include <string.h>' ] && \
sed -i '23i #include <string.h>' 'enttbl.c'

test="$(sed -n '2693p' 'uni2ascii.c')"
[ "$test" != 'int' ] && \
sed -i '2692i int' 'uni2ascii.c'

test="$(sed -n '2707p' 'uni2ascii.c')"
[ "$test" != 'int' ] && \
sed -i '2706i int' 'uni2ascii.c'

test="$(sed -n '70p' 'uni2ascii.c')"
[ "$test" != 'void putu8(wchar_t c);' ] && \
sed -i '70i void putu8(wchar_t c);' 'uni2ascii.c'

## build
./configure
make clean >/dev/null 2>&1
make || exit 1
strip uni2ascii ascii2uni
$doso make install

## package
tar -czf ../uni2ascii-$(uname -m).tar.gz uni2ascii ascii2uni
