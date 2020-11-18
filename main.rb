require "ruby2d"

text_new = lambda do |text = "", **args|
  Text.new text, font: Font.path("PressStart2P-Regular.ttf"), **args
end

block_size = 30 + 2 * margin = 1
x2 = block_size * 10 + block_size + border = block_size
field = nil
reset_field = lambda do
                   text_new.call "HI-SCORE:", color: "black", x: x2,              y: border + block_size * 9
  text_highscore = text_new.call              color: "black", x: x2 + block_size, y: border + block_size * 10
  lambda do
    field = Array.new(20){ Array.new 10 }
    text_highscore.text = File.exist?("#{Dir.home}/.rbtris") ?
                            File.read("#{Dir.home}/.rbtris").scan(/^2 .*?(\S+)$/).map(&:first).map(&:to_i).max : "---"
  end.tap &:call
end.call
set width: border * 2 + block_size * (field.first.size + 6), height: block_size * field.size + border * 2, title: "rbTris"
Rectangle.new width: Window.width,    height: Window.height,           color: "silver", z: -1
Rectangle.new width: block_size * 5,  height: block_size * 3,          color: "black", z: -1, x: x2, y: border
Rectangle.new width: block_size * 10, height: block_size * field.size, color: "black", z: -1, x: border, y: border
figure = x = y = nil
mix = lambda do |f|
  figure.each_with_index do |row, dy|
    row.each_index do |dx|
      field[y + dy][x + dx] = (row[dx] if f) if row[dx]
    end
  end
end
render = lambda do
  blocks = Array.new(field.size) do |y|
    Array.new(field.first.size) do |x|
      [ Square.new(x: border + margin + block_size * x,
                   y: border + margin + block_size * y,
                   z: -1, size: block_size - 2 * margin) ]
    end
  end
  lambda do
    mix.call true
    blocks.each_with_index do |row, i|
      row.each_with_index do |(block, drawn), j|
        if field[i][j]
          block.color = %w{ aqua yellow green red blue orange purple }[field[i][j] - 1]
          unless drawn == true
            block.add
            row[j][1] = true
          end
        else
          unless drawn == false
            block.remove
            row[j][1] = false
          end
        end
      end
    end
    mix.call false
  end
end.call

collision = lambda do
  figure.each_with_index.any? do |row, dy|
    row.each_with_index.any? do |a, dx|
      not !a ||
        ((0...field.size      ) === y + dy) &&
        ((0...field.first.size) === x + dx) &&
        !field[y + dy][x + dx]
    end
  end or (
    render.call
    false
  )
end

             text_new.call"SCORE:", color: "black", x: x2,              y: border + block_size * 6
text_score = text_new.call"",       color: "black", x: x2 + block_size, y: border + block_size * 7
             text_new.call"LEVEL:", color: "black", x: x2,              y: border + block_size * 12
text_level = text_new.call"",       color: "black", x: x2 + block_size, y: border + block_size * 13
score = nil

paused = false
toggle_pause = lambda do
  pause_rect = Rectangle.new(width: Window.width, height: Window.height, color: [0.5, 0.5, 0.5, 0.75], z: -1).tap &:remove
  pause_text = text_new.call("press 'Space'").tap &:remove
  pause_text.x = (Window.width - pause_text.width) / 2
  pause_text.y = (Window.height - pause_text.height) / 2
  lambda do
    [pause_rect, pause_text].each &((paused ^= true) ? :add : :remove)
  end
end.call
init_figure = lambda do
  make_figure = lambda do
    t = %w{ 070 777 006 666 500 555 440 044 033 330 22 22 1111 }.each_slice(2).to_a.sample
    rest = t.first.size - t.size
    (
      [?0 * t.first.size] * (rest / 2) + t +
      [?0 * t.first.size] * (rest - rest / 2)
    ).map{ |st| st.chars.map{ |c| c.to_i unless c == ?0 } }
  end
  next_figure = make_figure.call
  blocks = 4.times.map{ 4.times.map{ Square.new z: -1, size: block_size - 2 * margin } }
  lambda do
    x, y, figure, next_figure = 3, 0, next_figure, make_figure.call
    temp_figure = next_figure.select &:any?   # this all will become simplier probably if we start use only 4x4 array for figure
    dy = border + margin + block_size *  (1.5 - temp_figure.          count(&:any?) / 2.0)
    dx = border + margin + block_size * (13.5 - temp_figure.transpose.count(&:any?) / 2.0)
    blocks.each_with_index do |row, i|
      row.each_with_index do |block, j|
        next block.remove unless temp_figure[i] && temp_figure[i][j]
        block.color = %w{ aqua yellow green red blue orange purple }[temp_figure[i][j] - 1]
        block.y = dy + block_size * i
        block.x = dx + block_size * j
        block.add
      end
    end
    next unless collision.call
    File.open("#{Dir.home}/.rbtris", "a") do |f|
      f.puts "2 #{"#{text_level.text}   #{text_score.text}".tap &method(:puts)}"
    end
    toggle_pause.call
    score = nil
  end.tap &:call
end.call
reset = lambda do
  score, figure = 0, nil
  reset_field.call
  init_figure.call
end


semaphore = Mutex.new
holding = Hash.new

prev, row_time = nil, 0
reset.call
Window.update do
  current = Time.now
  text_score.text = score unless paused
  semaphore.synchronize do
    unless paused
      text_level.text = level = (((score / 5 + 0.125) * 2) ** 0.5 - 0.5 + 1e-6).floor
      row_time = (0.8 - (level - 1) * 0.007) ** (level - 1)
    end
    prev ||= current - row_time
    next unless current >= prev + row_time
    prev += row_time
    next unless figure && !paused
    y += 1
    next unless collision.call
    y -= 1
    holding["down"] = Time.now + 0.25
    mix.call true
    field.partition(&:all?).tap do |a, b|
      field = a.map{ Array.new field.first.size } + b
      score += [0, 1, 3, 5, 8].fetch a.size
    end
    init_figure.call
    render.call
  end
end


try_move = lambda do |dir|
  x += dir
  next unless collision.call
  x -= dir
end
try_rotate = lambda do
  figure = figure.reverse.transpose
  next unless collision.call
  figure = figure.transpose.reverse
end

Window.on :key_down do |event|
  holding[event.key] = Time.now
  semaphore.synchronize do
    case event.key
    when "left"  ; try_move.call -1 if figure && !paused
    when "right" ; try_move.call +1 if figure && !paused
    when "up"    ; try_rotate.call  if figure && !paused
    when "r"
      reset.call unless paused
    when "p", "space"
      toggle_pause.call
      reset.call unless score
    end
  end
end
Window.on :key_held do |event|
  semaphore.synchronize do
    case event.key
    when "left"  ; try_move.call -1 if figure && 0.5 < Time.now - holding[event.key]
    when "right" ; try_move.call +1 if figure && 0.5 < Time.now - holding[event.key]
    when "up"    ; try_rotate.call  if figure && 0.5 < Time.now - holding[event.key]
    when "down"  ;         next unless           0   < Time.now - holding[event.key]
      y += 1
      prev = if collision.call
        y -= 1
        Time.now - row_time
      else
        Time.now
      end
    end
  end unless paused
end

show
