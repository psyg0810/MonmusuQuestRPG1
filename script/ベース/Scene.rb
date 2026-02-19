=begin
=ベース/Scene

ここではSceneを中心に扱います


==更新履歴
  Date     Version Author Comment
==14/12/13 2.0.0   トリス 統合A～E A B
==14/12/19 2.0.1   トリス 統合F～I F G

=end

#==============================================================================
# ■ Scene_Base
#==============================================================================
class Scene_Base
  #--------------------------------------------------------------------------
  # ○ フレーム更新（基本）
  #--------------------------------------------------------------------------
  def update_basic
    Graphics.update
    Audio.update 
    Input.update
    update_all_windows
  end
end

#==============================================================================
# ■ Scene_Map
#==============================================================================
class Scene_Map < Scene_Base
  #--------------------------------------------------------------------------
  # ○ 全ウィンドウの作成
  #--------------------------------------------------------------------------
  def create_all_windows
    create_message_window
    create_scroll_text_window
    create_location_window
    create_simple_status_window
    create_gain_medal_window
    create_skillname_window
  end
  #--------------------------------------------------------------------------
  # ● 簡易ステータスウィンドウの作成
  #--------------------------------------------------------------------------
  def create_simple_status_window
    @simple_status_window = Window_SimpleStatus.new($game_actors[NWConst::Actor::LUCA])
    @simple_status_window.openness = 0
  end
  #--------------------------------------------------------------------------
  # ● スキル名ウィンドウの作成
  #--------------------------------------------------------------------------
  def create_skillname_window
    @sname_window = Window_SkillName.new
  end
  #--------------------------------------------------------------------------
  # ● 獲得メダルウィンドウの作成
  #--------------------------------------------------------------------------
  def create_gain_medal_window
    @gain_medal_window = Window_GainMedal.new
  end
end


#==============================================================================
# ■ Scene_Menu
#==============================================================================
class Scene_Menu < Scene_MenuBase
  #--------------------------------------------------------------------------
  # ○ コマンドウィンドウの作成
  #--------------------------------------------------------------------------
  def create_command_window
    @command_window = Window_MenuCommand.new
    @command_window.set_handler(:item,      method(:command_item))
    @command_window.set_handler(:skill,     method(:command_personal))
    @command_window.set_handler(:equip,     method(:command_personal))
    @command_window.set_handler(:status,    method(:command_personal))
    @command_window.set_handler(:formation, method(:command_formation))
    @command_window.set_handler(:save,      method(:command_save))
    @command_window.set_handler(:game_end,  method(:command_game_end))
    @command_window.set_handler(:cancel,    method(:return_scene))
    @command_window.set_handler(:ability, method(:command_personal))
  end  
  #--------------------------------------------------------------------------
  # ○ コマンド［スキル］［装備］［ステータス］
  #--------------------------------------------------------------------------
  def command_personal
    @status_window.select(0)
    @status_window.activate
    @status_window.set_handler(:ok,     method(:on_personal_ok))
    @status_window.set_handler(:cancel, method(:on_personal_cancel))
  end
  #--------------------------------------------------------------------------
  # ○ 個人コマンド［決定］
  #--------------------------------------------------------------------------
  def on_personal_ok
    Sound.play_ok
    case @command_window.current_symbol
    when :skill
      SceneManager.call(Scene_Skill)
    when :equip
      SceneManager.call(Scene_Equip)
    when :status
      SceneManager.call(Scene_Status)
    when :ability
      SceneManager.call(Scene_Ability)
    end
  end
  #--------------------------------------------------------------------------
  # ○ 並び替え［決定］
  #--------------------------------------------------------------------------
  def on_formation_ok
    if @status_window.pending_index >= 0
      Sound.play_ok
      $game_party.swap_order(@status_window.index, @status_window.pending_index)
      @status_window.pending_index = -1
      @status_window.redraw_item(@status_window.index)
    else
      Sound.play_ok
      @status_window.pending_index = @status_window.index
    end
    @status_window.activate
  end
  #--------------------------------------------------------------------------
  # ○ 並び替え［キャンセル］
  #--------------------------------------------------------------------------
  def on_formation_cancel
    Sound.play_cancel
    if @status_window.pending_index >= 0
      @status_window.pending_index = -1
      @status_window.activate
    else
      @status_window.unselect
      @command_window.activate
    end
  end  
end

#==============================================================================
# ■ Scene_Battle
#==============================================================================
class Scene_Battle < Scene_Base
  #--------------------------------------------------------------------------
  # ○ 開始後処理
  #--------------------------------------------------------------------------
  def post_start
    super
    unless $game_party.in_battle
      battle_start
    else
      start_party_command_selection
    end
  end
  #--------------------------------------------------------------------------
  # ○ 全ウィンドウの作成
  #--------------------------------------------------------------------------
  def create_all_windows
    create_message_window
    create_scroll_text_window
    create_log_window
    create_status_window
    create_bench_window #
    create_info_viewport
    create_party_command_window
    create_actor_command_window
    create_help_window
    create_skill_window
    create_item_window
    create_actor_window
    create_enemy_window
    create_simple_status_window #
    create_skillname_window #
  end
  #--------------------------------------------------------------------------
  # ○ ログウィンドウの作成
  #--------------------------------------------------------------------------
  def create_log_window
    @log_window = Window_BattleLog.new
    @log_window.method_wait = method(:wait)
    @log_window.method_wait_for_effect = method(:wait_for_effect)
    @log_window.method_process_down_word = method(:process_down_word)
  end
  #--------------------------------------------------------------------------
  # ○ ステータスウィンドウの作成
  #--------------------------------------------------------------------------
  def create_status_window
    @status_window = Window_BattleStatus.new
    @status_window.x = 200
    @status_window.set_handler(:ok,  method(:battle_member_ok))
    @status_window.set_handler(:cancel,  method(:battle_member_cancel))
  end
  #--------------------------------------------------------------------------
  # ○ 控えメンバーウィンドウの作成
  #--------------------------------------------------------------------------
  def create_bench_window
    @bench_window  = Window_BenchStatus.new
    @bench_window.x = 200
    @bench_window.y = @status_window.height
    @bench_window.set_handler(:ok,  method(:bench_member_ok))
    @bench_window.set_handler(:cancel,  method(:bench_member_cancel))
  end
  #--------------------------------------------------------------------------
  # ○ 情報表示ビューポートの作成
  #--------------------------------------------------------------------------
  def create_info_viewport
    @info_viewport = Viewport.new
    @info_viewport.rect.y = Graphics.height - @status_window.height
    @info_viewport.rect.height = @status_window.height + @bench_window.height
    @info_viewport.z = 100
    @info_viewport.ox = 64
    @info_viewport.visible = false
    @status_window.viewport = @info_viewport
    @bench_window.viewport = @info_viewport
  end
  #--------------------------------------------------------------------------
  # ○ パーティコマンドウィンドウの作成
  #--------------------------------------------------------------------------
  def create_party_command_window
    @party_command_window = Window_PartyCommand.new
    @party_command_window.viewport = @info_viewport
    @party_command_window.set_handler(:fight,  method(:command_fight))
    @party_command_window.set_handler(:escape, method(:command_escape))
    @party_command_window.set_handler(:shift_change, method(:command_shift_change))
    @party_command_window.set_handler(:giveup, method(:command_giveup))
    @party_command_window.set_handler(:library, method(:command_library))
    @party_command_window.set_handler(:config, method(:command_config))
    @party_command_window.unselect    
  end
  #--------------------------------------------------------------------------
  # ○ アクターコマンドウィンドウの作成
  #--------------------------------------------------------------------------
  def create_actor_command_window
    @actor_command_window = Window_ActorCommand.new
    @actor_command_window.viewport = @info_viewport
    @actor_command_window.set_handler(:attack, method(:command_attack))
    @actor_command_window.set_handler(:skill,  method(:command_skill))
    @actor_command_window.set_handler(:guard,  method(:command_guard))
    @actor_command_window.set_handler(:item,   method(:command_item))
    @actor_command_window.set_handler(:cancel, method(:prior_command))
    @actor_command_window.set_handler(:bind_resist, method(:command_bind_resist))
    @actor_command_window.set_handler(:mercy, method(:command_mercy))
    @actor_command_window.x = Graphics.width
  end
  #--------------------------------------------------------------------------
  # ● 簡易ステータスウィンドウの作成
  #--------------------------------------------------------------------------
  def create_simple_status_window
    @simple_status_window = Window_SimpleStatus.new($game_actors[NWConst::Actor::LUCA])
    @simple_status_window.openness = 0
  end
  #--------------------------------------------------------------------------
  # ● スキル名ウィンドウの作成
  #--------------------------------------------------------------------------
  def create_skillname_window
    @sname_window = Window_SkillName.new
  end
  #--------------------------------------------------------------------------
  # ○ ステータスウィンドウの情報を更新
  #--------------------------------------------------------------------------
  def refresh_status
    @status_window.refresh
    @bench_window.refresh
  end
  #--------------------------------------------------------------------------
  # ○ 情報表示ビューポートの更新
  #--------------------------------------------------------------------------
  def update_info_viewport
    if @party_command_window.active
      move_info_viewport(0)
      move_info_viewport2(360)
    elsif @actor_command_window.active
      move_info_viewport(200)
      move_info_viewport2(360)
    elsif @bench_window.open?
      move_info_viewport(0)
      move_info_viewport2(240)
    elsif BattleManager.in_turn?
      move_info_viewport(100)
      move_info_viewport2(360)
    end
  end
  #--------------------------------------------------------------------------
  # ● 情報表示ビューポートの移動（絶対座標）
  #--------------------------------------------------------------------------
  def move_info_viewport2(y)
    pos_y = @info_viewport.rect.y
    @info_viewport.rect.y = [y, pos_y + 16].min if pos_y < y
    @info_viewport.rect.y = [y, pos_y - 16].max if pos_y > y
  end
  #--------------------------------------------------------------------------
  # ○ パーティコマンド選択の開始
  #--------------------------------------------------------------------------
  def start_party_command_selection
    unless scene_changing?
      refresh_status
      @info_viewport.visible = true
      @status_window.unselect
      @status_window.open
      if BattleManager.input_start
        @actor_command_window.close
        @party_command_window.setup
      else
        @party_command_window.deactivate
        turn_start
      end
    end
  end
  #--------------------------------------------------------------------------
  # ○ コマンド［逃げる］
  #--------------------------------------------------------------------------
  def command_escape
    @info_viewport.visible = false
    turn_start unless BattleManager.process_escape
  end
  #--------------------------------------------------------------------------
  # ● コマンド［入れ替え］
  #--------------------------------------------------------------------------
  def command_shift_change
    BattleManager.shift_change
    refresh_status
    @bench_window.open
    @status_window.activate.select(0)
  end
  #--------------------------------------------------------------------------
  # ● 戦闘参加メンバー：決定
  #--------------------------------------------------------------------------
  def battle_member_ok
    @bench_window.activate.select(0)
  end
  #--------------------------------------------------------------------------
  # ● 戦闘参加メンバー：キャンセル
  #--------------------------------------------------------------------------
  def battle_member_cancel
    @status_window.unselect
    @bench_window.close
    BattleManager.init_phase
    refresh_status
    start_party_command_selection
  end
  #--------------------------------------------------------------------------
  # ● 控えメンバー：決定
  #--------------------------------------------------------------------------
  def bench_member_ok
    $game_party.sort_hidden_last
    $game_party.swap_order(@status_window.member_index, @bench_window.member_index)
    refresh_status
    bench_member_cancel
  end
  #--------------------------------------------------------------------------
  # ● 控えメンバー：キャンセル
  #--------------------------------------------------------------------------
  def bench_member_cancel
    @status_window.activate
    @bench_window.unselect
  end  
  #--------------------------------------------------------------------------
  # ● コマンド［降参］
  #--------------------------------------------------------------------------
  def command_giveup
    @info_viewport.visible = false
    BattleManager.giveup
    $game_temp.reserve_common_event(NWConst::Common::GIVEUP_START)
    process_event
    turn_start
  end
  #--------------------------------------------------------------------------
  # ○ 戦闘開始
  #--------------------------------------------------------------------------
  def battle_start
    BattleManager.battle_start
    process_event
    BattleManager.set_battle_start_skill
    process_action while BattleManager.gm_exist?
    start_party_command_selection
  end
  #--------------------------------------------------------------------------
  # ○ ターン開始
  #--------------------------------------------------------------------------
  def turn_start
    @info_viewport.visible = false
    @party_command_window.close
    @actor_command_window.close
    @status_window.unselect
    @subject =  nil
    BattleManager.turn_start
    @log_window.wait
    @log_window.clear
    BattleManager.set_turn_start_skill
    process_action while BattleManager.gm_exist?
  end
  #--------------------------------------------------------------------------
  # ○ コマンド［攻撃］
  #--------------------------------------------------------------------------
  def command_attack
    BattleManager.actor.input.set_attack
    if BattleManager.actor.bind_target?
      BattleManager.actor.input.target_index = BattleManager.bind_user_index
      next_command
    elsif BattleManager.actor.input.item.need_selection?
      select_enemy_selection
    else
      next_command
    end
  end
  #--------------------------------------------------------------------------
  # ○ コマンド［アイテム］
  #--------------------------------------------------------------------------
  def command_item
    @item_window.actor = BattleManager.actor
    @item_window.refresh
    @item_window.show.activate
  end  
  #--------------------------------------------------------------------------
  # ○ 敵キャラ選択の開始
  #--------------------------------------------------------------------------
  def select_enemy_selection
    skill = @skill_window.visible ? @skill_window.item : nil
    @enemy_window.friend_draw = skill ? skill.friend_draw? : false
    @enemy_window.refresh
    @enemy_window.show.activate
  end
  #--------------------------------------------------------------------------
  # ● コマンド［もがく］
  #--------------------------------------------------------------------------
  def command_bind_resist
    BattleManager.actor.input.target_index = BattleManager.bind_user_index
    BattleManager.actor.input.set_bind_resist
    next_command
  end
  #--------------------------------------------------------------------------
  # ● コマンド［なすがまま］
  #--------------------------------------------------------------------------
  def command_mercy
    BattleManager.actor.input.set_mercy
    next_command
  end
  #--------------------------------------------------------------------------
  # ○ 戦闘行動の処理
  #--------------------------------------------------------------------------
  def process_action
    return if scene_changing?
    if !@subject || !@subject.current_action
      @subject = BattleManager.next_subject
    end
    return turn_end unless @subject
    if @subject.current_action
      @subject.current_action.prepare
      execute_action
      @subject.remove_current_action
    end
    process_action_end unless @subject.current_action
  end
  #--------------------------------------------------------------------------
  # ○ スキル／アイテムの使用
  #--------------------------------------------------------------------------
  def use_item
    base_item = @subject.current_action.item
    use_items = @subject.current_action.use_items
    display_item = use_items.size == 1 ? use_items[0] : base_item
    # 【スキル名表示】
    process_skill_word(display_item)
    display_skill_name(display_item)
    # 使用直前失敗判定
    if @subject.skill_unusable?(base_item)
      display_skill_unusable(base_item)
      return true
    elsif @subject.eternal_bind_resist?(base_item)
      display_eternal_bind_resist
      return true
    end    
    # アイテムの使用
    @subject.use_item(base_item)
    refresh_status    
    # 使用直後メッセージ
    display_use_item(@subject.current_action, display_item)
    # 効果の発動
    process_invoke_item(@subject.current_action, use_items)
    close_skill_name
    apply_user_feedback(@subject, base_item)
  end
  #--------------------------------------------------------------------------
  # ○ スキル／アイテムの対象への効果適用
  #--------------------------------------------------------------------------
  def process_invoke_item(base_action, first_use_items)
    enable_counter = true
    base_item = base_action.item
    @subject.invoke_repeats(base_item).times{|repeat_time|
      break unless @subject.current_action
      use_items = (repeat_time == 0 ? first_use_items : base_action.use_items)
      display_item = use_items.size == 1 ? use_items[0] : base_item
      if repeat_time != 0
        process_skill_word(display_item)
        display_use_item(@subject.current_action, display_item)
      end
      use_items.each{|item|
        break unless @subject.current_action
        enable_invoke = true
        action = Game_Action.new(@subject)
        action.send(item.is_skill? ? :set_skill : :set_item, item.id)
        action.target_index = @subject.current_action.target_index
        targets = action.make_targets.compact
        show_animation(targets, item.animation_id)
        show_animation(targets, item.add_anime) if item.add_anime > 0
        if enable_counter                     # 先手反撃
          targets.uniq.each {|target|
            if target.alive? && rand < target.item_cnt_ex(@subject, item)
              invoke_counter_attack(target, item)
              enable_invoke = false           # スキル発動と後手反撃を無効
              break                           # 以降の先手反撃を無効
            end
          }
        end
        if enable_invoke                      # 効果の発動
          targets.each {|target| item.repeats.times{invoke_item(target, item)}}
          item.effects.each {|effect| item_user_effect_apply(@subject, item, effect) }
        end
        if enable_invoke and enable_counter   # 後手反撃
          targets.uniq.each {|target|        
            if target.alive? && rand < target.item_cnt(@subject, item)
              invoke_counter_attack(target, item)
            elsif target.dead? && target.final_invoke
              invoke_final_skill(target, item)
            end
          }
        end
        enable_counter = false  # 反撃できるのは最初の回の最初のスキルのみ
        display_skill_name(display_item) # 反撃スキル名から戻す
      } # use_items.each
      @log_window.clear
      break if $game_troop.all_dead?
    } # invoke_repeats.times
  end
  #--------------------------------------------------------------------------
  # ○ スキル／アイテムの使用メッセージ表示
  #--------------------------------------------------------------------------
  def display_use_item(action, display_item)
    display_action = Game_Action.new(@subject)
    display_action.send(display_item.is_skill? ? :set_skill : :set_item, display_item.id)
    display_action.target_index = action.target_index
    display_targets = display_action.make_targets.compact
    @log_window.display_use_item(@subject, display_targets, display_item)
  end
  #--------------------------------------------------------------------------
  # ● 対象に関係なく適用される使用効果の適用
  #--------------------------------------------------------------------------
  def item_user_effect_apply(user, item, effect)
    user = user.observer if user.is_a?(Game_Master)
    method_table = {
      NWUsableEffect::EFFECT_GET_ITEM     => :item_user_effect_get_item,
      NWUsableEffect::EFFECT_SELF_ENCHANT => :item_user_effect_self_enchant,
    }
    method_name = method_table[effect.code]
    send(method_name, user, item, effect) if method_name
  end
  #--------------------------------------------------------------------------
  # ● 使用効果［アイテム獲得］
  #--------------------------------------------------------------------------
  def item_user_effect_get_item(user, item, effect)
    return unless user.actor?
    effect.data_id.times{|i|
      $game_party.gain_item($data_items[effect.value1[i]], effect.value2[i])
    }
  end
  #--------------------------------------------------------------------------
  # ● 使用効果［自己ステート付与］
  #--------------------------------------------------------------------------
  def item_user_effect_self_enchant(user, item, effect)
    chance = effect.value1
    chance *= user.state_rate(effect.data_id) unless effect.value2
    if rand < chance
      user.add_state(effect.data_id)
      if user.state_addable?(effect.data_id)
        @log_window.display_user_self_enchant(user, effect.data_id)
      end
    end
  end
  #--------------------------------------------------------------------------
  # ● スキル使用失敗の表示
  #--------------------------------------------------------------------------
  def display_skill_unusable(item)
    @log_window.display_unusable(@subject, item)
    close_skill_name    
  end
  #--------------------------------------------------------------------------
  # ● 永久拘束抵抗の表示
  #--------------------------------------------------------------------------
  def display_eternal_bind_resist
    bind_user = $game_troop.members[@subject.current_action.target_index]
    @log_window.display_eternal_bind_resist(bind_user)
    close_skill_name    
  end  
  #--------------------------------------------------------------------------
  # ○ スキル／アイテムの発動
  #--------------------------------------------------------------------------
  def invoke_item(target, item)
    return unless @subject.alive?

    if target.alive? && rand < target.item_mrf(@subject, item)
      invoke_magic_reflection(target, item)
    else
      apply_item_effects(apply_substitute(target, item), item)
    end
    @subject.last_target_index = target.index
  end
  #--------------------------------------------------------------------------
  # ● 使用者のフィードバックの適用
  #--------------------------------------------------------------------------
  def apply_user_feedback(user, item)
    if item.pay_life?
      if user.own_crush_resist?
        user.hp = 1
        @log_window.display_pay_life_failure(user)
      else
        user.add_state(user.death_state_id)
        @log_window.display_pay_life(user)
      end
    end
  end
  #--------------------------------------------------------------------------
  # ○ スキル／アイテムの効果を適用
  #--------------------------------------------------------------------------
  def apply_item_effects(target, item)
    target = target.observer if target.is_a?(Game_Master)
    target.item_apply(@subject, item)
    refresh_status
    @log_window.display_action_results(target, item, @subject)
  end
  #--------------------------------------------------------------------------
  # ● 被ダメージ用セリフ処理
  #--------------------------------------------------------------------------  
  def process_down_word(target, item)
    return if $game_system.conf[:bt_skip] == true
    return unless target.down_word_hash
    abs_wait_short
    if target.result.added_state_objects.any?{|state| state.death?}
      if target.result.predation
        target.predation_word.execute if target.predation_word        
      elsif target.result.pleasure
        target.orgasm_word.execute if target.orgasm_word
        process_luca_orgasm if target.luca?
      else
        target.dead_word.execute if target.dead_word        
      end
      target.premortal_change
    elsif target.result.added_states.include?(NWConst::State::INCONTINENCE)
      target.incontinence_word.execute if target.incontinence_word
    end
    wait_for_message
  end
  #--------------------------------------------------------------------------
  # ● ルカの射精演出処理
  #--------------------------------------------------------------------------  
  def process_luca_orgasm
    wait_for_message
    $game_troop.screen.pictures[10].show("sys_white", 0, 0, 0, 100, 100, 0, 0)
    $game_troop.screen.pictures[10].move(0, 0, 0, 100, 100, 255, 0, 20)
    wait(20)
    RPG::SE.new("mon_syasei", 100, 100).play
    $game_troop.screen.pictures[10].move(0, 0, 0, 100, 100, 0, 0, 25)
    wait(25)
    $game_troop.screen.pictures[10].move(0, 0, 0, 100, 100, 255, 0, 20)
    wait(20)
    $game_troop.screen.pictures[10].move(0, 0, 0, 100, 100, 0, 0, 25)
    wait(25)
    $game_troop.screen.pictures[10].move(0, 0, 0, 100, 100, 255, 0, 6)
    wait(6)
    $game_troop.screen.pictures[10].move(0, 0, 0, 100, 100, 0, 0, 60)
    wait(60)
    $game_troop.screen.pictures[10].erase
  end  
  #--------------------------------------------------------------------------
  # ● スキル用セリフ処理
  #--------------------------------------------------------------------------  
  def process_skill_word(item)
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
  def display_skill_name(item)
    return unless item.is_skill? && item.visible?
    $game_party.display_skill_name = item.name
  end
  #--------------------------------------------------------------------------
  # ● スキル名を閉じる
  #--------------------------------------------------------------------------      
  def close_skill_name
    $game_party.display_skill_name = nil
    $game_troop.screen.pictures.each{|pic| pic.erase}
  end
  #--------------------------------------------------------------------------
  # ○ 反撃の発動
  #--------------------------------------------------------------------------
  def invoke_counter_attack(target, item)
    @log_window.clear
    @subject, target = target, @subject
    attack_skill = $data_skills[@subject.counter_skill ? @subject.counter_skill : @subject.attack_skill_id]
    @subject.skill_interrupt(attack_skill.id)
    process_skill_word(attack_skill)
    display_skill_name(attack_skill)
    @log_window.display_counter(@subject, attack_skill)
    show_animation([target], attack_skill.animation_id)
    apply_item_effects(apply_substitute(target, attack_skill), attack_skill)
    refresh_status
    @subject.remove_current_action
    @subject, target = target, @subject
  end
  #--------------------------------------------------------------------------
  # ● 最終反撃の発動
  #--------------------------------------------------------------------------
  def invoke_final_skill(target, item)
    @log_window.clear
    @subject, target = target, @subject
    attack_skill = $data_skills[@subject.final_invoke]
    @subject.skill_interrupt(attack_skill.id)
    process_skill_word(attack_skill)
    display_skill_name(attack_skill)
    @log_window.display_final_invoke(@subject, attack_skill)
    targets = @subject.current_action.make_targets.compact
    show_animation(targets, attack_skill.animation_id)
    targets.each {|t|
      apply_item_effects(apply_substitute(t, attack_skill), attack_skill)
    }
    refresh_status
    @subject.remove_current_action
    @subject, target = target, @subject
  end
  #--------------------------------------------------------------------------
  # ● メンバー入れ替えで拘束中のルカは選択不可
  #--------------------------------------------------------------------------
  def no_change_bind?
    return (BattleManager.bind? && $game_party.all_members[member_index].luca?)
  end
  #--------------------------------------------------------------------------
  # ● メンバー入れ替えでの全滅防止
  #--------------------------------------------------------------------------
  def no_change_all_dead_on_bench?
    status_index = @status_window.index
    bench_index  = @bench_window.index
    return ($game_party.alive_members.size == 1 &&
            $game_party.battle_members[status_index].alive? &&
            $game_party.bench_members[bench_index].dead?)
  end
end


