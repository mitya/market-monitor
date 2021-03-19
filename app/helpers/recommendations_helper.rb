module RecommendationsHelper
  def recommendation_view(recommendation)
    recommendation.ratings.join(', ')
  end

  def recommedation_significant_rating(recommendation, rating)
    rating_analysts = recommendation.send(rating)
    rating_ratio    = recommendation.send("#{rating}_ratio")
    rating_ratio > 0.1 ? rating_analysts : nil
  end
end
