The application is a macOS app that adds a context menu item 'Send to ChatGPT' when user right clicks on the selected text anywhere in their mac. If the user selects the item it will send the selected text to the chrome instance, given chrome is running and has the extension installed. Chrome extension will open chat.openai.com and paste the text into the chat box.


# Critical
- [Done] Release chrome extension
- Add vscode base build
- Listen for escape key to close the window (steel from share shot)
- Actually build the UI for the menu
- Add shortcut cmd ; and cmd shift ; to send to chatgpt
- Final tweaks to make sure it works
- Record a video of the thing
- Publish
    - on Gumroad
    - on homebrew
    - on GitHub
    - try enabling sandboxing as a separate target and distribute through app store
- Get Tito using the thing :D

# TODO
- Get on Gumroad
- Release the source code - since we are asking for high permissions, we want to be transparent
- Add ability to focus on chatgpt as well, so send and focus
  - Maybe hold down alt as you click the button?
- Add a keyboard shortcut to do the sends - should be the same as the vscode shortcut
  - VSCode Cmd K is not working - probably a collision with something else
- Start chrome browser if not running already
- If can't connect - suggest to start chrome, if still not working - suggest to install extension - show a tutorial
- Add basic analytics
- Distribute a nerved version of this through app store - it will just have keyboard shortcuts, no context menu. It will also use the clipboard to capture selection, not the accessibility APIs


# References

- Accessibility during development https://stackoverflow.com/questions/72312351/persist-accessibility-permissions-between-builds-in-xcode-13
- Unable to add app to accessibility apps with sandbox enabled https://developer.apple.com/forums/thread/707680
- Cannot distribute on AppStore non-sandboxed app :( https://developer.apple.com/forums/thread/693312
- Competition: There currently exists a copilot for Xcode https://medium.com/globant/boost-your-productivity-integrate-github-copilot-with-xcode-94a0ee74b961