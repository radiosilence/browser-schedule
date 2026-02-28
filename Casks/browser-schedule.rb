cask "browser-schedule" do
  version :latest
  sha256 :no_check

  url "https://github.com/radiosilence/browser-schedule/releases/latest/download/BrowserSchedule.dmg"
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
