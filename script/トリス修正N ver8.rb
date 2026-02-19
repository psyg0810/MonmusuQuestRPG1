
=begin

もんむす・くえすと！ＲＰＧ
　トリス修正N  ver8  2015/03/01



機能一覧　説明は下　このverで新規追加したものは●　変更したものは○
・一部メダルを獲得不能に
・<即死>ステートによる戦闘不能では、図鑑の撃破カウントが行われなかったのを修正
・戦闘不能時に<快楽死亡>ステートが付加された場合、快楽戦闘不能になるように
・難易度変数によって敵のステート有効度に補正を加える
・スキル使用時、ダメージ計算式に用いる能力値を別の数値に置き換える
・残りHPが1の時は <踏みとどまり N%> の効果が出ないように
・一部マップから同マップにワープするとＢＧＭとＢＧＳが止まったのを修正
・アクターについての条件分岐が、パーティにいなければ非合致になっていたのを修正
・キャラ図鑑の固有アビリティの改行を反映
●敵が選択可能な行動がない場合、代わりに特定スキルを使用する
●拘束時専用技はターンごとにダメージが50%増える

機能　説明

・一部メダルを獲得不能に
SettingData/Library(Medal).rb の NO_USE_MEDAL で設定
指定したIDは gain_medal(N) を実行しても何も起こらず、図鑑の完成度計算から除外
すでに入手済みのセーブデータでも、図鑑では表示されない

・戦闘不能時に<快楽死亡>ステートが付加された場合、快楽戦闘不能になるように
戦闘不能になった時、その時の状況が下記①②のどちらかを満たせば快楽戦闘不能になる
　①スキルの属性に快楽属性が含まれている（今まで通り）
　②同時に「メモに<快楽死亡>とあるステート」が付加された（今回追加）

・難易度変数によって敵のステート有効度に補正を加える
SettingData/IDReserve.rb の PARAM_STATE_RATE で各ステートIDごとに変数IDを指定
敵のステート有効度に、[その変数の値]% を乗算する
ただし変数の値が0なら100%（変化なし）、マイナスなら0%とする
この補正は、敵のメモに <難易度補正無視> があっても行われる

・スキル使用時、ダメージ計算式に用いる能力値を別の数値に置き換える
<能力値置き換え X,N,M>
能力値(N,M)  1:攻撃力  2:防御力  3:魔力  4:精神力  5:素早さ  6:器用さ
　特徴オブジェクト(敵、防具など)のメモに記述  例  <能力値置き換え 21,5,1>
スキルタイプXのダメージ計算時のみ、スキル使用者の能力値Nを能力値Mに置き換える

・一部マップから同マップにワープするとＢＧＭとＢＧＳが止まったのを修正
SettingData/Field.rb の AUTO_BGM_MAP_ID で指定したマップ以外で発生

●敵が選択可能な行動がない場合、代わりに特定スキルを使用する
行動条件(敵キャラ行動パターン)　<必殺技>(スキルメモ)　<一人旅未使用>(スキルメモ)
ターン開始時の行動決定で、上記３つによって「選択可能な行動」が０個だった場合、
　そのターンの行動はIDReserve.rbの NO_VALID_ACTION で指定したスキルに置き換わる

●拘束時専用技はターンごとにダメージが50%増える
被拘束者(ルカ)が拘束使用者から受ける「拘束時(永久拘束時)専用技」は
　「拘束(永久拘束)開始してからのターン数」によってダメージが補正される
開始後１ターン目は100%(変化なし)、２ターン目は150%、３ターン目は200%……となる
　２回行動で「拘束開始と同じターン(０ターン目)」に該当技を受けた場合も100%となる
この補正が働く時、コンソールに表示する
　表示例　"拘束ターン補正　攻撃者:蜜壺　永久拘束ターン数:1　補正結果:100%"

=end

#==============================================================================
# ■ NWConst::LibraryManager
#==============================================================================
module NWConst::LibraryManager
  #--------------------------------------------------------------------------
  # ● 有効なメダルIDを全取得
  #--------------------------------------------------------------------------
  def get_valid_medals
    NWConst::Library::MEDAL_DATA.keys.select do |id|
      !NWConst::Library::NO_USE_MEDAL.include?(id)
    end
  end
end
#==============================================================================
# ■ Game_Library
#==============================================================================
class Game_Library
  #--------------------------------------------------------------------------
  # ● 実績取得
  #--------------------------------------------------------------------------
  def gain_medal(id)
    return unless NWConst::Library::MEDAL_DATA.key?(id)
    return if NWConst::Library::NO_USE_MEDAL.include?(id)
    return if has_medal?(id)
    unlock_lib_medal
    $game_temp.gain_medal_push(id)
    @medal[id] = $game_system.realtime_s
  end
end

#==============================================================================
# ■ NWRegexp::State
#==============================================================================
module NWRegexp::State
  DEATH_PLEASURE            = /<快楽死亡>/i
end
#==============================================================================
# ■ RPG::State
#==============================================================================
class RPG::State < RPG::BaseItem
  #--------------------------------------------------------------------------
  # ● メモ欄解析 
  #--------------------------------------------------------------------------
#  alias nw_kure_note_analyze nw_note_analyze
  def nw_note_analyze
    nw_kure_note_analyze    
    self.note.each_line do |line|
      if NWRegexp::State::TMP_EQUIP.match(line)
        @data_ex[:tmp_equip] = $1.to_i
      elsif NWRegexp::State::DEATH.match(line)
        @data_ex[:death?] = true
      elsif NWRegexp::State::DEATH_PLEASURE.match(line)
        @data_ex[:death_pleasure?] = true
      end
    end
  end  
  #--------------------------------------------------------------------------
  # ● 快楽死亡ステート？
  #--------------------------------------------------------------------------
  def death_pleasure?
    return @data_ex.key?(:death_pleasure?) ? true : false
  end
end
#==============================================================================
# ■ Game_ActionResult
#==============================================================================
class Game_ActionResult
  #--------------------------------------------------------------------------
  # ● 死亡したか
  #--------------------------------------------------------------------------
  def death_state_added?
    added_state_objects.any? {|state| state.death? }
  end
  #--------------------------------------------------------------------------
  # ● 快楽死亡したか
  #--------------------------------------------------------------------------
  def death_pleasure_state_added?
    added_state_objects.any? {|state| state.death_pleasure? }
  end
end
#==============================================================================
# ■ Game_Battler
#==============================================================================
class Game_Battler < Game_BattlerBase
  #--------------------------------------------------------------------------
  # ○ スキル／アイテムの効果適用
  #--------------------------------------------------------------------------
  def item_apply(user, item, is_cnt = false)
    @result.clear
    @result.used = item_test(user, item)
    user = user.observer if user.is_a?(Game_Master)
    @result.missed = (@result.used && rand >= item_hit(user, item))
    @result.pleasure = user.final_elements(item).include?(NWConst::Elem::PLEASURE)
    if @result.hit?
      unless item.damage.none?
        @result.critical = (rand < item_cri(user, item))
        make_damage_value(user, item, is_cnt)
        execute_damage(user)
      end
      item.effects.each {|effect| item_effect_apply(user, item, effect) }
    end
    @result.pleasure ||= @result.death_pleasure_state_added?
    item_user_effect(user, item)
  end
  #--------------------------------------------------------------------------
  # ○ スキル／アイテムの効果適用 統合時は消す
  #--------------------------------------------------------------------------
  alias nw_variable_item_apply item_apply
  def item_apply(user, item, is_cnt = false)
    $game_temp.action_target = self
    nw_variable_item_apply(user, item, is_cnt)
    $game_temp.action_hit = @result.hit?
  end
end
#==============================================================================
# ■ Scene_Battle
#==============================================================================
class Scene_Battle < Scene_Base
  #--------------------------------------------------------------------------
  # ● 撃破に関するカウントアップ処理
  #--------------------------------------------------------------------------
  def count_up_defeat(subject, target, item)
    return unless target.result.death_state_added?
    if subject.final_elements(item).include?(NWConst::Elem::PLEASURE) or
       target.result.death_pleasure_state_added?
      $game_library.count_up_actor_carry(subject.id) if subject.actor?
      $game_library.count_up_actor_orgasm(target.id) if target.actor?
      $game_library.count_up_enemy_orgasm(target.id) if target.enemy?
      $game_library.count_up_friendly_orgasm if subject.actor? && target.luca?
    else
      $game_library.count_up_actor_defeat(subject.id) if subject.actor? && target.enemy?
      $game_library.count_up_actor_down(target.id) if target.actor?
      $game_library.count_up_enemy_down(target.id) if target.enemy?
    end
  end
end

#==============================================================================
# ■ Game_Enemy
#==============================================================================
class Game_Enemy < Game_Battler
  #--------------------------------------------------------------------------
  # ● ステート有効度の取得
  #--------------------------------------------------------------------------
  def state_rate(state_id)
    rate = super(state_id)
    var_id = NWConst::Var::PARAM_STATE_RATE[state_id]
    if var_id
      value = $game_variables[var_id]
      if value > 0
        rate *= value * 0.01
      elsif value < 0
        rate *= 0
      end
    end
    return rate
  end
end

#==============================================================================
# ■ NWRegexp::BaseItem
#==============================================================================
module NWRegexp::BaseItem
  SKILL_CONVERT_PARAM       = /<能力値置き換え\s?(\d+),\s?(\d+),\s?(\d+)>/
end
#==============================================================================
# ■ RPG::BaseItem
#==============================================================================
class RPG::BaseItem
  #--------------------------------------------------------------------------
  # ● メモ欄解析処理
  #--------------------------------------------------------------------------
  alias nw_toris_base_item_note_analyze nw_note_analyze
  def nw_note_analyze
    nw_toris_base_item_note_analyze
    self.note.each_line do |line|
      if false
        
      elsif NWRegexp::BaseItem::SKILL_CONVERT_PARAM.match(line)
        @data_ex[:skill_convert_param_data] ||= Hash.new
        @data_ex[:skill_convert_param_data][$1.to_i] ||= []
        @data_ex[:skill_convert_param_data][$1.to_i].push([$2.to_i + 1, $3.to_i + 1])
      end
    end
  end
  #--------------------------------------------------------------------------
  # ● カテゴリごとのデータ
  #--------------------------------------------------------------------------
  def category_convert_param_data(stype_id)
    return [] if @data_ex[:skill_convert_param_data].nil?
    return @data_ex[:skill_convert_param_data][stype_id]
  end
end
#==============================================================================
# ■ Game_Actor
#==============================================================================
class Game_Actor < Game_Battler
  #--------------------------------------------------------------------------
  # ● 通常能力値の取得
  #--------------------------------------------------------------------------
  alias :convert_param :param
  def param(param_id)
    if @convert_param_data and @convert_param_data[param_id]
      param_id = @convert_param_data[param_id]
    end
    convert_param(param_id)
  end
end
#==============================================================================
# ■ Game_Enemy
#==============================================================================
class Game_Enemy < Game_Battler
  #--------------------------------------------------------------------------
  # ● 通常能力値の取得
  #--------------------------------------------------------------------------
  alias :convert_param :param
  def param(param_id)
    if @convert_param_data and @convert_param_data[param_id]
      param_id = @convert_param_data[param_id]
    end
    convert_param(param_id)
  end
end
#==============================================================================
# ■ BattleManager
#==============================================================================
class << BattleManager
  #--------------------------------------------------------------------------
  # ● 拘束セット
  #--------------------------------------------------------------------------
  def bind_set(count)
    bind_reset
    @bind_count = count
    @bind_start_turn = $game_troop.turn_count
  end
  #--------------------------------------------------------------------------
  # ● 拘束セット
  #--------------------------------------------------------------------------
  def binding_turn
    $game_troop.turn_count - @bind_start_turn
  end
end
#==============================================================================
# ■ Game_Battler
#==============================================================================
class Game_Battler < Game_BattlerBase
  #--------------------------------------------------------------------------
  # ○ パラメータ置換
  #--------------------------------------------------------------------------
  def category_convert_param_data(stype_id)
    result = {}
    feature_objects.each do |object|
      data = object.category_convert_param_data(stype_id)
      next if data.nil?
      data.each do |convert|
        result[convert[0]] = convert[1]
      end
    end
    return result
  end
  def set_category_convert_param_data(stype_id)
    @convert_param_data = category_convert_param_data(stype_id)
  end
  def clear_convert_param_data
    @convert_param_data = nil
  end
  #--------------------------------------------------------------------------
  # ○ ダメージ計算
  #--------------------------------------------------------------------------
  def make_damage_value(user, item, is_cnt = false)
    if item.is_a?(RPG::Skill)
      user.set_category_convert_param_data(item.stype_id)
    end
    value = item.damage.eval(user, self, $game_variables)
    user.clear_convert_param_data
    value *= item_element_rate(user, item)
    value *= pdr if item.physical?
    value *= mdr if item.magical?
    value *= rec if item.damage.recover?
    value *= heel_reverse_rate(item)
    value *= boost_rate(user, item, is_cnt)
    value = apply_critical(value) if @result.critical
    value = apply_variance(value, item.damage.variance)
    value = apply_guard(value)
    value = apply_damage_bind_turn(value, item, user)
    value = apply_invalidate_wall(value, item)
    value = apply_defense_wall(value, item)
    value = apply_metal_body(value, item)
    value = apply_stand(value, item)
    value = apply_damage_mp_convert(value, item)
    value = apply_damage_gold_convert(value, item)
    value = apply_damage_mp_drain(value, item)
    value = apply_damage_gold_drain(value, item)
    @result.make_damage(value.to_i, item)
  end
  #--------------------------------------------------------------------------
  # ● 拘束ターン補正の適用
  #--------------------------------------------------------------------------
  def apply_damage_bind_turn(damage, item, user)
    return damage unless BattleManager.bind?
    return damage unless user.bind_user?
    return damage unless self.bind_target?
    return damage unless item.is_a?(RPG::Skill) and (item.bind? or item.eternal_bind?)
    turn = BattleManager.binding_turn
    rate = [1.0 + (turn - 1) * 0.5, 1.0].max
    s = self.state?(NWConst::State::ETBIND) ? "永久拘束" : "拘束"
    print "拘束ターン補正　攻撃者:#{user.name}　#{s}ターン数:#{turn}"
    print "　補正結果:#{(rate * 100).to_i}%\n"
    return damage * rate
  end
  #--------------------------------------------------------------------------
  # ● 踏みとどまりの適用
  #--------------------------------------------------------------------------
  def apply_stand(damage, item)
    return damage if hp == 1
    return damage unless hp <= damage
    return damage unless mhp * auto_stand < hp
    return damage if item.damage.recover?
    @result.auto_stand = true
    return hp - 1
  end
end

#==============================================================================
# ■ Scene_Warp
#==============================================================================
class Scene_Warp < Scene_MenuBase
  #--------------------------------------------------------------------------
  # ● 確認：決定
  #--------------------------------------------------------------------------  
  def confirm_ok
    if @cost_item.is_a?(RPG::Item)
      $game_party.consume_item(@cost_item)
    else
      @actor.pay_skill_cost(@cost_item)
    end
    NWConst::Warp::MOVE_SE.play
    RPG::BGM.fade(500)
    RPG::BGS.fade(500)
    fadeout(30)
    RPG::BGM.stop
    RPG::BGS.stop
    place = @select_place_window.current_ext
    $game_player.forced_get_off_vehicle
    $game_player.reserve_transfer(place[:map_id], place[:x], place[:y])
    $game_player.perform_transfer
    $game_map.autoplay
    $game_player.followers.visible = true
    $game_player.refresh
    $game_map.screen.clear
    # 乗り物の移動
    if $game_map.ship.exist? && place.key?(:v2location)
      map_id = place[:v2location][0]
      x = place[:v2location][1]
      y = place[:v2location][2]        
      $game_map.ship.set_location(map_id, x, y)
    end
    if $game_map.airship.exist? && place.key?(:v3location)
      map_id = place[:v3location][0]
      x = place[:v3location][1]
      y = place[:v3location][2]        
      $game_map.airship.set_location(map_id, x, y)
    end
    # ポケット魔王城の出口修正
    if place[:map_id] == 126
      $game_variables[21] = 2
      $game_variables[22] = 295
      $game_variables[23] = 356
    end
    goto_map
  end
end


#==============================================================================
# ■ Game_Interpreter
#==============================================================================
class Game_Interpreter
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
      enemy = $game_troop.members[@params[1]]
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
end

#==============================================================================
# ■ Window_Library_RightMain
#==============================================================================
class Window_Library_RightMain < Window_Selectable
  #--------------------------------------------------------------------------
  # ● アクターの固有アビリティ
  #--------------------------------------------------------------------------
  def draw_actor_fix_ability(y, actor)
    fix_abilities = ACTOR_FIX_ABILITY[actor.id]
    return y unless fix_abilities
    rect = standard_rect(y)
    reset_font_settings
    
    change_color(system_color)
    draw_text(rect, FIX_ABILITY_NAME)
    rect.y += rect.height
    change_color(special_color)
    draw_text(rect, fix_abilities.first)
    rect.y += rect.height
    change_color(normal_color)
    
    all_text = ""
    fix_abilities[1...fix_abilities.size].each{|fix_ability|
      all_text += fix_ability
      all_text += "。" unless all_text[-1] == "。"
      all_text += "\n"
    }
    all_text.slice!(-1, 1)
    rect = draw_text_auto_line_ex(rect, all_text)
    return rect.y
  end
  #--------------------------------------------------------------------------
  # ● 自動改行テキスト表示　配列の区切りで改行
  #--------------------------------------------------------------------------
  def draw_text_auto_line_ex(rect, text)
    array = []
    s = ""
    text.size.times{|i|
      s += text[i] if text[i] != "\n"
      next if text[i] != "\n" and
              self.contents.width >= text_size(s).width + (standard_padding * 2)
      array.push(s)
      s = ""
    }
    array.push(s)
    array.each{|str| draw_text(rect, str); rect.y += rect.height}
    return rect
  end
end

#==============================================================================
# ■ Game_Enemy
#==============================================================================
class Game_Enemy < Game_Battler
  #--------------------------------------------------------------------------
  # ○ 有効な行動がない場合の使用スキル
  #--------------------------------------------------------------------------
  def no_valid_action_skill_id
    NWConst::Skill::NO_VALID_ACTION
  end
  #--------------------------------------------------------------------------
  # ○ 戦闘行動の作成
  #--------------------------------------------------------------------------
  def make_actions
    super
    return if @actions.empty?
    
    if self.state?(NWConst::State::UBIND)
      action_list = make_bind_actions
    elsif self.state?(NWConst::State::EUBIND)
      action_list = make_eternal_bind_actions
    else
      action_list = make_normal_actions
    end
    action_list.select!{|a| conditions_met?(a)} 
    action_list.reject!{|a| @recharge_skills.keys.include?(a.skill_id)}
    action_list.reject!{|a| $game_party.lonely? && $data_skills[a.skill_id].lonely_unused?}
    cycle_success = []
    cycle_failure = []   
    action_list.select{|a| $data_skills[a.skill_id].cycle_skill?}.each{|a|
      if $data_skills[a.skill_id].cycle_eval
        cycle_success.push(a)
      else
        cycle_failure.push(a)
      end
    }
    cycle_failure.each{|a| action_list.delete(a)}
    action_list = cycle_success unless cycle_success.empty?
    
    if action_list.empty?
      @actions.each do |action|
        action.set_skill(no_valid_action_skill_id)
      end
    else
      rating_sum  = action_list.inject(0){|sum, a| sum += a.rating}
      @actions.each do |action|
        action.set_enemy_action(select_enemy_action(action_list, rating_sum))
      end
    end
  end
end
