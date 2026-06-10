cask "vigil" do
  version "1.0.0"
  sha256 "f1f637e23d5da544313dde69372a3245e22dec2ee1bb4be0734aa981cde70971"

  url "https://github.com/ussumant/vigil/releases/download/v#{version}/Vigil-#{version}.dmg"
  name "Vigil"
  desc "Menu-bar wakelock for macOS"
  homepage "https://github.com/ussumant/vigil"

  app "Vigil.app"
end
