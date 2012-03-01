#!/usr/bin/env ruby

$LOAD_PATH << "."

require 'finmodeling'

def get_args
  if ARGV.length != 2
    puts "usage #{__FILE__} <stock symbol or report URL> <0, for most recent|-1 for prevous|-2, etc>"
    exit
  end

  args = { :stock_symbol => nil, :filing_url => nil, :report_offset => nil }
  arg = ARGV[0]
  if arg =~ /http/
    args[:filing_url] = arg
  else
    args[:stock_symbol] = arg
  end
  args[:report_offset] = ARGV[1].to_i

  return args
end

def get_company_filing_url(stock_symbol, report_offset)
  company = FinModeling::Company.find(stock_symbol)
  raise RuntimeError.new("couldn't find company") if company.nil?
  puts "company name: #{company.name}"
  raise RuntimeError.new("company has no annual reports") if company.annual_reports.length == 0
  filing_url = company.annual_reports[-1+report_offset].link

  return filing_url
end

def get_filing(filing_url)
  puts "url:          #{filing_url}\n"
  filing = FinModeling::AnnualReportFiling.download(filing_url)
  return filing
end

def print_balance_sheet(filing)
  period = filing.balance_sheet.periods.last
  puts "Balance Sheet (#{period.to_pretty_s})"
  
  filing.balance_sheet.assets_calculation.summary(period).print
  filing.balance_sheet.liabs_and_equity_calculation.summary(period).print
end

def print_income_statement(filing)
  period  = filing.income_statement.net_income_calculation.periods.yearly.last
  puts "Income Statement (#{period.to_pretty_s})"

  filing.income_statement.net_income_calculation.summary(period).print
end

FinModeling::IncomeStatementItem.load_vectors_and_train(FinModeling::ISI_TRAINING_VECTORS)

args = get_args
filing_url = args[:filing_url] || get_company_filing_url(args[:stock_symbol], args[:report_offset])
filing = get_filing(filing_url)
print_balance_sheet(filing)
print_income_statement(filing)
raise RuntimeError.new("annual report is not valid") if !filing.is_valid?