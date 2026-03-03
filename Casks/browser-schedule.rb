cask "browser-schedule" do
  version "1.3.1"
  sha256 "3398719033275780e046c617ea743a0780990b89fcc1e228ce7b40445a5322a5"

  url "https://github.com/radiosilence/browser-schedule/releases/download/v#{version}/BrowserSchedule.dmg"
  name "BrowserSchedule"
  desc "Automatic browser switching based on time, day, and URL patterns"
  homepage "https://github.com/radiosilence/browser-schedule"

  depends_on macos: ">= :sonoma"

  app "BrowserSchedule.app"

  postflight do
    system_command "/usr/bin/xattr",
                   args: ["-cr", "#{appdir}/BrowserSchedule.app"]
  end

  uninstall_postflight do
    system_command "/usr/bin/open",
                   args: ["x-apple.systempreferences:com.apple.preference.dock"]
  end

  zap trash: [
    "~/.config/browser-schedule",
  ]
end
