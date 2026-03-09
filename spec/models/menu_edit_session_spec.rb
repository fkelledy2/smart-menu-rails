require 'rails_helper'

RSpec.describe MenuEditSession, type: :model do
  it 'belongs to a menu and a user' do
    session = described_class.reflect_on_association(:menu)
    user = described_class.reflect_on_association(:user)

    expect(session&.macro).to eq(:belongs_to)
    expect(user&.macro).to eq(:belongs_to)
  end

  it 'is valid with a menu and user' do
    record = build(:menu_edit_session, menu: create(:menu), user: create(:user))

    expect(record).to be_valid
  end
end
