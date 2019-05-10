# frozen_string_literal: true



x = y = nil

width, height = 10, 20
field = Array.new(height){ Array.new width }

require "ruby2d"
render = lambda do
  block_margin = 1
  block_side = 25
  s = block_margin * 2 + block_side
  margin = 30
  w = margin * 2 + s * width
  h = margin * 2 + s * height
  Window.set width: w, height: h, title: "rbTris"
  Rectangle.new x: 0,      y: 0,      width: w,              height: h,              color: "#ABF8FC"
  Rectangle.new x: margin, y: margin, width: w - 2 * margin, height: h - 2 * margin, color: "black"
  blocks = Array.new(height) do |y|
    Array.new(width) do |x|
      Square.new x: margin + block_margin + s * x,
                 y: margin + block_margin + s * y,
                 size: block_side
    end
  end
  lambda do
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
  end
end.call

figure = num = nil
get = lambda do
  figure.map{ |row| row.map{ |i| i * num } }
end

collision = lambda do
  return true if y + figure.      size > height
  return true if x + figure.first.size > width
  get.call.each_with_index.any? do |row, dy|
    row.each_with_index.any? do |a, dx|
      !a.zero? && field[y + dy][x + dx]
    end
  end
end


draw = lambda do |f|
  get.call.map.with_index do |row, dy|
    row.each_index do |dx|
      next if row[dx].zero?
      field[y + dy][x + dx] = (row[dx] if f)
    end
  end
end

wait = 18

key_lock = false
tick = 0
update do
  key_lock = true
  tick += 1

  if num && (tick % wait).zero?
    draw.call false
    y += 1
    unless collision.call
      draw.call true
    else
      y -= 1
      draw.call true
      a, b = field.partition &:all?
      field = a.map{ Array.new width } + b
      wait = 18
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
    draw.call true
  end
  render.call
  key_lock = false
end

move = lambda do |dx|
  draw.call false
  x += dx
  x -= dx if x < 0 || collision.call
  draw.call true
end

on :key_down do |event|
  next if key_lock
  key_lock = true
  case event.key
  when "left"  then move.call -1
  when "right" then move.call 1
  when "up"    then
    draw.call false

    figure = figure.reverse.transpose
    figure = figure.transpose.reverse if collision.call

    draw.call true
  when "down"  then wait = 2
  end
  key_lock = false
end

show
