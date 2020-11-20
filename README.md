# Tetris game in less than 250 lines of code

![](https://storage.googleapis.com/rbtris.github.nakilon.pro/screenshot10.png)

## Controls

**Left**, **Right** to move  
**Up** to rotate  
**Down** or **Space** to drop  
**R** to restart  
**P** or **Escape** to pause
**M** to pause/resume music

## Installation

```
bundle install
bundle exec ruby main.rb
```

For Linux you might need to read the [Ruby2d installation notes](http://www.ruby2d.com/learn/linux/#install-packages).

## TODO

* [x] [SRS canonical rotation](https://tetris.fandom.com/wiki/SRS)
* [x] scoreboard stored at `~/.rbtris`
* [x] ability to fall down only partially
* [x] ability to hold UP (just for fun)
* [x] using Mutex
* [x] option to restart
* [x] canonical increase of speed
* [x] holding LEFT and RIGHT
* [x] pause key

(all above is included in the "200 lines of code" `loc-200` git branch)

* [x] conflict-free `~/.rbtris` file for different branches of the game
* [x] SPACE to drop
* [x] bundle the font
* [x] see next piece
* [x] projetion of the piece on the bottom
* [x] wall kicks
* [x] [canonical music](https://en.wikipedia.org/wiki/Tetris#Music)
* [ ] autoresize to screen?
* [ ] cheats for testing purposes
* [ ] [canonical scoring](https://tetris.fandom.com/wiki/Scoring)?
* [ ] window size configuration?
* [ ] restore controller support?
* [ ] color scheme configuration
* [ ] [boss key](https://en.wikipedia.org/wiki/Boss_key)
* [ ] compile and publish?
* [ ] demo recording/playback?
* [ ] save/load game progress
* [ ] +/- to resize window (requires on ruby2d/ruby2d#168)

## Notes

It can't be compiled to binary right now because of using a MRI stdlib Mutex that is not in MRuby.

Cool font is [Press Start 2P](https://fonts.google.com/specimen/Press+Start+2P) -- licensed under the [Open Font License](LICENSE.OFL-1.1.txt).
