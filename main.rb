# based on https://gist.github.com/obelisk68/15ffdf1bfd82953361be0264b5ea4119


require "ruby2d"
include Ruby2D::DSL

Wait = 18

class Tetromino
  def initialize
    @pat = Array.new(4)
    pats = [["1111"], ["11", "11"], ["011", "110"], ["110", "011"],
            ["100", "111"], ["001", "111"], ["010", "111"]]
    @num = rand(1..pats.size)
    @pat[0] = pats.map {|pt| pt.map {|st| st.chars.map(&:to_i)} }[@num - 1]
    3.times do |i|
      @pat[i + 1] = @pat[i].reverse.transpose    #右回転
    end
    
    @dir = 0
    @x, @y = 3, 0
  end
  attr_accessor :x, :y
  
  def rotate(n)
    @dir = (@dir + n) % 4
  end
  
  def get
    @pat[@dir].map {|row| row.map {|i| i * @num} }
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
  S = BlockMargin * 2 + BlockSide
  W = Margin * 2 + S * Width
  H = Margin * 2 + S * Height
  
  Color = ["#158FAC", "#F1F101", "#2FFF43", "#DF0F0F",
           "#5858FF", "#FFB950", "#FF98F3"]
  
  def initialize
    set width: W, height: H, title: "Tetris Ruby2D"
    Rectangle.new x: 0, y: 0, width: W, height: H, color: "#ABF8FC", z: 0
    Rectangle.new x: Margin, y: Margin,
                  width: W - 2 * Margin, height: H - 2 * Margin,
                  color: "black", z: 0
    
    @blocks = Height.times.map do |y|
      Width.times.map do |x|
        Square.new x: Margin + BlockMargin + S * x,
                   y: Margin + BlockMargin + S * y,
                   size: BlockSide, color: "red", z: 10
      end
    end
    
    @field = @blocks.map {|row| row.map {0}}
    @key_in = true
  end
  attr_accessor :key_in
  
  def render
    Height.times do |y|
      Width.times do |x|
        @blocks[y][x].color = Color[@field[y][x] - 1]
        @field[y][x].nonzero? ? @blocks[y][x].add : @blocks[y][x].remove
      end
    end
  end
  
  def birth
    @piece = Tetromino.new
    collision? ? raise("game over") : write_to_field
  end
  
  def write_to_field
    x, y = @piece.x, @piece.y
    @piece.get.map.with_index do |row, dy|
      row.each_index {|dx| @field[y + dy][x + dx] = row[dx] if row[dx].nonzero?}
    end
  end
  
  def delete_from_field
    x, y = @piece.x, @piece.y
    @piece.get.map.with_index do |row, dy|
      row.each_index {|dx| @field[y + dy][x + dx] = 0 if row[dx].nonzero?}
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
    @piece.get.map.with_index do |row, dy|
      row.map.with_index {|a, dx| a.nonzero? && @field[y + dy][x + dx].nonzero?}.any?
    end.any?
  end
  
  def delete_blocks
    Height.times do |y|
      if @field[y].all?(&:nonzero?)
        @key_in = false
        @field.delete_at(y)
        @field.unshift(Array.new(Width, 0))
        return true  
      end
    end
    false
  end
  
  def move(dx)
    delete_from_field
    @piece.x += dx
    @piece.x -= dx if @piece.x < 0 || collision?
    write_to_field
  end
  
  def rotate
    delete_from_field
    @piece.rotate(1)
    @piece.rotate(-1) if collision?
    write_to_field
  end
end


f = Field.new
t = 1
check_delete = false    #ブロックを消す作業が終っていなければtrue
down_flag = false       #これ以上落下できなければtrue
key_lock = false
wait = Wait

on :key_down do |event|
  unless key_lock || !f.key_in || down_flag
    key_lock = true
    case event.key
    when "left"  then f.move(-1)
    when "right" then f.move(1)
    when "up"    then f.rotate
    when "down"  then wait = 2
    end
    key_lock = false
  end
end

on :controller_button_down do |event|
  unless key_lock || !f.key_in || down_flag
    key_lock = true
    case event.button
    when :left  then f.move(-1)
    when :right then f.move(1)
    when :a     then f.rotate
    when :down  then wait = 2
    end
    key_lock = false
  end
end

f.birth
f.render
    
update do
  key_lock = true
  down_flag = f.one_down if (t % wait).zero? && !down_flag    #ひとつ落下
  
  #消せる行があれば一行消す
  if (check_delete || down_flag) && (t % 30).zero?
    check_delete = f.delete_blocks
    #すべて消し終わったあとの処理
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
