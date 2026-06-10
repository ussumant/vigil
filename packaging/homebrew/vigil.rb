cask "vigil" do
  version "1.0.0"
  sha256 "77a6ebbbba19a32185f7dc6a62a516eac2152ce4ff47cbf52440a4f4fc8e6aaa"

  url "https://github.com/ussumant/vigil/releases/download/v#{version}/Vigil-#{version}.dmg"
  name "Vigil"
  desc "Menu-bar wakelock for macOS"
  homepage "https://github.com/ussumant/vigil"

  app "Vigil.app"
end
