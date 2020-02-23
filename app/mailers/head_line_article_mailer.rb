class HeadLineArticleMailer < ApplicationMailer
  def notification(head_line_articles)
    @head_line_articles = head_line_articles
      subject = '今日の為替と株価'
      from = '今日の為替と株価<info@example.com>'
      to = 'hogehoge@example.com'
      mail(to: to, from: from, subject: subject)
    end
  end
end
