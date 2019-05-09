require "ruby2d"

Wait = 18

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

class Field
  Width, Height = 10, 20

  Margin = 30
  BlockMargin = 1
  BlockSide = 25

  attr_accessor :key_in

  def initialize
    s = BlockMargin * 2 + BlockSide
    w = Margin * 2 + s * Width
    h = Margin * 2 + s * Height

    Window.set width: w, height: h, title: "rbTris"
    Rectangle.new x: 0,      y: 0,      width: w,              height: h,              color: "#ABF8FC"
    Rectangle.new x: Margin, y: Margin, width: w - 2 * Margin, height: h - 2 * Margin, color: "black"

    @blocks = Array.new(Height) do |y|
      Array.new(Width) do |x|
        Square.new x: Margin + BlockMargin + s * x,
                   y: Margin + BlockMargin + s * y,
                   size: BlockSide, color: "red", z: 10
      end
    end
    @field = Array.new(Height){ Array.new(Width){ 0 } }

    @key_in = true
  end

  def render
    Height.times do |y|
      Width.times do |x|
        @blocks[y][x].color = %w{ #158FAC #F1F101 #2FFF43 #DF0F0F #5858FF #FFB950 #FF98F3 }[@field[y][x] - 1]
        @field[y][x].zero? ? @blocks[y][x].remove : @blocks[y][x].add
      end
    end
  end

  def birth
    @piece = Tetromino.new
    fail "game over" if collision?
    write_to_field
  end

  def write_to_field
    x, y = @piece.x, @piece.y
    @piece.get.map.with_index do |row, dy|
      row.each_index do |dx|
        @field[y + dy][x + dx] = row[dx] unless row[dx].zero?
      end
    end
  end

  def delete_from_field
    x, y = @piece.x, @piece.y
    @piece.get.map.with_index do |row, dy|
      row.each_index do |dx|
        @field[y + dy][x + dx] = 0 unless row[dx].zero?
      end
    end
  end

  def one_down
    @key_in = false
    delete_from_field
    down_flag = false
    @piece.y += 1
    if collision?
      @piece.y -= 1
      down_flag = true
    end
    write_to_field
    @key_in = true
    return down_flag
  end

  def collision?
    x, y = @piece.x, @piece.y
    return true if y + @piece.height > Height || x + @piece.width > Width
    @piece.get.map.each_with_index.any? do |row, dy|
      row.map.each_with_index.any? do |a, dx|
        a.nonzero? && @field[y + dy][x + dx].nonzero?
      end
    end
  end

  def delete_blocks
    Height.times.any? do |y|
      next unless @field[y].all? &:nonzero?
      @key_in = false
      @field.delete_at y
      @field.unshift Array.new Width, 0
      true
    end
  end

  def move dx
    delete_from_field
    @piece.x += dx
    @piece.x -= dx if @piece.x < 0 || collision?
    write_to_field
  end

  def rotate
    delete_from_field
    @piece.rotate 1
    @piece.rotate -1 if collision?
    write_to_field
  end
end


f = Field.new
t = 1
check_delete = false
down_flag = false
key_lock = false
wait = Wait

on :key_down do |event|
  next if key_lock || !f.key_in || down_flag
  key_lock = true
  case event.key
  when "left"  then f.move -1
  when "right" then f.move 1
  when "up"    then f.rotate
  when "down"  then wait = 2
  end
  key_lock = false
end

on :controller_button_down do |event|
  next if key_lock || !f.key_in || down_flag
  key_lock = true
  case event.button
  when :left  then f.move -1
  when :right then f.move 1
  when :a     then f.rotate
  when :down  then wait = 2
  end
  key_lock = false
end

f.birth
f.render

update do
  key_lock = true
  down_flag = f.one_down if (t % wait).zero? && !down_flag

  if (check_delete || down_flag) && (t % 30).zero?
    check_delete = f.delete_blocks
    unless check_delete
      wait = Wait
      down_flag = false
      f.birth
      f.key_in = true
    end
  end

  t += 1
  f.render
  key_lock = false
end

show
