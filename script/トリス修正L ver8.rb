
=begin

もんむす・くえすと！ＲＰＧ
　トリス修正L  ver8  2015/03/31



機能一覧　説明は下　このverで新規追加したものは●　変更したものは○
・Graphics/System/PokerTrump.pngがないとエラーになるのを修正
・スロットのファンファーレを役ごとに追加
・ポーカーのファンファーレを役ごとに変更
・スロットとポーカーの効果音の音量調整
・スロットのチェリーのメッセージ統一
・スロットとポーカーの役によってメダル獲得
・メモに<自動戦闘不可>とあるスキルを自動戦闘アクターは使用しない
・永久拘束されている時に「なすがまま」を使うとエラーになるのを修正
・テストプレイでないと"errors.txt"が生成されないのを修正
○エラーメッセージ表示と"errors.txt"の先頭にパッチのバージョン名を追加
・スキルの<習得不可 A,B,...>を<習得不可> にして、ID指定は「IDReserve.rb」で

機能　説明

・Graphics/System/PokerTrump.pngがないとエラーになるのを修正
これは追加スクリプトだけでは対処できず、
　元スクリプト「【CACAO】ポーカー」を変更する必要があります。
　元スクリプトの更新時は、以下の変更を忘れずに行ってください。
変更内容：714～715行目をコメントアウト（行頭に # を付けて無効化）

・スロットのファンファーレを役ごとに追加
SE_WIN1（チェリー）の役が１ゲームで複数個当たった場合、
１個目の表示時のみ効果音を鳴らし、２個目以降は鳴らさない

・スキルの<習得不可 A,B,...>を<習得不可> にして、ID指定は「IDReserve.rb」で
アクターIDは IDReserve.rb の NOT_LEARN_ACTORS で指定
以前の<習得不可 A,B,...>も有効だがA,B,...は意味がなく NOT_LEARN_ACTORS を使用

=end

# 設定項目
module NWConst::Casino
  
  # 結果表示時の効果音　[ファイル名, ウェイト時間, BGM停止(trueかfalse)]
  #   BGM停止がtrueだと、再生開始時からウェイト終了時までBGMを止める
  
  # 役なし（通常時スロットでは鳴らない）
  SE_LOSE = ["Down1",         15, false]
  # ワンペア～ツーペア　　　　　　チェリー
  SE_WIN1 = ["mon_fanfale" ,  80, false]
  # スリーカード～フルハウス　　　プラム　ベル
  SE_WIN2 = ["mon_fanfale2", 120, false]
  # フォーカード～ファイブカード　スイカ　ＢＡＲ
  SE_WIN3 = ["mon_fanfale3", 330,  true]
  # ロイヤルストレートフラッシュ　７７７
  SE_WIN4 = ["mon_fanfale4", 750,  true]
  
  
  # 上記以外の効果音の音量
  VOLUME_SLOT_COIN   = 100   # スロットのコイン増減の効果音"Coin"
  VOLUME_POKER_OTHER = 100   # ポーカーの「娯楽/ポーカー改造」101行目以降の効果音
                              # （SOUND_WINとSOUND_LOSEを除く）
  
  # 役による獲得メダルID　[通常時, 戦闘時]
  MEDAL_SLOT  = [2012, 2013]  # スロット　７７７
  MEDAL_POKER = [2014, 2015]  # ポーカー　ロイヤルストレートフラッシュ
  
end
# 設定項目ここまで


#==============================================================================
# ■ CasinoManager
#==============================================================================
class << CasinoManager
  #--------------------------------------------------------------------------
  # ● メダル獲得
  #--------------------------------------------------------------------------
  def process_medal(type, param, index)
    case type
    when :poker
      $game_library.gain_medal(NWConst::Casino::MEDAL_POKER[index]) if param == 10
    when :slot
      $game_library.gain_medal(param[index]) if param
    end
  end
  #--------------------------------------------------------------------------
  # ● 結果表示の効果音
  #--------------------------------------------------------------------------
  def process_sound(type, param, wait_method)
    case type
    when :poker
      sound = 
        case param
        when 0;     NWConst::Casino::SE_LOSE
        when 1..2;  NWConst::Casino::SE_WIN1
        when 3..6;  NWConst::Casino::SE_WIN2
        when 7..9;  NWConst::Casino::SE_WIN3
        when 10;    NWConst::Casino::SE_WIN4
        end
    when :slot
      sound = param
    end
    if sound
      $game_system.save_bgm if sound[2]
      Audio.bgm_stop if sound[2]
      Audio.se_play("Audio/SE/" + sound[0])
      wait_method.call(sound[1])
      $game_system.replay_bgm if sound[2]
    end
  end
end

#==============================================================================
# ■ Scene_Poker
#==============================================================================
class Scene_Poker < Scene_MenuBase
  #--------------------------------------------------------------------------
  # ● 勝利の表示　toris
  #--------------------------------------------------------------------------
  def show_mes_win
    show_mes_result(true)
  end
  #--------------------------------------------------------------------------
  # ● 敗北の表示　toris
  #--------------------------------------------------------------------------
  def show_mes_lose
    show_mes_result(false)
  end
  #--------------------------------------------------------------------------
  # ● 結果の表示　toris
  #--------------------------------------------------------------------------
  def show_mes_result(win)
    if win
      CAO::Poker.gain_coin(@hands_window.prize)
      @coin_window.refresh
      @message_window.set_text(CAO::Poker::VOCAB_WIN % @hands_window.prize)
    else
      @message_window.set_text(CAO::Poker::VOCAB_LOSE % @hands_window.prize)
    end
    @message_window.arrows_visible = false
    @message_window.open.deactivate
    CasinoManager.process_sound(:poker, @hands_window.index, method(:abs_wait))
    CasinoManager.process_medal(:poker, @hands_window.index, 0)
    @message_window.arrows_visible = true
    @message_window.activate
  end
  #--------------------------------------------------------------------------
  # ● フレーム更新（ウェイト用） toris
  #--------------------------------------------------------------------------
  def abs_wait(duration)
    duration.times { update_basic }
  end
end
#==============================================================================
# ■ Window_PokerMessage
#==============================================================================
class Window_PokerMessage < Window_Base
  #--------------------------------------------------------------------------
  # ● ウィンドウ内容の高さを計算 toris
  #--------------------------------------------------------------------------
  def contents_height
    super + 1
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
    60.times do
      update_basic
      @battlepoker_spriteset.update
    end
    sound = 
      case @battlepoker_hands_window.index
      when 0;     NWConst::Casino::SE_LOSE
      when 1..2;  NWConst::Casino::SE_WIN1
      when 3..6;  NWConst::Casino::SE_WIN2
      when 7..9;  NWConst::Casino::SE_WIN3
      when 10;    NWConst::Casino::SE_WIN4
      end
    CasinoManager.process_sound(:poker, @battlepoker_hands_window.index, method(:abs_wait))
    CasinoManager.process_medal(:poker, @battlepoker_hands_window.index, 1)
    
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
# ■ NWConst::Slot
#==============================================================================
module NWConst::Slot
  # 役　娯楽/スロット 27
  BONUS = {
    [-1, -1, -1] => {
      :desc  => "表示する予定はありません",
      :scale => 0,
      :sound => NWConst::Casino::SE_LOSE,
      :skill_id => 3270,
      :medal => nil,
    },  
    [0, -1, -1] => {
      :desc  => "チェリーです",
      :scale => 1,
      :sound => NWConst::Casino::SE_WIN1,
      :skill_id => 3270,
      :medal => nil,
    },  
    [0, 0, -1] => {
      :desc  => "チェリーです",
      :scale => 2,
      :sound => NWConst::Casino::SE_WIN1,
      :skill_id => 3270,
      :medal => nil,
    },  
    [0, 0, 0] => {
      :desc  => "チェリーです",
      :scale => 5,
      :sound => NWConst::Casino::SE_WIN1,
      :skill_id => 3271,
      :medal => nil,
    },
    [1, 1, 1] => {
      :desc  => "プラムです",
      :scale => 20,
      :sound => NWConst::Casino::SE_WIN2,
      :skill_id => 3272,
      :medal => nil,
    },
    [2, 2, 2] => {
      :desc  => "ベルです",
      :scale => 50,
      :sound => NWConst::Casino::SE_WIN2,
      :skill_id => 3273,
      :medal => nil,
    },
    [3, 3, 3] => {
      :desc  => "スイカです",
      :scale => 100,
      :sound => NWConst::Casino::SE_WIN3,
      :skill_id => 3274,
      :medal => nil,
    },
    [4, 4, 4] => {
      :desc  => "ＢＡＲです",
      :scale => 200,
      :sound => NWConst::Casino::SE_WIN3,
      :skill_id => 3275,
      :medal => nil,
    },
    [5, 5, 5] => {
      :desc  => "７７７です",
      :scale => 500,
      :sound => NWConst::Casino::SE_WIN4,
      :skill_id => 3276,
      :medal => NWConst::Casino::MEDAL_SLOT,
    },
  } 
end
#==============================================================================
# ■ Game_Slot
#==============================================================================
class Game_Slot
  #--------------------------------------------------------------------------
  # ● 結果【効果音】の取得　娯楽/スロット toris 428
  #--------------------------------------------------------------------------
  def result_sound
    return @result_bonus ? NWConst::Slot::BONUS[@result_bonus][:sound] : nil
  end
  #--------------------------------------------------------------------------
  # ● 結果【メダル】の取得　娯楽/スロット toris 428
  #--------------------------------------------------------------------------
  def result_medal
    return @result_bonus ? NWConst::Slot::BONUS[@result_bonus][:medal] : nil
  end
end
#==============================================================================
# ■ Scene_CasinoBase
#==============================================================================
class Scene_CasinoBase < Scene_Base
  #--------------------------------------------------------------------------
  # ● フレーム更新（ウェイト用） toris 娯楽/基本 368
  #--------------------------------------------------------------------------
  def abs_wait(duration)
    duration.times { update_basic }
  end
end
#==============================================================================
# ■ Scene_Slot
#==============================================================================
class Scene_Slot < Scene_CasinoBase
  #--------------------------------------------------------------------------
  # ● 結果処理　娯楽/スロット 1035
  #--------------------------------------------------------------------------
  def process_result
    win1_flag = false
    CasinoManager.bet_num.times{|i|
      $game_slot.check_bonus(NWConst::Slot::LINES[i])
      next if $game_slot.result_scale == 0
      gain_coin = CasinoManager.minimum_coin * $game_slot.result_scale
      $game_party.gain_coin(gain_coin)
      desc_text  = $game_slot.result_desc
      desc_text += "\n#{gain_coin}枚獲得しました！"
      @desc_window.set_text(desc_text)
      @spriteset.set_line_number(i)
      sound = $game_slot.result_sound
      if sound == NWConst::Casino::SE_WIN1
        if win1_flag
          method(:abs_wait).call(sound[1])
          sound = nil
        end
        win1_flag = true
      end
      CasinoManager.process_sound(:slot, sound, method(:abs_wait))
      CasinoManager.process_medal(:slot, $game_slot.result_medal, 0)
    }
    @spriteset.set_line_number(nil)
    $game_slot.clear_result
    @desc_window.set_text(Help.slot_description[:stand])
    change_phase(:stand)
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
    
    abs_wait(6)
    result_skill_id = 1
    sound = NWConst::Casino::SE_LOSE
    CasinoManager.bet_num.times do |i|
      $game_slot.check_bonus(NWConst::Slot::LINES[i])
      if result_skill_id < $game_slot.result_skill_id
        sound = $game_slot.result_sound
        result_skill_id = $game_slot.result_skill_id
        @battleslot_bonus_window.select_key = $game_slot.result_bonus
        slot_spriteset.set_line_number(i)
      end
      CasinoManager.process_medal(:slot, $game_slot.result_medal, 1)
    end
    CasinoManager.process_sound(:slot, sound, method(:abs_wait))
    
    slot_spriteset.dispose
    @battleslot_bonus_window.dispose
    remove_instance_variable(:@battleslot_bonus_window)
    
    return result_skill_id
  end
end


#==============================================================================
# ■ NWConst::Casino 娯楽/基本 19
#==============================================================================
module NWConst::Casino
  COIN_SE  = RPG::SE.new("Coin", NWConst::Casino::VOLUME_SLOT_COIN)
end
#==============================================================================
# ■ Sound
#==============================================================================
module Sound
  #--------------------------------------------------------------------------
  # ● 再生メソッドの作成 娯楽/ポーカー改造 118 toris
  #--------------------------------------------------------------------------
  def self.define_poker_sound(method_name, file_name)
    if file_name.empty?
      instance_eval %Q{
        def #{method_name}
        end
      }
    else
      instance_eval %Q{
        @#{method_name} = RPG::SE.new(file_name, #{NWConst::Casino::VOLUME_POKER_OTHER})
        def #{method_name}
          @#{method_name}.play
        end
      }
    end
  end
  #--------------------------------------------------------------------------
  # ● ポーカーの効果音 娯楽/ポーカー改造 120
  #--------------------------------------------------------------------------
  define_poker_sound :play_poker_start,   CAO::Poker::SOUND_START
  define_poker_sound :play_poker_bet,     CAO::Poker::SOUND_BET
  define_poker_sound :play_poker_coin,    CAO::Poker::SOUND_COIN
  define_poker_sound :play_poker_deal,    CAO::Poker::SOUND_DEAL
  define_poker_sound :play_poker_slough,  CAO::Poker::SOUND_SLOUGH
  define_poker_sound :play_poker_reverse, CAO::Poker::SOUND_REVERSE
  define_poker_sound :play_poker_change,  CAO::Poker::SOUND_CHANGE
end

#==============================================================================
# ■ Game_Actor
#==============================================================================
class Game_Actor
  #--------------------------------------------------------------------------
  # ● 自動戦闘用の行動候補リストを作成 ベース/GameObject 2124 toris
  #--------------------------------------------------------------------------
  def make_action_list
    list = []
    list.push(Game_Action.new(self).set_attack.evaluate)
    usable_skills.each do |skill|
      list.push(Game_Action.new(self).set_skill(skill.id).evaluate)
    end
    list.delete_if {|action| action.item.no_auto_battle? }
    list.push(Game_Action.new(self).set_attack.evaluate) if list.empty?
    list
  end
end
#==============================================================================
# ■ NWRegexp::Skill ベース/DataObject 203
#==============================================================================
module NWRegexp::Skill
  NOT_LEARN_ACTORS          = /<習得不可>/i
  NOT_LEARN_ACTORS_SET      = /<習得不可\s?((?:\d+(?:\,\s?)?)+)>/i
  NO_AUTO_BATTLE            = /<自動戦闘不可>/i
end
#==============================================================================
# ■ RPG::Skill
#==============================================================================
class RPG::Skill < RPG::UsableItem
  #--------------------------------------------------------------------------
  # ● メモ欄解析処理 ベース/DataObject 1076
  #--------------------------------------------------------------------------
  def nw_note_analyze
    nw_kure_skill_note_analyze
    
    self.note.each_line do |line|
      if NWRegexp::Skill::HP_COST_EX.match(line)
        @data_ex[:hp_cost_ex] = {}
        @data_ex[:hp_cost_ex][:data] = $3.to_i
        @data_ex[:hp_cost_ex][:abs?] = $1 ? true : false
        @data_ex[:hp_cost_ex][:max?] = $2 == "MAXHP" ? true : false
        @data_ex[:hp_cost_ex][:per?] = $4.nil? ? false : true
      elsif NWRegexp::Skill::MP_COST_EX.match(line)
        @data_ex[:mp_cost_ex] = {}
        @data_ex[:mp_cost_ex][:data] = $3.to_i
        @data_ex[:mp_cost_ex][:abs?] = $1 ? true : false
        @data_ex[:mp_cost_ex][:max?] = $2 == "MAXMP" ? true : false
        @data_ex[:mp_cost_ex][:per?] = $4.nil? ? false : true
      elsif NWRegexp::Skill::TP_COST_EX.match(line)
        @data_ex[:tp_cost_ex] = {}
        @data_ex[:tp_cost_ex][:data] = $3.to_i
        @data_ex[:tp_cost_ex][:abs?] = $1 ? true : false
        @data_ex[:tp_cost_ex][:max?] = $2 == "MAXTP" ? true : false
        @data_ex[:tp_cost_ex][:per?] = $4.nil? ? false : true
      elsif NWRegexp::Skill::GOLD_COST.match(line)
        @data_ex[:gold_cost] = $1.to_i
      elsif NWRegexp::Skill::ITEM_COST.match(line)
        @data_ex[:item_cost] ||= []
        $1.scan(/(\d+)\-(\d+)/){|a, b| @data_ex[:item_cost].push({:id => a.to_i, :num => b.to_i})}
      elsif NWRegexp::Skill::NEED_ITEM.match(line)
        @data_ex[:need_item] ||= []
        $1.split(/\,\s?/).each{|id| @data_ex[:need_item].push(id.to_i)}
      elsif NWRegexp::Skill::NEED_DUAL_WIELD.match(line)
        @data_ex[:need_dual_wield?] = true
      elsif NWRegexp::Skill::FRIEND_DRAW.match(line)
        @data_ex[:friend_draw?] = true
      elsif NWRegexp::Skill::STYPE_EX.match(line)
        @data_ex[:stype_ex] ||= []
        $1.split(/\,\s?/).each{|id| @data_ex[:stype_ex].push(id.to_i)}
      elsif NWRegexp::Skill::SKILL_HIT.match(line)
        @data_ex[:skill_hit] = $1.to_f * 0.01
      elsif NWRegexp::Skill::SKILL_HIT_FACTOR.match(line)
        @data_ex[:skill_hit_factor] = $1.to_f * 0.01
      elsif NWRegexp::Skill::NOT_LEARN_ACTORS.match(line)  
        @data_ex[:not_learn_actors] = true
      elsif NWRegexp::Skill::NOT_LEARN_ACTORS_SET.match(line)  
        @data_ex[:not_learn_actors] = true
      elsif NWRegexp::Skill::MEMORIZE_COST.match(line)
        @data_ex[:memorize_cost] = $1.to_i
      elsif NWRegexp::Skill::PASSIVE_ARMORS.match(line)
        @data_ex[:passive_armors] ||= []
        $1.split(/\,\s?/).each{|id|@data_ex[:passive_armors].push(id.to_i)}
      elsif NWRegexp::Skill::NOT_JUMBLE_MEMORIZE.match(line)
        @data_ex[:not_jumble_memorize] ||= []        
        $1.split(/\,\s?/).each{|id| @data_ex[:not_jumble_memorize].push(id.to_i)}                
      elsif NWRegexp::Enemy::LIB_NAME.match(line)
        @data_ex[:lib_name] = $1.to_s
      elsif NWRegexp::Skill::INVISIBLE.match(line)
        @data_ex[:visible?] = true
      elsif NWRegexp::Skill::RECHARGE.match(line)
        @data_ex[:recharge] = $1.to_i
      elsif NWRegexp::Skill::CYCLE.match(line)
        @data_ex[:cycle] = "($game_troop.turn_count - #{$1}) % #{$2} == 0"
      elsif NWRegexp::Skill::LONELY_UNUSED.match(line)
        @data_ex[:lonely_unused?] = true
      elsif NWRegexp::Skill::NO_AUTO_BATTLE.match(line)
        @data_ex[:no_auto_battle?] = true
      end
    end
  end
  #--------------------------------------------------------------------------
  # ● 習得不可アクターID配列
  #--------------------------------------------------------------------------
  def not_learn_actors
    @data_ex.key?(:not_learn_actors) ? NWConst::Actor::NOT_LEARN_ACTORS : []
  end
  #--------------------------------------------------------------------------
  # ● 自動戦闘不可 ベース/DataObject 1292 toris
  #--------------------------------------------------------------------------
  def no_auto_battle?
    @data_ex.key?(:no_auto_battle?) ? true : false
  end
end

#==============================================================================
# ■ Game_Battler
#==============================================================================
class Game_Battler < Game_BattlerBase
  #--------------------------------------------------------------------------
  # ● 永久拘束中に攻撃をした？ ベース/GameObject 1602
  #--------------------------------------------------------------------------
  def eternal_bind_resist?(item)
    return false unless item.is_skill?
    return false unless state?(NWConst::State::ETBIND)
    return false unless item.id != bind_resist_skill_id
    return false unless item.id != mercy_skill_id
    return true
  end
end


# ---------------------------------------------------------------------------
# ◆ モジュール ErrorLogWriter
# ---------------------------------------------------------------------------
module ErrorLogWriter
  # -------------------------------------------------------------------------
  # ◆ エラー情報を記録 ( DEBUG のみ ⇒ デバッグ以外でも)
  # -------------------------------------------------------------------------
  def self.write( errobj )
    begin
      begin
        Graphics.safe_update
      rescue SecurityHazard
      end
      sleep(0.1)
      File.open("errors.txt","a") do | file |
        file.write("*Error - " + NWPatch.ver_str(" - ") +
                  (Time.now).strftime("%Y-%m-%d %H:%M:%S (%A)") + "\n")
        file.write( "Exception : #{errobj.class}\n" )
        file.write( errobj.message )
        unless $@.nil? and $@.empty?
          backtrace = ""
          for str in $@.dup
            unless (str[ERROR_SECTION_NUM]).nil?
              extra = $RGSS_SCRIPTS.at($1.to_i).at(1)
              str.gsub!(ERROR_SECTION) { "( " + extra + " )：" } 
            end
            backtrace += str
           end
          file.write( "\ntrace:\n" + $@.inspect + "\n" )
        end
      end
    rescue Exception => errs
      raise( errs , 
      errs.message + "\n (" + (errobj.class).to_s + " )\n" + errobj.message )
    end
  end
end
module MessageBox
  # ---------------------------------------------------------------------------
  # ◆ 異常終了のメッセージを整形
  # ---------------------------------------------------------------------------
  def self.error_message_setup( errobj )
    Graphics.freeze
    begin
      Graphics.safe_update
    rescue SecurityHazard
    end
    _message = ""
    # バックトレースを記憶する
    unless $@.nil? or ($@.at(0)).nil?
      tracer =  ($@.at(0)).dup
      # バックトレースを解析する
      backtrace = ""
      i = 0
      for str in $@.dup
        unless (str[ERROR_SECTION_NUM]).nil?
          extra = $RGSS_SCRIPTS.at($1.to_i).at(1)
          str.gsub!(ERROR_SECTION) { "( " + extra + " )：" } 
        end
        backtrace += str
      end
      unless errobj.is_a?(SystemStackError)
        if rpgvxace?
          _message = errobj.message.force_encoding("UTF-8") + 
                     "\n** backtrace：\n" + backtrace
        else
          _message = errobj.message + "\n** backtrace：\n" + backtrace
        end
      end
    else
      tracer = "" # バックトレース取得失敗
      if rpgvxace?
        _message = errobj.message.force_encoding("UTF-8")
      else
        _message = errobj.message
      end
    end    
    until (_message[DOUBLE_CRLF]).nil?
      _message.gsub!(DOUBLE_CRLF){ "\n" }
    end
    _message = NWPatch.ver_name("\n") + 
               "エラー " + (errobj.class).inspect +
               " が発生したため、処理を継続できませんでした。\n" +
               "公式サイト「パッチ・サポート」に同様のバグの情報がない場合、" + 
               "報告してください。\n" + 
               "お手数をおかけして申し訳ありません。\n" +
               "\n" + 
               "詳細情報：\n" +
               _message
    return _message, tracer
  end
end