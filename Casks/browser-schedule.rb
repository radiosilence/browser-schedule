cask "browser-schedule" do
  version "1.0.0"
  sha256 :no_check

  url "https://github.com/radiosilence/browser-schedule/releases/latest/download/BrowserSchedule.dmg"
  name "BrowserSchedule"
  desc "Automatic browser switching based on time, day, and URL patterns"
  homepage "https://github.com/radiosilence/browser-schedule"

  livecheck do
    url :url
    strategy :github_latest
  end

  app "BrowserSchedule.app"

  postflight do
    system_command "#{appdir}/BrowserSchedule.app/Contents/MacOS/browser-schedule",
                   args: ["--set-default"],
                   sudo: false
  end

  uninstall_postflight do
    system_command "/usr/bin/open",
                   args: ["x-apple.systempreferences:com.apple.preference.dock"]
  end

  zap trash: [
    "~/.config/browser-schedule",
  ]
end