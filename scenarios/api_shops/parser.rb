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
      @verification_errors << error
    ensure
      teardown()
    end
  end

  def setup
    @driver = Selenium::WebDriver.for :firefox
    @wait = Selenium::WebDriver::Wait.new(timeout: 5)

    @base_url = "http://www.apishops.com"
    @accept_next_alert = true
    @driver.manage.timeouts.implicit_wait = 30
    @verification_errors = []
  end

  def teardown
    @driver.quit
    unless @verification_errors.empty?
      @verification_errors.each do |error|
        puts error
      end
      puts 'There were errors'
    end
  end

  def run
    @driver.get(@base_url + "/")
    @driver.find_element(:css, "a.loginlink").click
    @driver.find_element(:css, "input[name=\"login\"]").clear
    @driver.find_element(:css, "input[name=\"login\"]").send_keys "coffeedolphins"
    @driver.find_element(:css, "input[name=\"password\"]").clear
    @driver.find_element(:css, "input[name=\"password\"]").send_keys "cXbirWN3hyhhs3"
    @driver.find_element(:name, "rememberLogin").click
    @driver.find_element(:css, "input[type=\"submit\"]").click
    @driver.get(@base_url + "/Webmaster/WebsiteGroup/WebsiteGroupList.jsp")
    @driver.find_element(:link, "Ассортимент").click
    @driver.find_element(:css, "a.modalCloseImg.simplemodal-close").click
    @driver.find_element(:id, "useTopHitsA").click

    parse_page()
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

private

  def parse_page
    begin
      @wait.until { @driver.find_element(:css, '.producttable') }
    rescue => error
      @verification_errors << "Can't find element .producttable"
    end

    page = Nokogiri::HTML(@driver.page_source)
    product_row = page.css('tr[alt]')[1]

    product = {
      product_id: product_row['alt'],
      title: product_row.at_css('td.pName span').content.capitalize,
      category_id: product_row.at_css('a.pCategory')['alt'],
      category_title: product_row.at_css('a.pCategory').content.capitalize,
      price: product_row.at_css('td.price')['alt'],
      profit: product_row.at_css('td.commission')['alt'],
      availability_level: product_row.css('.avBlock .avRect').length.to_s,
      image_url: @base_url + product_row.at_css('td a[rel="lightbox"]')['href']
    }

    product.values.each do |value|
      puts value
    end

    if element_present?(:link, 'Следующая →')
      # @driver.find_element(:link, 'Следующая →').click
      # parse_page()
    end
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
