![](https://storage.googleapis.com/rbtris.github.nakilon.pro/screenshot3.png)

based on https://gist.github.com/obelisk68/15ffdf1bfd82953361be0264b5ea4119

reduced original LOC from 211 to ~125  
now adding features -- some of them are listed below

for the cool font that you see on the screenshot, download the https://fonts.google.com/download?family=Press%20Start%202P to the working directory where you run the `bundle exec ruby main.rb`

TODO:

* [ ] projetion of the piece at the bottom
* [ ] canonical shapes rotation center
* [ ] shift a piece by bouncing of the walls when rotating
* [ ] scoreboard (maybe at $HOME/.rbtris)
* [x] ability to fall down only partially
* [x] ability to hold UP (just for fun)
* [x] Mutex stdlib class instead of key_lock var
* [ ] autoresize to screen
* [ ] option to restart
* [ ] cheat for testing purposes
* [x] canonical increase of speed
* [x] holding LEFT and RIGHT
* [ ] [canonical scoring](https://tetris.fandom.com/wiki/Scoring)
* [ ] see next piece
* [ ] pause key
* [ ] window size configuration
* [ ] canonical music
* [ ] restore controller support
