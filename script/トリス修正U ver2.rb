
=begin

もんむす・くえすと！ＲＰＧ
　トリス修正U  ver2  2015/07/28



機能一覧　説明は下　このverで新規追加したものは●　変更したものは○　削除は×
・非戦闘中に <アイテム獲得> <自己付与 ステート> が動作していなかったのを修正


=end

#==============================================================================
# ■ Scene_Battle
#==============================================================================
class Scene_Battle < Scene_Base
  #--------------------------------------------------------------------------
  # ● 対象に関係なく適用される使用効果の適用
  #--------------------------------------------------------------------------
  def item_user_effect_apply(user, item, effect)
    nil + nil
  end
  #--------------------------------------------------------------------------
  # ● 使用効果［アイテム獲得］
  #--------------------------------------------------------------------------
  def item_user_effect_get_item(user, item, effect)
    nil + nil
  end
  #--------------------------------------------------------------------------
  # ● 使用効果［自己ステート付与］
  #--------------------------------------------------------------------------
  def item_user_effect_self_enchant(user, item, effect)
    nil + nil
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
          @subject.item_one_use_apply(item, targets, self)
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
# ■ Scene_ItemBase
#==============================================================================
class Scene_ItemBase < Scene_MenuBase
  #--------------------------------------------------------------------------
  # ● アイテムの使用　デフォルトScene_ItemBase
  #--------------------------------------------------------------------------
  def use_item
    play_se_for_item
    user.use_item(item)
    use_item_to_actors
    user.item_one_use_apply(item, item_target_actors, self)
    check_common_event
    check_gameover
    @actor_window.refresh
  end
  #--------------------------------------------------------------------------
  # ○ アイテムの使用　画面/ワープ選択
  #--------------------------------------------------------------------------
  alias nw_warp_use_item use_item
  def use_item
    if item.warp_item?
      SceneManager.goto(Scene_Warp)
      SceneManager.scene.prepare(item)
    else
      nw_warp_use_item
    end
  end
end
#==============================================================================
# ■ Game_Battler
#==============================================================================
class Game_Battler < Game_BattlerBase
  #--------------------------------------------------------------------------
  # ● スキル／アイテムの「使用成功時に対象数に関わらず１度適用するもの」適用
  #--------------------------------------------------------------------------
  def item_one_use_apply(item, targets, called_scene = nil)
    self.item_use_tp_gain(item, "なし") if targets.empty? and called_scene.is_a?(Scene_Battle)
    item.effects.each {|effect| item_one_use_effect_apply(self, item, effect, called_scene) }
  end
  #--------------------------------------------------------------------------
  # ● 「使用成功時に対象数に関わらず１度適用する使用効果」の適用
  #--------------------------------------------------------------------------
  def item_one_use_effect_apply(user, item, effect, called_scene)
    user = user.observer if user.is_a?(Game_Master)
    method_table = {
      NWUsableEffect::EFFECT_GET_ITEM     => :item_one_use_effect_get_item,
      NWUsableEffect::EFFECT_SELF_ENCHANT => :item_one_use_effect_self_enchant,
    }
    method_name = method_table[effect.code]
    send(method_name, user, item, effect, called_scene) if method_name
  end
  #--------------------------------------------------------------------------
  # ● 使用効果［アイテム獲得］
  #--------------------------------------------------------------------------
  def item_one_use_effect_get_item(user, item, effect, called_scene)
    return unless user.actor?
    effect.data_id.times{|i|
      $game_party.gain_item($data_items[effect.value1[i]], effect.value2[i])
    }
  end
  #--------------------------------------------------------------------------
  # ● 使用効果［自己ステート付与］
  #--------------------------------------------------------------------------
  def item_one_use_effect_self_enchant(user, item, effect, called_scene)
    chance = effect.value1
    chance *= user.state_rate(effect.data_id) unless effect.value2
    if rand < chance
      user.add_state(effect.data_id)
      if user.state_addable?(effect.data_id) and called_scene.is_a?(Scene_Battle)
        called_scene.refresh_status
        log_window = called_scene.instance_variable_get(:@log_window)
        log_window.display_user_self_enchant(user, effect.data_id)
      end
    end
  end
end