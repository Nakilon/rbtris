# frozen_string_literal: true


unless File.exist? "PressStart2P-Regular.ttf"
  require "nethttputils"
  require "zip"
  tempfile = Tempfile.new "Press_Start_2P.zip"
  File.binwrite tempfile, NetHTTPUtils.request_data("https://fonts.google.com/download?family=Press%20Start%202P")
  Zip::File.open(tempfile){ |zip| zip.extract "PressStart2P-Regular.ttf", "PressStart2P-Regular.ttf" }
end


field = nil

require "ruby2d"
reset_field = lambda do
  field = Array.new(20){ Array.new 10 }
end
render = lambda do
  margin = 1
  inner = 30
  s = inner + 2 * margin
  reset_field.call
  w = s * (2 + field.first.size)
  h = s * (3 + field.size)
  set width: w, height: h, title: "rbTris"
  Rectangle.new width: w,         height: h,         color: "gray"
  Rectangle.new width: w - 2 * s, height: h - 3 * s, color: "black", x: s, y: s * 2
  blocks = Array.new(field.size) do |y|
    Array.new(field.first.size) do |x|
      [
        Square.new(x: margin + s * (1 + x),
                   y: margin + s * (2 + y),
                   size: inner),
        nil
      ]
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
mix = lambda do |f|
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

semaphore = Mutex.new
paused = false
pause_rect = Rectangle.new(width: Window.width, height: Window.height, color: [0.5, 0.5, 0.5, 0.75]).tap &:remove
pause_text = Text.new("press 'P'", z: 1, font: Font.path("PressStart2P-Regular.ttf")).tap &:remove


points = nil
collision = lambda do   # there is no collision
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
text_score = Text.new points, x: 5, y: 5, z: 1, font: Font.path("PressStart2P-Regular.ttf")
text_level = Text.new points, x: 5, y: 5, z: 1, font: Font.path("PressStart2P-Regular.ttf")
init_figure = lambda do
  figure = %w{ 070 777 006 666 500 555 440 044 033 330 22 22 1111 }.each_slice(2).to_a.sample
  rest = figure.first.size - figure.size
  figure = (
    [?0 * figure.first.size] * (rest / 2) + figure +
    [?0 * figure.first.size] * (rest - rest / 2)
  ).map!{ |st| st.chars.map &:to_i }
  x, y = 3, 0
  next draw_state.call if collision.call
  open("#{Dir.home}/.rbtris", "a") do |f|
    f.puts "1 #{"#{text_level.text}   #{text_score.text}".tap &method(:puts)}"
  end
  [pause_rect, pause_text].each &((paused ^= true) ? :add : :remove)
  points = nil
end
reset = lambda do
  points, figure = 0, nil
  reset_field.call
  init_figure.call
end


prev, row_time = nil, 0
tap do
  points, first_time = 0, nil
  reset_field.call
  init_figure.call
  update do
    current = Time.now
    first_time ||= current
    text_score.text = "Score: #{points}" unless paused
    semaphore.synchronize do
      unless paused
        level = (((points / 5 + 0.125) * 2) ** 0.5 - 0.5 + 1e-6).floor  # outside of Mutex points are being accesses by render[]
        text_level.text = "Level: #{level}"
        text_level.x = Window.width - 5 - text_level.width
        row_time = (0.8 - (level - 1) * 0.007) ** (level - 1)
      end
      prev ||= current - row_time
      if current >= prev + row_time
        prev += row_time
        if !paused && figure
          y += 1
          if collision.call
            draw_state.call
          else
            y -= 1
            mix.call true
            a, b = field.partition &:all?
            field = a.map{ Array.new field.first.size } + b
            points += [0, 1, 3, 5, 8].fetch a.size
            render.call
            init_figure.call
          end
        end
      end
    end
  end
end


try_move = lambda do |dir|
  next unless figure
  x += dir
  next draw_state.call if collision.call
  x -= dir
end
try_up = lambda do
  next unless figure
  figure = figure.reverse.transpose
  next draw_state.call if collision.call
  figure = figure.transpose.reverse
end

holding = Hash.new
pause_text.x = (Window.width - pause_text.width) / 2
pause_text.y = (Window.height - pause_text.height) / 2
on :key_down do |event|
  holding[event.key] = Time.now
  semaphore.synchronize do
    case event.key
    when "left"  ; try_move[-1] unless paused
    when "right" ; try_move[+1] unless paused
    when "up"    ; try_up.call  unless paused
    when "r" ; reset.call unless paused
    when "p", "space"
      [pause_rect, pause_text].each &((paused ^= true) ? :add : :remove)
      unless points
        reset.call
        draw_state.call
      end
    end
  end
end
on :key_held do |event|
  semaphore.synchronize do
    case event.key
    when "left"  ; try_move[-1] unless 0.5 > Time.now - holding[event.key]
    when "right" ; try_move[+1] unless 0.5 > Time.now - holding[event.key]
    when "up"    ; try_up.call  unless 0.5 > Time.now - holding[event.key]
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
