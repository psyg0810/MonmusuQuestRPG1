=begin
=ベース/Module

ここではModuleを中心に扱います


==更新履歴
  Date     Version Author Comment
==14/12/13 2.0.0   トリス 統合A～E D

=end

#==============================================================================
# ■ Audio
#==============================================================================
class << Audio
  #--------------------------------------------------------------------------
  # ● 基本初期化処理
  #--------------------------------------------------------------------------
  def init_basic
    bgm_stop
    bgs_stop
    @fiber_bgm = nil
    @fiber_bgs = nil
  end
  #--------------------------------------------------------------------------
  # ● 更新処理
  #--------------------------------------------------------------------------
  def update
  end
end

#==============================================================================
# ■ DataManager
#==============================================================================
class << DataManager
  #--------------------------------------------------------------------------
  # ○ データベースのロード
  #--------------------------------------------------------------------------
  def load_database
    if $BTEST
      load_battle_test_database
    else
      load_normal_database
      check_player_location
    end
    $data_library = Data_Library.new
  end
  #--------------------------------------------------------------------------
  # ○ 各種ゲームオブジェクトの作成
  #--------------------------------------------------------------------------
  def create_game_objects
    $game_temp          = Game_Temp.new
    $game_system        = Game_System.new
    $game_timer         = Game_Timer.new
    $game_message       = Game_Message.new
    $game_switches      = Game_Switches.new
    $game_variables     = Game_Variables.new
    $game_self_switches = Game_SelfSwitches.new
    $game_actors        = Game_Actors.new
    $game_party         = Game_Party.new
    $game_troop         = Game_Troop.new
    $game_map           = Game_Map.new
    $game_player        = Game_Player.new
    $game_novel         = Game_Novel.new #
    $game_poker         = Game_Poker.new #
    $game_slot          = Game_Slot.new #
  end
  #--------------------------------------------------------------------------
  # ○ 戦闘テストのセットアップ
  #--------------------------------------------------------------------------
  def setup_battle_test
    $game_map.setup($data_system.start_map_id) #
    $game_party.setup_battle_test
    BattleManager.setup($data_system.test_troop_id)
    BattleManager.play_battle_bgm
  end  
  #--------------------------------------------------------------------------
  # ○ セーブ内容の作成
  #--------------------------------------------------------------------------
  def make_save_contents
    contents = {}
    contents[:system]        = $game_system
    contents[:timer]         = $game_timer
    contents[:message]       = $game_message
    contents[:switches]      = $game_switches
    contents[:variables]     = $game_variables
    contents[:self_switches] = $game_self_switches
    contents[:actors]        = $game_actors
    contents[:party]         = $game_party
    contents[:troop]         = $game_troop
    contents[:map]           = $game_map
    contents[:player]        = $game_player
    contents[:novel]         = $game_novel
    contents
  end
  #--------------------------------------------------------------------------
  # ○ セーブ内容の展開
  #--------------------------------------------------------------------------
  def extract_save_contents(contents)
    $game_system        = contents[:system]
    $game_timer         = contents[:timer]
    $game_message       = contents[:message]
    $game_switches      = contents[:switches]
    $game_variables     = contents[:variables]
    $game_self_switches = contents[:self_switches]
    $game_actors        = contents[:actors]
    $game_party         = contents[:party]
    $game_troop         = contents[:troop]
    $game_map           = contents[:map]
    $game_player        = contents[:player]
    $game_novel         = contents[:novel]
  end
end

#==============================================================================
# ■ SceneManager
#==============================================================================
class << SceneManager
  #--------------------------------------------------------------------------
  # ○ 実行
  #--------------------------------------------------------------------------
  def run
    Audio.setup_midi if use_midi?
#~     Audio.init_basic
    Audio.reset_sound
    DataManager.init
    @scene = first_scene_class.new
    @scene.main while @scene
  end
  #--------------------------------------------------------------------------
  # ● シーンスタックへのプッシュ
  #--------------------------------------------------------------------------
  def push(scene)
    @stack.push(scene.new)
  end
end

#==============================================================================
# ■ Vocab
#==============================================================================
module Vocab
  #--------------------------------------------------------------------------
  # ○ 基本挿替
  #--------------------------------------------------------------------------
#  Evasion         = "しかし%sは素早くかわした！"
  ActorNoHit      = "しかし%sは素早くかわした！"
  EnemyNoHit      = "しかし%sは素早くかわした！"
  ActorNoDamage   = "%sには通じなかった！"
  EnemyNoDamage   = "%sには通じなかった！"

  #--------------------------------------------------------------------------
  # ● ユーザ定義
  #--------------------------------------------------------------------------  
  Giveup            = [
    "ルカは誘惑に屈し、無抵抗になった！", 
    "仲間達はルカを見離し、その場から立ち去った……"
  ]
  BindingStart      = [
    "%sは拘束された！",
    "%sは犯されてしまった！",
    "%sは犯されてしまった！",
    "しかし既に%sは拘束されている！"    
  ]
  TemptationActionFailure = "しかしルカはすでに倒れている！"
  
  Ability           = "アビリティ"  
  Shortage            = "しかし%sが足りない！"
  SkillSealedFailure  = "しかしスキルは封じられている！"
  ObtainJobExp        = "%s の職業経験値を獲得！"  
  Stealed             = "%sから%sを盗んだ！"
  StealFailure        = "%sから盗めなかった！"
  StealedItemEmpty    = "%sは何も持っていない！"
  Stand               = "%sは食いしばって耐えた！"
  Invalidate          = "%sはダメージを無効化した！"
  DefenseWall         = "%sは防御壁で相殺した！"
  FinalInvoke         = "%sは倒れる間際に%sで反撃した！"
  PayLife             = "%sは力尽きた！"
  PayLifeFailure      = "%sは激しく衰弱した！"
  OverDriveSuccess    = "%sは時を止めた！"
  OverDriveFailure    = "しかし既に時は止まっている！"
  BindResistSuccess   = "%sの拘束から脱出した！"
  BindResistFailure   = "しかし%sの拘束から逃れられない！"
  EternalBindResist   = "しかし%sにねじ伏せられてしまった！"
  PleasureFinished    = "はイってしまった！"  
  Predation           = "%sは捕食された！"
  ReStoration         = "%sは%s吸い取った！"
  ThrowItem           = "%sは%sを投げた！"
end

#==============================================================================
# ■ Vocab
#==============================================================================
class << Vocab
  # 能力値 (短)
  def params_a(param_id)
    ["攻撃", "防御", "魔力", "精神", "素早", "器用"][param_id]
  end
  # 仮想キー
  def key_a
    {:gamepad => "1", :keyboard => "Shift"}[$game_system.conf[:key_text]]
  end
  def key_b
    {:gamepad => "2", :keyboard => "X"}[$game_system.conf[:key_text]]
  end
  def key_c
    {:gamepad => "3", :keyboard => "Z"}[$game_system.conf[:key_text]]
  end
  def key_x
    {:gamepad => "4", :keyboard => "A"}[$game_system.conf[:key_text]]
  end
  def key_y
    {:gamepad => "5", :keyboard => "S"}[$game_system.conf[:key_text]]
  end
  def key_z
    {:gamepad => "6", :keyboard => "D"}[$game_system.conf[:key_text]]
  end
  def key_l
    {:gamepad => "7", :keyboard => "Q"}[$game_system.conf[:key_text]]
  end
  def key_r
    {:gamepad => "8", :keyboard => "W"}[$game_system.conf[:key_text]]
  end      
  # パーティコマンド
  def giveup;        "降参";     end
  def shift_change;  "入れ替え"; end  
  def library;       "図鑑";     end  
  def config;        "設定";     end  
end
  
#==============================================================================
# ■ Help
#==============================================================================
module Help; end
class << Help
  #--------------------------------------------------------------------------
  # ● アビリティ画面のヘルプメッセージ
  #--------------------------------------------------------------------------
  def ability
    "アビリティタイプを選択してください\n" + 
    "#{Vocab.key_c}:決定　#{Vocab.key_b}:キャンセル　#{Vocab.key_a}:外す"
  end
  #--------------------------------------------------------------------------
  # ● 図鑑画面のヘルプメッセージ
  #--------------------------------------------------------------------------
  def library
    {
      :blank      => "この項目は白紙です。 ",
      :discovery  => "この項目は詳細が分かりません。 ",
      :return_top => "図鑑のトップへ戻ります。",
      :close_lib  => "図鑑を閉じ、元の画面へ戻ります。",
      :btn_detail => "#{Vocab.key_c}:詳細を閲覧",
      :btn_column => "↑/↓:項目移動",
      :btn_jump   => "#{Vocab.key_l}/#{Vocab.key_r}:項目ジャンプ",
      :btn_page   => "←/→:ページ移動",
      :btn_scroll => "#{Vocab.key_y}/#{Vocab.key_z}:解説文上下",
    }
  end
  #--------------------------------------------------------------------------
  # ● コンフィグ-色調のヘルプメッセージ
  #--------------------------------------------------------------------------
  def config_tone
    [
      "赤成分の色調値設定です。\r\n←/→:増減。#{Vocab.key_l}/#{Vocab.key_r}:大きく増減。",
      "緑成分の色調値設定です。\r\n←/→:増減。#{Vocab.key_l}/#{Vocab.key_r}:大きく増減。",
      "青成分の色調値設定です。\r\n←/→:増減。#{Vocab.key_l}/#{Vocab.key_r}:大きく増減。",
      "初期値に戻します。",
      "戻ります。"
    ]  
  end
  #--------------------------------------------------------------------------
  # ● コンフィグ-音量のヘルプメッセージ
  #--------------------------------------------------------------------------
  def config_sound
    [
      "ＢＧＭの音量設定です。\r\n←/→:増減。#{Vocab.key_l}/#{Vocab.key_r}:大きく増減。",
      "ＢＧＳの音量設定です。\r\n←/→:増減。#{Vocab.key_l}/#{Vocab.key_r}:大きく増減。",
      "ＭＥの音量設定です。\r\n←/→:増減。#{Vocab.key_l}/#{Vocab.key_r}:大きく増減。",
      "ＳＥの音量設定です。\r\n←/→:増減。#{Vocab.key_l}/#{Vocab.key_r}:大きく増減。",
      "初期値に戻します。",
      "戻ります。"
    ]  
  end
  #--------------------------------------------------------------------------
  # ● パーティ編成画面のヘルプメッセージ
  #--------------------------------------------------------------------------  
  def party_edit
    [
      "#{Vocab.key_a}:外す",
      "#{Vocab.key_x}:ステータス",
      "#{Vocab.key_y}:ソート",
      "#{Vocab.key_z}:城内ワープ",
    ]
  end
  #--------------------------------------------------------------------------
  # ● 転職画面のヘルプメッセージ
  #--------------------------------------------------------------------------  
  def job_change
    ["#{Vocab.key_y}/#{Vocab.key_z}:ソート"]
  end  
  #--------------------------------------------------------------------------
  # ● ショップ画面の装備品情報変更テキスト
  #--------------------------------------------------------------------------  
  def shop_equip_change
    "←/→:情報変更"
  end
  #--------------------------------------------------------------------------
  # ● ショップ画面の装備品性能比較テキスト
  #--------------------------------------------------------------------------  
  def shop_param_compare
    "#{Vocab.key_x}:装備変更一覧"
  end
  #--------------------------------------------------------------------------
  # ● スロット画面の操作説明テキスト
  #--------------------------------------------------------------------------  
  def slot_description
    {
      :stand => "→:賭け金を増やす　#{Vocab.key_c}:スロットを回す\n←:賭け金を減らす　#{Vocab.key_b}:スロットをやめる",
      :play  => "#{Vocab.key_c}:リールを止める"
    }
  end
end

#==============================================================================
# ■ SceneManager
#==============================================================================
class << SceneManager
  #--------------------------------------------------------------------------
  # ○ 背景として使うためのスナップショット作成
  #--------------------------------------------------------------------------
  def snapshot_for_background
    @background_bitmap.dispose if @background_bitmap
    @background_bitmap = Graphics.snap_to_bitmap
#    @background_bitmap.blur
  end
end
  
#==============================================================================
# ■ BattleManager
#==============================================================================
class << BattleManager
  #--------------------------------------------------------------------------
  # ○ セットアップ
  #--------------------------------------------------------------------------
  def setup(troop_id, can_escape = true, can_lose = false)
    init_members
    $game_troop.setup(troop_id)
    @can_escape = can_escape
    @can_lose = can_lose
    make_escape_ratio
    setup_terrain
  end  
  #--------------------------------------------------------------------------
  # ○ メンバ変数の初期化
  #--------------------------------------------------------------------------
  def init_members
    @phase = :init              # 戦闘進行フェーズ
    @can_escape = false         # 逃走可能フラグ
    @can_lose = false           # 敗北可能フラグ
    @event_proc = nil           # イベント用コールバック
    @preemptive = false         # 先制攻撃フラグ
    @surprise = false           # 不意打ちフラグ
    @actor_index = -1           # コマンド入力中のアクター
    @action_forced = nil        # 戦闘行動の強制
    @map_bgm = nil              # 戦闘前の BGM 記憶用
    @map_bgs = nil              # 戦闘前の BGS 記憶用
    @action_battlers = []       # 行動順序リスト
    @action_game_masters = []   # 行動順序リスト（ＧＭ専用）
    @giveup = false             # 降参フラグ
    @giveup_count = 0           # 降参カウント
    @bind_count = 0             # 拘束カウント
    @terrain = :未定義          # 地形
  end
  #--------------------------------------------------------------------------
  # ○ エンカウント時の処理
  #--------------------------------------------------------------------------
  def on_encounter
    @preemptive = (rand < rate_preemptive)
    @surprise = (rand < rate_surprise && !@preemptive)
    print "先制攻撃発動率#{(rate_preemptive * 100.0).to_i}%.先制#{@preemptive ? "成功" : "失敗"}。\n" if $TEST
    print "不意打ち発動率#{(rate_surprise * 100.0).to_i}%.不意打ち#{@surprise ? "成功" : "失敗"}。\n" if $TEST
  end  
  #--------------------------------------------------------------------------
  # ○ 戦闘 BGM の演奏
  #--------------------------------------------------------------------------
  def play_battle_bgm
    $game_troop.battle_bgm.play
    RPG::BGS.stop
  end
  #--------------------------------------------------------------------------
  # ● 初期フェイズ
  #--------------------------------------------------------------------------  
  def init_phase
    @phase = :init
  end
  #--------------------------------------------------------------------------
  # ● 仲間入れ替えフェイズ
  #--------------------------------------------------------------------------  
  def shift_change
    @phase = :shift_change
    $game_party.clear_actions
  end  
  #--------------------------------------------------------------------------
  # ● 仲間入れ替えフェイズ?
  #--------------------------------------------------------------------------  
  def shift_change?
    @phase == :shift_change
  end
  #--------------------------------------------------------------------------
  # ● 降参
  #--------------------------------------------------------------------------  
  def giveup
    @giveup = true
    @giveup_count = 20
    $game_party.clear_actions
    $game_party.all_members.reject{|m| m.luca?}.each{|m| m.hide}
    luca_index = 0
    $game_party.all_members.each_with_index{|actor, i|
      luca_index = (actor.luca? ? i : luca_index)
    }
    $game_party.swap_order(0, luca_index)
  end
  #--------------------------------------------------------------------------
  # ● 降参中？
  #--------------------------------------------------------------------------  
  def giveup?
    return @giveup
  end
  #--------------------------------------------------------------------------
  # ● 降参カウントダウン
  #--------------------------------------------------------------------------  
  def giveup_count_down
    @giveup_count -= 1
    return @giveup_count == 0
  end
  #--------------------------------------------------------------------------
  # ● 拘束セット
  #--------------------------------------------------------------------------  
  def bind_set(count)
    bind_reset
    @bind_count = count
  end
  #--------------------------------------------------------------------------
  # ● 拘束カウントダウン
  #--------------------------------------------------------------------------  
  def bind_count_down
    @bind_count -= 1
    bind_refresh
  end
  #--------------------------------------------------------------------------
  # ● 拘束リフレッシュ
  #--------------------------------------------------------------------------  
  def bind_refresh
    bind_reset unless bind?
  end
  #--------------------------------------------------------------------------
  # ● 拘束発生中？
  #--------------------------------------------------------------------------  
  def bind?
    0 != @bind_count && bind_user_exist? && bind_target_exist?
  end
  #--------------------------------------------------------------------------
  # ● 拘束状態のリセット
  #--------------------------------------------------------------------------  
  def bind_reset
    $game_party.members.each{|m| m.clear_actions if m.bind_target?}
    $game_troop.members.each{|m| m.clear_actions if m.bind_user?}
    @bind_count = 0
    $game_troop.members.each{|m|
      m.remove_state(NWConst::State::UBIND)
      m.remove_state(NWConst::State::EUBIND)
    }
    $game_party.members.each{|m|
      m.remove_state(NWConst::State::TBIND)
      m.remove_state(NWConst::State::ETBIND)
    }
  end
  #--------------------------------------------------------------------------
  # ● 拘束技使用者は存在する？
  #--------------------------------------------------------------------------  
  def bind_user_exist?
    $game_troop.members.any?{|m| m.bind_user?}
  end
  #--------------------------------------------------------------------------
  # ● 拘束技対象は存在する？
  #--------------------------------------------------------------------------  
  def bind_target_exist?
    $game_party.members.any?{|m| m.bind_target?}
  end
  #--------------------------------------------------------------------------
  # ● 拘束技使用者のインデックス
  #--------------------------------------------------------------------------  
  def bind_user_index
    $game_troop.members.each_with_index{|member, i|
      return i if member.bind_user?
    }
    return -1
  end
  #--------------------------------------------------------------------------
  # ○ 逃走成功率の作成
  #--------------------------------------------------------------------------
  def make_escape_ratio
    lv = $game_actors[NWConst::Actor::LUCA].base_level
    escape_level = $game_troop.escape_level_max
    @escape_ratio = lv >= escape_level ? 1.0 : (1.0 / (escape_level - lv + 1))
  end  
  #--------------------------------------------------------------------------
  # ● 戦闘地形の設定
  #--------------------------------------------------------------------------
  def setup_terrain
    NWConst::Field::TERRAIN.each{|key, value|
      next if value[:tag] != $game_player.terrain_tag && !(value[:map_id].include?($game_map.map_id))
      @terrain = key
      break
    }
  end
  #--------------------------------------------------------------------------
  # ● 戦闘地形の取得
  #--------------------------------------------------------------------------
  def terrain
    return @terrain
  end
  #--------------------------------------------------------------------------
  # ○ 逃走許可の取得
  #--------------------------------------------------------------------------
  def can_escape?
    return @can_escape && !bind?
  end  
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
    if @preemptive
      $game_message.add(sprintf(Vocab::Preemptive, $game_party.name))
    elsif @surprise
      $game_message.add(sprintf(Vocab::Surprise, $game_party.name))
    end
    wait_for_message
  end
  #--------------------------------------------------------------------------
  # ○ 勝利の処理 
  #--------------------------------------------------------------------------
  def process_victory
    play_battle_end_me
    replay_bgm_and_bgs
    $game_message.add(sprintf(Vocab::Victory, $game_party.name))
    display_exp unless $game_switches[NWConst::Sw::GET_EXP_DISABLE]
    gain_gold
    gain_drop_items unless $game_switches[NWConst::Sw::GET_EXP_DISABLE]
    gain_exp unless $game_switches[NWConst::Sw::GET_EXP_DISABLE]
    gain_love
    process_follow #
    SceneManager.return
    battle_end(0)
    return true
  end
  #--------------------------------------------------------------------------
  # ● 好感度上昇
  #--------------------------------------------------------------------------
  def gain_love
    $game_party.battle_members.select{|member|
      !member.luca?
    }.each{|member|
      member.love += $game_variables[NWConst::Var::BATTLE_END_GAIN_LOVE]
    }
  end
  #--------------------------------------------------------------------------
  # ○ 逃走の処理
  #--------------------------------------------------------------------------
  def process_escape
    $game_message.add(sprintf(Vocab::EscapeStart, $game_party.name))
    success = @preemptive ? true : (rand < @escape_ratio)
    Sound.play_escape
    if success
      process_abort
    else
      $game_message.add('\.' + Vocab::EscapeFailure)
      $game_party.clear_actions
    end
    wait_for_message
    return success
  end
  #--------------------------------------------------------------------------
  # ● 強制逃走の処理
  #--------------------------------------------------------------------------
  def process_forced_escape
    $game_message.add(sprintf(Vocab::EscapeStart, $game_party.name))
    Sound.play_escape
    if can_escape?
      process_abort
    else
      $game_message.add('\.' + Vocab::EscapeFailure)
    end
    wait_for_message
  end
  #--------------------------------------------------------------------------
  # ○ 敗北の処理
  #--------------------------------------------------------------------------
  def process_defeat
    $game_message.add(sprintf(Vocab::Defeat, $game_party.name))
    wait_for_message
    if @can_lose
      revive_battle_members
      replay_bgm_and_bgs
      SceneManager.return
    else
      # 通常のゲームオーバーは完全排除
      Audio.bgm_stop
      Audio.bgs_stop
      revive_battle_members
      $game_map.interpreter.clear
      reset_player
      change_novel_scene
    end
    battle_end(2)
    return true
  end
  #--------------------------------------------------------------------------
  # ● プレイヤのリセット
  #--------------------------------------------------------------------------  
  def reset_player
    $game_player.transparent = true
    $game_player.followers.visible = false
    $game_player.moveto(0,0)
    $game_player.refresh    
  end
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
    if no_ls_skip?
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
  def no_ls_skip?
    enemy_id = $game_troop.lose_event_id - NWConst::Common::LOSE_EVENT_BASE
    return $data_enemies[enemy_id].note =~ /<スキップ不能>/ ? true : false
  end
  #--------------------------------------------------------------------------
  # ○ 戦闘終了
  #     result : 結果（0:勝利 1:逃走 2:敗北）
  #--------------------------------------------------------------------------
  def battle_end(result)
    @phase = nil
    @event_proc.call(result) if @event_proc
    $game_temp.reserve_common_event(NWConst::Common::BATTLE_END) #
    $game_party.on_battle_end
    $game_troop.on_battle_end
    SceneManager.exit if $BTEST
  end
  #--------------------------------------------------------------------------
  # ○ ターン開始
  #--------------------------------------------------------------------------
  def turn_start
    @phase = :turn
    clear_actor
    $game_party.check_change_action
    $game_troop.increase_turn
    make_action_orders
  end  
  #--------------------------------------------------------------------------
  # ● 戦闘開始スキルの設定
  #--------------------------------------------------------------------------
  def set_battle_start_skill
    return if giveup?
    @action_game_masters = []
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
    return if giveup?
    @action_game_masters = []
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
    return if giveup?
    @action_game_masters = []
    ($game_troop.alive_members + $game_party.alive_members).each{|member|
      member.turn_end_skill.each{|obj|
        skill_interrupt(member, obj[:id]) if rand < obj[:per]
      }
    }
  end  
  #--------------------------------------------------------------------------
  # ○ 獲得した経験値の表示
  #--------------------------------------------------------------------------
  def display_exp
    if $game_troop.exp_total > 0
      text = sprintf(Vocab::ObtainExp, $game_troop.exp_total)
      $game_message.add('\.' + text)
    end
    if $game_troop.class_exp_total > 0
      text2 = sprintf(Vocab::ObtainJobExp, $game_troop.class_exp_total)
      $game_message.add('\.' + text2)
    end
  end
  #--------------------------------------------------------------------------
  # ○ 経験値の獲得とレベルアップの表示
  #--------------------------------------------------------------------------
  def gain_exp
    $game_party.all_members.each { |actor|
      actor.gain_exp($game_troop.exp_total, $game_troop.class_exp_total)
    }
    wait_for_message
  end
end







