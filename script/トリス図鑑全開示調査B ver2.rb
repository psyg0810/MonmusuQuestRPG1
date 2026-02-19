
=begin

もんむす・くえすと！ＲＰＧ
　トリス図鑑全開示調査B  ver2  2015/02/11



ゲーム中、各フレームごとに
　「そのフレームでの図鑑フラグ操作の回数」と「その操作内容」をコンソールに表示
　また一定個数以上の操作されたフレームがあれば、
　　メッセージボックスとlibrary_check.txtに出力


表示内容は
①  図鑑フラグ操作  (ニューゲームからの経過フレーム数)フレーム  (操作個数)個
②  (操作フラグ種類)  (カテゴリ)  (ID)番

例：表示内容が
　　　    図鑑フラグ操作が発生しました  現在プレイ時間:10フレーム  操作数:2個
   　     :set_had  :weapon  1番
　　　    :set_had  :armor  1番
　　の場合
　　　プレイ時間10フレームの時点で、2個のフラグ操作が発生
　　　・武器1番の所有フラグをオン
　　　・防具1番の所有フラグをオン
　　を表す


表示内容の「操作フラグ種類」は以下の４つ
　:set_discovery　発見フラグオン
　:set_had　所有フラグと発見フラグオン
　:clear_discovery　発見フラグと所有フラグオフ
　:clear_had　所有フラグオフ

※チェックすべきフラグ操作(設定項目 FLAG_ONLY_NEW 参照)があればコンソール表示

※フラグオフはイベントスクリプト(all_clear_xxx_hadなど)以外では行われないはず

※敵の図鑑フラグ操作を行うのは、戦闘開始時ではなく戦闘終了時

=end

module LibraryFlagCheck
  
  # この機能でチェックするフラグ操作
  #   true: 現在のフラグ状態を変化させるフラグ操作
  #         （まだ入手していないアイテムを入手した場合などのみチェックする）
  #  false: 全てのフラグ操作
  #         （すでに入手済みのアイテムを入手した場合などでもチェックする）
  FLAG_ONLY_NEW = true
  
  # １フレームの間に「この個数以上の表示」があった場合、
  #   コンソール表示だけではなく
  #   ・メッセージボックスを出して表示内容①を通知する
  #   　（メッセージボックス：ゲームウインドウとは別のウインドウ）
  #   ・コンソールに表示した内容を library_check.txt に保存する
  FLAG_MSG_BOX_SIZE = 100
  
  
  # 上記 FLAG_MSG_BOX_SIZE によるメッセージボックスを、
  #   テストプレイ中だけでなく通常プレイ中でも表示するか
  # true:表示する　false:表示しない
  # （テストプレイヤーに調査してもらう場合は、この機能を使ってください）
  NORMAL_SHOW_BOX = true
  
  # 上記 NORMAL_SHOW_BOX によって通常プレイ中に表示した場合の追加メッセージ
  # "\n"の部分が改行になる 
  NORMAL_SHOW_MESSAGE = "上記の個数と現在の状況（マップ、会話中のイベント、戦闘の相手など）を報告してください\nまたlibrary_check.txtを保存するのでそれを添付してください"
  
end

#==============================================================================
# ■ Flag_Library
#==============================================================================
class Flag_Library
  #--------------------------------------------------------------------------
  # ● 発見済みの設定
  #--------------------------------------------------------------------------
  def set_discovery(*args)
    args.flatten.each do |id| 
      next unless id.is_a?(Integer)
      next if id < 0
      show_control(:set_discovery, id, !discovery?(id))
      set_flag(id, 0b01) 
    end
  end
  #--------------------------------------------------------------------------
  # ● 所有済みの設定 (発見済みフラグも同時に立てる)
  #--------------------------------------------------------------------------
  def set_had(*args)
    args.flatten.each do |id| 
      next unless id.is_a?(Integer)
      next if id < 0
      show_control(:set_had, id, !had?(id))
      set_flag(id, 0b11) 
    end
  end
  #--------------------------------------------------------------------------
  # ● 発見済みのクリア (所有済みフラグも同時に削除)
  #--------------------------------------------------------------------------
  def clear_discovery(*args)
    args.flatten.each do |id| 
      next unless id.is_a?(Integer)
      next if id < 0
      show_control(:clear_discovery, id, discovery?(id))
      clear_flag(id, 0b11) 
    end
  end
  #--------------------------------------------------------------------------
  # ● 所有済みのクリア (所有済みフラグのみ削除)
  #--------------------------------------------------------------------------
  def clear_had(*args)
    args.flatten.each do |id| 
      next unless id.is_a?(Integer)
      next if id < 0
      show_control(:clear_had, id, had?(id))
      clear_flag(id, 0b10)
    end
  end
  #--------------------------------------------------------------------------
  # ○ 自身のカテゴリ
  #--------------------------------------------------------------------------
  def self_category
    return :actor if self == $game_library.actor
    return :enemy if self == $game_library.enemy
    return :weapon if self == $game_library.weapon
    return :armor if self == $game_library.armor
    return :accessory if self == $game_library.accessory
    return :item if self == $game_library.item
    return "カテゴリ不明(バグ)"
  end
  #--------------------------------------------------------------------------
  # ○ 表示配列に追加
  #--------------------------------------------------------------------------
  def show_control(kind, id, new_flag)
    return if LibraryFlagCheck::FLAG_ONLY_NEW and !new_flag
    $test_LibraryFlagShow ||= []
    $test_LibraryFlagShow.push [kind, self_category, id]
  end
end

#==============================================================================
# ■ Graphics
#==============================================================================
class << Graphics
  #--------------------------------------------------------------------------
  # ● フレーム更新
  #--------------------------------------------------------------------------
  alias :update_LibraryFlagShow :update
  def update
    update_LibraryFlagShow
    $test_LibraryFlagShow ||= []
    unless $test_LibraryFlagShow.empty?
      puts ""
      t1 = "※これはスクリプト「図鑑全開示調査B」によるメッセージです\n"
      t2 = "　図鑑フラグ操作が発生しました  現在プレイ時間:%dフレーム  操作数:%d個"
      t2 = sprintf(t2, Graphics.frame_count, $test_LibraryFlagShow.size)
      text = t1 + t2
      puts text
      if $test_LibraryFlagShow.size >= LibraryFlagCheck::FLAG_MSG_BOX_SIZE
        if $TEST
          msgbox (text + "\nこのウインドウを閉じた直後、コンソールに表示、およびlibrary_check.txtに保存します")
        elsif LibraryFlagCheck::NORMAL_SHOW_BOX
          msgbox (text + "\n" + LibraryFlagCheck::NORMAL_SHOW_MESSAGE)
        end
      end
      $test_LibraryFlagShow.each do |parameter|
        t = sprintf("  :%s  :%s  %d番", *parameter)
        puts t
        t2 += "\n" + t
      end
      if $test_LibraryFlagShow.size >= LibraryFlagCheck::FLAG_MSG_BOX_SIZE
        File.open("library_check.txt", "w") {|f| f.write t2 }
      end
      $test_LibraryFlagShow.clear
      puts ""
    end
  end
end