# Tetris game in less than 200 lines of code

![](https://storage.googleapis.com/rbtris.github.nakilon.pro/screenshot8.png)

## Controls

**ARROWS**  
**R** to restart  
**P** or **Space** to pause

## Installation

```
bundle install
bundle exec ruby main.rb
```

For Linux you might need to read the [Ruby2d installation notes](http://www.ruby2d.com/learn/linux/#install-packages).

## TODO

* [ ] projetion of the piece on the bottom
* [x] [SRS canonical rotation](https://tetris.fandom.com/wiki/SRS)
* [ ] SRS wall kicks
* [x] scoreboard stored at `$HOME/.rbtris`
* [x] ability to fall down only partially
* [x] ability to hold UP (just for fun)
* [x] Mutex stdlib class
* [ ] autoresize to screen?
* [x] option to restart
* [ ] cheats for testing purposes
* [x] canonical increase of speed
* [x] holding LEFT and RIGHT
* [ ] [canonical scoring](https://tetris.fandom.com/wiki/Scoring)
* [ ] see next piece
* [x] pause key
* [ ] window size configuration?
* [ ] [canonical music](https://en.wikipedia.org/wiki/Tetris#Music)
* [ ] restore controller support?
* [ ] color scheme configuration
* [ ] [boss key](https://en.wikipedia.org/wiki/Boss_key)
* [ ] compile and publish?

## Notes

By default ruby2d looks for a font only in one system directory -- this is why ruby2d dependency here was [forked and patched](https://github.com/Nakilon/ruby2d/commit/a80fa4b47e713e22995a7c2698fd055f5464b23b) a bit to support sourcing from the working directory (and `$HOME/Library/Fonts`).

It can't be compiled to binary right now because of using a Mutex class that is not in MRuby.

It's hard to continue fitting it into 200 lines but I want to add more features -- ~~maybe I'll make a "300-LOC" branch~~ there is now 250-loc branch that has the "next piece" displayed.

Cool font is [Press Start 2P from Google Fonts](https://fonts.google.com/specimen/Press+Start+2P).
