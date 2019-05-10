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
  block_side = 25
  s = block_margin * 2 + block_side
  margin = 30
  w = margin * 2 + s * width
  h = margin * 2 + s * height
  Window.set width: w, height: h, title: "rbTris"
  Rectangle.new x: 0,      y: 0,      width: w,              height: h,              color: "gray"
  Rectangle.new x: margin, y: margin, width: w - 2 * margin, height: h - 2 * margin, color: "black"
  blocks = Array.new(height) do |y|
    Array.new(width) do |x|
      Square.new x: margin + block_margin + s * x,
                 y: margin + block_margin + s * y,
                 size: block_side
    end
  end
  lambda do
    draw.call true
    height.times do |y|
      width.times do |x|
        if field[y][x]
          blocks[y][x].color = %w{ aqua yellow green red blue orange purple }[(field[y][x] || 0) - 1]
          blocks[y][x].add
        else
          blocks[y][x].remove
        end
      end
    end
    draw.call false
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

tick = 0
update do
  tick += 1

  semaphore.synchronize do
    if figure && (tick % 20).zero?
      y += 1
      if collision.call
        y -= 1
        draw.call true
        a, b = field.partition &:all?
        field = a.map{ Array.new width } + b
        figure = nil
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

      abort "game over" if collision.call
    end
    render.call
  end
end

move = lambda do |dx|
  x += dx
  x -= dx if x < 0 || collision.call
end

holding = Hash.new
on :key_down do |event|
  semaphore.synchronize do
    case event.key
    when "left"  then move.call -1
    when "right" then move.call +1
    when "up"
      holding[event.key] = Time.now
      figure = figure.reverse.transpose
      figure = figure.transpose.reverse if collision.call
    end
  end
end
on :key_held do |event|
  semaphore.synchronize do
    case event.key
    when "up"
      next if 0.5 > Time.now - holding[event.key]
      figure = figure.reverse.transpose
      figure = figure.transpose.reverse if collision.call
    when "down"
      y += 1
      y -= 1 if collision.call
    end
  end
end
on :key_up do |event|
  case event.key
  when "up"
    holding.delete event.key
  end
end

show
