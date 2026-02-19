
=begin

もんむす・くえすと！ＲＰＧ
　トリス修正T  ver8  2015/07/11



機能一覧　説明は下　このverで新規追加したものは●　変更したものは○　削除は×
・「バトルの中断」で戦闘終了した場合は、「全ての冒険」の逃走回数を増やさない
・「メモに <スキップ不能> がある敵」は「魔物図鑑」の凌辱回数の表示を0に
・ルカの拘束中に「全員攻撃」すると、先頭の敵を攻撃したのを修正
・<戦闘開始時/ターン開始時/ターン終了時発動>を同キャラ同タイミングでは１回までに
・キャラ図鑑の固有アビリティの文末に「。」を自動追加していたのを削除
・アイテム系図鑑の説明文の「。」の自動追加を「改行」に変更
・マップ表示名の \V[n] を変数n番の値に置換
・特定スイッチがオンの時、100%未満のエンカウント率とスキル等の「逃げる」を無効
・冒険の記録の「今回の冒険」に混沌の迷宮の到達階層を表示
○物理攻撃を反射する拡張特徴 <拡張物理反射率 N%>
・IDが1001以上のエネミーがいる場合、その分アクター好感度変数が圧迫されたのを修正
・IDが1001～2000のエネミーは敗北時に実行するコモンイベントを[3000]に
・IDが1001～2000のエネミーは「メモに<図鑑除外>が入っているのと同じ扱い」に
・IDが1001～2000の敵は魔物図鑑「倒した、イカせた、凌辱された」数をID-1000に記録
・IDが1001～2000のエネミーは<友好度表示>スキルの対象選択で「友好度：なし」と表示
・指定アクターの経験値を増加させるスクリプトコマンド  gain_actor_exp


機能　説明
・特定スイッチがオンの時、100%未満のエンカウント率とスキル等の「逃げる」を無効
スイッチIDは IDReserve.rb の18行目 STRICT_ENCOUNT で設定
エンカウント率は、各特徴オブジェクトについて、100%未満の設定を無効
　例：50%と200%の装備品がある場合の結果は、オフ時（通常）は100%、オン時は200%
逃走は、スキル/アイテムの効果にのみ影響し、パーティコマンドの逃走には影響なし

・冒険の記録の「今回の冒険」に混沌の迷宮の到達階層を表示
変数IDは IDReserve.rb の114行目 EX_DUNGEON_REACH で設定
その変数の値が1以上の時のみ、それを階層として表示

・物理攻撃を反射する拡張特徴 <拡張物理反射率 N%>
この拡張特徴を持つ装備などがアクターに複数ある場合、全て加算する
メッセージは「(対象者名)は攻撃を跳ね返した！」
詳細情報では「物理反射率アップ50%」のように表示

・IDが1001以上のエネミーがいる場合、その分アクター好感度変数が圧迫されたのを修正
以前は、特定の変数IDの値を変更（change_friendなども含む）する時は、
　以下の制限がかかりました。
　①IDが「2000～2000+最高エネミーID」なら、
　　　値を0～100に制限（-1を代入しようとすると0が代入される）
　②上記以外かつ、IDが「3000～3000+最高アクターID」なら、
　　　値を0～1073741823に制限
上記①により、「データベースのエネミー最大数が1005個」のゲーム本体では、
　アクター1～5の好感度（変数3001～3005）の上限が100になりました。
また「アクター5の好感度が200のセーブデータ」を上記ゲーム本体で読み込んだ場合、
　一度でも「アクター5の好感度の変更（例：10加算）」をすると、
　その値は100まで下げられました。
この問題に対して、上記①の条件の
　最後「最高エネミーID」を「最高エネミーID か 1000 の低いほう」にすることで、
　範囲が最大でも2000～3000となるようにして解決しました。


・IDが1001～2000のエネミーは敗北時に実行するコモンイベントを[3000]に
この実行時は、コンフィグによるスキップおよびスキップ確認は行われない

・IDが1001～2000の敵は魔物図鑑「倒した、イカせた、凌辱された」数をID-1000に記録
それ以外の情報はその敵のID(-1000しないID)の魔物図鑑に記録されるが、
　その敵は魔物図鑑に表示されないので意味はない

・指定アクターの経験値を増加させるスクリプトコマンド  gain_actor_exp
gain_actor_exp(actor_id, kind, n, rate)
[actor_id] アクターID
[kind] 種類　「:base」でベース経験　「:class」で職業経験　「:tribe」で種族経験
[n]    増加する値　マイナスの値を指定すると減少する
[rate] 経験獲得率(ベース)か職業経験獲得率(職業、種族)をnに乗じるか true/false
actor_idとplusは変数指定可、rateはスイッチ指定可

また最後に1つ追加して
gain_actor_exp(actor_id, kind, n, rate, show)
[show] レベルアップとスキル習得メッセージを表示するか true/false スイッチ指定可
showを省略(actor_id, kind, n, rate)した場合、true(表示する)となる

=end

#==============================================================================
# ■ Game_Temp
#==============================================================================
class Game_Temp
  #--------------------------------------------------------------------------
  # ● 公開インスタンス変数
  #--------------------------------------------------------------------------
  attr_accessor :event_abort
end
#==============================================================================
# ■ Game_Interpreter
#==============================================================================
class Game_Interpreter
  #--------------------------------------------------------------------------
  # ● バトルの中断
  #--------------------------------------------------------------------------
  def command_340
    $game_temp.event_abort = true
    BattleManager.abort
    Fiber.yield
  end
  #--------------------------------------------------------------------------
  # ● 指定アクターの経験値増加
  #--------------------------------------------------------------------------
  def gain_actor_exp(actor_id, kind, n, rate, show = true)
    actor = $game_actors[actor_id]
    case kind
    when :base
      now  = actor.base_exp
      plus = n
      plus = (n * actor.final_exp_rate).ceil if rate
    when :class
      now  = actor.class_exp
      plus = n
      plus = (n * actor.final_cexp_rate).ceil if rate
    when :tribe
      now  = actor.tribe_exp
      plus = n
      plus = (n * actor.final_cexp_rate).ceil if rate
    end
    actor.change_exp(now + plus, show, kind)
  end
end
#==============================================================================
# ■ Scene_Map
#==============================================================================
class Scene_Map < Scene_Base
  #--------------------------------------------------------------------------
  # ● 開始処理
  #--------------------------------------------------------------------------
  alias :event_abort_start :start
  def start
    event_abort_start
    $game_temp.event_abort = false
  end
end
#==============================================================================
# ■ BattleManager
#==============================================================================
class << BattleManager
  #--------------------------------------------------------------------------
  # ○ 中断の処理 図鑑/カウント
  #--------------------------------------------------------------------------
#  alias nw_count_process_abort process_abort
  def process_abort
    tmp = []
    $game_troop.members.each {|enemy| tmp.push(enemy.id) if enemy}
    $game_library.enemy.set_discovery(tmp)
    $game_library.count_up_party_escape unless $game_temp.event_abort
    nw_count_process_abort
  end
end


#==============================================================================
# ■ Game_Library
#==============================================================================
class Game_Library
  #--------------------------------------------------------------------------
  # ● エネミーが勝利した回数取得
  #--------------------------------------------------------------------------
  def enemy_victory(id)
    return 0 if $data_enemies[id] and $data_enemies[id].no_lose_skip?
    enemy = @enemy_stat[id] || {}
    num = enemy[:victory] || 0
    return num
  end
end

#==============================================================================
# ■ Scene_Battle
#==============================================================================
class Scene_Battle < Scene_Base
  #--------------------------------------------------------------------------
  # ○ コマンド［全員攻撃］
  #--------------------------------------------------------------------------
  def command_all_attack
    $game_party.members.each do |actor|
      loop do
        break unless actor.inputable?
        actor.input.set_attack
        if actor.bind_target?
          actor.input.target_index = BattleManager.bind_user_index
        else
          actor.input.target_index = $game_troop.alive_members[0].index
        end
        break unless actor.next_command
      end
    end
    @info_viewport.visible = false
    turn_start
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
    return if not $game_party.in_battle
    return if $game_troop.interpreter.running?
    ($game_troop.alive_members + $game_party.alive_members).each{|member|
      member.battle_start_skill.each{|obj|
        if rand < obj[:per]
          skill_interrupt(member, obj[:id])
          break
        end
      }
    }
  end
  #--------------------------------------------------------------------------
  # ● ターン開始スキルの設定
  #--------------------------------------------------------------------------
  def set_turn_start_skill
    @action_game_masters = []
    return if giveup?
    return if not $game_party.in_battle
    return if $game_troop.interpreter.running?
    ($game_troop.alive_members + $game_party.alive_members).each{|member|
      member.turn_start_skill.each{|obj|
        if rand < obj[:per]
          skill_interrupt(member, obj[:id])
          break
        end
      }
    }
  end
  #--------------------------------------------------------------------------
  # ● ターン終了スキルの設定
  #--------------------------------------------------------------------------
  def set_turn_end_skill
    @action_game_masters = []
    return if giveup?
    return if not $game_party.in_battle
    return if $game_troop.interpreter.running?
    ($game_troop.alive_members + $game_party.alive_members).each{|member|
      member.turn_end_skill.each{|obj|
        if rand < obj[:per]
          skill_interrupt(member, obj[:id])
          break
        end
      }
    }
  end
end


#==============================================================================
# ■ Window_Library_RightMain
#==============================================================================
class Window_Library_RightMain < Window_Selectable
  #--------------------------------------------------------------------------
  # ● 冒険の記録-page1
  #--------------------------------------------------------------------------
  def draw_record1(rect)
    lr = Rect.new(rect.x, rect.y, Integer(rect.width * 0.65), rect.height)
    rr = Rect.new(rect.x + Integer(rect.width * 0.65), rect.y, Integer(rect.width * 0.35), rect.height)    
    change_color(system_color)
    draw_text(lr, "プレイ時間:");                        lr.y += rect.height
    draw_text(lr, "セーブ回数:");                        lr.y += rect.height
    draw_text(lr, "周回数:");                            lr.y += rect.height
    draw_text(lr, "現在の難易度:");                      lr.y += rect.height
    draw_text(lr, "クリアした最高難度:");                lr.y += rect.height
    draw_text(lr, "戦闘回数:");                          lr.y += rect.height
    draw_text(lr, "全滅した回数:");                      lr.y += rect.height        
    draw_text(lr, "仲間の数:");                          lr.y += rect.height
    draw_text(lr, "倒したバトルファッカーの数:");        lr.y += rect.height
    draw_text(lr, ex_dungeon_record[0]);                 lr.y += rect.height
    change_color(normal_color)
    draw_text(rr, $game_system.playtime_s);              rr.y += rect.height    
    draw_text(rr, "#{$game_system.save_count}回");       rr.y += rect.height    
    draw_text(rr, track);                                rr.y += rect.height    
    draw_text(rr, current_difficulty);                   rr.y += rect.height
    draw_text(rr, clear_difficulty);                     rr.y += rect.height    
    draw_text(rr, "#{$game_system.battle_count}回");     rr.y += rect.height    
    draw_text(rr, "#{$game_system.party_lose_count}回"); rr.y += rect.height    
    draw_text(rr, "#{party_friendly}人");                rr.y += rect.height
    draw_text(rr, battlefucker_defeat);                  rr.y += rect.height
    draw_text(rr, ex_dungeon_record[1]);                 rr.y += rect.height
  end
  #--------------------------------------------------------------------------
  # ● 冒険の記録-page1　混沌の迷宮の到達階層
  #--------------------------------------------------------------------------
  def ex_dungeon_record
    var = $game_variables[NWConst::Var::EX_DUNGEON_REACH]
    if var > 0
      return ["混沌の迷宮の最高到達階層:", "第#{var}階層"]
    else
      return ["", ""]
    end
  end
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
      all_text += "\n"
    }
    all_text.slice!(-1, 1)
    rect = draw_text_auto_line_ex(rect, all_text)
    return rect.y
  end
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
      all_text += "\n"
    end
    rect = draw_text_auto_line_ex(rect, all_text)
    
    return line_height + LINE_HEIGHT
  end
end

#==============================================================================
# ■ Game_Map
#==============================================================================
class Game_Map
  #--------------------------------------------------------------------------
  # ● 表示名の取得
  #--------------------------------------------------------------------------
  def display_name
    @map.display_name.gsub(/\\V\[(\d+)\]/i) { $game_variables[$1.to_i] }
  end
end

#==============================================================================
# ■ Game_Party
#==============================================================================
class Game_Party < Game_Unit
  #--------------------------------------------------------------------------
  # ● エンカウント倍率
  #--------------------------------------------------------------------------
  def encounter_rate
    array = members.inject([]){|ary, actor| ary + actor.encounter_rate}
    array.delete_if {|r| r < 1.0 } if $game_switches[NWConst::Sw::STRICT_ENCOUNT]
    unless array.empty?
      rate = array.inject(1.0){|result, r| result * r}
      return rate
    else
      return 1.0
    end
  end
end
#==============================================================================
# ■ BattleManager
#==============================================================================
class << BattleManager
  #--------------------------------------------------------------------------
  # ● 強制逃走が可能か
  #--------------------------------------------------------------------------
  def can_forced_escape?
    can_escape? and not $game_switches[NWConst::Sw::STRICT_ENCOUNT]
  end
  #--------------------------------------------------------------------------
  # ● 強制逃走の処理
  #--------------------------------------------------------------------------
  def process_forced_escape
    $game_message.add(sprintf(Vocab::EscapeStart, $game_party.name))
    Sound.play_escape
    if can_forced_escape?
      process_abort
    else
      $game_message.add('\.' + Vocab::EscapeFailure)
    end
    wait_for_message
  end
end
#==============================================================================
# ■ Game_Battler
#==============================================================================
class Game_Battler < Game_BattlerBase  
  #--------------------------------------------------------------------------
  # ○ 使用効果［特殊効果］
  #--------------------------------------------------------------------------
  def item_effect_special(user, item, effect)
    case effect.data_id
    when SPECIAL_EFFECT_ESCAPE
      if actor?
        # 味方の強制逃走
        BattleManager.process_forced_escape
        @result.success = true
      else
        # 敵の強制逃走
        if BattleManager.can_forced_escape?
          escape
          @result.success = true
        else
          @result.success = false
        end
      end
    end
  end
end


#==============================================================================
# ■ RPG::BaseItem
#==============================================================================
class RPG::BaseItem
  #--------------------------------------------------------------------------
  # ● メモ欄解析処理
  #--------------------------------------------------------------------------
 # alias nw_kure_base_item_note_analyze nw_note_analyze
  def nw_note_analyze
    nw_kure_base_item_note_analyze
       
    self.note.each_line do |line|
      if NWRegexp::BaseItem::FEATURE_XPARAM_EX.match(line)
        array = [:命中, :回避, :会心, :会心回避, :魔法回避, :魔法反射, :反撃, :HP再生, :MP再生, :TP再生]
        @add_features.push(RPG::BaseItem::Feature.new(FEATURE_XPARAM_EX, array.index($1.to_sym), $2.to_f * 0.01))
      elsif NWRegexp::BaseItem::PARTY_ABILITY.match(line)
        kind = [:獲得金額, :獲得アイテム, :エンカウント, :仲間加入]
        kind_id = kind.index($1.to_sym)
        @add_features.push(RPG::BaseItem::Feature.new(FEATURE_PARTY_EX_ABILITY, kind_id, $2.to_f * 0.01))
      elsif NWRegexp::BaseItem::SLOT_CHANCE.match(line)
        @add_features.push(RPG::BaseItem::Feature.new(FEATURE_PARTY_EX_ABILITY, SLOT_CHANCE, $1.to_i))
      elsif NWRegexp::BaseItem::UNLOCK_LEVEL.match(line)
        @add_features.push(RPG::BaseItem::Feature.new(FEATURE_PARTY_EX_ABILITY, UNLOCK_LEVEL, $1.to_i))
      elsif NWRegexp::BaseItem::STEAL_SUCCESS.match(line)
        @add_features.push(RPG::BaseItem::Feature.new(
          FEATURE_BATTLER_ABILITY, STEAL_SUCCESS, $1.to_f * 0.01))
      elsif NWRegexp::BaseItem::GET_EXP_RATE.match(line)
        @add_features.push(RPG::BaseItem::Feature.new(
          FEATURE_BATTLER_ABILITY, GET_EXP_RATE, $1.to_f * 0.01))        
      elsif NWRegexp::BaseItem::GET_CLASSEXP_RATE.match(line)
        @add_features.push(RPG::BaseItem::Feature.new(
          FEATURE_BATTLER_ABILITY, GET_CLASSEXP_RATE, $1.to_f * 0.01))        
      elsif NWRegexp::BaseItem::AUTO_STAND.match(line)
        @add_features.push(RPG::BaseItem::Feature.new(
          FEATURE_BATTLER_ABILITY, AUTO_STAND, $1.to_f * 0.01))
      elsif NWRegexp::BaseItem::HEEL_REVERSE.match(line)
        @add_features.push(RPG::BaseItem::Feature.new(
          FEATURE_BATTLER_ABILITY, HEEL_REVERSE, $1.to_f * 0.01))
      elsif NWRegexp::BaseItem::AUTO_STATE.match(line)
        array = []
        $1.split(/\,\s?/).each{|id|array.push(id.to_i)}
        @add_features.push(RPG::BaseItem::Feature.new(
          FEATURE_BATTLER_ABILITY, AUTO_STATE, array))
      elsif NWRegexp::BaseItem::TRIGGER_STATE.match(line)
        hash = {:point => $1.to_sym, :trigger => $2.to_i, :per => $3.to_f * 0.01, :state_id => $4.to_i}
        @add_features.push(RPG::BaseItem::Feature.new(
          FEATURE_BATTLER_ABILITY, TRIGGER_STATE, hash))
      elsif NWRegexp::BaseItem::METAL_BODY.match(line)
        @add_features.push(RPG::BaseItem::Feature.new(
          FEATURE_BATTLER_ABILITY, METAL_BODY, $1.to_i))
      elsif NWRegexp::BaseItem::DEFENSE_WALL.match(line)  
        @add_features.push(RPG::BaseItem::Feature.new(
          FEATURE_BATTLER_ABILITY, DEFENSE_WALL, $1.to_i))
      elsif NWRegexp::BaseItem::INVALIDATE_WALL.match(line)  
        @add_features.push(RPG::BaseItem::Feature.new(
          FEATURE_BATTLER_ABILITY, INVALIDATE_WALL, $1.to_i))
      elsif NWRegexp::BaseItem::DAMAGE_MP_CONVERT.match(line)
        @add_features.push(RPG::BaseItem::Feature.new(
          FEATURE_BATTLER_ABILITY, DAMAGE_MP_CONVERT, $1.to_f * 0.01))          
      elsif NWRegexp::BaseItem::DAMAGE_GOLD_CONVERT.match(line)
        @add_features.push(RPG::BaseItem::Feature.new(
          FEATURE_BATTLER_ABILITY, DAMAGE_GOLD_CONVERT, $1.to_f * 0.01))          
      elsif NWRegexp::BaseItem::DAMAGE_MP_DRAIN.match(line)
        @add_features.push(RPG::BaseItem::Feature.new(
          FEATURE_BATTLER_ABILITY, DAMAGE_MP_DRAIN, $1.to_f * 0.01))          
      elsif NWRegexp::BaseItem::DAMAGE_GOLD_DRAIN.match(line)
        @add_features.push(RPG::BaseItem::Feature.new(
          FEATURE_BATTLER_ABILITY, DAMAGE_GOLD_DRAIN, $1.to_f * 0.01))          
      elsif NWRegexp::BaseItem::DEAD_SKILL.match(line)
        @add_features.push(RPG::BaseItem::Feature.new(
          FEATURE_BATTLER_ABILITY, DEAD_SKILL, $1.to_i))
      elsif NWRegexp::BaseItem::BATTLE_START_SKILL.match(line)
        @add_features.push(RPG::BaseItem::Feature.new(
          FEATURE_BATTLER_ABILITY, BATTLE_START_SKILL,
          {:id => $1.to_i, :per => $2.to_f * 0.01}))
      elsif NWRegexp::BaseItem::TURN_START_SKILL.match(line)
        @add_features.push(RPG::BaseItem::Feature.new(
          FEATURE_BATTLER_ABILITY, TURN_START_SKILL,
          {:id => $1.to_i, :per => $2.to_f * 0.01}))
      elsif NWRegexp::BaseItem::TURN_END_SKILL.match(line)
        @add_features.push(RPG::BaseItem::Feature.new(
          FEATURE_BATTLER_ABILITY, TURN_END_SKILL,
          {:id => $1.to_i, :per => $2.to_f * 0.01}))
      elsif NWRegexp::BaseItem::CHANGE_ACTION.match(line)
        array = []
        $1.scan(/(\d+)\-(\d+)/){|a, b| array.push({:id => a.to_i, :per => b.to_f * 0.01})}
        @add_features.push(RPG::BaseItem::Feature.new(
          FEATURE_BATTLER_ABILITY, CHANGE_ACTION, array))
      elsif NWRegexp::BaseItem::STYPE_COST_RATE.match(line)  
        @add_features.push(RPG::BaseItem::Feature.new(
          FEATURE_BATTLER_ABILITY, STYPE_COST_RATE, {:type => $1.to_sym, :id => $2.to_i, :rate => $3.to_f * 0.01}))
      elsif NWRegexp::BaseItem::SKILL_COST_RATE.match(line)  
        @add_features.push(RPG::BaseItem::Feature.new(
          FEATURE_BATTLER_ABILITY, SKILL_COST_RATE, {:type => $1.to_sym, :id => $2.to_i, :rate => $3.to_f * 0.01}))
      elsif NWRegexp::BaseItem::TP_COST_RATE.match(line)  
        @add_features.push(RPG::BaseItem::Feature.new(
          FEATURE_BATTLER_ABILITY, TP_COST_RATE, $1.to_f * 0.01))
      elsif NWRegexp::BaseItem::HP_COST_RATE.match(line)
        @add_features.push(RPG::BaseItem::Feature.new(
          FEATURE_BATTLER_ABILITY, HP_COST_RATE, $1.to_f * 0.01))
      elsif NWRegexp::BaseItem::GOLD_COST_RATE.match(line)
        @add_features.push(RPG::BaseItem::Feature.new(
          FEATURE_BATTLER_ABILITY, GOLD_COST_RATE, $1.to_f * 0.01))
      elsif NWRegexp::BaseItem::INCREASE_TP.match(line)
        @add_features.push(RPG::BaseItem::Feature.new(
          FEATURE_BATTLER_ABILITY, INCREASE_TP, {:plus => $1.to_s == "増加", :num => $2.to_i, :per => $3 ? true : false}))
      elsif NWRegexp::BaseItem::START_TP_RATE.match(line)
        @add_features.push(RPG::BaseItem::Feature.new(
          FEATURE_BATTLER_ABILITY, START_TP_RATE, $1.to_f * 0.01))
      elsif NWRegexp::BaseItem::BATTLE_END_HEEL_HP.match(line)
        @add_features.push(RPG::BaseItem::Feature.new(
          FEATURE_BATTLER_ABILITY, BATTLE_END_HEEL_HP, $1.to_f * 0.01))
      elsif NWRegexp::BaseItem::BATTLE_END_HEEL_MP.match(line)
        @add_features.push(RPG::BaseItem::Feature.new(
          FEATURE_BATTLER_ABILITY, BATTLE_END_HEEL_MP, $1.to_f * 0.01))
      elsif NWRegexp::BaseItem::NORMAL_ATTACK.match(line)
        @add_features.push(RPG::BaseItem::Feature.new(
          FEATURE_BATTLER_ABILITY, Battler::NORMAL_ATTACK, $1.to_i))          
      elsif NWRegexp::BaseItem::COUNTER_SKILL.match(line)
        array = []
        $1.split(/\,\s?/).each{|id| array.push(id.to_i)}
        @add_features.push(RPG::BaseItem::Feature.new(
          FEATURE_BATTLER_ABILITY, COUNTER_SKILL, array))
      elsif NWRegexp::BaseItem::FINAL_INVOKE.match(line)  
        array = []
        $1.split(/\,\s?/).each{|id| array.push(id.to_i)}
        @add_features.push(RPG::BaseItem::Feature.new(
          FEATURE_BATTLER_ABILITY, FINAL_INVOKE, array))
      elsif NWRegexp::BaseItem::CERTAIN_COUNTER.match(line)
        @add_features.push(RPG::BaseItem::Feature.new(
          FEATURE_BATTLER_ABILITY, CERTAIN_COUNTER, $1.to_f * 0.01))
      elsif NWRegexp::BaseItem::MAGICAL_COUNTER.match(line)
        @add_features.push(RPG::BaseItem::Feature.new(
          FEATURE_BATTLER_ABILITY, MAGICAL_COUNTER, $1.to_f * 0.01))
      elsif NWRegexp::BaseItem::CERTAIN_COUNTER_EX.match(line)
        @add_features.push(RPG::BaseItem::Feature.new(
          FEATURE_BATTLER_ABILITY, CERTAIN_COUNTER_EX, $1.to_f * 0.01))
      elsif NWRegexp::BaseItem::PHYSICAL_COUNTER_EX.match(line)
        @add_features.push(RPG::BaseItem::Feature.new(
          FEATURE_BATTLER_ABILITY, PHYSICAL_COUNTER_EX, $1.to_f * 0.01))
      elsif NWRegexp::BaseItem::MAGICAL_COUNTER_EX.match(line)
        @add_features.push(RPG::BaseItem::Feature.new(
          FEATURE_BATTLER_ABILITY, MAGICAL_COUNTER_EX, $1.to_f * 0.01))
      elsif NWRegexp::BaseItem::CONSIDERATE.match(line)  
        @add_features.push(RPG::BaseItem::Feature.new(
          FEATURE_BATTLER_ABILITY, CONSIDERATE, $1.to_f * 0.01))
      elsif NWRegexp::BaseItem::INVOKE_REPEATS_TYPE.match(line)
        hash = {}
        $1.scan(/(\d+)\-(\d+)/){|a, b| hash[a.to_i] = b.to_i}
        @add_features.push(RPG::BaseItem::Feature.new(
          FEATURE_BATTLER_ABILITY, INVOKE_REPEATS_TYPE, hash))
      elsif NWRegexp::BaseItem::INVOKE_REPEATS_SKILL.match(line)
        hash = {}
        $1.scan(/(\d+)\-(\d+)/){|a, b| hash[a.to_i] = b.to_i}
        @add_features.push(RPG::BaseItem::Feature.new(
          FEATURE_BATTLER_ABILITY, INVOKE_REPEATS_SKILL, hash))
      elsif NWRegexp::BaseItem::OWN_CRUSH_RESIST.match(line)
        @add_features.push(RPG::BaseItem::Feature.new(
          FEATURE_BATTLER_ABILITY, OWN_CRUSH_RESIST, true))        
      elsif NWRegexp::BaseItem::ELEMENT_DRAIN.match(line)
        array = []
        $1.split(/\,\s?/).each{|id| array.push(id.to_i)}
        @add_features.push(RPG::BaseItem::Feature.new(
          FEATURE_BATTLER_ABILITY, ELEMENT_DRAIN, array))
      elsif NWRegexp::BaseItem::IGNORE_OVER_DRIVE.match(line)
        @add_features.push(RPG::BaseItem::Feature.new(
          FEATURE_BATTLER_ABILITY, IGNORE_OVER_DRIVE, true))        
      elsif NWRegexp::BaseItem::INSTANT_DEAD_REVERSE.match(line)
        @add_features.push(RPG::BaseItem::Feature.new(
          FEATURE_BATTLER_ABILITY, INSTANT_DEAD_REVERSE, true))
      elsif NWRegexp::BaseItem::CHANGE_SKILL.match(line)
        hash = {}
        $1.scan(/(\d+)\-(\d+)/){|a, b| hash[a.to_i] = b.to_i}
        @add_features.push(RPG::BaseItem::Feature.new(
          FEATURE_BATTLER_ABILITY, CHANGE_SKILL, hash))
      elsif NWRegexp::BaseItem::ITEM_COST_SCRIMP.match(line)
        hash = {}
        $1.scan(/(\d+)\-(\d+)/){|a, b| hash[a.to_i] = b.to_f * 0.01}
        @add_features.push(RPG::BaseItem::Feature.new(
          FEATURE_BATTLER_ABILITY, ITEM_COST_SCRIMP, hash))
      elsif NWRegexp::BaseItem::NEED_ITEM_IGNORE.match(line)
        array = []
        $1.split(/\,\s?/).each{|id| array.push(id.to_i)}          
        @add_features.push(RPG::BaseItem::Feature.new(
          FEATURE_BATTLER_ABILITY, NEED_ITEM_IGNORE, array))
      elsif NWRegexp::BaseItem::MULTI_BOOSTER.match(line)
        kind = [
          :属性強化,
          :武器強化物理,
          :武器強化魔法,
          :武器強化必中,
          :通常攻撃強化,
          :ステート割合強化タイプ,
          :ステート固定強化タイプ,
          :スキルタイプ強化,
          :ステート割合強化スキル,
          :スキル強化
        ]
        kind_id = kind.index($1.to_sym)
        hash = {}
        $2.scan(/(\d+)\-(\d+)/){|a, b| hash[a.to_i] = b.to_f * 0.01}
        @add_features.push(RPG::BaseItem::Feature.new(FEATURE_MULTI_BOOSTER, kind_id, hash))
      elsif NWRegexp::BaseItem::WTYPE_SKILL_BOOST.match(line)  
        hash = {}
        $1.scan(/(\d+)\-(\d+)\-(\d+)/){|a, b, c| hash[[a.to_i, b.to_i]] = c.to_f * 0.01}
        @add_features.push(RPG::BaseItem::Feature.new(FEATURE_MULTI_BOOSTER, WTYPE_SKILL, hash))
      elsif NWRegexp::BaseItem::COUNTER_BOOST.match(line)
        @add_features.push(RPG::BaseItem::Feature.new(FEATURE_MULTI_BOOSTER, COUNTER, $1.to_f * 0.01))
      elsif NWRegexp::BaseItem::FALL_HP_BOOST.match(line)
        hash = {:per => $1.to_f * 0.01, :boost => $2.to_f * 0.01}
        @add_features.push(RPG::BaseItem::Feature.new(FEATURE_MULTI_BOOSTER, FALL_HP, hash))
      elsif NWRegexp::BaseItem::OVER_SOUL.match(line)
        @add_features.push(RPG::BaseItem::Feature.new(
          FEATURE_MULTI_BOOSTER, OVER_SOUL, $1.to_f * 0.01))
      elsif NWRegexp::BaseItem::DUMMY_ENCHANT.match(line)
        @add_features.push(RPG::BaseItem::Feature.new(FEATURE_DUMMY_ENCHANT, nil, $1.to_s))
      elsif NWRegexp::BaseItem::TERRAIN_BOOSTER.match(line)
        @add_features.push(RPG::BaseItem::Feature.new(
          FEATURE_TERRAIN_BOOSTER, $1.to_sym, $2.nil? ? 0.2 : 0.4))
      elsif NWRegexp::BaseItem::SELLD_DRAW.match(line)
        @data_ex[:selld_draw] = $1.to_s
      elsif NWRegexp::BaseItem::EXCLUDE.match(line)
        @data_ex[:lib_exclude?] = true
      elsif NWRegexp::BaseItem::SKILL_CONVERT_PARAM.match(line)
        @data_ex[:skill_convert_param_data] ||= Hash.new
        @data_ex[:skill_convert_param_data][$1.to_i] ||= []
        @data_ex[:skill_convert_param_data][$1.to_i].push([$2.to_i + 1, $3.to_i + 1])
      elsif NWRegexp::BaseItem::PHYSICAL_REFLECTION.match(line)
        @add_features.push(RPG::BaseItem::Feature.new(
          FEATURE_BATTLER_ABILITY, PHYSICAL_REFLECTION, $1.to_f * 0.01))
      end
    end
  end
end
#==============================================================================
# ■ NWFeature
#==============================================================================
module NWFeature
  module Battler
    PHYSICAL_REFLECTION        = 46
  end
end
#==============================================================================
# ■ NWRegexp::BaseItem
#==============================================================================
module NWRegexp::BaseItem
  ## 拡張追加能力値
  PHYSICAL_REFLECTION       = /<拡張物理反射率\s?([-+]?\d+)\%>/i
end
#==============================================================================
# ■ RPG::BaseItem
#==============================================================================
class RPG::BaseItem
  #--------------------------------------------------------------------------
  # ● バトラーアビリティ名の取得
  #--------------------------------------------------------------------------  
  def battler_ability_name(ft)    
    method_table = {
      STEAL_SUCCESS           => :steal_success_name,
      AUTO_STAND              => :auto_stand_name,
      HEEL_REVERSE            => :heel_reverse_name,
      AUTO_STATE              => :auto_state_names,
      TRIGGER_STATE           => :trigger_state_name,
      METAL_BODY              => :metal_body_name,
      DEFENSE_WALL            => :defense_wall_name,
      INVALIDATE_WALL         => :invalidate_wall_name,
      DAMAGE_MP_CONVERT       => :damage_mp_convert_name,
      DAMAGE_GOLD_CONVERT     => :damage_gold_convert_name,
      DAMAGE_MP_DRAIN         => :damage_mp_drain_name,
      DAMAGE_GOLD_DRAIN       => :damage_gold_drain_name,
      DEAD_SKILL              => :dead_skill_name,
      BATTLE_START_SKILL      => :battle_start_skill_name,
      TURN_START_SKILL        => :turn_start_skill_name,
      TURN_END_SKILL          => :turn_end_skill_name,
      CHANGE_ACTION           => :change_action_names,
      STYPE_COST_RATE         => :stype_cost_rate_name,
      SKILL_COST_RATE         => :skill_cost_rate_name,
      TP_COST_RATE            => :tp_cost_rate_name,
      HP_COST_RATE            => :hp_cost_rate_name,
      GOLD_COST_RATE          => :gold_cost_rate_name,
      INCREASE_TP             => :increase_tp_name,
      START_TP_RATE           => :start_tp_rate_name,
      BATTLE_END_HEEL_HP      => :battle_end_heel_hp_name,
      BATTLE_END_HEEL_MP      => :battle_end_heel_mp_name,
      Battler::NORMAL_ATTACK  => :normal_attack_name,
      COUNTER_SKILL           => :counter_skill_names,
      FINAL_INVOKE            => :final_invoke_names,
      CERTAIN_COUNTER         => :certain_counter_name,
      MAGICAL_COUNTER         => :magical_counter_name,
      PHYSICAL_COUNTER_EX     => :physical_counter_ex_name,
      MAGICAL_COUNTER_EX      => :magical_counter_ex_name,
      CERTAIN_COUNTER_EX      => :certain_counter_ex_name,
      CONSIDERATE             => :considerate_name,
      GET_EXP_RATE            => :get_exp_rate_name,
      GET_CLASSEXP_RATE       => :get_classexp_rate_name,
      INVOKE_REPEATS_TYPE     => :invoke_repeats_type_names,
      INVOKE_REPEATS_SKILL    => :invoke_repeats_skill_names,
      OWN_CRUSH_RESIST        => :own_crush_resist_name,
      ELEMENT_DRAIN           => :element_drain_names,
      IGNORE_OVER_DRIVE       => :ignore_over_drive_name,
      INSTANT_DEAD_REVERSE    => :instant_dead_reverse_name,
      CHANGE_SKILL            => :change_skill_name,
      PHYSICAL_REFLECTION     => :physical_reclection_name
      
    }
    method_name = method_table[ft.data_id]
    return method_name ? send(method_name, ft) : "UNKNOWN:BattlerAbility"    
  end
  #--------------------------------------------------------------------------
  # ● 盗み成功率名の取得
  #--------------------------------------------------------------------------    
  def physical_reclection_name(ft)
    rate = (ft.value * 100.0).to_i
    return "物理反射率#{0 < rate ? "アップ" : "ダウン"}#{rate.abs}%"
  end
end
#==============================================================================
# ■ Vocab　ベース/Module
#==============================================================================
module Vocab
  PhysicalReflection = "%sは攻撃を跳ね返した！"
end
#==============================================================================
# ■ Window_BattleLog
#==============================================================================
class Window_BattleLog < Window_Selectable
  #--------------------------------------------------------------------------
  # ● 反射の表示
  #--------------------------------------------------------------------------
  def display_reflection(target, item)
    Sound.play_reflection
    if item.physical?
      add_text(sprintf(Vocab::PhysicalReflection, target.name))
    else
      add_text(sprintf(Vocab::MagicReflection, target.name))
    end
    wait
    back_one
  end
end
#==============================================================================
# ■ Game_Battler
#==============================================================================
class Game_Battler < Game_BattlerBase
  #--------------------------------------------------------------------------
  # ● スキル／アイテムの反射率計算
  #--------------------------------------------------------------------------
  def item_mrf(user, item)
    return physical_reflection_rate if item.physical? # 物理攻撃なら物理反射率
    return mrf if item.magical?             # 魔法攻撃なら魔法反射率を返す
    return 0
  end
  #--------------------------------------------------------------------------
  # ● 物理反射率の取得
  #--------------------------------------------------------------------------
  def physical_reflection_rate
    features_sum(FEATURE_BATTLER_ABILITY, PHYSICAL_REFLECTION)
  end
end

#==============================================================================
# ■ Game_Variables
#==============================================================================
class Game_Variables
  #--------------------------------------------------------------------------
  # ○ 変数の設定　「変数拡張」93行目
  #--------------------------------------------------------------------------
 # alias nw_array_set []=
  def []=(variable_id, value)
    case variable_id
    when (ENEMY_REL_BASE...(ENEMY_REL_BASE + [$data_enemies.size, 1001].min))
      # ※[$data_enemies.size, 1001].min 最高で1001 → 2000...3001 ＝ 2000～3000
      # 友好度制限0～100
      value = [[value, 0].max, 100].min
    when (ACTOR_REL_BASE...(ACTOR_REL_BASE+$data_actors.size))
      # 別人格でも好感度は統一
      actor = $data_actors[variable_id - ACTOR_REL_BASE]
      if actor && actor.persona_kind == :sub
        variable_id = ACTOR_REL_BASE + actor.original_persona_id
      end
      # 好感度制限0～1073741823(2**30-1)
      value = [[value, 0].max, 1073741823].min 
    end
    nw_array_set(variable_id, value)    
  end
  #--------------------------------------------------------------------------
  # ○ 変数の設定　「トリス修正M」統合時は消す
  #--------------------------------------------------------------------------
  alias nw_common_set []=
  def []=(variable_id, value)
    nw_common_set(common_variable_id(variable_id), value)    
  end
end
#==============================================================================
# ■ RPG::Enemy
#==============================================================================
class RPG::Enemy < RPG::BaseItem
  #--------------------------------------------------------------------------
  # ● 混沌の迷宮エネミーかどうか
  #--------------------------------------------------------------------------
  def ex_dungeon_enemy?
    (1001..2000).include?(id)
  end
  #--------------------------------------------------------------------------
  # ● 図鑑除外
  #--------------------------------------------------------------------------
  def lib_exclude?
    return true if ex_dungeon_enemy?
    return super
  end
  #--------------------------------------------------------------------------
  # ● 敗北後イベントID
  #--------------------------------------------------------------------------  
  def lose_event_id
    return NWConst::Common::LOSE_EVENT_BASE if ex_dungeon_enemy?
    return NWConst::Common::LOSE_EVENT_BASE + self.id
  end
end
#==============================================================================
# ■ BattleManager
#==============================================================================
class << BattleManager
  #--------------------------------------------------------------------------
  # ● スキップ不能か 「トリス修正M」
  #--------------------------------------------------------------------------
  def no_lose_skip?
    enemy_id = $game_troop.lose_event_id - NWConst::Common::LOSE_EVENT_BASE
    return true if enemy_id == 0 # LOSE_EVENT_BASEを直接実行=混沌の迷宮エネミー
    return true if $data_enemies[enemy_id].no_lose_skip?
    return false
  end
end
#==============================================================================
# ■ Game_Library
#==============================================================================
class Game_Library
  #--------------------------------------------------------------------------
  # ● エネミーが撃破された回数カウントアップ
  #--------------------------------------------------------------------------
  def count_up_enemy_down(id)
    id -= 1000 if $data_enemies[id].ex_dungeon_enemy?
    @enemy_stat[id] ||= {}
    @enemy_stat[id][:down] ||= 0
    @enemy_stat[id][:down] += 1
  end
  #--------------------------------------------------------------------------
  # ● エネミーが勝利した回数カウントアップ
  #--------------------------------------------------------------------------
  def count_up_enemy_victory(id)
    id -= 1000 if $data_enemies[id].ex_dungeon_enemy?
    @enemy_stat[id] ||= {}
    @enemy_stat[id][:victory] ||= 0
    @enemy_stat[id][:victory] += 1
  end
  #--------------------------------------------------------------------------
  # ● エネミーがイかされた回数カウントアップ
  #--------------------------------------------------------------------------
  def count_up_enemy_orgasm(id)
    id -= 1000 if $data_enemies[id].ex_dungeon_enemy?
    @enemy_stat[id] ||= {}
    @enemy_stat[id][:orgasm] ||= 0
    @enemy_stat[id][:orgasm] += 1
  end
end

#==============================================================================
# ■ Window_BattleEnemy
#==============================================================================
class Window_BattleEnemy < Window_Selectable
  #--------------------------------------------------------------------------
  # ○ 項目の描画
  #--------------------------------------------------------------------------
  def draw_item(index)
    e = $game_troop.alive_members[index]
    name = e.name.clone
    name += "(友好度:#{e.enemy.ex_dungeon_enemy? ? "なし" : e.friend})" if @friend_draw
    change_color(normal_color, enable?(e))
    draw_text(item_rect_for_text(index), name)
  end 
end