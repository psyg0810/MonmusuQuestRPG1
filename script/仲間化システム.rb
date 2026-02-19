=begin
=仲間化システム




==更新履歴
  Date     Version Author Comment

=end

#==============================================================================
# ■ NWConst::Follow
#==============================================================================
module NWConst::Follow
  SPECIAL = [158, 230, 241, 257, 338, 353, 398, 78, 87]
end

#==============================================================================
# ■ BattleManager
#==============================================================================
class << BattleManager
  #--------------------------------------------------------------------------
  # ● 仲間化の処理 
  #--------------------------------------------------------------------------
  def process_follow
    return if $game_switches[NWConst::Sw::FOLLWER_DISABLE]
    $game_troop.check_getup
    return unless $game_troop.follower_enemy    
    
    if NWConst::Follow::SPECIAL.include?($game_troop.follower_enemy.id)
      send("process_follow_enemy#{$game_troop.follower_enemy.id}".to_sym)
    else
      process_follow_normal
    end
  end
  #--------------------------------------------------------------------------
  # ● 仲間加入時の質問処理
  #--------------------------------------------------------------------------  
  def process_follow_question
    e = $game_troop.follower_enemy    
    e.follow_question_word.execute
    wait_for_message
  end
  #--------------------------------------------------------------------------
  # ● 仲間加入時の選択肢処理
  #--------------------------------------------------------------------------  
  def process_follow_choice(follower_name = nil)
    e = $game_troop.follower_enemy
    follower_name = e.original_name unless follower_name
    $game_message.add("なんと#{follower_name}が起き上がり、")
    $game_message.add("仲間になりたそうにこちらを見ている！\f")
    $game_message.add("仲間にしてあげますか？")
    choice = 0
    ["はい","いいえ"].each {|s| $game_message.choices.push(s) }
    $game_message.choice_cancel_type = 2
    $game_message.choice_proc = Proc.new {|n| choice = n }
    wait_for_message
    
    return choice == 0 ? true : false
  end
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
    $game_party.add_actor(e.follower_actor_id)
    $game_temp.getup_enemy = e.follower_actor_id
    $game_switches[NWConst::Sw::ADD_ACTOR_BASE + e.follower_actor_id] = true
  end
  #--------------------------------------------------------------------------
  # ● 仲間加入時の拒否処理
  #--------------------------------------------------------------------------  
  def process_follow_no
    e = $game_troop.follower_enemy
    e.follow_no_word.execute
    wait_for_message
  end
  #--------------------------------------------------------------------------
  # ● 仲間加入時の去る処理
  #--------------------------------------------------------------------------  
  def process_follow_bye(follower_name = nil)
    e = $game_troop.follower_enemy
    follower_name = e.original_name unless follower_name
    $game_troop.follower_enemy = nil
    $game_message.add("#{follower_name}は悲しそうに去っていった……")
    wait_for_message
  end  
  #--------------------------------------------------------------------------
  # ● 仲間加入時演出（通常パターン）
  #--------------------------------------------------------------------------  
  def process_follow_normal
    process_follow_question
    if process_follow_choice
      process_follow_ok
    else
      process_follow_no
      process_follow_bye
    end
  end  
  #--------------------------------------------------------------------------
  # ● ピクチャーの表示
  #--------------------------------------------------------------------------    
  def pic_show(num, name, ori, x, y, zx, zy, op, bl)
    name = "../Battlers/#{name}"
    $game_troop.screen.pictures[num].show(name, ori, x, y, zx, zy, op, bl)
  end
  #--------------------------------------------------------------------------
  # ● ピクチャーの移動
  #--------------------------------------------------------------------------    
  def pic_move(num, ori, x, y, zx, zy, op, bl, dur)
    $game_troop.screen.pictures[num].move(ori, x, y, zx, zy, op, bl, dur)
  end
  #--------------------------------------------------------------------------
  # ● ピクチャーのクリア
  #--------------------------------------------------------------------------    
  def pic_clear
    $game_troop.screen.clear_pictures
  end  
  #--------------------------------------------------------------------------
  # ● 仲間加入時演出（enemy158）
  #--------------------------------------------------------------------------  
  def process_follow_enemy158
    pic_show(20, "80_ittanmomen_st01", 0, 0, 0, 100, 100, 0, 0)
    pic_show(19, "80_ittanmomen_st11", 0, 0, 0, 100, 100, 0, 0)
    pic_show(18, "80_ittanmomen_st21", 0, 0, 0, 100, 100, 0, 0)
    pic_move(20, 0, 0, 0, 100, 100, 255, 0, 30)
    pic_move(19, 0, 0, 0, 100, 100, 255, 0, 30)
    pic_move(18, 0, 0, 0, 100, 100, 255, 0, 30)
    process_follow_question
    if process_follow_choice("一反木綿娘達")
      process_follow_ok("一反木綿娘達")
    else
      process_follow_no
      pic_move(20, 0, 0, 0, 100, 100, 0, 0, 30)
      pic_move(19, 0, 0, 0, 100, 100, 0, 0, 30)
      pic_move(18, 0, 0, 0, 100, 100, 0, 0, 30)      
      process_follow_bye("一反木綿娘達")
    end
    pic_clear
  end  
  #--------------------------------------------------------------------------
  # ● 仲間加入時演出（enemy230）
  #--------------------------------------------------------------------------  
  def process_follow_enemy230
    pic_show(18, "50_slime_red_st01", 0, 40, 90, 100, 100, 0, 0)
    pic_show(20, "50_slime_purple_st01", 0, 170, 90, 100, 100, 0, 0)
    pic_show(19, "50_slime_blue_st01", 0, 310, 90, 100, 100, 0, 0)
    pic_show(17, "50_slime_green_st01", 0, 450, 110, 100, 100, 0, 0)
    pic_move(18, 0, 40, 90, 100, 100, 255, 0, 30)
    pic_move(20, 0, 170, 90, 100, 100, 255, 0, 30)
    pic_move(19, 0, 310, 90, 100, 100, 255, 0, 30)
    pic_move(17, 0, 450, 110, 100, 100, 255, 0, 30)
    process_follow_question
    if process_follow_choice("パープルスライム達")
      process_follow_ok("パープルスライム達")
    else
      process_follow_no
      pic_move(18, 0, 40, 90, 100, 100, 0, 0, 30)
      pic_move(20, 0, 170, 90, 100, 100, 0, 0, 30)
      pic_move(19, 0, 310, 90, 100, 100, 0, 0, 30)      
      pic_move(17, 0, 450, 110, 100, 100, 0, 0, 30)      
      process_follow_bye("パープルスライム達")
    end
    pic_clear
  end  
  #--------------------------------------------------------------------------
  # ● 仲間加入時演出（enemy241）
  #--------------------------------------------------------------------------  
  def process_follow_enemy241
    pic_show(18, "50_gool_st11", 0, 100, 110, 100, 100, 0, 0)
    pic_show(20, "50_gool_st01", 0, 240, 90, 100, 100, 0, 0)
    pic_show(19, "50_gool_st21", 0, 370, 90, 100, 100, 0, 0)
    pic_move(18, 0, 100, 110, 100, 100, 255, 0, 30)
    pic_move(20, 0, 240, 90, 100, 100, 255, 0, 30)
    pic_move(19, 0, 370, 90, 100, 100, 255, 0, 30)
    process_follow_question
    if process_follow_choice("グール達")
      process_follow_ok("グール達")
    else
      process_follow_no
      pic_move(18, 0, 100, 110, 100, 100, 0, 0, 30)
      pic_move(20, 0, 240, 90, 100, 100, 0, 0, 30)
      pic_move(19, 0, 370, 90, 100, 100, 0, 0, 30)      
      process_follow_bye("グール達")
    end
    pic_clear
  end  
  #--------------------------------------------------------------------------
  # ● 仲間加入時演出（enemy257）
  #--------------------------------------------------------------------------  
  def process_follow_enemy257
    pic_show(20, "80_succubuses_st01", 0, 0, 0, 100, 100, 0, 0)
    pic_show(19, "80_succubuses_st11", 0, 0, 0, 100, 100, 0, 0)
    pic_show(18, "80_succubuses_st21", 0, 0, 0, 100, 100, 0, 0)
    pic_show(17, "80_succubuses_st31", 0, 0, 0, 100, 100, 0, 0)
    pic_move(20, 0, 0, 0, 100, 100, 255, 0, 30)
    pic_move(19, 0, 0, 0, 100, 100, 255, 0, 30)
    pic_move(18, 0, 0, 0, 100, 100, 255, 0, 30)
    pic_move(17, 0, 0, 0, 100, 100, 255, 0, 30)
    process_follow_question
    if process_follow_choice("サキュバス達")
      process_follow_ok("サキュバス達")
    else
      process_follow_no
      pic_move(20, 0, 0, 0, 100, 100, 0, 0, 30)
      pic_move(19, 0, 0, 0, 100, 100, 0, 0, 30)
      pic_move(18, 0, 0, 0, 100, 100, 0, 0, 30)      
      pic_move(17, 0, 0, 0, 100, 100, 0, 0, 30)      
      process_follow_bye("サキュバス達")
    end
    pic_clear
  end  
  #--------------------------------------------------------------------------
  # ● 仲間加入時演出（enemy338）
  #--------------------------------------------------------------------------  
  def process_follow_enemy338
    pic_show(20, "80_arachnes_st01", 0, 0, 0, 100, 100, 0, 0)
    pic_show(19, "80_arachnes_st11", 0, 0, 0, 100, 100, 0, 0)
    pic_show(18, "80_arachnes_st21", 0, 0, 0, 100, 100, 0, 0)
    pic_move(20, 0, 0, 0, 100, 100, 255, 0, 30)
    pic_move(19, 0, 0, 0, 100, 100, 255, 0, 30)
    pic_move(18, 0, 0, 0, 100, 100, 255, 0, 30)
    process_follow_question
    if process_follow_choice("アラクネ達")
      process_follow_ok("アラクネ達")
    else
      process_follow_no
      pic_move(20, 0, 0, 0, 100, 100, 0, 0, 30)
      pic_move(19, 0, 0, 0, 100, 100, 0, 0, 30)
      pic_move(18, 0, 0, 0, 100, 100, 0, 0, 30)      
      process_follow_bye("アラクネ達")
    end
    pic_clear
  end  
  #--------------------------------------------------------------------------
  # ● 仲間加入時演出（enemy398）
  #--------------------------------------------------------------------------  
  def process_follow_enemy398
    pic_show(19, "50_trinity_st11", 0, 150, 70, 100, 100, 0, 0)
    pic_show(20, "50_trinity_st01", 0, 210, 70, 100, 100, 0, 0)
    pic_show(18, "50_trinity_st21", 0, 340, 70, 100, 100, 0, 0)
    pic_move(19, 0, 150, 70, 100, 100, 255, 0, 30)
    pic_move(20, 0, 210, 70, 100, 100, 255, 0, 30)
    pic_move(18, 0, 340, 70, 100, 100, 255, 0, 30)
    process_follow_question
    if process_follow_choice
      process_follow_ok
    else
      process_follow_no
      pic_move(19, 0, 150, 70, 100, 100, 0, 0, 30)
      pic_move(20, 0, 210, 70, 100, 100, 0, 0, 30)
      pic_move(18, 0, 340, 70, 100, 100, 0, 0, 30)      
      process_follow_bye
    end
    pic_clear
  end  
  #--------------------------------------------------------------------------
  # ● 仲間加入時演出（enemy78）
  #--------------------------------------------------------------------------  
  def process_follow_enemy78
    pic_show(20, "80_zonbe_st21", 0, 210, 40, 100, 100, 0, 0)
    pic_show(19, "80_zonbe_st31", 0, 100, 0, 100, 100, 0, 0)
    pic_show(18, "80_zonbe_st41", 0, 300, 0, 100, 100, 0, 0)
    pic_show(17, "80_zonbe_st01", 0, 70, 0, 100, 100, 0, 0)
    pic_move(20, 0, 210, 40, 100, 100, 255, 0, 30)
    process_follow_question
    if process_follow_choice
      pic_move(20, 0, 240, 40, 100, 100, 255, 0, 30)
      pic_move(19, 0, 100, 0, 100, 100, 255, 0, 30)
      pic_move(18, 0, 300, 0, 100, 100, 255, 0, 30)
      pic_move(17, 0, 70, 0, 100, 100, 255, 0, 30)
      Word.new("ゾンビ達が集まってきた！", "", 0).execute
      wait_for_message
      Word.new("【ゾンビ娘】\nあぅぅぅ……", "zonbe_fc3", 2).execute
      wait_for_message
      Word.new("【ゾンビ娘】\nよろ……しく……", "zonbe_fc3", 3).execute      
      wait_for_message
      Word.new("【ルカ】\nえっ、ちょっと……", "ruka_fc1", 0).execute      
      wait_for_message
      process_follow_ok("ゾンビの集団")
    else
      process_follow_no
      pic_move(20, 0, 210, 40, 100, 100, 0, 0, 30)
      process_follow_bye
    end
    pic_clear
  end  
  #--------------------------------------------------------------------------
  # ● 仲間加入時演出（enemy87）
  #--------------------------------------------------------------------------  
  def process_follow_enemy87
    pic_show(20, "50_fairys_st01", 0, 230, 120, 100, 100, 0, 0)
    pic_show(19, "50_fairys_st41", 0, 140, 120, 100, 100, 0, 0)
    pic_show(18, "50_fairys_st21", 0, 320, 140, 100, 100, 0, 0)
    pic_show(17, "50_fairys_st11", 0, 220, 20, 100, 100, 0, 0)
    pic_show(16, "50_fairys_st51", 0, 100, 20, 100, 100, 0, 0)
    pic_show(15, "50_fairys_st31", 0, 360, 20, 100, 100, 0, 0)
    pic_move(20, 0, 230, 120, 100, 100, 255, 0, 30)
    process_follow_question
    if process_follow_choice
      pic_move(20, 0, 230, 120, 100, 100, 255, 0, 30)
      pic_move(19, 0, 140, 120, 100, 100, 255, 0, 30)
      pic_move(18, 0, 320, 140, 100, 100, 255, 0, 30)
      pic_move(17, 0, 220, 20, 100, 100, 255, 0, 30)
      pic_move(16, 0, 100, 20, 100, 100, 255, 0, 30)
      pic_move(15, 0, 360, 20, 100, 100, 255, 0, 30)      
      Word.new("フェアリー達が集まってきた！", "", 0).execute
      wait_for_message
      Word.new("【フェアリー】\nこの人が、外に連れて行ってくれるの……？", "fairys_fc2", 0).execute
      wait_for_message
      Word.new("【フェアリー】\nわーい、よろしくね！", "fairys_fc3", 0).execute      
      wait_for_message
      Word.new("【ルカ】\nちょ、ちょっと……！\nこんなにいっぱい……！？", "ruka_fc1", 0).execute      
      wait_for_message
      process_follow_ok("フェアリーの集団")
    else
      process_follow_no
      pic_move(20, 0, 230, 120, 100, 100, 0, 0, 30)
      process_follow_bye
    end
    pic_clear
  end  
end


#==============================================================================
# ■ RPG::Enemy
#==============================================================================
class RPG::Enemy < RPG::BaseItem
  #--------------------------------------------------------------------------
  # ● 仲間化可能？
  #--------------------------------------------------------------------------
  def follower?
    return NWConst::Follower::SETTINGS.key?(self.id)
  end
  #--------------------------------------------------------------------------
  # ● 仲間化用データの取得
  #--------------------------------------------------------------------------
  def follower_data
    NWConst::Follower::SETTINGS[self.id]
  end
  #--------------------------------------------------------------------------
  # ● 仲間になるアクターIDの取得
  #--------------------------------------------------------------------------
  def follower_actor_id
    follower_data[:actor_id]
  end  
  #--------------------------------------------------------------------------
  # ● 仲間化する確率分母取得
  #--------------------------------------------------------------------------
  def follower_denominator
    follower_data[:denominator]
  end  
end


#==============================================================================
# ■ Game_Enemy
#==============================================================================
class Game_Enemy < Game_Battler
  #--------------------------------------------------------------------------
  # ○ コラプス効果の実行
  #--------------------------------------------------------------------------
  alias nw_follower_perform_collapse_effect perform_collapse_effect  
  def perform_collapse_effect
    nw_follower_perform_collapse_effect
    $game_troop.dead_enemies.push(self)
  end
  #--------------------------------------------------------------------------
  # ● 仲間化可能？
  #--------------------------------------------------------------------------
  def follower?
    return enemy.follower?
  end
  #--------------------------------------------------------------------------
  # ● 仲間化用データの取得
  #--------------------------------------------------------------------------
  def follower_data
    enemy.follower_data
  end
  #--------------------------------------------------------------------------
  # ● 仲間になるアクターIDの取得
  #--------------------------------------------------------------------------
  def follower_actor_id
    enemy.follower_actor_id
  end  
  #--------------------------------------------------------------------------
  # ● 仲間化する確率分母取得
  #--------------------------------------------------------------------------
  def follower_denominator
    enemy.follower_denominator
  end
  #--------------------------------------------------------------------------
  # ● 仲間化時の質問セリフ取得
  #--------------------------------------------------------------------------
  def follow_question_word
    data = enemy.follower_data[:question]
    Word.new(data[0], data[1], data[2])
  end
  #--------------------------------------------------------------------------
  # ● 仲間化時の承諾セリフ取得
  #--------------------------------------------------------------------------
  def follow_yes_word
    data = enemy.follower_data[:yes]
    Word.new(data[0], data[1], data[2])
  end
  #--------------------------------------------------------------------------
  # ● 仲間化時の拒否セリフ取得
  #--------------------------------------------------------------------------
  def follow_no_word
    data = enemy.follower_data[:no]
    Word.new(data[0], data[1], data[2])
  end
  #--------------------------------------------------------------------------
  # ● 友好度の設定
  #--------------------------------------------------------------------------  
  def friend=(value)
    enemy.friend = value
  end
  #--------------------------------------------------------------------------
  # ● 友好度の取得
  #--------------------------------------------------------------------------  
  def friend
    return enemy.friend
  end
  #--------------------------------------------------------------------------
  # ● 仲間化処理の時に特殊演出が発生する？
  #--------------------------------------------------------------------------
  def follow_special?
    return NWConst::Follow::SPECIAL.include?(self.id)
  end    
end

#==============================================================================
# ■ Game_Troop
#==============================================================================
class Game_Troop < Game_Unit
  #--------------------------------------------------------------------------
  # ● 公開インスタンス変数
  #--------------------------------------------------------------------------
  attr_accessor   :follower_enemy
  attr_accessor   :dead_enemies
  #--------------------------------------------------------------------------
  # ● クリア
  #--------------------------------------------------------------------------
  alias nw_follower_clear clear
  def clear
    nw_follower_clear
    @follower_enemy = nil
    @dead_enemies = []
  end
  #--------------------------------------------------------------------------
  # ● 仲間化の抽選
  #--------------------------------------------------------------------------
  def check_getup
    e = @dead_enemies.reverse.uniq.select{|enemy|
      enemy.follower?
    }.reject{|enemy|
      $game_party.exist_all_actor_id?(enemy.follower_actor_id)
    }.first
    return unless e
    
    base   = 1.0 / e.follower_denominator
    second = base * $game_party.collect_rate
    last   = second * (e.friend / 100.0)
    # テスト用途中経過表示
    if $TEST
      print "ID#{e.id} #{e.name}\n"
      print "基礎確率:#{Integer(base * 100.0)}%\n"
      print "仲間加入倍率:*#{$game_party.collect_rate}\n"
      print "友好度補正倍率:*#{e.friend / 100.0}\n"
      print "最終確率:#{Integer(last * 100)}%\n"
    end
    @follower_enemy = e if rand < last
  end  
end


#==============================================================================
# ■ Sprite_Follower
#==============================================================================
class Sprite_Follower < Sprite_Base
  #--------------------------------------------------------------------------
  # ● 解放
  #--------------------------------------------------------------------------
  def dispose
    self.bitmap.dispose if self.bitmap
    super
  end
  #--------------------------------------------------------------------------
  # ● フレーム更新
  #--------------------------------------------------------------------------
  def update
    super
    refresh if $game_troop.follower_enemy != @enemy
    update_opacity
  end  
  #--------------------------------------------------------------------------
  # ● リフレッシュ
  #--------------------------------------------------------------------------
  def refresh
    @enemy  = $game_troop.follower_enemy
    return unless @enemy && !@enemy.follow_special?
    self.bitmap = Cache.battler(@enemy.enemy.battler_name, @enemy.enemy.battler_hue)
    self.ox = self.bitmap.width / 2
    self.oy = self.bitmap.height
    self.x = Graphics.width / 2
    self.y = @enemy.screen_y
    self.z = @enemy.screen_z
    self.opacity = 0
  end
  #--------------------------------------------------------------------------
  # ● 不透明度の更新
  #--------------------------------------------------------------------------
  def update_opacity
    self.opacity += @enemy ? 10 : -10
  end
end






