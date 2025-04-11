# Maintainer: Hildigerr Vergaray <Maintainer at YmirSystems dot com>

pkgname=xdg-launcher
pkgver=1.6
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
  '28bf41481ea71b561da18b8d02e3465ad6b1f9af7369d79ae4e77c813f6f15b8'
  'f1a4f92c47d04c167cf1fa14da2638c80bd38885468ed36a21e07fdfa0cb2167'
)

package() {
  install -Dm755 "${srcdir}/xdg-launch.sh" "${pkgdir}/usr/bin/xdg-launch"
  install -Dm644 "${srcdir}/xdg-launch.1" "${pkgdir}/usr/share/man/man1/xdg-launch.1"
}

