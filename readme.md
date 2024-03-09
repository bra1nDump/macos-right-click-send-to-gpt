The application is a macOS app that adds a context menu item 'Send to ChatGPT' when user right clicks on the selected text anywhere in their mac. If the user selects the item it will send the selected text to the chrome instance, given chrome is running and has the extension installed. Chrome extension will open chat.openai.com and paste the text into the chat box.

# Running
- To build with xcode simply open the project, replace the development team and run the app
- Select the text you want to send to chatgpt - anywhere in your mac [not really, tested, vscode does not work :D]

# Release 0.1
- Run it lol
- Handle the menu disappearing for any other reason other than escape - like clicking outside
  - I can try subscribing to global window changes if there's an API for that
- Release the source code
- Release the binary on github
- Record a video of the thing - remember that it needs to go with the chrome extension
- Message tito, to ask for a review

# Later
- Fixup the UI
  - Layout
  - Handle both dark and light mode
  - Add menu item so people can kill the app

- Publish in more places
    - on Gumroad
    - on homebrew
    - on GitHub
    - try enabling sandboxing as a separate target and distribute through app store

# Later later
- [interaction mode] [experiment] I extracting the response from ChatGPT without actually focusing on the browser

- [feature] Simply allow sharing the selection using the native share menu. Oftentimes I just want to send a friend a quote from my own notes or from a website. Can already share from the website using the chrome highlight sharing feature, but you copy the link, not share the contents of your clipboard with someone
- [feature] We can add more dev tools similar to https://devutils.com/ [$40 min pricing]

- Add ability to focus on chatgpt as well, so send and focus
  - Maybe hold down alt as you click the button?
- Add a keyboard shortcut to do the sends - should be the same as the vscode shortcut
  - Cmd + ;
- Chrome not running
  - Start chrome browser if not running already
  - If can't connect - suggest to start chrome, if still not working - suggest to install extension - show a tutorial

- Add basic analytics

# References

- Accessibility during development https://stackoverflow.com/questions/72312351/persist-accessibility-permissions-between-builds-in-xcode-13
- Unable to add app to accessibility apps with sandbox enabled https://developer.apple.com/forums/thread/707680
- Cannot distribute on AppStore non-sandboxed app :( https://developer.apple.com/forums/thread/693312
- Competition: There currently exists a copilot for Xcode https://medium.com/globant/boost-your-productivity-integrate-github-copilot-with-xcode-94a0ee74b961

# Done
- [Done] Release chrome extension
- [Done] Add vscode base build
- [Done] Listen for escape key to close the window (steel from share shot)
- [Done] Actually build the UI for the menu

