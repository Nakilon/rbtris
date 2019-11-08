unless File.exist? "PressStart2P-Regular.ttf"
  require "open-uri"
  require "zip"
  tempfile = Tempfile.new "Press_Start_2P.zip"
  File.binwrite tempfile, open("https://fonts.google.com/download?family=Press%20Start%202P", &:read)
  Zip::File.open(tempfile){ |zip| zip.extract "PressStart2P-Regular.ttf", "PressStart2P-Regular.ttf" }
end

require "ruby2d"

field = nil
block_size = 30 + 2 * margin = 1
reset_field = lambda do
  text_highscore = Text.new("", x: 5, y: 5, z: 1, font: Font.path("PressStart2P-Regular.ttf"))
  lambda do
    field = Array.new(20){ Array.new 10 }
    text_highscore.text = "Highscore: #{
      File.exist?("#{Dir.home}/.rbtris") ?
        File.read("#{Dir.home}/.rbtris").scan(/^1 .*?(\S+)$/).map(&:first).map(&:to_i).max : "---"
    }"
  end
end.call
render = lambda do
  reset_field.call
  w = block_size * (2 + field.first.size)
  h = block_size * (3 + field.size)
  set width: w, height: h, title: "rbTris"
  Rectangle.new width: w,                  height: h,                  color: "gray"
  Rectangle.new width: w - 2 * block_size, height: h - 3 * block_size, color: "black", x: block_size, y: block_size * 2
  blocks = Array.new(field.size) do |y|
    Array.new(field.first.size) do |x|
      [ Square.new(x: margin + block_size * (1 + x),
                   y: margin + block_size * (2 + y),
                   size: block_size - 2 * margin) ]
    end
  end
  lambda do
    blocks.each_with_index do |row, i|
      row.each_with_index do |(block, drawn), j|
        if field[i][j]
          unless drawn == true
            block.color = %w{ aqua yellow green red blue orange purple }[(field[i][j] || 0) - 1]
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
  end
end.call

figure = x = y = nil
mix = lambda do |f|     # add or subtract the figure from the field (call it before rendering)
  figure.each_with_index do |row, dy|
    row.each_index do |dx|
      field[y + dy][x + dx] = (row[dx] if f) unless row[dx].zero?
    end
  end
end
draw_state = lambda do
  mix.call true
  render.call
  mix.call false
end

collision = lambda do   # no collision
  figure.each_with_index.all? do |row, dy|
    row.each_with_index.all? do |a, dx|
      a.zero? || (
        ((0...field.size      ) === y + dy) &&
        ((0...field.first.size) === x + dx) &&
        !field[y + dy][x + dx]
      )
    end
  end
end

score = nil
text_score = Text.new score, x: 5, y: block_size + 5, z: 1, font: Font.path("PressStart2P-Regular.ttf")
text_level = Text.new score, x: 5, y: block_size + 5, z: 1, font: Font.path("PressStart2P-Regular.ttf")

paused = false
pause_rect = Rectangle.new(width: Window.width, height: Window.height, color: [0.5, 0.5, 0.5, 0.75]).tap &:remove
pause_text = Text.new("press 'Space'", z: 1, font: Font.path("PressStart2P-Regular.ttf")).tap &:remove
init_figure = lambda do
  figure = %w{ 070 777 006 666 500 555 440 044 033 330 22 22 1111 }.each_slice(2).to_a.sample
  rest = figure.first.size - figure.size
  x, y, figure = 3, 0, (
    [?0 * figure.first.size] * (rest / 2) + figure +
    [?0 * figure.first.size] * (rest - rest / 2)
  ).map{ |st| st.chars.map &:to_i }
  next draw_state.call if collision.call
  File.open("#{Dir.home}/.rbtris", "a") do |f|
    f.puts "1 #{"#{text_level.text}   #{text_score.text}".tap &method(:puts)}"
  end
  [pause_rect, pause_text].each &((paused ^= true) ? :add : :remove)
  score = nil
end
reset = lambda do
  score, figure = 0, nil
  reset_field.call
  init_figure.call
end


semaphore = Mutex.new

prev, row_time = nil, 0
tap do
  first_time = nil
  reset.call
  Window.update do
    current = Time.now
    first_time ||= current
    unless paused
      text_score.text = "Score: #{score}"
      text_score.x = Window.width - 5 - text_score.width
    end
    semaphore.synchronize do
      unless paused
        level = (((score / 5 + 0.125) * 2) ** 0.5 - 0.5 + 1e-6).floor  # outside of Mutex score is being accesses by render[]
        text_level.text = "Level: #{level}"
        row_time = (0.8 - (level - 1) * 0.007) ** (level - 1)
      end
      prev ||= current - row_time
      next unless current >= prev + row_time
      prev += row_time
      next unless !paused && figure
      y += 1
      next draw_state.call if collision.call
      y -= 1
      # puts "FPS: #{(Window.frames.round - 1) / (current - first_time)}" if Window.frames.round > 1
      mix.call true
      field.partition(&:all?).tap do |a, b|
        field = a.map{ Array.new field.first.size } + b
        score += [0, 1, 3, 5, 8].fetch a.size
      end
      render.call
      init_figure.call
    end
  end
end


try_move = lambda do |dir|
  x += dir
  next draw_state.call if collision.call
  x -= dir
end
try_rotate = lambda do
  figure = figure.reverse.transpose
  next draw_state.call if collision.call
  figure = figure.transpose.reverse
end

holding = Hash.new
pause_text.x = (Window.width - pause_text.width) / 2
pause_text.y = (Window.height - pause_text.height) / 2
Window.on :key_down do |event|
  holding[event.key] = Time.now
  semaphore.synchronize do
    case event.key
    when "left"  ; try_move.call -1 unless !figure || paused
    when "right" ; try_move.call +1 unless !figure || paused
    when "up"    ; try_rotate.call  unless !figure || paused
    when "r"
      reset.call unless paused
    when "p", "space"
      [pause_rect, pause_text].each &((paused ^= true) ? :add : :remove)
      reset.call unless score
    end
  end
end
Window.on :key_held do |event|
  semaphore.synchronize do
    case event.key
    when "left"  ; try_move.call -1 unless !figure || 0.5 > Time.now - holding[event.key]
    when "right" ; try_move.call +1 unless !figure || 0.5 > Time.now - holding[event.key]
    when "up"    ; try_rotate.call  unless !figure || 0.5 > Time.now - holding[event.key]
    when "down"
      y += 1
      unless collision.call
        prev = Time.now - row_time
        y -= 1
      else
        prev = Time.now
        draw_state.call
      end
    end
  end unless paused
end

show
