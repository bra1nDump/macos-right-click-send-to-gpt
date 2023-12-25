The application is a macOS app that adds a context menu item 'Send to ChatGPT' when user right clicks on the selected text anywhere in their mac. If the user selects the item it will send the selected text to the chrome instance, given chrome is running and has the extension installed. Chrome extension will open chat.openai.com and paste the text into the chat box.

# TODO
- Add ability to focus on chatgpt as well, so send and focus
  - Maybe hold down alt as you click the button?
- Add a keyboard shortcut to do the sends - should be the same as the vscode shortcut
- Start chrome browser if not running already
- If can't connect - suggest to start chrome, if still not working - suggest to install extension - show a tutorial
- Add basic analytics

# Critical
- Release chrome extension
- Get Tito using the thing :D
- Get on Gumroad
- Release the source code - since we are asking for high permissions, we want to be transparent

# References

- Accessibility during development https://stackoverflow.com/questions/72312351/persist-accessibility-permissions-between-builds-in-xcode-13
- Unable to add app to accessibility apps with sandbox enabled https://developer.apple.com/forums/thread/707680
- Cannot distribute on AppStore non-sandboxed app :( https://developer.apple.com/forums/thread/693312