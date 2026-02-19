
=begin

もんむす・くえすと！ＲＰＧ
　トリス修正M  ver7  2015/02/22



機能一覧　説明は下　このverで新規追加したものは●　変更したものは○　削除は×
・味方スキルによるステート付加では耐性が無効になるのを修正
・魔物図鑑、仲間になっている/なっていない表記
・一部モンスターの難易度変更によるパラメータ変動無効
・戦闘中、ボタン4(Aキー)で早送りに加えて戦闘アニメと敵消滅エフェクトもスキップ
・変数IDの共有化
・降参中に誘惑イベントによって敗北した時のフリーズを修正
・降参の時間切れで敗北した時のフリーズを修正
・メモに <スキップ不能> とある敵は、魔物図鑑での敗北回想が不可能
・メモに <捕食無効> とある敵は、起動ステートが付加されていても捕食されない
○特殊能力値「床ダメージ率」をパーティ全員に適用
・パーティ能力「不意打ち無効」「先制攻撃率アップ」を全メンバーから取得
・メモ <獲得金額倍率><獲得アイテム倍率><エンカウント倍率> を全メンバーから取得


機能　説明

・戦闘中、ボタン4での早送りに加えて戦闘アニメと敵消滅エフェクトもスキップ
通常消滅とボス消滅は、瞬間消滅して「通常消滅の効果音を演奏」する
瞬間消滅と「消えない」は変化なし

・変数IDの共有化
SettingData/IDReserve.rb で設定する
同じ[]内で指定したIDの変数は、全て同じものとして扱われる

・魔物図鑑、仲間になっている/なっていない表記
通常の仲間加入(SettingData/Follower.rb)しない敵は、
　メモに <仲間ID:N> とあれば魔物図鑑での仲間表記を行う
この場合、スイッチN番がオンであるかどうかで「なっている/なっていない」が決まる

・一部モンスターの難易度変更によるパラメータ変動無効
敵のメモに <難易度補正無視> とあれば、難易度(変数41～44)でパラメータが変わらない

○特殊能力値「床ダメージ率」をパーティ全員に適用
自身にしか適用されなかったのを、パーティ全員に効果が及ぶように
１人が複数持っている場合、複数人が持っている場合、どちらも最小値を使う

・パーティ能力「不意打ち無効」「先制攻撃率アップ」を全メンバーから取得
・メモ <獲得金額倍率><獲得アイテム倍率><エンカウント倍率> を全メンバーから取得
戦闘参加メンバー(1～4人目)からしか取得されなかったのを、全メンバーに


=end

#==============================================================================
# ■ Scene_Battle
#==============================================================================
class Scene_Battle < Scene_Base
  #--------------------------------------------------------------------------
  # ● アニメと崩壊エフェクトのスキップ toris
  #--------------------------------------------------------------------------
  def battle_show_skip?
    Input.press?(:X)
  end
  #--------------------------------------------------------------------------
  # ● アニメーションの表示 toris Scene_Battle
  #--------------------------------------------------------------------------
  def show_animation(targets, animation_id)
    return if battle_show_skip?
    # ターゲット拡張　統合時は消す
    item = @subject.current_action.item
    if item.non_overlap_anima?
      targets = targets.uniq
    end
    # ターゲット拡張　統合時は消す
    if animation_id < 0
      show_attack_animation(targets)
    else
      show_normal_animation(targets, animation_id)
    end
    @log_window.wait
    wait_for_animation
  end
end
#==============================================================================
# ■ Game_Enemy
#==============================================================================
class Game_Enemy < Game_Battler
  #--------------------------------------------------------------------------
  # ● アニメと崩壊エフェクトのスキップ toris
  #--------------------------------------------------------------------------
  def battle_show_skip?
    Input.press?(:X)
  end
  #--------------------------------------------------------------------------
  # ● コラプス効果の実行 toris Game_Enemy
  #--------------------------------------------------------------------------
  def perform_collapse_effect
    case collapse_type
    when 0
      if battle_show_skip?
        @sprite_effect_type = :instant_collapse
        Sound.play_enemy_collapse
      else
        @sprite_effect_type = :collapse
        Sound.play_enemy_collapse
      end
    when 1
      if battle_show_skip?
        @sprite_effect_type = :instant_collapse
        Sound.play_enemy_collapse
      else
        @sprite_effect_type = :boss_collapse
        Sound.play_boss_collapse1
      end
    when 2
      @sprite_effect_type = :instant_collapse
    end
    # 仲間化システム　統合時は消す
    $game_troop.dead_enemies.push(self)
    # 仲間化システム　統合時は消す
  end
end
#==============================================================================
# ■ Game_Battler
#==============================================================================
class Game_Battler < Game_BattlerBase
  #--------------------------------------------------------------------------
  # ○ 使用効果［ステート付加］：通常 ベース/GameObject 1340
  #--------------------------------------------------------------------------
  def item_effect_add_state_normal(user, item, effect)
    chance = effect.value1    
    if item.is_skill?
      chance *= user.booster_state_ratio_type(item)
      chance *= user.booster_state_ratio_skill(item)
      chance += user.booster_state_fix_type(item)
    end
    if (chance < 1.0) && (state_rate(effect.data_id) < 1.0)
      chance *= state_rate(effect.data_id)
    else
      chance += state_rate(effect.data_id) - 1.0
    end
    chance = 0.0 if state_rate(effect.data_id) == 0.0 || state_resist?(effect.data_id)
    
    print "#{$data_states[effect.data_id].name}付与最終成功率#{(chance * 100).to_i}%\n" if $TEST
    if rand < chance
      if effect.data_id == NWConst::State::INSTANT_DEAD && (0 < hp) && instant_dead_reverse?
        @result.hp_damage = -(mhp - hp)
        self.hp = mhp
      else
        add_state(effect.data_id)
      end
      @result.success = true
    end
  end
end

#==============================================================================
# ■ Game_Variables
#==============================================================================
class Game_Variables
  #--------------------------------------------------------------------------
  # ○ 変数の設定
  #--------------------------------------------------------------------------
  alias nw_common_set []=
  def []=(variable_id, value)
    nw_common_set(common_variable_id(variable_id), value)    
  end
  #--------------------------------------------------------------------------
  # ○ 変数の取得
  #--------------------------------------------------------------------------
  alias nw_common_get []
  def [](variable_id)
    return nw_common_get(common_variable_id(variable_id))
  end
  #--------------------------------------------------------------------------
  # ○ 共有変数IDの変換
  #--------------------------------------------------------------------------
  def common_variable_id(variable_id)
    NWConst::Var::COMMON_VARIABLE.each do |data|
      return data.min if data.include?(variable_id)
    end
    return variable_id
  end
end
#==============================================================================
# ■ Window_DebugRight
#==============================================================================
class Window_DebugRight < Window_Selectable
  #--------------------------------------------------------------------------
  # ● 選択項目の再描画
  #--------------------------------------------------------------------------
  def redraw_current_item
    refresh
  end
end


#==============================================================================
# ■ Scene_Battle
#==============================================================================
class Scene_Battle < Scene_Base
  #--------------------------------------------------------------------------
  # ○ ターン終了
  #--------------------------------------------------------------------------
  def turn_end
    all_battle_members.each do |battler|
      battler.on_turn_end
      refresh_status
      @log_window.display_auto_affected_status(battler)
      @log_window.wait_and_clear
    end
    BattleManager.turn_end
    process_event
    BattleManager.set_turn_end_skill
    process_action while BattleManager.gm_exist?
    # 降参時はコマンド入力飛ばし
    if BattleManager.giveup?
      if BattleManager.giveup_count_down
        actor = $game_actors[NWConst::Actor::LUCA]
        actor.add_state(actor.death_state_id)
        actor.orgasm_word.execute
        process_luca_orgasm
        BattleManager.process_defeat
      else
        $game_troop.make_actions
        turn_start
      end
    else
      start_party_command_selection
    end
  end
end
#==============================================================================
# ■ BattleManager
#==============================================================================
class << BattleManager
  #--------------------------------------------------------------------------
  # ● 戦闘開始スキルの設定
  #--------------------------------------------------------------------------
  def set_battle_start_skill
    @action_game_masters = []
    return if giveup?
    ($game_troop.alive_members + $game_party.alive_members).each{|member|
      member.battle_start_skill.each{|obj|
        skill_interrupt(member, obj[:id]) if rand < obj[:per]
      }
    }
  end
  #--------------------------------------------------------------------------
  # ● ターン開始スキルの設定
  #--------------------------------------------------------------------------
  def set_turn_start_skill
    @action_game_masters = []
    return if giveup?
    ($game_troop.alive_members + $game_party.alive_members).each{|member|
      member.turn_start_skill.each{|obj|
        skill_interrupt(member, obj[:id]) if rand < obj[:per]
      }
    }
  end
  #--------------------------------------------------------------------------
  # ● ターン終了スキルの設定
  #--------------------------------------------------------------------------
  def set_turn_end_skill
    @action_game_masters = []
    return if giveup?
    ($game_troop.alive_members + $game_party.alive_members).each{|member|
      member.turn_end_skill.each{|obj|
        skill_interrupt(member, obj[:id]) if rand < obj[:per]
      }
    }
  end
end

#==============================================================================
# ■ NWRegexp::Enemy
#==============================================================================
module NWRegexp::Enemy
  JOIN_SWITCH               = /<仲間ID:(\d+)>/i
  NO_DIFFICULTY             = /<難易度補正無視>/i
  NO_PREDATION              = /<捕食無効>/
  NO_LOSE_SKIP              = /<スキップ不能>/
end
#==============================================================================
# ■ RPG::Enemy
#==============================================================================
class RPG::Enemy < RPG::BaseItem
  #--------------------------------------------------------------------------
  # ● メモ欄解析処理
  #--------------------------------------------------------------------------
  #alias nw_kure_enemy_note_analyze nw_note_analyze
  def nw_note_analyze
    nw_kure_enemy_note_analyze
    
    self.note.each_line do |line|
      if NWRegexp::Enemy::ESCAPE_LEVEL.match(line)
        @data_ex[:escape_level] = $1.to_i
      elsif NWRegexp::Enemy::CLASSEXP.match(line)
        @data_ex[:class_exp] = $1.to_i
      elsif NWRegexp::Enemy::FRIEND_VARIABLE.match(line)
        @data_ex[:friend_variable] = $1.to_i
      elsif NWRegexp::Enemy::STEAL_LIST.match(line)
        @data_ex[:steal_list] ||= {1 => [], 2 => [], 3 => [], 4 => []}
        @data_ex[:steal_list][$1.to_i].push({
          :kind => {:I => 1, :W => 2, :A => 3}[$2.to_sym],
          :data_id => $3.to_i,
          :denominator => $4.to_i})
      elsif NWRegexp::Enemy::WEAPON_TYPE.match(line)    
        @data_ex[:wtype_id] = $1.to_i
      elsif NWRegexp::Enemy::CATEGORY.match(line)
        @data_ex[:lib_category] = $1.to_sym
      elsif NWRegexp::Enemy::LIB_NAME.match(line)
        @data_ex[:lib_name] = $1.to_s
      elsif NWRegexp::Battler::TEMPTATION_SKILL.match(line)
        @data_ex[:temptation_skill] = $1.to_i
      elsif NWRegexp::Enemy::JOIN_SWITCH.match(line)
        @data_ex[:join_switch] = $1.to_i
      elsif NWRegexp::Enemy::JOIN_SWITCH.match(line)
        @data_ex[:join_switch] = $1.to_i
      elsif NWRegexp::Enemy::NO_DIFFICULTY.match(line)
        @data_ex[:no_difficulty] = true
      elsif NWRegexp::Enemy::NO_PREDATION.match(line)
        @data_ex[:no_predation] = true
      elsif NWRegexp::Enemy::NO_LOSE_SKIP.match(line)
        @data_ex[:no_lose_skip] = true
      end
    end
  end
  #--------------------------------------------------------------------------
  # ● 仲間加入表記スイッチ
  #--------------------------------------------------------------------------
  def join_switch
    @data_ex.key?(:join_switch) ? @data_ex[:join_switch] : nil
  end
  #--------------------------------------------------------------------------
  # ● 難易度補正無視
  #--------------------------------------------------------------------------
  def no_difficulty?
    @data_ex.key?(:no_difficulty) ? true : false
  end
  #--------------------------------------------------------------------------
  # ● 捕食無効
  #--------------------------------------------------------------------------
  def no_predation?
    @data_ex.key?(:no_predation) ? true : false
  end
  #--------------------------------------------------------------------------
  # ● 敗北イベントスキップ不能
  #--------------------------------------------------------------------------
  def no_lose_skip?
    @data_ex.key?(:no_lose_skip) ? true : false
  end
end
#==============================================================================
# ■ Window_Library_RightMain
#==============================================================================
class Window_Library_RightMain < Window_Selectable
  #--------------------------------------------------------------------------
  # ● 敵キャラ統計描画
  #--------------------------------------------------------------------------
  def draw_enemy_stat(y, enemy)
    rect = standard_rect(y)
    lr = half_left_rect(rect.y)
    rr = half_right_rect(rect.y)
    join_flag = false
    join_exist = false
    if enemy.follower?
      join_flag = true
      join_exist = $game_party.exist_all_actor_id?(enemy.follower_actor_id)
    elsif enemy.join_switch
      join_flag = true
      join_exist = $game_switches[enemy.join_switch]
    end
    if join_flag
      txt = "仲間になって#{ join_exist ? "いる" : "いない" }"
      change_color(normal_color)
      draw_text(lr, txt)
      lr.y += lr.height + LINE_HEIGHT
      rr.y += rr.height + LINE_HEIGHT
    end
    txt = "種族:"
    change_color(system_color)
    draw_text(lr, txt)
    txt = enemy.lib_category.to_s
    change_color(normal_color)
    draw_text(rr, txt)
    lr.y += lr.height
    rr.y += rr.height
    draw_common_friend(lr, rr, enemy)
    lr.y += lr.height
    rr.y += rr.height    
    txt = "倒した数:"
    change_color(system_color)
    draw_text(lr, txt)
    txt = "#{enemy_down(enemy.id).to_i}回"
    change_color(normal_color)
    draw_text(rr, txt)
    lr.y += lr.height
    rr.y += rr.height
    txt = "イかせた数:"
    change_color(system_color)
    draw_text(lr, txt)
    txt = "#{enemy_orgasm(enemy.id).to_i}回"
    change_color(normal_color)
    draw_text(rr, txt)
    lr.y += lr.height
    rr.y += rr.height
    txt = "陵辱された回数:"
    change_color(system_color)
    draw_text(lr, txt)
    txt = "#{enemy_victory(enemy.id).to_i}回"
    change_color(normal_color)
    draw_text(rr, txt)
    lr.y += lr.height + LINE_HEIGHT
    rr.y += rr.height + LINE_HEIGHT
    y = draw_encounter_enemy_place(lr.y, enemy)
    return y
  end
end


#==============================================================================
# ■ Game_Enemy
#==============================================================================
class Game_Enemy < Game_Battler
  #--------------------------------------------------------------------------
  # ● 最大HP ベース/GameObject 2163 以下メソッドではこの表示を省略
  #--------------------------------------------------------------------------
  def mhp
    return super if enemy.no_difficulty?
    return super unless 0 < $game_variables[NWConst::Var::PARAM1]
    return (super * $game_variables[NWConst::Var::PARAM1] * 0.01).to_i
  end
  #--------------------------------------------------------------------------
  # ● 攻撃力
  #--------------------------------------------------------------------------
  def atk
    return super if enemy.no_difficulty?
    return super unless 0 < $game_variables[NWConst::Var::PARAM2]
    return (super * $game_variables[NWConst::Var::PARAM2] * 0.01).to_i
  end
  #--------------------------------------------------------------------------
  # ● 防御力
  #--------------------------------------------------------------------------
  def def
    return super if enemy.no_difficulty?
    return super unless 0 < $game_variables[NWConst::Var::PARAM3]
    return (super * $game_variables[NWConst::Var::PARAM3] * 0.01).to_i
  end
  #--------------------------------------------------------------------------
  # ● 魔力
  #--------------------------------------------------------------------------
  def mat
    return super if enemy.no_difficulty?
    return super unless 0 < $game_variables[NWConst::Var::PARAM2]
    return (super * $game_variables[NWConst::Var::PARAM2] * 0.01).to_i
  end
  #--------------------------------------------------------------------------
  # ● 精神
  #--------------------------------------------------------------------------
  def mdf
    return super if enemy.no_difficulty?
    return super unless 0 < $game_variables[NWConst::Var::PARAM3]
    return (super * $game_variables[NWConst::Var::PARAM3] * 0.01).to_i
  end
  #--------------------------------------------------------------------------
  # ● 素早
  #--------------------------------------------------------------------------
  def agi
    return super if enemy.no_difficulty?
    return super unless 0 < $game_variables[NWConst::Var::PARAM4]
    return (super * $game_variables[NWConst::Var::PARAM4] * 0.01).to_i
  end
  #--------------------------------------------------------------------------
  # ● 器用
  #--------------------------------------------------------------------------
  def luk
    return super if enemy.no_difficulty?
    return super unless 0 < $game_variables[NWConst::Var::PARAM2]
    return (super * $game_variables[NWConst::Var::PARAM2] * 0.01).to_i
  end
end

#==============================================================================
# ■ Game_Enemy
#==============================================================================
class Game_Enemy < Game_Battler
  #--------------------------------------------------------------------------
  # ● 使用効果［捕食］
  #--------------------------------------------------------------------------
  def item_effect_predation(user, item, effect)
    return if enemy.no_predation?
    super(user, item, effect)
  end
end

#==============================================================================
# ■ Window_Library_EnemyCommand
#==============================================================================
class Window_Library_EnemyCommand < Window_Command
  #--------------------------------------------------------------------------
  # ● 回想イベントに対応している？
  #--------------------------------------------------------------------------  
  def memory_event?
    return false if enemy.no_lose_skip?
    event = $data_common_events[enemy.lose_event_id]
    return false unless event
    return true
  end
end
#==============================================================================
# ■ BattleManager
#==============================================================================
class << BattleManager
  #--------------------------------------------------------------------------
  # ● ノベルパートへの移行
  #--------------------------------------------------------------------------  
  def change_novel_scene
    SceneManager.clear
    SceneManager.push(Scene_Map)
    $game_novel.setup($game_troop.lose_event_id)
    SceneManager.goto(Scene_Novel)
    
    skip_flag = $game_system.conf[:ls_skip] == 1
    skip_flag &&= $game_library.lose_event_view?($game_novel.event_id)
    skip_flag &&= $game_temp.lib_enemy_index == -1    
    check_flag = $game_system.conf[:ls_skip] == 2
    check_flag &&= $game_temp.lib_enemy_index == -1
    choice = -1
    if no_lose_skip?
      skip_flag  = false
      check_flag = false
    end
    if check_flag
      $game_message.add("敗北シーンをスキップしますか？")
      ["はい","いいえ"].each {|s| $game_message.choices.push(s) }
      $game_message.choice_cancel_type = 2
      $game_message.choice_proc = Proc.new {|n| choice = n }
      wait_for_message      
    end
    $game_novel.interpreter.goto_ilias if skip_flag || (choice == 0)
  end
  #--------------------------------------------------------------------------
  # ● スキップ不能か toris
  #--------------------------------------------------------------------------
  def no_lose_skip?
    enemy_id = $game_troop.lose_event_id - NWConst::Common::LOSE_EVENT_BASE
    return $data_enemies[enemy_id].no_lose_skip?
  end
end

#==============================================================================
# ■ Game_Actor
#==============================================================================
class Game_Actor < Game_Battler
  #--------------------------------------------------------------------------
  # ○ 床ダメージ率
  #--------------------------------------------------------------------------
  def fdr
    features_min(FEATURE_SPARAM, 8)
  end
  #--------------------------------------------------------------------------
  # ● 床ダメージの処理
  #--------------------------------------------------------------------------
  def execute_floor_damage
    damage = (basic_floor_damage * $game_party.floor_damage_rate).to_i
    self.hp -= [damage, max_floor_damage].min
    perform_map_damage_effect if damage > 0
  end
end
#==============================================================================
# ■ Game_Party
#==============================================================================
class Game_Party < Game_Unit
  #--------------------------------------------------------------------------
  # ● 床ダメージ率
  #--------------------------------------------------------------------------
  def floor_damage_rate
    all_members.map(&:fdr).min
  end
  #--------------------------------------------------------------------------
  # ● 全メンバーのパーティ能力判定
  #--------------------------------------------------------------------------
  def all_party_ability(ability_id)
    all_members.any? {|actor| actor.party_ability(ability_id) }
  end
  #--------------------------------------------------------------------------
  # ● 不意打ち無効？
  #--------------------------------------------------------------------------
  def cancel_surprise?
    all_party_ability(ABILITY_CANCEL_SURPRISE)
  end
  #--------------------------------------------------------------------------
  # ● 先制攻撃率アップ？
  #--------------------------------------------------------------------------
  def raise_preemptive?
    all_party_ability(ABILITY_RAISE_PREEMPTIVE)
  end
  #--------------------------------------------------------------------------
  # ● 獲得金額倍率
  #--------------------------------------------------------------------------
  def get_gold_rate
    all_members.inject([1.0]){|r, actor| r.push(actor.get_gold_rate)}.max
  end
  #--------------------------------------------------------------------------
  # ● 獲得アイテム倍率
  #--------------------------------------------------------------------------
  def get_item_rate
    all_members.inject([1.0]){|r, actor| r.push(actor.get_item_rate)}.max
  end
  #--------------------------------------------------------------------------
  # ● 仲間加入倍率
  #--------------------------------------------------------------------------
  def collect_rate
    all_members.inject([1.0]){|r, actor| r.push(actor.collect_rate)}.max
  end
end