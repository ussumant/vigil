cask "vigil" do
  version "1.0.0"
  sha256 "12dea6e0ce2136f4fc920854799dd190644e4f75aa8ed815e920318f0cdab2a0"

  url "https://github.com/ussumant/vigil/releases/download/v#{version}/Vigil-#{version}.dmg"
  name "Vigil"
  desc "Menu-bar wakelock for macOS"
  homepage "https://github.com/ussumant/vigil"

  app "Vigil.app"
end
