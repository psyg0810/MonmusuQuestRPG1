
=begin

もんむす・くえすと！ＲＰＧ
　トリス修正Q  ver6  2015/03/31



機能一覧　説明は下　このverで新規追加したものは●　変更したものは○　削除は×
・add_actor_ex(N)でNがパーティにいる場合、何もしない
・add_actor_ex(N)でNが城待機メンバーにいる場合、城待機から外してパーティに加入
・魔王城のパーティ編成で城内ワープの確認中はソート不能に
・特定変数の値が1以上なら、特定イベントコマンドの敵番号をその値に強制変換
・ルカ以外のパーティメンバーを全て城待機にするスクリプトコマンド
・戦闘での「全員攻撃」コマンド
・自動戦闘で「追加されていないタイプ」「非表示タイプ」のスキルを使用しないように
・降参中のパラメータ弱体が次の戦闘開始まで続行したのを修正
・ニューゲーム時とロード時、特定スイッチをオンにする
●装備情報の特殊効果で、全く同じ情報は複数表示しないように
●装備情報の特殊効果で、<スティール成功率 N%>の変化値が表示されなかったのを修正
●スキル画面のタイプ選択中の下部説明に、自動戦闘不使用とコンフィグ無効表示を追加
●戦闘開始の時点で、敵を「発見済み」の状態にする
●戦闘中の魔物図鑑で、出現している敵を緑色にしてカーソル初期位置を合わせる


機能　説明

・add_actor_ex(N)でNが城待機メンバーにいる場合、城待機から外してパーティに加入
以前はこの場合、何もしなかった

・特定変数が1以上なら「変数：ゲームデータと条件分岐」の敵番号がその値に強制変換
変数IDは IDReserve.rb の EVENT_ENEMY_ID で指定
対象となるイベントコマンドは
　・『変数の操作』　オペランドを「ゲームデータ」の「敵キャラ」にした場合のみ
　・『条件分岐』　「敵キャラ」にした場合のみ（出現とステート）
　・『敵キャラのHP増減』～『アニメーション表示』　（3タブ目「バトル」内）
　・『戦闘行動の強制』　行動主体を敵キャラにした場合のみ

・ルカ以外のパーティメンバーを全て城待機にするスクリプトコマンド
イベントコマンドのスクリプトで move_stand_actors_except_luca と実行する

・自動戦闘で「追加されていないタイプ」「非表示タイプ」のスキルを使用しないように
「非表示タイプ」を使用しないのは、コンフィグで「設定通り」になっている場合のみ
　コンフィグで「全表示」になっている場合は、非表示タイプであっても使用する

・ニューゲーム時とロード時、特定スイッチをオンにする
スイッチIDは IDReserve.rb の ON_GAME_START で指定

●戦闘中の魔物図鑑で、出現している敵を緑色にしてカーソル初期位置を合わせる
　「勝利済み」でない敵は暗い緑色になる
　カーソル初期位置は「出現している敵の中で最も上にある項目」

=end

#==============================================================================
# ■ Game_Interpreter
#==============================================================================
class Game_Interpreter
  #--------------------------------------------------------------------------
  # ● 敵キャラ用イテレータ（インデックス）
  #--------------------------------------------------------------------------
  def convert_enemy_id(param)
    var_param = $game_variables[NWConst::Var::EVENT_ENEMY_ID] - 1
    return var_param >= 0 ? var_param : param
  end
  #--------------------------------------------------------------------------
  # ● 敵キャラ用イテレータ（インデックス）
  #     param : 0 以上ならインデックス、-1 なら全体
  #--------------------------------------------------------------------------
  def iterate_enemy_index(param)
    param = convert_enemy_id(param)
    if param < 0
      $game_troop.members.each {|enemy| yield enemy }
    else
      enemy = $game_troop.members[param]
      yield enemy if enemy
    end
  end
  #--------------------------------------------------------------------------
  # ● 変数オペランド用ゲームデータの取得
  #--------------------------------------------------------------------------
  def game_data_operand(type, param1, param2)
    case type
    when 0  # アイテム
      return $game_party.item_number($data_items[param1])
    when 1  # 武器
      return $game_party.item_number($data_weapons[param1])
    when 2  # 防具
      return $game_party.item_number($data_armors[param1])
    when 3  # アクター
      actor = $game_actors[param1]
      if actor
        case param2
        when 0      # レベル
          return actor.level
        when 1      # 経験値
          return actor.exp
        when 2      # HP
          return actor.hp
        when 3      # MP
          return actor.mp
        when 4..11  # 通常能力値
          return actor.param(param2 - 4)
        end
      end
    when 4  # 敵キャラ
      enemy = $game_troop.members[ convert_enemy_id(param1) ]
      if enemy
        case param2
        when 0      # HP
          return enemy.hp
        when 1      # MP
          return enemy.mp
        when 2..9   # 通常能力値
          return enemy.param(param2 - 2)
        end
      end
    when 5  # キャラクター
      character = get_character(param1)
      if character
        case param2
        when 0  # X 座標
          return character.x
        when 1  # Y 座標
          return character.y
        when 2  # 向き
          return character.direction
        when 3  # 画面 X 座標
          return character.screen_x
        when 4  # 画面 Y 座標
          return character.screen_y
        end
      end
    when 6  # パーティ
      actor = $game_party.members[param1]
      return actor ? actor.id : 0
    when 7  # その他
      case param1
      when 0  # マップ ID
        return $game_map.map_id
      when 1  # パーティ人数
        return $game_party.members.size
      when 2  # ゴールド
        return $game_party.gold
      when 3  # 歩数
        return $game_party.steps
      when 4  # プレイ時間
        return Graphics.frame_count / Graphics.frame_rate
      when 5  # タイマー
        return $game_timer.sec
      when 6  # セーブ回数
        return $game_system.save_count
      when 7  # 戦闘回数
        return $game_system.battle_count
      end
    end
    return 0
  end
  #--------------------------------------------------------------------------
  # ○ 条件分岐
  #--------------------------------------------------------------------------
  def command_111
    result = false
    case @params[0]
    when 0  # スイッチ
      result = ($game_switches[@params[1]] == (@params[2] == 0))
    when 1  # 変数
      value1 = $game_variables[@params[1]]
      if @params[2] == 0
        value2 = @params[3]
      else
        value2 = $game_variables[@params[3]]
      end
      case @params[4]
      when 0  # と同値
        result = (value1 == value2)
      when 1  # 以上
        result = (value1 >= value2)
      when 2  # 以下
        result = (value1 <= value2)
      when 3  # 超
        result = (value1 > value2)
      when 4  # 未満
        result = (value1 < value2)
      when 5  # 以外
        result = (value1 != value2)
      end
    when 2  # セルフスイッチ
      if @event_id > 0
        key = [@map_id, @event_id, @params[1]]
        result = ($game_self_switches[key] == (@params[2] == 0))
      end
    when 3  # タイマー
      if $game_timer.working?
        if @params[2] == 0
          result = ($game_timer.sec >= @params[1])
        else
          result = ($game_timer.sec <= @params[1])
        end
      end
    when 4  # アクター
      actor = $game_actors[@params[1]]
      if actor
        case @params[2]
        when 0  # パーティにいる
          result = ($game_party.members.include?(actor))
        when 1  # 名前
          result = (actor.name == @params[3])
        when 2  # 職業
          result = (actor.class_id == @params[3])
        when 3  # スキル
          result = (actor.skill_learn?($data_skills[@params[3]]))
        when 4  # 武器
          result = (actor.weapons.include?($data_weapons[@params[3]]))
        when 5  # 防具
          result = (actor.armors.include?($data_armors[@params[3]]))
        when 6  # ステート
          result = (actor.state?(@params[3]))
        end
      end
    when 5  # 敵キャラ
      enemy = $game_troop.members[ convert_enemy_id(@params[1]) ]
      if enemy
        case @params[2]
        when 0  # 出現している
          result = (enemy.alive?)
        when 1  # ステート
          result = (enemy.state?(@params[3]))
        end
      end
    when 6  # キャラクター
      character = get_character(@params[1])
      if character
        result = (character.direction == @params[2])
      end
    when 7  # ゴールド
      case @params[2]
      when 0  # 以上
        result = ($game_party.gold >= @params[1])
      when 1  # 以下
        result = ($game_party.gold <= @params[1])
      when 2  # 未満
        result = ($game_party.gold < @params[1])
      end
    when 8  # アイテム
      result = $game_party.has_item?($data_items[@params[1]])
    when 9  # 武器
      result = $game_party.has_item?($data_weapons[@params[1]], @params[2])
    when 10  # 防具
      result = $game_party.has_item?($data_armors[@params[1]], @params[2])
    when 11  # ボタン
      result = Input.press?(@params[1])
    when 12  # スクリプト
      result = eval(@params[1])
    when 13  # 乗り物
      result = ($game_player.vehicle == $game_map.vehicles[@params[1]])
    end
    @branch[@indent] = result
    command_skip if !@branch[@indent]
  end
  #--------------------------------------------------------------------------
  # ● 拡張アクター加入
  #--------------------------------------------------------------------------
  def add_actor_ex(actor_id)
    return if $game_party.exist_actor_id?(actor_id)
    if party_members.size == 8
      $game_message.add("パーティはすでに満員です")
      $game_message.add("誰をパーティから外しますか？")
      members = party_members.reject{|actor| actor.luca?}
      names = members.collect{|actor| actor.name}
      names.push("いれかえない")
      choice = 0
      names.each { |name| $game_message.choices.push(name) }
      $game_message.choice_cancel_type = names.size
      $game_message.choice_proc = Proc.new {|n| choice = n }
      Fiber.yield while $game_message.choice?
      if choice < members.size
        move_stand_actor(members[choice].id)
      end
    end
    actor = $game_actors[actor_id]
    $game_party.add_actor(actor.id)
    $game_switches[NWConst::Sw::ADD_ACTOR_BASE + actor.id] = true
  end
  #--------------------------------------------------------------------------
  # ● ルカ以外を城待機に
  #--------------------------------------------------------------------------
  def move_stand_actors_except_luca
    party_members.each do |actor|
      move_stand_actor(actor.id) unless actor.luca?
    end
  end
end
#==============================================================================
# ■ Game_Party（nwapeg）
#==============================================================================
class Game_Party < Game_Unit
  #--------------------------------------------------------------------------
  # ○ アクターを加える　付随/多重人格
  #--------------------------------------------------------------------------
#  alias nw_persona_add_actor add_actor
  def add_actor(actor_id)
    if $game_party.exist_stand_actor_id?(actor_id)
      # まだ副人格統一に対応してません
      remove_stand_actor(actor_id)
    end
    return if @actors.any?{|id| $game_actors[id].id == $game_actors[actor_id].id}
    return if @stand_actors.any?{|id|$game_actors[id].id == $game_actors[actor_id].id}
    nw_persona_add_actor($game_actors[actor_id].id)
  end
end

#==============================================================================
# ■ Scene_PartyEdit
#==============================================================================
class Scene_PartyEdit < Scene_MenuBase
  #--------------------------------------------------------------------------
  # ● ソート表示ウィンドウの作成
  #--------------------------------------------------------------------------
  def create_sort_eval_window
    @sort_eval_window = Foo::PTEdit::Window_SortEval.new
    @sort_eval_window.set_all_refresh_method(method(:refresh_windows))
    @sort_eval_window.set_disable_method(method(:disable_sort?))
  end
  #--------------------------------------------------------------------------
  # ● ソート表示ウィンドウの作成
  #--------------------------------------------------------------------------
  def disable_sort?
    @popup_confirm_window.active
  end
end
#==============================================================================
# ■ Foo::PTEdit::Window_SortEval
#==============================================================================
class Foo::PTEdit::Window_SortEval < Window_Base
  #--------------------------------------------------------------------------
  # ● 無効メソッドの設定
  #--------------------------------------------------------------------------
  def set_disable_method(method)
    @disable_method = method
  end
  #--------------------------------------------------------------------------
  # ● ソート方法の切り替え
  #--------------------------------------------------------------------------
  def process_eval
    return unless Input.trigger?(:Y)
    return if @disable_method.call
    Input.update
    Sound.play_ok
    @eval_id = (@eval_id + 1) % eval_array.size
    @all_refresh_method.call unless @all_refresh_method.nil?
  end
end

#==============================================================================
# ■ Vocab
#==============================================================================
class << Vocab
  # パーティコマンド
  def all_attack;    "全員攻撃"; end
end
#==============================================================================
# ■ Window_PartyCommand
#==============================================================================
class Window_PartyCommand < Window_Command
  #--------------------------------------------------------------------------
  # ○ コマンドリストの作成
  #--------------------------------------------------------------------------
  def make_command_list
    add_command(Vocab::fight,       :fight)
    add_command(Vocab::shift_change,:shift_change, !$game_party.bench_members.empty?)
    add_command(Vocab::all_attack,  :all_attack)
    add_command(Vocab::escape,      :escape, BattleManager.can_escape?)
    add_command(Vocab::giveup,      :giveup, $game_party.all_members.any?{|member| member.luca?} && $game_actors[NWConst::Actor::LUCA].exist?)
    add_command(Vocab::library,     :library)
    add_command(Vocab::config,      :config)
  end
end
#==============================================================================
# ■ Scene_Battle
#==============================================================================
class Scene_Battle < Scene_Base
  #--------------------------------------------------------------------------
  # ○ パーティコマンドウィンドウの作成
  #--------------------------------------------------------------------------
  def create_party_command_window
    @party_command_window = Window_PartyCommand.new
    @party_command_window.viewport = @info_viewport
    @party_command_window.set_handler(:fight,  method(:command_fight))
    @party_command_window.set_handler(:escape, method(:command_escape))
    @party_command_window.set_handler(:all_attack, method(:command_all_attack))
    @party_command_window.set_handler(:shift_change, method(:command_shift_change))
    @party_command_window.set_handler(:giveup, method(:command_giveup))
    @party_command_window.set_handler(:library, method(:command_library))
    @party_command_window.set_handler(:config, method(:command_config))
    @party_command_window.unselect    
  end
  #--------------------------------------------------------------------------
  # ○ コマンド［全員攻撃］
  #--------------------------------------------------------------------------
  def command_all_attack
    $game_party.members.each do |actor|
      loop do
        break unless actor.inputable?
        actor.input.set_attack
        actor.input.target_index = $game_troop.alive_members[0].index
        break unless actor.next_command
      end
    end
    @info_viewport.visible = false
    turn_start
  end
end
#==============================================================================
# ■ Game_Actor
#==============================================================================
class Game_Actor
  #--------------------------------------------------------------------------
  # ● 自動戦闘用の行動候補リストを作成 ベース/GameObject 2124 toris
  #--------------------------------------------------------------------------
  def make_action_list
    list = []
    list.push(Game_Action.new(self).set_attack.evaluate)
    skills.each do |skill|
      
    end
    usable_skills.each do |skill|
      next if skill.no_auto_battle?
      next unless skill.stypes.any? {|type| added_skill_types.include?(type) }
      if $game_system.conf[:bt_stype]
        next unless skill.stypes.any? {|type| !skill_type_disabled?(type) }
      end
      list.push(Game_Action.new(self).set_skill(skill.id).evaluate)
    end
    list.push(Game_Action.new(self).set_attack.evaluate) if list.empty?
    list
  end
end

#==============================================================================
# ■ BattleManager
#==============================================================================
class << BattleManager
  #--------------------------------------------------------------------------
  # ○ 戦闘終了　ベース/Module
  #     result : 結果（0:勝利 1:逃走 2:敗北）
  #--------------------------------------------------------------------------
  def battle_end(result)
    @phase = nil
    @giveup = false
    @event_proc.call(result) if @event_proc
    $game_temp.reserve_common_event(NWConst::Common::BATTLE_END) #
    $game_party.on_battle_end
    $game_troop.on_battle_end
    SceneManager.exit if $BTEST
  end
  #--------------------------------------------------------------------------
  # ○ 戦闘終了　図鑑/カウント　統合時は消す
  #--------------------------------------------------------------------------
  alias nw_count_battle_end battle_end
  def battle_end(result)
    $game_system.battle_count += 1
    $game_library.count_up_party_battle
    $game_party.battle_members.each{|m|
      $game_library.count_up_actor_battle(m.id)
    }
    nw_count_battle_end(result)
  end
  #--------------------------------------------------------------------------
  # ○ 戦闘終了　変数拡張　統合時は消す
  #     result : 結果（0:勝利 1:逃走 2:敗北）
  #--------------------------------------------------------------------------
  alias nw_valiable_battle_end battle_end
  def battle_end(result)
    nw_valiable_battle_end(result)
    $game_temp.battle_init
  end
end

#==============================================================================
# ■ Scene_Title
#==============================================================================
class Scene_Title < Scene_Base
  #--------------------------------------------------------------------------
  # ● コマンド［ニューゲーム］
  #--------------------------------------------------------------------------
  def command_new_game
    DataManager.setup_new_game
    close_command_window
    fadeout_all
    $game_map.autoplay
    $game_switches[NWConst::Sw::ON_GAME_START] = true
    SceneManager.goto(Scene_Map)
  end
end
#==============================================================================
# ■ Scene_Load
#==============================================================================
class Scene_Load < Scene_File
  #--------------------------------------------------------------------------
  # ● ロード成功時の処理
  #--------------------------------------------------------------------------
  def on_load_success
    Sound.play_load
    fadeout_all
    $game_system.on_after_load
    $game_switches[NWConst::Sw::ON_GAME_START] = true
    SceneManager.goto(Scene_Map)
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
    
    self.features.sort_by{|ft| [ft.code, ft.data_id]}.each{|ft|
      method_name = method_table[ft.code]
      names.push(send(method_name, ft)) if method_name
    }
    return names.flatten.compact.uniq
  end
  #--------------------------------------------------------------------------
  # ● 盗み成功率名の取得
  #--------------------------------------------------------------------------    
  def steal_success_name(ft)
    rate = (ft.value * 100.0).to_i - 100
    return "盗み成功率#{rate}%#{0 < rate ? "アップ" : "ダウン"}"
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
    #t = "#{Vocab.key_c}:決定　#{Vocab.key_b}:キャンセル"
    t = "#{Vocab.key_a}:戦闘中非表示＆自動戦闘で不使用"
    t += "（※現在、コンフィグで無効）" unless $game_system.conf[:bt_stype]
    return t
  end
end

#==============================================================================
# ■ BattleManager
#==============================================================================
class << BattleManager
  #--------------------------------------------------------------------------
  # ○ 戦闘開始
  #--------------------------------------------------------------------------
  def battle_start
#    $game_system.battle_count += 1
    $game_temp.reserve_common_event(NWConst::Common::BATTLE_START) #
    $game_party.on_battle_start
    $game_troop.on_battle_start
    $game_troop.enemy_names.each do |name|
      $game_message.add(sprintf(Vocab::Emerge, name))
    end
    tmp = []
    $game_troop.members.each {|enemy| tmp.push(enemy.id) if enemy}
    $game_library.enemy.set_discovery(tmp)
    if @preemptive
      $game_message.add(sprintf(Vocab::Preemptive, $game_party.name))
    elsif @surprise
      $game_message.add(sprintf(Vocab::Surprise, $game_party.name))
    end
    wait_for_message
  end
end
#==============================================================================
# ■ Window_Library_MainCommand
#==============================================================================
class Window_Library_MainCommand < Window_Command
  #--------------------------------------------------------------------------
  # ● 項目の描画
  #--------------------------------------------------------------------------
  def draw_item(index)
    if @category == 2 and exist_enemy_include?(index)
      change_color(tp_gauge_color2, command_enabled?(index))
    else
      change_color(normal_color, command_enabled?(index))
    end
    draw_text(item_rect_for_text(index), command_name(index), alignment)
  end
  #--------------------------------------------------------------------------
  # ● 敵IDの取得（魔物図鑑かどうかは考慮しない）
  #--------------------------------------------------------------------------
  def command_enemy_id(index)
    return @list[index][:ext][1] % 10000
  end
  #--------------------------------------------------------------------------
  # ● 戦闘中かつその項目の敵が出現しているかどうか
  #--------------------------------------------------------------------------
  def exist_enemy_include?(index)
    return false unless $game_party.in_battle
    enemy_id = command_enemy_id(index)
    return unless $data_enemies[enemy_id]
    return $game_troop.alive_members.map(&:enemy_id).include?(enemy_id)
  end
end
#==============================================================================
# ■ Scene_Library
#==============================================================================
class Scene_Library < Scene_MenuBase
  #--------------------------------------------------------------------------
  # ● 戦闘中の魔物図鑑のカーソル開始位置
  #--------------------------------------------------------------------------
  def battle_enemy_index
    return 0 unless $game_party.in_battle
    result = nil
    alive_enemies = $game_troop.alive_members.map(&:enemy_id)
    @main_command_window.item_max.times do |i|
      enemy_id = @main_command_window.command_enemy_id(i)
      next unless $data_enemies[enemy_id]
      result = (result ? [result, i].min : i) if alive_enemies.include?(enemy_id)
    end
    return result ? result : 0
  end
  #--------------------------------------------------------------------------
  # ● 魔物の項
  #--------------------------------------------------------------------------
  def on_enemy_index
    @main_command_window.category = 2
    @main_command_window.refresh
    @main_command_window.select(@main_command_window.item_max - 1)
    @main_command_window.select(battle_enemy_index)
    @main_command_window.activate
  end
end