# frozen_string_literal: true


field = Array.new(20){ Array.new 10 }

figure = x = y = nil
mix = lambda do |f|
  figure.each_with_index do |row, dy|
    row.each_index do |dx|
      next if row[dx].zero?
      field[y + dy][x + dx] = (row[dx] if f)
    end
  end
end

require "ruby2d"
render = lambda do
  block_margin = 1
  block_side = 35
  s = block_margin * 2 + block_side
  margin = 30
  w = margin * 2 + s * field.first.size
  h = margin * 2 + s * field.size
  set width: w, height: h, title: "rbTris"
  Rectangle.new x: 0,      y: 0,      width: w,              height: h,              color: "gray"
  Rectangle.new x: margin, y: margin, width: w - 2 * margin, height: h - 2 * margin, color: "black"
  blocks = Array.new(field.size) do |y|
    Array.new(field.first.size) do |x|
      [
        Square.new(x: margin + block_margin + s * x,
                   y: margin + block_margin + s * y,
                   size: block_side),
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


semaphore = Mutex.new

draw_state = lambda do
  mix.call true
  render.call
  mix.call false
end

prev, row_time = nil, 0
tap do
  points, first_time = 0, nil
  text_score = Text.new points, x: 5, y: 5, font: Font.path("PressStart2P-Regular.ttf")
  text_level = Text.new points, x: 5, y: 5, font: Font.path("PressStart2P-Regular.ttf")
  update do
    current = Time.now
    first_time ||= current
    semaphore.synchronize do
      text_score.text = "Score: #{points}"
      level = (((points / 5 + 0.125) * 2) ** 0.5 - 0.5 + 1e-6).floor
      text_level.text = "Level: #{level}"
      text_level.x = Window.width - 5 - text_level.width
      row_time = (0.8 - (level - 1) * 0.007) ** (level - 1)
      prev ||= current - row_time
      if current >= prev + row_time
        prev += row_time
        if figure
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
            figure = nil
          end
        end
      end

      unless figure
        figure = [
          %w{ 1111    },
          %w{ 22  22  },
          %w{ 033 330 },
          %w{ 440 044 },
          %w{ 500 555 },
          %w{ 006 666 },
          %w{ 070 777 },
        ].sample
        rest = figure.first.size - figure.size
        figure = (
          [?0 * figure.first.size] * (rest / 2) + figure +
          [?0 * figure.first.size] * (rest - rest / 2)
        ).map!{ |st| st.chars.map &:to_i }
        x, y = 3, 0
        abort "#{text_score.text}\n#{text_level.text}" unless collision.call
        draw_state.call
      end
    end
  end
end


holding = Hash.new

try_left = lambda do
  x -= 1
  next draw_state.call if collision.call
  x += 1
end
try_right = lambda do
  x += 1
  next draw_state.call if collision.call
  x -= 1
end
try_up = lambda do
  figure = figure.reverse.transpose
  next draw_state.call if collision.call
  figure = figure.transpose.reverse
end

on :key_down do |event|
  holding[event.key] = Time.now
  semaphore.synchronize do
    case event.key
    when "left"  ; try_left.call
    when "right" ; try_right.call
    when "up"    ; try_up.call
    end
  end
end
on :key_held do |event|
  semaphore.synchronize do
    case event.key
    when "left"  ; try_left.call  unless 0.5 > Time.now - holding[event.key]
    when "right" ; try_right.call unless 0.5 > Time.now - holding[event.key]
    when "up"    ; try_up.call    unless 0.5 > Time.now - holding[event.key]
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
  end
end

show
