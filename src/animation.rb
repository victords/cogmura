module Animation
  def start_sequence(*steps)
    @sequence = steps
    @sequence_step = 0
    @sequence_timer = @sequence[0][:timer] || 0
  end

  def update_sequence
    return unless @sequence

    step = @sequence[@sequence_step]
    move_free(step[:target], step[:speed] || 1) if step[:target]
    animate(step[:indices], step[:interval] || 7) if step[:indices]
    @sequence_timer -= 1 if @sequence_timer > 0
    if step[:timer] && @sequence_timer == 0 ||
      step[:target] && @speed.x == 0 && @speed.y == 0
      step[:callback]&.call
      @sequence_step += 1
      if @sequence_step == @sequence.size
        @sequence = nil
      else
        step = @sequence[@sequence_step]
        set_animation(step[:indices][0]) if step[:indices]
        @flip = step[:flip] || false
        @sequence_timer = step[:timer] || 0
      end
    end
  end
end