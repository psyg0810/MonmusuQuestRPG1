
=begin

もんむす・くえすと！ＲＰＧ
　トリス戦闘回想  ver9  2015/07/04

機能一覧　説明は下　このverで新規追加したものは●　変更したものは○
○戦闘回想
・戦闘勝利メッセージを4ボタンで自動スキップするかどうかコンフィグで設定
・「メモに <スキップ不能> がある敵」が所属する敵グループとの戦闘では
　敗北時に「今回の冒険」「全ての冒険」の全滅回数を増やさない
●IDが1001～2000のエネミーは「メモに<戦闘回想不可>が入っているのと同じ扱い」に

機能　説明
・戦闘回想
　イベントコマンドのスクリプト battle_memory で開始
　魔物図鑑と同様に情報を閲覧可能　敵を選択して決定ボタンで戦闘に入る

　戦闘回想可能な敵は「勝利済み」かつ「戦闘回想不可エネミーではない」敵のみ
　　戦闘回想不可エネミー：メモに<戦闘回想不可>と入っているか、IDが1001～2000
　選択した敵を含み、かつ「全ての敵が戦闘回想可能」な敵グループからランダムに戦闘
　そのような敵グループが１つもない敵は戦闘回想を開始できない

　逃走可能
　勝利時は「経験値、お金、ドロップアイテムの獲得」「仲間加入」はしない

・戦闘勝利メッセージを4ボタンで自動スキップするかどうかコンフィグで設定
　初期状態は「スキップしない」
　①スキップしない：スキップしない（v1.03.00と同じ）
　②低速スキップ：1文字ごとに少しウェイト　および「高速スキップ」と同様にウェイト
　③高速スキップ：経験値等の表示は1行ごとにウェイト　他の表示は１ページごとにウェイト
　④瞬間スキップ：一切ウェイトしない（v1.02.01以前と同じ）


=end

#==============================================================================
# ■ Scene_Library
#==============================================================================
class Scene_Library < Scene_MenuBase
  #--------------------------------------------------------------------------
  # ● 魔物図鑑/キャラ図鑑から開始するかどうか
  #--------------------------------------------------------------------------
  def ex_window_start?
    return false if $game_temp.in_memory_battle
    return $game_temp.lib_enemy_index != -1
  end
  #--------------------------------------------------------------------------
  # ● 魔物図鑑/キャラ図鑑から開始する時のカーソル位置
  #--------------------------------------------------------------------------
  def start_index
    return $game_temp.lib_enemy_index % 10000 if $game_temp.lib_enemy_index != -1
    return 0
  end
  #--------------------------------------------------------------------------
  # ● ウィンドウの設定準備
  #--------------------------------------------------------------------------
  def window_setting
    if ex_window_start?
      $game_temp.in_memory_battle = false
      play_bgm_no_save
      @main_command_window.category = $game_temp.lib_enemy_index < 10000 ? 2 : 1
      @main_command_window.refresh
      @main_command_window.select(start_index)
      @main_command_window.activate
      $game_temp.lib_enemy_index = -1
    else
      @main_command_window.select(0)
      @main_command_window.activate
    end
  end
  #--------------------------------------------------------------------------
  # ● キャラ図鑑の決定
  #--------------------------------------------------------------------------
  def on_actor_ok
    @enemy_command_window.enemy_id = @main_contents_window.ext % 10000 + 10000
    @enemy_command_window.refresh
    @enemy_command_window.show.activate
    @enemy_command_window.select(0)
  end
  #--------------------------------------------------------------------------
  # ● 魔物図鑑の決定
  #--------------------------------------------------------------------------
  def on_enemy_ok
    @enemy_command_window.enemy_id = @main_contents_window.ext % 10000
    @enemy_command_window.refresh
    @enemy_command_window.show.activate
    @enemy_command_window.select(0)
  end
end
#==============================================================================
# ■ Scene_BattleLibrary
#==============================================================================
class Scene_BattleLibrary < Scene_Library
  #--------------------------------------------------------------------------
  # ● 魔物図鑑/キャラ図鑑から開始するかどうか
  #--------------------------------------------------------------------------
  def ex_window_start?
    true
  end
  #--------------------------------------------------------------------------
  # ● 開始処理
  #--------------------------------------------------------------------------
  def start
    super
    save_bgm
    $game_party.all_members.each {|actor| actor.recover_all }
    $game_player.refresh
  end
  #--------------------------------------------------------------------------
  # ● BGMの保存
  #--------------------------------------------------------------------------
  def save_bgm
    @prev_bgm = RPG::BGM.last
    @prev_bgs = RPG::BGS.last
  end
  #--------------------------------------------------------------------------
  # ● BGM と BGS の再開
  #--------------------------------------------------------------------------  
  def replay_bgm_and_bgs
  end
  #--------------------------------------------------------------------------
  # ● BGMの演奏　戦闘回想からの復帰用
  #--------------------------------------------------------------------------
  def play_bgm_no_save
    return unless @prev_bgm
    @prev_bgm.replay
    @prev_bgs.replay
  end
  #--------------------------------------------------------------------------
  # ● 左カラムウィンドウの作成
  #--------------------------------------------------------------------------
  def create_left_column_window
    @main_command_window = Window_BattleLibrary_MainCommand.new
    @main_command_window.set_handler(:lib_close,  method(:return_scene))
    @main_command_window.set_handler(:cancel,     method(:return_scene))
    @main_command_window.set_handler(:input_right, method(:on_next_page))
    @main_command_window.set_handler(:input_left,  method(:on_previous_page))
    @main_command_window.set_handler(:scrolldown,   method(:on_scroll_down))
    @main_command_window.set_handler(:scrollup,     method(:on_scroll_up))
    @main_command_window.set_handler(:on_enemy,     method(:on_enemy_ok))
    @main_command_window.index_window = @header_nav_window
    @main_command_window.contents_window = @main_contents_window      
    @main_command_window.help_window  = @footer_help_window
    on_enemy_index
  end
  #--------------------------------------------------------------------------
  # ● エネミー選択ウィンドウの作成
  #--------------------------------------------------------------------------
  def create_enemy_command_window
    @enemy_command_window = Window_BattleLibrary_EnemyCommand.new
    @enemy_command_window.set_handler(:memory_battle, method(:on_memory_battle))
    @enemy_command_window.set_handler(:cancel, method(:on_enemy_cancel))
  end
  #--------------------------------------------------------------------------
  # ● 魔物：戦闘回想
  #--------------------------------------------------------------------------
  def on_memory_battle
    $game_temp.in_memory_battle = true
    $game_temp.lib_enemy_index = @main_command_window.index
    troop_id = $game_temp.select_memory_battle_troop(@enemy_command_window.enemy.id)
    RPG::ME.stop
    BattleManager.setup(troop_id, true, false)
    BattleManager.save_bgm_and_bgs
    BattleManager.play_battle_bgm
    Sound.play_battle_start
    SceneManager.call(Scene_Battle)
  end
end
#==============================================================================
# ■ NWConst::Library
#----------------------------------------------------------------------------
# 図鑑に関するウィンドウにmixinして使用します。
#==============================================================================
module NWConst::Library
  #--------------------------------------------------------------------------
  # ● 定数
  #--------------------------------------------------------------------------
  INDEX_STRING = {
    :lib_top        => "図鑑",
    :lib_return     => "トップへ戻る",
    :lib_close      => "図鑑を閉じる",
    :memory_close   => "回想を終わる",
    :lib_actor      => "キャラ図鑑",
    :lib_enemy      => "魔物図鑑",
    :lib_weapon     => "武器図鑑",
    :lib_armor      => "防具図鑑",
    :lib_accessory  => "アクセサリ図鑑",
    :lib_item       => "アイテム図鑑",
    :lib_record     => "冒険の記録",
    :lib_medal      => "獲得メダル",
    :lib_class      => "職業情報",
    :lib_tribe      => "種族情報",
  }
end
#==============================================================================
# ■ Window_BattleLibrary_MainCommand
#==============================================================================
class Window_BattleLibrary_MainCommand < Window_Library_MainCommand
  #--------------------------------------------------------------------------
  # ● インデックスウィンドウの更新
  #--------------------------------------------------------------------------
  def update_index
    @index_window.set_text("#{INDEX_STRING[:lib_enemy]}(戦闘回想)\r\n収集率:" + sprintf("%3d", collect_per_enemy) + "%")
  end
  #--------------------------------------------------------------------------
  # ● トップに戻る(表示種別選択に戻る)コマンド
  #--------------------------------------------------------------------------
  def make_return_command
  end
  #--------------------------------------------------------------------------
  # ● 図鑑を閉じる(元のシーンに戻る)コマンド
  #--------------------------------------------------------------------------
  def make_close_command
    add_command(INDEX_STRING[:memory_close], :lib_close, true, [-2, -20000])
  end
end
#==============================================================================
# ■ Window_BattleLibrary_EnemyCommand
#==============================================================================
class Window_BattleLibrary_EnemyCommand < Window_Library_EnemyCommand
  #--------------------------------------------------------------------------
  # ● コマンドリストの作成
  #--------------------------------------------------------------------------
  def make_command_list
    return if disposed? or self.active
    add_command("戦闘回想",   :memory_battle, battle_memory?)
    add_command("キャンセル", :cancel, true)
    self.height = fitting_height(2) unless disposed?
  end
  #--------------------------------------------------------------------------
  # ● 回想イベントに対応している？
  #--------------------------------------------------------------------------  
  def battle_memory?
    return $game_temp.select_memory_battle_troop(enemy.id)
  end
end
#==============================================================================
# ■ Scene_Battle
#==============================================================================
class Scene_Battle < Scene_Base
  #--------------------------------------------------------------------------
  # ○ 終了処理 基盤システム/ノベルパート
  #--------------------------------------------------------------------------
  def terminate
    super
    @spriteset.dispose_enemies
    SceneManager.snapshot_for_background
    dispose_spriteset
    @info_viewport.dispose
    unless BattleManager.memory_battle?
      RPG::ME.stop
    end
  end
end
#==============================================================================
# ■ BattleManager
#==============================================================================
class << BattleManager
  #--------------------------------------------------------------------------
  # ○ 戦闘回想かどうか
  #--------------------------------------------------------------------------
  def memory_battle?
    $game_temp.in_memory_battle
  end
  #--------------------------------------------------------------------------
  # ○ 敗北カウントを行うか
  #--------------------------------------------------------------------------
  def enable_party_lose_count?
    $game_troop.members.each do |enemy|
      return false if enemy.enemy.no_lose_skip?
    end
    return true
  end
  #--------------------------------------------------------------------------
  # ○ 勝利の処理 
  #--------------------------------------------------------------------------
  def process_victory
    play_battle_end_me
    replay_bgm_and_bgs
    $game_temp.in_victory_message = true
    $game_message.add(sprintf(Vocab::Victory, $game_party.name))
    unless memory_battle?
      display_exp unless $game_switches[NWConst::Sw::GET_EXP_DISABLE]
      gain_gold
      gain_drop_items unless $game_switches[NWConst::Sw::GET_EXP_DISABLE]
      gain_exp unless $game_switches[NWConst::Sw::GET_EXP_DISABLE]
    end
    gain_love
    unless memory_battle?
      process_follow
    end
    if memory_battle?
      wait_for_message
    end
    $game_temp.in_victory_message = false
    SceneManager.return
    battle_end(0)
    unless memory_battle?
      DataManager.auto_save_game unless @event_proc
    end
    return true
  end
  #--------------------------------------------------------------------------
  # ○ 勝利の処理 図鑑/カウント 統合時は消す
  #--------------------------------------------------------------------------
  alias nw_count_process_victory process_victory
  def process_victory
    tmp = []
    $game_troop.members.each {|enemy| tmp.push(enemy.id) if enemy}
    $game_library.enemy.set_had(tmp) 
    $game_library.unlock_lib_enemy
    nw_count_process_victory
  end
  #--------------------------------------------------------------------------
  # ○ 敗北の処理 ベース/Module
  #--------------------------------------------------------------------------
  def process_defeat
    if $game_temp.common_event_reserved?
      SceneManager.scene.process_common_event_on_defeat
    end
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
      unless memory_battle?
        $game_map.interpreter.clear
        reset_player
      end
      change_novel_scene
    end
    battle_end(2)
    return true
  end
  #--------------------------------------------------------------------------
  # ○ 敗北の処理 図鑑/カウント 統合時は消す
  #--------------------------------------------------------------------------
  alias nw_count_process_defeat process_defeat
  def process_defeat
    tmp = []
    $game_troop.members.each {|enemy| tmp.push(enemy.id) if enemy}
    tmp.uniq.each{|id| $game_library.count_up_enemy_victory(id)}
    $game_library.enemy.set_discovery(tmp)
    if enable_party_lose_count?
      $game_library.count_up_party_lose
      $game_system.party_lose_count += 1
    end
    nw_count_process_defeat
  end
  #--------------------------------------------------------------------------
  # ● ノベルパートへの移行
  #--------------------------------------------------------------------------  
  def change_novel_scene
    unless memory_battle?
      SceneManager.clear
      SceneManager.push(Scene_Map)
    end
    $game_novel.setup($game_troop.lose_event_id)
    SceneManager.goto(Scene_Novel)
    
    skip_flag = $game_system.conf[:ls_skip] == 1
    skip_flag &&= $game_library.lose_event_view?($game_novel.event_id)
    check_flag = $game_system.conf[:ls_skip] == 2
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
    if no_lose_skip? and memory_battle?
      $game_novel.interpreter.memory_interruption
    elsif skip_flag || (choice == 0)
      $game_novel.interpreter.goto_ilias
    end
  end
end
#==============================================================================
# ■ RPG::Enemy
#==============================================================================
class RPG::Enemy < RPG::BaseItem
  #--------------------------------------------------------------------------
  # ○ 戦闘回想禁止
  #--------------------------------------------------------------------------
  def no_memory_battle?
    return true if @note =~ /<戦闘回想不可>/
    return true if ex_dungeon_enemy?
    return false
  end
end
#==============================================================================
# ■ Game_Temp
#==============================================================================
class Game_Temp
  #--------------------------------------------------------------------------
  # ● 公開インスタンス変数
  #--------------------------------------------------------------------------
  attr_accessor :in_memory_battle
  attr_accessor :in_victory_message
  #--------------------------------------------------------------------------
  # ○ 戦闘回想グループの初期化
  #--------------------------------------------------------------------------
  def clear_memory_battle_troop
    @memory_battle_troop = []
  end
  #--------------------------------------------------------------------------
  # ○ 戦闘回想グループの選択
  #--------------------------------------------------------------------------
  def select_memory_battle_troop(enemy_id)
    setup_memory_battle_troop(enemy_id)
    return @memory_battle_troop[enemy_id].sample
  end
  #--------------------------------------------------------------------------
  # ○ 戦闘回想グループの作成
  #--------------------------------------------------------------------------
  def setup_memory_battle_troop(enemy_id)
    @memory_battle_troop[enemy_id] ||= make_memory_battle_troop(enemy_id)
  end
  #--------------------------------------------------------------------------
  # ○ 戦闘回想グループの作成
  #--------------------------------------------------------------------------
  def make_memory_battle_troop(enemy_id)
    return [] if no_memory_battle_1(enemy_id)
    return [] if no_memory_battle_2(enemy_id)
    troops = $data_troops.compact.select do |t|
      t.members.any? {|m| m.enemy_id == enemy_id }
    end
    troops.reject! {|t| t.members.any? {|m| no_memory_battle_1(m.enemy_id) } }
    troops.reject! {|t| t.members.any? {|m| no_memory_battle_2(m.enemy_id) } }
    return troops.map {|t| t.id }
  end
  #--------------------------------------------------------------------------
  # ○ 戦闘回想不可エネミーか
  #--------------------------------------------------------------------------
  def no_memory_battle_1(enemy_id)
    $data_enemies[enemy_id].no_memory_battle? ? true : false
  end
  #--------------------------------------------------------------------------
  # ○ 戦闘回想不可エネミーか
  #--------------------------------------------------------------------------
  def no_memory_battle_2(enemy_id)
    !$data_library.enemy_had?(enemy_id)
  end
end
#==============================================================================
# ■ Game_Interpreter
#==============================================================================
class Game_Interpreter
  #--------------------------------------------------------------------------
  # ● 戦闘回想の開始
  #--------------------------------------------------------------------------  
  def battle_memory
    $game_temp.clear_memory_battle_troop
    SceneManager.call(Scene_BattleLibrary)
    wait(1)
  end
  #--------------------------------------------------------------------------
  # ● 回想なら中断
  #--------------------------------------------------------------------------
  def memory_interruption
    return if $game_temp.lib_enemy_index == -1  # 「図鑑からではない戦闘」は無効
    return if BattleManager.memory_battle?      # 「戦闘回想(図鑑)の戦闘」は無効
    # それ以外（＝図鑑からの敗北回想）の時のみ実行しイベント中断
    @index = @list.size
  end
end

#==============================================================================
# ■ Window_Config
#==============================================================================
class Window_Config < Window_Selectable
  #--------------------------------------------------------------------------
  # ● 項目のヘルプ文章を取得
  #--------------------------------------------------------------------------
  def help_text(index)
    text = CONTENTS[index][:help]
    text += "\r\n#{sub_help_text(index)}" if sub_exist?(index)
    text.gsub(/eval<(\S+)>/) { eval($1) }
  end
end
#==============================================================================
# ■ NWConst::Config
#==============================================================================
module NWConst::Config
  # 大項目のコンテンツ
  CONTENTS = [
    {:key => :window_tone,  :name => "ウィンドウ色", :sub => false,
     :help => "ウィンドウの色調設定です。"},  
    {:key => :sound_volume, :name => "音量設定", :sub => false,
     :help => "ゲーム中の音量設定です。"},
    {:key => :key_text,     :name => "ボタン説明文", :sub => true,
     :help => "表示される操作説明を変更します。\r\n←/→で選択。"},
    {:key => :map_dash,     :name => "ダッシュ反転", :sub => true,
     :help => "【マップ】歩行とダッシュを反転させる設定です。\r\n←/→で選択。"},
    {:key => :map_speed,    :name => "ダッシュ速度", :sub => true,
     :help => "【マップ】ダッシュ速度の設定です。\r\n←/→で選択。"},
    {:key => :bt_skip,      :name => "セリフ・カットイン", :sub => true,
     :help => "【戦闘】セリフとカットインの表示設定です。\r\n←/→で選択。"},
    {:key => :bt_auto,      :name => "ログ送り", :sub => true,
     :help => "【戦闘】ログの表示設定です。\r\n←/→で選択。"},
    {:key => :bt_wait,      :name => "戦闘時ウェイト", :sub => true,
     :help => "【戦闘】ウェイトの設定です。\r\n←/→で選択。"},
    {:key => :bt_result,    :name => "勝利結果スキップ", :sub => true,
     :help => "【戦闘】勝利結果の eval<Vocab.key_x>ボタン でのスキップ速度設定です。\r\n←/→で選択。"},   
    {:key => :bt_stype,     :name => "スキルタイプ表示", :sub => true,
     :help => "【戦闘】スキルタイプの表示設定です。\r\n←/→で選択。"},     
    {:key => :ls_auto,      :name => "オートモード", :sub => true,
     :help => "【敗北イベント】オートモードに関する設定です。\r\n←/→で選択。"},
    {:key => :ls_wait,      :name => "オート速度", :sub => true,
     :help => "【敗北イベント】オートモードの速度設定です。\r\n←/→で選択。"},
    {:key => :ls_predation, :name => "捕食シーンカット", :sub => true,
     :help => "【敗北イベント】捕食シーンカットの設定です。\r\n←/→で選択。"},     
    {:key => :ls_skip,      :name => "敗北イベントスキップ", :sub => true,
     :help => "敗北イベントのスキップ関連設定です。\r\n←/→で選択。"},     
    {:key => :default,      :name => "初期化", :sub => false,
     :help => "初期値に戻します。"},
    {:key => :return,       :name => "戻る", :sub => false,
     :help => "元の画面に戻ります。"},
  ]
  # 小項目のコンテンツ
  DATA = {
    :map_dash => [false, true],
    :map_speed => [0, 1, 2],
    :key_text => [:gamepad, :keyboard],
    :bt_skip => [false, true],
    :bt_auto => [false, true],
    :bt_wait => [100, 50, 25],
    :bt_result => [0, 1, 2, nil],
    :bt_stype => [false, true],
    :ls_auto => [false, true],
    :ls_wait => [10, 5, 3],
    :ls_predation => [false, true],
    :ls_skip => [0, 1, 2],
  }
  # 色調ゲージ用の色データ
  TONE_COLOR = {
    :tone_r => Color.new(255, 0, 0),
    :tone_g => Color.new(0, 255, 0),
    :tone_b => Color.new(0, 0, 255),
  }
  # 音量ゲージ用データ
  SOUND_GAUGE = {
    :volume_bgm => {:name => "BGM", :color => Color.new(255, 32, 32)},
    :volume_bgs => {:name => "BGS", :color => Color.new(255,192,  0)},
    :volume_me  => {:name => " ME", :color => Color.new(0, 192, 255)},
    :volume_se  => {:name => " SE", :color => Color.new(32, 32, 255)},
  }
  # 小項目のコンテンツ文章
  DATA_TEXT = {
    :key_text => {
      :gamepad => {:name => "ゲームパッド", :help => "ゲームパッド準拠で表示します。"},
      :keyboard => {:name => "キーボード", :help => "キーボード準拠で表示します。"},
    },
    :map_dash => {
      false => {:name => "反転させない", :help => "デフォルトで歩行状態です。"},
      true  => {:name => "反転させる", :help => "デフォルトでダッシュ状態です。"},
    },
    :map_speed => {
      0 => {:name => "基本", :help => "通常のダッシュ速度です。"},
      1 => {:name => "高速", :help => "一段階速いダッシュ速度です。"},
      2 => {:name => "最速", :help => "二段階速いダッシュ速度です。"},      
    },
    :bt_skip => {
      false => {:name => "表示", :help => "セリフとカットインを表示します。"},
      true  => {:name => "省略", :help => "セリフとカットインを省略します。"},
    },
    :bt_auto => {
      false => {:name => "手動", :help => "戦闘ログとメッセージを手動で次に送ります。"},
      true  => {:name => "自動", :help => "戦闘ログとメッセージを自動で次に送ります。"},
    },
    :bt_wait => {
      100 => {:name => "基本", :help => "戦闘中ウェイトをデフォルトにします。"},
      50 =>  {:name => "高速", :help => "戦闘中ウェイトを1/2にします。"},
      25 =>  {:name => "最速", :help => "戦闘中ウェイトを1/4にします。"},      
    },
    :bt_result => {
      0   => {:name => "スキップしない", :help => "スキップしません。"},
      1   => {:name => "低速スキップ", :help => "１文字ごとに少し待機してからスキップします。"},
      2   => {:name => "高速スキップ", :help => "行ごとかページごとに待機してからスキップします。"},
      nil => {:name => "瞬間スキップ", :help => "一瞬でスキップします。"},
    },
    :bt_stype => {
      true => {:name => "設定通り", :help => "非表示設定にしているスキルタイプを全て省略します。"},
      false  => {:name => "全表示", :help => "非表示設定にしているスキルタイプを全て表示します。"},
    },
    :ls_auto => {
      false => {:name => "オフ", :help => "オートモードをオフにしてイベント開始します。"},
      true  => {:name => "オン", :help => "オートモードをオンにしてイベント開始します。"},
    },
    :ls_wait => {
      10 => {:name => "低速", :help => "敗北イベント中ウェイトを2倍にします。"},
      5 =>  {:name => "基本", :help => "敗北イベント中ウェイトをデフォルトにします。"},
      3 =>  {:name => "高速", :help => "敗北イベント中ウェイトを1/2にします。"},      
    },
    :ls_predation => {
      false => {:name => "オフ", :help => "捕食シーンをカットしません。"},
      true  => {:name => "オン", :help => "捕食シーンをカットします。"},
    },
    :ls_skip => {
      0 => {:name => "毎回見る", :help => "毎回、敗北シーンを全て見ます。"},
      1 => {:name => "既読スキップ", :help => "一度見た敗北シーンをスキップします。"},
      2 => {:name => "毎回確認", :help => "敗北シーンを見るか事前確認します。"},
    },
  }
  # 規定値
  DEFAULT = {
    :tone_r => -34,
    :tone_g =>   0,
    :tone_b =>  68,
    :volume_bgm => 70,
    :volume_bgs => 70,
    :volume_se => 70,
    :volume_me => 70,
    :key_text => :gamepad,
    :map_dash => false,
    :map_speed => 0,
    :bt_skip => false,
    :bt_auto => false,
    :bt_wait => 100,
    :bt_result => nil,
    :bt_stype => true,
    :ls_auto => false,
    :ls_wait => 5,
    :ls_predation => false,
    :ls_skip => 0,
  }
end
#==============================================================================
# ■ Window_Message
#==============================================================================
class Window_Message < Window_Base
  #--------------------------------------------------------------------------
  # ○ スキップモード
  #--------------------------------------------------------------------------
  def message_skip_mode
    #     0: スキップしない
    #     1: 低速スキップ
    #     2: 高速スキップ
    # nil 3: 瞬間スキップ（通常時）
    return 3 if !$game_temp.in_victory_message
    return $game_system.conf[:bt_result] || 3
  end
  #--------------------------------------------------------------------------
  # ○ input_pauseのwait(10)後の文字送り入力
  #--------------------------------------------------------------------------
  def message_pause_input
    input_x = Input.trigger?(:X)
    input_x = Input.press?(:X) if message_skip_mode >= 1
    return Input.trigger?(:B) || Input.trigger?(:C) || input_x
  end
  #--------------------------------------------------------------------------
  # ○ ウェイト
  #--------------------------------------------------------------------------
  def wait(duration)
    return if Input.press?(:X) and message_skip_mode >= 3
    duration.times { Fiber.yield }
  end
  #--------------------------------------------------------------------------
  # ○ 一文字出力後のウェイト
  #--------------------------------------------------------------------------
  def wait_for_one_character
    return if Input.press?(:X) and message_skip_mode >= 2
    update_show_fast
    Fiber.yield unless @show_fast || @line_show_fast
  end
  #--------------------------------------------------------------------------
  # ○ 入力待ち処理
  #--------------------------------------------------------------------------
  def input_pause
    return if Input.press?(:X) and message_skip_mode >= 3
    self.pause = true
    wait(10)
    Fiber.yield until message_pause_input
    Input.update
    self.pause = false
  end
end