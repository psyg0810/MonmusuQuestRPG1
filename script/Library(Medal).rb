# -*- encoding: utf-8 -*-
=begin
=実績設定

=end

#==============================================================================
# ■ NWConst::Library
#==============================================================================
module NWConst::Library  
  # メダル獲得時の効果音
  SE_GAIN_MEDAL = RPG::SE.new("Powerup", 90, 140)
  
  # 使用しないメダルID
  NO_USE_MEDAL = [
    1003,1004,1013,1014,1023,1024,1033,1034,1043,1044,
    1053,1054,1063,1064,1072,1073
  ]
  
  MEDAL_DATA = {
    # 例
#   メダルID => { ※メダルIDは1~9999に収めてください
#      :icon_id => アイコンID,
#      :title => "タイトル",
#      :description => "解説",
#      :priority => :表示優先順位,
#    },
    1 => {
      :icon_id => 193,
      :title => "ハンスさん救出",
      :description => "さらわれた村人を救出した",
      :priority => 1,
    },
    2 => {
      :icon_id => 193,
      :title => "女神イリアス降臨",
      :description => "祝福なき勇者として認められた",
      :priority => 2,
    },
    3 => {
      :icon_id => 191,
      :title => "魔王のしもべ",
      :description => "魔王アリスを仲間にした……いや、された",
      :priority => 3,
    },
    4 => {
      :icon_id => 191,
      :title => "女神のしもべ",
      :description => "女神イリアスを仲間にした……いや、された",
      :priority => 4,
    },
    5 => {
      :icon_id => 193,
      :title => "ついてきた幼馴染み",
      :description => "ソニアが強引についてきた……",
      :priority => 5,
    },
    6 => {
      :icon_id => 193,
      :title => "勇気の証",
      :description => "「勇気の証」を発見し、兵士に認められた",
      :priority => 6,
    },
    7 => {
      :icon_id => 193,
      :title => "商人救出",
      :description => "遭難した商人を無事に救出した",
      :priority => 7,
    },
    8 => {
      :icon_id => 193,
      :title => "盗賊団壊滅",
      :description => "魔物盗賊団を壊滅させ、少女達を更正させた",
      :priority => 8,
    },
    9 => {
      :icon_id => 193,
      :title => "フェニックスの尾密売事件解決",
      :description => "だまされていたフェニックス娘を保護した",
      :priority => 9,
    },
    10 => {
      :icon_id => 192,
      :title => "並行世界の旅人",
      :description => "並行世界をも旅する冒険者",
      :priority => 10,
    },
    11 => {
      :icon_id => 193,
      :title => "ハーピー達の救い主",
      :description => "ハーピー達を伝染病から解放した",
      :priority => 11,
    },
    12 => {
      :icon_id => 193,
      :title => "素性不明のメダル女王",
      :description => "初めてメダル女王に謁見した",
      :priority => 12,
    },
    13 => {
      :icon_id => 193,
      :title => "ナメクジ退治",
      :description => "ナメクジタワーでナメクジのボスを倒した",
      :priority => 13,
    },
    15 => {
      :icon_id => 192,
      :title => "父の背中を追って",
      :description => "いつか、その背中に並ぶように",
      :priority => 15,
    },
    16 => {
      :icon_id => 193,
      :title => "失踪したミカエラ",
      :description => "いったい、どこに行ってしまったのか……",
      :priority => 16,
    },
    17 => {
      :icon_id => 192,
      :title => "はじめてのセントラ大陸",
      :description => "セントラ大陸、初上陸",
      :priority => 17,
    },
    18 => {
      :icon_id => 193,
      :title => "ショタハーレム崩壊",
      :description => "洗脳されていたメイアを倒した",
      :priority => 18,
    },
    19 => {
      :icon_id => 193,
      :title => "四精霊を追って",
      :description => "正しい歴史を歩み、そして力を得るために",
      :priority => 19,
    },
    20 => {
      :icon_id => 192,
      :title => "勇者として……",
      :description => "ミカエラの遺志、その胸に刻んで",
      :priority => 20,
    },
    21 => {
      :icon_id => 193,
      :title => "機甲法王七号機",
      :description => "教会の機密を知ってしまった……",
      :priority => 21,
    },
    22 => {
      :icon_id => 193,
      :title => "ゾンビの店仕舞い",
      :description => "クロムをこらしめ、お化け屋敷騒動に幕",
      :priority => 22,
    },
    23 => {
      :icon_id => 192,
      :title => "風の精霊",
      :description => "シルフの力を手に入れた",
      :priority => 23,
    },
    24 => {
      :icon_id => 193,
      :title => "熱き正義の魂",
      :description => "いわゆる巻き込まれ型ヒーロー",
      :priority => 24,
    },
    25 => {
      :icon_id => 193,
      :title => "黒きアリスの逆襲",
      :description => "悪夢の茶会は終わらない",
      :priority => 25,
    },
    26 => {
      :icon_id => 193,
      :title => "おてんば王女の名誉回復",
      :description => "サバサを救った知られざる英雄",
      :priority => 26,
    },
    27 => {
      :icon_id => 193,
      :title => "偶像のカーテンコール",
      :description => "サキちゃん、キラッ☆",
      :priority => 27,
    },
    28 => {
      :icon_id => 193,
      :title => "魔女の晩餐",
      :description => "マギステア村の紛争を解決した",
      :priority => 28,
    },
    29 => {
      :icon_id => 192,
      :title => "土の精霊",
      :description => "ノームの力を手に入れた",
      :priority => 29,
    },
    30 => {
      :icon_id => 191,
      :title => "滅びし世界の希望を",
      :description => "ラ・クロワから受け継がれた希望を胸に",
      :priority => 30,
    },
#==============================================================================
    # 買い物金額
    1001 => {
      :icon_id => 193,
      :title => "初めてのお買い物",
      :description => "初めて店でモノを買った",
      :priority => 1001,    
    },
    1002 => {
      :icon_id => 193,
      :title => "店屋の常連",
      :description => "買い物額30,000G達成、すっかり店屋の顔なじみ",
      :priority => 1002,    
    },
    1003 => {
      :icon_id => 192,
      :title => "買い物使用額300,000G達成",
      :description => "買い物使用額300,000G達成",
      :priority => 1003,    
    },
    1004 => {
      :icon_id => 191,
      :title => "買い物使用額3,000,000G達成",
      :description => "買い物使用額3,000,000G達成",
      :priority => 1004,    
    },
    # 鍛冶利用数
    1011 => {
      :icon_id => 193,
      :title => "初めての鍛冶",
      :description => "初めて鍛冶屋でモノを作ってもらった",
      :priority => 1011,    
    },
    1012 => {
      :icon_id => 193,
      :title => "駆け出し鍛冶ヤー",
      :description => "鍛冶を50回頼み、だいぶ慣れてきた",
      :priority => 1012,    
    },
    1013 => {
      :icon_id => 192,
      :title => "鍛冶回数200回達成",
      :description => "鍛冶回数200回達成",
      :priority => 1013,    
    },
    1014 => {
      :icon_id => 191,
      :title => "鍛冶回数500回達成",
      :description => "鍛冶回数500回達成",
      :priority => 1014,    
    },
    # 転職回数
    1021 => {
      :icon_id => 193,
      :title => "初めての転職",
      :description => "初めてイリアス神殿で転職した",
      :priority => 1021,    
    },
    1022 => {
      :icon_id => 193,
      :title => "そこそこ転職ヤー",
      :description => "10回転職し、職業のなんたるかを掴んだ",
      :priority => 1022,    
    },
    1023 => {
      :icon_id => 192,
      :title => "転職回数100回達成",
      :description => "転職回数100回達成",
      :priority => 1023,    
    },
    1024 => {
      :icon_id => 191,
      :title => "転職回数500回達成",
      :description => "転職回数500回達成",
      :priority => 1024,    
    },
    # 転種回数
    1031 => {
      :icon_id => 193,
      :title => "初めての転種",
      :description => "初めてイリアス神殿で転種した",
      :priority => 1031,    
    },
    1032 => {
      :icon_id => 193,
      :title => "それなり転種ヤー",
      :description => "5回転種し、種族について分かってきた",
      :priority => 1032,    
    },
    1033 => {
      :icon_id => 192,
      :title => "転種回数50回達成",
      :description => "転種回数50回達成",
      :priority => 1033,    
    },
    1034 => {
      :icon_id => 191,
      :title => "転種回数300回達成",
      :description => "転種回数300回達成",
      :priority => 1034,    
    },
    # 戦闘回数
    1041 => {
      :icon_id => 193,
      :title => "初めてのバトル！",
      :description => "初めて敵と戦った、忘れられない思い出",
      :priority => 1041,    
    },
    1042 => {
      :icon_id => 193,
      :title => "いっぱし冒険者",
      :description => "300回のバトルをこなせば、冒険者としてなかなかだ",
      :priority => 1042,    
    },
    1043 => {
      :icon_id => 192,
      :title => "戦闘1000回達成",
      :description => "戦闘1000回達成",
      :priority => 1043,    
    },
    1044 => {
      :icon_id => 191,
      :title => "戦闘3000回達成",
      :description => "戦闘3000回達成",
      :priority => 1044,    
    },
    # 逃亡回数
    1051 => {
      :icon_id => 193,
      :title => "初めての逃亡",
      :description => "初めて敵に背中を見せた屈辱の思い出",
      :priority => 1051,    
    },
    1052 => {
      :icon_id => 193,
      :title => "自由からの逃走",
      :description => "10回逃走し、逃げるのにも慣れてきた",
      :priority => 1052,    
    },
    1053 => {
      :icon_id => 192,
      :title => "逃亡50回達成",
      :description => "逃亡50回達成",
      :priority => 1053,    
    },
    1054 => {
      :icon_id => 191,
      :title => "逃亡150回達成",
      :description => "逃亡150回達成",
      :priority => 1054,    
    },
    # 敗北回数
    1061 => {
      :icon_id => 193,
      :title => "初めての敗北",
      :description => "敵に敗北し、ご褒美……いや、辱めを受けた",
      :priority => 1061,    
    },
    1062 => {
      :icon_id => 193,
      :title => "冒険する餌",
      :description => "30回敗北し、その数だけ餌食にされた",
      :priority => 1062,    
    },
    1063 => {
      :icon_id => 192,
      :title => "敗北100回達成",
      :description => "敗北100回達成",
      :priority => 1063,    
    },
    1064 => {
      :icon_id => 191,
      :title => "敗北500回達成",
      :description => "敗北500回達成",
      :priority => 1064,    
    },
    # 総撃破数
    1071 => {
      :icon_id => 193,
      :title => "魔物キラー",
      :description => "襲い来る敵500体を返り討ちにした",
      :priority => 1071,    
    },
    1072 => {
      :icon_id => 192,
      :title => "敵3000体撃破",
      :description => "敵3000体撃破",
      :priority => 1072,    
    },
    1073 => {
      :icon_id => 191,
      :title => "敵10000体撃破",
      :description => "敵10000体撃破",
      :priority => 1073,    
    },
    # 職業公開率
    1201 => {
      :icon_id => 191,
      :title => "職業100%達成",
      :description => "職業100パーセント達成",
      :priority => 1201,    
    },
    # 種族公開率
    1202 => {
      :icon_id => 191,
      :title => "種族100%達成",
      :description => "種族100パーセント達成",
      :priority => 1202,    
    },
    # キャラ図鑑コンプ率
    1301 => {
      :icon_id => 191,
      :title => "キャラ図鑑100%達成",
      :description => "キャラ図鑑100パーセント達成",
      :priority => 1301,    
    },
    # 魔物図鑑コンプ率
    1311 => {
      :icon_id => 191,
      :title => "魔物図鑑100%達成",
      :description => "魔物図鑑100パーセント達成",
      :priority => 1311,    
    },
    # 武器図鑑コンプ率
    1321 => {
      :icon_id => 191,
      :title => "武器図鑑100%達成",
      :description => "武器図鑑100パーセント達成",
      :priority => 1321,    
    },
    # 防具図鑑コンプ率
    1331 => {
      :icon_id => 191,
      :title => "防具図鑑100%達成",
      :description => "防具図鑑100パーセント達成",
      :priority => 1331,    
    },
    # アクセサリ図鑑コンプ率
    1341 => {
      :icon_id => 191,
      :title => "アクセサリ図鑑100%達成",
      :description => "アクセサリ図鑑100パーセント達成",
      :priority => 1341,    
    },
    # アイテム図鑑コンプ率
    1351 => {
      :icon_id => 191,
      :title => "アイテム図鑑100%達成",
      :description => "アイテム図鑑100パーセント達成",
      :priority => 1351,    
    },
#==============================================================================
    1401 => {
      :icon_id => 193,
      :title => "メダルビギナー",
      :description => "小さなメダルを集め始めたばかり",
      :priority => 1401,    
    },
    1402 => {
      :icon_id => 193,
      :title => "メダルコレクター",
      :description => "メダル女王様に名を覚えてもらった",
      :priority => 1402,    
    },
    1411 => {
      :icon_id => 193,
      :title => "BF初勝利",
      :description => "初めてバトルファックで勝利した",
      :priority => 1411,    
    },
    1412 => {
      :icon_id => 193,
      :title => "一人前バトルファッカー",
      :description => "15人のバトルファッカーを破った",
      :priority => 1412,    
    },
    1421 => {
      :icon_id => 193,
      :title => "BF初敗北",
      :description => "初めてバトルファックで敗北した",
      :priority => 1421,    
    },
    1422 => {
      :icon_id => 193,
      :title => "無様な敗者",
      :description => "バトルファックに30回敗北した",
      :priority => 1422,    
    },
    1501 => {
      :icon_id => 193,
      :title => "ヴァニラの小さなお店",
      :description => "薬草が扱えて、初めて道具屋だ",
      :priority => 1501,    
    },
    1502 => {
      :icon_id => 193,
      :title => "そこそこのお店",
      :description => "個人規模の道具屋として十分だ",
      :priority => 1502,    
    },
    1503 => {
      :icon_id => 192,
      :title => "一人前のお店",
      :description => "セントラ大陸でもやっていける品揃えだ",
      :priority => 1503,    
    },
    1511 => {
      :icon_id => 193,
      :title => "パピの鍛冶屋",
      :description => "鍛冶屋として、なかなかの一歩",
      :priority => 1511,    
    },
    1512 => {
      :icon_id => 192,
      :title => "一流の鍛冶屋",
      :description => "遠くからもお客が来るレベルだ",
      :priority => 1512,    
    },
#==============================================================================
    2000 => {
      :icon_id => 193,
      :title => "フリーダム",
      :description => "冒険は自由であるものだ",
      :priority => 2000,
    },
    2001 => {
      :icon_id => 192,
      :title => "ストライクフリーダム",
      :description => "ルカ、心のままに",
      :priority => 2001,
    },
    2005 => {
      :icon_id => 192,
      :title => "ネロ必死だな",
      :description => "通りすがりは大失敗したようだ",
      :priority => 2005,
    },
    2006 => {
      :icon_id => 193,
      :title => "アミラ斬殺",
      :description => "どうせ何事もなかったように復活する",
      :priority => 2006,
    },
    2007 => {
      :icon_id => 191,
      :title => "ブルジョアジー",
      :description => "超豪華宿に泊まり、金持ち気分を満喫した",
      :priority => 2007,
    },
    2008 => {
      :icon_id => 193,
      :title => "魔女狩りの村のコウモリ",
      :description => "あなたはいつでもキョロキョロ",
      :priority => 2008,
    },
    2009 => {
      :icon_id => 193,
      :title => "犬娘の悟り",
      :description => "悟りを開いても、骨付き肉は大好き",
      :priority => 2009,
    },
    2010 => {
      :icon_id => 193,
      :title => "羊をめぐる冒険",
      :description => "世界の酒場で目撃される酔っ払い羊",
      :priority => 2010,
    },
    2011 => {
      :icon_id => 193,
      :title => "仲良し二人",
      :description => "ヌルコとノームは友情を感じている……",
      :priority => 2011,
    },
    2012 => {
      :icon_id => 191,
      :title => "スロットマスター",
      :description => "スロットで777を出した",
      :priority => 2012,
    },
    2013 => {
      :icon_id => 191,
      :title => "バトル・イン・777",
      :description => "戦闘中に777を出した",
      :priority => 2013,
    },
    2014 => {
      :icon_id => 191,
      :title => "ポーカーマスター",
      :description => "ポーカーでRSFを出した",
      :priority => 2014,
    },
    2015 => {
      :icon_id => 191,
      :title => "バトル・イン・RSF",
      :description => "戦闘中にRSFを出した",
      :priority => 2015,
    },
    2016 => {
      :icon_id => 193,
      :title => "なぐりあい宇宙",
      :description => "君は、星の涙を見る",
      :priority => 2016,
    },
    2017 => {
      :icon_id => 193,
      :title => "重力に挑む小悪魔",
      :description => "身投げインプの噂があるようだ……",
      :priority => 2017,
    },
    2018 => {
      :icon_id => 193,
      :title => "ちぃぱっぱ",
      :description => "あたまのおはながちぃぱっぱ",
      :priority => 2018,
    },


    2020 => {
      :icon_id => 193,
      :title => "私を探して……",
      :description => "町に潜んでいるアミラを発見した",
      :priority => 2020,
    },
    2021 => {
      :icon_id => 192,
      :title => "15番目のアミラ",
      :description => "15匹のアミラを発見した",
      :priority => 2021,
    },
    2031 => {
      :icon_id => 193,
      :title => "パンツの第一歩",
      :description => "パンツ先生に初めてパンツを見せた",
      :priority => 2031,
    },
    2032 => {
      :icon_id => 192,
      :title => "パンツコレクター",
      :description => "パンツ先生に50枚のパンツを見せた",
      :priority => 2032,
    },
    2039 => {
      :icon_id => 191,
      :title => "パンツ先生死去",
      :description => "その死に世界中の変態が涙した",
      :priority => 2039,
    },

#==============================================================================
    3001 => {
      :icon_id => 191,
      :title => "天使殺し殺し",
      :description => "鎧の狂戦士を倒した",
      :priority => 3001,
    },
    3002 => {
      :icon_id => 192,
      :title => "七転び八起き",
      :description => "七尾を倒した",
      :priority => 3002,
    },
    3003 => {
      :icon_id => 192,
      :title => "なぞなぞ嫌い",
      :description => "スフィンクスを倒した",
      :priority => 3003,
    },
    3004 => {
      :icon_id => 192,
      :title => "魔王退治？",
      :description => "冥府アリスを倒した",
      :priority => 3004,
    },
    3005 => {
      :icon_id => 191,
      :title => "死に打ち勝った者",
      :description => "死神を倒した",
      :priority => 3005,
    },
    3100 => {
      :icon_id => 193,
      :title => "迷宮チャレンジャー",
      :description => "混沌の迷宮10階層に辿り着いた",
      :priority => 3100,
    },
    3101 => {
      :icon_id => 192,
      :title => "迷宮エキスパート",
      :description => "混沌の迷宮50階層に辿り着いた",
      :priority => 3101,
    },
    3102 => {
      :icon_id => 191,
      :title => "迷宮マスター",
      :description => "混沌の迷宮100階層に辿り着いた",
      :priority => 3102,
    },
    3103 => {
      :icon_id => 191,
      :title => "迷宮ゴッド",
      :description => "混沌の迷宮200階層に辿り着いた",
      :priority => 3103,
    },
  }
end

