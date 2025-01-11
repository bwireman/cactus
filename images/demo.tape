Output images/demo.gif
Set FontSize 14
Set PlaybackSpeed 1.25
Set TypingSpeed 75ms
Set FontFamily 'JetBrains Mono'
Set Margin 15
Set MarginFill "#ffaff3"
Set BorderRadius 12

#setup
Hide
Type `rm -rf .go-over/mirego-elixir-security-advisories .go-over/deps/s* && git branch -D demo && git branch demo --set-upstream-to origin demo && git checkout demo`
Enter
Type clear
Enter
Show

Type `gleam run -m cactus -- -h`
Enter
Sleep 8s

Type clear
Enter

Type `gleam run -m cactus`
Enter
Sleep 2s
Type `git push --dry-run`
Enter
Sleep 8s

#teardown
Hide
Type `git checkout -`
Type `git branch -D demo`
Type clear
Enter
Show
