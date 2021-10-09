module NewsHelper
  def highlight_news(text)
    text = highlight text, ['upgrade', 'raise'], highlighter: '<mark class="news-positive">\1</mark>'
    # text = highlight text, ['downgrade', 'lowered'], highlighter: '<mark class="news-negative">\1</mark>'
    text
  end
end
