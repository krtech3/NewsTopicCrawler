require 'date'
class HeadLineArticle < ApplicationRecord
  validates :article_name, presence: true
  validates :content_name, presence: true, uniqueness: { scope: :article_name }
  validates :url_name, presence: true
  validates :nikkei_average, presence: false
  validates :compare_nikkei_average, presence: false
  validates :exchange_rate_yen_dollar, presence: false
  validates :exchange_rate_yen_euro, presence: false
  validates :stock_price, presence: false
  validates :compare_stock_price, presence: false
  validates :corona_infection_status_info, presence: false
  validates :date_today, presence: false


  def self.fetch_head_line_article
    target_url = 'https://www.nikkei.com'

    agent = Mechanize.new
    page = agent.get(target_url)

    new_articles = []

    #
    # article_name getting
    #
    article_name = page.search('.k-card--headline .k-v').text

    #
    # content_name getting
    #
    content_name = page.search('.k-card__excerpt p')[0].text

    #
    # url_name getting
    #
    url_tag = page.search('.k-card--headline .k-card__title-link')
    url_tag2 = url_tag.at('a').attributes['href'].text
    url_name = target_url + url_tag2

    #
    # get Trade_Info
    #

    # 証券サイトトップページ
    kabutan_url = 'https://kabutan.jp/'

    # 日経平均
    kabutan_n_ave = 'stock/kabuka?code=0000'
    kabutan_page = agent.get(kabutan_url + kabutan_n_ave)
    
    # 日経平均の取得
    nikkei_average = kabutan_page.search('table.stock_kabuka1 tr:first-child td')[3].text

    # 日経平均（前日比）の取得
    compare_nikkei_average = kabutan_page.search('table.stock_kabuka1 tr:first-child td')[4].text

    # 為替（円・ドル）
    yen_dollar = 'stock/kabuka?code=0950'
    yen_dollar_page = agent.get(kabutan_url + yen_dollar)

    # 値の取得
    exchange_rate_yen_dollar = yen_dollar_page.search('table.stock_kabuka1 tr:first-child td')[3].text

    # 為替（円・ユーロ）
    yen_euro = 'stock/kabuka?code=0951'
    yen_euro_page = agent.get(kabutan_url + yen_euro)
    # 値の取得
    exchange_rate_yen_euro = yen_euro_page.search('table.stock_kabuka1 tr:first-child td')[3].text

    # 個別株（証券番号：3064）
    kobetsu = 'stock/kabuka?code=3064'
    kobetsu_page = agent.get(kabutan_url + kobetsu)

    # 値の取得
    stock_price = kobetsu_page.search('table.stock_kabuka1 tr:first-child td')[3].text
    
    # 個別株（前日比）の取得
    compare_stock_price = kobetsu_page.search('table.stock_kabuka1 tr:first-child td')[4].text

    #
    # get Corona Infection
    #

    # 日経新聞コロナ感染マップ
    corona_url = 'https://vdata.nikkei.com/newsgraphics/coronavirus-world-map/'
    corona_page = agent.get(corona_url)

    # 感染者状況の取得
    corona_infection_status_info = corona_page.search('.cover p.cover__text').text

    # record
    record = self.find_or_initialize_by(article_name: article_name, content_name: content_name, url_name: url_name,
                                        nikkei_average: nikkei_average, compare_nikkei_average: compare_nikkei_average,
                                        exchange_rate_yen_dollar: exchange_rate_yen_dollar, exchange_rate_yen_euro: exchange_rate_yen_euro,
                                        stock_price: stock_price,compare_stock_price: compare_stock_price,
                                        corona_infection_status_info: corona_infection_status_info)

    # データが新規ならDBに保存
    if record.new_record?
      record.save!

    # 配列に追記
    new_articles << record
    else
      logger.info "[INFO] Already saved."
    end
    
    # 配列に記事があればメール送信
    if new_articles.size > 0
      logger.info "[INFO] Send notification."
      HeadLineArticleMailer.notification(new_articles).deliver_now
    end
      logger.info "[INFO] Complete fetch_head_line_articles."
  end
end
