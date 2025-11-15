_: {
  programs.firefox.profiles.yash.settings = {
    "browser.discovery.enabled" = false;
    "browser.fullscreen.exit_on_escape" = false;
    "browser.safebrowsing.downloads.remote.block_dangerous" = false;
    "browser.safebrowsing.downloads.remote.block_dangerous_host" = false;
    "browser.safebrowsing.downloads.remote.block_potentially_unwanted" = false;
    "browser.safebrowsing.downloads.remote.block_uncommon" = false;
    "browser.safebrowsing.downloads.remote.url" = false;
    "browser.safebrowsing.downloads.remote.enabled" = false;
    "browser.safebrowsing.downloads.enabled" = false;
    "browser.toolbars.keyboard_navigation" = false;
    "browser.translations.automaticallyPopup" = false;

    # Disable AI features
    "browser.ml.enable" = false;
    "browser.ml.chat.enabled" = false;
    "browser.ml.chat.menu" = false;
    "browser.ml.chat.page" = false;
    "browser.ml.chat.page.footerBadge" = false;
    "browser.ml.chat.page.menuBadge" = false;
    "browser.ml.chat.shortcuts" = false;
    "browser.ml.chat.sidebar" = false;
    "browser.ml.pageAssist.enabled" = false;
    "extensions.ml.enabled" = false;
    "browser.tabs.groups.smart.enabled" = false;
    "browser.tabs.groups.smart.userEnable" = false;

    # Reduce search engine noise in the urlbar's completion window
    "browser.urlbar.suggest.searches" = false;
    "browser.urlbar.shortcuts.bookmarks" = false;
    "browser.urlbar.shortcuts.history" = false;
    "browser.urlbar.shortcuts.tabs" = false;
    "browser.urlbar.suggest.quicksuggest.sponsored" = false;
    "browser.urlbar.showSearchSuggestionsFirst" = false;
    "browser.urlbar.speculativeConnect.enabled" = false;

    # Disable crash reports
    "breakpad.reportURL" = "";
    "browser.tabs.crashReporting.sendReport" = false;
    "browser.crashReports.unsubmittedCheck.autoSubmit2" = false;

    # Disable Form autofill
    # https://wiki.mozilla.org/Firefox/Features/Form_Autofill
    "browser.formfill.enable" = false;
    "extensions.formautofill.addresses.enabled" = false;
    "extensions.formautofill.available" = "off";
    "extensions.formautofill.creditCards.available" = false;
    "extensions.formautofill.creditCards.enabled" = false;
    "extensions.formautofill.heuristics.enabled" = false;

    "datareporting.healthreport.service.enabled" = false;
    "font.name.monospace.x-western" = "IosevkaTerm Nerd Font Mono";
    "reader.parse-on-load.enabled" = false;
    "svg.context-properties.content.enabled" = true;
    "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
    "toolkit.telemetry.enabled" = false;
    "toolkit.telemetry.unified" = false;
  };
}
