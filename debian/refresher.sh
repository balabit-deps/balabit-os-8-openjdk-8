# call as: debian/rules debian/refresh
# or: dr_overrides='distribution=Ubuntu distrel=focal derivative=Ubuntu' \
#     mksh debian/refresher.sh i386 :

set -e
set -o pipefail
cd "$(dirname "$0")/.."
qrc=$PWD/debian/refresher.rc
arch=amd64
q() { quilt --quiltrc "$qrc" "$@"; }
function qpush {
	set +e
	local rc

	q push "$@"
	rc=$?
	if [[ $rc != [02] ]]; then
		print -ru2 "E: quilt push returned errorlevel $rc"
		print -ru2 "N: use the following command to clean up after inspecting:"
		print -ru2 "N: fakeroot debian/rules${dr_overrides:+ $dr_overrides} DEB_HOST_ARCH=$arch clean"
		exit $rc
	fi
	return $rc
}
typeset -ft q
set +o inherit-xtrace

set -x
for action in "$@"; do
	case $action {
	(:)
		fakeroot debian/rules $dr_overrides DEB_HOST_ARCH=$arch clean
		;;
	(.)
		rm stamps/series
		;;
	(*)
		arch=$action
		debian/rules $dr_overrides DEB_HOST_ARCH=$arch stamps/series
		cd src
		while qpush; do
			q refresh
		done
		q pop -a
		cd ..
		;;
	}
done
exit 0
