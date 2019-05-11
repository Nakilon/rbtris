# frozen_string_literal: true


width, height = 10, 20
field = Array.new(height){ Array.new width }

figure = x = y = nil
draw = lambda do |f|
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
  w = margin * 2 + s * width
  h = margin * 2 + s * height
  set width: w, height: h, title: "rbTris"
  Rectangle.new x: 0,      y: 0,      width: w,              height: h,              color: "gray"
  Rectangle.new x: margin, y: margin, width: w - 2 * margin, height: h - 2 * margin, color: "black"
  blocks = Array.new(height) do |y|
    Array.new(width) do |x|
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

collision = lambda do
  return true if y + figure.      size > height
  return true if x + figure.first.size > width
  figure.each_with_index.any? do |row, dy|
    row.each_with_index.any? do |a, dx|
      !a.zero? && field[y + dy][x + dx]
    end
  end
end


semaphore = Mutex.new

draw_state = lambda do
  draw.call true
  render.call
  draw.call false
end

points = row_time = 0
text_score = Text.new points, x: 5, y: 5, font: Font.path("PressStart2P-Regular.ttf")
text_level = Text.new points, x: 5, y: 5, font: Font.path("PressStart2P-Regular.ttf")
first_time = prev = nil
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
        unless collision.call
          draw_state.call
        else
          y -= 1
          draw.call true
          a, b = field.partition &:all?
          field = a.map{ Array.new width } + b
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
      ].sample.map{ |st| st.chars.map &:to_i }
      x, y = 3, 0

      abort "#{text_score.text}\n#{text_level.text}" if collision.call

      draw_state.call
    end
  end
end


holding = Hash.new

try_left = lambda do
  x -= 1
  if x < 0 || collision.call
    x += 1
  else
    draw_state.call
  end
end
try_right = lambda do
  x += 1
  if collision.call
    x -= 1
  else
    draw_state.call
  end
end
try_up = lambda do
  figure = figure.reverse.transpose
  if collision.call
    figure = figure.transpose.reverse
  else
    draw_state.call
  end
end

on :key_down do |event|
  holding[event.key] = Time.now
  semaphore.synchronize do
    case event.key
    when "left"
      try_left.call
    when "right"
      try_right.call
    when "up"
      try_up.call
    end
  end
end
on :key_held do |event|
  semaphore.synchronize do
    case event.key
    when "left"
      next if 0.5 > Time.now - holding[event.key]
      try_left.call
    when "right"
      next if 0.5 > Time.now - holding[event.key]
      try_right.call
    when "up"
      next if 0.5 > Time.now - holding[event.key]
      try_up.call
    when "down"
      y += 1
      if collision.call
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
