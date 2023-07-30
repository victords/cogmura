require_relative 'constants'

include MiniGL

class IsoBlock
  IMG_SLICE_OFFSET = Graphics::TILE_WIDTH / 2
  FADE_DURATION = 15.0

  TYPE_MAP = [
    [1, 1, 1, :block1, 0, 0, false],
    [4, 6, 7, :house1, -10, -40, false],
    [3, 3, 7, :house2, -10, -64, false],
    [1, 1, 15, :tree1, -128, 0, false],
    [3, 2, 2, :bed1, 0, -16, false],
    [1, 1, 7, :bedtable1, 0, 48, false],
    [1, 10, 7, :wall1, 0, -32, false],
    [6, 1, 7, :wall2, 0, -32, false],
    [4, 1, 7, :wall3, 0, 0, false],
    [1, 1, 7, :wall4, 0, 0, false],
    [1, 2, 7, :rack1, -4, 96, false],
    [2, 2, 2, :table1, 0, 0, false],
  ].freeze

  attr_reader :x, :y, :z, :w, :h, :height, :ramps, :z_index

  def initialize(type, col, row, layer = 0, x_tiles = 1, y_tiles = 1, height = 999, angled = false)
    x_tiles, y_tiles, height, img_id, img_gap_x, img_gap_y, angled =
      type ? TYPE_MAP[type] : [x_tiles, y_tiles, height, nil, 0, 0, angled]

    layer ||= 0
    unit = Physics::UNIT
    # in case of angled blocks, collision will be checked against the ramps
    @x = angled ? -10000 : col * unit
    @y = row * unit
    @z = layer * Physics::V_UNIT
    @w = x_tiles * unit
    @h = y_tiles * unit
    @col = col
    @row = row
    @height = height * Physics::V_UNIT
    @x_tiles = x_tiles
    @y_tiles = y_tiles

    image = img_id && Res.img("block_#{img_id}")
    if angled
      @img = image
      @z_index = col + row + (layer / 3) + 3
      @ramps = []
      x = col * unit
      (0...x_tiles).each do |i|
        @ramps << Ramp.new(x + i * unit, @y - i * unit, unit, unit, true, false)
        @ramps << Ramp.new(x + (y_tiles + i) * unit, @y + (y_tiles - i) * unit, unit, unit, false, true)
      end
      (0...y_tiles).each do |i|
        @ramps << Ramp.new(x + i * unit, @y + (i + 1) * unit, unit, unit, true, true)
        @ramps << Ramp.new(x + (x_tiles + i) * unit, @y + (i - x_tiles + 1) * unit, unit, unit, false, false)
      end
    elsif image
      @imgs = (0...(x_tiles + y_tiles - 1)).map do |i|
        img_gap_offset = i == 0 ? 0 : -img_gap_x
        x = (i >= x_tiles ? (i + 1) : i) * IMG_SLICE_OFFSET + img_gap_offset
        w = i == x_tiles + y_tiles - 2 ? image.width - x :
              (i == x_tiles - 1 ? 2 : 1) * IMG_SLICE_OFFSET + (i == 0 ? -img_gap_x : 0)
        image.subimage(x, 0, w, image.height)
      end
      @z_index = 100 * (col + row + x_tiles + y_tiles - 2) + 10 * layer
    end
    @img_gap = Vector.new(img_gap_x, img_gap_y)

    @alpha = 255
  end

  def passable; false; end

  def bounds
    Rectangle.new(@x, @y, @w, @h)
  end

  def height_level
    ((@z + @height) / Physics::V_UNIT).floor
  end

  def intersect?(obj)
    if @ramps
      @ramps.any? { |r| r.intersect?(obj) }
    else
      bounds.intersect?(obj)
    end
  end

  def draw(map, man)
    pos = map.get_screen_pos(@col, @row)
    if @img
      x = pos.x + @img_gap.x
      y = pos.y + Graphics::TILE_HEIGHT / 2 - @z - @height + @img_gap.y + Graphics::V_OFFSET
      behind = man_behind(man, x, x + @img.width, y, @z_index)
      update_alpha(behind)
      color = (@alpha << 24) | 0xffffff
      @img.draw(x, y, @z_index, 1, 1, color)
    elsif @imgs
      x = pos.x - ((@y_tiles - 1) * Graphics::TILE_WIDTH / 2)
      y = pos.y - @z - @height + @img_gap.y + Graphics::V_OFFSET
      behind =
        (0...@imgs.size).any? do |i|
          x1 = x + (i >= @x_tiles ? (i + 1) : i) * Graphics::TILE_WIDTH / 2 + (i == 0 ? @img_gap.x : 0)
          x2 = x1 + @imgs[i].width
          man_behind(man, x1, x2, y, @z_index - 100 * (i + 1 - @x_tiles).abs)
        end
      update_alpha(behind)
      color = (@alpha << 24) | 0xffffff
      @imgs.each_with_index do |img, i|
        img.draw(x + (i >= @x_tiles ? (i + 1) : i) * Graphics::TILE_WIDTH / 2 + (i == 0 ? @img_gap.x : 0), y,
          @z_index - 100 * (i + 1 - @x_tiles).abs, 1, 1, color)
      end
    end
  end

  private

  def man_behind(man, x1, x2, y, z_index)
    return false unless man.active
    man.screen_x - man.img_gap.x + man.w > x1 && man.screen_x - man.img_gap.x < x2 && man.screen_y + man.img_size.y - 10 > y &&
      man.z_index < z_index && man.z < @z + @height
  end

  def update_alpha(behind)
    @alpha -= 127 / FADE_DURATION if behind && @alpha > 128
    @alpha += 127 / FADE_DURATION if !behind && @alpha < 255
    @alpha = @alpha.round
  end
end
