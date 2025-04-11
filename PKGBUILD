# Maintainer: Hildigerr Vergaray <Maintainer at YmirSystems dot com>

pkgname=xdg-launcher
pkgver=1.4
pkgrel=1
pkgdesc="Launcher to enfoce XDG Base Directory compliance for any application."
arch=('any')
url="https://github.com/hildigerr/xdg-launcher"
license=('MIT')
source=(
  'xdg-launch.1'
  'xdg-launch.sh'
)
sha256sums=(
  'e5043da1277e398e191bdf57f7648f42ffb000e05ff3754c9ab7222432b3b215'
  'aff121a1315e6d45d5bbc8ce878201dcee0e49a5745c77fed7601aeaa29f2da3'
)

package() {
  install -Dm755 "${srcdir}/xdg-launch.sh" "${pkgdir}/usr/bin/xdg-launch"
  install -Dm644 "${srcdir}/xdg-launch.1" "${pkgdir}/usr/share/man/man1/xdg-launch.1"
}

