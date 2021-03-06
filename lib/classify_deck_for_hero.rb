class ClassifyDeckForHero
  MIN_CARDS_FOR_PREDICTION = 5
  MIN_CARDS_FOR_LEARNING   = 8

  attr_reader :hero, :counts_by_card

  def initialize(hero, counts_by_card)
    @hero = hero
    @counts_by_card = counts_by_card
  end

  def normalized_counts_by_card
    @normalized_counts_by_card ||= begin
                                     # a deck consists normally of 30 cards
                                     # if we only see 15, make sure we scale them properly
                                     num_cards = counts_by_card.values.sum
                                     scaling_factor = 30.0 / num_cards

                                     Hash[counts_by_card.collect do |key, value|
                                       [key, scaling_factor * value]
                                     end]
                                   end
  end

  def eligible_decks
    @eligible_decks ||= Deck.where(hero: hero)
  end

  def predict
    return nil if counts_by_card.values.sum < MIN_CARDS_FOR_PREDICTION

    best_score = nil
    best_deck = nil

    Rails.logger.info "[Classify] Predict for #{hero} #{counts_by_card} (norm: #{normalized_counts_by_card}"

    eligible_decks.each do |deck|
      score = deck.classifier.predict_score(normalized_counts_by_card)

      Rails.logger.info "[Classify] Deck #{deck} score #{score}"

      if best_score.nil? || score > best_score
        best_deck = deck
        best_score = score
      end
    end

    Rails.logger.info "[Classify] Best deck #{best_deck} score #{best_score}"

    # return nil if we are uncertain
    (best_score && best_score >= 1.0) ? best_deck : nil
  end

  def learn! true_deck
    return false if counts_by_card.values.sum < MIN_CARDS_FOR_LEARNING

    if true_deck && eligible_decks.exclude?(true_deck)
      Rails.logger.warn "[Classify] learn! called for ineligible deck #{true_deck} #{hero}"
      return
    end

    eligible_decks.each do |deck|
      label = true_deck == deck ? 1 : -1
      before_score = deck.classifier.predict_score(normalized_counts_by_card)
      deck.classifier.train(normalized_counts_by_card, label)
      after_score = deck.classifier.predict_score(normalized_counts_by_card)
      Rails.logger.info "[Classify] Learn classifier_deck: #{deck.full_name} true_deck: #{true_deck ? true_deck.full_name : nil} before_score: #{before_score} after_score: #{after_score} label: #{label}"
      deck.save!
    end

    true
  end

end
