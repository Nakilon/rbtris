![](https://storage.googleapis.com/rbtris.github.nakilon.pro/screenshot3.png)

Reduced [original gist](https://gist.github.com/obelisk68/15ffdf1bfd82953361be0264b5ea4119) LOC from 211 to ~125.  
Now adding features -- some of them are listed below in the TODO list.

By default ruby2d looks for a font only in one system directory -- this is why ruby2d dependency here was [forked and patched](https://github.com/Nakilon/ruby2d/commit/a80fa4b47e713e22995a7c2698fd055f5464b23b) a bit to support sourcing from the working directory (and `$HOME/Library/Fonts` one).

TODO:

* [ ] projetion of the piece at the bottom
* [x] [SRS canonical rotation](https://tetris.fandom.com/wiki/SRS)
* [ ] shift a piece by bouncing of the walls when rotating
* [ ] scoreboard (maybe at `$HOME/.rbtris`)
* [x] ability to fall down only partially
* [x] ability to hold UP (just for fun)
* [x] Mutex stdlib class (no MRuby support)
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
* [ ] color scheme configuration
* [ ] SRS wall kicks

Sketch of the almost current program structure:

![](https://storage.googleapis.com/rbtris.github.nakilon.pro/refactoring4.JPG)
