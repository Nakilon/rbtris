require "ruby2d"

wait = 18

class Tetromino
  attr_accessor :x, :y

  def initialize
    @pat = Array.new 4    # precalculated rotations
    pats = [
      %w{ 1111    },
      %w{ 11  11  },
      %w{ 011 110 },
      %w{ 110 011 },
      %w{ 100 111 },
      %w{ 001 111 },
      %w{ 010 111 },
    ]
    @num = rand 1..pats.size
    @pat[0] = pats.map{ |pt| pt.map{ |st| st.chars.map(&:to_i)} }[@num - 1]
    3.times do |i|
      @pat[i + 1] = @pat[i].reverse.transpose
    end

    @dir = 0
    @x, @y = 3, 0
  end

  def rotate n
    @dir = (@dir + n) % 4
  end

  def get
    @pat[@dir].map{ |row| row.map{ |i| i * @num } }
  end

  def width
    @pat[@dir].first.size
  end

  def height
    @pat[@dir].size
  end
end


width, height = 10, 20

block_side = 25

key_in = nil
blocks = nil
field = nil

render = lambda do
  height.times do |y|
    width.times do |x|
      blocks[y][x].color = %w{ #158FAC #F1F101 #2FFF43 #DF0F0F #5858FF #FFB950 #FF98F3 }[field[y][x] - 1]
      field[y][x].zero? ? blocks[y][x].remove : blocks[y][x].add
    end
  end
end

piece = nil
collision = nil
write_to_field = nil
birth = lambda do
  piece = Tetromino.new
  fail "game over" if collision.call
  write_to_field.call
end

write_to_field = lambda do
  x, y = piece.x, piece.y
  piece.get.map.with_index do |row, dy|
    row.each_index do |dx|
      field[y + dy][x + dx] = row[dx] unless row[dx].zero?
    end
  end
end

delete_from_field = lambda do
  x, y = piece.x, piece.y
  piece.get.map.with_index do |row, dy|
    row.each_index do |dx|
      field[y + dy][x + dx] = 0 unless row[dx].zero?
    end
  end
end

collision = lambda do
  x, y = piece.x, piece.y
  return true if y + piece.height > height || x + piece.width > width
  piece.get.map.each_with_index.any? do |row, dy|
    row.map.each_with_index.any? do |a, dx|
      a.nonzero? && field[y + dy][x + dx].nonzero?
    end
  end
end

move = lambda do |dx|
  delete_from_field.call
  piece.x += dx
  piece.x -= dx if piece.x < 0 || collision.call
  write_to_field.call
end


block_margin = 1
margin = 30
s = block_margin * 2 + block_side
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
field = Array.new(height){ Array.new(width){ 0 } }

key_in = true


t = 1
check_delete = false
down_flag = false
key_lock = false

on :key_down do |event|
  next if key_lock || !key_in || down_flag
  key_lock = true
  case event.key
  when "left"  then move.call -1
  when "right" then move.call 1
  when "up"    then
    delete_from_field.call
    piece.rotate 1
    piece.rotate -1 if collision.call
    write_to_field.call
  when "down"  then wait = 2
  end
  key_lock = false
end

birth.call
render.call

update do
  key_lock = true
  if (t % wait).zero? && !down_flag
    key_in = false
    delete_from_field.call
    tt = false
    piece.y += 1
    if collision.call
      piece.y -= 1
      tt = true
    end
    write_to_field.call
    key_in = true
    down_flag = tt
  end

  if (check_delete || down_flag) && (t % 30).zero?
    check_delete = height.times.any? do |y|
      next unless field[y].all? &:nonzero?
      key_in = false
      field.delete_at y
      field.unshift Array.new width, 0
      true
    end
    unless check_delete
      wait = 18
      down_flag = false
      birth.call
      key_in = true
    end
  end

  t += 1
  render.call
  key_lock = false
end

show
