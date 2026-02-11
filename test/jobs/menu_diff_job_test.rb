require 'test_helper'

class MenuDiffJobTest < ActiveSupport::TestCase
  test 'generate_diff shows added and removed lines' do
    job = MenuDiffJob.new

    old_text = "Margherita Pizza\nCaesar Salad\nTiramisu"
    new_text = "Margherita Pizza\nGreek Salad\nTiramisu\nPanna Cotta"

    diff = job.send(:generate_diff, old_text, new_text)

    assert_includes diff, '- Caesar Salad'
    assert_includes diff, '+ Greek Salad'
    assert_includes diff, '+ Panna Cotta'
    assert_includes diff, 'REMOVED (1 lines)'
    assert_includes diff, 'ADDED (2 lines)'
  end

  test 'generate_diff handles empty previous text' do
    job = MenuDiffJob.new

    diff = job.send(:generate_diff, '', "New Item 1\nNew Item 2")

    assert_includes diff, 'ADDED (2 lines)'
    assert_includes diff, '+ New Item 1'
    assert_includes diff, '+ New Item 2'
    assert_not_includes diff, 'REMOVED'
  end

  test 'generate_diff handles identical content' do
    job = MenuDiffJob.new

    diff = job.send(:generate_diff, "Same\nContent", "Same\nContent")

    assert_includes diff, 'No text differences detected'
  end

  test 'generate_diff handles whitespace-only differences' do
    job = MenuDiffJob.new

    diff = job.send(:generate_diff, "Item One\n  \nItem Two", "Item One\nItem Two")

    assert_includes diff, 'No text differences detected'
  end
end
