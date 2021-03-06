# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)
if Hero.count == 0
  Hero.create(name: 'Priest')
  Hero.create(name: 'Rogue')
  Hero.create(name: 'Mage')
  Hero.create(name: 'Paladin')
  Hero.create(name: 'Warrior')
  Hero.create(name: 'Warlock')
  Hero.create(name: 'Hunter')
  Hero.create(name: 'Shaman')
  Hero.create(name: 'Druid')
end

def attributes_by_json_card(card)
  {
    ref: card[:id],
    name: card[:name],
    description: card[:description],
    mana: card[:mana],
    type: card[:type],
    hero: card[:class],
    set: card[:set],
    quality: card[:legendary],
    race: card[:race],
    attack: card[:attack],
    health: card[:health]
  }
end

# rake db:seed update_cards=true
if Card.count == 0 || ENV['update_cards']
  Card.count.tap do |count_before|
    cards = JSON.parse(File.read(File.join(Rails.root, 'db', 'cards.json')), symbolize_names: true)
    cards.each do |card|
      db_card = Card.where(ref: card[:id]).first_or_initialize
      db_card.update_attributes(ref: card[:id],
                                name: card[:name],
                                description: card[:description],
                                mana: card[:mana],
                                type: card[:type],
                                hero: card[:class],
                                set: card[:set],
                                quality: card[:legendary],
                                race: card[:race],
                                attack: card[:attack],
                                health: card[:health])
    end

    puts "Cards added: #{Card.count - count_before}"
  end
end

# rake db:seed update_decks=true
if Deck.count == 0 || ENV['update_decks']
  Deck.count.tap do |count_before|
    decks_by_hero = JSON.parse(File.read(File.join(Rails.root, 'db', 'decks.json')), symbolize_names: true)
    decks_by_hero.each do |hero_name, decks|
      hero = Hero.where('lower(name) = ?', hero_name.downcase).first
      raise "Hero not found" unless hero
      decks.each do |deck|
        db_deck = Deck.where(key: deck[:key], hero: hero).first_or_initialize
        db_deck.update_attributes(key: deck[:key],
                                  name: deck[:name],
                                  hero_id: hero.id)
      end
    end

    puts "Decks added: #{Deck.count - count_before}"
  end
end

if Rails.env.development? && User.count == 0
  user = User.create(username: 'dev', password: 'dev', password_confirmation: 'dev')
  players = [:me, :opponent]
  all_cards = Card.all
  all_heroes = Hero.all

  100.times do |x|
    mode = [:arena, :casual, :practice, :ranked].sample
    result = Result.new(mode: mode,
                  hero: all_heroes.sample,
                  opponent: all_heroes.sample,
                  win: [true, false].sample,
                  coin: [true, false].sample,
                  user: user,
                  created_at: Date.today - rand(0..40).days
                 )
    result.rank = rand(1..25) if :ranked == mode
    result.card_history_list = rand(2..10).times.map do |n|
      CardHistoryEntry.new(
        player: players[(n + (result.coin ? 1 : 0)) % 2],
        card: all_cards.sample,
        turn: n + 1
      )
    end
    result.save
  end
end


