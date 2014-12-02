scenarios_data = []

require 'nokogiri'
require 'selenium-webdriver'

class Scenario

  def initialize(options = {})
    @options = options
    setup()

    begin
      run()
    rescue => error
      puts error.message
      puts error.backtrace.join("\n")
    ensure
      teardown()
    end
  end

  def setup
    @driver = Selenium::WebDriver.for :firefox
    @wait = Selenium::WebDriver::Wait.new(timeout: 30)

    @base_url = "http://coffeedolphins.ru"
    @accept_next_alert = true

    @wordstat = Selenium::WebDriver.for :firefox
  end

  def teardown
    @driver.quit
    @wordstat.quit
  end

  def run
    login_yandex()
    login_coffee()

    parse_page()
  end

private

  def login_yandex
    @wordstat.get('http://yandex.ru')

    login_popup = @wait.until { @wordstat.find_element(:css, '.popup.popup_visibility_visible') }
    login_popup.find_element(:css, '[name="login"]').clear
    login_popup.find_element(:css, '[name="login"]').send_keys 'serjio90'
    login_popup.find_element(:css, '[name="passwd"]').clear
    login_popup.find_element(:css, '[name="passwd"]').send_keys 'HOoQSLXjiEVVguJ9zu'

    login_button = @wait.until { login_popup.find_element(:css, '.auth__button .button.button_js_inited') }
    login_button.click

    @wait.until { @wordstat.find_element(:css, '.js-header-user-name') }
  end

  def login_coffee
    @driver.get(@base_url + "/login")

    @driver.find_element(:id, "new_user_email").clear
    @driver.find_element(:id, "new_user_email").send_keys "coffeedolphins@gmail.com"
    @driver.find_element(:id, "new_user_password").clear
    @driver.find_element(:id, "new_user_password").send_keys "ritamargarita"
    @driver.find_element(:css, '[type="submit"]').click

    @wait.until { @driver.find_element(:css, '[data-component="app#items_list"]') }
  end

  def parse_page
    @driver.find_elements(:css, '[data-view="item"]').each do |position|
      keywords = position.find_elements(:css, '.panel_list-value .tags-item')

      if keywords.any?
        position.find_element(:css, '[data-role="edit_item_button"]').click

        position_form = @wait.until { position.find_element(:css, '.panel_item .panel_item-body:not([data-role="item-info"])') }
        get_keywords_for_position(position_form)

        position_form.find_element(:css, '[type="submit"]').click

        @wait.until { position.find_element(:css, 'span.status.is-gray') }
      end
    end

    if element_present?(:css, '.pagination-next a')
      link = @driver.find_element(:css, '.pagination-next a')
      link_path = link.attribute('href')

      @driver.get(link_path)
      @wait.until { @driver.find_element(:css, '[data-component="app#items_list"]') }
      parse_page()
    end
  end

  def get_keywords_for_position(position_form)
    @wait.until { position_form.find_element(:css, '[data-role="keywords-container"]') }
    keywords = position_form.find_elements(:css, '[data-role="keyword"]')

    keywords.each do |keyword|
      keyword_name = keyword.attribute('data-name')
      keyword_count = get_keyword_stat(keyword_name.to_s)

      keyword.find_element(:css, '[type="text"]').clear
      keyword.find_element(:css, '[type="text"]').send_keys keyword_count
    end
  end

  def get_keyword_stat(keyword_name)
    sleep 4
    search_count_value = nil

    while search_count_value.nil? do
      begin
        @wordstat.get("http://yandex.ru/")
        @wait.until { @wordstat.find_element(:css, '.input__input') }
        sleep 4
        @wordstat.get("http://wordstat.yandex.ru/#!/?words=#{keyword_name}")
        search_count_text = @wait.until { @wordstat.find_element(:css, '.b-phrases__info') }
        matcher = /—(.+)показ/.match(search_count_text.text)

        if matcher[1]
          search_count_value = matcher[1].gsub(/\D/, '')
        else
          search_count_value = 0
        end
      rescue
        puts 'FUCK YOU, YANDEX'
      end
    end

    search_count_value
  end

  def element_present?(how, what)
    @driver.find_element(how, what)
    true
  rescue Selenium::WebDriver::Error::NoSuchElementError
    false
  end

  def alert_present?()
    @driver.switch_to.alert
    true
  rescue Selenium::WebDriver::Error::NoAlertPresentError
    false
  end

  def close_alert_and_get_its_text(how, what)
    alert = @driver.switch_to().alert()
    alert_text = alert.text
    if (@accept_next_alert) then
      alert.accept()
    else
      alert.dismiss()
    end
    alert_text
  ensure
    @accept_next_alert = true
  end
end

if scenarios_data.empty?
  Scenario.new()
else
  threads = []

  scenarios_data.each do |data|
    threads << Thread.new(data) do |thread_data|
      Scenario.new(thread_data)
    end
  end

  threads.each { |thr| thr.join }
end
