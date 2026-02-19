=begin
= 基盤システム/多重人格

複数のRPG::Actorクラスを切り替えるアクターを作ります


==更新履歴
  Date     Version Author Comment

=end

#==============================================================================
# ■ Game_Actor
#==============================================================================
class Game_Actor < Game_Battler  
  #--------------------------------------------------------------------------
  # ● 人格の変更
  #--------------------------------------------------------------------------
  def persona_change(persona_id)
    return if $data_actors[persona_id].persona_kind == :none
    @actor_id = persona_id    
    @name = actor.name
    @nickname = actor.nickname
    init_graphics
    refresh
  end
end

#==============================================================================
# ■ Game_Actors
#==============================================================================
class Game_Actors
  #--------------------------------------------------------------------------
  # ○ アクターの取得
  #--------------------------------------------------------------------------
  alias nw_persona_array []
  def [](actor_id)
    return nil unless $data_actors[actor_id]
    actor = $data_actors[actor_id]
    id = (actor.persona_kind == :sub) ? actor.original_persona_id : actor_id
    nw_persona_array(id)
  end
end

#==============================================================================
# ■ Game_Party
#==============================================================================
# パーティに登録するアクターIDは人格アクターに統一しています
class Game_Party
  #--------------------------------------------------------------------------
  # ○ アクターを加える
  #--------------------------------------------------------------------------
  alias nw_persona_add_actor add_actor
  def add_actor(actor_id)
    return if @actors.any?{|id| $game_actors[id].id == $game_actors[actor_id].id}
    return if @stand_actors.any?{|id|$game_actors[id].id == $game_actors[actor_id].id}
    nw_persona_add_actor($game_actors[actor_id].id)
  end
  #--------------------------------------------------------------------------
  # ○ アクターを外す
  #--------------------------------------------------------------------------
  alias nw_persona_remove_actor remove_actor
  def remove_actor(actor_id)
    nw_persona_remove_actor($game_actors[actor_id].id)
  end
  #--------------------------------------------------------------------------
  # ● 変更した人格アクターがパーティに存在する場合リフレッシュ
  #--------------------------------------------------------------------------
  def refresh_persona(actor_id, persona_id)
    @actors.collect!{|id|
      ($game_actors[persona_id].id == $game_actors[id].id) ? persona_id : id
    }
    @stand_actors.collect!{|id|
      ($game_actors[persona_id].id == $game_actors[id].id) ? persona_id : id
    }
    $game_library.actor.set_had(persona_id) 
  end
end

#==============================================================================
# ■ Game_Interpreter
#==============================================================================
class Game_Interpreter
  #--------------------------------------------------------------------------
  # ● 人格の変更
  #--------------------------------------------------------------------------
  def persona_change(persona_id)
    actor = $data_actors[persona_id]
    return unless actor
    return if actor.persona_kind == :none
    actor_id = (actor.persona_kind == :original) ? persona_id : actor.original_persona_id
    $game_actors[actor_id].persona_change(persona_id)
    $game_party.refresh_persona(actor_id, persona_id)
    $game_player.refresh
  end
end

