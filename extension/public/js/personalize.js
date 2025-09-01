function personalize() {
  // Get personalize
  const personalize = document.getElementById("personalize");
  // Get settings
  const settings = document.getElementById("settings");
  // Switch hide
  personalize.classList.toggle("hide");
  settings.classList.toggle("hide");
  // Remove fullscreen if close
  if (settings.classList.contains("hide")) {
    if (settings.parentElement.classList.contains("fullscreen")) {
      settingsFS();
    }
  } else {
    settingsFS();
  }
}
