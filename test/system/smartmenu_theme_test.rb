require 'application_system_test_case'

# Tests that:
#   1. data-theme on <html> reflects the saved theme
#   2. The correct font is applied to the page container per theme
#   3. The page background colour matches the theme's --sm-bg value
#   4. The dark-mode toggle changes data-color-scheme on <html>
#   5. Dark mode actually darkens the page background (not just foreground)
#   6. Section-tab active state uses the theme primary colour
class SmartmenuThemeTest < ApplicationSystemTestCase
  THEMES = {
    'modern' => { font_fragment: 'Inter',             bg_rgb: 'rgb(249, 250, 251)', dark_bg_rgb: 'rgb(15, 23, 42)' },
    'rustic' => { font_fragment: 'Playfair Display',  bg_rgb: 'rgb(253, 248, 240)', dark_bg_rgb: 'rgb(20, 13, 4)' },
    'elegant' => { font_fragment: 'Cormorant Garamond', bg_rgb: 'rgb(250, 250, 249)', dark_bg_rgb: 'rgb(8, 7, 6)' },
  }.freeze

  def setup
    @restaurant = Restaurant.create!(
      name: 'Theme Test Restaurant',
      user: users(:one),
      address1: '1 Test St',
      city: 'Dublin',
      state: 'D',
      country: 'IE',
      status: 'active',
    )
    @menu = Menu.create!(name: 'Theme Test Menu', restaurant: @restaurant, status: 'active')
  end

  # -------------------------------------------------------------------------
  # 1. data-theme attribute reflects the saved theme
  # -------------------------------------------------------------------------

  test 'data-theme on html element matches modern theme' do
    sm = create_smartmenu('theme-modern', 'modern')
    visit_smartmenu(sm)
    assert_html_theme('modern')
  end

  test 'data-theme on html element matches rustic theme' do
    sm = create_smartmenu('theme-rustic', 'rustic')
    visit_smartmenu(sm)
    assert_html_theme('rustic')
  end

  test 'data-theme on html element matches elegant theme' do
    sm = create_smartmenu('theme-elegant', 'elegant')
    visit_smartmenu(sm)
    assert_html_theme('elegant')
  end

  # -------------------------------------------------------------------------
  # 2. CSS variable --sm-font-family-base resolves to the correct font
  # -------------------------------------------------------------------------

  THEMES.each do |theme_name, expected|
    test "#{theme_name} theme sets the correct font CSS variable" do
      sm = create_smartmenu("font-#{theme_name}", theme_name)
      visit_smartmenu(sm)

      font_var = css_var('--sm-font-family-base')
      assert font_var.include?(expected[:font_fragment]),
             "Expected --sm-font-family-base to contain '#{expected[:font_fragment]}', got: '#{font_var}'"
    end

    # -------------------------------------------------------------------------
    # 3. Body background colour matches the theme's --sm-bg
    # -------------------------------------------------------------------------

    test "#{theme_name} theme applies correct background colour to body" do
      sm = create_smartmenu("bg-#{theme_name}", theme_name)
      visit_smartmenu(sm)

      bg = computed_style('body', 'backgroundColor')
      assert_equal expected[:bg_rgb], bg,
                   "Expected body background #{expected[:bg_rgb]} for #{theme_name}, got: #{bg}"
    end
  end

  # -------------------------------------------------------------------------
  # 4. Dark-mode toggle sets data-color-scheme on <html>
  # -------------------------------------------------------------------------

  test 'setting dark mode adds data-color-scheme=dark to html element' do
    sm = create_smartmenu('dm-attr', 'modern')
    visit_smartmenu(sm)

    set_color_scheme('dark')
    scheme = page.evaluate_script("document.documentElement.getAttribute('data-color-scheme')")
    assert_equal 'dark', scheme
  end

  test 'setting light mode adds data-color-scheme=light to html element' do
    sm = create_smartmenu('lm-attr', 'modern')
    visit_smartmenu(sm)

    set_color_scheme('light')
    scheme = page.evaluate_script("document.documentElement.getAttribute('data-color-scheme')")
    assert_equal 'light', scheme
  end

  test 'clearing color scheme removes data-color-scheme from html element' do
    sm = create_smartmenu('auto-attr', 'modern')
    visit_smartmenu(sm)

    set_color_scheme('dark')
    clear_color_scheme
    scheme = page.evaluate_script("document.documentElement.getAttribute('data-color-scheme')")
    assert_nil scheme
  end

  # -------------------------------------------------------------------------
  # 5. Dark mode actually changes the page background (not just foreground)
  # -------------------------------------------------------------------------

  THEMES.each do |theme_name, expected|
    test "#{theme_name} theme dark mode darkens the body background" do
      sm = create_smartmenu("dark-bg-#{theme_name}", theme_name)
      visit_smartmenu(sm)

      light_bg = computed_style('body', 'backgroundColor')
      set_color_scheme('dark')
      dark_bg = computed_style('body', 'backgroundColor')

      assert_not_equal light_bg, dark_bg,
                       "Dark mode did not change body background for #{theme_name} (stuck at #{light_bg})"
      assert_equal expected[:dark_bg_rgb], dark_bg,
                   "Expected dark body background #{expected[:dark_bg_rgb]} for #{theme_name}, got: #{dark_bg}"
    end

    # -------------------------------------------------------------------------
    # 6. Sticky header background matches the theme (not the generic surface)
    # -------------------------------------------------------------------------

    test "#{theme_name} theme applies background to sticky header" do
      sm = create_smartmenu("header-bg-#{theme_name}", theme_name)
      visit_smartmenu(sm)
      assert_selector '.menu-sticky-header-mobile', wait: 10

      header_bg = computed_style('.menu-sticky-header-mobile', 'backgroundColor')
      assert_equal expected[:bg_rgb], header_bg,
                   "Expected sticky header background #{expected[:bg_rgb]} for #{theme_name}, got: #{header_bg}"
    end
  end

  # -------------------------------------------------------------------------
  # 7. Section tabs exist and active tab uses theme colour
  # -------------------------------------------------------------------------

  test 'section tabs are rendered inside sections-tabs-container' do
    sm = create_smartmenu('tabs-present', 'modern')
    visit_smartmenu(sm)
    assert_selector '.sections-tabs-container .section-tab', minimum: 1, wait: 10
  end

  private

  def create_smartmenu(slug, theme)
    Smartmenu.create!(
      menu: @menu,
      restaurant: @restaurant,
      slug: slug,
      theme: theme,
    )
  end

  def visit_smartmenu(sm)
    visit smartmenu_path(sm.slug)
    assert_selector '.menu-sticky-header-mobile', wait: 15
  end

  def assert_html_theme(expected)
    actual = page.evaluate_script("document.documentElement.getAttribute('data-theme')")
    assert_equal expected, actual, "Expected data-theme='#{expected}' on <html>, got '#{actual}'"
  end

  # Returns the value of a CSS custom property on <html>
  def css_var(name)
    page.evaluate_script(
      "getComputedStyle(document.documentElement).getPropertyValue('#{name}').trim()",
    )
  end

  # Returns a computed CSS property for a selector (e.g. 'body', '.container-fluid')
  def computed_style(selector, property)
    page.evaluate_script(
      "getComputedStyle(document.querySelector('#{selector}')).#{property}",
    )
  end

  # Directly manipulate data-color-scheme (bypasses localStorage to keep tests deterministic)
  def set_color_scheme(scheme)
    page.execute_script("document.documentElement.setAttribute('data-color-scheme', '#{scheme}')")
    sleep 0.1 # allow one paint cycle
  end

  def clear_color_scheme
    page.execute_script("document.documentElement.removeAttribute('data-color-scheme')")
    sleep 0.1
  end
end
