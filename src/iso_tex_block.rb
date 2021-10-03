require_relative 'iso_block'

include MiniGL

class IsoTexBlock < IsoBlock
  IMG_SLICE_OFFSET = Graphics::TILE_WIDTH / 2 / Graphics::SCALE

  def initialize(col, row, x_tiles, y_tiles, height, img, img_gap, angled = false)
    super(col, row, height, angled)
    unit = Physics::UNIT
    @w = x_tiles * unit
    @h = y_tiles * unit
    @x_tiles = x_tiles
    @y_tiles = y_tiles
    image = Res.img(img)

    if angled
      @img = image
      @z_index = col + row + 3
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
    else
      @img = nil
      @imgs = (0...(x_tiles + y_tiles - 1)).map do |i|
        img_gap_offset = i == 0 ? 0 : -img_gap.x / Graphics::SCALE
        x = (i >= x_tiles ? (i + 1) : i) * IMG_SLICE_OFFSET + img_gap_offset
        w = i == x_tiles + y_tiles - 2 ? image.width - x :
              (i == x_tiles - 1 ? 2 : 1) * IMG_SLICE_OFFSET + (i == 0 ? -img_gap.x / Graphics::SCALE : 0)
        image.subimage(x, 0, w, image.height)
      end
      @z_index = @col + @row + @x_tiles + @y_tiles - 1
      @ramps = nil
    end
    @img_gap = img_gap
  end

  def draw(map)
    pos = map.get_screen_pos(@col, @row)
    if @img
      x = pos.x + @img_gap.x
      y = pos.y + Graphics::TILE_HEIGHT / 2 - @height * Physics::V_UNIT + @img_gap.y
      @img.draw(x, y, @z_index, Graphics::SCALE, Graphics::SCALE)
    else
      x = pos.x - ((@y_tiles - 1) * Graphics::TILE_WIDTH / 2)
      y = pos.y - @height * Physics::V_UNIT + @img_gap.y
      @imgs.each_with_index do |img, i|
        img.draw(x + (i >= @x_tiles ? (i + 1) : i) * Graphics::TILE_WIDTH / 2 + (i == 0 ? @img_gap.x : 0), y,
                 @z_index - (i + 1 - @x_tiles).abs, Graphics::SCALE, Graphics::SCALE)
      end
    end
  end
end
