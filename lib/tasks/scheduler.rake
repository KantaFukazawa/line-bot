desc "This task is called by the Heroku scheduler add-on"
task :update_feed => :environment do
  require 'line/bot'  
  require 'open-uri'
  require 'kconv'
  require 'rexml/document'

  client ||= Line::Bot::Client.new { |config|
    config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
    config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
  }
  url  = "https://www.drk7.jp/weather/xml/13.xml"
  xml  = open( url ).read.toutf8
  doc = REXML::Document.new(xml)
  xpath = 'weatherforecast/pref/area[4]/info/rainfallchance/'
  per06to12 = doc.elements[xpath + 'period[2]'].text
  per12to18 = doc.elements[xpath + 'period[3]'].text
  per18to24 = doc.elements[xpath + 'period[4]'].text
  min_per = 20
  
  if per06to12.to_i >= min_per || per12to18.to_i >= min_per || per18to24.to_i >= min_per
    word1 =
      ["いい朝だね！",
       "今日もよく眠れた？",
       "二日酔い大丈夫？",
       "早起きしてえらいね！",
       "いつもより起きるのちょっと遅いんじゃない？"].sample
    word2 =
      ["気をつけて行ってきてね(^^)",
       "良い一日を過ごしてね(^^)",
       "雨に負けずに今日も頑張ってね(^^)",
       "今日も一日楽しんでいこうね(^^)",
       "楽しいことがありますように(^^)"].sample
    mid_per = 50

    if per06to12.to_i >= mid_per || per12to18.to_i >= mid_per || per18to24.to_i >= mid_per
      word3 = "今日は雨が降りそうだから傘を忘れないでね！"
    else
      word3 = "今日は雨が降るかもしれないから折りたたみ傘があると安心だよ！"
    end 

    push=     
    "#{word1}\n#{word3}\n降水確率はこんな感じだよ。\n　  6〜12時　#{per06to12}％\n　12〜18時　 #{per12to18}％\n　18〜24時　#{per18to24}％\n#{word2}"

    user_ids = User.all.pluck(:line_id)
    message = {
      type: 'text',
      text: push
    }
    response = client.multicast(user_ids, message)
  end
  "OK"
end
