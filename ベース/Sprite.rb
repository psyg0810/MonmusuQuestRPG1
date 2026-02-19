=begin
=ベース/Sprite

ここではSpriteを中心に扱います


==更新履歴
  Date     Version Author Comment

=end

#==============================================================================
# ■ Sprite_Base
#==============================================================================
class Sprite_Base < Sprite
  #--------------------------------------------------------------------------
  # ○ アニメーションスプライトの作成
  #--------------------------------------------------------------------------
  def make_animation_sprites
    @ani_sprites = []
    if (@use_sprite || @animation.to_screen?) && !@@ani_spr_checker.include?(@animation)
      16.times do
        sprite = ::Sprite.new(viewport)
        sprite.visible = false
        @ani_sprites.push(sprite)
      end
      if @animation.position == 3
        @@ani_spr_checker.push(@animation)
      end
    end
    @ani_duplicated = @@ani_checker.include?(@animation)
    if !@ani_duplicated && @animation.position == 3
      @@ani_checker.push(@animation)
    end
  end    
  #--------------------------------------------------------------------------
  # ○ アニメーションスプライトの設定
  #     frame : フレームデータ（RPG::Animation::Frame）
  #--------------------------------------------------------------------------
  def animation_set_sprites(frame)
    cell_data = frame.cell_data
    @ani_sprites.each_with_index do |sprite, i|
      next unless sprite
      pattern = cell_data[i, 0]
      if !pattern || pattern < 0
        sprite.visible = false
        next
      end
      sprite.bitmap = pattern < 100 ? @ani_bitmap1 : @ani_bitmap2
      sprite.visible = true
      sprite.src_rect.set(pattern % 5 * 192,
        pattern % 100 / 5 * 192, 192, 192)
      if @ani_mirror
        sprite.x = @ani_ox - cell_data[i, 1]
        sprite.y = @ani_oy + cell_data[i, 2]
        sprite.angle = (360 - cell_data[i, 4])
        sprite.mirror = (cell_data[i, 5] == 0)
      else
        sprite.x = @ani_ox + cell_data[i, 1]
        sprite.y = @ani_oy + cell_data[i, 2]
        sprite.angle = cell_data[i, 4]
        sprite.mirror = (cell_data[i, 5] == 1)
      end
      sprite.z = self.z + 300 + i
      sprite.ox = 96
      sprite.oy = 96
      sprite.zoom_x = cell_data[i, 3] / 100.0
      sprite.zoom_y = cell_data[i, 3] / 100.0
      # アニメーションスプライトの拡大
      if @animation.position == 3
        zm = [Graphics.width.to_f / 544.0, Graphics.height.to_f / 416.0].max
        zm = 1.0 if zm < 1.0
        sprite.zoom_x *= zm
        sprite.zoom_y *= zm
      end
      sprite.opacity = cell_data[i, 6] * self.opacity / 255.0
      sprite.blend_type = cell_data[i, 7]
    end
  end
end

#==============================================================================
# ■ Sprite_Battler
#==============================================================================
class Sprite_Battler < Sprite_Base
  #--------------------------------------------------------------------------
  # ○ オブジェクト初期化
  #--------------------------------------------------------------------------
  def initialize(viewport, battler = nil)
    super(viewport)
    @battler = battler
    @battler_visible = false
    @effect_type = nil
    @effect_duration = 0
    init_visibility if @battler
  end    
  #--------------------------------------------------------------------------
  # ○ 転送元ビットマップの更新
  #--------------------------------------------------------------------------
  def update_bitmap
    new_bitmap = Cache.battler(@battler.battler_name, @battler.battler_hue)
    self.bitmap = new_bitmap if bitmap != new_bitmap
    # 死亡直後にspriteがhideになってしまう
  end
end

#==============================================================================
# ■ Spriteset_Battle
#==============================================================================
class Spriteset_Battle
  #--------------------------------------------------------------------------
  # ○ オブジェクト初期化
  #--------------------------------------------------------------------------
  def initialize
    create_viewports
    create_battleback1
    create_battleback2
    create_enemies
    create_actors
    create_pictures
    create_timer
    create_follower
    update
  end
  #--------------------------------------------------------------------------
  # ● 仲間化エネミースプライトの作成
  #--------------------------------------------------------------------------
  def create_follower
    @follower_sprite = Sprite_Follower.new(@viewport1)
  end
  #--------------------------------------------------------------------------
  # ○ 解放
  #--------------------------------------------------------------------------
  def dispose
    dispose_battleback1
    dispose_battleback2
    dispose_enemies
    dispose_actors
    dispose_pictures
    dispose_timer
    dispose_follower
    dispose_viewports
  end
  #--------------------------------------------------------------------------
  # ● 仲間化エネミースプライトの解放
  #--------------------------------------------------------------------------
  def dispose_follower
    @follower_sprite.dispose
  end
  #--------------------------------------------------------------------------
  # ○ フレーム更新
  #--------------------------------------------------------------------------
  def update
    update_battleback1
    update_battleback2
    update_enemies
    update_actors
    update_pictures
    update_timer
    update_follower
    update_viewports
  end
  #--------------------------------------------------------------------------
  # ● 仲間化エネミースプライトの更新
  #--------------------------------------------------------------------------
  def update_follower
    @follower_sprite.update
  end
end










