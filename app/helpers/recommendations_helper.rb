module RecommendationsHelper
  def recommendation_view(recommendation)
    recommendation.ratings.join(', ')
  end

  def recommedation_significant_rating(recommendation, rating)
    rating_analysts = recommendation.send(rating)
    rating_ratio    = recommendation.send("#{rating}_ratio")
    rating_ratio > 0.1 ? rating_analysts : nil
  end

  def recommendation_scale_badge(scale)
    return if scale.blank?
    color = scale < 2 ? 'bg-success' : scale < 3 ? 'bg-warning text-dark' : 'bg-danger'
    tag.span "#{number_with_precision scale, precision: 1}", class: "badge #{color}"
  end
end
