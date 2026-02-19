
=begin

もんむす・くえすと！ＲＰＧ
　トリス修正R  ver3  2015/04/15



機能一覧　説明は下　このverで新規追加したものは●　変更したものは○　削除は×
・IDReserve.rbの198行目 PRIORITY の機能を削除
・スキル画面で4+↑↓でスキルタイプ並べ替え　4+2でリセット
・スキル画面で使用不可なタイプも選択してスキル確認可能
・メモの <解説追加:xxx> がある場合、特殊効果情報にはそれ以外の情報を表示しない
・引継ぎ不能な体験版のセーブデータをロードした時、その旨を表示して強制終了
・装備を選択していない時に装備詳細情報を4ボタンで更新するとエラーになったのを修正
○アイテムのお気に入り登録　5ボタンで登録/解除、6ボタンで登録したもののみ表示
・<踏みとどまり N%> の効果を1戦闘で1度だけ発動するように
・<武器スキル倍率強化 N-M-L,...> でスキルMではなくスキルタイプMを強化するよう修正
●ショップの個数入力時は、右側ウィンドウに操作説明と情報を表示しない


機能　説明
・アイテムのお気に入り登録　5ボタンで登録/解除、6ボタンで登録したもののみ表示
　この機能は「アイテム、装備、戦闘」画面でのみ有効
　また「アイテム、装備、戦闘、店系」画面での「所持アイテム一覧ウィンドウ」では
　　登録アイテムが緑色で表示される

=end

#==============================================================================
# ■ Window_SkillList
#==============================================================================
class Window_SkillList < Window_Selectable
  #--------------------------------------------------------------------------
  # ● 公開インスタンス変数
  #--------------------------------------------------------------------------
  attr_accessor :stype_unusable
  #--------------------------------------------------------------------------
  # ● 選択項目の有効状態を取得
  #--------------------------------------------------------------------------
  def current_item_enabled?
    enable?(@data[index]) && !@stype_unusable
  end
  #--------------------------------------------------------------------------
  # ● アイテム名の描画
  #     enabled : 有効フラグ。false のとき半透明で描画
  #--------------------------------------------------------------------------
  def draw_item_name(item, x, y, enabled = true, width = 236)
    return unless item
    draw_icon(item.icon_index, x, y, enabled)
    color = @stype_unusable ? bad_color : normal_color
    change_color(color, enabled)
    draw_text(x + 24, y, width, line_height, item.name)
  end
end
#==============================================================================
# ■ Window_SkillCommand
#==============================================================================
class Window_SkillCommand < Window_Command
  #--------------------------------------------------------------------------
  # ● 選択項目の有効状態を取得
  #--------------------------------------------------------------------------
  def current_item_enabled?
    return true
  end
  #--------------------------------------------------------------------------
  # ● フレーム更新
  #--------------------------------------------------------------------------
  def update
    super
    if @skill_window
      @skill_window.stype_unusable = !current_data[:enabled]
      @skill_window.stype_id = current_ext
    end
  end
  #--------------------------------------------------------------------------
  # ● カーソルの移動可能判定
  #--------------------------------------------------------------------------
  def cursor_movable?
    super && !Input.press?(:X)
  end
  #--------------------------------------------------------------------------
  # ● 決定やキャンセルなどのハンドリング処理
  #--------------------------------------------------------------------------
  def process_handling
    return unless open? && active
    return process_swap(-1)    if Input.press?(:X)   && Input.repeat?(:UP)
    return process_swap( 1)    if Input.press?(:X)   && Input.repeat?(:DOWN)
    return process_clear_swap  if Input.press?(:X)   && Input.trigger?(:B)
    return process_ok       if ok_enabled?        && Input.trigger?(:C)
    return process_cancel   if cancel_enabled?    && Input.trigger?(:B)
    return process_pagedown if handle?(:pagedown) && Input.trigger?(:R)
    return process_pageup   if handle?(:pageup)   && Input.trigger?(:L)
    return process_sub      if Input.trigger?(:A)
  end
  #--------------------------------------------------------------------------
  # ● サブキー(Aボタン)が押されたときの処理
  #--------------------------------------------------------------------------
  def process_sub
    Sound.play_ok
    Input.update
    @actor.flip_skill_type_disabled(current_ext)
    refresh
  end
  #--------------------------------------------------------------------------
  # ● 並べ替えの処理
  #--------------------------------------------------------------------------
  def process_swap(plus)
    Input.update
    target = index + plus
    return Sound.play_buzzer unless (0..item_max-1).include?(target)
    Sound.play_equip
    @actor.swap_stype_sort(@list[index][:ext], @list[target][:ext])
    refresh
    select(target)
  end
  #--------------------------------------------------------------------------
  # ● 並べ替えリセットの処理
  #--------------------------------------------------------------------------
  def process_clear_swap
    Sound.play_equip
    Input.update
    last_ext = current_ext
    @actor.clear_stype_sort
    refresh
    select_ext(last_ext)
  end
  #--------------------------------------------------------------------------
  # ● 項目の描画
  #--------------------------------------------------------------------------
  def draw_item(index)
    super(index)
    return unless @actor.skill_type_disabled?(@list[index][:ext])
    change_color(bad_color, command_enabled?(index))
    draw_text(item_rect_for_text(index), "封", 2)
  end
  #--------------------------------------------------------------------------
  # ● 使用可能なスキルタイプ？（そのタイプのスキルを習得している）
  #--------------------------------------------------------------------------
  def stype_usable?(stype_id)
    @actor.skills.any?{|skill| skill.stype_id == stype_id}
  end
  #--------------------------------------------------------------------------
  # ○ コマンドリストの作成
  #--------------------------------------------------------------------------
  def make_command_list
    return unless @actor
    all_skill_types = @actor.skills.collect{|skill| skill.stype_id}.uniq
    all_skill_types.reject!{|stype_id| NWConst::Ability::ABILITY_SKILL_TYPE.include?(stype_id)}
    enable_skill_types = @actor.added_skill_types
    enable_skill_types.reject!{|stype_id| @actor.skill_type_sealed?(stype_id)}
    
    all_skill_types.select{|stype_id|
      stype_usable?(stype_id)
    }.tap {|stypes|
      break @actor.sorted_stypes(stypes)
    }.each{|stype_id|
      name = $data_system.skill_types[stype_id]
      add_command(name, :skill, enable_skill_types.include?(stype_id), stype_id)
    }
  end
end
#==============================================================================
# ■ Window_ActorCommand
#==============================================================================
class Window_ActorCommand < Window_Command
  #--------------------------------------------------------------------------
  # ○ スキルコマンドをリストに追加
  #--------------------------------------------------------------------------
  def add_skill_commands
    @actor.added_skill_types.sort.select{|stype_id|
      stype_usable?(stype_id)
    }.tap {|stypes|
      break @actor.sorted_stypes(stypes)
    }.each{|stype_id|
      name = $data_system.skill_types[stype_id]
      add_command(name, :skill, true, stype_id)
    }
  end
  #--------------------------------------------------------------------------
  # ● 使用可能なスキルタイプ？（そのタイプのスキルを習得しており非表示でない）
  #--------------------------------------------------------------------------
  def stype_usable?(stype_id)
    @actor.skills.any?{|skill| skill.stype_id == stype_id} &&
    !($game_system.conf[:bt_stype] && @actor.skill_type_disabled?(stype_id))
  end
end

#==============================================================================
# ■ Scene_Skill
#==============================================================================
class Scene_Skill < Scene_ItemBase
  #--------------------------------------------------------------------------
  # ● 操作ヘルプウィンドウの生成 ベース/Scene 139 toris
  #--------------------------------------------------------------------------
  def create_key_help_window
    @key_help_window = Window_Help_Color.new(2)
    @key_help_window.y = Graphics.height - @key_help_window.height
    @key_help_window.viewport = @viewport
    @key_help_window.set_text(Help.skill_type_key)
  end
  #--------------------------------------------------------------------------
  # ● 使用可能なスキルタイプ？（そのタイプのスキルを習得しており非表示でない）
  #--------------------------------------------------------------------------
  def update
    super
    @key_help_window.set_text(Help.skill_type_key)
  end
end
#==============================================================================
# ■ Window_Help_Color
#==============================================================================
class Window_Help_Color < Window_Help
  #--------------------------------------------------------------------------
  # ● リフレッシュ
  #--------------------------------------------------------------------------
  def refresh
    contents.clear
    x = 4
    y = 0
    @text.lines{|text| draw_text_ex(4, y, text); y += line_height}
  end
end
#==============================================================================
# ■ Help
#==============================================================================
class << Help
  #--------------------------------------------------------------------------
  # ● スキル画面の下部ヘルプメッセージ ベース/Module 239
  #--------------------------------------------------------------------------
  def skill_type_key
    t = ""
    t += "\\C[0]"
    t += "#{Vocab.key_a}:戦闘中非表示＆自動戦闘で不使用"
    t += "（※現在、コンフィグで無効）" unless $game_system.conf[:bt_stype]
    t += "\n"
    t += "\\C[16]" if Input.press?(:X)
    t += "#{Vocab.key_x}＋↑/↓:スキルタイプ並べ替え　"
    t += "#{Vocab.key_x}＋#{Vocab.key_b}:スキルタイプ位置リセット"
    return t
  end
end
#==============================================================================
# ■ Game_Actor
#==============================================================================
class Game_Actor < Game_Battler
  #--------------------------------------------------------------------------
  # ○ スキルタイプ配列に並べ替えを適用
  #--------------------------------------------------------------------------
  def sorted_stypes(stypes)
    @stype_sort ||= {}
    a = stypes
    b = stypes.sort_by {|stype| @stype_sort[stype] ? @stype_sort[stype] : stype }
    stypes.sort_by {|stype| @stype_sort[stype] ? @stype_sort[stype] : stype }
  end
  #--------------------------------------------------------------------------
  # ○ スキルタイプ並べ替えを実行
  #--------------------------------------------------------------------------
  def swap_stype_sort(a, b)
    @stype_sort ||= {}
    @stype_sort[a] ||= a
    @stype_sort[b] ||= b
    @stype_sort[a], @stype_sort[b] = @stype_sort[b], @stype_sort[a]
  end
  #--------------------------------------------------------------------------
  # ○ スキルタイプ並べ替えをリセット
  #--------------------------------------------------------------------------
  def clear_stype_sort
    @stype_sort = {}
  end
end

#==============================================================================
# ■ RPG::BaseItem
#==============================================================================
class RPG::BaseItem
  #--------------------------------------------------------------------------
  # ● エンチャント名配列の取得
  #--------------------------------------------------------------------------  
  def enchant_names
    names = []
    
    method_table = {
      FEATURE_ELEMENT_RATE      => :element_rate_name,
      FEATURE_DEBUFF_RATE       => :debuff_rate_name,
      FEATURE_STATE_RATE        => :state_rate_name,
      FEATURE_STATE_RESIST      => :state_resist_name,
      FEATURE_PARAM             => :param_name,
      FEATURE_XPARAM            => :xparam_name,
      FEATURE_SPARAM            => :sparam_name,
      FEATURE_ATK_ELEMENT       => :atk_element_name,
      FEATURE_ATK_STATE         => :atk_state_name,
      FEATURE_ATK_SPEED         => :atk_speed_name,
      FEATURE_ATK_TIMES         => :atk_times_name,
      FEATURE_STYPE_ADD         => :stype_add_name,
      FEATURE_STYPE_SEAL        => :stype_seal_name,
      FEATURE_EQUIP_WTYPE       => :equip_wtype_name,
      FEATURE_EQUIP_ATYPE       => :equip_atype_name,
      FEATURE_EQUIP_FIX         => :equip_fix_name,
      FEATURE_EQUIP_SEAL        => :equip_seal_name,
      FEATURE_SLOT_TYPE         => :slot_type_name,
      FEATURE_ACTION_PLUS       => :action_plus_name,
      FEATURE_SPECIAL_FLAG      => :special_flag_name,
      FEATURE_COLLAPSE_TYPE     => :collaplse_type_name,
      FEATURE_PARTY_ABILITY     => :party_ability_name,
      FEATURE_XPARAM_EX         => :xparam_ex_name,
      FEATURE_PARTY_EX_ABILITY  => :party_ex_ability_name,
      FEATURE_BATTLER_ABILITY   => :battler_ability_name,
      FEATURE_MULTI_BOOSTER     => :multi_booster_name,
      FEATURE_DUMMY_ENCHANT     => :dummy_enchant_name,  
      FEATURE_TERRAIN_BOOSTER   => :terrain_booster_name,
    }
    
    dummy = nil
    self.features.sort_by{|ft| [ft.code, ft.data_id]}.each{|ft|
      method_name = method_table[ft.code]
      if method_name == :dummy_enchant_name
        dummy ||= []
        dummy.push(send(method_name, ft))
      elsif method_name
        names.push(send(method_name, ft))
      end
    }
    names = dummy if dummy
    return names.flatten.compact.uniq
  end
end


#==============================================================================
# ■ Scene_Map
#==============================================================================
class Scene_Map < Scene_Base
  #--------------------------------------------------------------------------
  # ● 開始処理
  #--------------------------------------------------------------------------
  alias :trial_error_start :start
  def start
    trial_error_start
    return process_trial_error if $game_system.party_lose_count.nil?
  end
  #--------------------------------------------------------------------------
  # ● 引継ぎ不能時の処理
  #--------------------------------------------------------------------------
  def process_trial_error
    text = "このセーブデータは、引継ぎ不能な体験版で作成されたものです"
    text += "\n製品版では使用できないので、ニューゲームから開始してください"
    msgbox text
    SceneManager.exit
  end
end


#==============================================================================
# ■ FavoriteItem
#==============================================================================
module FavoriteItem
  #--------------------------------------------------------------------------
  # ○ 選択中のアイテムのお気に入り状態を変更
  #--------------------------------------------------------------------------
  def process_set_favorite_item
    Input.update
    return Sound.play_buzzer if @item_window.item.nil?
    Sound.play_ok
    @item_window.set_favorite_item
    @item_window.refresh
    if !@item_window.include?(@item_window.item) and @item_window.index > 0
      @item_window.select(@item_window.index - 1)
    end
  end
  #--------------------------------------------------------------------------
  # ○ お気に入り表示モードを変更
  #--------------------------------------------------------------------------
  def process_change_favorite_mode
    Input.update
    Sound.play_ok
    last_item = @item_window.item
    @item_window.change_favorite_mode
    @item_window.refresh
    if @item_window.active
      @item_window.select_item(last_item)
    else
      @item_window.select(-1)
    end
  end
  #--------------------------------------------------------------------------
  # ○ フレーム更新
  #--------------------------------------------------------------------------
  def update
    if enable_set_favorite_item?
      return process_set_favorite_item if Input.trigger?(:Y)
    end
    if enable_change_favorite_mode?
      return process_change_favorite_mode if Input.trigger?(:Z)
    end
    if off_favorite_mode? and @item_window.favorite_mode
      @item_window.change_favorite_mode
    end
    super
  end
  #--------------------------------------------------------------------------
  # ○ 可否　選択中のアイテムのお気に入り状態を変更
  #--------------------------------------------------------------------------
  def enable_set_favorite_item?
    false
  end
  #--------------------------------------------------------------------------
  # ○ 可否　お気に入り表示モードを変更
  #--------------------------------------------------------------------------
  def enable_change_favorite_mode?
    false
  end
  #--------------------------------------------------------------------------
  # ○ 有無　お気に入り表示モードをオフ
  #--------------------------------------------------------------------------
  def off_favorite_mode?
    !@item_window.visible
  end
end
#==============================================================================
# ■ Window_ItemList
#==============================================================================
class Window_ItemList < Window_Selectable
  #--------------------------------------------------------------------------
  # ○ 指定されたアイテムにカーソルを移動　なければ0番にカーソルを移動
  #--------------------------------------------------------------------------
  def select_item(s_item)
    @data.each_with_index do |d_item, i|
      return select(i) if s_item == d_item
    end
    return select(0)
  end
end
#==============================================================================
# ■ Scene_Item
#==============================================================================
class Scene_Item < Scene_ItemBase
  include FavoriteItem
  #--------------------------------------------------------------------------
  # ○ 可否　選択中のアイテムのお気に入り状態を変更
  #--------------------------------------------------------------------------
  def enable_set_favorite_item?
    @item_window.active
  end
  #--------------------------------------------------------------------------
  # ○ 可否　お気に入り表示モードを変更
  #--------------------------------------------------------------------------
  def enable_change_favorite_mode?
    @item_window.active or @category_window.active
  end
end
#==============================================================================
# ■ Scene_Equip
#==============================================================================
class Scene_Equip < Scene_MenuBase
  include FavoriteItem
  #--------------------------------------------------------------------------
  # ○ 可否　選択中のアイテムのお気に入り状態を変更
  #--------------------------------------------------------------------------
  def enable_set_favorite_item?
    @item_window.active
  end
  #--------------------------------------------------------------------------
  # ○ 可否　お気に入り表示モードを変更
  #--------------------------------------------------------------------------
  def enable_change_favorite_mode?
    @item_window.active or @slot_window.active
  end
end
#==============================================================================
# ■ Scene_Battle
#==============================================================================
class Scene_Battle < Scene_Base
  include FavoriteItem
  #--------------------------------------------------------------------------
  # ○ 可否　選択中のアイテムのお気に入り状態を変更
  #--------------------------------------------------------------------------
  def enable_set_favorite_item?
    @item_window.active
  end
  #--------------------------------------------------------------------------
  # ○ 可否　お気に入り表示モードを変更
  #--------------------------------------------------------------------------
  def enable_change_favorite_mode?
    @item_window.active
  end
end
#==============================================================================
# ■ Window_ItemList
#==============================================================================
class Window_ItemList < Window_Selectable
  #--------------------------------------------------------------------------
  # ● 公開インスタンス変数
  #--------------------------------------------------------------------------
  attr_reader   :favorite_mode            # お気に入りモード
  #--------------------------------------------------------------------------
  # ○ 選択中のアイテムのお気に入り状態を取得
  #--------------------------------------------------------------------------
  def get_favorite_item_state
    $game_party.favorite_item?(item)
  end
  #--------------------------------------------------------------------------
  # ○ 選択中のアイテムのお気に入り状態を変更
  #--------------------------------------------------------------------------
  def set_favorite_item
    $game_party.set_favorite_item(item)
  end
  #--------------------------------------------------------------------------
  # ○ お気に入り表示モードを変更
  #--------------------------------------------------------------------------
  def change_favorite_mode
    @favorite_mode = !@favorite_mode
  end
  #--------------------------------------------------------------------------
  # ● アイテムリストの作成
  #--------------------------------------------------------------------------
  def make_item_list
    @data = $game_party.all_items.select {|item| include?(item) }
    @data.reject! {|item| !$game_party.favorite_item?(item) } if @favorite_mode
    @data.push(nil) if include?(nil)
  end
  #--------------------------------------------------------------------------
  # ● アイテム名の描画
  #     enabled : 有効フラグ。false のとき半透明で描画
  #--------------------------------------------------------------------------
  def draw_item_name(item, x, y, enabled = true, width = 236)
    return unless item
    draw_icon(item.icon_index, x, y, enabled)
    color = $game_party.favorite_item?(item) ? tp_gauge_color2 : normal_color
    change_color(color, enabled)
    draw_text(x + 24, y, width, line_height, item.name)
  end
end
#==============================================================================
# ■ Game_Party
#==============================================================================
class Game_Party < Game_Unit
  #--------------------------------------------------------------------------
  # ○ アイテムのお気に入りキー
  #--------------------------------------------------------------------------
  def favorite_key(item)
    return [:item,   item.id] if item.is_a?(RPG::Item)
    return [:weapon, item.id] if item.is_a?(RPG::Weapon)
    return [:armor,  item.id] if item.is_a?(RPG::Armor)
    return nil
  end
  #--------------------------------------------------------------------------
  # ○ アイテムのお気に入り状態を変更
  #--------------------------------------------------------------------------
  def set_favorite_item(item)
    return if item.nil?
    key = favorite_key(item)
    symbol = key[0]
    id = key[1]
    @favorite_item ||= {}
    @favorite_item[symbol] ||= []
    @favorite_item[symbol][id] = !@favorite_item[symbol][id]
  end
  #--------------------------------------------------------------------------
  # ○ お気に入りかどうか
  #--------------------------------------------------------------------------
  def favorite_item?(item)
    return nil if item.nil?
    key = favorite_key(item)
    symbol = key[0]
    id = key[1]
    @favorite_item ||= {}
    @favorite_item[symbol] ||= []
    return @favorite_item[symbol][id]
  end
end

#==============================================================================
# ■ Game_Battler
#==============================================================================
class Game_Battler < Game_BattlerBase  
  #--------------------------------------------------------------------------
  # ● 戦闘用カウンターのクリア
  #--------------------------------------------------------------------------  
  def clear_counter
    @cnt = {}
    @cnt[:dead_skill] = []
    @cnt[:defense_wall] = []
    @cnt[:auto_stand] = false
  end  
  #--------------------------------------------------------------------------
  # ● 戦闘用カウンターのセット
  #--------------------------------------------------------------------------  
  def set_counter
    @cnt[:dead_skill] = dead_skill ? [dead_skill] : []
    @cnt[:defense_wall] = defense_wall ? [true] * defense_wall : []
    @cnt[:auto_stand] = true
  end
  #--------------------------------------------------------------------------
  # ● 踏みとどまりの適用
  #--------------------------------------------------------------------------
  def apply_stand(damage, item)
    return damage if hp == 1
    return damage unless hp <= damage
    return damage unless mhp * auto_stand < hp
    return damage if item.damage.recover?
    return damage unless @cnt[:auto_stand]
    @cnt[:auto_stand] = false
    @result.auto_stand = true
    return hp - 1
  end
  #--------------------------------------------------------------------------
  # ● ブースター補正率の取得
  #--------------------------------------------------------------------------
  def boost_rate(user, item, is_cnt)
    value  = 1.0
    value *= user.final_elements(item).inject(1.0){|max, id| max = max > user.booster_element(id) ? max : user.booster_element(id)}
    value *= 1.0 + (user.friends_unit.dead_members.size * user.considerate)
    value *= 1.0 + (user.friends_unit.dead_members.size * item.considerate_revise)
    user.wtypes.each{|id| value *= item.weapon_rate(id)}
    value *= user.pha if item.apply_pharmacology?
    value *= user.booster_counter if is_cnt
    
    user.wtypes.each do |wtype_id|
      case item.hit_type
      when 0; value *= user.booster_weapon_certain(wtype_id)
      when 1; value *= user.booster_weapon_physical(wtype_id)
      when 2; value *= user.booster_weapon_magical(wtype_id)
      end
    end
    if item.is_skill?
      use_wtypes = user.wtypes.empty? ? [0] : user.wtypes
      use_wtypes.each do |wtype_id|
        value *= user.booster_wtype_skill(wtype_id, item)
        if item == $data_skills[user.attack_skill_id]
          value *= user.booster_normal_attack(wtype_id)
        end
      end
      value *= user.booster_skill_type(item)
      value *= user.booster_skill(item)
    end
    return value
  end
end
#==============================================================================
# ■ Game_BattlerBase
#==============================================================================
class Game_BattlerBase
  #--------------------------------------------------------------------------
  # ● 武器スキル強化倍率を取得
  #--------------------------------------------------------------------------
  def booster_wtype_skill(wtype_id, skill)
    1.0 + skill.stypes.inject(0.0) do |sum, stype_id|
      sum + features_sum_booster(WTYPE_SKILL, [wtype_id, stype_id])
    end
  end
end


#==============================================================================
# ■ Window_ShopStatus
#==============================================================================
class Window_ShopStatus < Window_Base
  #--------------------------------------------------------------------------
  # ● ウィンドウの非アクティブ化
  #--------------------------------------------------------------------------
  def deactivate
    super
    refresh
  end
  #--------------------------------------------------------------------------
  # ○ リフレッシュ
  #--------------------------------------------------------------------------
  def refresh
    contents.clear
    return if @item.nil?
    draw_possession(4, 0)
    return unless self.active
    return if @item.is_a?(RPG::Item)
    draw_button(0, contents.height - (line_height * 2))
    return if page_max == 0
    method_name = draw_methods[@page_index][:name]
    index = draw_methods[@page_index][:index]
    send(method_name, 0, 28, index)    
  end
end
