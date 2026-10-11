{ ... } : {
    programs.librewolf.profiles.default.settings = {
        "privacy.sanitize.sanitizeOnShutdown" = true;
        "privacy.sanitize.timeSpan" = 0;
        "privacy.history.custom" = true;

        "privacy.clearOnShutdown_v2.cache" = true;
        "privacy.clearOnShutdown_v2.cookiesAndStorage" = true;
        "privacy.clearOnShutdown_v2.historyFormDataAndDownloads" = true;
        "privacy.clearOnShutdown_v2.browsingHistoryAndDownloads" = true;
        "privacy.clearOnShutdown_v2.formdata" = true;
        "privacy.clearOnShutdown_v2.downloads" = true;
        "privacy.clearOnShutdown_v2.siteSettings" = true;

        "signon.rememberSignons" = false;
        "browser.sessionstore.privacy_level" = 2;
        "browser.sessionstore.resume_from_crash" = false;
        "browser.sessionstore.max_resumed_crashes" = 0;
        "browser.sessionstore.restore_on_demand" = false;
    };
}
