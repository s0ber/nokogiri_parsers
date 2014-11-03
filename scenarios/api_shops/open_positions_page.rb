scenarios_data = []

require 'selenium-webdriver'

class Scenario

  def initialize(options = {})
    @options = options
    setup()

    begin
      run()
    rescue Exception => error
      @verification_errors << error
    ensure
      teardown()
    end
  end

  def setup
    @driver = Selenium::WebDriver.for :firefox
    @base_url = "http://www.apishops.com/"
    @accept_next_alert = true
    @driver.manage.timeouts.implicit_wait = 30
    @verification_errors = []
  end

  def teardown
    @driver.quit
    unless @verification_errors.empty?
      puts 'There were errors'
    end
  end

  def run
    @driver.get(@base_url + "/Webmaster/WebsiteGroup/WebsiteGroupList.jsp")
    @driver.find_element(:link, "Ассортимент").click
    @driver.find_element(:css, "a.modalCloseImg.simplemodal-close").click
    @driver.find_element(:id, "useTopHitsA").click
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
