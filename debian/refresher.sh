# call as: debian/rules debian/refresh

set -e
set -o pipefail
cd "$(dirname "$0")/.."
qrc=$PWD/debian/refresher.rc
arch=amd64
q() { quilt --quiltrc "$qrc" "$@"; }

set -x
for action in "$@"; do
	case $action {
	(:)
		fakeroot debian/rules DEB_HOST_ARCH=$arch clean
		;;
	(.)
		rm stamps/series
		;;
	(*)
		arch=$action
		debian/rules DEB_HOST_ARCH=$arch stamps/series
		cd src
		while q push; do
			q refresh
		done
		q pop -a
		cd ..
		;;
	}
done
