# frozen_string_literal: true


pats = [
  %w{ 1111    },
  %w{ 11  11  },
  %w{ 011 110 },
  %w{ 110 011 },
  %w{ 100 111 },
  %w{ 001 111 },
  %w{ 010 111 },
]
num = dir = nil

rotated = lambda do
  pat = pats[num - 1].map{ |st| st.chars.map &:to_i }
  dir.times do
    pat = pat.reverse.transpose
  end
  pat
end

get = lambda do
  rotated.call.map{ |row| row.map{ |i| i * num } }
end


x = y = nil

width, height = 10, 20
field = Array.new(height){ Array.new(width){ 0 } }

write_to_field = lambda do
  get.call.map.with_index do |row, dy|
    row.each_index do |dx|
      next if row[dx].zero?
      field[y + dy][x + dx] = row[dx]
    end
  end
end
delete_from_field = lambda do
  get.call.map.with_index do |row, dy|
    row.each_index do |dx|
      next if row[dx].zero?
      field[y + dy][x + dx] = 0
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
  Rectangle.new x: 0,      y: 0,      width: w,              height: h,              color: "#ABF8FC"
  Rectangle.new x: margin, y: margin, width: w - 2 * margin, height: h - 2 * margin, color: "black"
  blocks = Array.new(height) do |y|
    Array.new(width) do |x|
      Square.new x: margin + block_margin + s * x,
                 y: margin + block_margin + s * y,
                 size: block_side, color: "red", z: 10
    end
  end
  lambda do
    height.times do |y|
      width.times do |x|
        blocks[y][x].color = %w{ #158FAC #F1F101 #2FFF43 #DF0F0F #5858FF #FFB950 #FF98F3 }[field[y][x] - 1]
        field[y][x].zero? ? blocks[y][x].remove : blocks[y][x].add
      end
    end
  end
end.call

collision = lambda do
  return true if y + rotated.call.      size > height
  return true if x + rotated.call.first.size > width
  get.call.map.each_with_index.any? do |row, dy|
    row.map.each_with_index.any? do |a, dx|
      a.nonzero? && field[y + dy][x + dx].nonzero?
    end
  end
end


wait = 18

key_in = true

new_tetromino = lambda do
  x, y, dir = 3, 0, 0
  num = rand 1..pats.size
end
new_tetromino.call

write_to_field.call
render.call
key_lock = false
tick = 0
update do
  key_lock = true
  tick += 1

  if (tick % wait).zero?
    key_in = false
    delete_from_field.call
    tt = false
    y += 1
    if collision.call
      y -= 1
      tt = true
    end
    write_to_field.call
    key_in = true
    if tt
      a, b = field.partition{ |row| row.none? &:zero? }
      field = a.map{ Array.new width, 0 } + b
        wait = 18
        new_tetromino.call
        fail "game over" if collision.call
        write_to_field.call
    end
  end

  render.call
  key_lock = false
end

move = lambda do |dx|
  delete_from_field.call
  x += dx
  x -= dx if x < 0 || collision.call
  write_to_field.call
end

on :key_down do |event|
  next if key_lock || !key_in
  key_lock = true
  case event.key
  when "left"  then move.call -1
  when "right" then move.call 1
  when "up"    then
    delete_from_field.call

    old = dir
    dir = (dir + 1) % 4
    dir = old if collision.call

    write_to_field.call
  when "down"  then wait = 2
  end
  key_lock = false
end

show
