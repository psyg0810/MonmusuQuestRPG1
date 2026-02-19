
=begin

もんむす・くえすと！ＲＰＧ
　トリス修正O  ver8  2015/03/21



機能一覧　説明は下　このverで新規追加したものは●　変更したものは○
・戦闘後の仲間加入時にそのアクターを初期化
・ポーカーとスロットの役の倍率設定を変更
・スロットの役表示を、小さい役から役ごとに一括表示(チェリーは３種同時)
・キャラ図鑑/魔物図鑑のＣＧ閲覧の終了時、「BGMの保存」のBGMが再開されたのを修正
・魔物図鑑の敗北回想の開始時、「BGMの保存」が行われたのを修正
・説明の１行目が 【○○】 だけのものの図鑑解説が 。 で始まっていたのを修正
・降参開始時に全アクターと全生存エネミーの全ステートを解除
・全エネミー画像を非表示にするイベントコマンド
●降参開始からの強制敗北ターンを20ターンから10ターンに


機能　説明

・スロットの役表示を、小さい役から役ごとに一括表示(チェリーは３種同時)
　チェリー３種、プラム、ベル……の順番で表示する
　（「ライン矢印の強調表示」と「役一覧ウインドウの強調表示」の２つ）
　またチェリーの表示時のみ、役一覧ウインドウの各役（３種）に当たった個数を表示

・全エネミー画像を非表示にするイベントコマンド
　イベントコマンドのスクリプトで以下の「」内のものを記述
　　「 battler_graphic_hide 」非表示をオン
　　「 battler_graphic_show 」非表示をオフ＝表示する


=end

#==============================================================================
# ■ BattleManager
#==============================================================================
class << BattleManager
  #--------------------------------------------------------------------------
  # ● 仲間加入時の承諾処理
  #--------------------------------------------------------------------------  
  def process_follow_ok(follower_name = nil)
    e = $game_troop.follower_enemy
    follower_name = e.original_name unless follower_name
    e.follow_yes_word.execute
    wait_for_message
    $game_message.add("#{follower_name}が仲間に加わった！")
    wait_for_message
    if $game_party.party_member_max <= $game_party.all_members.size
      $game_message.add("パーティは満員です")
      $game_message.add("待機させるメンバーを選んでください")
      wait_for_message
      choice = 0
      members = $game_party.all_members.reject{|actor| actor.luca?}
      members.each{|actor| $game_message.choices.push(actor.name)}
      $game_message.choices.push(follower_name)
      $game_message.choice_cancel_type = $game_party.party_member_max
      $game_message.choice_proc = Proc.new {|n| choice = n }
      wait_for_message
      if choice < $game_party.party_member_max - 1
        $game_party.move_stand_actor(members[choice].id)
        wait_member_name = members[choice].name
      else
        wait_member_name = follower_name
      end
      $game_message.add("#{wait_member_name}はポケット魔王城に向かった！")
      wait_for_message
    end
    # 仲間になったエネミーを保存
    $game_actors[e.follower_actor_id].setup(e.follower_actor_id)
    $game_party.add_actor(e.follower_actor_id)
    $game_temp.getup_enemy = e.follower_actor_id
    $game_switches[NWConst::Sw::ADD_ACTOR_BASE + e.follower_actor_id] = true
  end
end

#==============================================================================
# ■ Scene_Library
#==============================================================================
class Scene_Library < Scene_MenuBase
  #--------------------------------------------------------------------------
  # ● 魔物：回想イベント
  #--------------------------------------------------------------------------
  def on_memory_event
    $game_temp.lib_enemy_index = @main_command_window.index
    if NWConst::Library::MEMORY_BG_IMAGE.key?(@enemy_command_window.enemy.id)
      $game_novel.bg_data = NWConst::Library::MEMORY_BG_IMAGE[@enemy_command_window.enemy.id]
    else
      $game_novel.bg_data = {:pic => NWConst::Library::DEFAULT_MEMORY_BG_IMAGE}
    end
    $game_novel.setup(@enemy_command_window.enemy.lose_event_id)
    SceneManager.call(Scene_Novel)
  end
end
#==============================================================================
# ■ Scene_Library
#==============================================================================
class Scene_Library < Scene_MenuBase
  #--------------------------------------------------------------------------
  # ● ウィンドウの設定準備
  #--------------------------------------------------------------------------
  def window_setting
    if $game_temp.lib_enemy_index != -1
      play_bgm_no_save
      @main_command_window.category = $game_temp.lib_enemy_index < 10000 ? 2 : 1
      @main_command_window.refresh
      @main_command_window.select($game_temp.lib_enemy_index % 10000)
      @main_command_window.activate
      $game_temp.lib_enemy_index = -1
    else
      @main_command_window.select(0)
      @main_command_window.activate
    end
  end
  #--------------------------------------------------------------------------
  # ● 直前BGMの保存を行わずに図鑑BGMの演奏　敗北回想からの復帰用
  #--------------------------------------------------------------------------
  def play_bgm_no_save
    NWConst::Library::BGM.play
    RPG::BGS.stop
  end
end

#==============================================================================
# ■ Window_Library_RightMain
#==============================================================================
class Window_Library_RightMain < Window_Selectable
  #--------------------------------------------------------------------------
  # ● 描画共通部分(武器, 防具, アクセサリ, アイテム)
  #--------------------------------------------------------------------------
  def draw_items_common(item)
    rect = standard_rect
    reset_font_settings
    # アイテム名の描画
    draw_item_name(item, rect.x, rect.y)
    rect.y = self.contents.height - (line_height * 5)
    
    # 解説の描画
    change_color(system_color)
    draw_text(rect, "解説")
    rect.y += rect.height
    change_color(normal_color)
    all_text = ""
    item.description.each_line do |d|
      d.slice!(/【\S+】/)
      d.chomp!
      next if d == ""
      all_text += d
      all_text += "。" unless all_text[-1] == "。"
    end
    rect = draw_text_auto_line(rect, all_text)
    
    return line_height + LINE_HEIGHT
  end
end

#==============================================================================
# ■ BattleManager
#==============================================================================
class << BattleManager
  #--------------------------------------------------------------------------
  # ● 降参
  #--------------------------------------------------------------------------  
  def giveup
    @giveup = true
    @giveup_count = 10
    $game_party.clear_actions
    $game_party.all_members.reject {|m| m.luca? }.each {|m| m.hide }
    ($game_party.all_members + $game_troop.alive_members).each {|m| m.clear_states }
    luca_index = 0
    $game_party.all_members.each_with_index do |actor, i|
      luca_index = (actor.luca? ? i : luca_index)
    end
    $game_party.swap_order(0, luca_index)
  end
end

#==============================================================================
# ■ Sprite_Battler
#==============================================================================
class Sprite_Battler < Sprite_Base
  #--------------------------------------------------------------------------
  # ● 転送元ビットマップの更新 ベース/Sprite 100
  #--------------------------------------------------------------------------
  def update_bitmap
    if $game_temp.battler_graphic_hide
      return if @battler_graphic_hide
      @battler_graphic_hide = true
      bitmap_name = ""
    else
      @battler_graphic_hide = false
      bitmap_name = @battler.battler_name
    end
    new_bitmap = Cache.battler(bitmap_name, @battler.battler_hue)
    self.bitmap = new_bitmap if bitmap != new_bitmap
  end
end
#==============================================================================
# ■ Game_Temp
#==============================================================================
class Game_Temp
  #--------------------------------------------------------------------------
  # ● 公開インスタンス変数
  #--------------------------------------------------------------------------
  attr_accessor :battler_graphic_hide
end
#==============================================================================
# ■ Game_Interpreter
#==============================================================================
class Game_Interpreter
  #--------------------------------------------------------------------------
  # ● バトラー画像非表示オン
  #--------------------------------------------------------------------------
  def battler_graphic_hide
    $game_temp.battler_graphic_hide = true
  end
  #--------------------------------------------------------------------------
  # ● バトラー画像非表示オフ
  #--------------------------------------------------------------------------
  def battler_graphic_show
    $game_temp.battler_graphic_hide = false
  end
end

#==============================================================================
# ◆ 設定項目 娯楽/ポーカー改造
#==============================================================================
module CAO::Poker
  #--------------------------------------------------------------------------
  # ◇ 掛け金の増加量 ( n 倍)
  #--------------------------------------------------------------------------
  DIVIDEND_COVER = [0, 1, 2, 3, 5, 7, 10, 30, 50, 100, 300]
end
#==============================================================================
# ■ NWConst::Slot
#==============================================================================
module NWConst::Slot
  # 役　娯楽/スロット 27
  BONUS = {
    [-1, -1, -1] => {
      :desc  => "表示する予定はありません",
      :scale => 0,
      :sound => NWConst::Casino::SE_LOSE,
      :skill_id => 3270,
      :medal => nil,
    },  
    [0, -1, -1] => {
      :desc  => "チェリーです",
      :scale => 1,
      :sound => NWConst::Casino::SE_WIN1,
      :skill_id => 3270,
      :medal => nil,
    },  
    [0, 0, -1] => {
      :desc  => "チェリーです",
      :scale => 2,
      :sound => NWConst::Casino::SE_WIN1,
      :skill_id => 3270,
      :medal => nil,
    },  
    [0, 0, 0] => {
      :desc  => "チェリーです",
      :scale => 5,
      :sound => NWConst::Casino::SE_WIN1,
      :skill_id => 3271,
      :medal => nil,
    },
    [1, 1, 1] => {
      :desc  => "プラムです",
      :scale => 20,
      :sound => NWConst::Casino::SE_WIN2,
      :skill_id => 3272,
      :medal => nil,
    },
    [2, 2, 2] => {
      :desc  => "ベルです",
      :scale => 50,
      :sound => NWConst::Casino::SE_WIN2,
      :skill_id => 3273,
      :medal => nil,
    },
    [3, 3, 3] => {
      :desc  => "スイカです",
      :scale => 100,
      :sound => NWConst::Casino::SE_WIN3,
      :skill_id => 3274,
      :medal => nil,
    },
    [4, 4, 4] => {
      :desc  => "ＢＡＲです",
      :scale => 200,
      :sound => NWConst::Casino::SE_WIN3,
      :skill_id => 3275,
      :medal => nil,
    },
    [5, 5, 5] => {
      :desc  => "７７７です",
      :scale => 500,
      :sound => NWConst::Casino::SE_WIN4,
      :skill_id => 3276,
      :medal => NWConst::Casino::MEDAL_SLOT,
    },
  } 
end


#==============================================================================
# ■ CasinoManager
#==============================================================================
class << CasinoManager
  #--------------------------------------------------------------------------
  # ● 結果処理　娯楽/スロット 1035
  #--------------------------------------------------------------------------
  def slot_result
    hash = {}
    CasinoManager.bet_num.times do |i|
      $game_slot.check_bonus(NWConst::Slot::LINES[i])
      next if $game_slot.result_scale == 0
      hash[$game_slot.result_bonus[0]] ||= []
      hash[$game_slot.result_bonus[0]].push(i)
    end
    result = []
    hash.keys.sort.each do |key|
      result.push(hash[key])
    end
    return result
  end
end
#==============================================================================
# ■ Scene_Slot
#==============================================================================
class Scene_Slot < Scene_CasinoBase
  #--------------------------------------------------------------------------
  # ● 結果処理　娯楽/スロット 1035
  #--------------------------------------------------------------------------
  def process_result
    CasinoManager.slot_result.each do |bonus_lines|
      gain_coin = 0
      desc_text = nil
      sound = nil
      bonuses = []
      bonus_lines.each do |line_index|
        $game_slot.check_bonus(NWConst::Slot::LINES[line_index])
        CasinoManager.process_medal(:slot, $game_slot.result_medal, 0)
        bonuses.push($game_slot.result_bonus)
        gain_coin += CasinoManager.minimum_coin * $game_slot.result_scale
        desc_text = $game_slot.result_desc
        sound = $game_slot.result_sound
      end
      @spriteset.set_line_number(bonus_lines)
      @bonus_window.cursor_keys = bonuses
      $game_party.gain_coin(gain_coin)
      @desc_window.set_text(desc_text + "\n#{gain_coin}枚獲得しました！")
      CasinoManager.process_sound(:slot, sound, method(:abs_wait))
      @bonus_window.cursor_keys = []
    end
    
    @spriteset.set_line_number([])
    $game_slot.clear_result
    @desc_window.set_text(Help.slot_description[:stand])
    change_phase(:stand)
  end
end
#==============================================================================
# ■ Scene_Battle
#==============================================================================
class Scene_Battle < Scene_Base
  #--------------------------------------------------------------------------
  # ● スロットの処理 娯楽/スロット 1061
  #--------------------------------------------------------------------------
  def process_slot
    $game_slot.clear
    CasinoManager.setup(0)
    CasinoManager.add_line
    slot_spriteset = Spriteset_Slot.new
    @battleslot_bonus_window = Window_BattleSlotBonus.new
    
    $game_slot.rolling_start
    while $game_slot.rolling?
      update_basic
      $game_slot.update
      $game_slot.rolling_stop if Input.trigger?(:C)
      slot_spriteset.update
    end
    
    abs_wait(6)
    result_skill_id = 1
    sound = NWConst::Casino::SE_LOSE
    
    CasinoManager.bet_num.times do |i|
      $game_slot.check_bonus(NWConst::Slot::LINES[i])
      if result_skill_id < $game_slot.result_skill_id
        sound = $game_slot.result_sound
        result_skill_id = $game_slot.result_skill_id
        @battleslot_bonus_window.select_key = $game_slot.result_bonus
        slot_spriteset.set_line_number([i]) if $game_slot.result_bonus[0] >= 0
      end
      CasinoManager.process_medal(:slot, $game_slot.result_medal, 1)
    end
    CasinoManager.process_sound(:slot, sound, method(:abs_wait))
    
    slot_spriteset.dispose
    @battleslot_bonus_window.dispose
    remove_instance_variable(:@battleslot_bonus_window)
    
    return result_skill_id
  end
end
#==============================================================================
# ■ Spriteset_Slot
#==============================================================================
class Spriteset_Slot
  #--------------------------------------------------------------------------
  # ● ライン番号スプライトの強調
  #--------------------------------------------------------------------------
  def set_line_number(index)
    color1 = Color.new(255, 255, 255, 128)
    color2 = Color.new(0, 0, 0, 0)
    @line_number_sprites.each_with_index do |sprite, i|
      sprite.color = index.include?(i) ? color1 : color2
    end
  end
end
#==============================================================================
# ■ Window_SlotBonusShow
#==============================================================================
class Window_SlotBonusShow < Window_SlotBonus
  #--------------------------------------------------------------------------
  # ● オブジェクト初期化
  #-------------------------------------------------------------------------
  def initialize(key, base)
    @base_window = base
    super()
    self.z = base.z + 1
    self.opacity = 0
    @key = key
  end
  #--------------------------------------------------------------------------
  # ● ウィンドウ幅の取得
  #--------------------------------------------------------------------------
  def window_width
    return @base_window.width
  end
  #--------------------------------------------------------------------------
  # ● 子ウインドウの作成
  #--------------------------------------------------------------------------
  def make_show_windows
    @show_windows = []
  end
  #--------------------------------------------------------------------------
  # ● 更新処理
  #--------------------------------------------------------------------------
  def update
    super
    if @base_window.cursor_keys.include?(@key)
      self.cursor_rect.set(rect_cursor(@key))
    else
      self.cursor_rect.empty
    end
  end
  #--------------------------------------------------------------------------
  # ● リフレッシュ
  #--------------------------------------------------------------------------
  def refresh
    contents.clear
  end
end
#==============================================================================
# ■ Window_SlotBonus
#==============================================================================
class Window_SlotBonus < Window_Base
  #--------------------------------------------------------------------------
  # ● オブジェクト初期化
  #--------------------------------------------------------------------------
  def initialize
    super(Graphics.width - window_width, 0, window_width, window_height)
    self.contents.font.name =  ["ＭＳ ゴシック"]
    @cursor_keys = []
    make_list
    refresh
    make_show_windows
  end
  #--------------------------------------------------------------------------
  # ● 子ウインドウの作成
  #--------------------------------------------------------------------------
  def make_show_windows
    @show_windows = []
    @list.keys.each do |key|
      @show_windows.push(Window_SlotBonusShow.new(key, self))
    end
  end
  #--------------------------------------------------------------------------
  # ● 更新処理
  #--------------------------------------------------------------------------
  def update
    super
    @show_windows.each {|w| w.update }
  end
  #--------------------------------------------------------------------------
  # ● 解放
  #--------------------------------------------------------------------------
  def dispose
    super
    @show_windows.each {|w| w.dispose }
  end
  #--------------------------------------------------------------------------
  # ● カーソル位置キー取得
  #--------------------------------------------------------------------------
  def cursor_keys
    @cursor_keys
  end
  #--------------------------------------------------------------------------
  # ● カーソル位置キー設定とリフレッシュ
  #--------------------------------------------------------------------------
  def cursor_keys=(k)
    @cursor_keys = k
    refresh
  end
  #--------------------------------------------------------------------------
  # ● 役の描画
  #--------------------------------------------------------------------------
  def draw_bonus
    change_color(normal_color)
    bitmap = Cache.casino("slot_panels")
    @list.reverse_each do |key, value|
      rect = rect_bonus(key)
      draw_bonus_panels(rect, key, bitmap)
      draw_bonus_scale(rect, value[:scale])
      if key[0] == 0 and @cursor_keys.count(key) >= 1
        rect.x += 100
        draw_text(rect, sprintf("×%d", @cursor_keys.count(key)))
      end
    end
    bitmap.dispose
  end
end
#==============================================================================
# ■ Window_BattleSlotBonus
#==============================================================================
class Window_BattleSlotBonus < Window_SlotBonus
  #--------------------------------------------------------------------------
  # ● カーソル位置のキー
  #--------------------------------------------------------------------------
  def cursor_keys
    [@select_key]
  end
end