=begin
=変数拡張




==更新履歴
  Date     Version Author Comment

=end

#==============================================================================
# ■ BattleManager
#==============================================================================
class << BattleManager
  #--------------------------------------------------------------------------
  # ○ セットアップ
  #--------------------------------------------------------------------------
  alias nw_valiable_setup setup
  def setup(troop_id, can_escape = true, can_lose = false)
    nw_valiable_setup(troop_id, can_escape, can_lose)
    $game_temp.battle_init
  end
  #--------------------------------------------------------------------------
  # ○ 戦闘終了
  #     result : 結果（0:勝利 1:逃走 2:敗北）
  #--------------------------------------------------------------------------
  alias nw_valiable_battle_end battle_end
  def battle_end(result)
    nw_valiable_battle_end(result)
    $game_temp.battle_init
  end
end
  
#==============================================================================
# ■ Game_Temp
#==============================================================================
class Game_Temp
  #--------------------------------------------------------------------------
  # ● 公開インスタンス変数
  #--------------------------------------------------------------------------
  attr_accessor :action_user
  attr_accessor :action_target
  attr_accessor :action_hit
  attr_accessor :used_skill
  attr_accessor :getup_enemy
  #--------------------------------------------------------------------------
  # ○ オブジェクト初期化
  #--------------------------------------------------------------------------
  alias nw_variable_initialize initialize
  def initialize
    nw_variable_initialize
    battle_init
  end
  #--------------------------------------------------------------------------
  # ● 戦闘用一時変数の初期化
  #--------------------------------------------------------------------------
  def battle_init
    @action_user   = nil
    @action_target = nil
    @used_skill    = nil 
    @getup_enemy   = nil
    @action_hit    = false    
  end
end

#==============================================================================
# ■ Game_Switches
#==============================================================================
class Game_Switches
  include NWConst::Sw
  #--------------------------------------------------------------------------
  # ○ スイッチの取得
  #--------------------------------------------------------------------------
  alias nw_array_get []
  def [](switch_id)
    case switch_id
    when CUT_PREDATION
      return $game_system.conf[:ls_predation]
    end    
    return nw_array_get(switch_id)
  end
end

#==============================================================================
# ■ Game_Variables
#==============================================================================
class Game_Variables
  include NWConst::Var
  #--------------------------------------------------------------------------
  # ○ 変数の設定
  #--------------------------------------------------------------------------
  alias nw_array_set []=
  def []=(variable_id, value)
    case variable_id    
    when (ENEMY_REL_BASE...(ENEMY_REL_BASE+$data_enemies.size))
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
  # ○ 変数の取得
  #--------------------------------------------------------------------------
  alias nw_array_get []
  def [](variable_id)
    case variable_id
    when ACTION_USER
      return $game_temp.action_user ? $game_temp.action_user.id : 0
    when ACTION_TARGET
      return $game_temp.action_target ? $game_temp.action_target.id : 0
    when STEPS
      return $game_party.steps
    when GOLD
      return $game_party.gold
    when USED_SKILL_ID
      return $game_temp.used_skill ? $game_temp.used_skill.id : 0
    when ACTION_HIT
      return $game_temp.action_hit ? 1 : 0
    when ACTION_TARGET_FRIEND
      return ($game_temp.action_target && $game_temp.action_target.enemy?) ? $game_temp.action_target.friend : 0
    when GET_UP
      return $game_temp.getup_enemy ? $game_temp.getup_enemy.id : 0
    when ACTION_USER_LEVEL
      return $game_temp.action_user && $game_temp.action_user.actor? ? $game_temp.action_user.base_level : 0
    when ACTION_TARGET_LEVEL
      return $game_temp.action_target && $game_temp.action_target.enemy? ? $game_temp.action_target.escape_level : 0
    when COIN
      return $game_party.coin
    when (ACTOR_REL_BASE...(ACTOR_REL_BASE+$data_actors.size))
      # 別人格でも好感度は統一
      actor = $data_actors[variable_id - ACTOR_REL_BASE]
      if actor && actor.persona_kind == :sub
        variable_id = ACTOR_REL_BASE + actor.original_persona_id
      end
    end    
    return nw_array_get(variable_id)
  end  
end

#==============================================================================
# ■ Game_Battler
#==============================================================================
class Game_Battler < Game_BattlerBase
  #--------------------------------------------------------------------------
  # ○ スキル／アイテムの効果適用
  #--------------------------------------------------------------------------
  alias nw_variable_item_apply item_apply
  def item_apply(user, item, is_cnt = false)
    $game_temp.action_target = self
    nw_variable_item_apply(user, item, is_cnt)
    $game_temp.action_hit = @result.hit?
  end
end

#==============================================================================
# ■ Scene_Battle
#==============================================================================
class Scene_Battle < Scene_Base
  #--------------------------------------------------------------------------
  # ○ スキル／アイテムの使用
  #--------------------------------------------------------------------------
  alias nw_variable_use_item use_item
  def use_item
    $game_temp.action_user   = @subject
    $game_temp.used_skill    = @subject.current_action.item    
    nw_variable_use_item
  end
end















