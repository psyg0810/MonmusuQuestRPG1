=begin
=Foo_公開スクリプトコマンド




==更新履歴
  Date     Version Author Comment

=end


#==============================================================================
# ■ Game_Interpreter
#==============================================================================
class Game_Interpreter
  include NWConst::LibraryManager
  include NWConst::PartyManager  
  #--------------------------------------------------------------------------
  # ● 現在行動者にスキル割り込み
  #--------------------------------------------------------------------------  
  def interrupt_skill(skill_id)
    battler = $game_actors[v(NWConst::Var::ACTION_USER)]
    return if !$game_party.in_battle || $data_skills[skill_id].nil? || battler.nil?
    BattleManager.skill_interrupt(battler, skill_id)
  end
  #--------------------------------------------------------------------------
  # ● 選択肢呼び出し
  #--------------------------------------------------------------------------
  def unlimited_choices(var_id, names)
    return if names.empty? || var_id <= 0
    names.each { |name| $game_message.choices.push(name.to_s) }
    $game_message.choice_cancel_type = names.size + 1
    $game_message.choice_proc = Proc.new {|n| $game_variables[var_id] = n }
    Fiber.yield while $game_message.choice?
  end  
  #--------------------------------------------------------------------------
  # ● 強制的にボートに乗る
  #--------------------------------------------------------------------------
  def forced_get_on_boat
    $game_player.forced_get_on_vehicle(:boat)
  end   
  #--------------------------------------------------------------------------
  # ● 強制的に大型船に乗る
  #--------------------------------------------------------------------------
  def forced_get_on_ship
    $game_player.forced_get_on_vehicle(:ship)
  end   
  #--------------------------------------------------------------------------
  # ● 強制的に飛行船に乗る
  #--------------------------------------------------------------------------
  def forced_get_on_airship
    $game_player.forced_get_on_vehicle(:airship)
  end   
  #--------------------------------------------------------------------------
  # ● 強制的に乗り物から降りる
  #--------------------------------------------------------------------------
  def forced_get_off_vehicle
    $game_player.forced_get_off_vehicle
  end
  #--------------------------------------------------------------------------
  # ● スキル名を表示する
  #--------------------------------------------------------------------------
  def display_skill_name(text)
    $game_party.display_skill_name = text
  end  
  #--------------------------------------------------------------------------
  # ● スキル名を非表示にする
  #--------------------------------------------------------------------------
  def clear_skill_name
    $game_party.display_skill_name = nil
  end
  #--------------------------------------------------------------------------
  # ● キーを入力する
  #--------------------------------------------------------------------------
  def input_keys(duration)
    $game_temp.keys_stack = []
    duration.times{
      Fiber.yield      
      if Input.trigger?(:UP)
        $game_temp.keys_stack.push(:U)
      elsif Input.trigger?(:DOWN)
        $game_temp.keys_stack.push(:D)
      elsif Input.trigger?(:LEFT)
        $game_temp.keys_stack.push(:L)
      elsif Input.trigger?(:RIGHT)
        $game_temp.keys_stack.push(:R)
      elsif Input.trigger?(:A)
        $game_temp.keys_stack.push(:B1)
      elsif Input.trigger?(:B)
        $game_temp.keys_stack.push(:B2)
      elsif Input.trigger?(:C)
        $game_temp.keys_stack.push(:B3)        
      elsif Input.trigger?(:X)
        $game_temp.keys_stack.push(:B4)
      elsif Input.trigger?(:Y)
        $game_temp.keys_stack.push(:B5)        
      elsif Input.trigger?(:Z)
        $game_temp.keys_stack.push(:B6)        
      elsif Input.trigger?(:L)
        $game_temp.keys_stack.push(:B7)        
      elsif Input.trigger?(:R)
        $game_temp.keys_stack.push(:B8)        
      end
    }
  end
  #--------------------------------------------------------------------------
  # ● 入力キースタックの取得
  #--------------------------------------------------------------------------
  def keys_stack
    return $game_temp.keys_stack
  end
  #--------------------------------------------------------------------------
  # ● 解錠レベルの取得
  #--------------------------------------------------------------------------
  def unlock_level
    return $game_party.unlock_level
  end
  #--------------------------------------------------------------------------
  # ● 一時メンバーのセット
  #--------------------------------------------------------------------------
  def set_temp_actors(*args)
    $game_party.set_temp_actors(args)
  end
  #--------------------------------------------------------------------------
  # ● 一時メンバーの解放
  #--------------------------------------------------------------------------
  def release_temp_actors
    $game_party.release_temp_actors
  end
  #--------------------------------------------------------------------------
  # ● 拡張アクター加入
  #--------------------------------------------------------------------------
  def add_actor_ex(actor_id)
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
  # ● 拡張アクター移動
  #--------------------------------------------------------------------------
  def move_actor_ex(actor_id)
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
        move_actor(actor_id)
      end
    else
      move_actor(actor_id)
    end
  end
  #--------------------------------------------------------------------------
  # ● パーティに指定のアクターがいる場合ラベルにジャンプ
  #--------------------------------------------------------------------------
  def actor_label_jump
    labels = $game_party.all_members.collect{|actor| "#{actor.id}"}
    index = []
    @list.each_with_index{|command, i|
      next unless command.code == 118 && labels.include?(command.parameters[0])
      index.push(i)
    }
    return if index.empty?
    @index = index.sample
  end  
  #--------------------------------------------------------------------------
  # ● 指定のエネミーの友好度変化
  #--------------------------------------------------------------------------
  def change_friend(value)
    return unless $data_enemies[$game_variables[51]]
    return if value == 0
    enemy = $data_enemies[$game_variables[51]]
    se   = RPG::SE.new(0 < value ? "Raise3" : "Down3", 100, 100)
    text = sprintf("%sの友好度が%d%s", enemy.name, value.abs, 0 < value ? "上がった！" : "下がった！")
    enemy.friend += value
    se.play
    $game_message.add(text)
    wait_for_message
  end  
  #--------------------------------------------------------------------------
  # ● 職業（種族）レベルの変更
  #--------------------------------------------------------------------------
  def set_class_level(actor_id, class_id, level, show = false)
    return unless $game_actors.exist?(actor_id)
    actor = $game_actors[actor_id]
    kind = NWConst::Class::JOB_RANGE.include?(class_id) ? :class : :tribe
    temp_class_id = kind == :class ? actor.class_id : actor.tribe_id
    temp_equips = actor.equips
    actor.clear_equipments
    actor.change_class(class_id, kind)    
    actor.change_level(level, show, kind)
    actor.change_class(temp_class_id, kind)
    temp_equips.each_with_index{|equip, i| actor.change_equip(i, equip)}
  end
  #--------------------------------------------------------------------------
  # ● アクターID:Nが職業ID:Mだったならば
  #--------------------------------------------------------------------------
  def actor_class?(actor_id, class_id)
    return false unless $game_actors.exist?(actor_id)
    actor = $game_actors[actor_id]
    return [actor.class_id, actor.tribe_id].include?(class_id)
  end
  #--------------------------------------------------------------------------
  # ● アクターID:Nの職業ID:MがL以上だったならば
  #--------------------------------------------------------------------------
  def actor_class_level_over?(actor_id, class_id, level)
    return false unless $game_actors.exist?(actor_id)
    actor = $game_actors[actor_id]
    return false if actor.level_list[class_id].nil?
    return level <= actor.level_list[class_id]
  end
  #--------------------------------------------------------------------------
  # ● パーティ編成画面の呼び出し
  #--------------------------------------------------------------------------
  def call_party_edit
    # 隊列集合
    $game_player.followers.gather
    Fiber.yield until $game_player.followers.gather?
    # ルカの戦闘不能の解除
    $game_actors[NWConst::Actor::LUCA].remove_state(1)
    SceneManager.call(Scene_PartyEdit)
    Fiber.yield    
  end  
end












