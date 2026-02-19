
=begin

もんむす・くえすと！ＲＰＧ
　トリス修正P  ver4  2015/03/15



機能一覧　説明は下　このverで新規追加したものは●　変更したものは○　削除は×
×暗号化時のみ、特定エネミー加入演出でエラーになったのを修正
・全滅時に死亡時スキルのコモンイベントがマップに戻ってから実行されたのを修正
・ダメージ床にならない毒沼があったのを修正


機能　説明

×暗号化時のみ、特定エネミー加入演出でエラーになったのを修正
　../ を使うファイル読み込みは暗号化アーカイブでは動作しないので、使わないように

・ダメージ床にならない毒沼があったのを修正
　マップデータには１マスごとに上層、中層、下層の３つのタイルがある
　　基本的な地面は下層
　　「タイルセット004:ダンジョン」にある毒沼は中層
　　「001:フィールド」にある毒沼は下層
　つまり004において「毒沼と地面は１マス中に共存する」仕様になっている
　そしてダメージ床は「３層の内の有効タイルの全てがダメージ床」の時のみ有効だった
　004では「毒沼はダメージ床だが、地面がダメージ床ではない」ので無効となった
　解決：ダメージ床を「３層の内の有効タイルの１つでもダメージ床」なら有効とした
　　　　なおこれはVXAceデフォルトの仕様である
　　　　なぜデフォルトの仕様から変更してあったのかは不明

=end

#~ #==============================================================================
#~ # ■ Sprite_Picture
#~ #==============================================================================
#~ class Sprite_Picture < Sprite
#~   #--------------------------------------------------------------------------
#~   # ● 転送元ビットマップの更新
#~   #--------------------------------------------------------------------------
#~   #def update_bitmap
#~     if @picture.name =~ /\.\.\/Battlers\/([\S\s]+)/
#~       self.bitmap = Cache.battler($1, 0)
#~     else
#~       self.bitmap = Cache.picture(@picture.name)
#~     end
#~   #end
#~ end

#==============================================================================
# ■ Scene_Battle
#==============================================================================
class Scene_Battle < Scene_Base
  #--------------------------------------------------------------------------
  # ● 全滅時の死亡時スキルによるコモンイベントの処理
  #--------------------------------------------------------------------------
  def process_common_event_on_defeat
    while !scene_changing?
      $game_troop.interpreter.update
      $game_troop.interpreter.setup_reserved_common_event
      wait_for_message
      wait_for_effect if $game_troop.all_dead?
      process_forced_action
      break unless $game_troop.interpreter.running?
      update_for_wait
    end
  end
end
#==============================================================================
# ■ BattleManager
#==============================================================================
class << BattleManager
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
      $game_map.interpreter.clear
      reset_player
      change_novel_scene
    end
    battle_end(2)
    return true
  end
  #--------------------------------------------------------------------------
  # ○ 敗北の処理
  #   統合時は消す
  #--------------------------------------------------------------------------
  alias nw_count_process_defeat process_defeat
  def process_defeat
    tmp = []
    $game_troop.members.each {|enemy| tmp.push(enemy.id) if enemy}
    tmp.uniq.each{|id| $game_library.count_up_enemy_victory(id)}
    $game_library.enemy.set_discovery(tmp)
    $game_library.count_up_party_lose
    $game_system.party_lose_count += 1
    nw_count_process_defeat
  end
end

#==============================================================================
# ■ Game_Map
#==============================================================================
class Game_Map
  #--------------------------------------------------------------------------
  # ○ ダメージ床判定
  #--------------------------------------------------------------------------
  def damage_floor?(x, y)
    return false unless valid?(x, y)
    layered_tiles(x, y).each{|tile_id|
      next if tile_id == 0
      return true if tileset.flags[tile_id] & 0x100 != 0
    }
    return false
  end
end