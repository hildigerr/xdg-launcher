# Maintainer: Hildigerr Vergaray <Maintainer at YmirSystems dot com>

pkgname=xdg-launcher
pkgver=1.1
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
  '72f645146e78c1ceb16f3509930bcf49687ef3055e8cee1037e0732b22e13c87'
  '87582c6e0f2fcabecdcb81d86d4a125cf7344b157c54920e6140c1037b1448e7'
)

package() {
  install -Dm755 "${srcdir}/xdg-launch.sh" "${pkgdir}/usr/bin/xdg-launch"
  install -Dm644 "${srcdir}/xdg-launch.1" "${pkgdir}/usr/share/man/man1/xdg-launch.1"
}

