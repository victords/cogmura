include MiniGL

class IsoTexBlock < Block
  IMG_SLICE_OFFSET = Graphics::TILE_WIDTH / 2 / Graphics::SCALE

  attr_reader :height

  def initialize(col, row, x_tiles, y_tiles, height, img, img_gap)
    super(col * Physics::UNIT, row * Physics::UNIT, x_tiles * Physics::UNIT, y_tiles * Physics::UNIT)
    @col = col
    @row = row
    @x_tiles = x_tiles
    @y_tiles = y_tiles
    @height = height
    image = Res.img(img)
    @imgs = (0...(x_tiles + y_tiles - 1)).map do |i|
      img_gap_offset = i == 0 ? 0 : -img_gap.x / Graphics::SCALE
      x = (i >= x_tiles ? (i + 1) : i) * IMG_SLICE_OFFSET + img_gap_offset
      w = i == x_tiles + y_tiles - 2 ? image.width - x :
            (i == x_tiles - 1 ? 2 : 1) * IMG_SLICE_OFFSET + (i == 0 ? -img_gap.x / Graphics::SCALE : 0)
      image.subimage(x, 0, w, image.height)
    end
    @img_gap = img_gap
    @z_index = @col + @row + @x_tiles + @y_tiles - 1
  end

  def draw(map)
    pos = map.get_screen_pos(@col, @row)
    x = pos.x - ((@y_tiles - 1) * Graphics::TILE_WIDTH / 2)
    y = pos.y - @height * Physics::V_UNIT + @img_gap.y
    @imgs.each_with_index do |img, i|
      img.draw(x + (i >= @x_tiles ? (i + 1) : i) * Graphics::TILE_WIDTH / 2 + (i == 0 ? @img_gap.x : 0), y,
               @z_index - (i + 1 - @x_tiles).abs, Graphics::SCALE, Graphics::SCALE)
    end
  end
end
