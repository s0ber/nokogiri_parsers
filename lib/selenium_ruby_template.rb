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
    @wait = Selenium::WebDriver::Wait.new(timeout: 5)

    @base_url = "${baseURL}"
    @accept_next_alert = true
    @driver.manage.timeouts.implicit_wait = 30
  end

  def teardown
    @driver.quit
  end

  def run

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
