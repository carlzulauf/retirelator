require "google/apis/sheets_v4"
require "googleauth/stores/file_token_store"

module Retirelator
  class GoogleSheetWriter
    SERVICE = Google::Apis::SheetsV4
    extend Dry::Initializer

    option :credentials_path,   default: -> { config_credentials_path }
    option :token_path,         default: -> { config_token_path }
    option :spreadsheets_path,  default: -> { config_spreadsheets_path }
    option :api_scope,          default: -> { write_spreadsheets_scope }
    option :user_id,            default: -> { "default" }
    option :app_name,           default: -> { "Retirelator" }
    option :auth_urn,           default: -> { "urn:ietf:wg:oauth:2.0:oob" }
    option :service,            default: -> { desktop_service }

    def write_simulation(simulation)
      name = [simulation.retiree.name, simulation.configuration.description].join(" - ")
      sheets = build_sheets(simulation)
      print "Looking up or creating Google Sheet.."
      id = find_or_create_spreadsheet_id(name)
      puts "."
      puts "Spreadsheet URL: https://docs.google.com/spreadsheets/d/#{id}"
      update_sheet_properties(id, sheets)
      clear_values(id, sheets)
      write_values(id, sheets)
    end

    def clear_values(id, sheets)
      request = SERVICE::BatchClearValuesRequest.new(
        ranges: sheets.map { |title, _values| "#{title}!A1:Z10000" }
      )
      service.batch_clear_values(id, request)
    end

    def write_values(id, sheets)
      data = sheets.map do |title, collection|
        rows = collection.flat_map(&:as_csv)
        columns = rows.first.keys
        last_column = ("A".."Z").to_a[columns.count - 1]
        last_row = rows.count + 1
        SERVICE::ValueRange.new(
          range: "#{title}!A1:#{last_column}#{last_row}",
          major_dimension: "ROWS",
          values: [
            columns,
            *rows.map(&:values)
          ]
        )
      end
      request = SERVICE::BatchUpdateValuesRequest.new(
        value_input_option: "USER_ENTERED",
        data:               data,
      )
      print "Updating spreadsheet values.."
      service.batch_update_values(id, request)
      puts "."
    end

    def update_sheet_properties(id, sheets)
      requests = sheet_requests(sheets, service.get_spreadsheet(id).sheets)
      return if requests.empty?
      print "Updating spreadsheet sheets.."
      service.batch_update_spreadsheet(id, batch_update_request(requests))
      puts "."
    end

    def batch_update_request(requests)
      SERVICE::BatchUpdateSpreadsheetRequest.new(requests: requests)
    end

    def sheet_requests(sheets, existing_sheets)
      [].tap do |requests|
        sheets.keys.each_with_index do |title, i|
          sheet = existing_sheets[i]
          if sheet.present?
            next if sheet.properties.title == title
            requests << SERVICE::Request.new(
              update_sheet_properties: SERVICE::UpdateSheetPropertiesRequest.new(
                fields: "title",
                properties: SERVICE::SheetProperties.new(
                  sheet_id: sheet.properties.sheet_id,
                  title: title,
                )
              )
            )
          else
            requests << SERVICE::Request.new(
              add_sheet: SERVICE::AddSheetRequest.new(
                properties: SERVICE::SheetProperties.new(
                  sheet_id: i,
                  title: title
                )
              )
            )
          end
        end
      end
    end

    def build_sheets(simulation)
      {
        "Configuration"         => simulation.config_info,
        "Monthly Balances"      => simulation.monthly_balances,
        "All Transactions"      => simulation.transactions,
        "Tax Transactions"      => simulation.tax_transactions,
        "Tax Years"             => simulation.tax_years,
        "IRA Transactions"      => simulation.ira_transactions,
        "Savings Transactions"  => simulation.savings_transactions,
        "Roth IRA Transactions" => simulation.roth_transactions,
      }
    end

    def find_or_create_spreadsheet_id(name)
      spreadsheets = if File.exist?(spreadsheets_path)
        YAML.load_file(spreadsheets_path)
      else
        {}
      end
      id = spreadsheets[name]
      return id if id.present?
      spreadsheet = service.create_spreadsheet({
        properties: {
          title: name
        }
      }, fields: 'spreadsheetId')
      spreadsheet.spreadsheet_id.tap do |id|
        spreadsheets[name] = id
        File.write(spreadsheets_path, spreadsheets.to_yaml)
      end
    end

    def desktop_service
      SERVICE::SheetsService.new.tap do |service|
        service.client_options.application_name = app_name
        service.authorization = desktop_authorize
      end
    end

    private

    def desktop_authorize
      client_id   = Google::Auth::ClientId.from_file(credentials_path)
      token_store = Google::Auth::Stores::FileTokenStore.new(file: token_path)
      authorizer  = Google::Auth::UserAuthorizer.new(client_id, api_scope, token_store)
      credentials = authorizer.get_credentials(user_id)
      return credentials if credentials.present?
      auth_url = authorizer.get_credentials(base_url: auth_urn)
      puts "Login via this URL and paste resulting code:", url
      code = STDIN.gets.chomp
      authorizer.get_and_store_credentials_from_code(
        user_id: user_id, code: code, base_url: auth_urn
      )
    end

    def write_spreadsheets_scope
      SERVICE::AUTH_SPREADSHEETS
    end

    def config_credentials_path
      config_path "credentials.json"
    end

    def config_token_path
      config_path "token.yml"
    end

    def config_spreadsheets_path
      config_path "spreadsheets.yml"
    end

    def config_path(name)
      File.join(ROOT_DIR, "config", name)
    end
  end
end
