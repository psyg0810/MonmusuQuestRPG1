
=begin

もんむす・くえすと！ＲＰＧ
　トリス修正S  ver8  2015/07/04



機能一覧　説明は下　このverで新規追加したものは●　変更したものは○　削除は×
・転職画面で「パーティか城待機のメンバー」のいずれかが転職可能なら？？？にしない
・転職画面の右側の要求職業を、転職可否とマスター状況によって表示を変更
・図鑑から「いずれかのキャラで転職可能」な職業/種族を確認（収集率には含めない）
・スキル/アイテム使用時の「得TP」で対象者のTPチャージ率を適用していたのを修正
・全体攻撃での２回目以降の効果適用時は「得TP」の増加を行わないように
・効果範囲が「なし」でも「得TP」の増加を行うように
・「得TP」の増加時、コンソールに情報を表示
・降参して戦闘終了すると、ルカ以外の能力強化/弱体が解けなかったのを修正
・戦闘中でない場合とイベント中は「ターン終了時スキル」などを発動しないよう修正
・味方全体（戦闘不能）で使用者を対象から外すスキル/アイテム <特殊使用者除外>
●対象の防御壁を消すスキル/アイテム <防御壁無効化>


機能　説明
・転職画面の右側の要求職業を、転職可否とマスター状況によって表示を変更
　全員が転職不可能：灰色で？？？
　自身が転職不可能：灰色で職業名
　転職可能でマスター前：青色で職業名
　転職可能でマスター後：★アイコンと青色で職業名

・全体攻撃での２回目以降の効果適用時は「得TP」の増加を行わないように
　各『発動』内で最初の「対象への効果適用処理」でのみ増加を行う
　・拡張特徴<連続発動タイプ><連続発動スキル>　スキル/アイテム<順番発動>
　　これは別個の『発動』とする
　・スキル/アイテム<連続回数>か項目「連続回数」　の複数攻撃
　　これは同一の『発動』内のものとする

・戦闘中でない場合とイベント中は「ターン終了時スキル」などを発動しないよう修正
　対象スキルは「戦闘開始時スキル」「ターン開始時スキル」「ターン終了時スキル」
　戦闘中でない場合とは「バトルの中断」「BattleManager.process_defeat」の実行後
　ターン終了時のバトルイベント内で上記コマンドによって「戦闘中でなく」なり、
　　その後の「ターン終了時スキル」の確率判定に成功するとフリーズした

・味方全体（戦闘不能）で使用者を対象から外すスキル/アイテム <特殊使用者除外>
スキル/アイテムのメモ欄で <特殊使用者除外> と記述すると、使用者が対象から外れる
使用者を外すのは「効果適用時」なので
　・「味方単体」の対象選択ウィンドウでは使用者を選択可能
　・ランダム対象では使用者が選ばれる可能性あり（除外される分、対象数が減る）
となる
<順番発動><ランダム発動>スキルでは、実際に効果適用する個々のスキルに記述
味方全体（戦闘不能）以外では「ターゲット拡張_102」の機能で使用者除外が可能

●対象の防御壁を消すスキル/アイテム <防御壁無効化>
スキル/アイテムのメモ欄で <防御壁無効化> と記述すると
命中時に対象の防御壁を全て消す
ダメージとこの効果が両方ある場合、先に防御壁を消してからダメージを与える


=end

#==============================================================================
# ■ Scene_JobChange
#==============================================================================
class Scene_JobChange < Scene_MenuBase
  #--------------------------------------------------------------------------
  # ● 開始処理
  #--------------------------------------------------------------------------
  def start
    super
    check_class_show_enable
    create_all_window
    @change_class_type_id = -1
    @change_class_actor_id = -1
  end
  #--------------------------------------------------------------------------
  # ● 表示可否の事前チェック
  #--------------------------------------------------------------------------
  def check_class_show_enable
    Foo::JobChange::ShowChecker.new.check_class_show_enable
  end
end
#==============================================================================
# ■ Foo::JobChange::Window_ClassName
#==============================================================================
class Foo::JobChange::Window_ClassName < Window_Command
  #--------------------------------------------------------------------------
  # ● 表示用クラス名の取得
  #--------------------------------------------------------------------------
  def class_name
    class_id.collect{|id|
      if class_show_enable?(id)
        [$data_classes[id].name, class_change_enable?(id)]
      else
        [unknown_name, false]
      end
    }
  end
  #--------------------------------------------------------------------------
  # ● コマンドリストの作成（オーバーライド）
  #--------------------------------------------------------------------------
  def make_command_list
    return unless @actor_id != -1 && @class_type_id != -1
    class_name.each{|name|add_command(name[0], :ok, name[1])}
  end
  #--------------------------------------------------------------------------
  # ● フレーム更新
  #--------------------------------------------------------------------------
  def update
    super
    if $TEST && active && Input.press?(:F6)
      checker = Foo::JobChange::ShowChecker
      if self.instance_of?(Foo::JobChange::Window_ClassName)
        msgbox checker.class_show_text(select_class_id, actor.name,
                                       class_change_enable?(select_class_id))
      else
        msgbox checker.class_show_text(select_class_id, nil, nil)
      end
    end
  end
end
#==============================================================================
# ■ Foo::JobChange::Window_ClassStatus
#==============================================================================
class Foo::JobChange::Window_ClassStatus < Window_Base
  #--------------------------------------------------------------------------
  # ● 不明職業の要求アイテム描画
  #--------------------------------------------------------------------------
  def draw_unknown_need_item(y)
    return y if job.need_jobchange_item.empty?
    reset_font_settings
    rect = standard_rect(y, ((job.need_jobchange_item.size + 1) / 2) + 2)
    r = Rect.new(rect.x, rect.y, rect.width, line_height)
    result = job.need_jobchange_item.all?{|item_id| $game_party.has_item?($data_items[item_id])}
    draw_text(r, NWConst::JobChange::UNKNOWN_NEED_ITEM + (result ? "います" : "いません"))
    r.y += line_height
    r.width /= 2
    job.need_jobchange_item.each_with_index{|item_id, i|
      if $game_party.has_item?($data_items[item_id])
        name = $data_items[item_id].name
        change_color(system_color)
      else
        name = unknown_name
        change_color(normal_color, false)
      end
      draw_text(r, name)
      r.x = (r.x + r.width) % rect.width
      r.y += line_height if (i % 2) == 1
    }
    
    return rect.y + rect.height
  end
  #--------------------------------------------------------------------------
  # ● 不明職業の要求経験職描画
  #--------------------------------------------------------------------------
  def draw_unknown_need_class(y)
    return y if job.need_jobchange_class.empty?
    rect = standard_rect(y, (job.need_jobchange_class.size + 1) / 2 + 2)
    r = Rect.new(rect.x, rect.y, rect.width, line_height)
    reset_font_settings
    draw_text(r, NWConst::JobChange::UNKNOWN_NEED_CLASS)
    
    ox = r.x
    oy = r.y + line_height
    r.width /= 2
    job.need_jobchange_class.each_with_index{|obj, i|
      draw_unknown_need_or_select_class(ox, oy, r, obj, i)
    }
    
    return rect.y + rect.height
  end
  #--------------------------------------------------------------------------
  # ● 不明職業の選択経験職描画
  #--------------------------------------------------------------------------
  def draw_unknown_select_class(y)
    return y if job.select_jobchange_class.empty?
    rect = standard_rect(y, (job.select_jobchange_class.size + 1) / 2 + 2)
    r = Rect.new(rect.x, rect.y, rect.width, line_height)
    reset_font_settings
    draw_text(r, NWConst::JobChange::UNKNOWN_SELECT_CLASS)
    
    ox = r.x
    oy = r.y + line_height
    r.width /= 2
    job.select_jobchange_class.each_with_index{|obj, i|
      draw_unknown_need_or_select_class(ox, oy, r, obj, i)
    }
    
    return rect.y + rect.height
  end
  #--------------------------------------------------------------------------
  # ● 経験職描画
  #--------------------------------------------------------------------------
  def draw_unknown_need_or_select_class(ox, oy, r, obj, i)
    r.x = ox + (r.width  * (i % 2))
    r.y = oy + (r.height * (i / 2))
    name = class_show_enable?(obj[:id]) ? $data_classes[obj[:id]].name : unknown_name
    color = class_change_enable?(obj[:id]) ? [system_color] : [normal_color, false]
    change_color(*color)
    class_level = actor ? actor.level_list[obj[:id]] : nil
    if !class_level.nil? && NWConst::JobChange::CLASS_MASTER_LEVEL <= class_level
      draw_icon(NWConst::JobChange::CLASS_MASTER_ICON_ID, r.x, r.y)
      r.x += 24
    end
    draw_text(r, name)
  end
end
#==============================================================================
# ■ Foo::JobChange::EnableCheck
#==============================================================================
module Foo::JobChange::EnableCheck
  #--------------------------------------------------------------------------
  # ● 職業名表示判定
  #--------------------------------------------------------------------------
  def class_show_enable?(id)
    return Foo::JobChange::ShowChecker.class_show_enable?(id)
  end
end
#==============================================================================
# ■ Foo::JobChange::ShowChecker
#==============================================================================
class Foo::JobChange::ShowChecker
  include Foo::JobChange::EnableCheck
  #--------------------------------------------------------------------------
  # ● 判定結果
  #--------------------------------------------------------------------------
  @@class_show = nil
  #--------------------------------------------------------------------------
  # ● 全ての判定対象クラスID
  #--------------------------------------------------------------------------
  def class_id
    return NWConst::Class::JOB_RANGE.to_a + NWConst::Class::TRIBE_RANGE.to_a
  end
  #--------------------------------------------------------------------------
  # ● 現在の判定対象アクター
  #--------------------------------------------------------------------------
  def actor
    @check_show_actor
  end
  #--------------------------------------------------------------------------
  # ● チェックを実行
  #--------------------------------------------------------------------------
  def check_class_show_enable
    @@class_show = []
    @@actors_num = 0
    ($game_party.all_members + $game_party.stand_members).each do |member|
      @@actors_num += 1
      @check_show_actor = member
      class_id.each do |id|
        next unless class_change_enable?(id)
        @@class_show[id] ||= []
        @@class_show[id][0] ||= 0
        @@class_show[id][0] += 1
        @@class_show[id].push(member.name)
      end
    end
    @check_show_actor = nil
  end
  #--------------------------------------------------------------------------
  # ● 表示可能か
  #--------------------------------------------------------------------------
  def self.class_show_enable?(id)
    @@class_show[id]
  end
  #--------------------------------------------------------------------------
  # ● テスト用情報テキスト
  #--------------------------------------------------------------------------
  def self.class_show_text(id, actor_name, actor_enable)
    result = ""
    (@@class_show[id] || [0]).each_with_index do |data, i|
      case i
      when 0
        text = ""
        text += (data > 0 ? $data_classes[id].name : "？？？？？？")
        if data > 0
          text += "　　#{actor_name}:転職#{ actor_enable ? "可能" : "不可能" }" if actor_name
          text += "\n\n全キャラ:#{ @@actors_num }"
          text += "　　転職可能キャラ:#{ data }"
          text += "　　転職不可能キャラ:#{ @@actors_num - data }"
          text += "\n\n転職可能キャラ:\n"
        end
        result += text
      when 1
        result += sprintf("　%s", data)
      else
        result += sprintf("、%s", data)
      end
    end
    return result
  end
end

#==============================================================================
# ■ Scene_JobShow
#==============================================================================
class Scene_JobShow < Scene_JobChange
  #--------------------------------------------------------------------------
  # ● 全ウィンドウの作成
  #--------------------------------------------------------------------------
  def create_all_window
    @change_class_type_id = $game_temp.lib_class_type_id
    create_help_window
    create_class_status_window
    create_class_name_window
    create_class_type_window
    create_result_popup_window
    
    class_type_name = ["職業", "種族"].at(@change_class_type_id)
    @help_window.text = "#{class_type_name}情報（収集率には含みません）"
    @class_status_window.show.activate
    @class_status_window.actor_id = @change_class_actor_id
    @class_type_window.show.activate
    @class_type_window.class_type_id = @change_class_type_id 
    @class_type_window.refresh
    @class_type_window.select(0)
    @class_name_window.show.activate
    @class_name_window.class_type_id = @change_class_type_id
    @class_name_window.actor_id = @change_class_actor_id
    @class_name_window.refresh
    @class_name_window.select(0)
  end
  #--------------------------------------------------------------------------
  # ● クラスステータスウィンドウの作成
  #--------------------------------------------------------------------------
  def create_class_status_window
    @class_status_window = Foo::JobChange::LibWindow_ClassStatus.new
  end
  #--------------------------------------------------------------------------
  # ● クラス選択ウィンドウの作成
  #--------------------------------------------------------------------------
  def create_class_name_window
    @class_name_window = Foo::JobChange::LibWindow_ClassName.new(@class_status_window)
    @class_name_window.set_handler(:cancel, method(:return_scene))
  end
  #--------------------------------------------------------------------------
  # ● クラスタイプ選択ウィンドウの作成
  #--------------------------------------------------------------------------
  def create_class_type_window
    @class_type_window = Foo::JobChange::Window_ClassType.new(@class_name_window)
  end
end
#==============================================================================
# ■ Game_Temp
#==============================================================================
class Game_Temp
  #--------------------------------------------------------------------------
  # ● 公開インスタンス変数
  #--------------------------------------------------------------------------
  attr_accessor :lib_class_type_id
end
#==============================================================================
# ■ Foo::JobChange::LibWindow_ClassName
#==============================================================================
class Foo::JobChange::LibWindow_ClassName < Foo::JobChange::Window_ClassName
  #--------------------------------------------------------------------------
  # ● 転職可能判定
  #--------------------------------------------------------------------------
  def class_change_enable?(id)
    return class_show_enable?(id)
  end
  #--------------------------------------------------------------------------
  # ● 項目の描画
  #--------------------------------------------------------------------------
  def draw_item(index)
    change_color(normal_color, command_enabled?(index))
    rect = item_rect_for_text(index)
    rect.width -= 24
    draw_text(rect, command_name(index), alignment)
  end
  #--------------------------------------------------------------------------
  # ● 決定ボタンが押されたときの処理
  #--------------------------------------------------------------------------
  def process_ok
  end
end
#==============================================================================
# ■ Foo::JobChange::LibWindow_ClassStatus
#==============================================================================
class Foo::JobChange::LibWindow_ClassStatus < Foo::JobChange::Window_ClassStatus
  #--------------------------------------------------------------------------
  # ● 転職可能判定
  #--------------------------------------------------------------------------
  def class_change_enable?(id)
    return class_show_enable?(id)
  end
  #--------------------------------------------------------------------------
  # ● ジョブ名の描画
  #--------------------------------------------------------------------------
  def draw_job_name(y)
    rect = standard_rect(y)
    rect.width -= 60
    reset_font_settings
    draw_text(rect, job.name)
    rect.x += rect.width
    
    return rect.y + rect.height
  end
  #--------------------------------------------------------------------------
  # ● 不明職業の種族判定描画
  #--------------------------------------------------------------------------
  def draw_unknown_different_kind(y)
    return y
  end
  #--------------------------------------------------------------------------
  # ● 現在の判定対象アクター
  #--------------------------------------------------------------------------
  def actor
    nil
  end
end
#==============================================================================
# ■ Scene_Library
#==============================================================================
class Scene_Library < Scene_MenuBase
  #--------------------------------------------------------------------------
  # ● 終了処理 図鑑/本体
  #--------------------------------------------------------------------------
  def terminate
    super
    replay_bgm_and_bgs unless SceneManager.scene_is?(Scene_CGViewer) ||
                              SceneManager.scene_is?(Scene_ActorCGViewer) ||
                              SceneManager.scene_is?(Scene_Novel) ||
                              SceneManager.scene_is?(Scene_JobShow)
  end
  #--------------------------------------------------------------------------
  # ● 左カラムウィンドウの作成
  #--------------------------------------------------------------------------
  def create_left_column_window
    @main_command_window = Window_Library_MainCommand.new
    @main_command_window.set_handler(:lib_record, method(:on_record_index))
    @main_command_window.set_handler(:lib_medal, method(:on_medal_index))
    @main_command_window.set_handler(:lib_actor,  method(:on_actor_index))
    @main_command_window.set_handler(:lib_enemy,  method(:on_enemy_index))
    @main_command_window.set_handler(:lib_weapon, method(:on_weapon_index))
    @main_command_window.set_handler(:lib_armor,  method(:on_armor_index))
    @main_command_window.set_handler(:lib_accessory,  method(:on_accessory_index))
    @main_command_window.set_handler(:lib_item,   method(:on_item_index))
    @main_command_window.set_handler(:lib_class,  method(:on_class_index))
    @main_command_window.set_handler(:lib_tribe,  method(:on_tribe_index))
    @main_command_window.set_handler(:lib_return, method(:return_index))
    @main_command_window.set_handler(:lib_close,  method(:return_scene))
    @main_command_window.set_handler(:cancel,     method(:on_command_cancel))
    @main_command_window.set_handler(:input_right, method(:on_next_page))
    @main_command_window.set_handler(:input_left,  method(:on_previous_page))
    @main_command_window.set_handler(:scrolldown,   method(:on_scroll_down))
    @main_command_window.set_handler(:scrollup,     method(:on_scroll_up))
    @main_command_window.set_handler(:on_actor,     method(:on_actor_ok))
    @main_command_window.set_handler(:on_enemy,     method(:on_enemy_ok))
    @main_command_window.index_window = @header_nav_window
    @main_command_window.contents_window = @main_contents_window      
    @main_command_window.help_window  = @footer_help_window 
  end
  #--------------------------------------------------------------------------
  # ● 職業の項
  #--------------------------------------------------------------------------
  def on_class_index
    $game_temp.lib_class_type_id = 0
    SceneManager.call(Scene_JobShow)
  end
  #--------------------------------------------------------------------------
  # ● 種族の項
  #--------------------------------------------------------------------------
  def on_tribe_index
    $game_temp.lib_class_type_id = 1
    SceneManager.call(Scene_JobShow)
  end
end
#==============================================================================
# ■ Window_Library_MainCommand
#==============================================================================
class Window_Library_MainCommand < Window_Command
  #--------------------------------------------------------------------------
  # ● コマンドリストの作成【オーバーライド】
  #--------------------------------------------------------------------------
  def make_command_list
    case @category
    when 1
      make_actor_main_command
      make_return_command
    when 2
      make_enemy_main_command
      make_return_command
    when 3
      make_weapon_main_command
      make_return_command
    when 4
      make_armor_main_command
      make_return_command
    when 5
      make_accessory_main_command
      make_return_command
    when 6
      make_item_main_command
      make_return_command
    when 7
      make_record_main_command
      make_return_command
    when 8
      make_medal_main_command
      make_return_command
    else
      make_record_index_command
      make_medal_index_command      
      make_actor_index_command
      make_enemy_index_command
      make_weapon_index_command
      make_armor_index_command
      make_accessory_index_command
      make_item_index_command
      make_class_index_command
      make_tribe_index_command
    end
    make_close_command
  end
  #--------------------------------------------------------------------------
  # ● 職業indexコマンド
  #--------------------------------------------------------------------------
  def make_class_index_command
    enable = !$game_party.temp_actors_use?
    add_command(INDEX_STRING[:lib_class], :lib_class, enable, [ 9,  90000])
  end
  #--------------------------------------------------------------------------
  # ● 種族indexコマンド
  #--------------------------------------------------------------------------
  def make_tribe_index_command
    enable = !$game_party.temp_actors_use?
    add_command(INDEX_STRING[:lib_tribe], :lib_tribe, enable, [10, 100000])
  end
end
#==============================================================================
# ■ Game_Party
#==============================================================================
class Game_Party < Game_Unit
  #--------------------------------------------------------------------------
  # ○ 全メンバーの取得
  #--------------------------------------------------------------------------
  def temp_actors_use?
    return !@temp_actors.empty?
  end
end

#==============================================================================
# ■ Game_Battler
#==============================================================================
class Game_Battler < Game_BattlerBase
  #--------------------------------------------------------------------------
  # ○ スキル／アイテムの使用者側への効果
  #--------------------------------------------------------------------------
  def item_user_effect(user, item)
    user.tp += (item.tp_gain * user.tcr).ceil
  end
end

#==============================================================================
# ■ Scene_Battle
#==============================================================================
class Scene_Battle < Scene_Base
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
        targets.delete(@subject) if item.target_reject_user?
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
          $game_temp.normal_invoke_start
          targets.each {|target| item.repeats.times { invoke_item(target, item) } }
          @subject.item_use_tp_gain(item, "なし") if targets.empty?
          item.effects.each {|effect| item_user_effect_apply(@subject, item, effect) }
          $game_temp.normal_invoke_end
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
end
#==============================================================================
# ■ Game_Temp
#==============================================================================
class Game_Temp
  #--------------------------------------------------------------------------
  # ● 公開インスタンス変数
  #--------------------------------------------------------------------------
  attr_reader   :normal_invoke_count
  #--------------------------------------------------------------------------
  # ○ 「反撃以外での効果適用」の開始
  #--------------------------------------------------------------------------
  def normal_invoke_start
    @normal_invoke_count = 0
  end
  #--------------------------------------------------------------------------
  # ○ 「反撃以外での効果適用」の得TPカウント加算
  #--------------------------------------------------------------------------
  def normal_invoke_plus_count
    @normal_invoke_count += 1 if @normal_invoke_count
  end
  #--------------------------------------------------------------------------
  # ○ 「反撃以外での効果適用」の終了
  #--------------------------------------------------------------------------
  def normal_invoke_end
    @normal_invoke_count = nil
  end
end
#==============================================================================
# ■ Game_Battler
#==============================================================================
class Game_Battler < Game_BattlerBase
  #--------------------------------------------------------------------------
  # ○ スキル／アイテムの対象への効果適用時の、使用者側への効果
  #--------------------------------------------------------------------------
  def item_user_effect(user, item)
    user.item_use_tp_gain(item, self.name)
  end
  #--------------------------------------------------------------------------
  # ○ スキル／アイテムの対象への効果適用時の、得TPの増加を行うか
  #--------------------------------------------------------------------------
  def enable_apply_tp_gain?(item)
    return true unless $game_party.in_battle                # 戦闘中ではない
    return true unless item.for_all?                        # 全体攻撃ではない
    return true unless $game_temp.normal_invoke_count       # 通常/反射ではない
    return true unless $game_temp.normal_invoke_count >= 1  # ２回目以降ではない
    # 「戦闘中、通常/反射、全体攻撃、２回目以降」を全て満たす場合、TP増加しない
    return false
  end
  #--------------------------------------------------------------------------
  # ○ スキル／アイテムの対象への効果適用時の、得TPの増加
  #--------------------------------------------------------------------------
  def item_use_tp_gain(item, target_name)
    print "＜#{name}　#{item.name}　対象者:#{target_name}"
    if enable_apply_tp_gain?(item)
      self.tp += (item.tp_gain * tcr).ceil
      $game_temp.normal_invoke_plus_count
      print "　得TP:#{item.tp_gain}　増加値:#{(item.tp_gain * tcr).ceil}＞"
    else
      print "　得TPは無効"
    end
    print "\n"
  end
end

#==============================================================================
# ■ Game_Actor
#==============================================================================
class Game_Actor < Game_Battler
  #--------------------------------------------------------------------------
  # ● 強化／弱体の全解除
  #--------------------------------------------------------------------------
  def remove_all_buffs
    clear_buffs
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
        skill_interrupt(member, obj[:id]) if rand < obj[:per]
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
        skill_interrupt(member, obj[:id]) if rand < obj[:per]
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
        skill_interrupt(member, obj[:id]) if rand < obj[:per]
      }
    }
  end
end

#==============================================================================
# ■ NWRegexp::UsableItem
#==============================================================================
module NWRegexp::UsableItem
  TARGET_REJECT_USER        = /<特殊使用者除外>/i
  ERASE_DEFENSE_WALL        = /<防御壁無効化>/i
end
#==============================================================================
# ■ RPG::UsableItem
#==============================================================================
class RPG::UsableItem < RPG::BaseItem
  #--------------------------------------------------------------------------
  # ● メモ欄解析処理
  #--------------------------------------------------------------------------
 # alias nw_kure_usable_item_note_analyze nw_note_analyze
  def nw_note_analyze
    nw_kure_usable_item_note_analyze    
    
    self.note.each_line do |line|
      if NWRegexp::UsableItem::EXT_SCOPE.match(line)
        @data_ex[:ext_scope] ||= 0x0
        @data_ex[:ext_scope] |= NWSex::LUCA if $1.include?("ルカ")
        @data_ex[:ext_scope] |= NWSex::MALE if $1.include?("男")
        @data_ex[:ext_scope] |= NWSex::FEMALE if $1.include?("女")
        @data_ex[:ext_scope] |= NWSex::ALL if $1.include?("無差別")        
      elsif NWRegexp::UsableItem::HEEL_REVERSE_IGNORE.match(line)
        @data_ex[:heel_reverse_ignore] = true
      elsif NWRegexp::UsableItem::CONSIDERATE_REVISE.match(line)
        @data_ex[:considerate_revise] = $1.to_f * 0.01
      elsif NWRegexp::UsableItem::PAY_LIFE.match(line)
        @data_ex[:pay_life?] = true
      elsif NWRegexp::UsableItem::RANDOM_INVOKE.match(line)
        @data_ex[:random_invoke] ||= []
        $1.split(/\,\s?/).each{|id| @data_ex[:random_invoke].push(id.to_i)}
      elsif NWRegexp::UsableItem::MULTI_INVOKE.match(line)
        @data_ex[:multi_invoke] ||= []
        $1.split(/\,\s?/).each{|id| @data_ex[:multi_invoke].push(id.to_i)}
      elsif NWRegexp::UsableItem::ADD_ANIME.match(line)
        @data_ex[:add_anime] = $1.to_i
      elsif NWRegexp::UsableItem::ELEMENT_EX.match(line)
        @data_ex[:element_ex] ||= []
        $1.split(/\,\s?/).each{|id| @data_ex[:element_ex].push(id.to_i)}        
      elsif NWRegexp::UsableItem::WEAPON_RATE.match(line)
        @data_ex[:weapon_rate] ||= {}
        $1.scan(/(\d+)\-(\d+)/){|a, b|
          @data_ex[:weapon_rate][a.to_i] = 1.00 + (b.to_f * 0.01)
        }
      elsif NWRegexp::UsableItem::APPLY_PHARMACOLOGY.match(line)
        @data_ex[:apply_pharmacology?] = true
      elsif NWRegexp::UsableItem::WARP_ITEM.match(line)
        @data_ex[:warp_item?] = true
      elsif NWRegexp::UsableItem::PENETRATE.match(line)
        @data_ex[:penetrate] ||= 0
        @data_ex[:penetrate] |= 0x1 unless $1.to_s.empty?
        @data_ex[:penetrate] |= 0x2 unless $2.to_s.empty?
      elsif NWRegexp::UsableItem::SLOT.match(line)
        @data_ex[:use_slot?] = true
      elsif NWRegexp::UsableItem::POKER.match(line)
        @data_ex[:use_poker?] = true
      elsif NWRegexp::UsableItem::THROW.match(line)
        @data_ex[:throw?] = true
      elsif NWRegexp::UsableItem::ADD_STEAL.match(line)
        @effects_ex.push(RPG::UsableItem::Effect.new(EFFECT_STEAL, $1.to_i))        
      elsif NWRegexp::UsableItem::ITEM_GET.match(line)
        id = []; num = []
        $1.scan(/(\d+)\-(\d+)/){|a, b| id.push(a.to_i); num.push(b.to_i)}
        @effects_ex.push(RPG::UsableItem::Effect.new(EFFECT_GET_ITEM, id.size, id, num))
      elsif NWRegexp::UsableItem::ADD_DEFENSE_WALL.match(line)
        @effects_ex.push(RPG::UsableItem::Effect.new(EFFECT_DEFENSE_WALL, $1.to_i))
      elsif NWRegexp::UsableItem::OVER_DRIVE.match(line)
        @effects_ex.push(RPG::UsableItem::Effect.new(EFFECT_OVER_DRIVE, $1.to_i))
      elsif NWRegexp::UsableItem::GAIN_EXP.match(line)
        @effects_ex.push(RPG::UsableItem::Effect.new(EFFECT_GAIN_EXP, ["基本", "職業", "種族"].index($1.to_s), $2.to_i))
      elsif NWRegexp::UsableItem::DEATH_ELEMENT.match(line)
        @effects_ex.push(RPG::UsableItem::Effect.new(EFFECT_DEATH_ELEMENT, 1, 1.0, {:id => $1.to_i, :opt => $2.nil? ? false : true}))
      elsif NWRegexp::UsableItem::DEATH_STATE.match(line)
        @effects_ex.push(RPG::UsableItem::Effect.new(EFFECT_DEATH_STATE, $2.to_i, $3.nil? ? 1.0 : $3.to_f / 100.0, {:id => $1.to_i, :opt => $4.nil? ? false : true}))
      elsif NWRegexp::UsableItem::PREDATION.match(line)
        bit = 0
        bit |= 0x1 unless $2.to_s.empty?
        bit |= 0x2 unless $3.to_s.empty?
        bit |= 0x4 unless $4.to_s.empty?
        @effects_ex.push(RPG::UsableItem::Effect.new(EFFECT_PREDATION, 0, $1.split(",").collect{|id|id.to_i}, bit))
      elsif NWRegexp::UsableItem::SELF_ENCHANT.match(line)
        @effects_ex.push(RPG::UsableItem::Effect.new(EFFECT_SELF_ENCHANT, $1.to_i, $2.nil? ? 1.0 : $2.to_f / 100.0, $3.nil? ? false : true))
      elsif NWRegexp::UsableItem::RESTORATION.match(line)
        @effects_ex.push(RPG::UsableItem::Effect.new(EFFECT_RESTORATION, $1.to_sym, $2.to_i * 0.01))
      elsif NWRegexp::UsableItem::BINDING_START.match(line)
        @data_ex[:binding_start?] = true
        @effects_ex.push(RPG::UsableItem::Effect.new(EFFECT_BINDING_START, $1.to_i, NWConst::State::UBIND, NWConst::State::TBIND))
      elsif NWRegexp::UsableItem::EBINDING_START.match(line)
        @data_ex[:binding_start?] = true
        # 使用効果は通常版と共通
        @effects_ex.push(RPG::UsableItem::Effect.new(EFFECT_BINDING_START, -1, NWConst::State::EUBIND, NWConst::State::ETBIND))
      elsif NWRegexp::UsableItem::BIND_RESIST.match(line)
        @effects_ex.push(RPG::UsableItem::Effect.new(EFFECT_BIND_RESIST, 1))
      elsif NWRegexp::UsableItem::REPEATS_EX.match(line)
        @data_ex[:repeat_ex] = $1.to_i
      elsif NWRegexp::UsableItem::TARGET_REJECT_USER.match(line)
        @data_ex[:target_reject_user?] = true
      elsif NWRegexp::UsableItem::ERASE_DEFENSE_WALL.match(line)
        @data_ex[:erase_defense_wall?] = true
      end
    end
  end
  #--------------------------------------------------------------------------
  # ○ 対象から使用者を除外する
  #--------------------------------------------------------------------------
  def target_reject_user?
    @data_ex.key?(:target_reject_user?) ? true : false
  end
  #--------------------------------------------------------------------------
  # ○ 防御壁を消す
  #--------------------------------------------------------------------------
  def erase_defense_wall?
    @data_ex.key?(:erase_defense_wall?) ? true : false
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
      if item.erase_defense_wall?
        @cnt[:defense_wall] = []
      end
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