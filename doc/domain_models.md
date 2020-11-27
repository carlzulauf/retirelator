# Retirement Planner, Domain Models

These are the basic building blocks we will use to track and simulate retirement across a projected lifetime.

## Retiree

* name
* date_of_birth
* salary
* 401k_contribution_rate
* 401k_match_percent
* ira_balance
* roth_balance
* savings_balance
* annual_ira_contribution
* annual_roth_contribution
* annual_roth_conversion
* monthly_savings

## Retirement Goals

* monthly_allowance
* target_retirement_date
* target_death_date

## Simulation

* description
* start_date
* inflation_rate
* inflate_thresholds
* salary_growth_rate
* investment_growth_rate
* short_term_gains_ratio
* noise

## Simulator

* current_date
* current_year
* ira_account
* roth_account
* savings_account
* fixed_incomes

## Tax Year

* year
* ppp
* transactions
* income_tax_brackets
* capital_gains_tax_brackets

## Taxes

* type (income or capital gains)
* brackets

## Tax Bracket

* range
* rate
* remaining
* transactions

## Account

* type
* balance
* transactions
* taxable_gains
* taxable_withdrawals

## Fixed Income

* description
* monthly_amount
* inflates (boolean)

## Transaction

* account
* description
* gross_amount
* net_amount
* balance
* taxes

## Tax Transaction

* transaction
* amount
* tax_type
* tax_rate
* tax_rate_remaining
* paid
