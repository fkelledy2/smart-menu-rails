require 'test_helper'

class MenuDiscovery::WebMenuScraperTest < ActiveSupport::TestCase
  setup do
    @scraper = MenuDiscovery::WebMenuScraper.new
  end

  test 'scrape returns empty result for empty pages array' do
    result = @scraper.scrape([])
    assert_equal '', result[:menu_text]
    assert_equal 0, result[:pages_scraped]
    assert_empty result[:source_urls]
  end

  test 'scrape extracts text from pre-fetched HTML with menu content' do
    html = <<~HTML
      <html><body>
        <div class="menu-section">
          <h2>Starters</h2>
          <div class="menu-item"><span>Soup of the Day</span> <span>€6.50</span></div>
          <div class="menu-item"><span>Bruschetta</span> <span>€8.00</span></div>
          <div class="menu-item"><span>Caesar Salad</span> <span>€9.50</span></div>
        </div>
        <div class="menu-section">
          <h2>Mains</h2>
          <div class="menu-item"><span>Grilled Salmon</span> <span>€18.00</span></div>
          <div class="menu-item"><span>Beef Burger</span> <span>€14.50</span></div>
        </div>
      </body></html>
    HTML

    pages = [{ url: 'https://example.com/menu', html: html }]
    result = @scraper.scrape(pages)

    assert result[:menu_text].present?
    assert_equal 1, result[:pages_scraped]
    assert_includes result[:source_urls], 'https://example.com/menu'
    assert_includes result[:menu_text], 'Starters'
    assert_includes result[:menu_text], 'Soup of the Day'
    assert_includes result[:menu_text], '€6.50'
    assert_includes result[:menu_text], 'Grilled Salmon'
  end

  test 'scrape strips JavaScript artifacts from Alpine.js content' do
    html = <<~HTML
      <html><body>
        <div id="menu">
          <h2>Cocktails</h2>
          <div x-data="{ focusImage: null }" @click="{ focusImage = '/img/aurora.jpg'; focusTitle = 'Aurora'; }">
            <span>Aurora</span>
            <span>Poitín, sake, pandan, mango</span>
          </div>
          <div @mouseleave="(() => { focusImage = null; })">
            <span>Backbone</span>
            <span>Gin, vermouth, passion fruit - €14.00</span>
          </div>
          <div><span>Crystal</span><span>Vodka, Aperol, rhubarb - €13.50</span></div>
        </div>
      </body></html>
    HTML

    pages = [{ url: 'https://example.com/menu', html: html }]
    result = @scraper.scrape(pages)

    assert result[:menu_text].present?
    assert_includes result[:menu_text], 'Aurora'
    assert_includes result[:menu_text], 'Backbone'
    # Should NOT contain JavaScript artifacts
    refute_includes result[:menu_text], 'focusImage'
    refute_includes result[:menu_text], 'focusTitle'
    refute_includes result[:menu_text], 'scrollIntoView'
  end

  test 'scrape removes script, style, nav, footer, header elements' do
    html = <<~HTML
      <html><body>
        <nav>Home | About | Contact</nav>
        <header>Restaurant Name</header>
        <script>var x = 1;</script>
        <style>.menu { color: red; }</style>
        <div class="menu-content">
          <h2>Wine List</h2>
          <p>Chardonnay from Burgundy, France - €8.00 per glass</p>
          <p>Pinot Noir from Oregon, USA - €9.00 per glass</p>
          <p>Sauvignon Blanc from Marlborough, NZ - €7.50 per glass</p>
          <p>Cabernet Sauvignon from Napa Valley - €12.00 per glass</p>
          <p>Riesling from Alsace, France - €8.50 per glass</p>
          <p>Malbec from Mendoza, Argentina - €9.50 per glass</p>
        </div>
        <footer>© 2025 Restaurant</footer>
      </body></html>
    HTML

    pages = [{ url: 'https://example.com/menu', html: html }]
    result = @scraper.scrape(pages)

    assert result[:menu_text].present?
    assert_includes result[:menu_text], 'Wine List'
    assert_includes result[:menu_text], 'Chardonnay'
    refute_includes result[:menu_text], 'var x = 1'
    refute_includes result[:menu_text], 'color: red'
    refute_includes result[:menu_text], '© 2025'
  end

  test 'scrape handles multiple pages' do
    page1_html = <<~HTML
      <html><body>
        <div class="menu-section">
          <h2>Food Menu</h2>
          <p>Classic Beef Burger with fries and salad - €12.00</p>
          <p>Margherita Pizza with fresh mozzarella and basil - €14.00</p>
          <p>Caesar Salad with grilled chicken and croutons - €10.00</p>
          <p>Fish and Chips with mushy peas and tartar sauce - €15.50</p>
          <p>Pasta Carbonara with pancetta and parmesan - €13.00</p>
        </div>
      </body></html>
    HTML

    page2_html = <<~HTML
      <html><body>
        <div class="menu-section">
          <h2>Drinks Menu</h2>
          <p>Craft Beer selection from local breweries - €5.00</p>
          <p>House Wine red or white by the glass - €7.00</p>
          <p>Signature Cocktail of the month - €12.00</p>
          <p>Fresh Orange Juice pressed to order - €4.50</p>
          <p>Espresso Martini with Jameson Irish Whiskey - €14.00</p>
        </div>
      </body></html>
    HTML

    pages = [
      { url: 'https://example.com/food-menu', html: page1_html },
      { url: 'https://example.com/drink-menu', html: page2_html },
    ]
    result = @scraper.scrape(pages)

    assert_equal 2, result[:pages_scraped]
    assert_includes result[:menu_text], 'Food'
    assert_includes result[:menu_text], 'Drinks'
    assert_includes result[:menu_text], 'Burger'
    assert_includes result[:menu_text], 'Beer'
  end
end
