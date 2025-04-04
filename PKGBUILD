# Maintainer: Hildigerr Vergaray <Maintainer at YmirSystems dot com>

pkgname=xdg-launcher
pkgver=1.0
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
  'bbd0b8c8e8795f9b1f1e7d131aad9d349e4f44867b7424470ce15a98e9315486'
  'a706889c5106a96c546116fd2a415940ccdc7d4733e4504246a2fc675d25b0d7'
)

package() {
  install -Dm755 "${srcdir}/xdg-launch.sh" "${pkgdir}/usr/bin/xdg-launch"
  install -Dm644 "${srcdir}/xdg-launch.1" "${pkgdir}/usr/share/man/man1/xdg-launch.1"
}

