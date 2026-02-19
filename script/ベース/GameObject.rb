=begin
=ベース/GameObject

ここではGameObjectを中心に扱います


==更新履歴
  Date     Version Author Comment
==14/12/13 2.0.0   トリス 統合A～E A B C
==14/12/19 2.0.1   トリス 統合F～I F G H I

=end

#==============================================================================
# ■ Game_Temp
#==============================================================================
class Game_Temp
  #--------------------------------------------------------------------------
  # ● 公開インスタンス変数
  #--------------------------------------------------------------------------
  attr_accessor   :gain_medal_count
  attr_accessor   :keys_stack
  #--------------------------------------------------------------------------
  # ○ オブジェクト初期化
  #--------------------------------------------------------------------------
  def initialize
    @common_events = []
    @gain_medals = []
    @gain_medal_count = 0
    @fade_type = 0
    @keys_stack = []
  end
  #--------------------------------------------------------------------------
  # ○ コモンイベントの呼び出しを予約
  #--------------------------------------------------------------------------
  def reserve_common_event(common_event_id)
    @common_events.push(common_event_id)
  end
  #--------------------------------------------------------------------------
  # ○ コモンイベントの呼び出し予約をクリア
  #--------------------------------------------------------------------------
  def clear_common_event
    @common_events.clear
  end
  #--------------------------------------------------------------------------
  # ● コモンイベントの呼び出し予約の先頭を排除
  #--------------------------------------------------------------------------
  def shift_common_event
    @common_events.shift
  end
  #--------------------------------------------------------------------------
  # ○ コモンイベント呼び出しの予約判定
  #--------------------------------------------------------------------------
  def common_event_reserved?
    !@common_events.empty?
  end
  #--------------------------------------------------------------------------
  # ○ 予約されているコモンイベントを取得
  #--------------------------------------------------------------------------
  def reserved_common_event
    common_event_id = common_event_reserved? ? @common_events[0] : 0
    $data_common_events[common_event_id]
  end
  #--------------------------------------------------------------------------
  # ● 獲得メダルを予約
  #--------------------------------------------------------------------------
  def gain_medal_push(id)
    @gain_medals.push(id)
  end
  #--------------------------------------------------------------------------
  # ● 獲得メダルを取り出す
  #--------------------------------------------------------------------------
  def gain_medal_pop
    @gain_medals.shift
  end
  #--------------------------------------------------------------------------
  # ● 獲得メダルが存在する？
  #--------------------------------------------------------------------------
  def gain_medal_exist?
    return !@gain_medals.empty?
  end
end

#==============================================================================
# ■ Game_System
#==============================================================================
class Game_System
  #--------------------------------------------------------------------------
  # ● 公開インスタンス変数
  #--------------------------------------------------------------------------
  attr_accessor :party_lose_count # 全滅回数  
  #--------------------------------------------------------------------------
  # ○ オブジェクト初期化
  #--------------------------------------------------------------------------
  def initialize
    @save_disabled = false
    @menu_disabled = false
    @encounter_disabled = false
    @formation_disabled = false
    @battle_count = 0
    @save_count = 0
    @version_id = 0
    @window_tone = nil
    @battle_bgm = nil
    @battle_end_me = nil
    @saved_bgm = nil
    #
    @party_lose_count = 0
  end
  #--------------------------------------------------------------------------
  # ● リアル時間を文字列で取得
  #--------------------------------------------------------------------------
  def realtime_s
    return Time.now.strftime("%Y/%m/%d %H:%M")
  end  
end

#==============================================================================
# ■ Game_Action
#==============================================================================
class Game_Action
  #--------------------------------------------------------------------------
  # ○ シンボルをセット　死亡時スキルの判定に使用
  #--------------------------------------------------------------------------
  def set_symbol(symbol)
    @symbol = symbol
  end
  #--------------------------------------------------------------------------
  # ● もがくを設定
  #--------------------------------------------------------------------------
  def set_bind_resist
    set_skill(subject.bind_resist_skill_id)
    self
  end
  #--------------------------------------------------------------------------
  # ● なすがままを設定
  #--------------------------------------------------------------------------
  def set_mercy
    set_skill(subject.mercy_skill_id)
    self
  end
  #--------------------------------------------------------------------------
  # ● 誘惑時行動スキルを設定
  #--------------------------------------------------------------------------
  def set_temptation
    set_skill(subject.temptation_skill_id)
    self    
  end
  #--------------------------------------------------------------------------
  # ○ 行動準備
  #--------------------------------------------------------------------------
  def prepare
    if subject.temptation? && !forcing
      set_temptation
    elsif subject.confusion? && !forcing
      set_confusion
    end    
    decide_random_target if @target_index == -1    
  end
  #--------------------------------------------------------------------------
  # ○ ターゲットの配列作成
  #--------------------------------------------------------------------------
  def make_targets
    if !forcing && subject.temptation?
      temptation_targets
    elsif !forcing && subject.confusion?
      [confusion_target]
    elsif item.for_opponent?
      targets_for_opponents
    elsif item.for_friend?
      targets_for_friends
    else
      []
    end
  end  
  #--------------------------------------------------------------------------
  # ● 誘惑時のターゲット
  #--------------------------------------------------------------------------
  def temptation_targets
    return [$game_actors[NWConst::Actor::LUCA]]
  end
  #--------------------------------------------------------------------------
  # ● 使用アイテム配列の取得
  #--------------------------------------------------------------------------
  def use_items
    return [SceneManager.scene.process_slot]  if item.use_slot?
    return [SceneManager.scene.process_poker] if item.use_poker?
    return [$data_skills[item.random_invoke.sample]] if item.random_invoke
    return item.multi_invoke.collect{|id| $data_skills[id]} if item.multi_invoke
    return [item]
  end
  #--------------------------------------------------------------------------
  # ○ ランダムターゲット
  #--------------------------------------------------------------------------
  def decide_random_target
    if item.for_dead_friend?
      target = friends_unit.random_dead_target_ex(item.ext_scope)
    elsif item.for_friend?
      target = friends_unit.random_target_ex(item.ext_scope)
    else
      target = opponents_unit.random_target_ex(item.ext_scope)
    end
    if target
      @target_index = target.index
    else
      return if @symbol == :dead_skill
      return if !forcing && subject.temptation?
      clear
    end
  end
  #--------------------------------------------------------------------------
  # ○ 混乱時のターゲット
  #--------------------------------------------------------------------------
  def confusion_target
    case subject.confusion_level
    when 1
      return opponents_unit.random_target_ex(item.ext_scope)
    when 2
      if rand(2) == 0
        return opponents_unit.random_target_ex(item.ext_scope)
      else
        return friends_unit.random_target_ex(item.ext_scope)
      end
    else
      return friends_unit.random_target_ex(item.ext_scope)
    end
  end
  #--------------------------------------------------------------------------
  # ○ 敵に対するターゲット
  #--------------------------------------------------------------------------
  def targets_for_opponents
    if item.for_random?
      return Array.new(item.number_of_targets) { opponents_unit.random_target_ex(item.ext_scope) }
    elsif item.for_one?
      num = 1 + (attack? ? subject.atk_times_add.to_i : 0)
      if @target_index < 0
        return [opponents_unit.random_target_ex(item.ext_scope)] * num
      else
        return [opponents_unit.smooth_target(@target_index)] * num
      end
    else
      num = 1 + (attack? ? subject.atk_times_add.to_i : 0)
      return opponents_unit.alive_members_ex(item.ext_scope) * num
    end
  end
  #--------------------------------------------------------------------------
  # ○ 味方に対するターゲット
  #--------------------------------------------------------------------------
  def targets_for_friends
    if item.for_user?
      return subject.game_master? ? [subject.observer] : [subject] # GM込み仕様に対応
    elsif item.for_dead_friend?
      if item.for_one?
        return [friends_unit.smooth_dead_target(@target_index)]
      else
        return friends_unit.dead_members_ex(item.ext_scope)
      end
    elsif item.for_friend?
      if item.for_one?
        return [friends_unit.smooth_target(@target_index)]
      else
        return friends_unit.alive_members_ex(item.ext_scope)
      end
    end
  end
  #--------------------------------------------------------------------------
  # ○ スキル／アイテムの使用対象候補を取得
  #--------------------------------------------------------------------------
  def item_target_candidates
    if item.for_opponent?
      return opponents_unit.alive_members_ex(item.ext_scope)
    elsif item.for_user?
      return [subject]
    elsif item.for_dead_friend?
      return friends_unit.dead_members_ex(item.ext_scope)
    else
      return friends_unit.alive_members_ex(item.ext_scope)
    end
  end
end

#==============================================================================
# ■ Game_ActionResult
#==============================================================================
class Game_ActionResult
  #--------------------------------------------------------------------------
  # ● 公開インスタンス変数
  #--------------------------------------------------------------------------
  attr_accessor   :unusable
  attr_accessor   :predation
  attr_accessor   :pleasure
  attr_accessor   :hp_restore
  attr_accessor   :mp_restore
  attr_accessor   :stealed
  attr_accessor   :stealed_item_empty
  attr_accessor   :stealed_item_kind
  attr_accessor   :stealed_item_id
  attr_accessor   :auto_stand
  attr_accessor   :invalidate_wall
  attr_accessor   :defense_wall
  attr_accessor   :over_drive  
  attr_accessor   :binding_start
  attr_accessor   :bind_resist
  #--------------------------------------------------------------------------
  # ○ クリア
  #--------------------------------------------------------------------------
  def clear
    clear_hit_flags
    clear_damage_values
    clear_status_effects
    clear_nwapeg_extends
    clear_stealed_information
    clear_battler_ability
    clear_binded_information
  end
  #--------------------------------------------------------------------------
  # ● 前任が拡張した機能情報のクリア 
  # 要整理
  #--------------------------------------------------------------------------
  def clear_nwapeg_extends
    @unusable     = -1
    @predation    = false
    @pleasure     = false #
    @hp_restore   = 0
    @mp_restore   = 0
  end  
  #--------------------------------------------------------------------------
  # ● スティール結果情報のクリア
  #--------------------------------------------------------------------------
  def clear_stealed_information
    @stealed            = false
    @stealed_item_empty = false
    @stealed_item_kind  = 0
    @stealed_item_id    = 0
  end
  #--------------------------------------------------------------------------
  # ● バトラーアビリティフラグのクリア
  #--------------------------------------------------------------------------
  def clear_battler_ability
    @auto_stand      = false
    @invalidate_wall = false
    @defense_wall    = false
    @over_drive      = false
  end
  #--------------------------------------------------------------------------
  # ● 拘束結果情報のクリア
  #--------------------------------------------------------------------------
  def clear_binded_information
    @binding_start   = -1
    @bind_resist     = false
  end
  #--------------------------------------------------------------------------
  # ○ 最終的に命中したか否かを判定
  #--------------------------------------------------------------------------
  def hit?
    @used && !@missed && !@evaded && @unusable == -1
  end
  #--------------------------------------------------------------------------
  # ● 還元される？
  #--------------------------------------------------------------------------
  def restoration?
    return (0 < @hp_restore) || (0 < @mp_restore)
  end
  #--------------------------------------------------------------------------
  # ● 失敗時の文章を取得
  #--------------------------------------------------------------------------
  def unusable_text
    if (0...5).include?(@unusable)
      values = ["ＨＰ", "ＭＰ", "ＳＰ", "ゴールド", "アイテム"]
      return sprintf(Vocab::Shortage, values[@unusable])
    elsif @unusable == 5
      return Vocab::SkillSealedFailure
    elsif @unusable == 6
      return Vocab::TemptationActionFailure
    end
    return ""
  end
  #--------------------------------------------------------------------------
  # ● ダメージ還元の文章を取得
  #--------------------------------------------------------------------------
  def restoration_text(subject)
    ary = []
    ary.push("HP#{@hp_restore}") if 0 < @hp_restore
    ary.push("MP#{@mp_restore}") if 0 < @mp_restore    
    return sprintf(Vocab::ReStoration, subject.name, ary.join(", "))
  end
end

#==============================================================================
# ■ Game_BattlerBase
#==============================================================================
class Game_BattlerBase
  #--------------------------------------------------------------------------
  # ● 定数（能力強化／弱体アイコンの開始番号）
  #--------------------------------------------------------------------------
  ICON_BUFF_START       = 80              # 強化（16 個）
  ICON_DEBUFF_START     = 120             # 弱体（16 個）
  #--------------------------------------------------------------------------
  # ● Mix-In
  #--------------------------------------------------------------------------
  include       NWFeature
  include       NWFeature::PartyEx
  include       NWFeature::Battler
  include       NWFeature::Booster
  #--------------------------------------------------------------------------
  # ○ TP の割合を取得
  #--------------------------------------------------------------------------
  def tp_rate
    0 < max_tp ? tp / max_tp.to_f : 0.0
  end
  #--------------------------------------------------------------------------
  # ● 特徴値の最高値（データ ID を指定）
  #--------------------------------------------------------------------------
  def features_max(code, id)
    features_with_id(code, id).inject(0.0){|r, ft|r = r < ft.value ? ft.value : r}
  end
  #--------------------------------------------------------------------------
  # ● 特徴値の最低値（データ ID を指定）
  #--------------------------------------------------------------------------
  def features_min(code, id)
    features_with_id(code, id).inject(1.0){|r, ft|r = r > ft.value ? ft.value : r}
  end
  #--------------------------------------------------------------------------
  # ● ブースター用特徴値総和計算
  #--------------------------------------------------------------------------
  def features_sum_booster(feature_id, data_id)
    features_with_id(FEATURE_MULTI_BOOSTER, feature_id).inject(0.0){|sum, ft|
      ft.value.key?(data_id) ? sum + ft.value[data_id] : sum
    }
  end  
  #--------------------------------------------------------------------------
  # ○ 通常能力値の最大値取得
  #--------------------------------------------------------------------------
  def param_max(param_id)
    return 999999 if param_id == 0  # MHP
    return 9999
  end
  #--------------------------------------------------------------------------
  # ○ 通常能力値の取得
  #--------------------------------------------------------------------------
  def param(param_id)
    value = param_base(param_id) + param_plus(param_id)
    value *= param_rate(param_id) * param_buff_rate(param_id)   
    if $game_party.in_battle && (2..7).include?(param_id)
      value *= (booster_fall_hp && hp_rate < booster_fall_hp[:per]) ? 1.0 + booster_fall_hp[:boost] : 1.0
      value *= 1.0 + (friends_unit.dead_members.size * over_soul)
      value *= terrain_revise
    end
    Integer([[value, param_max(param_id)].min, param_min(param_id)].max)
  end
  #--------------------------------------------------------------------------
  # ○ 追加能力値の取得
  #--------------------------------------------------------------------------
  def xparam(xparam_id)
    x = features_max(FEATURE_XPARAM, xparam_id)
    x = 0.9 if xparam_id == 0 && x == 0.0 # 命中率
    x += features_sum(FEATURE_XPARAM_EX, xparam_id)
    return [7,8,9].include?(xparam_id) ? x : [0.0, x].max
  end
  #--------------------------------------------------------------------------
  # ○ 攻撃追加回数の取得
  #--------------------------------------------------------------------------
  def atk_times_add
    features(FEATURE_ATK_TIMES).inject(0.0){|r, ft| r < ft.value ? ft.value : r}
  end
  #--------------------------------------------------------------------------
  # ○ 防御効果率の取得
  #--------------------------------------------------------------------------
  def grd
    [1.0, features_max(FEATURE_SPARAM, 1)].max
  end
  #--------------------------------------------------------------------------
  # ○ 回復効果率の取得
  #--------------------------------------------------------------------------
  def rec
    [1.0, features_max(FEATURE_SPARAM, 2)].max
  end
  #--------------------------------------------------------------------------
  # ○ 薬の知識の取得
  #--------------------------------------------------------------------------
  def pha
    [1.0, features_max(FEATURE_SPARAM, 3)].max
  end
  #--------------------------------------------------------------------------
  # ○ TPチャージ率の取得
  #--------------------------------------------------------------------------
  def tcr
    [1.0, features_max(FEATURE_SPARAM, 5)].max
  end
  #--------------------------------------------------------------------------
  # ● 獲得金額倍率
  #--------------------------------------------------------------------------
  def get_gold_rate
    [1.0, features_max(FEATURE_PARTY_EX_ABILITY, GET_GOLD_RATE)].max
  end
  #--------------------------------------------------------------------------
  # ● 獲得アイテム倍率
  #--------------------------------------------------------------------------
  def get_item_rate
    [1.0, features_max(FEATURE_PARTY_EX_ABILITY, GET_ITEM_RATE)].max
  end
  #--------------------------------------------------------------------------
  # ● エンカウント倍率
  #--------------------------------------------------------------------------
  def encounter_rate
    features_with_id(FEATURE_PARTY_EX_ABILITY, ENCOUNTER_RATE).collect{|ft| ft.value}
  end
  #--------------------------------------------------------------------------
  # ● 仲間加入倍率
  #--------------------------------------------------------------------------
  def collect_rate
    [1.0, features_max(FEATURE_PARTY_EX_ABILITY, COLLECT_RATE)].max
  end
  #--------------------------------------------------------------------------
  # ● スロットチャンス
  #--------------------------------------------------------------------------
  def slot_chance
    features_max(FEATURE_PARTY_EX_ABILITY, SLOT_CHANCE).to_i
  end
  #--------------------------------------------------------------------------
  # ● 解錠レベル
  #--------------------------------------------------------------------------
  def unlock_level
    features_max(FEATURE_PARTY_EX_ABILITY, UNLOCK_LEVEL).to_i
  end
  #--------------------------------------------------------------------------
  # ● 盗み成功率を取得
  #--------------------------------------------------------------------------
  def steal_success
    [1.0, features_max(FEATURE_BATTLER_ABILITY, STEAL_SUCCESS)].max
  end
  #--------------------------------------------------------------------------
  # ○ 獲得経験値倍率を取得
  #--------------------------------------------------------------------------
  def exr
    max = features_max(FEATURE_BATTLER_ABILITY, GET_EXP_RATE)
    min = features_min(FEATURE_BATTLER_ABILITY, GET_EXP_RATE)
    return [max, 1.0].max - (1.0 - min)
  end
  #--------------------------------------------------------------------------
  # ● 獲得職業経験値倍率を取得
  #--------------------------------------------------------------------------
  def cexr
    max = features_max(FEATURE_BATTLER_ABILITY, GET_CLASSEXP_RATE)
    min = features_min(FEATURE_BATTLER_ABILITY, GET_CLASSEXP_RATE)
    return [max, 1.0].max - (1.0 - min)
  end  
  #--------------------------------------------------------------------------
  # ● 踏みとどまり値を取得
  #--------------------------------------------------------------------------
  def auto_stand
    features_min(FEATURE_BATTLER_ABILITY, AUTO_STAND)
  end  
  #--------------------------------------------------------------------------
  # ● 回復反転値を取得
  #--------------------------------------------------------------------------
  def heel_reverse
    features_max(FEATURE_BATTLER_ABILITY, HEEL_REVERSE)
  end
  #--------------------------------------------------------------------------
  # ● オートステートID配列を取得
  #--------------------------------------------------------------------------
  def auto_state
    features_with_id(FEATURE_BATTLER_ABILITY, AUTO_STATE).inject([]){|r, ft| r | ft.value}
  end  
  #--------------------------------------------------------------------------
  # ● トリガーステートを取得
  #--------------------------------------------------------------------------
  def trigger_state
    features_with_id(FEATURE_BATTLER_ABILITY, TRIGGER_STATE).collect{|ft| ft.value}
  end
  #--------------------------------------------------------------------------
  # ● メタルボディ上限値を取得
  #--------------------------------------------------------------------------
  def metal_body
    features_with_id(FEATURE_BATTLER_ABILITY, METAL_BODY).inject([]){|r, ft| r | [ft.value]}.min
  end
  #--------------------------------------------------------------------------
  # ● 防御壁展開を取得
  #--------------------------------------------------------------------------
  def defense_wall
    features_with_id(FEATURE_BATTLER_ABILITY, DEFENSE_WALL).inject([]){|r, ft| r | [ft.value]}.max
  end
  #--------------------------------------------------------------------------
  # ● 無効化障壁を取得
  #--------------------------------------------------------------------------
  def invalidate_wall
    features_with_id(FEATURE_BATTLER_ABILITY, INVALIDATE_WALL).inject([]){|r, ft| r | [ft.value]}.max
  end
  #--------------------------------------------------------------------------
  # ● ダメージMP変換を取得
  #--------------------------------------------------------------------------
  def damage_mp_convert
    features_with_id(FEATURE_BATTLER_ABILITY, DAMAGE_MP_CONVERT).inject([]){|r, ft| r | [ft.value]}.min
  end  
  #--------------------------------------------------------------------------
  # ● ダメージゴールド変換を取得
  #--------------------------------------------------------------------------
  def damage_gold_convert
    features_with_id(FEATURE_BATTLER_ABILITY, DAMAGE_GOLD_CONVERT).inject([]){|r, ft| r | [ft.value]}.min
  end
  #--------------------------------------------------------------------------
  # ● ダメージMP吸収を取得
  #--------------------------------------------------------------------------
  def damage_mp_drain
    features_with_id(FEATURE_BATTLER_ABILITY, DAMAGE_MP_DRAIN).inject([]){|r, ft| r | [ft.value]}.max
  end  
  #--------------------------------------------------------------------------
  # ● ダメージゴールド回収を取得
  #--------------------------------------------------------------------------
  def damage_gold_drain
    features_with_id(FEATURE_BATTLER_ABILITY, DAMAGE_GOLD_DRAIN).inject([]){|r, ft| r | [ft.value]}.max
  end
  #--------------------------------------------------------------------------
  # ● 死亡時スキルを取得
  #--------------------------------------------------------------------------
  def dead_skill
    features_with_id(FEATURE_BATTLER_ABILITY, DEAD_SKILL).inject([]){|r, ft| r |= [ft.value]}.max
  end
  #--------------------------------------------------------------------------
  # ● 戦闘開始時スキルを取得
  #--------------------------------------------------------------------------
  def battle_start_skill
    features_with_id(FEATURE_BATTLER_ABILITY, BATTLE_START_SKILL).inject([]){|r, ft| r.push(ft.value)}
  end
  #--------------------------------------------------------------------------
  # ● ターン開始時スキルを取得
  #--------------------------------------------------------------------------
  def turn_start_skill
    features_with_id(FEATURE_BATTLER_ABILITY, TURN_START_SKILL).inject([]){|r, ft| r.push(ft.value)}
  end
  #--------------------------------------------------------------------------
  # ● ターン終了時スキルを取得
  #--------------------------------------------------------------------------
  def turn_end_skill
    features_with_id(FEATURE_BATTLER_ABILITY, TURN_END_SKILL).inject([]){|r, ft| r.push(ft.value)}
  end
  #--------------------------------------------------------------------------
  # ● 行動変化を取得
  #--------------------------------------------------------------------------
  def change_action
    features_with_id(FEATURE_BATTLER_ABILITY, CHANGE_ACTION).inject([]){|r, ft| r += [ft.value]}.flatten.shuffle
  end
  #--------------------------------------------------------------------------
  # ● スキル変化を取得
  #--------------------------------------------------------------------------
  def change_skill(src_skill_id)
    features_with_id(FEATURE_BATTLER_ABILITY, CHANGE_SKILL).inject({}){|sum, ft|
      sum.merge(ft.value)
    }[src_skill_id]
  end  
  #--------------------------------------------------------------------------
  # ● スキルタイプ消費率を取得
  #--------------------------------------------------------------------------
  def stype_cost_rate(stype_id, type)
    features_with_id(FEATURE_BATTLER_ABILITY, STYPE_COST_RATE).select{|ft|
      ft.value[:type] == type
    }.inject(1.0){|r, ft|
      if ft.value[:id] == stype_id then r *= ft.value[:rate] else r end    
    }
  end  
  #--------------------------------------------------------------------------
  # ● HPタイプ消費率を取得
  #--------------------------------------------------------------------------
  def stype_cost_rate_hp(skill)
    skill.stypes.inject(1.0){|r, stype_id| r *= stype_cost_rate(stype_id, :HP)}
  end
  #--------------------------------------------------------------------------
  # ● MPタイプ消費率を取得
  #--------------------------------------------------------------------------
  def stype_cost_rate_mp(skill)
    skill.stypes.inject(1.0){|r, stype_id| r *= stype_cost_rate(stype_id, :MP)}
  end  
  #--------------------------------------------------------------------------
  # ● TPタイプ消費率を取得
  #--------------------------------------------------------------------------
  def stype_cost_rate_tp(skill)
    skill.stypes.inject(1.0){|r, stype_id| r *= stype_cost_rate(stype_id, :TP)}
  end  
  #--------------------------------------------------------------------------
  # ● スキル消費率を取得
  #--------------------------------------------------------------------------
  def skill_cost_rate(skill_id, type)
    features_with_id(FEATURE_BATTLER_ABILITY, SKILL_COST_RATE).select{|ft|
      ft.value[:type] == type
    }.inject(1.0){|r, ft|
      if ft.value[:id] == skill_id then r *= ft.value[:rate] else r end    
    }
  end  
  #--------------------------------------------------------------------------
  # ● HPスキル消費率を取得
  #--------------------------------------------------------------------------
  def skill_cost_rate_hp(skill)
    skill_cost_rate(skill.id, :HP)
  end
  #--------------------------------------------------------------------------
  # ● MPスキル消費率を取得
  #--------------------------------------------------------------------------
  def skill_cost_rate_mp(skill)
    skill_cost_rate(skill.id, :MP)
  end
  #--------------------------------------------------------------------------
  # ● TPスキル消費率を取得
  #--------------------------------------------------------------------------
  def skill_cost_rate_tp(skill)
    skill_cost_rate(skill.id, :TP)
  end
  #--------------------------------------------------------------------------
  # ● TP消費率を取得
  #--------------------------------------------------------------------------
  def tp_cost_rate
    features_min(FEATURE_BATTLER_ABILITY, TP_COST_RATE)
  end  
  #--------------------------------------------------------------------------
  # ● HP消費率を取得
  #--------------------------------------------------------------------------
  def hp_cost_rate
    features_min(FEATURE_BATTLER_ABILITY, HP_COST_RATE)
  end  
  #--------------------------------------------------------------------------
  # ● ゴールド消費率を取得
  #--------------------------------------------------------------------------
  def gold_cost_rate
    features_pi(FEATURE_BATTLER_ABILITY, GOLD_COST_RATE)
  end
  #--------------------------------------------------------------------------
  # ● 消費アイテム節約率を取得
  #--------------------------------------------------------------------------
  def item_cost_scrimp(item_id)
    list = [0]
    features_with_id(FEATURE_BATTLER_ABILITY, ITEM_COST_SCRIMP).each {|ft|
      list.push(ft.value[item_id]) if ft.value[item_id]
    }
    return list.max
  end
  #--------------------------------------------------------------------------
  # ● 必要アイテム無視を取得
  #--------------------------------------------------------------------------
  def need_item_ignore?(item_id)
    features_with_id(FEATURE_BATTLER_ABILITY, NEED_ITEM_IGNORE).any?{|ft| ft.value.include?(item_id)}
  end
  #--------------------------------------------------------------------------
  # ● 固定TP増加値を取得
  #--------------------------------------------------------------------------
  def increase_tp_fix
    features_with_id(FEATURE_BATTLER_ABILITY, INCREASE_TP).select{|ft|
      !ft.value[:per]
    }.inject(0){|sum, ft|
      sum += ft.value[:plus] ? ft.value[:num] : -ft.value[:num]
    }
  end  
  #--------------------------------------------------------------------------
  # ● 割合TP増加値を取得
  #--------------------------------------------------------------------------
  def increase_tp_per
    hoge = features_with_id(FEATURE_BATTLER_ABILITY, INCREASE_TP).select{|ft|
      ft.value[:per]
    }.inject(1.0){|sum, ft|
      sum += ft.value[:plus] ? ft.value[:num] * 0.01 : -ft.value[:num] * 0.01
    }
  end
  #--------------------------------------------------------------------------
  # ● 開始時TPを取得
  #--------------------------------------------------------------------------
  def start_tp_rate
    features_max(FEATURE_BATTLER_ABILITY, START_TP_RATE)
  end
  #--------------------------------------------------------------------------
  # ● 戦闘後HP回復を取得
  #--------------------------------------------------------------------------
  def battle_end_heel_hp
    features_max(FEATURE_BATTLER_ABILITY, BATTLE_END_HEEL_HP)
  end  
  #--------------------------------------------------------------------------
  # ● 戦闘後MP回復を取得
  #--------------------------------------------------------------------------
  def battle_end_heel_mp
    features_max(FEATURE_BATTLER_ABILITY, BATTLE_END_HEEL_MP)
  end
  #--------------------------------------------------------------------------
  # ○ 通常攻撃用スキルIDを取得
  #--------------------------------------------------------------------------
  def attack_skill_id
    features_with_id(FEATURE_BATTLER_ABILITY, Battler::NORMAL_ATTACK).inject([1]){|r, ft| r | [ft.value]}.max
  end
  #--------------------------------------------------------------------------
  # ● 反撃スキルを取得
  #--------------------------------------------------------------------------
  def counter_skill
    features_with_id(FEATURE_BATTLER_ABILITY, COUNTER_SKILL).inject([]){|r, ft| r | [ft.value]}.flatten.sample
  end
  #--------------------------------------------------------------------------
  # ● 最終反撃を取得
  #--------------------------------------------------------------------------
  def final_invoke
    features_with_id(FEATURE_BATTLER_ABILITY, FINAL_INVOKE).inject([]){|r, ft| r | [ft.value]}.flatten.sample
  end
  #--------------------------------------------------------------------------
  # ● 必中反撃率を取得
  #--------------------------------------------------------------------------
  def certain_counter
    features_with_id(FEATURE_BATTLER_ABILITY, CERTAIN_COUNTER).inject(0.0){|sum, ft| sum + ft.value}
  end
  #--------------------------------------------------------------------------
  # ● 魔法反撃率を取得
  #--------------------------------------------------------------------------
  def magical_counter
    features_with_id(FEATURE_BATTLER_ABILITY, MAGICAL_COUNTER).inject(0.0){|sum, ft| sum + ft.value}
  end
  #--------------------------------------------------------------------------
  # ● 拡張必中反撃率を取得
  #--------------------------------------------------------------------------
  def certain_counter_ex
    features_with_id(FEATURE_BATTLER_ABILITY, CERTAIN_COUNTER_EX).inject(0.0){|sum, ft| sum + ft.value}
  end
  #--------------------------------------------------------------------------
  # ● 拡張反撃率を取得
  #--------------------------------------------------------------------------
  def physical_counter_ex
    features_with_id(FEATURE_BATTLER_ABILITY, PHYSICAL_COUNTER_EX).inject(0.0){|sum, ft| sum + ft.value}
  end
  #--------------------------------------------------------------------------
  # ● 拡張魔法反撃率を取得
  #--------------------------------------------------------------------------
  def magical_counter_ex
    features_with_id(FEATURE_BATTLER_ABILITY, MAGICAL_COUNTER_EX).inject(0.0){|sum, ft| sum + ft.value}
  end
  #--------------------------------------------------------------------------
  # ● 仲間想い補正を取得
  #--------------------------------------------------------------------------
  def considerate
    features_max(FEATURE_BATTLER_ABILITY, CONSIDERATE)
  end
  #--------------------------------------------------------------------------
  # ● 連続発動を取得
  #--------------------------------------------------------------------------
  def invoke_repeats(item)
    return 1 unless item.is_skill?
    stype_max = item.stypes.inject(1){|max, stype_id|
      features_with_id(FEATURE_BATTLER_ABILITY, INVOKE_REPEATS_TYPE).each{|ft|
        if ft.value.key?(stype_id)
          max = max < ft.value[stype_id] ? ft.value[stype_id] : max
        end
      }
      max
    }
    skill_max = features_with_id(FEATURE_BATTLER_ABILITY, INVOKE_REPEATS_SKILL).inject(1){|max, ft|
      if ft.value.key?(item.id) then max < ft.value[item.id] ? ft.value[item.id] : max else max end
    }
    return [stype_max, skill_max].max
  end
  #--------------------------------------------------------------------------
  # ● 自爆耐性判定を取得
  #--------------------------------------------------------------------------
  def own_crush_resist?
    !features_with_id(FEATURE_BATTLER_ABILITY, OWN_CRUSH_RESIST).empty?
  end
  #--------------------------------------------------------------------------
  # ● 属性吸収判定を取得
  #--------------------------------------------------------------------------
  def element_drain?(element_id)
    features_with_id(FEATURE_BATTLER_ABILITY, ELEMENT_DRAIN).inject([]){|r, ft| r | ft.value}.include?(element_id)
  end
  #--------------------------------------------------------------------------
  # ● 時間停止無視を取得
  #--------------------------------------------------------------------------
  def ignore_over_drive?
    !features_with_id(FEATURE_BATTLER_ABILITY, IGNORE_OVER_DRIVE).empty?
  end
  #--------------------------------------------------------------------------
  # ● 即死反転を取得
  #--------------------------------------------------------------------------
  def instant_dead_reverse?
    !features_with_id(FEATURE_BATTLER_ABILITY, INSTANT_DEAD_REVERSE).empty?
  end
  #--------------------------------------------------------------------------
  # ● 属性ブースター倍率を取得
  #--------------------------------------------------------------------------
  def booster_element(element_id)
    1.0 + features_sum_booster(ELEMENT, element_id)
  end
  #--------------------------------------------------------------------------
  # ● 武器強化物理倍率を取得
  #--------------------------------------------------------------------------
  def booster_weapon_physical(wtype_id)
    1.0 + features_sum_booster(WEAPON_PHYSICAL, wtype_id)
  end
  #--------------------------------------------------------------------------
  # ● 武器強化魔法倍率を取得
  #--------------------------------------------------------------------------
  def booster_weapon_magical(wtype_id)
    1.0 + features_sum_booster(WEAPON_MAGICAL, wtype_id)
  end
  #--------------------------------------------------------------------------
  # ● 武器強化必中倍率を取得
  #--------------------------------------------------------------------------
  def booster_weapon_certain(wtype_id)
    1.0 + features_sum_booster(WEAPON_CERTAIN, wtype_id)
  end
  #--------------------------------------------------------------------------
  # ● 通常攻撃強化倍率を取得
  #--------------------------------------------------------------------------
  def booster_normal_attack(wtype_id)
    1.0 + features_sum_booster(Booster::NORMAL_ATTACK, wtype_id)
  end
  #--------------------------------------------------------------------------
  # ● ステート割合強化タイプ倍率を取得
  #--------------------------------------------------------------------------
  def booster_state_ratio_type(skill)
    1.0 + skill.stypes.inject(0.0){|sum, id|
      sum + features_sum_booster(STATE_RATIO_TYPE, id)
    }    
  end
  #--------------------------------------------------------------------------
  # ● ステート固定強化タイプを取得
  #--------------------------------------------------------------------------
  def booster_state_fix_type(skill)
    skill.stypes.inject(0.0){|sum, id|
      sum + features_sum_booster(STATE_FIX_TYPE, id)
    }
  end
  #--------------------------------------------------------------------------
  # ● スキルタイプ強化倍率を取得
  #--------------------------------------------------------------------------
  def booster_skill_type(skill)
    1.0 + skill.stypes.inject(0.0){|sum, id|
      sum + features_sum_booster(SKILL_TYPE, id)
    }
  end
  #--------------------------------------------------------------------------
  # ● ステート割合強化スキル倍率を取得
  #--------------------------------------------------------------------------
  def booster_state_ratio_skill(skill)
    1.0 + features_sum_booster(STATE_RATIO_SKILL, skill.id)
  end
  #--------------------------------------------------------------------------
  # ● スキル強化倍率を取得
  #--------------------------------------------------------------------------
  def booster_skill(skill)
    1.0 + features_sum_booster(SKILL, skill.id)
  end
  #--------------------------------------------------------------------------
  # ● 武器スキル強化倍率を取得
  #--------------------------------------------------------------------------
  def booster_wtype_skill(wtype_skill)
    1.0 + features_sum_booster(WTYPE_SKILL, wtype_skill)
  end
  #--------------------------------------------------------------------------
  # ● カウンター強化倍率を取得
  #--------------------------------------------------------------------------
  def booster_counter
    1.0 + features_sum(FEATURE_MULTI_BOOSTER, COUNTER)
  end
  #--------------------------------------------------------------------------
  # ● HP減少時強化を取得
  #--------------------------------------------------------------------------
  def booster_fall_hp
    features_with_id(FEATURE_MULTI_BOOSTER, FALL_HP).collect{|ft| 
      ft.value
    }.sort{|a, b|b[:boost] <=> a[:boost]}.first
  end
  #--------------------------------------------------------------------------
  # ● オーバーソウルを取得
  #--------------------------------------------------------------------------
  def over_soul
    features_max(FEATURE_MULTI_BOOSTER, OVER_SOUL)
  end
  #--------------------------------------------------------------------------
  # ● 地形補正を取得
  #--------------------------------------------------------------------------
  def terrain_revise
    return 1.0 + features_max(FEATURE_TERRAIN_BOOSTER, BattleManager.terrain)
  end
  #--------------------------------------------------------------------------
  # ● 誘惑状態判定
  #--------------------------------------------------------------------------
  def temptation?
    exist? && state?(NWConst::State::TEMPTATION)
  end
  #--------------------------------------------------------------------------
  # ○ スキルの消費 MP 計算
  #--------------------------------------------------------------------------
  def skill_mp_cost(skill)
    cost = skill.mp_cost
    if skill.mp_cost_ex
      cost  = skill.mp_cost_ex[:data]      
      cost *= 0.01 * (skill.mp_cost_ex[:max?] ? mmp : mp) if skill.mp_cost_ex[:per?]
      return cost.ceil if skill.mp_cost_ex[:abs?]
    end
    return (cost * mcr * stype_cost_rate_mp(skill) * skill_cost_rate_mp(skill)).ceil
  end
  #--------------------------------------------------------------------------
  # ○ スキルの消費 TP 計算
  #--------------------------------------------------------------------------
  def skill_tp_cost(skill)
    cost = skill.tp_cost
    if skill.tp_cost_ex
      cost  = skill.tp_cost_ex[:data]
      cost *= 0.01 * (skill.tp_cost_ex[:max?] ? max_tp : tp) if skill.tp_cost_ex[:per?]
      return cost.ceil if skill.tp_cost_ex[:abs?]
    end
    return (cost * tp_cost_rate * stype_cost_rate_tp(skill) * skill_cost_rate_tp(skill)).ceil
  end
  #--------------------------------------------------------------------------
  # ● スキルの消費 HP 計算
  #--------------------------------------------------------------------------
  def skill_hp_cost(skill)
    cost = 0
    if skill.hp_cost_ex
      cost  = skill.hp_cost_ex[:data]      
      cost *= 0.01 * (skill.hp_cost_ex[:max?] ? mhp : hp) if skill.hp_cost_ex[:per?]
      return cost.ceil if skill.hp_cost_ex[:abs?]
    end
    return (cost * hp_cost_rate * stype_cost_rate_hp(skill) * skill_cost_rate_hp(skill)).ceil
  end
  #--------------------------------------------------------------------------
  # ● スキルの消費 金額 計算
  #--------------------------------------------------------------------------
  def skill_gold_cost(skill)
    return (skill.gold_cost * gold_cost_rate).ceil
  end
  #--------------------------------------------------------------------------
  # ● スキル使用時必要アイテムの所持判定
  #--------------------------------------------------------------------------
  def skill_need_item?(skill)
    skill.item_cost.all?{|cost| cost[:num] <= $game_party.item_number($data_items[cost[:id]])} &&
    skill.need_item.all?{|item_id|
      $game_party.has_item?($data_items[item_id]) || need_item_ignore?(item_id)
    }
  end
  #--------------------------------------------------------------------------
  # ● スキルの二刀流要求判定
  #--------------------------------------------------------------------------
  def skill_need_dual_wield?(skill)
    return true unless skill.need_dual_wield?
    return true if actor? && dual_wield? && weapons[1]
    return false
  end  
  #--------------------------------------------------------------------------
  # ○ スキル使用コストの支払い
  #--------------------------------------------------------------------------
  def pay_skill_cost(skill)
    self.hp -= skill_hp_cost(skill)
    self.mp -= skill_mp_cost(skill)
    self.tp -= skill_tp_cost(skill)
    $game_party.lose_gold(skill_gold_cost(skill))
    skill.item_cost.each{|cost|
      next if rand < item_cost_scrimp(cost[:id])
      $game_party.lose_item($data_items[cost[:id]], cost[:num])
    }
  end
  #--------------------------------------------------------------------------
  # ○ スキル使用コストの支払い可能判定
  #--------------------------------------------------------------------------
  def skill_cost_payable?(skill)
    tp >= skill_tp_cost(skill) &&
    mp >= skill_mp_cost(skill) &&
    hp > skill_hp_cost(skill) &&
    $game_party.gold >= skill_gold_cost(skill)    
  end
  #--------------------------------------------------------------------------
  # ○ スキルの使用可能条件チェック
  #--------------------------------------------------------------------------
  def skill_conditions_met?(skill)
    usable_item_conditions_met?(skill) &&
    skill_wtype_ok?(skill) &&
    skill_cost_payable?(skill) &&
    !skill_sealed?(skill.id) &&
    !skill.stypes.all?{|stype_id| skill_type_sealed?(stype_id)} &&
    skill_need_item?(skill) &&
    skill_need_dual_wield?(skill) &&
    !(temptation? && !$game_actors[NWConst::Actor::LUCA].alive?)
  end
  #--------------------------------------------------------------------------
  # ○ 装備可能判定
  #--------------------------------------------------------------------------
  def equippable?(item)
    return false unless item.is_a?(RPG::EquipItem)
    return false if equip_type_sealed?(item.etype_id)
    return false if item.exclusive_actors && !item.exclusive_actors.include?(self.id)
    if item.is_a?(RPG::Weapon)
      return false if item.not_dual_wield? && weapons.size == 2
      return equip_wtype_ok?(item.wtype_id)
    elsif item.is_a?(RPG::Armor)
      return equip_atype_ok?(item.atype_id)
    end
    return false
  end
  #--------------------------------------------------------------------------
  # ○ スキル／アイテムの使用可能判定
  #--------------------------------------------------------------------------
  def usable?(item)
    result = false
    result = skill_conditions_met?(item) if item.is_a?(RPG::Skill)
    result = item_conditions_met?(item) if item.is_a?(RPG::Item)
    return result && usable_item_sex_ok?(item)
  end
  #--------------------------------------------------------------------------
  # ● スキル／アイテムの性別使用可能条件チェック 
  #--------------------------------------------------------------------------
  def usable_item_sex_ok?(item)
    # 無差別なら無条件で可能
    return true if item.ext_scope == NWSex::ALL
    case item.scope
    # 敵の中に、拡張スコープに合致するものがいれば使用可能
    when 1..6
      return true unless opponents_unit.alive_members_ex(item.ext_scope).empty?
    # 味方の中に、〃
    when 7..8
      return true unless friends_unit.alive_members_ex(item.ext_scope).empty?
    # 味方死者の中に、〃
    when 9..10
      return true unless friends_unit.dead_members_ex(item.ext_scope).empty?
    # 自分に、〃
    when 11
      return true unless (self.sex & item.ext_scope) != 0
    end
    return false
  end
  #--------------------------------------------------------------------------
  # ● もがくのスキル ID を取得
  #--------------------------------------------------------------------------
  def bind_resist_skill_id
    return NWConst::Skill::BIND_RESIST
  end
  #--------------------------------------------------------------------------
  # ● なすがままのスキル ID を取得
  #--------------------------------------------------------------------------
  def mercy_skill_id
    return NWConst::Skill::MERCY
  end
  #--------------------------------------------------------------------------
  # ○ スキル／アイテムの使用可能時チェック
  #--------------------------------------------------------------------------
  def occasion_ok?(item)
    ($game_party.in_battle ? item.battle_ok? : item.menu_ok?) && throw_ok?(item)
  end
  #--------------------------------------------------------------------------
  # ● 投擲専用アイテムの使用可能チェック
  # 「忍術」持ちのみ使用可能
  #--------------------------------------------------------------------------
  def throw_ok?(item)
    return true unless item.throw?
    return true if added_skill_types.include?(31) 
    return false
  end  
end

#==============================================================================
# ■ Game_Battler
#==============================================================================
class Game_Battler < Game_BattlerBase  
  #--------------------------------------------------------------------------
  # ● Mix-In（使用効果）
  #--------------------------------------------------------------------------
  include NWUsableEffect

  #--------------------------------------------------------------------------
  # ○ オブジェクト初期化
  #--------------------------------------------------------------------------
  def initialize
    @battler_name = ""
    @battler_hue = 0
    @actions = []
    @speed = 0
    @result = Game_ActionResult.new(self)
    @last_target_index = 0
    @guarding = false
    clear_sprite_effects
    clear_counter
    super
  end
  #--------------------------------------------------------------------------
  # ● 性別
  #--------------------------------------------------------------------------
  def sex
    return NWSex::FEMALE
  end
  #--------------------------------------------------------------------------
  # ● ルカ？
  #--------------------------------------------------------------------------
  def luca?
    return actor? && self.id == NWConst::Actor::LUCA
  end
  #--------------------------------------------------------------------------
  # ● 捕食されているか
  #--------------------------------------------------------------------------
  def predationed?
    @predationed
  end
  #--------------------------------------------------------------------------
  # ○ ステートの付加
  #--------------------------------------------------------------------------
  def add_state(state_id)
    display_state_id = state_id
    state_id = death_state_id if $data_states[state_id].death?    
    if state_addable?(state_id)
      add_new_state(state_id) unless state?(state_id)
      reset_state_counts(state_id)
      @result.added_states.push(display_state_id).uniq!
    end
  end
  #--------------------------------------------------------------------------
  # ○ ステートの解除
  #--------------------------------------------------------------------------
  def remove_state(state_id)
    if state?(state_id)
      revive if state_id == death_state_id
      erase_state(state_id)
      refresh
      @result.removed_states.push(state_id).uniq!
      BattleManager.bind_refresh if $game_party.in_battle
    end
  end
  #--------------------------------------------------------------------------
  # ○ 行動回数の決定
  #--------------------------------------------------------------------------
  def make_action_times
    return 1 + (action_plus_set.empty? ? 0 : action_plus_set.max.floor)
  end
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
    item_user_effect(user, item)
  end
  #--------------------------------------------------------------------------
  # ○ 使用効果の適用
  #--------------------------------------------------------------------------
  def item_effect_apply(user, item, effect)    
    method_table = {
      EFFECT_RECOVER_HP    => :item_effect_recover_hp,
      EFFECT_RECOVER_MP    => :item_effect_recover_mp,
      EFFECT_GAIN_TP       => :item_effect_gain_tp,
      EFFECT_ADD_STATE     => :item_effect_add_state,
      EFFECT_REMOVE_STATE  => :item_effect_remove_state,
      EFFECT_ADD_BUFF      => :item_effect_add_buff,
      EFFECT_ADD_DEBUFF    => :item_effect_add_debuff,
      EFFECT_REMOVE_BUFF   => :item_effect_remove_buff,
      EFFECT_REMOVE_DEBUFF => :item_effect_remove_debuff,
      EFFECT_SPECIAL       => :item_effect_special,
      EFFECT_GROW          => :item_effect_grow,
      EFFECT_LEARN_SKILL   => :item_effect_learn_skill,
      EFFECT_COMMON_EVENT  => :item_effect_common_event,
      EFFECT_STEAL         => :item_effect_steal,
      EFFECT_GET_ITEM      => :item_effect_get_item,
      EFFECT_DEFENSE_WALL  => :item_effect_defense_wall,
      EFFECT_OVER_DRIVE    => :item_effect_over_drive,
      EFFECT_GAIN_EXP      => :item_effect_gain_exp,
      EFFECT_DEATH_ELEMENT => :item_effect_death_element,
      EFFECT_DEATH_STATE   => :item_effect_death_state,
      EFFECT_PREDATION     => :item_effect_predation,
      EFFECT_SELF_ENCHANT  => :item_effect_self_enchant,
      EFFECT_RESTORATION   => :item_effect_restoration,
      EFFECT_BINDING_START => :item_effect_binding_start,
      EFFECT_BIND_RESIST   => :item_effect_bind_resist,
    }
    method_name = method_table[effect.code]
    send(method_name, user, item, effect) if method_name
  end
  #--------------------------------------------------------------------------
  # ○ 使用効果［HP 回復］
  #--------------------------------------------------------------------------
  def item_effect_recover_hp(user, item, effect)
    value = (mhp * effect.value1 + effect.value2) * rec
    value *= user.pha if item.is_a?(RPG::Item)
    value *= -heel_reverse if $game_party.in_battle && 0.0 < heel_reverse && !item.heel_reverse_ignore?
    value = value.to_i
    @result.hp_damage -= value
    @result.success = true
    self.hp += value
  end  
  #--------------------------------------------------------------------------
  # ○ 使用効果［TP 増加］
  #--------------------------------------------------------------------------
  def item_effect_gain_tp(user, item, effect)
    value = (self.max_tp * effect.value1.to_f * 0.01).ceil
    @result.tp_damage -= value
    @result.success = true if value != 0
    self.tp += value
  end
  #--------------------------------------------------------------------------
  # ○ 使用効果［ステート付加］
  #--------------------------------------------------------------------------
  def item_effect_add_state(user, item, effect)
    if item.state_penetrate?  
      item_effect_add_state_penetrate(user, item, effect)
    else
      if effect.data_id == 0
        item_effect_add_state_attack(user, item, effect)
      else
        item_effect_add_state_normal(user, item, effect)
      end
    end
  end
  #--------------------------------------------------------------------------
  # ○ 使用効果［ステート付加］：通常攻撃
  #--------------------------------------------------------------------------
  def item_effect_add_state_attack(user, item, effect)
    user.atk_states.each do |state_id|
      chance = effect.value1 * user.atk_states_rate(state_id)    
      chance *= user.booster_state_ratio_type(item)
      chance *= user.booster_state_ratio_skill(item)
      chance += user.booster_state_fix_type(item)
      if (chance < 1.0) && (state_rate(state_id) < 1.0)
        chance *= state_rate(state_id)
      else
        chance += state_rate(state_id) - 1.0
      end
      chance = 0.0 if state_rate(state_id) == 0.0 || state_resist?(state_id)
      
      print "#{$data_states[state_id].name}付与最終成功率#{(chance * 100).to_i}%\n" if $TEST
      if rand < chance
        if state_id == NWConst::State::INSTANT_DEAD && (0 < hp) && instant_dead_reverse?
          @result.hp_damage = -(mhp - hp)
          self.hp = mhp
        else
          add_state(state_id)
        end
        @result.success = true
      end
    end
  end
  #--------------------------------------------------------------------------
  # ○ 使用効果［ステート付加］：通常
  #--------------------------------------------------------------------------
  def item_effect_add_state_normal(user, item, effect)
    chance = effect.value1    
    if opposite?(user)
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
    end
    
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
  #--------------------------------------------------------------------------
  # ● 使用効果［ステート付加］：耐性無視
  #--------------------------------------------------------------------------
  def item_effect_add_state_penetrate(user, item, effect)
    if rand < effect.value1
      add_state(effect.data_id)
      @result.success = true
    end
  end
  #--------------------------------------------------------------------------
  # ○ 使用効果［特殊効果］
  #--------------------------------------------------------------------------
  def item_effect_special(user, item, effect)
    case effect.data_id
    when SPECIAL_EFFECT_ESCAPE
      if actor?
        BattleManager.process_forced_escape
        @result.success = true
      else
        if BattleManager.can_escape?
          escape
          @result.success = true
        else
          @result.success = false
        end
      end
    end
  end
  #--------------------------------------------------------------------------
  # ○ 使用効果［コモンイベント］
  #--------------------------------------------------------------------------
  def item_effect_common_event(user, item, effect)
    @result.success = true
  end
  #--------------------------------------------------------------------------
  # ● 使用効果［アイテムスティール]
  #--------------------------------------------------------------------------
  def item_effect_steal(user, item, effect)
    return unless user.actor? && self.enemy?
    
    list = self.steal_list[effect.data_id]
    @result.stealed_item_empty = list.empty? ? true : false
    list.sort{|a, b| b[:denominator] <=> a[:denominator]}.each{|steal|      
      next unless rand * steal[:denominator] < user.steal_success
      case steal[:kind]
      when 1; item = $data_items[steal[:data_id]]
      when 2; item = $data_weapons[steal[:data_id]]
      when 3; item = $data_armors[steal[:data_id]]
      end
      
      $game_party.gain_item(item, 1)
      $game_library.count_up_actor_steal(user.id)
      $game_library.count_up_steal_item(self.id, effect.data_id, steal)
      list.clear
      @result.stealed_item_kind = steal[:kind]
      @result.stealed_item_id   = steal[:data_id]
      break
    }
    @result.stealed = true
    @result.success = true
  end
  #--------------------------------------------------------------------------
  # ● 使用効果［アイテム獲得]
  #--------------------------------------------------------------------------
  def item_effect_get_item(user, item, effect)
  end
  #--------------------------------------------------------------------------
  # ● 使用効果［防御壁追加]
  #--------------------------------------------------------------------------
  def item_effect_defense_wall(user, item, effect)
    @cnt[:defense_wall] += [true] * effect.data_id
    @result.success = true
  end
  #--------------------------------------------------------------------------
  # ● 使用効果［経験値上昇]
  #--------------------------------------------------------------------------
  def item_effect_gain_exp(user, item, effect)
    case effect.data_id
    when 0
      current_exp = base_exp
      kind = :base
    when 1
      current_exp = class_exp
      kind = :class
    when 2
      current_exp = tribe_exp
      kind = :tribe
    end
    change_exp(current_exp + effect.value1, true, kind)
    @result.success = true
  end
  #--------------------------------------------------------------------------
  # ● 使用効果［属性即死]
  #--------------------------------------------------------------------------
  def item_effect_death_element(user, item, effect)
    if rand < elements_max_rate([effect.value2[:id]])
      chance = effect.value1
      chance *= state_rate(effect.data_id) unless effect.value2[:opt]
      if rand < chance
        add_state(effect.data_id)
        @result.success = true
      end
    end
  end
  #--------------------------------------------------------------------------
  # ● 使用効果［ステート限定付与］
  #--------------------------------------------------------------------------
  def item_effect_death_state(user, item, effect)
    if state?(effect.value2[:id])
      chance = effect.value1
      chance *= state_rate(effect.data_id) unless effect.value2[:opt]
      if rand < chance
        add_state(effect.data_id)
        @result.success = true
      end
    end
  end
  #--------------------------------------------------------------------------
  # ● 使用効果［捕食］
  #--------------------------------------------------------------------------
  def item_effect_predation(user, item, effect)
    return unless effect.value1.any?{|state_id| self.state?(state_id)}
    if effect.value2 & 0x1 == 0x1
      user.hp += self.hp
      self.hp = 0
    end
    if effect.value2 & 0x2 == 0x2
      user.mp += self.mp
      self.mp = 0
    end
    if effect.value2 & 0x4 == 0x4
      user.tp += self.tp
      self.tp = 0
    end
    self.add_state(death_state_id)
    self.hide unless self.luca?
    @result.predation = true
    @result.success = true
    @predationed = true
  end
  #--------------------------------------------------------------------------
  # ● 使用効果［自己ステート付与］
  #--------------------------------------------------------------------------
  def item_effect_self_enchant(user, item, effect)
  end
  #--------------------------------------------------------------------------
  # ● 使用効果［ダメージ還元］
  #--------------------------------------------------------------------------
  def item_effect_restoration(user, item, effect)
    value = 0
    case item.damage.type
    when 1, 5
      value = @result.hp_damage
    when 2, 6
      value = @result.mp_damage
    end    
    value = (value * effect.value1).to_i
    
    return unless 0 < value
    case effect.data_id
    when :HP
      user.hp += value
      @result.hp_restore = value
    when :MP
      user.mp += value
      @result.mp_restore = value
    end
    @result.success = true
  end
  #--------------------------------------------------------------------------
  # ● 使用効果［拘束開始技］
  #--------------------------------------------------------------------------
  def item_effect_binding_start(user, item, effect)
    return unless user.enemy?
    return unless self.luca?
    return unless rand < self.state_rate(effect.value2)
    return unless self.state_addable?(effect.value2)
    
    if BattleManager.bind? && (BattleManager.bind_user_index != user.index)
      @result.binding_start = 3
    else
      unless user.bind_user? 
        @result.binding_start = effect.value1 == NWConst::State::UBIND ? 0 : 1
      else
        @result.binding_start = 2
      end
      BattleManager.bind_set(effect.data_id)
      user.add_state(effect.value1)
      self.add_state(effect.value2)
    end
    clear_actions
    @result.success = true
  end
  #--------------------------------------------------------------------------
  # ● 使用効果［もがく］
  #--------------------------------------------------------------------------
  def item_effect_bind_resist(user, item, effect)
    BattleManager.bind_count_down
    @result.bind_resist = true
    @result.success     = true
  end
  #--------------------------------------------------------------------------
  # ● 最終的に適用される属性を取得
  #--------------------------------------------------------------------------
  def final_elements(item)
    return item.elements.collect{|id| id < 0 ? atk_elements : id}.flatten
  end
  #--------------------------------------------------------------------------
  # ● スキル使用不可能？
  #--------------------------------------------------------------------------
  def skill_unusable?(item)
    return false unless item.is_skill?
    return false if skill_conditions_met?(item)
    @result.clear
    @result.used = true    
    if hp < skill_hp_cost(item)
      @result.unusable = 0
    elsif mp < skill_mp_cost(item)
      @result.unusable = 1
    elsif tp < skill_tp_cost(item)
      @result.unusable = 2
    elsif $game_party.gold < skill_gold_cost(item)
      @result.unusable = 3
    elsif !skill_need_item?(item)  
      @result.unusable = 4
    elsif skill_type_sealed?(item.stype_id) || skill_sealed?(item.id)
      @result.unusable = 5
    elsif temptation? && !$game_actors[NWConst::Actor::LUCA].alive?
      @result.unusable = 6
    end
    return true
  end    
  #--------------------------------------------------------------------------
  # ● 永久拘束中に攻撃をした？
  #--------------------------------------------------------------------------
  def eternal_bind_resist?(item)
    return false unless item.is_skill?
    return false unless state?(NWConst::State::ETBIND)
    return false unless item.id != bind_resist_skill_id
    return true
  end
  #--------------------------------------------------------------------------
  # ○ 運による有効度変化率の取得
  #--------------------------------------------------------------------------
  def luk_effect_rate(user)
    1.0
  end
  #--------------------------------------------------------------------------
  # ○ 被ダメージによる TP チャージ
  #--------------------------------------------------------------------------
  def charge_tp_by_damage(damage_rate)
  end
  #--------------------------------------------------------------------------
  # ○ スキル／アイテムの使用者側への効果
  #--------------------------------------------------------------------------
  def item_user_effect(user, item)
    user.tp += (item.tp_gain * tcr).ceil
  end
  #--------------------------------------------------------------------------
  # ○ 戦闘開始処理
  #--------------------------------------------------------------------------
  def on_battle_start
    init_tp unless preserve_tp?
    set_counter
    set_trigger_state
    auto_state.each{|state_id| add_state(state_id)}
  end
  #--------------------------------------------------------------------------
  # ● 戦闘用カウンターのクリア
  #--------------------------------------------------------------------------  
  def clear_counter
    @cnt = {}
    @cnt[:dead_skill] = []
    @cnt[:defense_wall] = []
  end  
  #--------------------------------------------------------------------------
  # ● 戦闘用カウンターのセット
  #--------------------------------------------------------------------------  
  def set_counter
    @cnt[:dead_skill] = dead_skill ? [dead_skill] : []
    @cnt[:defense_wall] = defense_wall ? [true] * defense_wall : []
  end
  #--------------------------------------------------------------------------
  # ● トリガーステートのセット
  #--------------------------------------------------------------------------
  def set_trigger_state
    trigger_state.each{|obj|
      rate  = {:H => hp_rate, :M => mp_rate, :T => tp_rate}[obj[:point]]
      check = [rate < obj[:per], obj[:per] <= rate]
      exec  = [:add_state, :remove_state]      
      method(exec[obj[:trigger] / 2]).call(obj[:state_id]) if check[obj[:trigger] % 2]
    }
  end
  #--------------------------------------------------------------------------
  # ○ 戦闘不能になる
  #--------------------------------------------------------------------------
  def die
    if $game_party.in_battle && !@cnt[:dead_skill].empty?
      BattleManager.skill_interrupt(self, @cnt[:dead_skill].pop, :dead_skill)
    end
    @hp = 0
    clear_states
    clear_buffs
    BattleManager.bind_refresh if $game_party.in_battle # もしくはclear_statesで
  end
  #--------------------------------------------------------------------------
  # ○ スキル／アイテムの反撃率計算
  #--------------------------------------------------------------------------
  def item_cnt(user, item)
    return 0.0 unless opposite?(user)         # 味方には反撃しない
    return 0.0 unless movable?
    return 0.0 if bind_target?
    return certain_counter if item.certain?
    return cnt             if item.physical?
    return magical_counter #if item.magical?
  end
  #--------------------------------------------------------------------------
  # ● スキル／アイテムの拡張反撃率計算
  #--------------------------------------------------------------------------
  def item_cnt_ex(user, item)
    return 0.0 unless opposite?(user)         # 味方には反撃しない
    return 0.0 unless movable?
    return 0.0 if bind_target?
    return certain_counter_ex  if item.certain?
    return physical_counter_ex if item.physical?
    return magical_counter_ex  #if item.magical?
  end
  #--------------------------------------------------------------------------
  # ○ ダメージ計算
  #--------------------------------------------------------------------------
  def make_damage_value(user, item, is_cnt = false)
    value = item.damage.eval(user, self, $game_variables)
    value *= item_element_rate(user, item)
    value *= pdr if item.physical?
    value *= mdr if item.magical?
    value *= rec if item.damage.recover?
    value *= heel_reverse_rate(item)
    value *= boost_rate(user, item, is_cnt)
    value = apply_critical(value) if @result.critical
    value = apply_variance(value, item.damage.variance)
    value = apply_guard(value)
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
  # ○ スキル／アイテムの属性修正値を取得
  #--------------------------------------------------------------------------
  def item_element_rate(user, item)
    return  1.0 if item.element_penetrate?
    return -1.0 if user.final_elements(item).any?{|id| element_drain?(id)}
    return elements_max_rate(user.final_elements(item))
  end
  #--------------------------------------------------------------------------
  # ○ 属性の最大修正値の取得
  #     elements : 属性 ID の配列
  #    与えられた属性の中で最も有効な修正値を返す
  #--------------------------------------------------------------------------
  def elements_max_rate(elements)
    return 1.0 if elements.empty?
    return elements.inject([0.0]) {|r, i| r.push(element_rate(i)) }.max
  end
  #--------------------------------------------------------------------------
  # ○ スキル／アイテムの命中率計算
  #--------------------------------------------------------------------------
  def item_hit(user, item)
    hit_chance = item.success_rate * 0.01
    eva_chance = 1.0
    if item.physical?
      hit  = (item.is_skill? && item.skill_hit) ? item.skill_hit : user.hit
      hit_factor = item.is_skill? ? item.skill_hit_factor : 0.0
      hit_chance *= hit + hit_factor 
      eva_chance -= self.eva
    elsif item.magical?
      eva_chance -= self.mev
    end
    if (hit_chance < 1.0) && (eva_chance < 1.0)
      chance = hit_chance * eva_chance
    else
      chance = hit_chance - (1.0 - eva_chance)
    end
    
    print "#{item.name}最終命中率:#{(chance * 100.0).to_i}%\n" if $TEST
    return chance
  end
  #--------------------------------------------------------------------------
  # ● 回復反転率の取得
  #--------------------------------------------------------------------------
  def heel_reverse_rate(item)
    return 1.0 unless $game_party.in_battle
    return 1.0 unless item.damage.recover?
    return 1.0 unless 0.0 < heel_reverse
    return 1.0 if item.heel_reverse_ignore?
    return -(heel_reverse)
  end
  #--------------------------------------------------------------------------
  # ○ クリティカルの適用
  #--------------------------------------------------------------------------
  def apply_critical(damage)
    damage * 2
  end
  #--------------------------------------------------------------------------
  # ● 無効化障壁の適用
  #--------------------------------------------------------------------------
  def apply_invalidate_wall(damage, item)
    return damage unless invalidate_wall
    return damage if invalidate_wall < damage
    return damage if item.damage.recover?
    @result.invalidate_wall = true
    return 0
  end  
  #--------------------------------------------------------------------------
  # ● 防御壁展開の適用
  #--------------------------------------------------------------------------
  def apply_defense_wall(damage, item)
    return damage if @cnt[:defense_wall].empty?
    return damage if @result.invalidate_wall
    return damage if item.damage.recover?
    @cnt[:defense_wall].pop
    @result.defense_wall = true
    return 0
  end  
  #--------------------------------------------------------------------------
  # ● メタルボディの適用
  #--------------------------------------------------------------------------
  def apply_metal_body(damage, item)
    return damage unless metal_body
    return damage unless metal_body < damage
    return damage if item.damage.recover?
    return metal_body
  end
  #--------------------------------------------------------------------------
  # ● 踏みとどまりの適用
  #--------------------------------------------------------------------------
  def apply_stand(damage, item)
    return damage unless hp <= damage
    return damage unless mhp * auto_stand < hp
    return damage if item.damage.recover?
    @result.auto_stand = true
    return hp - 1
  end
  #--------------------------------------------------------------------------
  # ● ダメージMP変換の適用
  #--------------------------------------------------------------------------
  def apply_damage_mp_convert(damage, item)
    return damage unless damage_mp_convert
    return damage if item.damage.recover?
    return 0 if damage_mp_convert == 0.0
    mp_damage = damage * damage_mp_convert
    rest      = 0.0 < (mp_damage - mp) ? mp_damage - mp : 0.0
    self.mp  -= mp_damage.ceil
    return (rest / damage_mp_convert).ceil
  end
  #--------------------------------------------------------------------------
  # ● ダメージゴールド変換の適用
  #--------------------------------------------------------------------------
  def apply_damage_gold_convert(damage, item)
    return damage unless damage_gold_convert
    return damage if item.damage.recover?
    return 0 if damage_gold_convert == 0.0
    gold_damage = damage * damage_gold_convert
    rest        = 0.0 < (gold_damage - $game_party.gold) ? gold_damage - $game_party.gold : 0.0
    $game_party.lose_gold(gold_damage.ceil)
    return (rest / damage_gold_convert).ceil
  end  
  #--------------------------------------------------------------------------
  # ● ダメージMP吸収の適用
  #--------------------------------------------------------------------------
  def apply_damage_mp_drain(damage, item)
    return damage unless damage_mp_drain
    return damage if item.damage.recover?
    self.mp += (damage * damage_mp_drain).ceil
    return damage
  end
  #--------------------------------------------------------------------------
  # ● ダメージゴールド回収の適用
  #--------------------------------------------------------------------------
  def apply_damage_gold_drain(damage, item)
    return damage unless damage_gold_drain
    return damage if item.damage.recover?
    $game_party.gain_gold((damage * damage_gold_drain).ceil)
    return damage
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
    
    user.wtypes.each{|wtype_id|
      case item.hit_type
      when 0; value *= user.booster_weapon_certain(wtype_id)
      when 1; value *= user.booster_weapon_physical(wtype_id)
      when 2; value *= user.booster_weapon_magical(wtype_id)
      end
      value *= user.booster_wtype_skill([wtype_id, item.id]) if item.is_skill?
      value *= user.booster_normal_attack(wtype_id) if item == $data_skills[user.attack_skill_id]
    }
    if user.wtypes.empty?
      value *= user.booster_wtype_skill([0, item.id]) if item.is_skill?
      value *= user.booster_normal_attack(0) if item == $data_skills[user.attack_skill_id]
    end
    if item.is_skill?
      value *= user.booster_skill_type(item)
      value *= user.booster_skill(item)
    end
    return value
  end
  #--------------------------------------------------------------------------
  # ○ TP の再生
  #--------------------------------------------------------------------------
  def regenerate_tp
    @result.tp_damage = -(max_tp * trg).ceil
    self.tp -= @result.tp_damage
  end
  #--------------------------------------------------------------------------
  # ○ 全ての再生
  #--------------------------------------------------------------------------
  def regenerate_all
    if $game_party.in_battle && alive?
      regenerate_hp
      regenerate_mp
      regenerate_tp
    end
  end
  #--------------------------------------------------------------------------
  # ○ 戦闘行動終了時の処理
  #--------------------------------------------------------------------------
  def on_action_end
    @result.clear
    regenerate_all
    remove_states_auto(1)
    remove_buffs_auto
  end
  #--------------------------------------------------------------------------
  # ○ ターン終了処理
  #--------------------------------------------------------------------------
  def on_turn_end
    @result.clear
    update_state_turns
    update_buff_turns
    remove_states_auto(2)
    set_trigger_state if $game_party.in_battle
  end  
  #--------------------------------------------------------------------------
  # ○ 戦闘終了処理
  #--------------------------------------------------------------------------
  def on_battle_end
    @result.clear
    remove_battle_states
    remove_all_buffs
    clear_actions
    init_tp unless preserve_tp?
    appear
    self.hp += Integer(mhp * battle_end_heel_hp)
    self.mp += Integer(mmp * battle_end_heel_mp)
    @predationed = false
  end
  #--------------------------------------------------------------------------
  # ● 武器種別攻撃力算出
  #--------------------------------------------------------------------------
  def wp_atk
    # 計算値が高い方を優先する
    a = self
    warray = wtypes.empty? ? [0] : wtypes
    warray.collect{|w| eval(NWConst::Parameter::WEAPON_TYPE_DAMAGE[w])}.max
  end
  #--------------------------------------------------------------------------
  # ● 拘束技使用者？
  #--------------------------------------------------------------------------
  def bind_user?
    self.state?(NWConst::State::UBIND) || self.state?(NWConst::State::EUBIND)
  end
  #--------------------------------------------------------------------------
  # ● 拘束技対象者？
  #--------------------------------------------------------------------------
  def bind_target?
    self.state?(NWConst::State::TBIND) || self.state?(NWConst::State::ETBIND)
  end
end

#==============================================================================
# ■ Game_Actor
#==============================================================================
class Game_Actor < Game_Battler  
  #--------------------------------------------------------------------------
  # ● 性別
  #--------------------------------------------------------------------------
  def sex
    return actor.sex
  end  
  #--------------------------------------------------------------------------
  # ○ 通常能力値の加算値取得
  #--------------------------------------------------------------------------
  def param_plus(param_id)
    return super(param_id)    
  end  
  #--------------------------------------------------------------------------
  # ● 通常能力値の取得
  #--------------------------------------------------------------------------
  def param(param_id)
    value = super(param_id)
    value += equips.compact.inject(0) {|r, item| r + item.params[param_id]}
    Integer([[value, param_max(param_id)].min, param_min(param_id)].max)
  end
  #--------------------------------------------------------------------------
  # ● 攻撃力
  #--------------------------------------------------------------------------
  def atk
    (BattleManager.giveup? && luca?) || bind_target? ? super * 0.5 : super
  end
  #--------------------------------------------------------------------------
  # ● 防御力
  #--------------------------------------------------------------------------
  def def
    (BattleManager.giveup? && luca?) ? 0.0 : super
  end
  #--------------------------------------------------------------------------
  # ● 精神力
  #--------------------------------------------------------------------------
  def mdf
    (BattleManager.giveup? && luca?) ? 0.0 : super
  end
  #--------------------------------------------------------------------------
  # ● 素早さ
  #--------------------------------------------------------------------------
  def agi
    (BattleManager.giveup? && luca?) || bind_target? ? super * 0.5 : super
  end
  #--------------------------------------------------------------------------
  # ● 器用さ
  #--------------------------------------------------------------------------
  def luk
    (BattleManager.giveup? && luca?) || bind_target? ? super * 0.5 : super
  end
  #--------------------------------------------------------------------------
  # ○ 武器オブジェクトの配列取得
  #--------------------------------------------------------------------------
  def weapons
    w = @equips.select {|item| item.is_weapon? }.collect {|item| item.object}
    states.select{|state| state.tmp_equip > 0}.each{|state|
      w[0] = $data_weapons[state.tmp_equip]
    }
    return w
  end
  #--------------------------------------------------------------------------
  # ○ 装備品オブジェクトの配列取得
  #--------------------------------------------------------------------------
  def equips
    e = @equips.collect {|item| item.object}
    states.select{|state| state.tmp_equip > 0}.each{|state|
      e[0] = $data_weapons[state.tmp_equip]
    }
    return e
  end  
  #--------------------------------------------------------------------------
  # ● 武器タイプ配列の取得
  #--------------------------------------------------------------------------
  def wtypes
    weapons.collect{|w| w.wtype_id}
  end
  #--------------------------------------------------------------------------
  # ○ 最強装備
  #--------------------------------------------------------------------------
  def optimize_equipments
    accessory = equips[4]
    clear_equipments
    4.times do |i|
      next if !equip_change_ok?(i)
      items = $game_party.equip_items.select do |item|
        item.etype_id == equip_slots[i] &&
        equippable?(item) && item.performance >= 0
      end
      change_equip(i, items.max_by {|item| item.performance })
    end
    change_equip(4, accessory)
  end  
  #--------------------------------------------------------------------------
  # ● 誘惑時行動スキルIDの取得
  #--------------------------------------------------------------------------
  def temptation_skill_id
    actor.temptation_skill ? actor.temptation_skill : NWConst::Skill::DEFAULT_TEMPTATION
  end
  #--------------------------------------------------------------------------
  # ○ 通常能力値の最大値取得
  #--------------------------------------------------------------------------
  def param_max(param_id)
    return 99999 if param_id == 0  # MHP
    return super
  end  
  #--------------------------------------------------------------------------
  # ○ スキルオブジェクトの配列取得
  #--------------------------------------------------------------------------
  def skills
    (@skills | added_skills).sort.collect {|id| $data_skills[id] }
  end  
  #--------------------------------------------------------------------------
  # ○ 床ダメージの基本値を取得
  #--------------------------------------------------------------------------
  def basic_floor_damage
    return NWConst::Map::DAMAGE_FLOOR[$game_player.terrain_tag]
  end
  #--------------------------------------------------------------------------
  # ● 全回復【オーバーライド】
  #--------------------------------------------------------------------------
  def recover_all
    super
    init_tp
  end
  #--------------------------------------------------------------------------
  # ● TP の最大値を取得【オーバーライド】
  #--------------------------------------------------------------------------
  def max_tp
    [((actor.base_tp + (actor.tp_level_revise * (base_level - 1)) + increase_tp_fix) * increase_tp_per).ceil, 1].max
  end
  #--------------------------------------------------------------------------
  # ● TP の初期化【オーバーライド】
  #--------------------------------------------------------------------------
  def init_tp
    self.tp = (max_tp * start_tp_rate).ceil
  end
  #--------------------------------------------------------------------------
  # ○ 最終的な経験獲得率の計算
  #--------------------------------------------------------------------------
  def final_exp_rate
    exr * (battle_member? ? 1 : reserve_members_exp_rate) * (death_state? ? 0 : 1)
  end
  #--------------------------------------------------------------------------
  # ● 最終的な職業経験獲得率の計算
  #--------------------------------------------------------------------------
  def final_cexp_rate
    cexr * (battle_member? ? 1 : reserve_members_exp_rate) * (death_state? ? 0 : 1)
  end  
  #--------------------------------------------------------------------------
  # ● スキルタイプ非表示の判定
  #--------------------------------------------------------------------------
  def skill_type_disabled?(stype_id)
    return @skill_types_disabled[stype_id]
  end
  #--------------------------------------------------------------------------
  # ● スキルタイプ非表示フラグの反転
  #--------------------------------------------------------------------------
  def flip_skill_type_disabled(stype_id)
    @skill_types_disabled[stype_id] = !@skill_types_disabled[stype_id]
  end
end

#==============================================================================
# ■ Game_Enemy
#==============================================================================
class Game_Enemy < Game_Battler
  #--------------------------------------------------------------------------
  # ● 公開インスタンス変数
  #--------------------------------------------------------------------------
  attr_reader     :steal_list
  #--------------------------------------------------------------------------
  # ○ オブジェクト初期化
  #--------------------------------------------------------------------------
  def initialize(index, enemy_id)
    super()
    @index = index
    @enemy_id = enemy_id
    enemy = $data_enemies[@enemy_id]
    @original_name = enemy.name
    @letter = ""
    @plural = false
    @screen_x = 0
    @screen_y = 0
    @battler_name = enemy.battler_name
    @battler_hue = enemy.battler_hue
    @hp = mhp
    @mp = mmp
    @steal_list = Marshal.load(Marshal.dump(enemy.steal_list))
    @recharge_skills = {}
  end
  #--------------------------------------------------------------------------
  # ● エネミーIDの取得
  #--------------------------------------------------------------------------
  def id
    @enemy_id
  end
  #--------------------------------------------------------------------------
  # ● 最大HP ベース/GameObject 2166 以下メソッドでは省略
  #--------------------------------------------------------------------------
  def mhp
    return super unless 0 < $game_variables[NWConst::Var::PARAM1]
    return (super * $game_variables[NWConst::Var::PARAM1] * 0.01).to_i
  end
  #--------------------------------------------------------------------------
  # ● 攻撃力
  #--------------------------------------------------------------------------
  def atk
    return super unless 0 < $game_variables[NWConst::Var::PARAM2]
    return (super * $game_variables[NWConst::Var::PARAM2] * 0.01).to_i
  end
  #--------------------------------------------------------------------------
  # ● 防御力
  #--------------------------------------------------------------------------
  def def
    return super unless 0 < $game_variables[NWConst::Var::PARAM3]
    return (super * $game_variables[NWConst::Var::PARAM3] * 0.01).to_i
  end
  #--------------------------------------------------------------------------
  # ● 魔力
  #--------------------------------------------------------------------------
  def mat
    return super unless 0 < $game_variables[NWConst::Var::PARAM2]
    return (super * $game_variables[NWConst::Var::PARAM2] * 0.01).to_i
  end
  #--------------------------------------------------------------------------
  # ● 精神
  #--------------------------------------------------------------------------
  def mdf
    return super unless 0 < $game_variables[NWConst::Var::PARAM3]
    return (super * $game_variables[NWConst::Var::PARAM3] * 0.01).to_i
  end
  #--------------------------------------------------------------------------
  # ● 素早
  #--------------------------------------------------------------------------
  def agi
    return super unless 0 < $game_variables[NWConst::Var::PARAM4]
    return (super * $game_variables[NWConst::Var::PARAM4] * 0.01).to_i
  end
  #--------------------------------------------------------------------------
  # ● 器用
  #--------------------------------------------------------------------------
  def luk
    return super unless 0 < $game_variables[NWConst::Var::PARAM2]
    return (super * $game_variables[NWConst::Var::PARAM2] * 0.01).to_i
  end
  #--------------------------------------------------------------------------
  # ● TP の最大値を取得【オーバーライド】
  #--------------------------------------------------------------------------
  def max_tp
    # 基本値999
    [((999 + increase_tp_fix) * increase_tp_per).ceil, 1].max
  end
  #--------------------------------------------------------------------------
  # ● TP の初期化【オーバーライド】
  #--------------------------------------------------------------------------
  def init_tp
    self.tp = max_tp
  end  
  #--------------------------------------------------------------------------
  # ○ TP の再生
  #--------------------------------------------------------------------------
  def regenerate_tp
    init_tp
  end
  #--------------------------------------------------------------------------
  # ○ ドロップアイテム取得率の倍率を取得
  #--------------------------------------------------------------------------
  def drop_item_rate
    [$game_party.get_item_rate, ($game_party.drop_item_double? ? 2.0 : 1.0)].max
  end
  #--------------------------------------------------------------------------
  # ● 逃走レベルの取得
  #--------------------------------------------------------------------------
  def escape_level
    enemy.escape_level
  end
  #--------------------------------------------------------------------------
  # ● 職業経験値の取得
  #--------------------------------------------------------------------------
  def class_exp
    enemy.class_exp
  end
  #--------------------------------------------------------------------------
  # ● 武器タイプ配列の取得
  #--------------------------------------------------------------------------
  def wtypes
    [enemy.wtype_id]
  end
  #--------------------------------------------------------------------------
  # ● 誘惑時行動スキルIDの取得
  #--------------------------------------------------------------------------
  def temptation_skill_id
    enemy.temptation_skill ? enemy.temptation_skill : NWConst::Skill::DEFAULT_TEMPTATION
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
    
    return if action_list.empty?
    rating_sum  = action_list.inject(0){|sum, a| sum += a.rating}
    @actions.each{ |action|
      action.set_enemy_action(select_enemy_action(action_list, rating_sum))
    }
  end
  #--------------------------------------------------------------------------
  # ○ 戦闘行動をランダムに選択
  #--------------------------------------------------------------------------
  def select_enemy_action(action_list, rating_sum)
    value = rand(rating_sum)
    action_list.each{|action| 
      value -= action.rating
      return action if value < 0
    }
  end
  #--------------------------------------------------------------------------
  # ● 拘束中行動の作成
  #--------------------------------------------------------------------------
  def make_bind_actions
    enemy.actions.select{|action|
      skill = $data_skills[action.skill_id]
      result = skill.bind?
      result &&= !(skill.binding_start? && BattleManager.bind? && (BattleManager.bind_user_index != self.index))
      result
    }
  end
  #--------------------------------------------------------------------------
  # ● 永久拘束中行動の作成
  #--------------------------------------------------------------------------
  def make_eternal_bind_actions
    enemy.actions.select{|action|
      $data_skills[action.skill_id].eternal_bind?
    }
  end
  #--------------------------------------------------------------------------
  # ● 通常行動の作成
  #--------------------------------------------------------------------------
  def make_normal_actions
    enemy.actions.select{|action|
      skill    = $data_skills[action.skill_id]
      result   = !skill.bind?
      result &&= !skill.eternal_bind?
      result &&= !(skill.binding_start? && BattleManager.bind? && (BattleManager.bind_user_index != self.index))
      result &&= usable_item_sex_ok?(skill)
      result
    }
  end  
  #--------------------------------------------------------------------------
  # ● スキル使用コストの支払い
  #--------------------------------------------------------------------------
  def pay_skill_cost(skill)
    super
    @recharge_skills[skill.id] = skill.recharge
  end
  #--------------------------------------------------------------------------
  # ● ターン終了処理
  #--------------------------------------------------------------------------
  def on_turn_end
    super
    count_recharge_skills
  end
  #--------------------------------------------------------------------------
  # ● スキルのリチャージカウントを進める
  #--------------------------------------------------------------------------
  def count_recharge_skills
    @recharge_skills.each{|key, value|
      @recharge_skills[key] = value - 1
    }
    @recharge_skills.delete_if {|key, value| value <= 0}
  end
end

#==============================================================================
# ■ Game_Actors
#==============================================================================
class Game_Actors
  #--------------------------------------------------------------------------
  # ● アクターの解放
  #--------------------------------------------------------------------------
  def release(actor_id)
    @data[actor_id] = nil
  end
end

#==============================================================================
# ■ Game_Unit
#==============================================================================
class Game_Unit
  #--------------------------------------------------------------------------
  # ● 公開インスタンス変数
  #--------------------------------------------------------------------------
  attr_accessor     :display_skill_name
  #--------------------------------------------------------------------------
  # ● 生存しているメンバーの配列取得
  #--------------------------------------------------------------------------
  def alive_members_ex(scope = NWSex::ALL)
    return alive_members if scope == NWSex::ALL
    return alive_members.select{|member| (member.sex & scope) != 0}
  end
  #--------------------------------------------------------------------------
  # ● 戦闘不能のメンバーの配列取得
  #--------------------------------------------------------------------------
  def dead_members_ex(scope = NWSex::ALL)
    return dead_members if scope == NWSex::ALL
    return dead_members.select{|member| (member.sex & scope) != 0}
  end
  #--------------------------------------------------------------------------
  # ● 戦闘不能か捕食メンバーの配列取得
  #--------------------------------------------------------------------------
  def defeated_members
    members.select {|member| member.dead? || member.predationed? }
  end
  #--------------------------------------------------------------------------
  # ● ターゲットのランダムな決定
  #--------------------------------------------------------------------------
  def random_target_ex(scope = NWSex::ALL)
    return random_target if scope == NWSex::ALL
    tgr_rand = rand * alive_members_ex(scope).inject(0){|r, member| r + member.tgr}
    alive_members_ex(scope).each {|member|
      tgr_rand -= member.tgr
      return member if tgr_rand < 0
    }
    return alive_members_ex(scope).first
  end
  #--------------------------------------------------------------------------
  # ● ターゲットのランダムな決定（戦闘不能）
  #--------------------------------------------------------------------------
  def random_dead_target_ex(scope = NWSex::ALL)
    return random_dead_target if scope == NWSex::ALL
    return nil if dead_members_ex(scope).empty?
    return dead_members_ex(scope).sample
  end
end

#==============================================================================
# ■ Game_Actors
#==============================================================================
class Game_Actors
  #--------------------------------------------------------------------------
  # ● 存在する？
  #--------------------------------------------------------------------------
  def exist?(actor_id)
    return @data[actor_id] != nil
  end
end

#==============================================================================
# ■ Game_Party
#==============================================================================
class Game_Party < Game_Unit
  #--------------------------------------------------------------------------
  # ● オブジェクト初期化
  #--------------------------------------------------------------------------
  def initialize
    super
    @gold = 0
    @steps = 0
    @last_item = Game_BaseItem.new
    @menu_actor_id = 0
    @target_actor_id = 0
    @actors = []
    @temp_actors = []
    init_all_items
  end
  #--------------------------------------------------------------------------
  # ○ 全メンバーの取得
  #--------------------------------------------------------------------------
  def all_members
    (@temp_actors.empty? ? @actors : @temp_actors).collect{|id| $game_actors[id]}
  end
  #--------------------------------------------------------------------------
  # ● 一時メンバーの解放
  #--------------------------------------------------------------------------
  def release_temp_actors
    @temp_actors.each{|actor_id| $game_actors.release(actor_id)}
    @temp_actors.clear
  end
  #--------------------------------------------------------------------------
  # ● 一時メンバーのセット
  #--------------------------------------------------------------------------
  def set_temp_actors(ary)
    @temp_actors = ary[0, max_battle_members]
  end
  #--------------------------------------------------------------------------
  # ● 一人しかいない？
  #--------------------------------------------------------------------------  
  def lonely?
    return battle_members.size == 1
  end
  #--------------------------------------------------------------------------
  # ○ バトルメンバーの取得
  #--------------------------------------------------------------------------
  def battle_members
    all_members.select{|actor| actor.exist?}[0, max_battle_members]
  end
  #--------------------------------------------------------------------------
  # ● ベンチメンバーの取得
  #--------------------------------------------------------------------------
  def bench_members
    id = battle_members.collect{|actor| actor.id}
    return all_members.reject{|actor| actor.hidden? || id.include?(actor.id)}
  end
  #--------------------------------------------------------------------------
  # ○ 戦闘テスト用パーティのセットアップ
  #--------------------------------------------------------------------------
  def setup_battle_test_members
    $data_system.test_battlers.each do |battler|
      actor = $game_actors[battler.actor_id]
      actor.change_level(battler.level, false, :base)
      actor.init_equips(battler.equips)
      actor.recover_all
      add_actor(actor.id)
    end
  end  
  #--------------------------------------------------------------------------
  # ● 行動変化判定
  #--------------------------------------------------------------------------
  def check_change_action
    members.each{|actor|
      actor.change_action.each{|action|
        if rand < action[:per]
          actor.clear_actions
          actor.skill_interrupt(action[:id])
          break
        end
      }
    }
    members.each{|actor|
      actor.actions.each{|action|
        next unless action.item
        next unless action.item.is_skill?
        next unless actor.change_skill(action.item.id)
        action.set_skill(actor.change_skill(action.item.id))
      }
    }
  end
  #--------------------------------------------------------------------------
  # ○ 全滅判定
  #--------------------------------------------------------------------------
  def all_dead?
    return super && !$game_switches[NWConst::Sw::ALL_DEAD_DISABLE]
  end
  #--------------------------------------------------------------------------
  # ● 獲得金額倍率
  #--------------------------------------------------------------------------
  def get_gold_rate
    members.inject([1.0]){|r, actor| r.push(actor.get_gold_rate)}.max
  end
  #--------------------------------------------------------------------------
  # ● 獲得アイテム倍率
  #--------------------------------------------------------------------------
  def get_item_rate
    members.inject([1.0]){|r, actor| r.push(actor.get_item_rate)}.max
  end
  #--------------------------------------------------------------------------
  # ● エンカウント倍率
  #--------------------------------------------------------------------------
  def encounter_rate
    array = members.inject([]){|ary, actor| ary + actor.encounter_rate}
    unless array.empty?
      rate = array.inject(1.0){|result, r| result * r}
      return rate
    else
      return 1.0
    end
  end
  #--------------------------------------------------------------------------
  # ● 仲間加入倍率
  #--------------------------------------------------------------------------
  def collect_rate
    members.inject([1.0]){|r, actor| r.push(actor.collect_rate)}.max
  end
  #--------------------------------------------------------------------------
  # ● スロットチャンス
  #--------------------------------------------------------------------------
  def slot_chance
    members.inject(0){|r, actor| r < actor.slot_chance ? actor.slot_chance : r}
  end
  #--------------------------------------------------------------------------
  # ● 解錠レベル
  #--------------------------------------------------------------------------
  def unlock_level
    members.inject(0){|r, actor| r < actor.unlock_level ? actor.unlock_level : r}
  end
  #--------------------------------------------------------------------------
  # ○ 先制攻撃の確率計算
  #--------------------------------------------------------------------------
  def rate_preemptive(troop_agi)
    raise_preemptive? ? 0.15 : 0.03
  end
  #--------------------------------------------------------------------------
  # ○ 不意打ちの確率計算
  #--------------------------------------------------------------------------
  def rate_surprise(troop_agi)
    cancel_surprise? ? 0.0 : 0.03
  end
  #--------------------------------------------------------------------------
  # ○ 捕食されているメンバーを最後尾に
  #--------------------------------------------------------------------------
  def sort_hidden_last
    @actors.sort_by! {|id|
      ($game_actors[id].hidden? ? 100 : 0) + @actors.index(id)
    }
  end
  #--------------------------------------------------------------------------
  # ○ メンバー入れ替えでの全滅防止
  #--------------------------------------------------------------------------
  def no_swap_all_dead?(index1, index2)
    temp = Marshal.load(Marshal.dump(@actors))
    temp[index1], temp[index2] = temp[index2], temp[index1]
    return true if actors_all_dead?(temp[0, max_battle_members])
    return false
  end
  #--------------------------------------------------------------------------
  # ○ 指定したアクターIDが全て戦闘不能か
  #--------------------------------------------------------------------------
  def actors_all_dead?(actors)
    actors.compact.each {|actor_id|
      return false if $game_actors[actor_id].alive?
    }
    return true
  end
  #--------------------------------------------------------------------------
  # ○ 戦闘終了処理
  #--------------------------------------------------------------------------
  alias :nw_predation_on_battle_end :on_battle_end
  def on_battle_end
    # アクターの on_battle_end で predationed をオフにするので必ず事前に入れ替え
    sort_hidden_last if actors_all_dead?(@actors[0, max_battle_members])
    nw_predation_on_battle_end
  end
end

#==============================================================================
# ■ Game_Troop
#==============================================================================
class Game_Troop < Game_Unit
  #--------------------------------------------------------------------------
  # ○ 画面の色調を初期化
  #--------------------------------------------------------------------------
  def init_screen_tone
#    @screen.start_tone_change($game_map.screen.tone, 0) if $game_map
  end  
  #--------------------------------------------------------------------------
  # ● 逃走レベルの最大計算
  #--------------------------------------------------------------------------
  def escape_level_max
    members.inject(1) {|r, enemy| r = r > enemy.escape_level ? r : enemy.escape_level}
  end
  #--------------------------------------------------------------------------
  # ● 経験値の合計計算
  #--------------------------------------------------------------------------
  def exp_total
    defeated_members.inject(0) {|r, enemy| r += enemy.exp }
  end
  #--------------------------------------------------------------------------
  # ● ドロップアイテムの配列作成
  #--------------------------------------------------------------------------
  def make_drop_items
    defeated_members.inject([]) {|r, enemy| r += enemy.make_drop_items }
  end
  #--------------------------------------------------------------------------
  # ● 職業経験値の合計計算
  #--------------------------------------------------------------------------
  def class_exp_total
    Integer(defeated_members.inject(0) {|r, enemy| r += enemy.class_exp})
  end
  #--------------------------------------------------------------------------
  # ○ お金の合計計算
  #--------------------------------------------------------------------------
  def gold_total
    (defeated_members.inject(0){|r, enemy| r += enemy.gold } * gold_rate).to_i
  end
  #--------------------------------------------------------------------------
  # ○ お金の倍率を取得
  #--------------------------------------------------------------------------
  def gold_rate
    [$game_party.get_gold_rate, ($game_party.gold_double? ? 2.0 : 1.0)].max
  end  
  #--------------------------------------------------------------------------
  # ● 戦闘 BGM の取得
  #--------------------------------------------------------------------------
  def battle_bgm
    if troop.name =~ /<BGM(?:\:|：)(\S+)>/i
      return RPG::BGM.new($1.to_s)
    else
      return $game_system.battle_bgm
    end
  end  
  #--------------------------------------------------------------------------
  # ○ バトルイベント（ページ）の条件合致判定
  #--------------------------------------------------------------------------
  def conditions_met?(page)
    c = page.condition
    if !c.turn_ending && !c.turn_valid && !c.enemy_valid &&
       !c.actor_valid && !c.switch_valid
      return false      # 条件未設定…実行しない
    end
    if @event_flags[page]
      return false      # 実行済み
    end
    if c.turn_ending    # ターン終了時
      return false unless BattleManager.turn_end?
    end
    if c.turn_valid     # ターン数
      n = @turn_count
      a = c.turn_a
      b = c.turn_b
      return false if (b == 0 && n != a)
      return false if (b > 0 && (n < 1 || n < a || n % b != a % b))
    end
    if c.enemy_valid    # 敵キャラ
      enemy = $game_troop.members[c.enemy_index]
      return false if enemy == nil
      return false if enemy.hp_rate * 100 > c.enemy_hp
    end
    if c.actor_valid    # アクター
      return false unless $game_party.members.any?{|member| member.id == c.actor_id}
      return false if $game_actors[c.actor_id].hp_rate * 100 > c.actor_hp
    end
    if c.switch_valid   # スイッチ
      return false if !$game_switches[c.switch_id]
    end
    return true         # 条件合致
  end
end

#==============================================================================
# ■ Game_Map
#==============================================================================
class Game_Map
  #--------------------------------------------------------------------------
  # ○ セットアップ
  #--------------------------------------------------------------------------
  def setup(map_id)
    @map_id = map_id
    @map = load_data(sprintf("Data/Map%03d.rvdata2", @map_id))
    @tileset_id = @map.tileset_id
    @display_x = 0
    @display_y = 0
    referesh_vehicles
    setup_map_level
    setup_events
    setup_scroll
    setup_parallax
    setup_battleback
    @need_refresh = false
  end
  #--------------------------------------------------------------------------
  # ● マップレベルのセットアップ
  #--------------------------------------------------------------------------
  def setup_map_level
    if field? || encounter_list.empty?
      @map_level = 1
    else
      @map_level = encounter_list.inject(1){|troop_max, troop|
        max = $data_troops[troop.troop_id].members.inject(1){|enemy_max, enemy|
          max = $data_enemies[enemy.enemy_id].escape_level
          enemy_max < max ? max : enemy_max
        }
        troop_max < max ? max : troop_max
      }
    end
  end
  #--------------------------------------------------------------------------
  # ● マップレベルの取得
  #--------------------------------------------------------------------------
  def map_level
    return @map_level
  end  
  #--------------------------------------------------------------------------
  # ○ 通行チェック
  #     bit : 調べる通行禁止ビット
  #--------------------------------------------------------------------------
  def check_passage(x, y, bit)
    all_tiles(x, y).each_with_index do |tile_id, i|
      flag = tileset.flags[tile_id]
      next if flag & 0x10 != 0              # [☆] : 通行に影響しない
      next if (i == 1) && (flag & bit == 0) # ２層目であり通行可なら判定を無視する
      return true  if flag & bit == 0       # [○] : 通行可
      return false if flag & bit == bit     # [×] : 通行不可
    end
    return false                            # 通行不可
  end
  #--------------------------------------------------------------------------
  # ○ ダメージ床判定
  #--------------------------------------------------------------------------
  def damage_floor?(x, y)
    return false unless valid?(x, y)
    layered_tiles(x, y).each{|tile_id|
      next if tile_id == 0
      return false unless tileset.flags[tile_id] & 0x100 != 0
    }
    return true
  end
end

#==============================================================================
# ■ Game_Player
#==============================================================================
class Game_Player < Game_Character  
  #--------------------------------------------------------------------------
  # ○ エンカウント カウント作成
  #--------------------------------------------------------------------------
  def make_encounter_count
    n = $game_map.encounter_step
    m = rand(n) + rand(n) + 1
    @encounter_count = n + ((m - n) * 0.5)
      
    if $TEST
      step = 0.0 < $game_party.encounter_rate ? "#{(@encounter_count / $game_party.encounter_rate).ceil}歩" : "エンカウントなし"
      print "maplv:#{$game_map.map_level} encounter:#{$game_party.encounter_rate}/#{@encounter_count}(#{step})\n"
    end
#~     @encounter_rate  = $game_party.encounter_rate
#~     if $TEST
#~       step = 0.0 < @encounter_rate ? "#{(@encounter_count / @encounter_rate).ceil}歩" : "エンカウントなし"
#~       print "maplv:#{$game_map.map_level} encounter:#{@encounter_rate}/#{@encounter_count}(#{step})\n"
#~     end
  end
  #--------------------------------------------------------------------------
  # ○ エンカウントの更新
  #--------------------------------------------------------------------------
  def update_encounter
    return if $TEST && Input.press?(:CTRL)
    return if $game_map.encounter_list.empty?
    return if in_airship?
    return if @move_route_forcing
    @encounter_count -= encounter_progress_value
  end  
  #--------------------------------------------------------------------------
  # ○ エンカウント進行値の取得
  #--------------------------------------------------------------------------
  def encounter_progress_value
    value = $game_map.bush?(@x, @y) ? 2.0 : 1.0
    value *= in_ship? ? 0.5 : 1.0
    value *= $game_party.encounter_rate
#~     value *= @encounter_rate
    value
  end
  #--------------------------------------------------------------------------
  # ● 強制的に乗り物に乗る
  #--------------------------------------------------------------------------
  def forced_get_on_vehicle(type)
    return if vehicle
    $game_map.vehicle(type).set_location($game_map.map_id, self.x, self.y)
    @vehicle_type = type
    @followers.gather
    @direction = vehicle.direction
    @move_speed = vehicle.speed
    @transparent = true
    @through     = true if in_airship?
    vehicle.get_on
  end
  #--------------------------------------------------------------------------
  # ● 強制的に乗り物から降りる
  #--------------------------------------------------------------------------
  def forced_get_off_vehicle
    return unless vehicle
    @direction = vehicle.direction
    @followers.synchronize(@x, @y, @direction)
    vehicle.get_off
    @followers.gather
    @move_speed  = 4
    @through     = false
    make_encounter_count
    @vehicle_type = :walk
    @transparent = false
  end  
end

#==============================================================================
# ■ Game_Vehicle
#==============================================================================
class Game_Vehicle < Game_Character
  #--------------------------------------------------------------------------
  # ● 存在している？
  #--------------------------------------------------------------------------
  def exist?
    0 < @map_id
  end
end

#==============================================================================
# ■ Game_Event
#==============================================================================
class Game_Event < Game_Character
  #--------------------------------------------------------------------------
  # ○ 通行可能判定
  #     d : 方向（2,4,6,8）
  #--------------------------------------------------------------------------
  def passable?(x, y, d)
    x2 = $game_map.round_x_with_direction(x, d)
    y2 = $game_map.round_y_with_direction(y, d)
    return false unless $game_map.valid?(x2, y2)
    return true if @through || debug_through?
    return false unless map_passable?(x, y, d)
    return false unless map_passable?(x2, y2, reverse_dir(d))
    return false unless region_passable?(x, y, d)
    return false if collide_with_characters?(x2, y2)
    return true
  end
  #--------------------------------------------------------------------------
  # ● リージョン通行可能判定
  #     d : 方向（2,4,6,8）
  #--------------------------------------------------------------------------
  def region_passable?(x, y, d)
    x2 = $game_map.round_x_with_direction(x, d)
    y2 = $game_map.round_y_with_direction(y, d)
    return region_id == $game_map.region_id(x2, y2)
  end
  #--------------------------------------------------------------------------
  # ○ イベントページの条件合致判定
  #--------------------------------------------------------------------------
  def conditions_met?(page)
    c = page.condition
    if c.switch1_valid
      return false unless $game_switches[c.switch1_id]
    end
    if c.switch2_valid
      return false unless $game_switches[c.switch2_id]
    end
    if c.variable_valid
      return false if $game_variables[c.variable_id] < c.variable_value
    end
    if c.self_switch_valid
      key = [@map_id, @event.id, c.self_switch_ch]
      return false if $game_self_switches[key] != true
    end
    if c.item_valid
      item = $data_items[c.item_id]
      return false unless $game_party.has_item?(item)
    end
    if c.actor_valid
      return false unless $game_party.members.any?{|member| member.id == c.actor_id}
    end
    return true
  end
end

#==============================================================================
# ■ Game_Interpreter
#==============================================================================
class Game_Interpreter
  #--------------------------------------------------------------------------
  # ○ 呼び出し予約されたコモンイベントを検出／セットアップ
  #--------------------------------------------------------------------------
  def setup_reserved_common_event
    if $game_temp.common_event_reserved?
      setup($game_temp.reserved_common_event.list)
      $game_temp.shift_common_event
      true
    else
      false
    end
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
      actor_id = @params[1]
      party_exist = $game_party.members.any?{|member| member.id == actor_id}      
      if party_exist
        actor = $game_actors[actor_id]
        case @params[2]
        when 0  # パーティにいる
          result = party_exist
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
      else
        result = false
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
  #--------------------------------------------------------------------------
  # ○ メンバーの入れ替え
  #--------------------------------------------------------------------------
  def command_129
    actor = $game_actors[@params[0]]
    if actor
      if @params[1] == 0    # 加える
        if @params[2] == 1  # 初期化
          $game_actors[@params[0]].setup(@params[0])
        end
        add_actor_ex(@params[0])
      else                  # 外す
        $game_party.remove_actor(@params[0])
      end
    end
  end
  #--------------------------------------------------------------------------
  # ○ 隊列歩行の変更
  #--------------------------------------------------------------------------
  def command_216
    unless @params[0] == 0
      luca_index = 0
      $game_party.all_members.each_with_index{|actor, i|
        luca_index = (actor.luca? ? i : luca_index)
      }
      $game_party.swap_order(0, luca_index)
    end
    $game_player.followers.visible = (@params[0] == 0)
    $game_player.refresh
  end
  #--------------------------------------------------------------------------
  # ○ スクリプト
  #--------------------------------------------------------------------------
unless $TEST
  def command_355
    script = @list[@index].parameters[0] + "\n"
    while next_event_code == 655
      @index += 1
      script += @list[@index].parameters[0] + "\n"
    end
    begin
      eval(script)
    rescue Exception => exc
      if $TEST
        p "スクリプトコマンドの実行に失敗しました"
        p exc
      end
    end
  end
end
end





