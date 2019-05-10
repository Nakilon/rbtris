# frozen_string_literal: true


width, height = 10, 20
field = Array.new(height){ Array.new width }

figure = num = nil
get = lambda do
  figure.map{ |row| row.map{ |i| i * num } }
end

x = y = nil
draw = lambda do |f|
  get.call.each_with_index do |row, dy|
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
          blocks[y][x].color = %w{ #158FAC #F1F101 #2FFF43 #DF0F0F #5858FF #FFB950 #FF98F3 }[(field[y][x] || 0) - 1]
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
  get.call.each_with_index.any? do |row, dy|
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
    if num && (tick % 20).zero?
      y += 1
      if collision.call
        y -= 1
        draw.call true
        a, b = field.partition &:all?
        field = a.map{ Array.new width } + b
        num = nil
      end
    end

    unless num
      pats = [
        %w{ 1111    },
        %w{ 11  11  },
        %w{ 011 110 },
        %w{ 110 011 },
        %w{ 100 111 },
        %w{ 001 111 },
        %w{ 010 111 },
      ]
      num = rand 1..pats.size
      figure = pats[num - 1].map{ |st| st.chars.map &:to_i }
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

on :key_down do |event|
  semaphore.synchronize do
    case event.key
    when "left"  then move.call -1
    when "right" then move.call 1
    when "up"    then
      figure = figure.reverse.transpose
      figure = figure.transpose.reverse if collision.call
    end
  end
end
on :key_held do |event|
  case event.key
  when "down"
    semaphore.synchronize do
      y += 1
      y -= 1 if collision.call
    end
  end
end

show
