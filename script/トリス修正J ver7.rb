
=begin

もんむす・くえすと！ＲＰＧ
　トリス修正J  ver7  2015/03/02



機能一覧　説明は下　このverで新規追加したものは●　変更したものは○
・ランダム発動の発動先スキルの①②③表示の前に、発動元スキルの①③表示
・スキル使用中の１度目のスキル発動でしか最終反撃しなかったのを修正
・最終反撃を死亡時スキルに近い仕様に
・反撃(拡張/通常)で「連続発動」と「スキル変化」が適用されていなかったのを修正
・ターン中に対象不在になった場合のエラーを修正
●イベントスクリプト「interrupt_skill(N)」でセリフとカットインを表示しないように
●直前に解除されたステートの <自己付与 ステート> が効かなかったのを修正

・ver1以降で順番発動スキルを使用した時のエラー修正
・「トリス修正B ver2」以降でルカ拘束中に入れ替えした時のエラー修正
・ver1以降で変数[スキル使用者ID,使用者レベル,スキルID]が無効になっていたのを修正


機能　説明
・ランダム発動の発動先スキルの①②③表示の前に、発動元スキルの①③表示
　①セリフとカットイン
　②スキル名（画面上部）
　③使用メッセージ
　ランダム発動スキルでは
　　発動元スキルの①を表示して決定キー待ち
　　発動元スキルの③を表示して40フレームのウェイト
　　発動先スキルの本来の処理
　という流れに


・スキル使用中の１度目のスキル発動でしか最終反撃しなかったのを修正
　・「拡張特徴 <連続発動タイプ> <連続発動スキル> による複数回の発動」
　・「スキル <順番発動> による複数個のスキルの発動」
　によって複数のスキル発動がある場合、最初のものでしか最終反撃しなかったのを修正


・最終反撃を死亡時スキルに近い仕様に
　・発動要因を「あらゆる要因での死亡」に
　・使用メッセージを「○○は倒れる間際に××で反撃した！」ではなく通常のものに
　・ゲームマスタースキルとして発動　これにより以下の２つの効果
　　・発動タイミングを「攻撃されたスキルの使用が終了した直後」に
　　・連続発動とスキル変化が行われていなかったのを修正

　現在、死亡時スキルとの違いは「回数が無制限」であることだけ


・ターン中に対象不在になった場合のエラーを修正
　行動直前に「行動対象が存在しなければ行動を消去」する機能が原因

　敵の行動（スキル）は「ターン開始時」に決定される
　例えばターン開始時に <対象：女> の攻撃スキルが選択されて、
　　その敵が行動するより前に「全ての女アクターが死亡」した場合、
　　その敵の行動時点では「対象不在」となり行動が消去される
　消去された行動を発動しようとすることでエラーになった

　これを修正し、行動が消去された場合、エラーにならず使用失敗とするようにした
　使用失敗メッセージ「(行動者名)は様子を見ている……」のみ表示し、
　　コスト消費と行動終了処理（HP等再生、行動終了時ステートの解除）は行わない

　他の要因での使用失敗（「しかしＭＰが足りない！」など）とは違い、
　　セリフとカットイン、スキル名は表示しない

　・この修正での注意点　メールに記載した内容と同じ
　　このエラーは「行動対象が存在しなければ行動を消去」する機能が原因です。
　　今回の修正によって、「これと同じ原因によって発生していたエラー」は
　　　全て「対象不在のため使用失敗」となりました。
　　しかしそれらが全て「予期している動作」になっているとは限りません。

　　例えば、最初に提示された「死亡時スキル」「誘惑」のエラーは
　　　これと同じ原因によるものです。
　　もし現在までこの２つのバグを修正していなければ、エラーが発生しなくなり、
　　　その代わりに使用失敗するようになっていたということです。

　　解決はせずに「エラーという分かりやすい形のバグ」ではなくなるため、
　　　バグに気付きにくくなるとも言えます。
　　「対象不在の使用失敗メッセージ」が表示された場合は、
　　　それが正しい動作かどうか注意してください。


●イベントスクリプト「interrupt_skill(N)」でセリフとカットインを表示しないように
　interrupt_skill(N, nil) とすると、以前のようにセリフとカットインを表示する


●直前に解除されたステートの <自己付与 ステート> が効かなかったのを修正
　バトラーは「今解除されたステート」という情報を持っている
　これに含まれるステートは、付加されることがない

　この情報は
　　①戦闘終了時（ステートの戦闘終了解除の直前）
　　②ターン終了時（ステートのターン経過＆自動解除の直前）
　　③行動した場合、その行動の終了時
　　④行動対象になった場合、その効果(ダメージ等)を適用される前　
　に消去される
　『１つのスキルを受ける時、付加と解除が両方行われることがない』という風に働く

　報告があった状況での、ステート自動解除とステート自己付与の流れは
　  A ターン3終了時　②「今解除されたステート」を消去
　　B ターン3終了時　ステート自動解除（解除した場合「今解除されたステート」に追加）
　　C ターン4 ステート自己付与スキルを使用　各対象への『④消去 と 効果適用』実行
　　D ターン4 ステート自己付与効果が適用され、使用者にステート付加
　　E ターン4 スキル終了時　③使用者の「今解除されたステート」を消去
　となる　Dの時点では「今解除されたステート」に含まれているため付加されない

　つまりこの不具合（ステートが付与されない）が起きる条件は
　　・「ターン経過の自動解除」か「自身の行動(③)以外による解除」で解除される
　　・その後、一度も「行動対象になる(④)、ターン終了する(②)」が発生しないまま
　　　「自身を対象とする(④)ものではないステート自己付与スキル」を使用する
　である

　これを修正し、ステート自己付与効果によるステート付加のみ
　　「今解除されたステート」に含まれていても付加されるようにした


ゲームマスタースキルの一覧
　拡張特徴 <戦闘開始時発動> <ターン開始時発動> <ターン終了時発動>
　　　　　 <死亡時スキル> <最終反撃>
　イベント interrupt_skill(skill_id)

=end

#==============================================================================
# ■ Scene_Battle
#==============================================================================
class Scene_Battle < Scene_Base
  #--------------------------------------------------------------------------
  # ● スキル用セリフ処理
  #--------------------------------------------------------------------------  
  def process_skill_word(item, action = nil)
    return if action and action.symbol == :event_interrupt
    return if $game_system.conf[:bt_skip] == true
    return unless item.is_skill?
    return unless @subject.exist_skill_word?(item.id)
    word = @subject.skill_word(item.id)
    word.execute
    wait_for_message
    return unless @subject.exist_cutin?(item.id)
    @subject.cutin(item.id).execute(method(:wait))
  end  
  #--------------------------------------------------------------------------
  # ● スキル名の表示
  #--------------------------------------------------------------------------      
  def display_skill_name(item, action = nil)
    return unless item.is_skill? && item.visible?
    $game_party.display_skill_name = item.name
  end
  #--------------------------------------------------------------------------
  # ○ スキルの決定処理 toris ベース/Scene 457
  #--------------------------------------------------------------------------
  def process_use_items(mode, base_action, item, can_failure)
    close_skill_name
    process_skill_word(item, base_action)
    if can_failure and process_skill_unusable(item, false)
      display_skill_name(item)
      process_skill_unusable(item, true)
      wait(40)
      return :unusable
    end
    display_use_item(base_action, item)
    case mode
    when :slot  ; result_skill_id = process_slot
    when :poker ; result_skill_id = process_poker
    when :random; result_skill_id = item.random_invoke.sample; wait(40)
    end
    @log_window.clear
    return $data_skills[result_skill_id]
  end
  #--------------------------------------------------------------------------
  # ○ スキル／アイテムの使用メッセージ表示 ベース/Scene 537
  #--------------------------------------------------------------------------
  def display_use_item(action, display_item)
    display_action = Game_Action.new(@subject)
    display_action.send(display_item.is_skill? ? :set_skill : :set_item, display_item.id)
    display_action.target_index = action.target_index
    display_targets = display_action.make_targets.compact
    @log_window.display_use_item(@subject, display_targets, display_item)
  end
  #--------------------------------------------------------------------------
  # ○ スキル発動不可能の処理 toris ベース/Scene 457
  #--------------------------------------------------------------------------
  def process_skill_unusable(base_item, display_flag)
    if @subject.skill_unusable?(base_item)
      display_skill_unusable(base_item) if display_flag
      return true
    elsif @subject.eternal_bind_resist?(base_item)
      display_eternal_bind_resist if display_flag
      return true
    end
    return false
  end
  #--------------------------------------------------------------------------
  # ○ スキル／アイテムの使用 ベース/Scene 457
  #--------------------------------------------------------------------------
  def use_item
    # 「変数拡張」
    $game_temp.action_user   = @subject
    $game_temp.used_skill    = @subject.current_action.item
    # 「変数拡張」
    base_item = @subject.current_action.item
    if base_item.nil?
      @log_window.display_target_empty(@subject)
      return true
    end
    use_items = @subject.current_action.use_items(true)
    display_item = use_items.size == 1 ? use_items[0] : base_item
    # 使用直前失敗判定
    if [:slot, :poker, :random].include?(base_item.use_items_mode)
      return true if display_item == :unusable
    end
    # 【スキル名表示】
    process_skill_word(display_item, @subject.current_action)
    display_skill_name(display_item)
    # 使用直前失敗判定
    if [:multi, :normal].include?(base_item.use_items_mode)
      return true if process_skill_unusable(base_item, true)
    end
    # アイテムの使用
    @subject.use_item(base_item)
    refresh_status    
    # 使用直後メッセージ
    display_use_item(@subject.current_action, display_item)
    # 効果の発動
    process_invoke_item(@subject.current_action, use_items)
    close_skill_name
    apply_user_feedback(@subject.master_observer, base_item)
  end
  #--------------------------------------------------------------------------
  # ○ スキル／アイテムの対象への効果適用 ベース/Scene 485
  #--------------------------------------------------------------------------
  def process_invoke_item(base_action, first_use_items)
    enable_counter = true
    base_item = base_action.item
    @subject.invoke_repeats(base_item).times do |repeat_time|
      break unless @subject.current_action
      use_items = (repeat_time == 0 ? first_use_items : base_action.use_items(false))
      display_item = use_items.size == 1 ? use_items[0] : base_item
      if repeat_time != 0
        process_skill_word(display_item, base_action)
      end
      use_items.each_with_index do |item, item_time|
        break unless @subject.current_action
        if repeat_time != 0 or item_time != 0 # 反撃スキルから戻す
          display_skill_name(display_item)
          display_use_item(base_action, display_item)
        end
        enable_invoke = true
        action = Game_Action.new(@subject)
        action.send(item.is_skill? ? :set_skill : :set_item, item.id)
        action.target_index = base_action.target_index
        targets = action.make_targets.compact
        show_animation(targets, item.animation_id)
        show_animation(targets, item.add_anime) if item.add_anime > 0
        if enable_counter                     # 拡張反撃
          targets.uniq.each {|target|
            if target.alive? && rand < target.item_cnt_ex(@subject, item)
              invoke_counter_attack(target, item)
              enable_invoke = false           # スキル発動と通常反撃を無効
              break                           # 以降の先手反撃を無効
            end
          }
        end
        if enable_invoke                      # 効果の発動
          targets.each {|target| item.repeats.times { invoke_item(target, item) } }
          item.effects.each {|effect| item_user_effect_apply(@subject, item, effect) }
        end
        if enable_invoke and enable_counter   # 通常反撃
          targets.uniq.each {|target|
            if target.alive? && rand < target.item_cnt(@subject, item)
              invoke_counter_attack(target, item)
            end
          }
        end
        enable_counter = false  # 反撃できるのは最初の回の最初のスキルのみ
        @log_window.clear
      end # use_items.each
      @log_window.clear  # 2行上のclearはbreakによって無視される可能性がある
      break if $game_troop.all_dead?
    end # invoke_repeats.times
  end
  #--------------------------------------------------------------------------
  # ○ 反撃の発動 ベース/Scene 702
  #--------------------------------------------------------------------------
  def invoke_counter_attack(target, item)
    @log_window.clear
    @subject, target = target, @subject
    base_item = $data_skills[@subject.counter_skill ? @subject.counter_skill : @subject.attack_skill_id]
    @subject.skill_interrupt(base_item.id)
    @subject.invoke_repeats(base_item).times do |repeat_time|
      use_items = @subject.current_action.use_items(false)
      display_item = use_items.size == 1 ? use_items[0] : base_item
      process_skill_word(display_item)
      display_skill_name(display_item)
      @log_window.display_counter(@subject, display_item)
      use_items.each do |attack_skill|
        show_animation([target], attack_skill.animation_id)
        apply_item_effects(apply_substitute(target, attack_skill), attack_skill)
      end
      @log_window.clear
    end
    refresh_status
    @subject.remove_current_action
    @subject, target = target, @subject
  end
end

#==============================================================================
# ■ Game_Action
#==============================================================================
class Game_Action
  #--------------------------------------------------------------------------
  # ● 公開インスタンス変数 toris ベース/GameObject 122
  #--------------------------------------------------------------------------
  attr_reader  :symbol
  #--------------------------------------------------------------------------
  # ● 使用アイテム配列の取得 ベース/GameObject 185
  #--------------------------------------------------------------------------
  def use_items(can_failure)
    mode = item.use_items_mode
    case mode
    when :multi ; return item.multi_invoke.collect {|id| $data_skills[id] }
    when :normal; return [item]
    else        ; return [SceneManager.scene.process_use_items(mode, self, item, can_failure)]
    end
  end
  #--------------------------------------------------------------------------
  # ○ ランダムターゲット ベース/GameObject 195
  #--------------------------------------------------------------------------
  def decide_random_target
    target = make_random_target
    if target
      @target_index = target.index
    else
      return if @symbol == :dead_skill
      return if @symbol == :final_invoke
      return if !forcing && subject.temptation?
      clear
    end
  end
  #--------------------------------------------------------------------------
  # ○ ランダムターゲット toris ベース/GameObject 195
  #--------------------------------------------------------------------------
  def make_random_target
    if item.for_dead_friend?
      target = friends_unit.random_dead_target_ex(item.ext_scope)
    elsif item.for_friend?
      target = friends_unit.random_target_ex(item.ext_scope)
    else
      target = opponents_unit.random_target_ex(item.ext_scope)
    end
    return target
  end
end
#==============================================================================
# ■ RPG::UsableItem
#==============================================================================
class RPG::UsableItem < RPG::BaseItem
  #--------------------------------------------------------------------------
  # ● 使用アイテム決定の種類 toris ベース/DataObject 590
  #--------------------------------------------------------------------------
  def use_items_mode
    return :slot   if use_slot?
    return :poker  if use_poker?
    return :random if random_invoke
    return :multi  if multi_invoke
    return :normal
  end
end

#==============================================================================
# ■ Window_BattleLog
#==============================================================================
class Window_BattleLog < Window_Selectable
  #--------------------------------------------------------------------------
  # ● 反撃の表示 toris ベース/Window 886
  #--------------------------------------------------------------------------
  def display_counter(target, item)
    Sound.play_evasion
    add_text(sprintf(Vocab::CounterAttack, target.name))
    wait
  end
  #--------------------------------------------------------------------------
  # ● スキル対象不在の表示 toris ベース/Window 791
  #--------------------------------------------------------------------------
  def display_target_empty(subject)
    add_text("#{subject.name}は様子を見ている……")
    wait_and_clear
  end
end

#==============================================================================
# ■ Game_BattlerBase
#==============================================================================
class Game_BattlerBase
  #--------------------------------------------------------------------------
  # ○ スキル使用コストの支払い可能判定 ベース/GameObject 1055
  #--------------------------------------------------------------------------
  def skill_cost_payable?(skill)
    tp >= skill_tp_cost(skill) &&
    mp >= skill_mp_cost(skill) &&
    hp > skill_hp_cost(skill) &&
    $game_party.gold >= skill_gold_cost(skill) &&
    skill_need_item?(skill)  
  end
  #--------------------------------------------------------------------------
  # ○ スキルの使用可能条件チェック ベース/GameObject 1064
  #--------------------------------------------------------------------------
  def skill_conditions_met?(skill)
    usable_item_conditions_met?(skill) &&
    skill_wtype_ok?(skill) &&
    skill_cost_payable?(skill) &&
    !skill_sealed?(skill.id) &&
    !skill.stypes.all?{|stype_id| skill_type_sealed?(stype_id)} &&
    skill_need_dual_wield?(skill) &&
    !(temptation? && !$game_actors[NWConst::Actor::LUCA].alive?)
  end
end

#==============================================================================
# ■ Game_Battler
#==============================================================================
class Game_Battler < Game_BattlerBase  
  #--------------------------------------------------------------------------
  # ● ゲームマスターならばオブザーバーを返す toris
  #--------------------------------------------------------------------------
  def master_observer
    return game_master? ? @observer : self
  end
  #--------------------------------------------------------------------------
  # ○ 戦闘不能になる ベース/GameObject 1663
  #--------------------------------------------------------------------------
  def die
    if $game_party.in_battle && !@cnt[:dead_skill].empty?
      BattleManager.skill_interrupt(self, @cnt[:dead_skill].pop, :dead_skill)
    end
    if $game_party.in_battle && final_invoke
      BattleManager.skill_interrupt(self, final_invoke, :final_invoke)
    end
    @hp = 0
    clear_states
    clear_buffs
    BattleManager.bind_refresh if $game_party.in_battle # もしくはclear_statesで
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
    
    wait(6)
    result_skill_id = 1
    CasinoManager.bet_num.times do |i|
      $game_slot.check_bonus(NWConst::Slot::LINES[i])
      if result_skill_id < $game_slot.result_skill_id
        result_skill_id = $game_slot.result_skill_id
        @battleslot_bonus_window.select_key = $game_slot.result_bonus
        slot_spriteset.set_line_number(i)
      end
    end
    wait(60)
    
    slot_spriteset.dispose
    @battleslot_bonus_window.dispose
    remove_instance_variable(:@battleslot_bonus_window)
    
    return result_skill_id
  end
end
#==============================================================================
# ■ Scene_Battle
#==============================================================================
class Scene_Battle < Scene_Base
  #--------------------------------------------------------------------------
  # ● ポーカーの処理 娯楽/ポーカー改造 532
  #--------------------------------------------------------------------------
  def process_poker
    @battlepoker_help_window = Window_BattlePokerHelp.new
    @battlepoker_help_window.y = 0
    @battlepoker_hands_window = Window_BattlePokerHands.new
    @battlepoker_hands_window.y = @battlepoker_help_window.height
    viewport = Viewport.new
    viewport.rect.y = @battlepoker_hands_window.y +
                      @battlepoker_hands_window.height - 48
    viewport.rect.height -= viewport.rect.y + @battlepoker_help_window.height
    @battlepoker_spriteset = Spriteset_PokerTrump.new(viewport)
    @battlepoker_spriteset.set_handler(:cancel, method(:battlepoker_change_card))
    
    @battlepoker_hand = CAO::Poker::Hand.new
    @battlepoker_spriteset.deal(@battlepoker_hand)
    @battlepoker_spriteset.open
    @battlepoker_spriteset.select(0)
    @battlepoker_spriteset.activate
    
    while @battlepoker_spriteset.active
      update_basic
      @battlepoker_spriteset.update
    end
    @battlepoker_hands_window.index == 0 ? Sound.play_battlepoker_lose :
                                           Sound.play_battlepoker_win
    60.times do
      update_basic
      @battlepoker_spriteset.update
    end
    
    result_skill_id = CAO::Poker::BATTLE_SKILL[@battlepoker_hands_window.index]
    
    @battlepoker_hands_window.dispose
    @battlepoker_help_window.dispose
    @battlepoker_spriteset.dispose
    remove_instance_variable(:@battlepoker_hands_window)
    remove_instance_variable(:@battlepoker_help_window)
    remove_instance_variable(:@battlepoker_spriteset)
    remove_instance_variable(:@battlepoker_hand)
    
    return result_skill_id
  end
end

#==============================================================================
# ■ Window_BattleStatus
#==============================================================================
class Window_BattleStatus < Window_Selectable
  #--------------------------------------------------------------------------
  # ● 選択項目の有効状態を取得 ベース/Window 1098
  #--------------------------------------------------------------------------
  def current_item_enabled?
    !(BattleManager.shift_change? && BattleManager.bind? && $game_party.all_members[member_index].luca?)
  end
end

#==============================================================================
# ■ Game_Interpreter
#==============================================================================
class Game_Interpreter
  #--------------------------------------------------------------------------
  # ● 現在行動者にスキル割り込み
  #--------------------------------------------------------------------------  
  def interrupt_skill(skill_id, symbol = :event_interrupt)
    battler = $game_actors[v(NWConst::Var::ACTION_USER)]
    return if !$game_party.in_battle || $data_skills[skill_id].nil? || battler.nil?
    BattleManager.skill_interrupt(battler, skill_id, symbol)
  end
end
#==============================================================================
# ■ Scene_Battle
#==============================================================================
class Scene_Battle < Scene_Base
  #--------------------------------------------------------------------------
  # ● 使用効果［自己ステート付与］
  #--------------------------------------------------------------------------
  def item_user_effect_self_enchant(user, item, effect)
    chance = effect.value1
    chance *= user.state_rate(effect.data_id) unless effect.value2
    if rand < chance
      user.result.removed_states.delete(effect.data_id)
      user.add_state(effect.data_id)
      if user.state_addable?(effect.data_id)
        @log_window.display_user_self_enchant(user, effect.data_id)
      end
    end
  end
end