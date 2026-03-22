require 'test_helper'

class VoiceCommandIntentServiceTest < ActiveSupport::TestCase
  # === EMPTY / BLANK INPUT ===

  test 'returns empty type for blank transcript' do
    result = VoiceCommandIntentService.new(transcript: '').parse
    assert_equal 'empty', result[:type]
  end

  test 'returns empty type for whitespace-only transcript' do
    result = VoiceCommandIntentService.new(transcript: '   ').parse
    assert_equal 'empty', result[:type]
  end

  test 'preserves original transcript in raw field' do
    transcript = 'Add 2 burgers please'
    result = VoiceCommandIntentService.new(transcript: transcript).parse
    assert_equal transcript, result[:raw]
  end

  # === START ORDER ===

  test 'detects start order intent' do
    result = VoiceCommandIntentService.new(transcript: 'start an order please').parse
    assert_equal 'start_order', result[:type]
  end

  test 'detects open order intent' do
    result = VoiceCommandIntentService.new(transcript: 'open a new order').parse
    assert_equal 'start_order', result[:type]
  end

  test 'detects begin order intent' do
    result = VoiceCommandIntentService.new(transcript: 'can I begin an order').parse
    assert_equal 'start_order', result[:type]
  end

  test 'detects start tab intent' do
    result = VoiceCommandIntentService.new(transcript: "let's start a tab").parse
    assert_equal 'start_order', result[:type]
  end

  # === CLOSE ORDER ===

  test 'detects close order intent' do
    result = VoiceCommandIntentService.new(transcript: 'close the order').parse
    assert_equal 'close_order', result[:type]
  end

  test 'detects finish order intent' do
    result = VoiceCommandIntentService.new(transcript: 'finish the order').parse
    assert_equal 'close_order', result[:type]
  end

  test 'detects we are done intent' do
    result = VoiceCommandIntentService.new(transcript: "we're done").parse
    assert_equal 'close_order', result[:type]
  end

  # === REQUEST BILL ===

  test 'detects request bill intent' do
    result = VoiceCommandIntentService.new(transcript: 'can I have the bill').parse
    assert_equal 'request_bill', result[:type]
  end

  test 'detects get the check intent' do
    result = VoiceCommandIntentService.new(transcript: 'get the check please').parse
    assert_equal 'request_bill', result[:type]
  end

  test 'detects ready to pay intent' do
    result = VoiceCommandIntentService.new(transcript: 'ready to pay').parse
    assert_equal 'request_bill', result[:type]
  end

  # === SUBMIT ORDER ===

  test 'detects submit order intent' do
    result = VoiceCommandIntentService.new(transcript: 'submit the order').parse
    assert_equal 'submit_order', result[:type]
  end

  test 'detects place order intent' do
    result = VoiceCommandIntentService.new(transcript: "place the order").parse
    assert_equal 'submit_order', result[:type]
  end

  test 'detects checkout intent' do
    result = VoiceCommandIntentService.new(transcript: 'checkout').parse
    assert_equal 'submit_order', result[:type]
  end

  test 'detects that is all intent' do
    result = VoiceCommandIntentService.new(transcript: "that's all").parse
    assert_equal 'submit_order', result[:type]
  end

  # === ADD ITEM ===

  test 'detects add item with quantity' do
    result = VoiceCommandIntentService.new(transcript: 'add 2 burgers').parse
    assert_equal 'add_item', result[:type]
    assert_equal 2, result[:qty]
    assert_includes result[:query], 'burger'
  end

  test 'detects add item with word quantity' do
    result = VoiceCommandIntentService.new(transcript: 'add one pizza').parse
    assert_equal 'add_item', result[:type]
    assert_equal 1, result[:qty]
  end

  test 'detects add item without quantity defaults to 1' do
    result = VoiceCommandIntentService.new(transcript: 'add fries').parse
    assert_equal 'add_item', result[:type]
    assert_equal 1, result[:qty]
    assert_includes result[:query], 'fries'
  end

  test 'detects i want intent' do
    result = VoiceCommandIntentService.new(transcript: "i'd like a steak").parse
    assert_equal 'add_item', result[:type]
  end

  test 'detects can i get intent' do
    result = VoiceCommandIntentService.new(transcript: "can i get a salad").parse
    assert_equal 'add_item', result[:type]
  end

  test 'detects order intent for add' do
    result = VoiceCommandIntentService.new(transcript: 'order 3 tacos').parse
    assert_equal 'add_item', result[:type]
    assert_equal 3, result[:qty]
  end

  # === REMOVE ITEM ===

  test 'detects remove item' do
    result = VoiceCommandIntentService.new(transcript: 'remove the burger').parse
    assert_equal 'remove_item', result[:type]
    assert_includes result[:query], 'burger'
  end

  test 'detects delete item' do
    result = VoiceCommandIntentService.new(transcript: 'delete 2 fries').parse
    assert_equal 'remove_item', result[:type]
    assert_equal 2, result[:qty]
  end

  test 'detects take off intent' do
    result = VoiceCommandIntentService.new(transcript: 'take off the salad').parse
    assert_equal 'remove_item', result[:type]
  end

  test 'detects cancel item intent' do
    result = VoiceCommandIntentService.new(transcript: 'cancel the soup').parse
    assert_equal 'remove_item', result[:type]
  end

  # === POLITENESS STRIPPING ===

  test 'strips please from the end before matching' do
    result_with = VoiceCommandIntentService.new(transcript: 'add a burger please').parse
    result_without = VoiceCommandIntentService.new(transcript: 'add a burger').parse
    assert_equal result_with[:type], result_without[:type]
  end

  test 'strips thanks from the end' do
    result = VoiceCommandIntentService.new(transcript: 'add fries thanks').parse
    assert_equal 'add_item', result[:type]
  end

  # === UNKNOWN ===

  test 'returns unknown for unrecognised transcript' do
    result = VoiceCommandIntentService.new(transcript: 'bananas on the ceiling').parse
    assert_equal 'unknown', result[:type]
    assert_equal 'bananas on the ceiling', result[:raw]
  end

  # === FRENCH LOCALE ===

  test 'detects start order in French' do
    result = VoiceCommandIntentService.new(transcript: 'commencer une commande', locale: 'fr').parse
    assert_equal 'start_order', result[:type]
  end

  test 'detects add item in French' do
    result = VoiceCommandIntentService.new(transcript: 'ajoute deux pizzas', locale: 'fr').parse
    assert_equal 'add_item', result[:type]
    assert_equal 2, result[:qty]
  end

  test 'detects remove item in French' do
    result = VoiceCommandIntentService.new(transcript: 'retire un burger', locale: 'fr').parse
    assert_equal 'remove_item', result[:type]
    assert_equal 1, result[:qty]
  end

  # === LOCALE NORMALISATION ===

  test 'normalises locale with region tag' do
    result = VoiceCommandIntentService.new(transcript: 'start an order', locale: 'en-US').parse
    assert_equal 'start_order', result[:type]
  end

  test 'falls back to English for unknown locale' do
    result = VoiceCommandIntentService.new(transcript: 'add a salad', locale: 'zz').parse
    assert_equal 'add_item', result[:type]
  end

  test 'nil locale treated as English' do
    result = VoiceCommandIntentService.new(transcript: 'add a salad', locale: nil).parse
    assert_equal 'add_item', result[:type]
  end

  # === QUANTITY NORMALISATION ===

  test 'normalises numeric string quantity' do
    result = VoiceCommandIntentService.new(transcript: 'add 3 sodas').parse
    assert_equal 3, result[:qty]
  end

  test 'normalises two to 2' do
    result = VoiceCommandIntentService.new(transcript: 'add two burgers').parse
    assert_equal 2, result[:qty]
  end

  test 'normalises three to 3' do
    result = VoiceCommandIntentService.new(transcript: 'add three beers').parse
    assert_equal 3, result[:qty]
  end
end
